.PHONY: build test fmt lint clean help ci

help:
	@echo "Available targets:"
	@echo "  make build      - Build the project"
	@echo "  make test       - Run tests"
	@echo "  make fmt        - Format code (rustfmt)"
	@echo "  make lint       - Run clippy linter"
	@echo "  make doc        - Generate documentation"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make ci         - Run full CI pipeline"

build:
	cargo build --release

test:
	cargo test --verbose

fmt:
	cargo fmt --all

fmt-check:
	@if cargo fmt -- --check ; then echo "✓ Format check passed"; else exit 1; fi

lint:
	cargo clippy --all --all-targets -- -D warnings

doc:
	cargo doc --no-deps

clean:
	cargo clean

ci: fmt-check lint test doc

.DEFAULT_GOAL := help
