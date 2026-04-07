SWIFT ?= swift
XCODE_DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
APP_SCHEME_ENV = DEVELOPER_DIR=$(XCODE_DEVELOPER_DIR)
STAGED_APP_DIR ?= ./dist
STAGED_APP_NAME ?= MacTextActions Dev.app
STAGED_APP_PATH = $(STAGED_APP_DIR)/$(STAGED_APP_NAME)
PROD_APP_NAME ?= MacTextActions.app
PROD_APP_PATH = $(STAGED_APP_DIR)/$(PROD_APP_NAME)
BUILD_APP_TEMPLATE_PATH = .build/MacTextActions.app
BUILD_EXECUTABLE_PATH = .build/release/MacTextActionsApp
BUILD_ICONSET_PATH = .build/AppIcon.iconset
BUILD_ICON_PATH = .build/AppIcon.icns
DEV_INSTALL_DIR ?= $(HOME)/Applications
DEV_APP_NAME ?= MacTextActions Dev.app
DEV_APP_PATH = $(DEV_INSTALL_DIR)/$(DEV_APP_NAME)
DEV_EXECUTABLE_PATH = $(DEV_APP_PATH)/Contents/MacOS/MacTextActionsApp
DEV_BUNDLE_IDENTIFIER ?= com.macTextActions.app.dev
DEV_BUNDLE_NAME ?= MacTextActions Dev
PROD_INSTALL_DIR ?= /Applications
PROD_INSTALL_PATH = $(PROD_INSTALL_DIR)/$(PROD_APP_NAME)
PROD_BUNDLE_IDENTIFIER ?= com.macTextActions.app
PROD_BUNDLE_NAME ?= MacTextActions
DEV_EXECUTABLE_NAME ?= MacTextActionsApp

.PHONY: help test build build-core build-app build-prod-app install-app install-dev-app refresh-dev-app run-dev-app dev-app lint clean

help:
	@printf "Available targets:\n"
	@printf "  make test       - Run unit tests for the package\n"
	@printf "  make build      - Build core and app targets\n"
	@printf "  make build-core - Build MacTextActionsCore target\n"
	@printf "  make build-app       - Build a local Dev.app template under ./dist\n"
	@printf "  make build-prod-app  - Build a local production app template under ./dist\n"
	@printf "  make install-app     - Install the production app into /Applications\n"
	@printf "  make install-dev-app - Install the fixed Dev.app into ~/Applications\n"
	@printf "  make refresh-dev-app - Refresh the installed Dev.app in place\n"
	@printf "  make run-dev-app     - Launch the fixed Dev.app\n"
	@printf "  make dev-app         - Refresh and launch the fixed Dev.app\n"
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
	# 2. 导出静态应用图标资源，供 Finder 和应用列表使用
	rm -rf "$(BUILD_ICONSET_PATH)"
	rm -f "$(BUILD_ICON_PATH)"
	"$(BUILD_EXECUTABLE_PATH)" --export-app-iconset "$(BUILD_ICONSET_PATH)"
	iconutil -c icns "$(BUILD_ICONSET_PATH)" -o "$(BUILD_ICON_PATH)"
	# 3. 生成本地开发版模板，避免继续把 .app 复制到仓库根目录
	mkdir -p "$(STAGED_APP_DIR)"
	rm -rf "$(STAGED_APP_PATH)"
	ditto "$(BUILD_APP_TEMPLATE_PATH)" "$(STAGED_APP_PATH)"
	# 4. 用最新可执行文件和图标资源刷新模板 bundle
	cp -f "$(BUILD_EXECUTABLE_PATH)" "$(STAGED_APP_PATH)/Contents/MacOS/MacTextActionsApp"
	chmod +x "$(STAGED_APP_PATH)/Contents/MacOS/MacTextActionsApp"
	mkdir -p "$(STAGED_APP_PATH)/Contents/Resources"
	cp -f "$(BUILD_ICON_PATH)" "$(STAGED_APP_PATH)/Contents/Resources/AppIcon.icns"
	# 5. 固定开发版 bundle 信息，便于后续安装到稳定路径
	plutil -replace CFBundleIdentifier -string "$(DEV_BUNDLE_IDENTIFIER)" "$(STAGED_APP_PATH)/Contents/Info.plist"
	plutil -replace CFBundleName -string "$(DEV_BUNDLE_NAME)" "$(STAGED_APP_PATH)/Contents/Info.plist"
	plutil -replace CFBundleDisplayName -string "$(DEV_BUNDLE_NAME)" "$(STAGED_APP_PATH)/Contents/Info.plist"
	plutil -replace CFBundleIconFile -string "AppIcon" "$(STAGED_APP_PATH)/Contents/Info.plist"
	@echo "✅ 开发版模板已生成: $(STAGED_APP_PATH)"

