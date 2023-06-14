package e2e_test

import (
	"github.com/gruntwork-io/terratest/modules/terraform"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"testing"
)

func TestExamplesVariable(t *testing.T) {
	t.Parallel()
	tempFolder := teststructure.CopyTerraformFolderToTemp(t, "../..", "examples/complete")
	terraformOptionsPlan := &terraform.Options{
		TerraformDir: tempFolder,
		Upgrade:      false,
		VarFiles: []string{
			"fixtures.common.tfvars",
			"fixtures.insecure.tfvars",
		},
		// Set any overrides for variables you would like to validate
		Vars: map[string]interface{}{
			"keycloak_enabled": false,
		},
		SetVarsAfterVarFiles: true,
	}
	teststructure.RunTestStage(t, "TERRAFORM_INIT", func() {
		terraform.Init(t, terraformOptionsPlan)
	})
	// Run `terraform plan` with the specified variable
	teststructure.RunTestStage(t, "TERRAFORM_PLAN", func() {
		terraform.Plan(t, terraformOptionsPlan)
	})
}
