include .env

.DEFAULT_GOAL := help

# Optionally add the "-it" flag for docker run commands if the env var "CI" is not set (meaning we are on a local machine and not in github actions)
TTY_ARG :=
ifndef CI
	TTY_ARG := -it
endif

# Silent mode by default. Run `make VERBOSE=1` to turn off silent mode.
ifndef VERBOSE
.SILENT:
endif

# Idiomatic way to force a target to always run, by having it depend on this dummy target
FORCE:

.PHONY: help
help: ## Show a list of all targets
	grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)##\(.*\)/\1:\3/p' \
	| column -t -s ":"

.PHONY: _create-folders
_create-folders:
	mkdir -p .cache/docker
	mkdir -p .cache/pre-commit
	mkdir -p .cache/go
	mkdir -p .cache/go-build
	mkdir -p .cache/tmp
	mkdir -p .cache/.terraform.d/plugin-cache
	mkdir -p .cache/.zarf-cache

.PHONY: _test-all
_test-all: _create-folders
	# import any TF_VAR_ environment variables into the docker container.
	echo "Running automated tests. This will take several minutes. At times it does not log anything to the console. If you interrupt the test run you will need to log into AWS console and manually delete any orphaned infrastructure.";\
	TF_VARS=$$(env | grep '^TF_VAR_' | awk -F= '{printf "-e %s ", $$1}'); \
	docker run $(TTY_ARG) --rm \
		--cap-add=NET_ADMIN \
		--cap-add=NET_RAW \
		-v "${PWD}:/app" \
		-v "${PWD}/.cache/tmp:/tmp" \
		-v "${PWD}/.cache/go:/root/go" \
		-v "${PWD}/.cache/go-build:/root/.cache/go-build" \
		-v "${PWD}/.cache/.terraform.d/plugin-cache:/root/.terraform.d/plugin-cache" \
		-v "${PWD}/.cache/.zarf-cache:/root/.zarf-cache" \
		--workdir "/app" \
		-e TF_LOG_PATH \
		-e TF_LOG \
		-e GOPATH=/root/go \
		-e GOCACHE=/root/.cache/go-build \
		-e TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=true \
		-e TF_PLUGIN_CACHE_DIR=/root/.terraform.d/plugin-cache \
		-e AWS_REGION \
		-e AWS_DEFAULT_REGION \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_SESSION_TOKEN \
		-e AWS_SECURITY_TOKEN \
		-e AWS_SESSION_EXPIRATION \
		-e SKIP_SETUP \
		-e SKIP_TEST \
		-e SKIP_TEARDOWN \
		$${TF_VARS} \
		${BUILD_HARNESS_REPO}:${BUILD_HARNESS_VERSION} \
		bash -c 'git config --global --add safe.directory /app && cd examples/complete && tofu init -upgrade=true && cd ../../test/e2e && go test -count 1 -v $(EXTRA_TEST_ARGS) .'

.PHONY: bastion-connect
bastion-connect: _create-folders ## To be used after deploying "secure mode" of examples/complete. It (a) creates a tunnel through the bastion host using sshuttle, and (b) sets up the KUBECONFIG so that the EKS cluster is able to be interacted with. Requires the standard AWS cred environment variables to be set. We recommend using 'aws-vault' to set them.
	# TODO: Figure out a better way to deal with the bastion's SSH password. Ideally it should come from a terraform output but you can't directly pass inputs to outputs (at least not when you are using "-target")
	docker run $(TTY_ARG) --rm \
		--cap-add=NET_ADMIN \
		--cap-add=NET_RAW \
		-v "${PWD}:/app" \
		-v "${PWD}/.cache/tmp:/tmp" \
		-v "${PWD}/.cache/go:/root/go" \
		-v "${PWD}/.cache/go-build:/root/.cache/go-build" \
		-v "${PWD}/.cache/.terraform.d/plugin-cache:/root/.terraform.d/plugin-cache" \
		-v "${PWD}/.cache/.zarf-cache:/root/.zarf-cache" \
		--workdir "/app/examples/complete" \
		-e TF_LOG_PATH \
		-e TF_LOG \
		-e GOPATH=/root/go \
		-e GOCACHE=/root/.cache/go-build \
		-e TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=true \
		-e TF_PLUGIN_CACHE_DIR=/root/.terraform.d/plugin-cache \
		-e AWS_REGION \
		-e AWS_DEFAULT_REGION \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_SESSION_TOKEN \
		-e AWS_SECURITY_TOKEN \
		-e AWS_SESSION_EXPIRATION \
		${BUILD_HARNESS_REPO}:${BUILD_HARNESS_VERSION} \
		bash -c 'git config --global --add safe.directory /app \
				&& tofu init -upgrade=true \
				&& sshuttle -D -e '"'"'sshpass -p "my-password" ssh -q -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="aws ssm --region $(shell cd examples/complete && terraform output -raw bastion_region) start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p"'"'"' --dns --disable-ipv6 -vr ec2-user@$(shell cd examples/complete && terraform output -raw bastion_instance_id) $(shell cd examples/complete && terraform output -raw vpc_cidr) \
				&& aws eks --region $(shell cd examples/complete && terraform output -raw bastion_region) update-kubeconfig --name $(shell cd examples/complete && terraform output -raw eks_cluster_name) \
				&& echo "SShuttle is running and KUBECONFIG has been set. Try running kubectl get nodes." \
				&& bash'

.PHONY: test
test: ## Run all automated tests. Requires access to an AWS account. Costs real money.
	$(MAKE) _test-all EXTRA_TEST_ARGS="-timeout 3h"

