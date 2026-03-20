# 群晖管家 / Project Status

## 当前状态

这是一个基于 Flutter 的 Synology DSM 7+ 手机管理工具项目，已经从手工源码骨架推进到标准 Flutter 工程，并进入真实 DSM 联调阶段。

当前项目状态：
- 已执行 `flutter create .` 补全标准工程
- 已删除不需要的平台目录：`linux/`、`macos/`、`windows/`、`web/`
- 已在 Flutter SDK 环境完成：
  - `flutter pub get`
  - `flutter gen-l10n`
  - `flutter analyze`
- App 已在设备上成功运行
- Android Gradle / Maven 仓库已调整为：阿里云镜像优先，官方源兜底
- 认证层已切换到 DSM v7 登录主线，不再保留 v6 兼容方向

## 已完成模块

### 登录页
- 地址 / 域名 / IP
- 端口
- 基础路径
- HTTPS 开关
- 用户名记忆
- 测试连接
- DSM 登录
- 历史设备快速登录模式（有历史记录时优先展示）
- 历史设备选择已收敛进快速登录卡片内部，不再额外单独占用上方页面区域
- 快速登录进一步收敛为：历史设备选择 + 默认只读用户名 + 密码输入
- 支持在快速登录模式下临时切换“更换账号”编辑用户名
- 快速登录卡片新增当前选中设备摘要，减少用户对“当前正在登录哪台 NAS”的疑惑
- 登录页顶部蓝色介绍卡已减重，首屏视觉焦点进一步回到登录动作本身
- 顶部蓝卡中的“快速登录 / 测试连接”快捷入口已移除，避免与下方真实操作区重复
- 已修复一次快速登录用户名编辑区引入的 `Padding/TextField` 括号闭合错误
- 快速登录 / 新账号登录双模式切换
- 登录前 DSM 版本探测
- DSM 6 不支持提示

### 启动恢复
- 恢复当前设备
- 恢复 SID / SynoToken / Cookie / 认证扩展状态

### 首页
- 连接信息
- 会话状态
- 基础资源卡片
- 设备信息卡
- 运行时间卡
- 首页已改为 HTTP 概览 + WS 实时指标合并显示
- 首页系统版本不再重复展示，统一只保留在顶部主卡区域
- 首页版本号已开始切换到更可靠的数据源：`SYNO.Entry.Request` -> `SYNO.Core.Upgrade.Server.check`
- 首页运行时间已开始切换到更可靠的数据源：`SYNO.Core.System.SystemHealth.get`
- 首页运行时间卡已增加本地定时器递增显示
- 已修复一次 dashboard 页 `_MetricCard` 中 `Column` 结束括号误写导致的编译错误
- 首页已移除设备信息卡（model / SN）
- 首页存储空间按 volume 展示占用情况
- 首页存储空间补充“已用 / 总计”具体数值展示，并对空值做兜底
- `volume1` / `volume2` 等默认名在首页转换为“存储空间1 / 存储空间2”样式

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
- SynoToken / CookieHeader 存在性展示

### 主题与多语言
- Material 3 主题模式切换（系统 / 浅色 / 深色）
- 主题色切换（蓝 / 绿 / 橙 / 紫）
- 语言切换骨架（系统 / 中文 / English）
- 本地持久化主题和语言设置
- 登录页 / 首页 / 设置页 / 文件页 / 下载页 / 部分调试与详情页文案已迁移到 l10n

### 错误处理
- 基础网络错误映射
- 部分 DSM 错误码中文化
- 首页实时监控失败时不再整页报错，而是降级显示
- 已增加 websocket / HTTP 控制台调试日志

## 已完成的工程动作

### Flutter 工程与校验
- 已使用 `flutter create .` 生成标准 Flutter 项目结构
- 已修复 `test/widget_test.dart` 中默认 `MyApp` 引用问题，改为当前应用入口 `QunhuiManagerApp`
- 已修复若干导入路径问题与无效空断言
- 当前静态分析通过
- App 已在设备上成功运行

### Android 工程
- 已补全 `android/` 工程
- 已将 `android/settings.gradle.kts` 与 `android/build.gradle.kts` 调整为国内镜像优先
- 当前策略：
  - 阿里云 `google`
  - 阿里云 `public`
  - 阿里云 `central`
  - 阿里云 `gradle-plugin`
  - 官方源兜底（`google()` / `mavenCentral()` / `gradlePluginPortal()`）

