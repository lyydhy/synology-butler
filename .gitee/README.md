# Gitee CI Notes

本目录放 Gitee 侧自动化构建配置。

已提供：
- `workflows/android-release.yml`

如果你的 Gitee 实例支持兼容 GitHub Actions 的工作流语法，可直接使用。
如果使用的是 Gitee 原生流水线语法，可将该文件作为步骤模板迁移。

核心构建步骤：
1. 安装 Java 17
2. 安装 Flutter stable
3. `flutter pub get`
4. `flutter analyze`
5. 构建 release APK（按 ABI 分包）
6. 构建 release AAB
7. 上传 APK / AAB / symbols / mapping
