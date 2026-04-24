SWIFT ?= swift
XCODE_DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
APP_SCHEME_ENV = DEVELOPER_DIR=$(XCODE_DEVELOPER_DIR)
STAGED_APP_DIR ?= ./dist
STAGED_APP_NAME ?= MacTextActions Dev.app
STAGED_APP_PATH = $(STAGED_APP_DIR)/$(STAGED_APP_NAME)
PROD_APP_NAME ?= MacTextActions.app
PROD_APP_PATH = $(STAGED_APP_DIR)/$(PROD_APP_NAME)
SIGNED_PROD_ARCHIVE_NAME ?= MacTextActions-signed.zip
SIGNED_PROD_ARCHIVE_PATH = $(STAGED_APP_DIR)/$(SIGNED_PROD_ARCHIVE_NAME)
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
BUNDLE_EXECUTABLE_NAME ?= MacTextActionsApp
PLIST_BUDDY ?= /usr/libexec/PlistBuddy
RCODESIGN ?= rcodesign
CODESIGN ?= codesign
SIGNING_MODE ?= self-signed
SIGNING_DIR ?= $(HOME)/.mac-text-actions-signing
SELF_SIGNED_P12_PATH ?= $(SIGNING_DIR)/self-signed-cert.p12
SELF_SIGNED_PASSWORD_PATH ?= $(SIGNING_DIR)/self-signed-cert.password
SELF_SIGNED_PERSON_NAME ?= Mac Text Actions Local Signing

define create_app_bundle_skeleton
	mkdir -p "$(1)/Contents/MacOS"
	mkdir -p "$(1)/Contents/Resources"
	printf 'APPL????' > "$(1)/Contents/PkgInfo"
	rm -f "$(1)/Contents/Info.plist"
	plutil -create xml1 "$(1)/Contents/Info.plist"
	"$(PLIST_BUDDY)" -c "Add :CFBundleDevelopmentRegion string en" "$(1)/Contents/Info.plist"
	"$(PLIST_BUDDY)" -c "Add :CFBundleExecutable string $(BUNDLE_EXECUTABLE_NAME)" "$(1)/Contents/Info.plist"
	"$(PLIST_BUDDY)" -c "Add :CFBundleIconFile string AppIcon" "$(1)/Contents/Info.plist"
	"$(PLIST_BUDDY)" -c "Add :CFBundleIdentifier string $(2)" "$(1)/Contents/Info.plist"
	"$(PLIST_BUDDY)" -c "Add :CFBundleInfoDictionaryVersion string 6.0" "$(1)/Contents/Info.plist"
	"$(PLIST_BUDDY)" -c "Add :CFBundleName string $(3)" "$(1)/Contents/Info.plist"
	"$(PLIST_BUDDY)" -c "Add :CFBundleDisplayName string $(3)" "$(1)/Contents/Info.plist"
	"$(PLIST_BUDDY)" -c "Add :CFBundlePackageType string APPL" "$(1)/Contents/Info.plist"
	"$(PLIST_BUDDY)" -c "Add :CFBundleShortVersionString string 1.0.0" "$(1)/Contents/Info.plist"
	"$(PLIST_BUDDY)" -c "Add :CFBundleVersion string 1" "$(1)/Contents/Info.plist"
	"$(PLIST_BUDDY)" -c "Add :LSMinimumSystemVersion string 13.0" "$(1)/Contents/Info.plist"
	"$(PLIST_BUDDY)" -c "Add :LSUIElement bool true" "$(1)/Contents/Info.plist"
endef

define ensure_command
	command -v "$(1)" >/dev/null 2>&1 || { \
		echo "❌ 未找到命令: $(1)"; \
		echo "ℹ️ 请先安装对应工具后再重试。"; \
		exit 1; \
	}
endef

define ensure_file
	[ -f "$(1)" ] || { \
		echo "❌ 缺少文件: $(1)"; \
		echo "ℹ️ 请先补齐签名材料后再重试。"; \
		exit 1; \
	}
endef

define ensure_directory
	[ -d "$(1)" ] || { \
		echo "❌ 缺少目录: $(1)"; \
		echo "ℹ️ 请先构建应用后再执行当前目标。"; \
		exit 1; \
	}
endef

define ensure_self_signed_mode
	[ "$(SIGNING_MODE)" = "self-signed" ] || { \
		echo "❌ 当前仅支持 SIGNING_MODE=self-signed"; \
		echo "ℹ️ Developer ID 正式签名和公证链路需在后续单独接入。"; \
		exit 1; \
	}
endef

define ensure_self_signed_materials
	$(call ensure_file,$(SELF_SIGNED_P12_PATH))
	$(call ensure_file,$(SELF_SIGNED_PASSWORD_PATH))
endef

define sign_app_bundle
	"$(RCODESIGN)" sign \
		--p12-file "$(SELF_SIGNED_P12_PATH)" \
		--p12-password-file "$(SELF_SIGNED_PASSWORD_PATH)" \
		"$(1)"
endef

define verify_signed_bundle
	"$(CODESIGN)" --verify --deep --strict --verbose=2 "$(1)"
