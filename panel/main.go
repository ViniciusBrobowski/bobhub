// BobHub Control Panel is a small local web application used to start,
// stop and observe the BobHub v0.3 multi-cloud lab.
//
// The panel is intentionally dependency-free (Go standard library only).
// It serves an embedded front end, exposes a JSON/SSE API and invokes the
// existing PowerShell lifecycle scripts in non-interactive mode.
package main

import (
	"bufio"
	"context"
	"crypto/rand"
	"crypto/subtle"
	"embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"regexp"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"
)

//go:embed static
var embeddedStatic embed.FS

var (
	repoRoot      string
	startScript   string
	stopScript    string
	ociDir        string
	azureDir      string
	panelFS       fs.FS
	staticHandler http.Handler
	cache         = newCache()
	bus           = newEventBus()
	manager       *Manager
	authToken     string
)

const (
	defaultPort = 8090
	maxLogLines = 2000
)

func main() {
	host := flag.String("host", "127.0.0.1", "Endereço de escuta (padrão: somente local)")
	port := flag.Int("port", defaultPort, "Porta HTTP")
	repo := flag.String("repo", "", "Caminho da raiz do repositório BobHub")
	noBrowser := flag.Bool("no-browser", false, "Não abrir o navegador automaticamente")
	flag.Parse()

	var err error

	if *repo != "" {
		repoRoot, err = filepath.Abs(*repo)
	} else {
		repoRoot, err = findRepoRoot()
	}

	if err != nil {
		log.Fatalf("não foi possível localizar a raiz do BobHub: %v", err)
	}

	startScript = lifecycleScript("start")
	stopScript = lifecycleScript("stop")
	ociDir = filepath.Join(repoRoot, "terraform", "multicloud", "oci-dr")
	azureDir = filepath.Join(repoRoot, "terraform", "multicloud", "azure-data")

	if !fileExists(startScript) || !fileExists(stopScript) {
		log.Fatalf("scripts de ciclo de vida não encontrados em %s", filepath.Join(repoRoot, "scripts", "cloud"))
	}

	panelFS, err = fs.Sub(embeddedStatic, "static")
	if err != nil {
		log.Fatalf("falha ao carregar os assets embutidos: %v", err)
	}

	staticHandler = http.FileServer(http.FS(panelFS))
	manager = newManager()
	authToken = newToken()

	mux := http.NewServeMux()
	mux.HandleFunc("/api/health", handleHealth)
	mux.HandleFunc("/api/status", handleStatus)
	mux.HandleFunc("/api/events", handleEvents)
	mux.HandleFunc("/api/start", handleStart)
	mux.HandleFunc("/api/stop", handleStop)
	mux.HandleFunc("/api/cancel", handleCancel)
	mux.HandleFunc("/api/az-login", handleAZLogin)
	mux.HandleFunc("/api/waf-test", handleWAFTest)
	mux.HandleFunc("/api/logs/clear", handleClearLogs)
	mux.HandleFunc("/", handleRoot)

	addr := net.JoinHostPort(*host, strconv.Itoa(*port))

	browserHost := *host
	if browserHost == "0.0.0.0" || browserHost == "::" {
		browserHost = "127.0.0.1"
	}
	browserURL := fmt.Sprintf("http://%s", net.JoinHostPort(browserHost, strconv.Itoa(*port)))

	server := &http.Server{
		Addr:              addr,
		Handler:           securityHeaders(hostGuard(mux, *host, *port)),
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       120 * time.Second,
	}

	log.Printf("BobHub Control Panel")
	log.Printf("  repositório: %s", repoRoot)
	log.Printf("  endereço:    %s", browserURL)
	log.Printf("  scripts:     start=%t stop=%t", fileExists(startScript), fileExists(stopScript))

	envSecrets := secretsStatus()
	log.Printf(
		"  secrets:     admin_user=%t admin_password=%t app_password=%t nat_ip=%t (ambiente)",
		envSecrets.AdminUser,
		envSecrets.AdminPassword,
		envSecrets.AppPassword,
		envSecrets.NATIP,
	)

	if !*noBrowser {
		go func() {
			time.Sleep(900 * time.Millisecond)
			openBrowser(browserURL)
		}()
	}

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt)

	go func() {
		<-stop
		log.Println("encerrando painel...")
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = server.Shutdown(ctx)
	}()

	if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatalf("servidor HTTP falhou: %v", err)
	}
}

