package e2e_test

import (
	// "os/exec"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"

	// "github.com/stretchr/testify/require"

	"github.com/defenseunicorns/delivery_aws_iac_utils/pkg/utils"
)

// This test deploys the complete example in govcloud, "secure mode". Secure mode is:
// 1. In govcloud
// 2. With dedicated tenancy
// 3. With the eks endpoint in private mode
func TestExamplesCompleteSecure(t *testing.T) {
	t.Parallel()

	// Set the TF_VAR_region to us-gov-west-1 if it's not already set
	utils.SetDefaultEnvVar("TF_VAR_region", "us-gov-west-1")

	tempFolder := teststructure.CopyTerraformFolderToTemp(t, "../..", "examples/complete")
	terraformOptions := &terraform.Options{
		TerraformDir: tempFolder,
		Upgrade:      false,
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

	// Defer the teardown
	defer func() {
		t.Helper()
		teststructure.RunTestStage(t, "TEARDOWN", func() {
			terraform.Destroy(t, terraformOptions)
		})
	}()

	// Set up the infra
	teststructure.RunTestStage(t, "SETUP", func() {
		terraform.InitAndApply(t, terraformOptions)
	})

	// Run assertions
	teststructure.RunTestStage(t, "TEST", func() {
		// // Start sshuttle
		// cmd, err := utils.RunSshuttleInBackground(t, tempFolder)
		// require.NoError(t, err)
		// defer func(t *testing.T, cmd *exec.Cmd) {
		// 	t.Helper()
		// 	err := utils.StopSshuttle(t, cmd)
		// 	require.NoError(t, err)
		// }(t, cmd)
		// utils.ValidateEFSFunctionality(t, tempFolder)
		// utils.DownloadZarfInitPackage(t)
		// utils.ConfigureKubeconfig(t, tempFolder)
		// utils.ValidateZarfInit(t, tempFolder)
	})
}
