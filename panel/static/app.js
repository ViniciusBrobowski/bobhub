"use strict";

const TOKEN = document.querySelector('meta[name="bobhub-token"]').content;
const $ = (selector) => document.querySelector(selector);

const state = {
  status: null,
  run: {},
  wasActive: false,
  connected: false,
  elapsedTimer: null,
  statusError: false,
};

const els = {
  adminUser: $("#admin-user"),
  adminPassword: $("#admin-password"),
  appPassword: $("#app-password"),
  start: $("#btn-start"),
  stop: $("#btn-stop"),
  cancel: $("#btn-cancel"),
  refresh: $("#btn-refresh"),
  statusRefresh: $("#btn-status-refresh"),
  azLogin: $("#btn-az-login"),
  runBanner: $("#run-banner"),
  runLabel: $("#run-label"),
  runElapsed: $("#run-elapsed"),
  envTitle: $("#env-title"),
  envSubtitle: $("#env-subtitle"),
  envDot: $("#env-dot"),
  statusGrid: $("#status-grid"),
  appHint: $("#app-hint"),
  appLinks: $("#app-links"),
  log: $("#log"),
  logCount: $("#log-count"),
  autoscroll: $("#autoscroll"),
  clearLog: $("#btn-clear-log"),
  connBadge: $("#conn-badge"),
  clock: $("#clock"),
  repoPath: $("#repo-path"),
  secretsNote: $("#secrets-note"),
  secretsNoteText: $("#secrets-note-text"),
  dialog: $("#confirm-dialog"),
  toasts: $("#toasts"),
};

// --------------------------------------------------------------------------
// API
// --------------------------------------------------------------------------

async function api(path, options = {}) {
  const response = await fetch(path, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      "X-BobHub-Token": TOKEN,
      ...(options.headers || {}),
    },
  });

  if (!response.ok) {
    const text = (await response.text()).trim();
    throw new Error(text || `HTTP ${response.status}`);
  }

  if (response.status === 204) {
    return null;
  }

  return response.json().catch(() => null);
}

// --------------------------------------------------------------------------
// Status
// --------------------------------------------------------------------------

async function loadStatus(refresh = false) {
  try {
    const status = await api(`/api/status${refresh ? "?refresh=1" : ""}`);
    state.statusError = false;
    renderStatus(status);
  } catch (error) {
    if (!state.statusError) {
      state.statusError = true;
      toast(`Falha ao consultar o status: ${error.message}`, "error");
    }
  }
}

function renderStatus(status) {
  state.status = status;

  const oci = status.oci || {};
  const ociValues = oci.values || {};
  const azureValues = (status.azure_data || {}).values || {};

  const running = ociValues.application_instance_state === "RUNNING";
  const loadBalancer = ociValues.load_balancer_public_ip || "";
  const natIP = ociValues.nat_gateway_public_ip || "";

  els.envTitle.textContent = running ? "Ambiente ativo" : "Ambiente parado";
  els.envSubtitle.textContent = running
    ? `OCI ${ociValues.application_instance_private_ip || "—"} · LB ${loadBalancer || "—"} · NAT ${natIP || "—"}`
    : "Inicie o laboratório para provisionar OCI, Azure PostgreSQL e o túnel de administração.";

  if (els.envDot) {
    els.envDot.className = `env-state-dot ${running ? "ok" : "warn"}`;
  }

  renderSecrets(status.secrets || {});

  els.repoPath.textContent = status.repo_root || "—";

  renderCards(status, ociValues, azureValues);
  renderApp(status);
  renderRun(status.run || {});
}

function renderSecrets(secrets) {
  const provided = [];

  if (secrets.admin_user) {
    provided.push("usuário admin");
  }

  if (secrets.admin_password) {
    provided.push("senha admin");
  }

  if (secrets.app_password) {
    provided.push("senha do app");
  }

  if (secrets.nat_ip) {
    provided.push("IP do NAT");
  }

  const hasSecrets = provided.length > 0;

  els.secretsNote.classList.toggle("hidden", !hasSecrets);

  if (hasSecrets) {
    els.secretsNoteText.textContent =
      `Do ambiente (Vault): ${provided.join(", ")}. Campos em branco usam esses valores.`;
  }

  els.adminUser.placeholder = secrets.admin_user ? "fornecido pelo ambiente" : "bobhubadmin";
  els.adminPassword.placeholder = secrets.admin_password ? "fornecido pelo ambiente" : "";
  els.appPassword.placeholder = secrets.app_password ? "fornecido pelo ambiente" : "";
}