// ---------------------------------------------------------------------------
// HTTP handlers
// ---------------------------------------------------------------------------

func handleHealth(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"ok":   true,
		"time": time.Now().UnixMilli(),
	})
}

func handleStatus(w http.ResponseWriter, r *http.Request) {
	if !allowMethod(w, r, http.MethodGet) || !requireToken(w, r) {
		return
	}

	refresh := r.URL.Query().Get("refresh") == "1"
	writeJSON(w, http.StatusOK, buildStatus(refresh))
}

func handleEvents(w http.ResponseWriter, r *http.Request) {
	if !allowMethod(w, r, http.MethodGet) || !requireToken(w, r) {
		return
	}

	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming não suportado", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache, no-transform")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("X-Accel-Buffering", "no")
	w.WriteHeader(http.StatusOK)

	events, unsubscribe := bus.Subscribe()
	defer unsubscribe()

	if err := writeSSE(w, "ready", map[string]any{"time": time.Now().UnixMilli()}); err != nil {
		return
	}

	for _, line := range bus.History() {
		if err := writeSSE(w, "log", line); err != nil {
			return
		}
	}

	flusher.Flush()

	keepAlive := time.NewTicker(15 * time.Second)
	defer keepAlive.Stop()

	for {
		select {
		case <-r.Context().Done():
			return
		case event := <-events:
			if err := writeSSE(w, event.Name, event.Data); err != nil {
				return
			}
			flusher.Flush()
		case <-keepAlive.C:
			if _, err := io.WriteString(w, ": keep-alive\n\n"); err != nil {
				return
			}
			flusher.Flush()
		}
	}
}

