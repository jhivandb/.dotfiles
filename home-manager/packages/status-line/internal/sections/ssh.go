package sections

import (
	"fmt"
	"os"

	"github.com/jhivandb/status-line/internal/api"
)

type SSH struct{}

func (s *SSH) Render() string {
	if os.Getenv("SSH_CONNECTION") == "" && os.Getenv("SSH_TTY") == "" {
		return ""
	}
	host, err := os.Hostname()
	if err != nil {
		return ""
	}
	return fmt.Sprintf("%s %s", api.ColorYellow, host)
}