function renderCards(status, ociValues, azureValues) {
  const cards = [];

  // Azure CLI authentication
  const azure = status.azure || {};
  if (azure.authenticated) {
    cards.push(card("Azure", "ok", "autenticado", [
      ["Assinatura", azure.name || "—"],
      ["Usuário", azure.user || "—"],
      ["ID", short(azure.id, 20)],
    ]));
  } else {
    cards.push(card("Azure", "error", "offline", [
      ["Detalhe", short(azure.error || "az login necessário", 42)],
    ]));
  }

  // OCI infrastructure
  const oci = status.oci || {};
  if (oci.available) {
    const instanceState = ociValues.application_instance_state || "";
    const tone = instanceState === "RUNNING"
      ? "ok"
      : instanceState === "STOPPED"
        ? "warn"
        : instanceState
          ? "error"
          : "unknown";

    cards.push(card("OCI", tone, instanceState || "não provisionado", [
      ["Instância", short(ociValues.application_instance_id, 22)],
      ["IP privado", ociValues.application_instance_private_ip || "—"],
      ["NAT público", ociValues.nat_gateway_public_ip || "—"],
      ["Load Balancer", ociValues.load_balancer_public_ip || "—"],
    ]));
  } else {
    cards.push(card("OCI", "unknown", "indisponível", [
      ["Detalhe", short(oci.error || "sem dados do Terraform", 42)],
    ]));
  }

  // Azure PostgreSQL
  const azureData = status.azure_data || {};
  if (azureData.available) {
    const fqdn = azureValues.postgresql_fqdn || "";
    cards.push(card("Azure PostgreSQL", fqdn ? "ok" : "unknown", fqdn ? "online" : "n/d", [
      ["FQDN", short(fqdn, 34)],
      ["Database", azureValues.postgresql_database_name || "—"],
    ]));
  } else {
    cards.push(card("Azure PostgreSQL", "unknown", "indisponível", [
      ["Detalhe", short(azureData.error || "sem dados do Terraform", 42)],
    ]));
  }

  // Local SSH tunnel
  const tunnel = status.tunnel || {};
  cards.push(card("Túnel SSH", tunnel.up ? "ok" : "unknown", tunnel.up ? "ativo" : "inativo", [
    ["Endpoint", "127.0.0.1:2222"],
    ["Bastion", short(ociValues.bastion_id, 22)],
  ]));

  // Application through the public load balancer
  const app = status.app || {};
  const health = app.health;
  const appTone = health ? (health.ok ? "ok" : "error") : "unknown";

  cards.push(card("Aplicação", appTone, health ? String(health.status) : "sem dados", [
    ["URL", app.url || "—"],
    ["Health", health ? short(health.body, 18) : "—"],
    ["DB", app.db_health ? short(app.db_health.body, 14) : "—"],
    ["WAF", app.waf ? (app.waf.status === 403 ? "403 bloqueado" : `HTTP ${app.waf.status}`) : "—"],
  ]));

  // Local toolchain
  const platform = status.platform || "windows";
  const required = ["terraform", "az", "oci", "ssh", "ansible"];

  if (platform === "windows") {
    required.push("wsl");
  } else {
    required.push("jq");
  }

  const tools = status.tools || {};
  const missing = required.filter((name) => !(tools[name] && tools[name].found));

  cards.push(card(
    "Toolchain",
    missing.length ? "warn" : "ok",
    missing.length ? `${missing.length} faltando` : "completo",
    required.map((name) => [name, tools[name] && tools[name].found ? "ok" : "faltando"]),
  ));

  els.statusGrid.innerHTML = cards.join("");
}

function card(title, tone, pill, rows) {
  const body = rows.map(([label, value]) => {
    const safe = value === undefined || value === null || value === "" ? "—" : String(value);
    return `<div><dt>${esc(label)}</dt><dd title="${esc(safe)}">${esc(safe)}</dd></div>`;
  }).join("");

  return `<article class="status-card">
    <div class="status-head">
      <span class="dot ${tone}"></span>
      <span class="status-title">${esc(title)}</span>
      <span class="pill ${tone}">${esc(pill)}</span>
    </div>
    <dl>${body}</dl>
  </article>`;
}

