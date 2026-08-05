package sections

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/jhivandb/status-line/internal/api"
)

func initRepo(t *testing.T) string {
	t.Helper()

	root := t.TempDir()
	cmd := exec.Command("git", "init", "--initial-branch=main")
	cmd.Dir = root
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Skipf("git init unavailable: %v: %s", err, out)
	}
	return root
}

func TestGetGitBranchAtRepoRoot(t *testing.T) {
	root := initRepo(t)

	got := getGitBranch(api.InputData{Workspace: api.Workspace{CurrentDir: root}})

	if !strings.HasSuffix(got, "main") {
		t.Errorf("getGitBranch() = %q, want a value ending in %q", got, "main")
	}
}

func TestGetGitBranchFromSubdirectory(t *testing.T) {
	root := initRepo(t)
	nested := filepath.Join(root, "internal", "sections")
	if err := os.MkdirAll(nested, 0o755); err != nil {
		t.Fatalf("creating nested dir: %v", err)
	}

	got := getGitBranch(api.InputData{Workspace: api.Workspace{CurrentDir: nested}})

	if !strings.HasSuffix(got, "main") {
		t.Errorf("getGitBranch() = %q, want a value ending in %q — a subdirectory is still inside the repo", got, "main")
	}
}

func TestGetGitBranchOutsideRepo(t *testing.T) {
	got := getGitBranch(api.InputData{Workspace: api.Workspace{CurrentDir: t.TempDir()}})

	if got != "No Git" {
		t.Errorf("getGitBranch() = %q, want %q", got, "No Git")
	}
}

func TestGetGitBranchFallsBackToCWD(t *testing.T) {
	root := initRepo(t)

	got := getGitBranch(api.InputData{CWD: root})

	if !strings.HasSuffix(got, "main") {
		t.Errorf("getGitBranch() = %q, want a value ending in %q", got, "main")
	}
}

func TestGetGitBranchWithoutDirectory(t *testing.T) {
	if got := getGitBranch(api.InputData{}); got != "No Git" {
		t.Errorf("getGitBranch() = %q, want %q", got, "No Git")
	}

	missing := filepath.Join(t.TempDir(), "gone")
	if got := getGitBranch(api.InputData{CWD: missing}); got != "No Git" {
		t.Errorf("getGitBranch() = %q, want %q for a nonexistent directory", got, "No Git")
	}
}
