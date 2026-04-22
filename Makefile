# Minimal makefile for Sphinx documentation
#

SHELL         := /bin/bash
SPHINXOPTS    ?=
SOURCEDIR     = source
BUILDDIR      = build
POETRY_PATH   = export PATH="$(HOME)/.local/bin:$$PATH";

# Put it first so that "make" without argument is like "make help".
help:
	@printf "Project targets:\n"
	@printf "  setup       install Poetry if needed and run 'poetry install'\n"
	@printf "  build       build HTML docs via 'poetry run sphinx-build -M html'\n"
	@printf "  publish     build docs and publish local HTML to the 'gh-pages' branch\n\n"
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

publish:
	@$(POETRY_PATH) poetry run sphinx-build -M html "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O) -a
	@TMPDIR="$$(mktemp -d)"; \
	trap 'rm -rf "$$TMPDIR"' EXIT; \
	cp -R "$(BUILDDIR)/html/." "$$TMPDIR/"; \
	touch "$$TMPDIR/.nojekyll"; \
	cd "$$TMPDIR" && \
	git init -q && \
	git checkout -q -b gh-pages && \
	git add -A && \
	git commit -q -m "update notes" && \
	git push --force "$(shell git remote get-url origin)" gh-pages:gh-pages

.PHONY: help setup build publish Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(POETRY_PATH) poetry run sphinx-build -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
