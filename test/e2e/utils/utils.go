// Package utils is a package that contains utility functions for the e2e tests.
package utils

import (
	"encoding/base64"
	"fmt"
	"os/exec"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/eks"
	"github.com/stretchr/testify/require"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"sigs.k8s.io/aws-iam-authenticator/pkg/token"
)

// DoLog logs the given arguments to the given writer, along with a timestamp.
func DoLog(args ...interface{}) {
	date := time.Now()
	prefix := fmt.Sprintf("%s:", date.Format(time.RFC3339))
	allArgs := append([]interface{}{prefix}, args...)
	fmt.Println(allArgs...) //nolint:forbidigo
}

// NewK8sClientset returns a new kubernetes clientset for the given cluster.
func NewK8sClientset(cluster *eks.Cluster) (*kubernetes.Clientset, error) {
	gen, err := token.NewGenerator(true, false)
	if err != nil {
		return nil, fmt.Errorf("failed to create token generator: %w", err)
	}
	opts := &token.GetTokenOptions{
		ClusterID: aws.StringValue(cluster.Name),
	}
	tok, err := gen.GetWithOptions(opts)
	if err != nil {
		return nil, fmt.Errorf("failed to create token: %w", err)
	}
	ca, err := base64.StdEncoding.DecodeString(aws.StringValue(cluster.CertificateAuthority.Data))
	if err != nil {
		return nil, fmt.Errorf("failed to decode string: %w", err)
	}
	clientset, err := kubernetes.NewForConfig(
		&rest.Config{
			Host:        aws.StringValue(cluster.Endpoint),
			BearerToken: tok.Token,
			TLSClientConfig: rest.TLSClientConfig{
				CAData: ca,
			},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create clientset: %w", err)
	}
	return clientset, nil
}

// InstallZarf installs Zarf
func InstallZarf(t *testing.T) {
	t.Helper()
	// Add Zarf plugin for asdf
	err := exec.Command("bash", "-c", "asdf plugin add zarf https://github.com/defenseunicorns/asdf-zarf.git || true").Run()
	require.NoError(t, err)
	// Install Zarf
	err = exec.Command("bash", "-c", "asdf install zarf latest").Run()
	require.NoError(t, err)
	err = exec.Command("bash", "-c", "mkdir -p ~/.zarf-cache").Run()
	require.NoError(t, err)
	err = exec.Command("bash", "-c", `VERSION=$(zarf version); URL=https://github.com/defenseunicorns/zarf/releases/download/${VERSION}/zarf-init-amd64-${VERSION}.tar.zst; TARGET=~/.zarf-cache/zarf-init-amd64-${VERSION}.tar.zst; curl -L $URL -o $TARGET`).Run()
	require.NoError(t, err)
}
