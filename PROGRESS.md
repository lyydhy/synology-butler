# Synology Butler 开发进度

## 2026-03-26 网络层重构与性能监控优化

### 一、网络层架构重构

#### 1. `DioClient` 与 `AppDioFactory` 合并

- **删除** `lib/core/network/dio_client.dart`
- **合并** 至 `lib/core/network/app_dio.dart`
- `businessDio()` 改为顶层函数，每次调用创建新实例（避免 `ignoreBadCertificate` 参数被缓存忽略）
- 导出 `connectionStore` 顶层变量供全局使用

```
之前:
  DioClient (dio_client.dart) ← 独立文件
  AppDioFactory.businessDio() ← 静态方法 + 全局缓存

之后:
  DioClient (app_dio.dart) ← 合并
  businessDio() ← 顶层函数，无缓存
  connectionStore ← 顶层变量导出
```

#### 2. API 类简化 - 去掉 Dio 构造器传参

所有 API 类不再从外部接收 `Dio` 实例，改为内部调用 `businessDio()`：

| 文件 | 改动 |
|------|------|
| `dsm_auth_api.dart` | `Dio get _dio => businessDio()` |
| `system_api.dart` | `Dio get _dio => businessDio(ignoreBadCertificate: ...)` |
| `file_station_api.dart` | 同上 |
| `download_station_api.dart` | 同上 |
| `package_api.dart` | 同上 |

**例外**：`DsmSystemApi` 保留 `ignoreBadCertificate` 参数，因为需要支持自签名证书跳过。

#### 3. Provider 简化

移除冗余的 `xxxApiProvider`，Repository 直接 new API 实例：

```dart
// 之前
final downloadStationApiProvider = Provider((ref) {
  return DsmDownloadStationApi(dio: ref.read(businessDioProvider));
});
final downloadRepositoryProvider = Provider((ref) {
  return DownloadRepositoryImpl(ref.read(downloadStationApiProvider));
});

// 之后
final downloadRepositoryProvider = Provider((ref) {
  return DownloadRepositoryImpl(DsmDownloadStationApi());
});
```

---

### 二、Session 恢复机制重构

#### 1. 问题根因

热重载后：
- `SessionRecoveryBridge.callback` 被清空
- `savedUsernameProvider` / `savedPasswordProvider`（Riverpod StateProvider）重置为 null
- 恢复时读不到凭证 → 报错

#### 2. 解决方案

**凭证存到 `connectionStore`（内存单例，热重载不丢失）**

```dart
// current_connection_store.dart
class AuthCredentials {
  final String username;
  final String password;
}

void setCredentials({required String username, required String password});
AuthCredentials? get credentials;
```

**登录时保存凭证**：

```dart
// auth_providers.dart - persistLoginProvider
if (rememberPassword) {
  connectionStore.setCredentials(username: username, password: password);
}
```

**恢复时优先读 `connectionStore`**：

```dart
// auth_providers.dart - recoverSessionProvider
final stored = connectionStore.credentials;
final username = stored?.username ?? ref.read(savedUsernameProvider);
final password = stored?.password ?? ref.read(savedPasswordProvider);
```

#### 3. SessionRecoveryInterceptor 修复

- 移除对 `SessionRecoveryBridge.callback` 的强制依赖
- callback 为 null 时，直接从 `connectionStore.credentials` 读凭证
- 修复 `_cloneOptions` 中 `Content-Type` header 与 `contentType` 参数冲突

---

### 三、性能监控页面重构

#### 1. 文件拆分

原 1500+ 行单文件拆分为 5 个模块：

```
performance/presentation/
├── pages/
│   └── performance_page.dart      ← 主逻辑 + history provider
└── widgets/
    ├── chart_painters.dart        ← 图表绘制 (MultiLineChart, MiniLineChart)
    ├── metric_cards.dart          ← 指标卡片组件
    ├── overview_cards.dart        ← 概览卡片组件
    └── tab_content.dart           ← 各 Tab 内容
```