func handleStart(w http.ResponseWriter, r *http.Request) {
	if !allowMethod(w, r, http.MethodPost) || !requireToken(w, r) {
		return
	}

	var req RunRequest
	if err := json.NewDecoder(io.LimitReader(r.Body, 1<<20)).Decode(&req); err != nil {
		http.Error(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	req.AdminUser = strings.TrimSpace(req.AdminUser)
	req.applyEnvironment()

	if req.AdminUser == "" || req.AdminPassword == "" || req.AppPassword == "" {
		http.Error(w, "credenciais ausentes: preencha o formulário ou injete BOBHUB_DB_ADMIN_USER, TF_VAR_postgresql_admin_password e BOBHUB_DB_PASSWORD no ambiente do painel", http.StatusBadRequest)
		return
	}

	if err := manager.Start("start", req); err != nil {
		http.Error(w, err.Error(), http.StatusConflict)
		return
	}

	writeJSON(w, http.StatusAccepted, manager.Snapshot())
}

func handleStop(w http.ResponseWriter, r *http.Request) {
	if !allowMethod(w, r, http.MethodPost) || !requireToken(w, r) {
		return
	}

	var req RunRequest
	if err := json.NewDecoder(io.LimitReader(r.Body, 1<<20)).Decode(&req); err != nil {
		http.Error(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	req.applyEnvironment()

	if req.AdminPassword == "" {
		http.Error(w, "admin_password é obrigatório para destruir o ambiente (formulário ou TF_VAR_postgresql_admin_password)", http.StatusBadRequest)
		return
	}

	if err := manager.Start("stop", req); err != nil {
		http.Error(w, err.Error(), http.StatusConflict)
		return
	}

	writeJSON(w, http.StatusAccepted, manager.Snapshot())
}

func handleCancel(w http.ResponseWriter, r *http.Request) {
	if !allowMethod(w, r, http.MethodPost) || !requireToken(w, r) {
		return
	}

	if !manager.Cancel() {
		http.Error(w, "nenhuma execução ativa", http.StatusConflict)
		return
	}

	writeJSON(w, http.StatusAccepted, manager.Snapshot())
}

func handleAZLogin(w http.ResponseWriter, r *http.Request) {
	if !allowMethod(w, r, http.MethodPost) || !requireToken(w, r) {
		return
	}

	if runtime.GOOS != "windows" {
		http.Error(w, "na VPS, autentique com 'az login --use-device-code' por SSH", http.StatusNotImplemented)
		return
	}

	cmd := exec.Command(
		"powershell.exe",
		"-NoProfile",
		"-Command",
		"Start-Process powershell.exe -ArgumentList '-NoExit','-Command','az login'",
	)

	if err := cmd.Start(); err != nil {
		http.Error(w, "não foi possível abrir a janela de login do Azure: "+err.Error(), http.StatusInternalServerError)
		return
	}

	writeJSON(w, http.StatusAccepted, map[string]string{
		"status": "janela de login do Azure aberta",
	})
}

func handleWAFTest(w http.ResponseWriter, r *http.Request) {
	if !allowMethod(w, r, http.MethodPost) || !requireToken(w, r) {
		return
	}

	status := buildStatus(false)
	lbIP := resolveLBIP(status.OCI)

	if lbIP == "" {
		http.Error(w, "Load Balancer público não disponível", http.StatusConflict)
		return
	}

	result := probe("http://"+lbIP+"/health", map[string]string{
		"X-BobHub-WAF-Test": "block",
	})

	writeJSON(w, http.StatusOK, result)
}

func handleClearLogs(w http.ResponseWriter, r *http.Request) {
	if !allowMethod(w, r, http.MethodPost) || !requireToken(w, r) {
		return
	}

	bus.Clear()
	w.WriteHeader(http.StatusNoContent)
}

func handleRoot(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path == "/" || r.URL.Path == "/index.html" {
		serveIndex(w)
		return
	}

	w.Header().Set("Cache-Control", "no-cache")
	staticHandler.ServeHTTP(w, r)
}

func serveIndex(w http.ResponseWriter) {
	data, err := fs.ReadFile(panelFS, "index.html")
	if err != nil {
		http.Error(w, "index.html não encontrado", http.StatusInternalServerError)
		return
	}

	page := strings.ReplaceAll(string(data), "__BOBHUB_TOKEN__", authToken)

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	_, _ = io.WriteString(w, page)
}

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

type Status struct {
	RepoRoot   string          `json:"repo_root"`
	Scripts    map[string]bool `json:"scripts"`
	Secrets    SecretsStatus   `json:"secrets"`
	Tools      ToolsStatus     `json:"tools"`
	Azure      AzureAuth       `json:"azure"`
	OCI        TerraformStatus `json:"oci"`
	AzureData  TerraformStatus `json:"azure_data"`
	Tunnel     TunnelStatus    `json:"tunnel"`
	App        AppStatus       `json:"app"`
	Run        RunState        `json:"run"`
	Platform   string          `json:"platform"`
	ServerTime int64           `json:"server_time"`
}

// SecretsStatus only reports whether each secret is available in the process
// environment. Values are never serialized or sent to the browser.
type SecretsStatus struct {
	AdminUser     bool `json:"admin_user"`
	AdminPassword bool `json:"admin_password"`
	AppPassword   bool `json:"app_password"`
	NATIP         bool `json:"nat_ip"`
}

func secretsStatus() SecretsStatus {
	return SecretsStatus{
		AdminUser:     envValue("BOBHUB_DB_ADMIN_USER") != "",
		AdminPassword: envValue("TF_VAR_postgresql_admin_password") != "",
		AppPassword:   envValue("BOBHUB_DB_PASSWORD") != "",
		NATIP:         envValue("TF_VAR_oci_nat_public_ip") != "",
	}
}

func envValue(name string) string {
	return strings.TrimSpace(os.Getenv(name))
}

type ToolsStatus map[string]ToolResult

type ToolResult struct {
	Found bool   `json:"found"`
	Path  string `json:"path,omitempty"`
}

type AzureAuth struct {
	Authenticated bool   `json:"authenticated"`
	Name          string `json:"name,omitempty"`
	ID            string `json:"id,omitempty"`
	User          string `json:"user,omitempty"`
	Error         string `json:"error,omitempty"`
}

type TerraformStatus struct {
	Available bool           `json:"available"`
	Values    map[string]any `json:"values,omitempty"`
	Error     string         `json:"error,omitempty"`
}

type TunnelStatus struct {
	Up   bool `json:"up"`
	Port int  `json:"port"`
}

type AppStatus struct {
	URL      string `json:"url,omitempty"`
	Health   *Probe `json:"health,omitempty"`
	Whoami   *Probe `json:"whoami,omitempty"`
	DBHealth *Probe `json:"db_health,omitempty"`
	WAF      *Probe `json:"waf,omitempty"`
}

type Probe struct {
	OK     bool   `json:"ok"`
	Status int    `json:"status,omitempty"`
	Body   string `json:"body,omitempty"`
	Error  string `json:"error,omitempty"`
}

func buildStatus(refresh bool) Status {
	if refresh {
		cache.Invalidate()
	}

	var (
		tools     ToolsStatus
		azure     AzureAuth
		oci       TerraformStatus
		azureData TerraformStatus
		wg        sync.WaitGroup
	)

	wg.Add(4)

	go func() {
		defer wg.Done()
		tools = cache.Get("tools", 60*time.Second, loadTools).(ToolsStatus)
	}()

	go func() {
		defer wg.Done()
		azure = cache.Get("azure", 30*time.Second, loadAzure).(AzureAuth)
	}()

	go func() {
		defer wg.Done()
		oci = cache.Get("tf:oci", 45*time.Second, func() any {
			return loadTerraform(ociDir, nil)
		}).(TerraformStatus)
	}()

	go func() {
		defer wg.Done()
		azureData = cache.Get("tf:azure", 45*time.Second, func() any {
			// The status probe is read-only. Dummy values satisfy the
			// required variables without touching the real infrastructure.
			return loadTerraform(azureDir, map[string]string{
				"TF_VAR_postgresql_admin_password": "panel-readonly",
				"TF_VAR_oci_nat_public_ip":         "127.0.0.1",
			})
		}).(TerraformStatus)
	}()

	wg.Wait()

	lbIP := resolveLBIP(oci)

	// Do not mutate the cached Terraform map: copy it before adding the
	// resolved LB address so the front end sees a consistent snapshot.
	values := make(map[string]any, len(oci.Values)+1)
	for key, value := range oci.Values {
		values[key] = value
	}
	if lbIP != "" {
		values["load_balancer_public_ip"] = lbIP
	}
	oci.Values = values

	app := cache.Get("app:"+lbIP, 10*time.Second, func() any {
		return loadAppStatus(lbIP)
	}).(AppStatus)

	return Status{
		RepoRoot: repoRoot,
		Scripts: map[string]bool{
			"start": fileExists(startScript),
			"stop":  fileExists(stopScript),
		},
		Secrets:    secretsStatus(),
		Tools:      tools,
		Azure:      azure,
		OCI:        oci,
		AzureData:  azureData,
		Tunnel:     checkTunnel(),
		App:        app,
		Run:        manager.Snapshot(),
		Platform:   runtime.GOOS,
		ServerTime: time.Now().UnixMilli(),
	}
}

func loadTools() any {
	names := []string{"terraform", "az", "oci", "ssh", "git", "python", "python3", "jq"}
	if runtime.GOOS == "windows" {
		names = append(names, "wsl")
	}

	result := ToolsStatus{}

	for _, name := range names {
		if path, err := exec.LookPath(name); err == nil {
			result[name] = ToolResult{Found: true, Path: path}
		} else {
			result[name] = ToolResult{}
		}
	}

	if runtime.GOOS != "windows" {
		if path, err := exec.LookPath("ansible-playbook"); err == nil {
			result["ansible"] = ToolResult{Found: true, Path: path}
		} else {
			result["ansible"] = ToolResult{}
		}

		return result
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "wsl", "bash", "-lc", "command -v ansible-playbook")

	if out, err := cmd.Output(); err == nil && strings.TrimSpace(string(out)) != "" {
		result["ansible"] = ToolResult{Found: true, Path: strings.TrimSpace(string(out))}
	} else {
		result["ansible"] = ToolResult{}
	}

	return result
}

func loadAzure() any {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "az", "account", "show", "--output", "json")
	out, err := cmd.CombinedOutput()

	if err != nil {
		return AzureAuth{Error: truncate(strings.TrimSpace(string(out)), 400)}
	}

	var account struct {
		Name string `json:"name"`
		ID   string `json:"id"`
		User struct {
			Name string `json:"name"`
		} `json:"user"`
	}

	if err := json.Unmarshal(out, &account); err != nil {
		return AzureAuth{Error: err.Error()}
	}

	return AzureAuth{
		Authenticated: true,
		Name:          account.Name,
		ID:            account.ID,
		User:          account.User.Name,
	}
}

func loadTerraform(dir string, extraEnv map[string]string) any {
	info, err := os.Stat(dir)
	if err != nil || !info.IsDir() {
		return TerraformStatus{Error: "diretório Terraform não encontrado"}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "terraform", "-chdir="+dir, "output", "-json")
	cmd.Env = append(os.Environ(), "TF_IN_AUTOMATION=1", "TF_INPUT=0")

	for key, value := range extraEnv {
		cmd.Env = append(cmd.Env, key+"="+value)
	}

	out, err := cmd.CombinedOutput()

	if err != nil {
		message := strings.TrimSpace(string(out))
		if message == "" {
			message = err.Error()
		}
		return TerraformStatus{Error: truncate(message, 900)}
	}

	var raw map[string]struct {
		Value any `json:"value"`
	}

	if err := json.Unmarshal(out, &raw); err != nil {
		return TerraformStatus{Error: err.Error()}
	}

	values := make(map[string]any, len(raw))
	for key, item := range raw {
		values[key] = item.Value
	}

	return TerraformStatus{Available: true, Values: values}
}

// resolveLBIP prefers the Terraform output and falls back to reading the LB
// resource directly from state. The fallback keeps the panel useful for
// environments created before the output was added to the configuration.
func resolveLBIP(oci TerraformStatus) string {
	if ip := mapString(oci.Values, "load_balancer_public_ip"); ip != "" {
		return ip
	}

	if !oci.Available {
		return ""
	}

	return cache.Get("lb-ip-fallback", 45*time.Second, func() any {
		return loadLBIPFromState()
	}).(string)
}

func loadLBIPFromState() string {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	cmd := exec.CommandContext(
		ctx,
		"terraform",
		"-chdir="+ociDir,
		"state",
		"show",
		"-no-color",
		"oci_load_balancer_load_balancer.bobhub",
	)
	cmd.Env = append(os.Environ(), "TF_IN_AUTOMATION=1", "TF_INPUT=0")

	out, err := cmd.Output()
	if err != nil {
		return ""
	}

	return parseLBIP(string(out))
}

var lbIPPatterns = []*regexp.Regexp{
	regexp.MustCompile(`(?s)ip_address_details\s*=\s*\[\s*\{\s*ip_address\s*=\s*"([^"]+)"`),
	regexp.MustCompile(`(?s)ip_addresses\s*=\s*\[\s*"([^"]+)"`),
}

func parseLBIP(state string) string {
	for _, pattern := range lbIPPatterns {
		match := pattern.FindStringSubmatch(state)
		if len(match) == 2 {
			return match[1]
		}
	}

	return ""
}

func checkTunnel() TunnelStatus {
	conn, err := net.DialTimeout("tcp", "127.0.0.1:2222", 1500*time.Millisecond)
	if err != nil {
		return TunnelStatus{Port: 2222}
	}

	_ = conn.Close()

	return TunnelStatus{Up: true, Port: 2222}
}

func loadAppStatus(lbIP string) AppStatus {
	if lbIP == "" {
		return AppStatus{}
	}

	base := "http://" + lbIP
	result := AppStatus{URL: base}

	var wg sync.WaitGroup
	wg.Add(4)

	go func() {
		defer wg.Done()
		result.Health = probe(base+"/health", nil)
	}()

	go func() {
		defer wg.Done()
		result.Whoami = probe(base+"/whoami", nil)
	}()

	go func() {
		defer wg.Done()
		result.DBHealth = probe(base+"/db-health", nil)
	}()

	go func() {
		defer wg.Done()
		result.WAF = probe(base+"/health", map[string]string{
			"X-BobHub-WAF-Test": "block",
		})
	}()

	wg.Wait()

	return result
}

func probe(url string, headers map[string]string) *Probe {
	client := &http.Client{Timeout: 4 * time.Second}

	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return &Probe{Error: err.Error()}
	}

	req.Header.Set("User-Agent", "BobHub-Panel/1.0")

	for key, value := range headers {
		req.Header.Set(key, value)
	}

	resp, err := client.Do(req)
	if err != nil {
		return &Probe{Error: err.Error()}
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))

	return &Probe{
		OK:     resp.StatusCode >= 200 && resp.StatusCode < 400,
		Status: resp.StatusCode,
		Body:   strings.TrimSpace(string(body)),
	}
}

// ---------------------------------------------------------------------------
// Execution manager
// ---------------------------------------------------------------------------

type RunRequest struct {
	AdminUser     string `json:"admin_user"`
	AdminPassword string `json:"admin_password"`
	AppPassword   string `json:"app_password"`
	NATIP         string `json:"nat_ip"`
}

// applyEnvironment fills empty request fields from environment variables.
// Values explicitly sent by the browser take precedence. The environment is
// normally populated by a Vault Agent template rendered into the service
// environment, so secrets never need to transit the UI.
func (r *RunRequest) applyEnvironment() {
	if strings.TrimSpace(r.AdminUser) == "" {
		r.AdminUser = envValue("BOBHUB_DB_ADMIN_USER")
	}

	if r.AdminPassword == "" {
		r.AdminPassword = os.Getenv("TF_VAR_postgresql_admin_password")
	}

	if r.AppPassword == "" {
		r.AppPassword = os.Getenv("BOBHUB_DB_PASSWORD")
	}

	if strings.TrimSpace(r.NATIP) == "" {
		r.NATIP = envValue("TF_VAR_oci_nat_public_ip")
	}
}

type RunState struct {
	Active     bool   `json:"active"`
	Action     string `json:"action,omitempty"`
	PID        int    `json:"pid,omitempty"`
	StartedAt  int64  `json:"started_at,omitempty"`
	FinishedAt int64  `json:"finished_at,omitempty"`
	ExitCode   *int   `json:"exit_code,omitempty"`
	Cancelled  bool   `json:"cancelled"`
	Error      string `json:"error,omitempty"`
}

type Manager struct {
	mu      sync.Mutex
	run     RunState
	command *exec.Cmd
}

func newManager() *Manager {
	return &Manager{}
}

func (m *Manager) Snapshot() RunState {
	m.mu.Lock()
	defer m.mu.Unlock()

	return m.run
}

func (m *Manager) Start(action string, req RunRequest) error {
	req.applyEnvironment()

	m.mu.Lock()

	if m.run.Active {
		m.mu.Unlock()
		return errors.New("já existe uma execução em andamento")
	}

	script := startScript
	if action == "stop" {
		script = stopScript
	}

	env := append(os.Environ(), "BOBHUB_PANEL=1", "TF_IN_AUTOMATION=1")
	env = append(env, "TF_VAR_postgresql_admin_password="+req.AdminPassword)

	if action == "start" {
		env = append(env,
			"BOBHUB_DB_ADMIN_USER="+req.AdminUser,
			"BOBHUB_DB_PASSWORD="+req.AppPassword,
		)
	}

	if req.NATIP != "" {
		env = append(env, "TF_VAR_oci_nat_public_ip="+req.NATIP)
	}

	var cmd *exec.Cmd

	if runtime.GOOS == "windows" {
		shell := "powershell.exe"
		if path, err := exec.LookPath("pwsh"); err == nil {
			shell = path
		} else if path, err := exec.LookPath("powershell.exe"); err == nil {
			shell = path
		}

		quotedScript := strings.ReplaceAll(script, "'", "''")
		command := fmt.Sprintf(
			"try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}; & '%s' -NonInteractive",
			quotedScript,
		)

		cmd = exec.Command(shell, "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command", command)
	} else {
		cmd = exec.Command("bash", script, "--non-interactive")
	}

	cmd.Dir = repoRoot
	cmd.Env = env
	configureCommand(cmd)

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		m.mu.Unlock()
		return fmt.Errorf("falha ao capturar a saída do script: %w", err)
	}

	cmd.Stderr = cmd.Stdout

	if err := cmd.Start(); err != nil {
		_ = stdout.Close()
		m.mu.Unlock()
		return fmt.Errorf("falha ao iniciar o script: %w", err)
	}

	m.command = cmd
	secrets := []string{
		req.AdminPassword,
		req.AppPassword,
		os.Getenv("TF_VAR_postgresql_admin_password"),
		os.Getenv("BOBHUB_DB_PASSWORD"),
	}
	m.run = RunState{
		Active:    true,
		Action:    action,
		PID:       cmd.Process.Pid,
		StartedAt: time.Now().UnixMilli(),
	}

	snapshot := m.run
	m.mu.Unlock()

	bus.Log(fmt.Sprintf("==> Iniciando ação '%s' (PID %d)", action, snapshot.PID))
	bus.Publish("run", snapshot)

	go m.pump(cmd, stdout, secrets)

	return nil
}

