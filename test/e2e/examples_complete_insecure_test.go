package e2e_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/eks"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	batchv1 "k8s.io/api/batch/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/wait"

	"github.com/defenseunicorns/delivery-aws-iac/test/e2e/utils"
)

//nolint:goconst
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

	defer teardownTestExamplesCompleteInsecure(t, terraformOptions)
	setupTestExamplesCompleteInsecure(t, terraformOptions)

	// Run assertions
	teststructure.RunTestStage(t, "TEST", func() {
		// Get outputs
		bastionRegion := terraform.Output(t, terraformOutputOptions, "bastion_region")
		clusterName := terraform.Output(t, terraformOutputOptions, "eks_cluster_name")
		// Create the EKS clientset
		sess := session.Must(session.NewSession(&aws.Config{
			Region: aws.String(bastionRegion),
		}))
		eksSvc := eks.New(sess)
		input := &eks.DescribeClusterInput{Name: aws.String(clusterName)}
		result, err := eksSvc.DescribeCluster(input)
		require.NoError(t, err)
		clientset, err := utils.NewK8sClientset(result.Cluster)
		require.NoError(t, err)
		// Wait for the job "test-write" in the namespace "default" to complete, with a 2-minute timeout
		namespace := "default"
		jobName := "test-write"
		timeout := 2 * time.Minute
		err = wait.PollImmediate(time.Second, timeout, func() (bool, error) {
			job, err := clientset.BatchV1().Jobs(namespace).Get(context.Background(), jobName, metav1.GetOptions{})
			if err != nil {
				return false, fmt.Errorf("failed to get kubernetes jobs: %w", err)
			}
			// Check the job's status
			for _, c := range job.Status.Conditions {
				if c.Type == batchv1.JobComplete && c.Status == "True" {
					return true, nil
				} else if c.Type == batchv1.JobFailed && c.Status == "True" {
					return false, fmt.Errorf("job failed")
				}
			}
			return false, nil
		})
		if err != nil {
			utils.DoLog("Job did not complete in time: %v\n", err)
		} else {
			utils.DoLog("Job completed successfully")
		}
		assert.NoError(t, err)
	})
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
