# Android 自动化构建与体积优化

## 已配置内容

项目已补充：

- Gitee 可用流水线：`.gitee/workflows/android-release.yml`
- Android R8 / ProGuard 规则：`android/app/proguard-rules.pro`
- Release 构建建议：
  - `minifyEnabled = true`
  - `shrinkResources = true`
  - `--obfuscate`
  - `--split-debug-info`
  - `--split-per-abi`

## 推荐产物

### 调试联调
- APK debug

### 内测分发
- APK release（按 ABI 分包）
  - `app-arm64-v8a-release.apk`
  - `app-armeabi-v7a-release.apk`
  - `app-x86_64-release.apk`

### 正式发布
- AAB release

## 推荐命令

### APK（按 ABI 分包）
```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
```

### AAB
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

## 体积优化建议

### 1. 开启 R8 + 资源收缩
通过 Gradle release 配置：
- `isMinifyEnabled = true`
- `isShrinkResources = true`

### 2. Flutter Dart 层混淆
通过构建参数：
- `--obfuscate`
- `--split-debug-info=...`

### 3. ABI 分包
通过：
- `--split-per-abi`

这样可显著降低单个 APK 体积。

### 4. 图标 / 图片资源控制
- 优先 webp
- 避免超大 png
- 避免未使用资源长期留在 `assets/`

### 5. 插件数量控制
当前项目包含：
- video_player
- photo_manager
- file_picker
- flutter_secure_storage

这些都合理，但后续不要轻易继续堆大型插件。

## Gitee 使用说明

如果你的 Gitee 企业版/流水线环境兼容 GitHub Actions 风格工作流，直接使用：
- `.gitee/workflows/android-release.yml`

如果你的 Gitee 环境使用自家 YAML 规范，也可以保留这份文件作为迁移模板，核心步骤不变：
1. checkout
2. 安装 Java 17
3. 安装 Flutter stable
4. `flutter pub get`
5. `flutter analyze`
6. `flutter build apk --release --split-per-abi --obfuscate --split-debug-info=...`
7. `flutter build appbundle --release --obfuscate --split-debug-info=...`
8. 上传 APK / AAB / symbols / mapping

## 发布前还建议补的内容

### 签名配置
当前项目默认还是 debug 签名风格，正式发布前应改为：
- `key.properties`
- release keystore
- release signingConfig

### applicationId
当前还是：
- `com.example.syno_keeper`

正式发布前必须替换成正式包名。

### 混淆回溯文件保存
务必保存：
- `build/app/outputs/symbols`
- `android/app/build/outputs/mapping/release`

否则线上崩溃会很难排查。
