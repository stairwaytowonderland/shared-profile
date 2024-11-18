# MAKEFLAGS += --no-print-directory

####################
# Global Variables
####################

SHELL := bash
UNAME := $(shell uname -s)
SCRIPT_DIR := $(shell sed "s@$$HOME@~@" <<<$$(pwd))

####################
# Standard
####################

.PHONY: all
all: $(TARGETS)
	@printf "\033[1m%s\033[0m\n" "Please specify additional targets"
	@LC_ALL=C $(MAKE) .list-targets | sed -E 's/^all ?//' | sort -u | xargs -n3 printf "%-26s%-26s%-26s%s\n"

.PHONY: help
help: ## Show this help.
	@echo "Please use \`make <target>' where <target> is one of"
	@grep '^[a-zA-Z]' $(MAKEFILE_LIST) | \
    sort | \
    awk -F ':.*?## ' 'NF==2 {printf "\033[36m  %-26s\033[0m %s\n", $$1, $$2}'

.PHONY: list
list: ## List public targets
	@LC_ALL=C $(MAKE) .list-targets | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs -n3 printf "%-26s%-26s%-26s%s\n"

####################
# Helpers
####################

.PHONY: .list-targets
.list-targets:
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort

.PHONY: .install-full
.install-full:
	@set -x; DEBUG=$(DEBUG) BASE_DIR=$(SCRIPT_DIR) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/setup.sh

.PHONY: .install-bashrc
.install-bashrc:
	@set -x; DEBUG=$(DEBUG) BASE_DIR=$(SCRIPT_DIR) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/setup.sh --install bash

.PHONY: .install-skel
.install-skel: .install-bashrc
	@set -x; DEBUG=$(DEBUG) BASE_DIR=$(SCRIPT_DIR) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/setup.sh --install env
	@set -x; DEBUG=$(DEBUG) BASE_DIR=$(SCRIPT_DIR) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/setup.sh --install git

.PHONY: .update-bash
.update-bash:
	@set -x; DEBUG=$(DEBUG) BASE_DIR=$(SCRIPT_DIR) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/setup.sh --update bash

.PHONY: .update-skel
.update-skel:
	@set -x; DEBUG=$(DEBUG) BASE_DIR=$(SCRIPT_DIR) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/setup.sh --update env
	@set -x; DEBUG=$(DEBUG) BASE_DIR=$(SCRIPT_DIR) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/setup.sh --update git

.PHONY: .update
.update:
	@set -x; DEBUG=$(DEBUG) BASE_DIR=$(SCRIPT_DIR) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/setup.sh --update all

.PHONY: .update-dist
.update-dist: DIST_FILES ?= $(shell find "$$(realpath $(SCRIPT_DIR))/dist" -type f -name ".*" -mindepth 1 -maxdepth 1 -exec echo {} \;)
.update-dist:
	@set -x; DEBUG=$(DEBUG) BASE_DIR=$(SCRIPT_DIR) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/setup.sh --update dist $(DIST_FILES)

.PHONY: .home-commit
.home-commit: SKEL_FILES ?= $(shell find "$$(realpath $(SCRIPT_DIR))/etc/skel" -name ".*" -exec echo {} \;)
.home-commit:
	@set -x; BASE_DIR=$(SCRIPT_DIR) DEBUG=$(DEBUG) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/setup.sh --git commit $(SKEL_FILES)

.PHONY: .home-status
.home-status:
	@set -x; DEBUG=$(DEBUG) BASE_DIR=$(SCRIPT_DIR) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/setup.sh --git status

.PHONY: .build
.build:
	@set -x; DEBUG=$(DEBUG) BASE_DIR=$(SCRIPT_DIR) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/setup.sh --build

.PHONY: .deploy
.deploy: .update-dist

####################
# Common
####################

.PHONY: install
install: .install-full ## Full install

.PHONY: test
test: DEBUG = true
test: install ## Test install (test-only)

.PHONY: update
update: commit-home .update

.PHONY: build
build: FILE_NAME ?= dist/home/.bashrc
build: .build combined-profile ## Build files 'dist/.*'

.PHONY: test-build
test-build: DEBUG = true
test-build: build ## Test build (test-only)

.PHONY: deploy
deploy: .deploy ## Copy files 'dist/.*' to $HOME; $HOME will get backed up with git

.PHONY: test-deploy
test-deploy: DEBUG = true
test-deploy: deploy ## Test deploy (test-only)

####################
# Misc
####################

.PHONY: combined-profile
combined-profile: FILE_NAME ?= dist/.bashrc
combined-profile: ## Build combined profile in 'dist/home/.bashrc'
	@set -x; DEBUG=$(DEBUG) BASE_DIR=$(SCRIPT_DIR) UNAME=$(UNAME) $(SCRIPT_DIR)/setup/profile/generate.sh "$(FILE_NAME)"

.PHONY: bbedit-default-editor
bbedit-default-editor: ## Run script to set bbedit as the default editor on macos
	@set -x; '$(SCRIPT_DIR)/setup/bbedit/bbedit-default-editor'

.PHONY: brew-dump
brew-dump: BREWFILE = "$(SCRIPT_DIR)/setup/brew/Brewfile"
brew-dump: ## Create brew dump file at 'setup/brew/Brewfile'; Current dump file (setup/brew/Brewfile) will get backed up
	@set -x; [ ! -r $(BREWFILE) ] || cp "$(BREWFILE)" "$(BREWFILE).$(shell date +\%u.\%H).bak" && brew bundle dump --file="$(BREWFILE)" --force

### Install

.PHONY: install-bashrc
install-bashrc: .install-bashrc ## Install bash (profile) files only; Does not overwrite

.PHONY: install-skel
install-skel: install-bashrc .install-env .install-git ## Install all skel files (bash files, .env, .gitconfig); Does not overwrite

.PHONY: test-install-skel
test-install-skel: DEBUG=true
test-install-skel: install-skel ## Install skel files test (test-only); Does not overwrite

### Update

.PHONY: update-bash
update-bash: commit-home .update-bash ## Install bash (profile) files only

.PHONY: update-skel
update-skel: commit-home update-bash .update-env .update-git ## Install all skel files (bash files, .env, .gitconfig)

.PHONY: test-update-skel
test-update-skel: DEBUG=true
test-update-skel: update-skel ## Test update (test-only)

### Maintain

.PHONY: commit-home
commit-home: .home-commit ## Git commit handled files in $HOME folder

.PHONY: test-commit
test-commit: DEBUG = true
test-commit: commit-home ## Test git commit handled files in $HOME folder

.PHONY: status-commit
status-commit: .home-status ## Git status handled files in $HOME folder

.PHONY: quick
quick: build deploy ## Build and then deploy 'dist/home'

.PHONY: test-quick
test-quick: DEBUG = true
test-quick: quick ## Test buld and deploy of 'dist/home'