endef

define sync_signed_dev_bundle
	mkdir -p "$(DEV_INSTALL_DIR)"
	if pgrep -x "$(DEV_EXECUTABLE_NAME)" >/dev/null 2>&1; then \
		pkill -x "$(DEV_EXECUTABLE_NAME)"; \
		sleep 1; \
	fi
	rm -rf "$(DEV_APP_PATH)"
	ditto "$(STAGED_APP_PATH)" "$(DEV_APP_PATH)"
	touch "$(DEV_APP_PATH)"
endef

.PHONY: help test build build-core build-app build-prod-app init-self-signed-cert sign-dev-app sign-prod-app build-signed-dev-app build-signed-prod-app verify-dev-app-signature verify-prod-app-signature package-signed-prod-app install-app install-signed-app install-dev-app install-signed-dev-app refresh-dev-app refresh-signed-dev-app run-dev-app dev-app signed-dev-app lint clean

help:
	@printf "Available targets:\n"
	@printf "  make test       - Run unit tests for the package\n"
	@printf "  make build      - Build core and app targets\n"
	@printf "  make build-core - Build MacTextActionsCore target\n"
	@printf "  make build-app       - Build a local Dev.app template under ./dist\n"
	@printf "  make build-prod-app  - Build a local production app template under ./dist\n"
	@printf "  make init-self-signed-cert - Create or reuse a local self-signed certificate for rcodesign\n"
	@printf "  make build-signed-dev-app  - Build and self-sign the Dev.app template\n"
	@printf "  make build-signed-prod-app - Build and self-sign the production app template\n"
	@printf "  make package-signed-prod-app - Zip the self-signed production app for trusted distribution\n"
	@printf "  make install-signed-app     - Install the self-signed production app into /Applications\n"
	@printf "  make install-signed-dev-app - Install the self-signed Dev.app into ~/Applications\n"
	@printf "  make refresh-signed-dev-app - Refresh the installed self-signed Dev.app in place\n"
	@printf "  make signed-dev-app         - Refresh and launch the self-signed Dev.app\n"
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
	# 3. 生成本地开发版模板，避免依赖 SwiftPM 不会产出的 .app 包
	mkdir -p "$(STAGED_APP_DIR)"
	rm -rf "$(STAGED_APP_PATH)"
	$(call create_app_bundle_skeleton,$(STAGED_APP_PATH),$(DEV_BUNDLE_IDENTIFIER),$(DEV_BUNDLE_NAME))
	# 4. 用最新可执行文件和图标资源刷新模板 bundle
	cp -f "$(BUILD_EXECUTABLE_PATH)" "$(STAGED_APP_PATH)/Contents/MacOS/$(BUNDLE_EXECUTABLE_NAME)"
	chmod +x "$(STAGED_APP_PATH)/Contents/MacOS/$(BUNDLE_EXECUTABLE_NAME)"
	cp -f "$(BUILD_ICON_PATH)" "$(STAGED_APP_PATH)/Contents/Resources/AppIcon.icns"
	@echo "✅ 开发版模板已生成: $(STAGED_APP_PATH)"

build-prod-app:
	# 1. 构建 release 版本的可执行文件
	$(APP_SCHEME_ENV) $(SWIFT) build --product MacTextActionsApp -c release
	# 2. 导出正式版静态应用图标资源
	rm -rf "$(BUILD_ICONSET_PATH)"
	rm -f "$(BUILD_ICON_PATH)"
	"$(BUILD_EXECUTABLE_PATH)" --export-app-iconset "$(BUILD_ICONSET_PATH)"
	iconutil -c icns "$(BUILD_ICONSET_PATH)" -o "$(BUILD_ICON_PATH)"
	# 3. 生成正式版模板，避免依赖 SwiftPM 不会产出的 .app 包
	mkdir -p "$(STAGED_APP_DIR)"
	rm -rf "$(PROD_APP_PATH)"
	$(call create_app_bundle_skeleton,$(PROD_APP_PATH),$(PROD_BUNDLE_IDENTIFIER),$(PROD_BUNDLE_NAME))
	# 4. 刷新正式版 bundle 的可执行文件和图标资源
	cp -f "$(BUILD_EXECUTABLE_PATH)" "$(PROD_APP_PATH)/Contents/MacOS/$(BUNDLE_EXECUTABLE_NAME)"
	chmod +x "$(PROD_APP_PATH)/Contents/MacOS/$(BUNDLE_EXECUTABLE_NAME)"
	cp -f "$(BUILD_ICON_PATH)" "$(PROD_APP_PATH)/Contents/Resources/AppIcon.icns"
	@echo "✅ 正式版模板已生成: $(PROD_APP_PATH)"

