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

publish: build
	@TMPDIR="$$(mktemp -d)"; \
	TMPBRANCH="gh-pages-publish-$$"; \
	trap 'git worktree remove --force "$$TMPDIR" >/dev/null 2>&1 || true; git branch -D "$$TMPBRANCH" >/dev/null 2>&1 || true' EXIT; \
	if git show-ref --verify --quiet refs/remotes/origin/gh-pages; then \
		git worktree add -B "$$TMPBRANCH" "$$TMPDIR" origin/gh-pages >/dev/null; \
	else \
		git worktree add --detach "$$TMPDIR" HEAD >/dev/null; \
		git -C "$$TMPDIR" checkout --orphan "$$TMPBRANCH" >/dev/null 2>&1; \
	fi; \
	git -C "$$TMPDIR" rm -r -q . >/dev/null 2>&1 || true; \
	git -C "$$TMPDIR" clean -fdx >/dev/null; \
	cp -R "$(BUILDDIR)/html/." "$$TMPDIR/"; \
	touch "$$TMPDIR/.nojekyll"; \
	git -C "$$TMPDIR" add -A; \
	if git -C "$$TMPDIR" diff --cached --quiet; then \
		echo "No site changes to publish."; \
	else \
		git -C "$$TMPDIR" commit -m "update notes" >/dev/null; \
		git -C "$$TMPDIR" push origin HEAD:gh-pages; \
	fi

.PHONY: help setup build publish Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(POETRY_PATH) poetry run sphinx-build -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