function renderApp(status) {
  const app = status.app || {};

  if (!app.url) {
    els.appHint.textContent = "A aplicação ainda não está exposta. Inicie o ambiente para obter o IP público do Load Balancer.";
    els.appLinks.innerHTML = "";
    return;
  }

  const health = app.health;
  els.appHint.textContent = health
    ? `${app.url} · health ${health.status} · db ${app.db_health ? app.db_health.status : "—"}`
    : `${app.url} · aguardando resposta`;

  const links = [
    ["Abrir aplicação", app.url],
    ["/health", `${app.url}/health`],
    ["/whoami", `${app.url}/whoami`],
    ["/db-health", `${app.url}/db-health`],
  ];

  els.appLinks.innerHTML = links.map(([label, href]) =>
    `<a class="btn btn-secondary btn-sm" href="${esc(href)}" target="_blank" rel="noreferrer">${esc(label)}</a>`,
  ).join("") + `<button id="btn-waf" class="btn btn-secondary btn-sm" type="button">Testar WAF</button>`;

  $("#btn-waf").addEventListener("click", testWAF);
}

async function testWAF() {
  try {
    const result = await api("/api/waf-test", { method: "POST" });

    if (result && result.status === 403) {
      toast(`WAF bloqueou a requisição como esperado (403): ${result.body || "sem corpo"}`, "ok");
    } else {
      toast(`WAF retornou ${result && result.status ? result.status : "erro"} — verifique a regra.`, "warn");
    }
  } catch (error) {
    toast(error.message, "error");
  }
}

// --------------------------------------------------------------------------
// Run state
// --------------------------------------------------------------------------

function renderRun(run) {
  state.run = run || {};

  const active = Boolean(state.run.active);
  const wasActive = state.wasActive;

  els.start.disabled = active;
  els.stop.disabled = active;
  els.cancel.classList.toggle("hidden", !active);
  els.runBanner.classList.toggle("hidden", !active);

  if (active) {
    els.runLabel.textContent = state.run.action === "stop"
      ? "Destruindo ambiente (Terraform destroy)…"
      : "Provisionando ambiente (Terraform apply + Ansible)…";
    startElapsed(state.run.started_at || Date.now());
  } else {
    stopElapsed();

    if (wasActive) {
      const code = state.run.exit_code;

      if (state.run.cancelled) {
        toast("Execução cancelada.", "warn");
      } else if (code === 0) {
        toast("Execução concluída com sucesso.", "ok");
      } else {
        toast(`Execução finalizada com código ${code === undefined ? "?" : code}.`, "error");
      }

      loadStatus(false);
    }
  }

  state.wasActive = active;
}

function startElapsed(startedAt) {
  stopElapsed();

  const update = () => {
    els.runElapsed.textContent = formatDuration(Date.now() - startedAt);
  };

  update();
  state.elapsedTimer = setInterval(update, 1000);
}

function stopElapsed() {
  if (state.elapsedTimer) {
    clearInterval(state.elapsedTimer);
    state.elapsedTimer = null;
  }
}

