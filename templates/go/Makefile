.PHONY: build test fmt lint clean help

help:
	@echo "Available targets:"
	@echo "  make build      - Build the binary"
	@echo "  make test       - Run tests"
	@echo "  make fmt        - Format code (gofmt, goimports)"
	@echo "  make lint       - Run linter (golangci-lint)"
	@echo "  make vet        - Run go vet"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make ci         - Run full CI pipeline (fmt check, vet, lint, test)"

build:
	go build -o bin/$(shell basename $$PWD) .

test:
	go test -v -race -coverprofile=coverage.out ./...

fmt:
	gofmt -w .
	go run golang.org/x/tools/cmd/goimports@latest -w .

fmt-check:
	@if ! gofmt -l . | grep -q .; then echo "✓ Format check passed"; else echo "Format issues found:"; gofmt -l .; exit 1; fi

vet:
	go vet ./...

lint:
	golangci-lint run ./...

clean:
	go clean
	rm -f bin/$(shell basename $$PWD) coverage.out

ci: fmt-check vet lint test

.DEFAULT_GOAL := help