func (m *Manager) pump(cmd *exec.Cmd, stdout io.ReadCloser, secrets []string) {
	scanner := bufio.NewScanner(stdout)
	scanner.Buffer(make([]byte, 64*1024), 1024*1024)

	for scanner.Scan() {
		line := scanner.Text()

		for _, secret := range secrets {
			if len(secret) >= 4 {
				line = strings.ReplaceAll(line, secret, "********")
			}
		}

		bus.Log(line)
	}

	if err := scanner.Err(); err != nil {
		m.mu.Lock()
		cancelled := m.run.Cancelled
		m.mu.Unlock()

		if !cancelled {
			bus.Log("==> Erro ao ler a saída do script: " + err.Error())
		}
	}

	err := cmd.Wait()

	exitCode := 0
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			exitCode = exitErr.ExitCode()
		} else {
			exitCode = -1
		}
	}

	m.mu.Lock()
	m.run.Active = false
	m.run.FinishedAt = time.Now().UnixMilli()
	m.run.ExitCode = &exitCode
	if err != nil && !m.run.Cancelled {
		m.run.Error = err.Error()
	}
	snapshot := m.run
	m.command = nil
	m.mu.Unlock()

	if snapshot.Cancelled {
		bus.Log("==> Execução cancelada pelo operador.")
	} else if exitCode == 0 {
		bus.Log("==> Execução concluída com sucesso.")
	} else {
		bus.Log(fmt.Sprintf("==> Execução finalizada com código %d.", exitCode))
	}

	cache.Invalidate()
	bus.Publish("run", snapshot)
	bus.Publish("status-invalidated", true)
}

