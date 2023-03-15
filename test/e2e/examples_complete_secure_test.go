package test_test

import (
	"github.com/gruntwork-io/terratest/modules/terraform"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"testing"
)

// To run this test, we first have to apply with the EKS public endpoint on, then apply again to turn the endpoint off. When destroying we need to do the opposite.
func TestExamplesCompleteSecure(t *testing.T) {
	t.Parallel()
	tempFolder := teststructure.CopyTerraformFolderToTemp(t, "../..", "examples/complete")
	terraformOptionsWithPublicEndpointOn := &terraform.Options{
		TerraformDir: tempFolder,
		Upgrade:      false,
		VarFiles: []string{
			"fixtures.common.tfvars",
			"fixtures.secure.tfvars",
			"fixtures.eks-public-endpoint-on.tfvars",
		},
	}
	terraformOptionsWithPublicEndpointOff := &terraform.Options{
		TerraformDir: tempFolder,
		Upgrade:      false,
		VarFiles: []string{
			"fixtures.common.tfvars",
			"fixtures.secure.tfvars",
			"fixtures.eks-public-endpoint-off.tfvars",
		},
	}
	defer teardownTestExamplesCompleteSecure(t, terraformOptionsWithPublicEndpointOn)
	setupTestExamplesCompleteSecure(t, terraformOptionsWithPublicEndpointOn, terraformOptionsWithPublicEndpointOff)
}

func setupTestExamplesCompleteSecure(t *testing.T, terraformOptionsWithPublicEndpointOn *terraform.Options, terraformOptionsWithPublicEndpointOff *terraform.Options) {
	t.Helper()
	teststructure.RunTestStage(t, "SETUP", func() {
		terraform.InitAndApply(t, terraformOptionsWithPublicEndpointOn)
		terraform.InitAndApply(t, terraformOptionsWithPublicEndpointOff)
	})
}

func teardownTestExamplesCompleteSecure(t *testing.T, terraformOptionsWithPublicEndpointOn *terraform.Options) {
	t.Helper()
	teststructure.RunTestStage(t, "TEARDOWN", func() {
		terraform.InitAndApply(t, terraformOptionsWithPublicEndpointOn)
		terraform.Destroy(t, terraformOptionsWithPublicEndpointOn)
	})
}
