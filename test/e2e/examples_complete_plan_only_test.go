package e2e_test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestExamplesCompletePlanOnly(t *testing.T) {
	t.Parallel()
	exampleDir := os.Getenv("EXAMPLE_DIR")
	if exampleDir == "" {
		exampleDir = ExampleDirDefault // Default value if not set
	}
	tempFolder := teststructure.CopyTerraformFolderToTemp(t, "../..", exampleDir)
	terraformOptionsPlan := &terraform.Options{
		TerraformDir: tempFolder,
		Upgrade:      false,
		VarFiles: []string{
			"fixtures.common.tfvars",
			"fixtures.insecure.tfvars",
		},
		// Set any overrides for variables you would like to validate
		Vars: map[string]interface{}{
			"enable_password_rotation_lambda": false,
		},
		SetVarsAfterVarFiles: true,
	}
	teststructure.RunTestStage(t, "SETUP", func() {
		terraform.Init(t, terraformOptionsPlan)
		terraform.Plan(t, terraformOptionsPlan)
	})
}
