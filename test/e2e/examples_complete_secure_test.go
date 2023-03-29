package e2e_test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/terraform"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"os/exec"
	"testing"
)

// This test deploys the complete example in "secure mode". Secure mode is:
// - Self-managed nodegroups only
// - Dedicated instance tenancy
// - EKS public endpoint disabled
// Sequence of events:
// 1. Deploy the VPC and Bastion
// 2. With Sshuttle tunneling to the bastion, deploy the EKS cluster
// 3. Wait 30 seconds
// 4. With Sshuttle tunneling to the bastion, deploy the rest of the example
// 5. With Sshuttle tunneling to the bastion, destroy EKS cluster
// 6. Destroy the rest of the example
// Notes:
// - Steps 2 and 3 wouldn't normally be necessary, but we have an issue with Terraform trying to deploy stuff to the EKS cluster before it is ready. Separating out deployment of the EKS cluster and everything that goes into the EKS cluster gives the cluster a bit more time to be ready to accept deployments to it.
func TestExamplesCompleteSecure(t *testing.T) {
	t.Parallel()
	tempFolder := teststructure.CopyTerraformFolderToTemp(t, "../..", "examples/complete")
	terraformOptionsNoTargets := &terraform.Options{
		TerraformDir: tempFolder,
		Upgrade:      false,
		VarFiles: []string{
			"fixtures.common.tfvars",
			"fixtures.secure.tfvars",
		},
	}
	terraformOptionsWithVPCAndBastionTargets := &terraform.Options{
		TerraformDir: tempFolder,
		Upgrade:      false,
		VarFiles: []string{
			"fixtures.common.tfvars",
			"fixtures.secure.tfvars",
		},
		Targets: []string{
			"module.vpc",
			"module.bastion",
		},
	}
	// terraformOptionsWithVPCAndBastionAndEKSTargets := &terraform.Options{
	// 	TerraformDir: tempFolder,
	// 	Upgrade:      false,
	// 	VarFiles: []string{
	// 		"fixtures.common.tfvars",
	// 		"fixtures.secure.tfvars",
	// 	},
	// 	Targets: []string{
	// 		"module.vpc",
	// 		"module.bastion",
	// 		"module.eks",
	// 	},
	// }
	terraformOptionsWithEKSTarget := &terraform.Options{
		TerraformDir: tempFolder,
		Upgrade:      false,
		VarFiles: []string{
			"fixtures.common.tfvars",
			"fixtures.secure.tfvars",
		},
		Targets: []string{
			"module.eks",
		},
	}
	defer func() {
		t.Helper()
		teststructure.RunTestStage(t, "TEARDOWN", func() {
			bastionInstanceID := terraform.Output(t, terraformOptionsWithEKSTarget, "bastion_instance_id")
			//nolint:godox
			// TODO: Figure out how to parse the input variables to get the bastion password rather than having to hardcode it
			bastionPassword := "my-password"
			vpcCidr := terraform.Output(t, terraformOptionsWithEKSTarget, "vpc_cidr")
			bastionRegion := terraform.Output(t, terraformOptionsWithEKSTarget, "bastion_region")
			err := destroyWithSshuttle(t, bastionInstanceID, bastionRegion, bastionPassword, vpcCidr, terraformOptionsWithEKSTarget)
			assert.NoError(t, err)
			terraform.Destroy(t, terraformOptionsNoTargets)
		})
	}()
	// setupTestExamplesCompleteSecure(t, terraformOptionsNoTargets, terraformOptionsWithVPCAndBastionTargets)
	teststructure.RunTestStage(t, "SETUP", func() {
		terraform.Init(t, terraformOptionsNoTargets)
		terraform.Apply(t, terraformOptionsWithVPCAndBastionTargets)
		bastionInstanceID := terraform.Output(t, terraformOptionsWithVPCAndBastionTargets, "bastion_instance_id")
		//nolint:godox
		// TODO: Figure out how to parse the input variables to get the bastion password rather than having to hardcode it
		bastionPassword := "my-password"
		vpcCidr := terraform.Output(t, terraformOptionsWithVPCAndBastionTargets, "vpc_cidr")
		bastionRegion := terraform.Output(t, terraformOptionsWithVPCAndBastionTargets, "bastion_region")
		// err := applyWithSshuttle(t, bastionInstanceID, bastionRegion, bastionPassword, vpcCidr, terraformOptionsWithVPCAndBastionAndEKSTargets)
		// require.NoError(t, err)
		// time.Sleep(3 * time.Minute)
		err := applyWithSshuttle(t, bastionInstanceID, bastionRegion, bastionPassword, vpcCidr, terraformOptionsNoTargets)
		require.NoError(t, err)
	})
}

func applyWithSshuttle(t *testing.T, bastionInstanceID string, bastionRegion string, bastionPassword string, vpcCidr string, terraformOptions *terraform.Options) error {
	t.Helper()
	cmd, err := runSshuttleInBackground(t, bastionInstanceID, bastionRegion, bastionPassword, vpcCidr)
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

func destroyWithSshuttle(t *testing.T, bastionInstanceID string, bastionRegion string, bastionPassword string, vpcCidr string, terraformOptions *terraform.Options) error {
	t.Helper()
	cmd, err := runSshuttleInBackground(t, bastionInstanceID, bastionRegion, bastionPassword, vpcCidr)
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

func runSshuttleInBackground(t *testing.T, bastionInstanceID string, bastionRegion string, bastionPassword string, vpcCidr string) (*exec.Cmd, error) {
	t.Helper()
	cmd := exec.Command("sshuttle", "-e", fmt.Sprintf(`sshpass -p "%s" ssh -q -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="aws ssm --region '%s' start-session --target %%h --document-name AWS-StartSSHSession --parameters 'portNumber=%%p'"`, bastionPassword, bastionRegion), "--dns", "--disable-ipv6", "-vr", fmt.Sprintf("ec2-user@%s", bastionInstanceID), vpcCidr) //nolint:gosec
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("failed to start sshuttle: %w", err)
	}
	return cmd, nil
}

func stopSshuttle(t *testing.T, cmd *exec.Cmd) error {
	t.Helper()
	if err := cmd.Process.Kill(); err != nil {
		return fmt.Errorf("failed to stop sshuttle: %w", err)
	}
	return nil
}
