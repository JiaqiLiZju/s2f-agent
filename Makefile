SHELL := /bin/bash

REPO_ROOT := $(CURDIR)
SKILLS_DIR ?= $(CODEX_HOME)/skills
ifeq ($(strip $(SKILLS_DIR)),/skills)
SKILLS_DIR := $(HOME)/.codex/skills
endif
ifeq ($(strip $(SKILLS_DIR)),)
SKILLS_DIR := $(HOME)/.codex/skills
endif

DEPLOY_ROOT ?= $(REPO_ROOT)/.deploy
PYTHON_BIN ?= python3

BOOTSTRAP_FLAGS :=
ifeq ($(COPY_SKILLS),1)
BOOTSTRAP_FLAGS += --copy-skills
endif
ifeq ($(FORCE_LINKS),1)
BOOTSTRAP_FLAGS += --force-links
endif

.PHONY: help link-skills bootstrap bootstrap-evo2-light bootstrap-evo2-full smoke

help:
	@printf '%s\n' \
	  'Available targets:' \
	  '  make link-skills           Link all packaged skills into the Codex skills dir' \
	  '  make bootstrap             One-step install: skills + alphagenome + gpn + nt-jax + smoke test' \
	  '  make bootstrap-evo2-light  Same as bootstrap, plus evo2-light (requires TORCH_INSTALL_CMD)' \
	  '  make bootstrap-evo2-full   Same as bootstrap, plus evo2-full in active conda env' \
	  '  make smoke                 Run smoke tests against the deployed paths' \
	  '' \
	  'Useful variables:' \
	  "  SKILLS_DIR=$(SKILLS_DIR)" \
	  "  DEPLOY_ROOT=$(DEPLOY_ROOT)" \
	  "  PYTHON_BIN=$(PYTHON_BIN)" \
	  '  COPY_SKILLS=1              Copy skills instead of symlinking them' \
	  '  FORCE_LINKS=1             Replace existing paths in the skills directory' \
	  '' \
	  'Example:' \
	  '  make bootstrap SKILLS_DIR=$$HOME/.codex/skills DEPLOY_ROOT=$$HOME/.cache/s2f-skills'

link-skills:
	bash $(REPO_ROOT)/scripts/link_skills.sh --skills-dir "$(SKILLS_DIR)" $(if $(filter 1,$(COPY_SKILLS)),--copy,) $(if $(filter 1,$(FORCE_LINKS)),--force,)

bootstrap:
	bash $(REPO_ROOT)/scripts/bootstrap.sh \
	  --skills-dir "$(SKILLS_DIR)" \
	  --deploy-root "$(DEPLOY_ROOT)" \
	  --python "$(PYTHON_BIN)" \
	  $(BOOTSTRAP_FLAGS)

bootstrap-evo2-light:
	bash $(REPO_ROOT)/scripts/bootstrap.sh \
	  --skills-dir "$(SKILLS_DIR)" \
	  --deploy-root "$(DEPLOY_ROOT)" \
	  --python "$(PYTHON_BIN)" \
	  --with-evo2-light \
	  $(BOOTSTRAP_FLAGS)

bootstrap-evo2-full:
	bash $(REPO_ROOT)/scripts/bootstrap.sh \
	  --skills-dir "$(SKILLS_DIR)" \
	  --deploy-root "$(DEPLOY_ROOT)" \
	  --python "$(PYTHON_BIN)" \
	  --with-evo2-full \
	  $(BOOTSTRAP_FLAGS)

smoke:
	bash $(REPO_ROOT)/scripts/smoke_test.sh \
	  --skills-dir "$(SKILLS_DIR)" \
	  --alphagenome-python "$(DEPLOY_ROOT)/venvs/alphagenome/bin/python" \
	  --gpn-python "$(DEPLOY_ROOT)/venvs/gpn/bin/python" \
	  --nt-python "$(DEPLOY_ROOT)/venvs/nt-jax/bin/python"
