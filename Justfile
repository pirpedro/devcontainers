# Use bash with "fail fast"
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# --------- Variables you can tweak ---------
# GitHub namespace (owner/repo) and full GHCR namespace.
OWNER     := env_var_or_default('OWNER', 'pirpedro')
REPO_NAME := env_var_or_default('REPO_NAME', 'devcontainers')
GHCR_NS   := "ghcr.io" / OWNER / REPO_NAME

# Auto-discover features from src/* (space-separated), portable across GNU/BSD userlands
TEMPLATES := `ls -1d src/*/ 2>/dev/null | sed 's#/$##' | xargs -n1 basename | sort | tr '\n' ' ' | sed 's/ $//'`
DEFAULT_TEMPLATE := "dev-tools"

# Workspace folder for real devcontainer runs
WF := "."

# --------- Help ---------
# Default help target showing common tasks and usage examples.
help:
	@echo "=== Devcontainer Templates Justfile ==="
	@echo
	@echo "Available commands:"
	@echo "  just test [TEMPLATE] [-- flags...]         # run template tests (default = all TEMPLATES)"
	@echo "  just test-debug [TEMPLATE] [-- flags...]   # same as 'test' but with verbose logs and no cleanup"
	@echo "  just info-all                             # show GHCR metadata for all discovered TEMPLATEs"
	@echo "  just info [TEMPLATE] [TAG]                 # show GHCR metadata for a single TEMPLATE (default tag=latest)"
	@echo "  just tag version=<X.Y.Z>                  # create and push git tag 'vX.Y.Z'"
	@echo "  just up                                   # start a real devcontainer from workspace"
	@echo "  just exec CMD='bash'                      # exec a command inside the real devcontainer"
	@echo "  just docker-enter-last                    # enter the most recent test container (sh)"
	@echo "  just ghcr-tags TEMPLATE=<name>             # list GHCR tags for a template (requires 'oras')"
	@echo
	@echo "Examples:"
	@echo "  just test chezmoi                         # run tests for local template 'chezmoi'"
	@echo "  just test-debug chezmoi -- --log-level trace"
	@echo "  just info chezmoi latest                  # show GHCR metadata for 'chezmoi:latest'"
	@echo "  just tag version=1.2.3                    # create and push git tag 'v1.2.3'"

# --------- Template tests ---------
# Run tests for a template (local or GHCR). Default = all TEMPLATES.
test template=TEMPLATES:
	./.github/actions/smoke-test/build.sh {{template}}
	./.github/actions/smoke-test/test.sh {{template}}


# --------- Info / inspection ---------
# Show remote GHCR metadata for all discovered templates.
info-all:
	for f in {{TEMPLATES}}; do \
	  echo "==> ${f}"; \
	  devcontainer templates metadata "{{GHCR_NS}}/${f}" || true; \
	  echo; \
	done

# Show remote GHCR metadata for one template (default tag = latest).
info template=DEFAULT_TEMPLATE:
	devcontainer templates metadata "{{GHCR_NS}}/{{template}}"

# --------- Release / Docs ---------
# Create and push a git tag with prefix 'v'.
tag version:
	git tag "v{{version}}"
	git push --tags
	echo "Tag v{{version}} pushed."

# --------- Real Dev Container ---------
# Bring up a real devcontainer from the current workspace.
up:
	devcontainer up --workspace-folder "${WF:-{{WF}}}"

# Exec command inside the real devcontainer. Defaults to bash, falls back to sh.
exec:
	devcontainer exec --workspace-folder "${WF:-{{WF}}}" ${CMD:-bash} || \
	devcontainer exec --workspace-folder "${WF:-{{WF}}}" sh




