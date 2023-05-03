# The version of the build harness container to use
BUILD_HARNESS_REPO := ghcr.io/defenseunicorns/not-a-build-harness/not-a-build-harness
# renovate: datasource=docker depName=ghcr.io/defenseunicorns/not-a-build-harness/not-a-build-harness versioning=docker
BUILD_HARNESS_VERSION := 0.0.13

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
	mkdir -p .cache/go
	mkdir -p .cache/go-build
	mkdir -p .cache/tmp
	mkdir -p .cache/.terraform.d/plugin-cache

.PHONY: _test-all
_test-all: _create-folders
	echo "Running automated tests. This will take several minutes. At times it does not log anything to the console. If you interrupt the test run you will need to log into AWS console and manually delete any orphaned infrastructure."
	docker run $(TTY_ARG) --rm \
		--cap-add=NET_ADMIN \
		--cap-add=NET_RAW \
		-v "${PWD}:/app" \
		-v "${PWD}/.cache/tmp:/tmp" \
		-v "${PWD}/.cache/go:/root/go" \
		-v "${PWD}/.cache/go-build:/root/.cache/go-build" \
		-v "${PWD}/.cache/.terraform.d/plugin-cache:/root/.terraform.d/plugin-cache" \
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
		$(BUILD_HARNESS_REPO):$(BUILD_HARNESS_VERSION) \
		bash -c 'asdf install && cd examples/complete && terraform init -upgrade=true && cd ../../test/e2e && go test -count 1 -v $(EXTRA_TEST_ARGS) .'

.PHONY: bastion-connect
bastion-connect: _create-folders ## To be used after deploying "secure mode" of examples/complete. It (a) creates a tunnel through the bastion host using sshuttle, and (b) sets up the KUBECONFIG so that the EKS cluster is able to be interacted with. Requires the standard AWS cred environment variables to be set. We recommend using 'aws-vault' to set them.
	# TODO: Figure out a better way to deal with the bastion's SSH password. Ideally it should come from a terraform output but you can't directly pass inputs to outputs (at least not when you are using "-target")
	cd examples/complete && terraform init
	docker run $(TTY_ARG) --rm \
		--cap-add=NET_ADMIN \
		--cap-add=NET_RAW \
		-v "${PWD}:/app" \
		--workdir "/app/examples/complete" \
		-e AWS_REGION \
		-e AWS_DEFAULT_REGION \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_SESSION_TOKEN \
		-e AWS_SECURITY_TOKEN \
		-e AWS_SESSION_EXPIRATION \
		$(BUILD_HARNESS_REPO):$(BUILD_HARNESS_VERSION) \
		bash -c 'asdf install \
				&& sshuttle -D -e '"'"'sshpass -p "my-password" ssh -q -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="aws ssm --region $(shell cd examples/complete && terraform output -raw bastion_region) start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p"'"'"' --dns --disable-ipv6 -vr ec2-user@$(shell cd examples/complete && terraform output -raw bastion_instance_id) $(shell cd examples/complete && terraform output -raw vpc_cidr) \
				&& aws eks --region $(shell cd examples/complete && terraform output -raw bastion_region) update-kubeconfig --name $(shell cd examples/complete && terraform output -raw eks_cluster_name) \
				&& echo "SShuttle is running and KUBECONFIG has been set. Try running kubectl get nodes." \
				&& bash'

.PHONY: test
test: ## Run all automated tests. Requires access to an AWS account. Costs real money.
	$(MAKE) _test-all EXTRA_TEST_ARGS="-timeout 2h"

.PHONY: test-complete-insecure
test-complete-insecure: ## Run one test (TestExamplesCompleteInsecure). Requires access to an AWS account. Costs real money.
	$(MAKE) _test-all EXTRA_TEST_ARGS="-timeout 2h -run TestExamplesCompleteInsecure"

.PHONY: test-complete-secure
test-complete-secure: ## Run one test (TestExamplesCompleteSecure). Requires access to an AWS account. Costs real money.
	$(MAKE) _test-all EXTRA_TEST_ARGS="-timeout 2h -run TestExamplesCompleteSecure"

.PHONY: docker-save-build-harness
docker-save-build-harness: ## Pulls the build harness docker image and saves it to a tarball
	mkdir -p .cache/docker
	docker pull $(BUILD_HARNESS_REPO):$(BUILD_HARNESS_VERSION)
	docker save -o .cache/docker/build-harness.tar $(BUILD_HARNESS_REPO):$(BUILD_HARNESS_VERSION)

.PHONY: docker-load-build-harness
docker-load-build-harness: ## Loads the saved build harness docker image
	docker load -i .cache/docker/build-harness.tar

.PHONY: run-pre-commit-hooks
run-pre-commit-hooks: ## Run all pre-commit hooks. Returns nonzero exit code if any hooks fail. Uses Docker for maximum compatibility
	mkdir -p .cache/pre-commit
	docker run $(TTY_ARG) --rm -v "${PWD}:/app" --workdir "/app" -e "PRE_COMMIT_HOME=/app/.cache/pre-commit" $(BUILD_HARNESS_REPO):$(BUILD_HARNESS_VERSION) bash -c 'asdf install && pre-commit run -a --show-diff-on-failure'

.PHONY: fix-cache-permissions
fix-cache-permissions: ## Fixes the permissions on the pre-commit cache
	docker run $(TTY_ARG) --rm -v "${PWD}:/app" --workdir "/app" -e "PRE_COMMIT_HOME=/app/.cache/pre-commit" $(BUILD_HARNESS_REPO):$(BUILD_HARNESS_VERSION) chmod -R a+rx .cache
