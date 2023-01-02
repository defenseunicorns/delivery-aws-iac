# The version of Zarf to use. To keep this repo as portable as possible the Zarf binary will be downloaded and added to
# the build folder.
ZARF_VERSION := v0.22.2

# Figure out which Zarf binary we should use based on the operating system we are on
ZARF_BIN := zarf

# Provide a value for the operating system architecture and processor to install the correct terraform binary
ifeq ($(OS),Windows_NT)
	ARCH_NAME := windows
	ARCH_PROC := amd64
else
	UNAME_S := $(shell uname -s)
	UNAME_P := $(shell uname -p)
	ifeq ($(UNAME_S),Darwin)
		ARCH_NAME := darwin
		ARCH_PROC := amd64
		ifeq ($(UNAME_P),arm)
			ARCH_PROC := arm64
		endif
	endif
	ifeq ($(UNAME_S),Linux)
		ARCH_NAME := linux
		ifeq ($(UNAME_P),amd)
			ARCH_PROC := amd64
		endif
		ifeq ($(UNAME_P),i386)
			ARCH_PROC := 386
		endif
		ifeq ($(UNAME_P),arm)
			ARCH_PROC := arm64
		endif
	endif
endif

# Set terraform version
TF_VERSION := 1.3.6
# Terraform environment directory
TF_ENV_DIR := "./examples/complete-example"
TF_ENV := "complete-example"
TF_ENV_STATE_DIR := "./examples/tf-state-backend"
TF_ENV_STATE := "tf-state-backend"
# Terraform modules directory
TF_MODULES_DIR := "./modules"

.DEFAULT_GOAL := help

# Idiomatic way to force a target to always run, by having it depend on this dummy target
FORCE:

.PHONY: help
help: ## Show a list of all targets
	@grep -E '^\S*:.*##.*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)##\(.*\)/\1:\3/p' \
	| column -t -s ":"

.PHONY: clean
clean: ## Clean up build files
	@rm -rf ./build

mkdir: 
	@mkdir -p build

.PHONY: build
build: mkdir ## Build the IaC Zarf Package
	@echo "Creating the deploy package"
	@$(ZARF_BIN) package create --set TF_ENV_DIR=$(TF_ENV_DIR) --set TF_ENV_STATE_DIR=$(TF_ENV_STATE_DIR) --set TF_MODULES_DIR=$(TF_MODULES_DIR) --set TF_ENV=$(TF_ENV) --set TF_ENV_STATE=$(TF_ENV_STATE) --set ARCH_PROC=$(ARCH_PROC) --set ARCH_NAME=$(ARCH_NAME) --set TF_VERSION=$(TF_VERSION) --confirm
	@mv zarf-package-terraform-$(ARCH_PROC).tar.zst build/zarf-package-terraform-$(ARCH_PROC).tar.zst
