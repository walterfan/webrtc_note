# Minimal makefile for Sphinx documentation
#

SHELL         := /bin/bash
SPHINXOPTS    ?=
SOURCEDIR     = source
BUILDDIR      = build
POETRY_PATH   = export PATH="$(HOME)/.local/bin:$$PATH";
PAGES_WORKFLOW ?= github-pages.yml
CURRENT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

# Put it first so that "make" without argument is like "make help".
help:
	@printf "Project targets:\n"
	@printf "  setup       install Poetry if needed and run 'poetry install'\n"
	@printf "  build       build HTML docs via 'poetry run sphinx-build -M html'\n"
	@printf "  publish     build docs, push current branch, and trigger GitHub Pages\n\n"
	@if command -v poetry >/dev/null 2>&1 || [ -x "$(HOME)/.local/bin/poetry" ]; then \
		printf "Sphinx targets:\n"; \
		$(POETRY_PATH) poetry run sphinx-build -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O); \
	else \
		printf "Sphinx targets are available after running 'make setup'.\n"; \
	fi

setup:
	@if ! command -v poetry >/dev/null 2>&1; then \
		curl -sSL https://install.python-poetry.org | python3 -; \
	fi
	@$(POETRY_PATH) poetry install

# Alias: "make build" runs html builder
build:
	@$(POETRY_PATH) poetry run sphinx-build -M html "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

publish: build
	@if [ -n "$$(git status --short)" ]; then \
		echo "Working tree has uncommitted changes. Commit them before publish so the remote deployment matches the local build."; \
		exit 1; \
	fi
	@command -v gh >/dev/null 2>&1 || { echo "gh CLI is required for make publish."; exit 1; }
	@git push -u origin "$(CURRENT_BRANCH)"
	@gh workflow run "$(PAGES_WORKFLOW)" --ref "$(CURRENT_BRANCH)"

.PHONY: help setup build publish Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(POETRY_PATH) poetry run sphinx-build -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
