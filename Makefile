# Minimal makefile for Sphinx documentation
#

SHELL         := /bin/bash
SPHINXOPTS    ?=
SOURCEDIR     = source
BUILDDIR      = build
POETRY_PATH   = export PATH="$(HOME)/.local/bin:$$PATH";
CURRENT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

# Put it first so that "make" without argument is like "make help".
help:
	@printf "Project targets:\n"
	@printf "  setup       install Poetry if needed and run 'poetry install'\n"
	@printf "  build       build HTML docs via 'poetry run sphinx-build -M html'\n"
	@printf "  publish     build docs and push current branch for GitHub Pages deployment\n\n"
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
	@case "$(CURRENT_BRANCH)" in \
		master|main) ;; \
		*) echo "Warning: GitHub Pages auto-deploy is configured for pushes to master/main. Pushing '$(CURRENT_BRANCH)' will not publish the site until the workflow branch filters are updated." ;; \
	esac
	@git push -u origin "$(CURRENT_BRANCH)"

.PHONY: help setup build publish Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(POETRY_PATH) poetry run sphinx-build -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
