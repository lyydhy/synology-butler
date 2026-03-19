# 群晖管家 / Project Status

## 当前状态

这是一个基于 Flutter 的 Synology DSM 7+ 手机管理工具项目，已经从手工源码骨架推进到**标准 Flutter 工程**，并完成了 Android / iOS 平台骨架补全、依赖安装、国际化生成与静态检查。

当前项目状态：
- 已执行 `flutter create .` 补全标准工程
- 已删除不需要的平台目录：`linux/`、`macos/`、`windows/`、`web/`
- 已在本地 Flutter SDK 环境完成：
  - `flutter pub get`
  - `flutter gen-l10n`
  - `flutter analyze`
- 当前 `flutter analyze` 结果：**No issues found**
- Android Gradle / Maven 仓库已调整为：**阿里云镜像优先，官方源兜底**

## 已完成模块

### 登录页
- 地址 / 域名 / IP
- 端口
- 基础路径
- HTTPS 开关
- 用户名记忆
- 测试连接
- DSM 登录

### 启动恢复
- 恢复当前设备
- 恢复 SID

### 首页
- 连接信息
- 会话状态
- 基础资源卡片
- 设备信息卡
- 运行时间卡

### 文件模块
- 文件列表
- 路径导航
- 返回上一级
- 按名称 / 大小排序
- 新建文件夹
- 重命名
- 删除
- 生成分享链接
- 上传对话框与上传接口骨架
- 文件详情弹层

### 下载模块
- 任务列表
- 状态中文化
- 筛选
- 新建下载任务
- 暂停 / 恢复 / 删除
- 任务详情弹层

### 设置 / 连接管理
- 已保存设备
- 切换设备
- 编辑设备
- 删除设备
- 退出登录

### 调试支持
- 调试信息页
- 模块诊断页
- 当前连接 / 本地保存状态展示
- 基础联通测试（auth / file / download）

### 主题与多语言
- Material 3 主题模式切换（系统 / 浅色 / 深色）
- 主题色切换（蓝 / 绿 / 橙 / 紫）
- 语言切换骨架（系统 / 中文 / English）
- 本地持久化主题和语言设置
- 登录页 / 首页 / 设置页 / 文件页 / 下载页 / 部分调试与详情页文案已迁移到 l10n

### 错误处理
- 基础网络错误映射
- 部分 DSM 错误码中文化

## 已完成的工程动作

### Flutter 工程与校验
- 已使用 `flutter create .` 生成标准 Flutter 项目结构
- 已修复 `test/widget_test.dart` 中默认 `MyApp` 引用问题，改为当前应用入口 `QunhuiManagerApp`
- 已修复若干导入路径问题与无效空断言
- 当前静态分析通过

### Android 工程
- 已补全 `android/` 工程
- 已将 `android/settings.gradle.kts` 与 `android/build.gradle.kts` 调整为国内镜像优先
- 当前策略：
  - 阿里云 `google`
  - 阿里云 `public`
  - 阿里云 `central`
  - 阿里云 `gradle-plugin`
  - 官方源兜底（`google()` / `mavenCentral()` / `gradlePluginPortal()`）

## 当前限制

- 尚未执行 `flutter run` 的真实设备运行验证
- 尚未完成 Android 真机 / 模拟器联调
- 国际化文案目前只完成部分页面迁移，尚未覆盖全部页面文案
- DSM 系统资源接口仍为浅层骨架，部分字段可能需要真实 NAS 联调修正
- 部分 DSM API 参数和版本可能需要根据真实设备行为微调
- 上传、分享等功能已完成骨架，但仍需真实 DSM 联调验证
- iOS 尚未在真实 Apple 开发环境验证

## 建议下一步

1. 在 Windows 本地 SSD 环境 clone 项目并运行
2. 执行：
   - `flutter pub get`
   - `flutter gen-l10n`
   - `dart format .`
   - `flutter analyze`
   - `flutter run`
3. 连接 Android 真机，开始第一轮 UI / 路由 / 插件运行验证
4. 开始 DSM 7 真实联调：
   - 登录
   - 文件列表
   - 下载任务
5. 根据真实联调结果校正 DSM API 参数与返回结构
6. 继续清理剩余国际化硬编码文案

## 关键目录

- `android/` Android 工程
- `ios/` iOS 工程
- `lib/app/` 应用入口与路由
- `lib/core/` 通用工具、错误、存储、网络
- `lib/data/` API / models / repositories
- `lib/domain/` 实体和仓库接口
- `lib/features/` 功能模块页面与 provider
- `lib/l10n/` 国际化资源
- `RUN.md` 运行说明
