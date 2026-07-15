# DoriDori project Makefile
# Dependencies are pinned as Git submodules in .gitmodules.

.PHONY: help setup init update install build-repos build clean status test dev

REPOS_DIR := repos
DRAWING_COMMON := $(REPOS_DIR)/drawing-common
HOME_TEACHER_COMMON := $(REPOS_DIR)/home-teacher-common
DORIDORI_APP := $(REPOS_DIR)/doridori-app
SUBMODULES := $(DRAWING_COMMON) $(HOME_TEACHER_COMMON) $(DORIDORI_APP)

.DEFAULT_GOAL := help

## help: Show available commands
help:
	@echo "DoriDori project"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  make /'

## setup: Initialize submodules, install dependencies, and build
setup: init install build-repos

## init: Initialize the submodules pinned by this repository
init:
	@git submodule update --init --recursive

## update: Move submodules to their configured remote branches
update:
	@git submodule update --remote --recursive

## install: Install dependencies in every submodule
install: init
	@cd $(DRAWING_COMMON) && npm install
	@cd $(HOME_TEACHER_COMMON) && npm install
	@cd $(DORIDORI_APP) && npm install

## build-repos: Build shared libraries
build-repos: init
	@cd $(DRAWING_COMMON) && npm run build

## build: Build shared libraries and the DoriDori application
build: build-repos
	@cd $(DORIDORI_APP) && npm run build

## dev: Start the DoriDori Vite development server
dev: init
	@cd $(DORIDORI_APP) && npm run dev

## clean: Remove generated build output while keeping submodules
clean:
	@rm -rf $(DRAWING_COMMON)/dist $(HOME_TEACHER_COMMON)/dist $(DORIDORI_APP)/dist deploy

## status: Show parent and submodule Git status
status:
	@git status -sb
	@git submodule status
	@for repo in $(SUBMODULES); do echo ""; echo "$$repo:"; git -C $$repo status -sb; done

## test: Run test scripts where provided
test: init
	@for repo in $(SUBMODULES); do if npm -s --prefix $$repo run | grep -q 'test'; then npm --prefix $$repo test; fi; done
