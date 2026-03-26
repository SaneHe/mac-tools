SWIFT ?= swift
XCODE_DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
APP_SCHEME_ENV = DEVELOPER_DIR=$(XCODE_DEVELOPER_DIR)

.PHONY: help test build build-core build-app lint clean

help:
	@printf "Available targets:\n"
	@printf "  make test       - Run unit tests for the package\n"
	@printf "  make build      - Build core and app targets\n"
	@printf "  make build-core - Build MacTextActionsCore target\n"
	@printf "  make build-app  - Build MacTextActionsApp target (requires full Xcode setup)\n"
	@printf "  make lint       - Run SwiftLint if installed\n"
	@printf "  make clean      - Remove .build artifacts\n"

test:
	$(SWIFT) test

build: build-core build-app

build-core:
	$(SWIFT) build --target MacTextActionsCore

build-app:
	$(APP_SCHEME_ENV) $(SWIFT) build --target MacTextActionsApp

lint:
	swiftlint

clean:
	$(SWIFT) package clean
