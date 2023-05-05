package e2e_test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestExamplesCompleteInsecure(t *testing.T) {
	t.Parallel()
	tempFolder := teststructure.CopyTerraformFolderToTemp(t, "../..", "examples/complete")
	terraformOptions := &terraform.Options{
		// EnvVars: map[string]string{
		// 	"TF_LOG": "DEBUG",
		// },
		TerraformDir: tempFolder,
		Upgrade:      false,
		VarFiles: []string{
			"fixtures.common.tfvars",
			"fixtures.insecure.tfvars",
		},
		RetryableTerraformErrors: map[string]string{
			".*Error: error reading S3 Bucket.*Logging: empty output.*": "bug in aws_s3_bucket_logging, intermittent error",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 5 * time.Second,
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
