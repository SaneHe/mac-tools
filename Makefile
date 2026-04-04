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
	# 1. 构建 release 版本的可执行文件（必须使用 --product 才会链接）
	$(APP_SCHEME_ENV) $(SWIFT) build --product MacTextActionsApp -c release
	# 2. 将新的可执行文件复制到 .app bundle 中
	cp -f .build/release/MacTextActionsApp .build/MacTextActions.app/Contents/MacOS/MacTextActionsApp
	# 3. 确保可执行文件有执行权限
	chmod +x .build/MacTextActions.app/Contents/MacOS/MacTextActionsApp
	# 4. 复制到项目根目录
	cp -R .build/MacTextActions.app ./MacTextActions.app
	@echo "✅ MacTextActions.app 已生成到当前目录"

lint:
	swiftlint

clean:
	$(SWIFT) package clean