func (m *Manager) Cancel() bool {
	m.mu.Lock()

	if !m.run.Active || m.run.PID == 0 {
		m.mu.Unlock()
		return false
	}

	m.run.Cancelled = true
	pid := m.run.PID
	command := m.command
	m.mu.Unlock()

	bus.Log("==> Cancelando execução...")

	killProcessTree(pid, command)

	return true
}

// ---------------------------------------------------------------------------
// Event bus (SSE)
// ---------------------------------------------------------------------------

type LogLine struct {
	Line string `json:"line"`
	TS   int64  `json:"ts"`
}

type Event struct {
	Name string
	Data any
}

type EventBus struct {
	mu      sync.Mutex
	subs    map[chan Event]struct{}
	history []LogLine
}

func newEventBus() *EventBus {
	return &EventBus{subs: make(map[chan Event]struct{})}
}

func (b *EventBus) Log(line string) {
	entry := LogLine{Line: line, TS: time.Now().UnixMilli()}

	b.mu.Lock()
	b.history = append(b.history, entry)
	if len(b.history) > maxLogLines {
		b.history = b.history[len(b.history)-maxLogLines:]
	}
	subs := b.subscribersLocked()
	b.mu.Unlock()

	broadcast(subs, Event{Name: "log", Data: entry})
}