function formatDuration(milliseconds) {
  const total = Math.max(0, Math.floor(milliseconds / 1000));
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const seconds = total % 60;

  if (hours > 0) {
    return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
  }

  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

// --------------------------------------------------------------------------
// Actions
// --------------------------------------------------------------------------

async function startLab() {
  const payload = credentials(true);
  if (!payload) {
    return;
  }

  setActionsBusy(true);

  try {
    const run = await api("/api/start", { method: "POST", body: JSON.stringify(payload) });
    renderRun(run || {});
    toast("Iniciando o ambiente… acompanhe o console.", "ok");
  } catch (error) {
    toast(error.message, "error");
    setActionsBusy(false);
  }
}

async function stopLab() {
  const payload = stopCredentials();
  if (!payload) {
    return;
  }

  setActionsBusy(true);

  try {
    const run = await api("/api/stop", { method: "POST", body: JSON.stringify(payload) });
    renderRun(run || {});
    toast("Parando o ambiente…", "warn");
  } catch (error) {
    toast(error.message, "error");
    setActionsBusy(false);
  }
}

function credentials(requireAppPassword) {
  const adminUser = els.adminUser.value.trim();
  const adminPassword = els.adminPassword.value;
  const appPassword = els.appPassword.value;
  const secrets = (state.status && state.status.secrets) || {};

  if (!adminUser && !secrets.admin_user) {
    toast("Informe o usuário admin do PostgreSQL ou defina BOBHUB_DB_ADMIN_USER.", "warn");
    return null;
  }

  if (!adminPassword && !secrets.admin_password) {
    toast("Informe a senha admin do PostgreSQL ou defina TF_VAR_postgresql_admin_password.", "warn");
    return null;
  }

  if (requireAppPassword && !appPassword && !secrets.app_password) {
    toast("Informe a senha do app (bobhub_app) ou defina BOBHUB_DB_PASSWORD.", "warn");
    return null;
  }

  return {
    admin_user: adminUser,
    admin_password: adminPassword,
    app_password: appPassword,
    nat_ip: (state.status && state.status.oci && state.status.oci.values
      && state.status.oci.values.nat_gateway_public_ip) || "",
  };
}

function stopCredentials() {
  const adminPassword = els.adminPassword.value;
  const secrets = (state.status && state.status.secrets) || {};

  if (!adminPassword && !secrets.admin_password) {
    toast("Informe a senha admin do PostgreSQL ou defina TF_VAR_postgresql_admin_password.", "warn");
    return null;
  }

  let natIP = (state.status && state.status.oci && state.status.oci.values
    && state.status.oci.values.nat_gateway_public_ip) || "";

  if (!natIP) {
    natIP = window.prompt(
      "IP público do NAT Gateway da OCI (necessário para destruir o Azure):",
      "",
    ) || "";

    if (!natIP.trim()) {
      toast("Informe o IP do NAT Gateway para continuar.", "warn");
      return null;
    }
  }

  return {
    admin_password: adminPassword,
    nat_ip: natIP.trim(),
  };
}

function setActionsBusy(busy) {
  if (busy) {
    els.start.disabled = true;
    els.stop.disabled = true;
    return;
  }

  renderRun(state.run);
}

// --------------------------------------------------------------------------
// Console
// --------------------------------------------------------------------------

const LOG_BOTTOM_THRESHOLD = 24;

function isLogAtBottom() {
  return els.log.scrollHeight - els.log.scrollTop - els.log.clientHeight <= LOG_BOTTOM_THRESHOLD;
}

function appendLog(entry) {
  const wasAtBottom = isLogAtBottom();
  const line = document.createElement("div");
  line.className = `log-line ${classify(entry.line || "")}`.trim();

  const timestamp = document.createElement("span");
  timestamp.className = "log-ts";
  timestamp.textContent = new Date(entry.ts || Date.now()).toLocaleTimeString("pt-BR");

  const text = document.createElement("span");
  text.className = "log-text";
  text.textContent = entry.line || "";

  line.append(timestamp, text);
  els.log.append(line);

  while (els.log.childElementCount > 2000) {
    els.log.firstElementChild.remove();
  }

  updateLogCount();

  if (wasAtBottom || els.autoscroll.checked) {
    els.log.scrollTop = els.log.scrollHeight;
  }
}

function classify(line) {
  if (/^==>/.test(line)) {
    return "step";
  }

  if (/(error|erro|fatal|fail|falha|exception|traceback)/i.test(line)) {
    return "error";
  }

  if (/(success|sucesso|conclu|completed|validated|healthy)/i.test(line)) {
    return "ok";
  }

  if (/(warning|warn|atenção|atencao)/i.test(line)) {
    return "warn";
  }

  return "";
}

function updateLogCount() {
  const count = els.log.childElementCount;
  els.logCount.textContent = `${count} ${count === 1 ? "linha" : "linhas"}`;
}

async function clearLogs() {
  els.log.replaceChildren();
  updateLogCount();

  try {
    await api("/api/logs/clear", { method: "POST" });
  } catch {
    // The local console is already clear; a failed server-side clear is harmless.
  }
}

// --------------------------------------------------------------------------
// SSE
// --------------------------------------------------------------------------

function connectEvents() {
  const events = new EventSource(`/api/events?token=${encodeURIComponent(TOKEN)}`);

  events.addEventListener("open", () => {
    setConnected(true);
    els.log.replaceChildren();
    updateLogCount();
    loadStatus(false);
  });

  events.addEventListener("error", () => {
    setConnected(false);
  });

  events.addEventListener("log", (event) => {
    appendLog(JSON.parse(event.data));
  });

  events.addEventListener("run", (event) => {
    renderRun(JSON.parse(event.data));
  });

  events.addEventListener("status-invalidated", () => {
    loadStatus(false);
  });
}

function setConnected(connected) {
  state.connected = connected;
  els.connBadge.textContent = connected ? "ao vivo" : "reconectando…";
  els.connBadge.className = `badge ${connected ? "online" : "offline"}`;
}

// --------------------------------------------------------------------------
// UI helpers
// --------------------------------------------------------------------------

function toast(message, tone = "info") {
  const item = document.createElement("div");
  item.className = `toast ${tone}`;
  item.textContent = message;
  els.toasts.append(item);

  while (els.toasts.childElementCount > 5) {
    els.toasts.firstElementChild.remove();
  }

  setTimeout(() => item.remove(), 5200);
}

function esc(value) {
  return String(value === undefined || value === null ? "" : value).replace(/[&<>"']/g, (character) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  }[character]));
}

function short(value, max = 28) {
  const text = String(value === undefined || value === null ? "" : value);
  return text.length > max ? `${text.slice(0, max)}…` : text;
}

// --------------------------------------------------------------------------
// Wiring
// --------------------------------------------------------------------------

$("#credentials-form").addEventListener("submit", (event) => {
  event.preventDefault();
  startLab();
});

els.start.addEventListener("click", startLab);

els.stop.addEventListener("click", () => {
  if (els.dialog.open) {
    return;
  }

  const secrets = (state.status && state.status.secrets) || {};

  if (!els.adminPassword.value && !secrets.admin_password) {
    toast("Informe a senha admin do PostgreSQL ou defina TF_VAR_postgresql_admin_password.", "warn");
    return;
  }

  els.dialog.showModal();
});

els.dialog.addEventListener("close", () => {
  if (els.dialog.returnValue === "confirm") {
    stopLab();
  }
});

els.cancel.addEventListener("click", async () => {
  if (!window.confirm("Cancelar a execução em andamento?")) {
    return;
  }

  try {
    await api("/api/cancel", { method: "POST" });
    toast("Cancelamento solicitado.", "warn");
  } catch (error) {
    toast(error.message, "error");
  }
});

els.azLogin.addEventListener("click", async () => {
  try {
    await api("/api/az-login", { method: "POST" });
    toast("Janela de login do Azure aberta.", "ok");
  } catch (error) {
    toast(error.message, "error");
  }
});

async function refreshStatus() {
  toast("Atualizando status…");
  await loadStatus(true);
}

els.refresh.addEventListener("click", refreshStatus);
els.statusRefresh.addEventListener("click", refreshStatus);
els.clearLog.addEventListener("click", clearLogs);

els.log.addEventListener("scroll", () => {
  if (els.autoscroll.checked && !isLogAtBottom()) {
    els.autoscroll.checked = false;
  }
}, { passive: true });

document.querySelectorAll(".eye").forEach((button) => {
  button.addEventListener("click", () => {
    const input = document.getElementById(button.dataset.target);
    const show = input.type === "password";

    input.type = show ? "text" : "password";
    button.textContent = show ? "ocultar" : "mostrar";
    button.setAttribute("aria-label", show ? "Ocultar senha" : "Mostrar senha");
  });
});

function tickClock() {
  els.clock.textContent = new Date().toLocaleTimeString("pt-BR");
}

tickClock();
setInterval(tickClock, 1000);

setInterval(() => {
  if (!state.run.active) {
    loadStatus(false);
  }
}, 12000);

// --------------------------------------------------------------------------
// Section navigation
// --------------------------------------------------------------------------

const navItems = Array.from(document.querySelectorAll(".nav-item[data-section]"));

function setActiveNav(id) {
  navItems.forEach((item) => {
    item.classList.toggle("is-active", item.dataset.section === id);
  });
}

navItems.forEach((item) => {
  item.addEventListener("click", () => setActiveNav(item.dataset.section));
});

if ("IntersectionObserver" in window) {
  const observer = new IntersectionObserver(
    (entries) => {
      const visible = entries
        .filter((entry) => entry.isIntersecting)
        .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];

      if (visible) {
        setActiveNav(visible.target.id);
      }
    },
    { rootMargin: "-64px 0px -55% 0px", threshold: [0, 0.15, 0.4] },
  );

  navItems
    .map((item) => document.getElementById(item.dataset.section))
    .filter(Boolean)
    .forEach((section) => observer.observe(section));
}

const disableSSE = new URLSearchParams(window.location.search).has("nosse");

loadStatus(true);

if (disableSSE) {
  els.connBadge.textContent = "polling";
  els.connBadge.className = "badge";
} else {
  connectEvents();
}
