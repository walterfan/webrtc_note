# Minimal makefile for Sphinx documentation
#

SHELL         := /bin/bash
SPHINXOPTS    ?=
SOURCEDIR     = source
BUILDDIR      = build
PORT          ?= 9028
UV            ?= uv

# Put it first so that "make" without argument is like "make help".
help:
	@printf "Project targets:\n"
	@printf "  deps        install dependencies via 'uv sync --locked'\n"
	@printf "  setup       alias for 'make deps'\n"
	@printf "  build       build HTML docs via 'uv run --locked sphinx-build -M html'\n"
	@printf "  serve       serve generated HTML on http://127.0.0.1:$(PORT)\n"
	@printf "  publish     build docs and publish local HTML to the 'gh-pages' branch\n\n"
	@if command -v "$(UV)" >/dev/null 2>&1; then \
		printf "Sphinx targets:\n"; \
		$(UV) run --locked sphinx-build -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O); \
	else \
		printf "Install uv, then run 'make deps' to enable Sphinx targets.\n"; \
	fi

deps:
	@if ! command -v "$(UV)" >/dev/null 2>&1; then \
		printf "uv is required. Install it first (macOS: brew install uv).\n"; \
		exit 1; \
	fi
	@$(UV) sync --locked

setup: deps

# Alias: "make build" runs html builder
build:
	@$(UV) run --locked sphinx-build -M html "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

serve:
	@if [ ! -d "$(BUILDDIR)/html" ]; then \
		printf "HTML not found in $(BUILDDIR)/html. Run 'make build' first.\n"; \
		exit 1; \
	fi
	@printf "Serving docs at http://127.0.0.1:$(PORT)\n"
	@python3 -m http.server $(PORT) --directory "$(BUILDDIR)/html"

publish:
	@$(UV) run --locked sphinx-build -M html "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O) -a
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

.PHONY: help deps setup build serve publish Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(UV) run --locked sphinx-build -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
