package utils_test

import (
	"testing"

	"github.com/defenseunicorns/delivery-aws-iac/test/e2e/utils"
)

func TestInstallZarf(t *testing.T) { //nolint:paralleltest
	utils.InstallZarf(t)
}