func (b *EventBus) Publish(name string, data any) {
	b.mu.Lock()
	subs := b.subscribersLocked()
	b.mu.Unlock()

	broadcast(subs, Event{Name: name, Data: data})
}

func (b *EventBus) Subscribe() (chan Event, func()) {
	ch := make(chan Event, 256)

	b.mu.Lock()
	b.subs[ch] = struct{}{}
	b.mu.Unlock()

	return ch, func() {
		b.mu.Lock()
		delete(b.subs, ch)
		b.mu.Unlock()
	}
}

func (b *EventBus) History() []LogLine {
	b.mu.Lock()
	defer b.mu.Unlock()

	out := make([]LogLine, len(b.history))
	copy(out, b.history)
	return out
}

func (b *EventBus) Clear() {
	b.mu.Lock()
	b.history = nil
	b.mu.Unlock()
}

func (b *EventBus) subscribersLocked() []chan Event {
	out := make([]chan Event, 0, len(b.subs))
	for ch := range b.subs {
		out = append(out, ch)
	}
	return out
}

func broadcast(subs []chan Event, event Event) {
	for _, ch := range subs {
		select {
		case ch <- event:
		default:
		}
	}
}

func writeSSE(w io.Writer, name string, data any) error {
	payload, err := json.Marshal(data)
	if err != nil {
		return err
	}

	_, err = fmt.Fprintf(w, "event: %s\ndata: %s\n\n", name, payload)
	return err
}

