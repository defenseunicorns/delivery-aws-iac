package e2e_test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestExamplesCompleteInsecure(t *testing.T) {
	t.Parallel()
	tempFolder := teststructure.CopyTerraformFolderToTemp(t, "../..", "examples/complete")
	terraformOptions := &terraform.Options{
		TerraformDir: tempFolder,
		Upgrade:      false,
		VarFiles: []string{
			"fixtures.common.tfvars",
			"fixtures.insecure.tfvars",
		},
	}
	defer teardownTestExamplesCompleteInsecure(t, terraformOptions)
	setupTestExamplesCompleteInsecure(t, terraformOptions)
}

func setupTestExamplesCompleteInsecure(t *testing.T, terraformOptions *terraform.Options) {
	t.Helper()
	teststructure.RunTestStage(t, "SETUP", func() {
		terraform.InitAndApply(t, terraformOptions)
	})
}

func teardownTestExamplesCompleteInsecure(t *testing.T, terraformOptions *terraform.Options) {
	t.Helper()
	teststructure.RunTestStage(t, "TEARDOWN", func() {
		terraform.Destroy(t, terraformOptions)
	})
}
