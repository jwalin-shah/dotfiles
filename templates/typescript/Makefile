.PHONY: install build test fmt lint type clean help ci

help:
	@echo "Available targets:"
	@echo "  make install    - Install dependencies"
	@echo "  make build      - Build the project"
	@echo "  make test       - Run tests"
	@echo "  make fmt        - Format code (prettier)"
	@echo "  make lint       - Run linter (eslint)"
	@echo "  make type       - Run type checker (tsc)"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make ci         - Run full CI pipeline"

install:
	npm install

build:
	npm run build

test:
	npm test

fmt:
	npx prettier --write .

fmt-check:
	@if npx prettier --check . ; then echo "✓ Format check passed"; else exit 1; fi

lint:
	npx eslint . --ext .ts,.tsx,.js,.jsx

type:
	npx tsc --noEmit

clean:
	rm -rf node_modules dist coverage build

ci: fmt-check lint type test

.DEFAULT_GOAL := help
