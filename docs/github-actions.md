# GitHub Actions 使用说明

## 已提供工作流

- `.github/workflows/android-release.yml`
- `.github/workflows/pr-check.yml`

## android-release.yml

触发条件：
- push 到 `main` / `master`
- push tag（如 `v0.1.0`）
- 手动触发 `workflow_dispatch`

执行内容：
1. checkout
2. 安装 Java 17
3. 安装 Flutter stable
4. `flutter pub get`
5. `flutter analyze`（continue-on-error，不阻断流程）
6. 构建 release APK（按 ABI 分包）
7. 构建 release AAB
8. 上传 APK / AAB / symbols / mapping

## pr-check.yml

触发条件：
- PR 到 `main` / `master`

执行内容：
1. checkout
2. 安装 Java 17
3. 安装 Flutter stable
4. `flutter pub get`
5. `flutter analyze`（continue-on-error，不阻断流程）

## 产物位置

GitHub Actions 执行完成后，在 Actions 页面对应运行记录的 Artifacts 中可下载：

- `android-apk-release`
- `android-obfuscation-symbols`
- `android-r8-mapping`

## 当前限制

当前项目还未配置正式签名：
- Android release 仍走 debug signing
- 适合内部测试与 CI 验证
- 不适合正式上架发布

## 后续建议

后续正式发布前建议补：
1. release keystore
2. key.properties / GitHub Secrets
3. 正式 applicationId
4. GitHub Release 自动发版