init-self-signed-cert:
	# 1. 仅允许当前的自签名模式，避免误导为正式发布证书
	$(call ensure_self_signed_mode)
	# 2. rcodesign 与 openssl 都是初始化签名材料的必要依赖
	$(call ensure_command,$(RCODESIGN))
	$(call ensure_command,openssl)
	mkdir -p "$(SIGNING_DIR)"
	if [ ! -f "$(SELF_SIGNED_PASSWORD_PATH)" ]; then \
		openssl rand -hex 24 > "$(SELF_SIGNED_PASSWORD_PATH)"; \
		chmod 600 "$(SELF_SIGNED_PASSWORD_PATH)"; \
	fi
	if [ ! -f "$(SELF_SIGNED_P12_PATH)" ]; then \
		"$(RCODESIGN)" generate-self-signed-certificate \
			--p12-file "$(SELF_SIGNED_P12_PATH)" \
			--p12-password "$$(cat "$(SELF_SIGNED_PASSWORD_PATH)")" \
			--person-name "$(SELF_SIGNED_PERSON_NAME)"; \
		chmod 600 "$(SELF_SIGNED_P12_PATH)"; \
		echo "✅ 已生成本地自签名证书: $(SELF_SIGNED_P12_PATH)"; \
	else \
		echo "ℹ️ 复用已有自签名证书: $(SELF_SIGNED_P12_PATH)"; \
	fi

sign-dev-app:
	# 1. 对已构建的 Dev.app 原地签名，保持固定 bundle 标识
	$(call ensure_self_signed_mode)
	$(call ensure_command,$(RCODESIGN))
	$(call ensure_command,$(CODESIGN))
	$(call ensure_directory,$(STAGED_APP_PATH))
	$(call ensure_self_signed_materials)
	$(call sign_app_bundle,$(STAGED_APP_PATH))
	$(call verify_signed_bundle,$(STAGED_APP_PATH))
	@echo "✅ 开发版模板已完成自签名: $(STAGED_APP_PATH)"

sign-prod-app:
	# 1. 对已构建的正式版 .app 原地签名，供可信范围内分发
	$(call ensure_self_signed_mode)
	$(call ensure_command,$(RCODESIGN))
	$(call ensure_command,$(CODESIGN))
	$(call ensure_directory,$(PROD_APP_PATH))
	$(call ensure_self_signed_materials)
	$(call sign_app_bundle,$(PROD_APP_PATH))
	$(call verify_signed_bundle,$(PROD_APP_PATH))
	@echo "✅ 正式版模板已完成自签名: $(PROD_APP_PATH)"

build-signed-dev-app: build-app sign-dev-app

build-signed-prod-app: build-prod-app sign-prod-app

verify-dev-app-signature:
	$(call ensure_command,$(CODESIGN))
	$(call ensure_directory,$(STAGED_APP_PATH))
	$(call verify_signed_bundle,$(STAGED_APP_PATH))
	@echo "✅ 开发版签名校验通过: $(STAGED_APP_PATH)"

verify-prod-app-signature:
	$(call ensure_command,$(CODESIGN))
	$(call ensure_directory,$(PROD_APP_PATH))
	$(call verify_signed_bundle,$(PROD_APP_PATH))
	@echo "✅ 正式版签名校验通过: $(PROD_APP_PATH)"

package-signed-prod-app: build-signed-prod-app
	ditto -c -k --sequesterRsrc --keepParent "$(PROD_APP_PATH)" "$(SIGNED_PROD_ARCHIVE_PATH)"
	@echo "✅ 自签名正式版压缩包已生成: $(SIGNED_PROD_ARCHIVE_PATH)"

install-app: build-prod-app
	mkdir -p "$(PROD_INSTALL_DIR)"
	rm -rf "$(PROD_INSTALL_PATH)"
	ditto "$(PROD_APP_PATH)" "$(PROD_INSTALL_PATH)"
	touch "$(PROD_INSTALL_PATH)"
	@echo "✅ 正式版已安装: $(PROD_INSTALL_PATH)"

install-signed-app: build-signed-prod-app
	mkdir -p "$(PROD_INSTALL_DIR)"
	rm -rf "$(PROD_INSTALL_PATH)"
	ditto "$(PROD_APP_PATH)" "$(PROD_INSTALL_PATH)"
	touch "$(PROD_INSTALL_PATH)"
	@echo "✅ 自签名正式版已安装: $(PROD_INSTALL_PATH)"
	@echo "ℹ️ 该版本适合自测或可信范围内分发，仍不等同于 Developer ID + notarization 正式发行包。"

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

install-signed-dev-app: build-signed-dev-app
	# 1. 保持固定安装路径，但每次安装都写入完整签名 bundle，避免签名失效
	$(call sync_signed_dev_bundle)
	@echo "✅ 固定自签名开发版已安装: $(DEV_APP_PATH)"
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

refresh-signed-dev-app: build-signed-dev-app
	# 1. 通过整包覆盖保持签名一致，尽量降低系统重复授权概率
	$(call sync_signed_dev_bundle)
	open "$(DEV_APP_PATH)"
	@echo "✅ 固定自签名开发版已就地刷新: $(DEV_APP_PATH)"

run-dev-app:
	open "$(DEV_APP_PATH)"

dev-app: refresh-dev-app run-dev-app

signed-dev-app: refresh-signed-dev-app

lint:
	swiftlint

clean:
	$(SWIFT) package clean
	rm -rf "$(STAGED_APP_DIR)"
