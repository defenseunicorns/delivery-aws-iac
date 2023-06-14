// Package utils is a package that contains utility functions for the e2e tests.
package utils

import (
	"context"
	"encoding/base64"
	"fmt"
	"os/exec"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/eks"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	batchv1 "k8s.io/api/batch/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/wait"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"sigs.k8s.io/aws-iam-authenticator/pkg/token"
)

// TODO: Figure out how to parse the input variables to get the bastion password rather than having to hardcode it.
//
//nolint:godox
const bastionPassword = "my-password"

// DoLog logs the given arguments to the given writer, along with a timestamp.
func DoLog(args ...interface{}) {
	date := time.Now()
	prefix := fmt.Sprintf("%s:", date.Format(time.RFC3339))
	allArgs := append([]interface{}{prefix}, args...)
	fmt.Println(allArgs...) //nolint:forbidigo
}

// GetEKSCluster returns the EKS cluster for the given terraform folder.
func GetEKSCluster(t *testing.T, tempFolder string) (*eks.Cluster, error) {
	t.Helper()
	terraformOutputOptions := &terraform.Options{
		TerraformDir: tempFolder,
		Logger:       logger.Discard,
	}
	// Get outputs
	bastionRegion := terraform.Output(t, terraformOutputOptions, "bastion_region")
	clusterName := terraform.Output(t, terraformOutputOptions, "eks_cluster_name")
	// Create the EKS clientset
	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(bastionRegion),
	}))
	eksSvc := eks.New(sess)
	input := &eks.DescribeClusterInput{Name: aws.String(clusterName)}
	result, err := eksSvc.DescribeCluster(input)
	if err != nil {
		return nil, fmt.Errorf("failed to describe cluster: %w", err)
	}
	return result.Cluster, nil
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

// ApplyWithSshuttle runs terraform apply with sshuttle running in the background.
func ApplyWithSshuttle(t *testing.T, terraformOptions *terraform.Options) error {
	t.Helper()
	cmd, err := RunSshuttleInBackground(t, terraformOptions.TerraformDir)
	if err != nil {
		return err
	}
	defer func(t *testing.T, cmd *exec.Cmd) {
		t.Helper()
		err := StopSshuttle(t, cmd)
		require.NoError(t, err)
	}(t, cmd)
	terraform.Apply(t, terraformOptions)
	return nil
}

// DestroyWithSshuttle runs terraform destroy with sshuttle running in the background.
func DestroyWithSshuttle(t *testing.T, terraformOptions *terraform.Options) error {
	t.Helper()
	cmd, err := RunSshuttleInBackground(t, terraformOptions.TerraformDir)
	if err != nil {
		return err
	}
	defer func(t *testing.T, cmd *exec.Cmd) {
		t.Helper()
		err := StopSshuttle(t, cmd)
		require.NoError(t, err)
	}(t, cmd)
	terraform.Destroy(t, terraformOptions)
	return nil
}

// RunSshuttleInBackground runs sshuttle in the background.
func RunSshuttleInBackground(t *testing.T, tempFolder string) (*exec.Cmd, error) {
	t.Helper()
	terraformOutputOptions := &terraform.Options{
		TerraformDir: tempFolder,
		Logger:       logger.Discard,
	}
	bastionInstanceID := terraform.Output(t, terraformOutputOptions, "bastion_instance_id")
	bastionPrivateDNS := terraform.Output(t, terraformOutputOptions, "bastion_private_dns")
	vpcCidr := terraform.Output(t, terraformOutputOptions, "vpc_cidr")
	bastionRegion := terraform.Output(t, terraformOutputOptions, "bastion_region")
	// Check that SShuttle is actually working by querying the bastion's private DNS, which will only work if sshuttle is working.
	// If it works, it will return exit code 52 ("Empty reply from server"). Failure will most likely result in exit code 28 ("Couldn't connect to server"), but any result other than exit code 52 should be treated as a failure.
	// We'll retry a few times in case the bastion is still starting up.
	retryAttempts := 25
	var sshuttleCmd *exec.Cmd
	for i := 0; i < retryAttempts; i++ {
		sshuttleCmd, err := startSshuttle(t, bastionInstanceID, bastionRegion, bastionPassword, vpcCidr)
		if err != nil {
			return nil, fmt.Errorf("failed to start sshuttle: %w", err)
		}

		// It takes a few seconds for sshuttle to start up
		time.Sleep(20 * time.Second)

		//nolint:gosec
		curlCmd := exec.Command("curl", "-v", bastionPrivateDNS)
		// We don't care about the output, just the exit code. Since we are looking for exit code 52, we should expect an error here.
		err = curlCmd.Run()
		if err != nil {
			DoLog(err)
		}
		if curlCmd.ProcessState.ExitCode() == 52 {
			// Success! sshuttle is working.
			return sshuttleCmd, nil
		}
		// Failure. Try again.
		DoLog(fmt.Sprintf("sshuttle failed to start up. Retrying... (attempt %d of %d)", i+1, retryAttempts))
		err = StopSshuttle(t, sshuttleCmd)
		if err != nil {
			DoLog(err)
		}
	}
	// If we get here, we got through our for loop without verifying that sshuttle was working, so we should stop it and return an error.
	err := StopSshuttle(t, sshuttleCmd)
	if err != nil {
		DoLog(err)
	}
	return nil, fmt.Errorf("failed to start sshuttle: could not verify that sshuttle was working")
}

