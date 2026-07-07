.PHONY: install fmt lint type test clean help ci

help:
	@echo "Available targets:"
	@echo "  make install    - Install dependencies"
	@echo "  make fmt        - Format code (black, isort)"
	@echo "  make lint       - Run linters (ruff)"
	@echo "  make type       - Run type checking (mypy)"
	@echo "  make test       - Run tests (pytest)"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make ci         - Run full CI pipeline"

install:
	pip install -e ".[dev]"

fmt:
	black .
	isort .

fmt-check:
	@if black --check . && isort --check . ; then echo "✓ Format check passed"; else exit 1; fi

lint:
	ruff check .

type:
	mypy . --ignore-missing-imports

test:
	pytest -v --cov=. --cov-report=term-missing

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +
	find . -type d -name .mypy_cache -exec rm -rf {} +
	rm -rf .coverage htmlcov build dist *.egg-info

ci: fmt-check lint type test

.DEFAULT_GOAL := help
