package e2e_test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"
)

// This test deploys the complete example in govcloud, "secure mode". Secure mode is:
// - Self-managed nodegroups only
// - Dedicated instance tenancy
// - EKS public endpoint disabled.
func TestExamplesCompleteSecure(t *testing.T) {
	t.Parallel()
	// Setup options
	tempFolder := teststructure.CopyTerraformFolderToTemp(t, "../..", "examples/complete")
	terraformOptions := &terraform.Options{
		TerraformBinary: "tofu",
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

	// Defer the teardown
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

	// // Run assertions
	// add tests here to do stuff to the cluster with sshuttle because the public endpoint is disabled

	// teststructure.RunTestStage(t, "TEST", func() {
	// 	// Start sshuttle
	// 	cmd, err := utils.RunSshuttleInBackground(t, tempFolder)
	// 	require.NoError(t, err)
	// 	defer func(t *testing.T, cmd *exec.Cmd) {
	// 		t.Helper()
	// 		err := utils.StopSshuttle(t, cmd)
	// 		require.NoError(t, err)
	// 	}(t, cmd)
	// 	utils.ValidateEFSFunctionality(t, tempFolder)
	// 	utils.DownloadZarfInitPackage(t)
	// 	utils.ConfigureKubeconfig(t, tempFolder)
	// 	utils.ValidateZarfInit(t, tempFolder)
	// })
}