build-prod-app:
	# 1. 构建 release 版本的可执行文件
	$(APP_SCHEME_ENV) $(SWIFT) build --product MacTextActionsApp -c release
	# 2. 导出正式版静态应用图标资源
	rm -rf "$(BUILD_ICONSET_PATH)"
	rm -f "$(BUILD_ICON_PATH)"
	"$(BUILD_EXECUTABLE_PATH)" --export-app-iconset "$(BUILD_ICONSET_PATH)"
	iconutil -c icns "$(BUILD_ICONSET_PATH)" -o "$(BUILD_ICON_PATH)"
	# 3. 生成正式版模板
	mkdir -p "$(STAGED_APP_DIR)"
	rm -rf "$(PROD_APP_PATH)"
	ditto "$(BUILD_APP_TEMPLATE_PATH)" "$(PROD_APP_PATH)"
	# 4. 刷新正式版 bundle 的可执行文件和图标资源
	cp -f "$(BUILD_EXECUTABLE_PATH)" "$(PROD_APP_PATH)/Contents/MacOS/MacTextActionsApp"
	chmod +x "$(PROD_APP_PATH)/Contents/MacOS/MacTextActionsApp"
	mkdir -p "$(PROD_APP_PATH)/Contents/Resources"
	cp -f "$(BUILD_ICON_PATH)" "$(PROD_APP_PATH)/Contents/Resources/AppIcon.icns"
	# 5. 固定正式版 bundle 信息
	plutil -replace CFBundleIdentifier -string "$(PROD_BUNDLE_IDENTIFIER)" "$(PROD_APP_PATH)/Contents/Info.plist"
	plutil -replace CFBundleName -string "$(PROD_BUNDLE_NAME)" "$(PROD_APP_PATH)/Contents/Info.plist"
	plutil -replace CFBundleDisplayName -string "$(PROD_BUNDLE_NAME)" "$(PROD_APP_PATH)/Contents/Info.plist"
	plutil -replace CFBundleIconFile -string "AppIcon" "$(PROD_APP_PATH)/Contents/Info.plist"
	@echo "✅ 正式版模板已生成: $(PROD_APP_PATH)"

install-app: build-prod-app
	mkdir -p "$(PROD_INSTALL_DIR)"
	rm -rf "$(PROD_INSTALL_PATH)"
	ditto "$(PROD_APP_PATH)" "$(PROD_INSTALL_PATH)"
	touch "$(PROD_INSTALL_PATH)"
	@echo "✅ 正式版已安装: $(PROD_INSTALL_PATH)"

install-dev-app: build-app
	# 1. 首次安装时复制完整模板，后续保持固定安装路径
	mkdir -p "$(DEV_INSTALL_DIR)"
	if [ ! -d "$(DEV_APP_PATH)" ]; then \
		ditto "$(STAGED_APP_PATH)" "$(DEV_APP_PATH)"; \
	else \
		cp -f "$(STAGED_APP_PATH)/Contents/MacOS/MacTextActionsApp" "$(DEV_EXECUTABLE_PATH)"; \
		chmod +x "$(DEV_EXECUTABLE_PATH)"; \
		if [ -d "$(STAGED_APP_PATH)/Contents/Resources" ]; then \
			mkdir -p "$(DEV_APP_PATH)/Contents/Resources"; \
			ditto "$(STAGED_APP_PATH)/Contents/Resources" "$(DEV_APP_PATH)/Contents/Resources"; \
		fi; \
	fi
	plutil -replace CFBundleIdentifier -string "$(DEV_BUNDLE_IDENTIFIER)" "$(DEV_APP_PATH)/Contents/Info.plist"
	plutil -replace CFBundleName -string "$(DEV_BUNDLE_NAME)" "$(DEV_APP_PATH)/Contents/Info.plist"
	plutil -replace CFBundleDisplayName -string "$(DEV_BUNDLE_NAME)" "$(DEV_APP_PATH)/Contents/Info.plist"
	plutil -replace CFBundleIconFile -string "AppIcon" "$(DEV_APP_PATH)/Contents/Info.plist"
	touch "$(DEV_APP_PATH)"
	@echo "✅ 固定开发版已安装: $(DEV_APP_PATH)"
	@echo "ℹ️ 首次安装后，请只为这一个 Dev.app 授予辅助功能权限。"

refresh-dev-app:
	# 1. 若固定开发版尚未安装，则先执行首次安装
	if [ ! -d "$(DEV_APP_PATH)" ]; then \
		$(MAKE) install-dev-app; \
	else \
		if pgrep -x "$(DEV_EXECUTABLE_NAME)" >/dev/null 2>&1; then \
			pkill -x "$(DEV_EXECUTABLE_NAME)"; \
			sleep 1; \
		fi; \
		$(MAKE) build-app; \
		cp -f "$(STAGED_APP_PATH)/Contents/MacOS/MacTextActionsApp" "$(DEV_EXECUTABLE_PATH)"; \
		chmod +x "$(DEV_EXECUTABLE_PATH)"; \
		if [ -d "$(STAGED_APP_PATH)/Contents/Resources" ]; then \
			mkdir -p "$(DEV_APP_PATH)/Contents/Resources"; \
			ditto "$(STAGED_APP_PATH)/Contents/Resources" "$(DEV_APP_PATH)/Contents/Resources"; \
		fi; \
		plutil -replace CFBundleIdentifier -string "$(DEV_BUNDLE_IDENTIFIER)" "$(DEV_APP_PATH)/Contents/Info.plist"; \
		plutil -replace CFBundleName -string "$(DEV_BUNDLE_NAME)" "$(DEV_APP_PATH)/Contents/Info.plist"; \
		plutil -replace CFBundleDisplayName -string "$(DEV_BUNDLE_NAME)" "$(DEV_APP_PATH)/Contents/Info.plist"; \
		plutil -replace CFBundleIconFile -string "AppIcon" "$(DEV_APP_PATH)/Contents/Info.plist"; \
		touch "$(DEV_APP_PATH)"; \
		open "$(DEV_APP_PATH)"; \
		echo "✅ 固定开发版已就地刷新: $(DEV_APP_PATH)"; \
	fi

run-dev-app:
	open "$(DEV_APP_PATH)"

dev-app: refresh-dev-app run-dev-app

lint:
	swiftlint

clean:
	$(SWIFT) package clean
	rm -rf "$(STAGED_APP_DIR)"
