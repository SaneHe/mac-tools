# `rcodesign` 自签名接入设计

## 目标
- 在没有 `Apple Developer Program` 账号的前提下，为 `Mac Text Actions` 提供可维护的本地自签名流程
- 将签名入口收敛到 `Makefile`，同时保留未来切换到 `Developer ID + notarization` 的扩展空间
- 优先改善固定开发机上的 `Dev.app` 身份稳定性，降低因重复构建导致的重新授权成本

## 方案摘要
- 保留现有 `build-app` 与 `build-prod-app` 的未签名构建职责
- 新增 `init-self-signed-cert`、`sign-dev-app`、`sign-prod-app`、`build-signed-dev-app`、`build-signed-prod-app`
- 新增 `install-signed-dev-app` 与 `refresh-signed-dev-app`，通过整包覆盖固定路径上的 `Dev.app`，尽量保持签名结果一致
- 新增 `package-signed-prod-app`，产出适合可信范围内部分发的自签名压缩包

## 关键决策
- 签名工具选用开源 `rcodesign`，避免将方案绑定到 `codesign` 独占实现
- 自签名材料默认保存在 `~/.mac-text-actions-signing/`，不进入仓库，避免泄露私钥并减少误提交风险
- 仍明确区分“自签名内测版”和“正式公开发行版”：
  - 自签名用于开发、自测、可信内测
  - 正式公开分发仍需要 `Developer ID` 签名与 `Apple notarization`

## 风险与边界
- 自签名不能替代 `Gatekeeper` 对公开发行软件的信任链
- 删除并重建本地签名材料后，系统可能把应用视为新的签名身份
- 当前仓库的 `GitHub Release` 仍发布未签名压缩包；若后续要发布自签名或正式签名产物，需要单独改造工作流
