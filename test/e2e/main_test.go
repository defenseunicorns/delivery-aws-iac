package e2e_test

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"
)

// TestMain is the entry point for all tests. We are using a custom one so that we can log a message to the console every few seconds. Without this there is a risk of GitHub Actions killing the test run if it believes it is hung.
func TestMain(m *testing.M) {
	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			default:
				doLog("The test is still running! Don't kill me!")
			}
			time.Sleep(10 * time.Second)
		}
	}()
	exitVal := m.Run()
	cancel()
	os.Exit(exitVal)
}

// doLog logs the given arguments to the given writer, along with a timestamp.
func doLog(args ...interface{}) {
	date := time.Now()
	prefix := fmt.Sprintf("%s:", date.Format(time.RFC3339))
	allArgs := append([]interface{}{prefix}, args...)
	fmt.Println(allArgs...) //nolint:forbidigo
}