### DSM Realtime Socket
- 已确认 DSM 首页资源数据来自 socket 推送，而不是简单 HTTP 概览接口
- 已完成 engine.io polling + websocket upgrade + Cookie/Origin + socket.io 帧级联调
- 已完成 DSM `request_webapi` 帧格式联调
- 当前已成功通过 websocket 获取首页实时资源快照：
  - `SYNO.Core.System.Utilization` `get`
- 当前首页资源映射：
  - CPU → `user_load + system_load + other_load`
  - 内存 → `memory.real_usage`
  - 存储总览 → `space.total.utilization`
  - 各存储空间 → `space.volume[].display_name + utilization`
- 已补充 volume 级别容量字段读取（若接口返回则展示 used / total）
- `subscribe` 当前返回错误码 `103`，已暂时移除，只保留 `get` 路径确保首页稳定展示
- 首页当前已改为：HTTP 概览（设备名/版本/设备信息/uptime）+ WS 实时指标（CPU/内存/存储）合并展示

### 认证层
- 已确认 DSM Web UI 的 realtime 业务层依赖 DSM v7 登录链路
- 已切换到 DSM v7 登录主线（`entry.cgi` + `version=7`）
- 已开始扩展会话状态以承载：
  - `SynoToken`
  - Cookie Header
  - Request Hash Seed
  - Auth Token
  - Request Nonce
- 当前 DSM v7 登录已成功返回：
  - `sid`
  - `synotoken`
  - `device_id`
- 登录前新增 DSM 版本探测逻辑，用于拦截 DSM 6 并给出明确提示
- 但完整 Noise 握手 / `SynoHash` 生成链路仍未实现完毕

## 当前限制

- 首页实时资源 `get` 已成功，但真正的持续订阅流仍未完成
- 首页版本信息虽然已补强兜底逻辑，但仍受限于 DSM HTTP 概览接口的实际返回字段，部分设备上可能仍需额外接口补齐
- 设备信息 / 运行时间 / 服务器名目前仍主要依赖 HTTP 概览接口；若该接口字段不完整，首页对应区域仍可能为空或占位
- DSM Web UI 使用的完整 Noise / `SynoHash` 请求链路尚未完全实现
- 登录页快速登录 / 新账号登录双模式已接入，但仍需真机验证交互体验与边界行为
- 登录页退出后表单回填已开始修正，但仍需真机继续验证
- 国际化文案目前只完成部分页面迁移，尚未覆盖全部页面文案
- 上传、分享等功能已完成骨架，但仍需真实 DSM 联调验证
- iOS 尚未在真实 Apple 开发环境验证
- 当前环境缺少 Flutter SDK，无法在本机执行 `flutter analyze` / `flutter run` 做最终校验

## 建议下一步

1. 在真机 / Flutter 环境验证本次改动：
   - 快速登录默认模式是否符合预期
   - 新账号登录切换是否顺滑
   - DSM 6 提示是否准确
   - 首页系统版本信息是否稳定显示
   - 首页 volume 展示是否与真实 DSM 一致
2. 继续完善 DSM v7 Noise 登录实现：
   - `ik_message` / `kk_message`
   - handshake hash / request hash
3. 若要实现真正实时刷新，继续研究 `subscribe` 返回 `103` 的原因
4. 继续首页收尾：
   - 校正设备信息 / uptime 的 HTTP 数据来源
   - 如有必要，补单独系统信息接口
5. 继续 DSM 7 真实联调：
   - 文件列表
   - 下载任务
6. 完成登录页退出后表单回填验证与修复
7. 继续清理剩余国际化硬编码文案
8. 后续所有开发动作都要同步写入 `PROJECT_STATUS.md` 与工作日志，保证可恢复进度

## 留痕规则

从本次开始，后续所有与本项目相关的操作都必须留痕，至少包括：
- 修改了什么
- 为什么改
- 改到了哪些文件
- 当前是否已验证
- 下一步建议做什么

建议最少同步到以下两处：
- `project/qunhuimanage/PROJECT_STATUS.md`：面向项目全局的持续状态
- `memory/YYYY-MM-DD.md`：面向当天工作过程的时间线日志

若某次变更较大，还应补充：
- git commit（若本机已配置 git 用户信息）
- 必要的运行/验证记录

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