func startSshuttle(t *testing.T, bastionInstanceID string, bastionRegion string, bastionPassword string, vpcCidr string) (*exec.Cmd, error) {
	t.Helper()
	cmd := exec.Command("sshuttle", "-e", fmt.Sprintf(`sshpass -p "%s" ssh -q -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="aws ssm --region '%s' start-session --target %%h --document-name AWS-StartSSHSession --parameters 'portNumber=%%p'"`, bastionPassword, bastionRegion), "--dns", "--disable-ipv6", "-vr", fmt.Sprintf("ec2-user@%s", bastionInstanceID), vpcCidr) //nolint:gosec
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("failed to start sshuttle: %w", err)
	}
	return cmd, nil
}

// StopSshuttle stops sshuttle.
func StopSshuttle(t *testing.T, cmd *exec.Cmd) error {
	t.Helper()
	if cmd == nil {
		return fmt.Errorf("failed to stop sshuttle: cmd is nil")
	}
	if cmd.Process == nil {
		return fmt.Errorf("failed to stop sshuttle: cmd.Process is nil")
	}
	if err := cmd.Process.Kill(); err != nil {
		return fmt.Errorf("failed to stop sshuttle: %w", err)
	}
	return nil
}

// ValidateEFSFunctionality idempotently validates that EFS functionality is working.
func ValidateEFSFunctionality(t *testing.T, tempFolder string) {
	t.Helper()
	terraformOutputOptions := &terraform.Options{
		TerraformDir: tempFolder,
		Logger:       logger.Discard,
	}
	// Validate that var.enable_efs was set to true, otherwise this will always fail. We'll do that by checking for the presence of the output "efs_storageclass_name".
	efsStorageClassName := terraform.Output(t, terraformOutputOptions, "efs_storageclass_name")
	require.NotNil(t, efsStorageClassName)
	require.NotEmpty(t, efsStorageClassName)

	// Get the cluster
	cluster, err := GetEKSCluster(t, tempFolder)
	require.NoError(t, err)
	clientset, err := NewK8sClientset(cluster)
	require.NoError(t, err)
	// Wait for the job "test-write" in the namespace "default" to complete, with a 2-minute timeout
	namespace := "default"
	jobName := "test-write"
	timeout := 2 * time.Minute
	// See https://github.com/kubernetes/kubernetes/issues/116712
	//nolint:staticcheck
	err = wait.PollImmediate(time.Second, timeout, func() (bool, error) {
		job, err := clientset.BatchV1().Jobs(namespace).Get(context.Background(), jobName, metav1.GetOptions{})
		if err != nil {
			return false, fmt.Errorf("failed to get kubernetes jobs: %w", err)
		}
		// Check the job's status
		for _, c := range job.Status.Conditions {
			if c.Type == batchv1.JobComplete && c.Status == "True" {
				return true, nil
			} else if c.Type == batchv1.JobFailed && c.Status == "True" {
				return false, fmt.Errorf("job failed")
			}
		}
		return false, nil
	})
	if err != nil {
		DoLog("Job did not complete in time: %v\n", err)
	} else {
		DoLog("Job completed successfully")
	}
	assert.NoError(t, err)
}

// DownloadZarfInitPackage idempotently downloads the Zarf init package if it doesn't already exist.
func DownloadZarfInitPackage(t *testing.T) {
	t.Helper()
	// Download the Zarf init package if it doesn't already exist
	err := exec.Command("bash", "-c", `VERSION=$(zarf version); URL=https://github.com/defenseunicorns/zarf/releases/download/${VERSION}/zarf-init-amd64-${VERSION}.tar.zst; TARGET=~/.zarf-cache/zarf-init-amd64-${VERSION}.tar.zst; mkdir -p ~/.zarf-cache; [ -f $TARGET ] || curl -L $URL -o $TARGET`).Run()
	require.NoError(t, err)
}

// ConfigureKubeconfig idempotently uses the AWS CLI to configure the user's kubeconfig file with the new EKS cluster.
func ConfigureKubeconfig(t *testing.T, tempFolder string) {
	t.Helper()
	terraformOutputOptions := &terraform.Options{
		TerraformDir: tempFolder,
		Logger:       logger.Discard,
	}
	eksClusterName := terraform.Output(t, terraformOutputOptions, "eks_cluster_name")
	region := terraform.Output(t, terraformOutputOptions, "bastion_region")
	err := exec.Command("bash", "-c", fmt.Sprintf("mkdir -p ~/.kube && aws eks update-kubeconfig --name %s --alias %s --region %s", eksClusterName, eksClusterName, region)).Run() //nolint:gosec
	require.NoError(t, err)
	// Make sure it worked. This command should return without error
	err = exec.Command("bash", "-c", "kubectl get nodes").Run()
	require.NoError(t, err)
}

// ValidateZarfInit idempotently ensures that zarf init runs successfully.
func ValidateZarfInit(t *testing.T, tempFolder string) {
	t.Helper()
	terraformOutputOptions := &terraform.Options{
		TerraformDir: tempFolder,
		Logger:       logger.Discard,
	}
	storageClassName := terraform.Output(t, terraformOutputOptions, "efs_storageclass_name")
	outputBytes, err := exec.Command("bash", "-c", fmt.Sprintf("zarf init --components=logging,git-server --confirm --no-log-file --no-progress --storage-class %s", storageClassName)).CombinedOutput() //nolint:gosec
	if err != nil {
		DoLog("zarf init failed: %v\n", err)
		DoLog("zarf init output: %s\n", string(outputBytes))
	}
	require.NoError(t, err)
}
