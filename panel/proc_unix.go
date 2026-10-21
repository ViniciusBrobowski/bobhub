//go:build !windows

package main

import (
	"os/exec"
	"syscall"
	"time"
)

// configureCommand starts the lifecycle script in its own process group so a
// cancel request can terminate the whole tree (bash, terraform, ansible, ...).
func configureCommand(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
}

func killProcessTree(pid int, _ *exec.Cmd) {
	_ = syscall.Kill(-pid, syscall.SIGTERM)

	go func() {
		time.Sleep(2 * time.Second)
		_ = syscall.Kill(-pid, syscall.SIGKILL)
	}()
}