#### 2. 数据流重构

```dart
// 之前: listenManual + fireImmediately (首次可能漏掉)
_overviewSubscription = ref.listenManual(..., fireImmediately: true);

// 之后: ref.watch 驱动 rebuild + history notifier 推送数据
final overview = ref.watch(dashboardOverviewSafeProvider);
overview.whenData((data) {
  if (data != null) {
    ref.read(perfHistoryProvider.notifier).push(data);
  }
});
```

#### 3. WebSocket 实时数据轮询

`system_api.dart` - `watchUtilization()` 增加定时器：

```dart
// 首次数据到达后，每 5 秒请求一次
Timer? periodicTimer;
void startPeriodicTimer() {
  periodicTimer = Timer.periodic(const Duration(seconds: 5), (_) => requestCurrent());
}
```

---

### 四、UI 组件优化

#### 1. 新增 `SlidingTabBar` 组件

位置：`lib/core/widgets/sliding_tab_bar.dart`

特性：
- 胶囊形背景 + 滑动指示器
- 图标 + 文字标签
- 220ms 切换动画
- 纯 `AnimationController` 实现，不依赖 Material `TabBar`

#### 2. 登录页面历史设备入口

- 移除 `DropdownButtonFormField`
- 改为底部文字按钮 → 弹出 `ModalBottomSheet` 列表
- 点击列表项自动填入服务器/用户名

#### 3. 信息中心页面 Tab 组件升级

- 使用 `SlidingTabBar` 替代 Material `TabBar`
- 统一性能监控/信息中心两页面的 Tab 样式

---

### 五、日志系统完善

#### 1. `system_api.dart` 日志改进

新增 getter 统一获取认证信息：

```dart
String get _baseUrl { ... }
String get _sid => connectionStore.session?.sid ?? '';
String? get _synoToken => connectionStore.session?.synoToken;
String? get _cookieHeader => connectionStore.session?.cookieHeader;
```

所有 `DsmLogger` 调用现在携带真实 `sid` / `synoToken` / `cookieHeader`。

#### 2. SessionRecoveryInterceptor 日志清理

移除所有 `debugPrint` 调试语句，统一使用 `DsmLogger`。

---

### 六、Bug 修复

| 问题 | 文件 | 修复 |
|------|------|------|
| 中文乱码 | 多个文件 | PowerShell 编码问题，改用直接 `write` 工具写入 UTF-8 |
| `static` 顶层变量 | `app_dio.dart` | 移除 `static` 关键字 |
| RenderFlex overflow | `login_page.dart` | `DropdownMenuItem` 内 `Column` 改为单行 `Text` |
| Content-Type 冲突 | `session_recovery_interceptor.dart` | `_cloneOptions` 移除 headers 中的 Content-Type |
| 图表单点偏移 | `chart_painters.dart` | 单点居中显示 |

---

### 七、文件变更清单

```
M  lib/core/network/app_dio.dart          # DioClient 合并，businessDio 顶层函数
M  lib/core/network/current_connection_store.dart  # 新增 AuthCredentials
D  lib/core/network/dio_client.dart       # 已删除
M  lib/core/network/session_recovery_interceptor.dart  # 热重载安全恢复
M  lib/data/api/*.dart                    # API 类简化
M  lib/features/*/providers/*.dart        # Provider 简化
M  lib/features/performance/presentation/ # 页面重构 + 组件拆分
M  lib/features/auth/presentation/        # 登录页历史设备入口
?? lib/core/widgets/                      # 新增 SlidingTabBar
?? lib/features/performance/presentation/widgets/  # 拆分的组件
```

---

### 八、待办事项

- [ ] 考虑将 `AuthCredentials` 持久化到 secure storage（当前仅内存）
- [ ] WebSocket 断线重连逻辑优化
- [ ] 更多性能监控指标（进程列表、服务状态）
- [ ] 国际化支持完善
