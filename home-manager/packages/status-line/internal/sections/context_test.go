package sections

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/jhivandb/status-line/internal/api"
)

func writeTranscript(t *testing.T, lines ...string) string {
	t.Helper()

	path := filepath.Join(t.TempDir(), "transcript.jsonl")
	if err := os.WriteFile(path, []byte(strings.Join(lines, "\n")+"\n"), 0o600); err != nil {
		t.Fatalf("writing transcript: %v", err)
	}
	return path
}

func assistantLine(input, cacheCreation, cacheRead, output int) string {
	return fmt.Sprintf(
		`{"type":"assistant","message":{"usage":{"input_tokens":%d,"cache_creation_input_tokens":%d,"cache_read_input_tokens":%d,"output_tokens":%d}}}`,
		input, cacheCreation, cacheRead, output)
}

// hugeToolResultLine mimics a real transcript line carrying a whole file read.
// Lines like this routinely exceed bufio.Scanner's 64KB default line cap.
func hugeToolResultLine(bytes int) string {
	return fmt.Sprintf(`{"type":"user","message":{"content":"%s"}}`, strings.Repeat("x", bytes))
}

func TestCalculateTokenUsageCountsLatestAssistantMessage(t *testing.T) {
	path := writeTranscript(t,
		assistantLine(1, 2, 3, 4),
		assistantLine(2, 300, 279085, 456),
	)

	got := calculateTokenUsage(api.InputData{TranscriptPath: path})

	if want := 279843; got != want {
		t.Errorf("calculateTokenUsage() = %d, want %d", got, want)
	}
}

func TestCalculateTokenUsageSurvivesLinesOverScannerCap(t *testing.T) {
	path := writeTranscript(t,
		hugeToolResultLine(200_000),
		assistantLine(2, 300, 279085, 456),
	)

	got := calculateTokenUsage(api.InputData{TranscriptPath: path})

	if want := 279843; got != want {
		t.Errorf("calculateTokenUsage() = %d, want %d — an oversized line must not zero the count", got, want)
	}
}

func TestCalculateTokenUsageIgnoresTrailingNonAssistantEntries(t *testing.T) {
	path := writeTranscript(t,
		assistantLine(2, 300, 279085, 456),
		`{"type":"user","message":{"content":"hi"}}`,
		`{"type":"file-history-snapshot"}`,
		`not json at all`,
	)

	got := calculateTokenUsage(api.InputData{TranscriptPath: path})

	if want := 279843; got != want {
		t.Errorf("calculateTokenUsage() = %d, want %d", got, want)
	}
}

func TestCalculateTokenUsageWithoutTranscript(t *testing.T) {
	if got := calculateTokenUsage(api.InputData{}); got != 0 {
		t.Errorf("calculateTokenUsage() = %d, want 0 for empty path", got)
	}

	missing := filepath.Join(t.TempDir(), "nope.jsonl")
	if got := calculateTokenUsage(api.InputData{TranscriptPath: missing}); got != 0 {
		t.Errorf("calculateTokenUsage() = %d, want 0 for missing file", got)
	}
}

func TestFormatSize(t *testing.T) {
	cases := []struct {
		size int
		want string
	}{
		{0, "0"},
		{999, "999"},
		{1000, "1.0K"},
		{1543, "1.5K"},
		{1999, "2.0K"},
		{2000, "2.0K"},
		{279843, "279.8K"},
	}

	for _, c := range cases {
		if got := formatSize(c.size); got != c.want {
			t.Errorf("formatSize(%d) = %q, want %q", c.size, got, c.want)
		}
	}
}
