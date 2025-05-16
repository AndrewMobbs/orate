# Use a Makefile to ensure that the generator is run if needed
# The generator clobbers Cargo.toml - so we can't just use build.rs and need to go outside cargo for generation
# Still use cargo for bulk of build tooling

API_PACKAGE = orate_api
SPEC_FILE := api/orate.yaml

WORKSPACE_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
API_DIR := $(WORKSPACE_ROOT)/$(API_PACKAGE)
API_CARGO_TOML := $(API_DIR)/Cargo.toml
SPEC_FILE_PATH := $(API_DIR)/$(SPEC_FILE)
# Define a "sentinel" file that is generated to check against timestamp of spec file for regeneration
GENERATED_OUTPUT_SENTINEL := $(API_DIR)/src/lib.rs

# Extract the API version
YQ_PATH := $(shell command -v yq)

# If YQ_PATH is empty, fall back to a hacky bit of awk to try to parse the YAML
ifeq ($(YQ_PATH),)
  $(warning WARNING: 'yq' command not found. Falling back to 'awk' for version extraction. Recommend installing 'yq' for robust YAML parsing.)
  API_VERSION := $(shell awk '/^info:/ {in_info=1} in_info && /^[ \t]*version:/ { match($$0, /^[ \t]*version:[ \t]*/); version = substr($$0, RSTART + RLENGTH); print version; exit}' $(SPEC_FILE_PATH))
else
  API_VERSION := $(shell $(YQ_PATH) '.info.version' $(SPEC_FILE_PATH))
endif
# --- Targets ---

# Default target: runs the full build
# Depends on the patching step, which in turn depends on generation.
# Also depends directly on the generated source sentinel to ensure rebuilds.
.PHONY: all build
all: build

build: patch-cargo-toml $(GENERATED_OUTPUT_SENTINEL)
# Run cargo build from the workspace root
# $(filter-out $@,$(MAKECMDGOALS)) passes through arguments like --release
	cargo build $(filter-out $@,$(MAKECMDGOALS))

# Target to run the OpenAPI generator, depends on the OpenAPI spec file.
# Make will only run this recipe if $(SPEC_FILE_PATH) is newer than $(GENERATED_OUTPUT_SENTINEL).
# Run the generator using podman, mapping in the API library crate as a volume
$(GENERATED_OUTPUT_SENTINEL): $(SPEC_FILE_PATH) | validate_version
	$(info Running OpenAPI Generator)
	@podman run --rm \
		-v "$(API_DIR)":/local \
		openapitools/openapi-generator-cli generate \
		-g rust-axum \
		--generate-alias-as-model \
		--additional-properties=packageName=$(API_PACKAGE),packageVersion=$(API_VERSION) \
		-i /local/$(SPEC_FILE) \
		-o /local

# Target to patch generated Cargo.toml
# It depends on the generator output sentinel to ensure patching happens after generation.
.PHONY: patch-cargo-toml
patch-cargo-toml: $(GENERATED_OUTPUT_SENTINEL)
# Check if the build line exists, add if not.
	@grep -q 'build = "build.rs"' "$(API_CARGO_TOML)" || \
		{ \
		sed -i '/edition = /a build = "build.rs"' "$(API_CARGO_TOML)"; \
		printf "Added 'build = \"build.rs\"' to %s\n" $(API_CARGO_TOML); \
	    }

# Target to clean generated files and Cargo artifacts
.PHONY: clean
clean:
	cargo clean

# Get API version
.PHONY: api_version
api_version: validate_version
	@echo "Extracted API Version: $(API_VERSION)"

# Validate API version string
# See https://semver.org/spec/v2.0.0.html#backusnaur-form-grammar-for-valid-semver-versions
SEMVER_REGEX := "^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$$"
.PHONY: validate_version
validate_version:
	@echo "$(API_VERSION)" | grep -E -q $(SEMVER_REGEX) || \
	{ printf "ERROR: Extracted API version '%s' is not a valid SemVer 2.0.0 string.\nSee the SemVer specification at: https://semver.org/spec/v2.0.0.html\n" $(API_VERSION); exit 1; }