.PHONY: test-ci-complete-insecure
test-ci-complete-insecure: ## Run one test (TestExamplesCompleteInsecure). Requires access to an AWS account. Costs real money.
	$(eval export TF_VAR_region := $(or $(REGION),$(TF_VAR_region),us-east-2))
	$(MAKE) _test-all EXTRA_TEST_ARGS="-timeout 3h -run TestExamplesCompleteInsecure"

.PHONY: test-release-complete-secure
test-release-complete-secure: ## Run one test (TestExamplesCompleteSecure). Requires access to an AWS account. Costs real money.
	$(eval export TF_VAR_region := $(or $(REGION),$(TF_VAR_region),us-gov-west-1))
	$(MAKE) _test-all EXTRA_TEST_ARGS="-timeout 3h -run TestExamplesCompleteSecure"

.PHONY: test-complete-plan-only
test-complete-plan-only: ## Run one test (TestExamplesCompletePlanOnly). Requires access to an AWS account. It will not cost money or create any resources since it is just running `terraform plan`.
	$(eval export TF_VAR_region := $(or $(REGION),$(TF_VAR_region),us-east-2))
	$(MAKE) _test-all EXTRA_TEST_ARGS="-timeout 2h -run TestExamplesCompletePlanOnly"

.PHONY: docker-save-build-harness
docker-save-build-harness: _create-folders ## Pulls the build harness docker image and saves it to a tarball
	docker pull ${BUILD_HARNESS_REPO}:${BUILD_HARNESS_VERSION}
	docker save -o .cache/docker/build-harness.tar ${BUILD_HARNESS_REPO}:${BUILD_HARNESS_VERSION}

.PHONY: docker-load-build-harness
docker-load-build-harness: ## Loads the saved build harness docker image
	docker load -i .cache/docker/build-harness.tar

.PHONY: _runhooks
_runhooks: _create-folders
	docker run $(TTY_ARG) --rm \
		-v "${PWD}:/app" \
		-v "${PWD}/.cache/tmp:/tmp" \
		-v "${PWD}/.cache/go:/root/go" \
		-v "${PWD}/.cache/go-build:/root/.cache/go-build" \
		-v "${PWD}/.cache/.terraform.d/plugin-cache:/root/.terraform.d/plugin-cache" \
		-v "${PWD}/.cache/.zarf-cache:/root/.zarf-cache" \
		--workdir "/app" \
		-e GOPATH=/root/go \
		-e GOCACHE=/root/.cache/go-build \
		-e TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=true \
		-e TF_PLUGIN_CACHE_DIR=/root/.terraform.d/plugin-cache \
		-e "SKIP=$(SKIP)" \
		-e "PRE_COMMIT_HOME=/app/.cache/pre-commit" \
		${BUILD_HARNESS_REPO}:${BUILD_HARNESS_VERSION} \
		bash -c 'git config --global --add safe.directory /app && pre-commit run -a --show-diff-on-failure $(HOOK)'

.PHONY: pre-commit-all
pre-commit-all: ## Run all pre-commit hooks. Returns nonzero exit code if any hooks fail. Uses Docker for maximum compatibility
	$(MAKE) _runhooks HOOK="" SKIP=""

.PHONY: pre-commit-terraform
pre-commit-terraform: ## Run the terraform pre-commit hooks. Returns nonzero exit code if any hooks fail. Uses Docker for maximum compatibility
	$(MAKE) _runhooks HOOK="" SKIP="check-added-large-files,check-merge-conflict,detect-aws-credentials,detect-private-key,end-of-file-fixer,fix-byte-order-marker,trailing-whitespace,check-yaml,fix-smartquotes,go-fmt,golangci-lint,renovate-config-validator"

.PHONY: pre-commit-golang
pre-commit-golang: ## Run the golang pre-commit hooks. Returns nonzero exit code if any hooks fail. Uses Docker for maximum compatibility
	$(MAKE) _runhooks HOOK="" SKIP="check-added-large-files,check-merge-conflict,detect-aws-credentials,detect-private-key,end-of-file-fixer,fix-byte-order-marker,trailing-whitespace,check-yaml,fix-smartquotes,terraform_fmt,tofu_docs,tofu_checkov,terraform_tflint,renovate-config-validator"

.PHONY: pre-commit-renovate
pre-commit-renovate: ## Run the renovate pre-commit hooks. Returns nonzero exit code if any hooks fail. Uses Docker for maximum compatibility
	$(MAKE) _runhooks HOOK="renovate-config-validator" SKIP=""

.PHONY: pre-commit-common
pre-commit-common: ## Run the common pre-commit hooks. Returns nonzero exit code if any hooks fail. Uses Docker for maximum compatibility
	$(MAKE) _runhooks HOOK="" SKIP="go-fmt,golangci-lint,terraform_fmt,tofu_docs,tofu_checkov,terraform_tflint,renovate-config-validator"

.PHONY: fix-cache-permissions
fix-cache-permissions: ## Fixes the permissions on the pre-commit cache
	docker run $(TTY_ARG) --rm -v "${PWD}:/app" --workdir "/app" -e "PRE_COMMIT_HOME=/app/.cache/pre-commit" ${BUILD_HARNESS_REPO}:${BUILD_HARNESS_VERSION} chmod -R a+rx .cache

.PHONY: autoformat
autoformat: ## Update files with automatic formatting tools. Uses Docker for maximum compatibility.
	$(MAKE) _runhooks HOOK="" SKIP="check-added-large-files,check-merge-conflict,detect-aws-credentials,detect-private-key,check-yaml,golangci-lint,tofu_checkov,terraform_tflint,renovate-config-validator"
