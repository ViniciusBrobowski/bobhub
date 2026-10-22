//go:build windows

package main

import (
	"os/exec"
	"strconv"
)

func configureCommand(_ *exec.Cmd) {}

func killProcessTree(pid int, _ *exec.Cmd) {
	_ = exec.Command("taskkill", "/PID", strconv.Itoa(pid), "/T", "/F").Run()
}
