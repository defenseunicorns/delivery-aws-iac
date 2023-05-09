package e2e_test

import (
	"fmt"
	"os/exec"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// This test deploys the complete example in "secure mode". Secure mode is:
// - Self-managed nodegroups only
// - Dedicated instance tenancy
// - EKS public endpoint disabled
// Sequence of events:
// 1. Deploy the VPC and Bastion.
// 2. With Sshuttle tunneling to the bastion, deploy the rest of the example.
// 3. With Sshuttle tunneling to the bastion, destroy EKS cluster.
// 4. Destroy the rest of the example.
func TestExamplesCompleteSecure(t *testing.T) {
	t.Parallel()
	tempFolder := teststructure.CopyTerraformFolderToTemp(t, "../..", "examples/complete")
	terraformInitOptions := &terraform.Options{
		TerraformDir: tempFolder,
		Upgrade:      false,
	}
	terraformOptionsNoTargets := &terraform.Options{
		TerraformDir: tempFolder,
		VarFiles: []string{
			"fixtures.common.tfvars",
			"fixtures.secure.tfvars",
		},
		RetryableTerraformErrors: map[string]string{
			".*empty output.*": "bug in aws_s3_bucket_logging, intermittent error",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 5 * time.Second,
	}
	terraformOptionsWithVPCAndBastionTargets := &terraform.Options{
		TerraformDir: tempFolder,
		VarFiles: []string{
			"fixtures.common.tfvars",
			"fixtures.secure.tfvars",
		},
		Targets: []string{
			"module.vpc",
			"module.bastion",
		},
		RetryableTerraformErrors: map[string]string{
			".*empty output.*": "bug in aws_s3_bucket_logging, intermittent error",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 5 * time.Second,
	}
	terraformOptionsWithEKSTarget := &terraform.Options{
		TerraformDir: tempFolder,
		VarFiles: []string{
			"fixtures.common.tfvars",
			"fixtures.secure.tfvars",
		},
		Targets: []string{
			"module.eks",
		},
		RetryableTerraformErrors: map[string]string{
			".*empty output.*": "bug in aws_s3_bucket_logging, intermittent error",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 5 * time.Second,
	}
	terraformOutputOptions := &terraform.Options{
		TerraformDir: tempFolder,
		Logger:       logger.Discard,
	}
	defer func() {
		t.Helper()
		teststructure.RunTestStage(t, "TEARDOWN", func() {
			bastionInstanceID, outputBastionInstanceIDErr := terraform.OutputE(t, terraformOutputOptions, "bastion_instance_id")
			bastionPrivateDNS := terraform.Output(t, terraformOutputOptions, "bastion_private_dns")
			// We are intentionally using `assert` here and not `require`. We want the rest of this function to run even if there are errors.
			assert.NoError(t, outputBastionInstanceIDErr)
			//nolint:godox
			// TODO: Figure out how to parse the input variables to get the bastion password rather than having to hardcode it
			bastionPassword := "my-password"
			vpcCidr, outputVpcCidrErr := terraform.OutputE(t, terraformOutputOptions, "vpc_cidr")
			assert.NoError(t, outputVpcCidrErr)
			bastionRegion, outputBastionRegionErr := terraform.OutputE(t, terraformOutputOptions, "bastion_region")
			assert.NoError(t, outputBastionRegionErr)
			if outputBastionInstanceIDErr == nil && outputVpcCidrErr == nil && outputBastionRegionErr == nil {
				// We can only destroy using sshuttle if the bastion exists and is functional. If we get, for example, an error saying there is not enough capacity in the chosen AZ, the bastion will have never been deployed and this will fail because `terraform output` didn't return anything.
				err := destroyWithSshuttle(t, bastionInstanceID, bastionPrivateDNS, bastionRegion, bastionPassword, vpcCidr, terraformOptionsWithEKSTarget)
				assert.NoError(t, err)
			}
			terraform.Destroy(t, terraformOptionsNoTargets)
		})
	}()
	// setupTestExamplesCompleteSecure(t, terraformOptionsNoTargets, terraformOptionsWithVPCAndBastionTargets)
	teststructure.RunTestStage(t, "SETUP", func() {
		terraform.Init(t, terraformInitOptions)
		terraform.Apply(t, terraformOptionsWithVPCAndBastionTargets)
		bastionInstanceID := terraform.Output(t, terraformOutputOptions, "bastion_instance_id")
		bastionPrivateDNS := terraform.Output(t, terraformOutputOptions, "bastion_private_dns")
		//nolint:godox
		// TODO: Figure out how to parse the input variables to get the bastion password rather than having to hardcode it
		bastionPassword := "my-password"
		vpcCidr := terraform.Output(t, terraformOutputOptions, "vpc_cidr")
		bastionRegion := terraform.Output(t, terraformOutputOptions, "bastion_region")
		err := applyWithSshuttle(t, bastionInstanceID, bastionPrivateDNS, bastionRegion, bastionPassword, vpcCidr, terraformOptionsNoTargets)
		require.NoError(t, err)
	})
}

func applyWithSshuttle(t *testing.T, bastionInstanceID string, bastionPrivateDNS string, bastionRegion string, bastionPassword string, vpcCidr string, terraformOptions *terraform.Options) error {
	t.Helper()
	cmd, err := runSshuttleInBackground(t, bastionInstanceID, bastionPrivateDNS, bastionRegion, bastionPassword, vpcCidr)
	if err != nil {
		return err
	}
	defer func(t *testing.T, cmd *exec.Cmd) {
		t.Helper()
		err := stopSshuttle(t, cmd)
		require.NoError(t, err)
	}(t, cmd)
	terraform.Apply(t, terraformOptions)
	return nil
}

func destroyWithSshuttle(t *testing.T, bastionInstanceID string, bastionPrivateDNS string, bastionRegion string, bastionPassword string, vpcCidr string, terraformOptions *terraform.Options) error {
	t.Helper()
	cmd, err := runSshuttleInBackground(t, bastionInstanceID, bastionPrivateDNS, bastionRegion, bastionPassword, vpcCidr)
	if err != nil {
		return err
	}
	defer func(t *testing.T, cmd *exec.Cmd) {
		t.Helper()
		err := stopSshuttle(t, cmd)
		require.NoError(t, err)
	}(t, cmd)
	terraform.Destroy(t, terraformOptions)
	return nil
}

func runSshuttleInBackground(t *testing.T, bastionInstanceID string, bastionPrivateDNS string, bastionRegion string, bastionPassword string, vpcCidr string) (*exec.Cmd, error) {
	t.Helper()
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
		time.Sleep(20 * time.Second) // It takes a few seconds for sshuttle to start up
		curlCmd := exec.Command("curl", "-v", bastionPrivateDNS)
		// We don't care about the output, just the exit code. Since we are looking for exit code 52, we should expect an error here.
		err = curlCmd.Run()
		if err != nil {
			doLog(err)
		}
		if curlCmd.ProcessState.ExitCode() == 52 {
			// Success! sshuttle is working.
			return sshuttleCmd, nil
		}
		// Failure. Try again.
		doLog(fmt.Sprintf("sshuttle failed to start up. Retrying... (attempt %d of %d)", i+1, retryAttempts))
		err = stopSshuttle(t, sshuttleCmd)
		if err != nil {
			doLog(err)
		}
	}
	// If we get here, we got through our for loop without verifying that sshuttle was working, so we should stop it and return an error.
	err := stopSshuttle(t, sshuttleCmd)
	if err != nil {
		doLog(err)
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

func stopSshuttle(t *testing.T, cmd *exec.Cmd) error {
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