// ---------------------------------------------------------------------------
// Cache
// ---------------------------------------------------------------------------

type cacheEntry struct {
	value   any
	expires time.Time
}

type Cache struct {
	mu   sync.Mutex
	data map[string]cacheEntry
}

func newCache() *Cache {
	return &Cache{data: make(map[string]cacheEntry)}
}

func (c *Cache) Get(key string, ttl time.Duration, load func() any) any {
	c.mu.Lock()
	if entry, ok := c.data[key]; ok && time.Now().Before(entry.expires) {
		c.mu.Unlock()
		return entry.value
	}
	c.mu.Unlock()

	value := load()

	c.mu.Lock()
	c.data[key] = cacheEntry{value: value, expires: time.Now().Add(ttl)}
	c.mu.Unlock()

	return value
}

func (c *Cache) Invalidate() {
	c.mu.Lock()
	c.data = make(map[string]cacheEntry)
	c.mu.Unlock()
}

// ---------------------------------------------------------------------------
// HTTP helpers
// ---------------------------------------------------------------------------

func allowMethod(w http.ResponseWriter, r *http.Request, method string) bool {
	if r.Method == method {
		return true
	}

	w.Header().Set("Allow", method)
	http.Error(w, "método não permitido", http.StatusMethodNotAllowed)
	return false
}

