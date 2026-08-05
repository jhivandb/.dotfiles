package sections

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/jhivandb/status-line/internal/api"
)

type Context struct {
	config string
	In     api.InputData
}

func (ctx *Context) Render() string {
	tokens := calculateTokenUsage(ctx.In)
	contextColor := api.ColorLightGreen
	if tokens > 90000 {
		contextColor = api.ColorPink
	}

	return fmt.Sprintf("%s%s", contextColor, formatSize(tokens))
}

// calculateTokenUsage scans the transcript for the most recent assistant message
// carrying token usage, and returns its total (input + cache creation + cache
// read + output tokens).
func calculateTokenUsage(in api.InputData) int {
	if in.TranscriptPath == "" {
		return 0
	}

	file, err := os.Open(in.TranscriptPath)
	if err != nil {
		return 0
	}
	defer file.Close()

	// A single transcript line holds a whole tool result and regularly runs past
	// bufio.Scanner's 64KB line cap, so read with a Reader that grows instead.
	reader := bufio.NewReader(file)
	latest := 0
	for {
		line, readErr := reader.ReadString('\n')
		if total, ok := assistantTokenTotal(line); ok {
			latest = total
		}
		if readErr != nil {
			return latest
		}
	}
}

// assistantTokenTotal reports a transcript line's combined token count, and
// whether the line was an assistant message carrying usage at all.
func assistantTokenTotal(line string) (int, bool) {
	line = strings.TrimSpace(line)
	if line == "" {
		return 0, false
	}

	var entry api.TranscriptEntry
	if err := json.Unmarshal([]byte(line), &entry); err != nil {
		return 0, false
	}
	if entry.Type != "assistant" {
		return 0, false
	}

	usage := entry.Message.Usage
	total := usage.InputTokens + usage.CacheCreationInputTokens +
		usage.CacheReadInputTokens + usage.OutputTokens

	return total, total > 0
}

func formatSize(size int) string {
	const (
		K = 1000
	)

	switch {
	case size >= K:
		return fmt.Sprintf("%.1fK", float64(size)/K)
	default:
		return fmt.Sprintf("%d", size)
	}
}
