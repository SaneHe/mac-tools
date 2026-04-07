# Accessibility Dev Build Design

## 背景
当前仓库通过 `Swift Package` 直接产出 `MacTextActionsApp` 可执行文件，再由 `Makefile` 把该二进制手工复制进 `.app` bundle。这个流程适合快速拼出可运行产物，但对 `Accessibility` 这类依赖 `TCC` 身份识别的权限并不友好。

现象上表现为：
- 开发时重新 `build` 并安装 `.app` 后，经常需要重新授予辅助功能权限
- 安装版与调试版容易被系统视为不同对象
- 每次重装整包都会打断日常开发节奏

## 目标
- 为开发期提供一个固定的 `Dev.app` 身份
- 把日常迭代从“重装整个 `.app`”改为“就地刷新已安装开发版”
- 保留现有 `Swift Package` 结构，不在本轮引入完整 `Xcode` App target
- 让后续迁移到标准 macOS App 工程时具备清晰过渡路径

## 非目标
- 本轮不解决正式发布所需的签名、公证与分发问题
- 本轮不把仓库改造成完整 `Xcode project` / `workspace`
- 本轮不承诺彻底消除所有机器上的 `Accessibility` 重新授权现象

## 方案比较

### 方案 A：继续使用当前整包复制流程
优点：
- 不需要改动构建脚本

缺点：
- `.app` 身份不稳定
- 对 `Accessibility` 授权最不友好
- 日常开发重复劳动高

### 方案 B：固定开发版安装路径，并在已安装 app 内就地刷新
优点：
- 改动最小
- 不需要立即补齐完整 `Xcode` app 工程
- 能显著减少“重新安装整包”带来的权限抖动

缺点：
- 仍然属于过渡方案
- 受限于当前未签名、非标准 app target 的工程形态，不能保证所有机器都完全免授权

### 方案 C：立即切换到标准 `Xcode` App target
优点：
- 是长期正确方向
- 最有利于权限、签名、entitlements 和发布链路的稳定性

缺点：
- 本轮改动面过大
- 超出“先解决开发期权限冲突”的最小任务范围

## 结论
采用方案 B，先把开发链路收敛到一个固定身份的 `Dev.app`。

具体规则如下：
- 开发版 app 名称固定为 `MacTextActions Dev.app`
- 开发版安装路径固定为 `~/Applications/MacTextActions Dev.app`
- 开发版 `Bundle Identifier` 固定为 `com.macTextActions.app.dev`
- 首次安装使用完整 app 模板复制
- 后续日常开发优先使用“刷新已安装开发版”的方式，只更新可执行文件和必要资源

## 构建与使用约定
- `make build-app`
  - 生成本地开发版模板，不再把 `.app` 复制到仓库根目录
- `make install-dev-app`
  - 首次安装或重新引导开发版 app
- `make refresh-dev-app`
  - 基于固定安装路径，就地刷新已安装开发版
- `make dev-app`
  - 日常推荐入口，自动完成刷新并打开开发版 app

## 风险与后续
- 由于当前仓库尚未引入标准 `Xcode` app target，也没有正式签名链路，`Accessibility` 授权是否完全稳定仍受系统环境影响
- 若后续仍存在明显授权抖动，下一阶段应升级为标准 macOS App target，并将 `Info.plist`、entitlements、签名与打包流程完全交给 `Xcode`