func requireToken(w http.ResponseWriter, r *http.Request) bool {
	token := r.Header.Get("X-BobHub-Token")

	if token == "" {
		token = r.URL.Query().Get("token")
	}

	if subtle.ConstantTimeCompare([]byte(token), []byte(authToken)) != 1 {
		http.Error(w, "não autorizado", http.StatusUnauthorized)
		return false
	}

	return true
}

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("Referrer-Policy", "no-referrer")
		w.Header().Set(
			"Content-Security-Policy",
			"default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; connect-src 'self'; base-uri 'none'; form-action 'self'",
		)

		next.ServeHTTP(w, r)
	})
}

func hostGuard(next http.Handler, host string, _ int) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if host != "127.0.0.1" && host != "localhost" {
			next.ServeHTTP(w, r)
			return
		}

		requestHost := r.Host
		if h, _, err := net.SplitHostPort(r.Host); err == nil {
			requestHost = h
		}

		if requestHost != "127.0.0.1" && requestHost != "localhost" && requestHost != "::1" {
			http.Error(w, "host inválido", http.StatusMisdirectedRequest)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

func lifecycleScript(action string) string {
	extension := ".ps1"
	if runtime.GOOS != "windows" {
		extension = ".sh"
	}

	return filepath.Join(repoRoot, "scripts", "cloud", action+"-v03-lab"+extension)
}

func findRepoRoot() (string, error) {
	var starts []string

	if wd, err := os.Getwd(); err == nil {
		starts = append(starts, wd)
	}

	if exe, err := os.Executable(); err == nil {
		starts = append(starts, filepath.Dir(exe))
	}

	for _, start := range starts {
		dir := start

		for range 8 {
			if fileExists(filepath.Join(dir, "scripts", "cloud", "start-v03-lab.ps1")) ||
				fileExists(filepath.Join(dir, "scripts", "cloud", "start-v03-lab.sh")) {
				return dir, nil
			}

			parent := filepath.Dir(dir)
			if parent == dir {
				break
			}
			dir = parent
		}
	}

	return "", errors.New("use --repo para informar o caminho do repositório")
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

func mapString(values map[string]any, key string) string {
	if values == nil {
		return ""
	}

	if value, ok := values[key].(string); ok {
		return value
	}

	return ""
}

func truncate(value string, max int) string {
	runes := []rune(value)
	if len(runes) <= max {
		return value
	}

	return string(runes[:max]) + "..."
}

func newToken() string {
	buffer := make([]byte, 32)
	if _, err := rand.Read(buffer); err != nil {
		log.Fatalf("falha ao gerar token local: %v", err)
	}

	return hex.EncodeToString(buffer)
}

func openBrowser(url string) {
	var cmd *exec.Cmd

	switch runtime.GOOS {
	case "windows":
		cmd = exec.Command("rundll32", "url.dll,FileProtocolHandler", url)
	case "darwin":
		cmd = exec.Command("open", url)
	default:
		cmd = exec.Command("xdg-open", url)
	}

	_ = cmd.Start()
}
