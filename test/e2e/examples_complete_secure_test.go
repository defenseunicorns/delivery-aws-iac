package e2e_test

import (
	"os/exec"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/defenseunicorns/delivery_aws_iac_utils/pkg/utils"
)

// This test deploys the complete example in govcloud, "secure mode". Secure mode is:
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
	// Setup options
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
			".*": "Failed to apply Terraform configuration due to an error.",
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
			".*": "Failed to apply Terraform configuration due to an error.",
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
			".*": "Failed to apply Terraform configuration due to an error.",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 5 * time.Second,
	}

	// Defer the teardown
	defer func() {
		t.Helper()
		teststructure.RunTestStage(t, "TEARDOWN", func() {
			terraformOutputOptions := &terraform.Options{
				TerraformDir: tempFolder,
				Logger:       logger.Discard,
			}
			_, outputBastionInstanceIDErr := terraform.OutputE(t, terraformOutputOptions, "bastion_instance_id")
			// We are intentionally using `assert` here and not `require`. We want the rest of this function to run even if there are errors.
			assert.NoError(t, outputBastionInstanceIDErr)
			_, outputVpcCidrErr := terraform.OutputE(t, terraformOutputOptions, "vpc_cidr")
			assert.NoError(t, outputVpcCidrErr)
			_, outputBastionRegionErr := terraform.OutputE(t, terraformOutputOptions, "bastion_region")
			assert.NoError(t, outputBastionRegionErr)
			if outputBastionInstanceIDErr == nil && outputVpcCidrErr == nil && outputBastionRegionErr == nil {
				// We can only destroy using sshuttle if the bastion exists and is functional. If we get, for example, an error saying there is not enough capacity in the chosen AZ, the bastion will have never been deployed and this will fail because `terraform output` didn't return anything.
				err := utils.DestroyWithSshuttle(t, terraformOptionsWithEKSTarget)
				assert.NoError(t, err)
			}
			terraform.Destroy(t, terraformOptionsNoTargets)
		})
	}()

	// Deploy the infra
	teststructure.RunTestStage(t, "SETUP", func() {
		terraform.Init(t, terraformInitOptions)
		terraform.Apply(t, terraformOptionsWithVPCAndBastionTargets)
		err := utils.ApplyWithSshuttle(t, terraformOptionsNoTargets)
		require.NoError(t, err)
	})

	// Run assertions
	teststructure.RunTestStage(t, "TEST", func() {
		// Start sshuttle
		cmd, err := utils.RunSshuttleInBackground(t, tempFolder)
		require.NoError(t, err)
		defer func(t *testing.T, cmd *exec.Cmd) {
			t.Helper()
			err := utils.StopSshuttle(t, cmd)
			require.NoError(t, err)
		}(t, cmd)
		utils.ValidateEFSFunctionality(t, tempFolder)
		utils.DownloadZarfInitPackage(t)
		utils.ConfigureKubeconfig(t, tempFolder)
		utils.ValidateZarfInit(t, tempFolder)
	})
}
