package sections

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/jhivandb/status-line/internal/api"
)

type Git struct {
	config string
	In     api.InputData
}

func (g *Git) Render() string {
	branch := getGitBranch(g.In)
	return fmt.Sprintf("%s%s", api.ColorTeal, branch)
}

// GetGitBranch executes git command to get the current branch
func getGitBranch(in api.InputData) string {
	workDir := in.Workspace.CurrentDir
	if workDir == "" {
		workDir = in.CWD
	}

	if workDir == "" {
		return "No Git"
	}

	if !isInsideGitRepo(workDir) {
		return "No Git"
	}

	// Execute git command to get current branch
	cmd := exec.Command("git", "branch", "--show-current")
	cmd.Dir = workDir

	output, err := cmd.Output()
	if err != nil {
		// Try alternative method for detached HEAD or older git versions
		return getGitBranchFallback(workDir)
	}

	branch := strings.TrimSpace(string(output))
	if branch == "" {
		return getGitBranchFallback(workDir)
	}

	return fmt.Sprintf("\uf09b \ue0a0%s", branch)
}

// isInsideGitRepo reports whether workDir sits anywhere within a git work tree.
// A .git entry exists only at the repo root, so asking git itself is what makes
// this hold true from subdirectories and worktrees alike.
func isInsideGitRepo(workDir string) bool {
	cmd := exec.Command("git", "rev-parse", "--git-dir")
	cmd.Dir = workDir

	return cmd.Run() == nil
}

// getGitBranchFallback tries alternative methods to get git branch info
func getGitBranchFallback(workDir string) string {
	// Try git symbolic-ref for current branch
	cmd := exec.Command("git", "symbolic-ref", "--short", "HEAD")
	cmd.Dir = workDir

	output, err := cmd.Output()
	if err == nil {
		branch := strings.TrimSpace(string(output))
		if branch != "" {
			return branch
		}
	}

	// Try git describe for detached HEAD
	cmd = exec.Command("git", "describe", "--tags", "--exact-match")
	cmd.Dir = workDir

	output, err = cmd.Output()
	if err == nil {
		tag := strings.TrimSpace(string(output))
		if tag != "" {
			return fmt.Sprintf("tag:%s", tag)
		}
	}

	// Try git rev-parse for commit hash
	cmd = exec.Command("git", "rev-parse", "--short", "HEAD")
	cmd.Dir = workDir

	output, err = cmd.Output()
	if err == nil {
		hash := strings.TrimSpace(string(output))
		if hash != "" {
			return fmt.Sprintf("detached:%s", hash)
		}
	}

	return "No Git"
}
