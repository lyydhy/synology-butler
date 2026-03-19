# 群晖管家 运行说明

项目目录：

```bash
/root/.openclaw/project/qunhuimanage
```

这个项目目前是 **Flutter 源码骨架**，已经有：
- 页面结构
- 路由
- Riverpod 状态管理
- Material 3 主题
- 多语言骨架
- DSM API 接口骨架

但因为之前的开发环境里 **没有 Flutter SDK**，所以你现在要做的是：
**在一个有 Flutter 的环境里完成依赖安装、国际化生成、编译检查和运行。**

---

## 一、环境要求

建议你准备一个能运行 Flutter 的环境，至少需要：

- Flutter SDK
- Dart（通常 Flutter 自带）
- Android Studio / Android SDK  
  或者
- Xcode（如果跑 iOS）
- Git
- 能联网下载依赖

建议先确认：

```bash
flutter --version
dart --version
flutter doctor
```

如果 `flutter doctor` 里还有红色错误，先修它。

---

## 二、进入项目目录

```bash
cd /root/.openclaw/project/qunhuimanage
```

先看一下项目文件是否在：

```bash
ls
```

你应该至少能看到：

- `pubspec.yaml`
- `lib/`
- `l10n.yaml`
- `PROJECT_STATUS.md`

---

## 三、安装依赖

先执行：

```bash
flutter pub get
```

这一步会安装项目依赖，包括：

- `flutter_riverpod`
- `dio`
- `go_router`
- `flutter_secure_storage`
- `shared_preferences`
- `file_picker`
- `intl`

如果这一步报错，把完整输出贴给我。

---

## 四、生成国际化代码

因为项目已经加了 `l10n.yaml` 和 `arb` 文件，所以要生成 `AppLocalizations`。

执行：

```bash
flutter gen-l10n
```

如果成功，会生成本地化代码供这些引用使用：

```dart
import '../l10n/app_localizations.dart';
```

如果这里报错，通常是：
- `arb` 文件格式不合法
- Flutter 版本问题
- `generate: true` 配置没生效

把报错贴给我，我帮你修。

---

## 五、先做静态检查

在真正运行前，先做一次分析：

```bash
flutter analyze
```

这一步非常重要，因为之前是在没有 Flutter SDK 的环境里直接写代码，**大概率会有一些语法、类型、import、生成文件相关的小问题**。

如果报错，先不要慌，把输出发我，我会按优先级帮你改。

---

## 六、格式化代码

建议跑一下格式化：

```bash
dart format .
```

或者：

```bash
flutter format .
```

通常用：

```bash
dart format .
```

更稳。

---

## 七、运行项目

### Android
如果你已经接好 Android 模拟器或真机：

```bash
flutter run
```

如果设备很多，先看设备列表：

```bash
flutter devices
```

然后指定设备：

```bash
flutter run -d <device_id>
```

---

### iOS
如果你在 macOS 上：

```bash
flutter run -d ios
```

或者先看：

```bash
flutter devices
```

---

### Web（如果只是想先看 UI）
如果你只想先快速看 UI 结构，也可以试：

```bash
flutter run -d chrome
```

不过这个项目本质上是移动端管理工具，  
而且像 `flutter_secure_storage`、`file_picker`、部分设备行为在 Web 上不一定完全等价，  
所以 **Web 只适合看 UI，不适合做最终联调**。

---

## 八、首次运行后优先检查哪些功能

我建议你不要一上来就全测，按这个顺序来：

### 1. App 是否能正常启动
检查：
- 首页是否能打开
- 路由是否正常
- 设置页是否能进
- 没有明显崩溃

### 2. 多语言是否正常
去设置页切换：
- 中文
- English

检查：
- 登录页
- 首页
- 设置页
- 文件页
- 下载页

文案是否切换正常。

### 3. 主题是否正常
去设置页切换：
- 跟随系统
- 浅色
- 深色
- 蓝 / 绿 / 橙 / 紫

检查主题是否真的变化。

### 4. 登录页功能
先不要急着真登录，先测：
- 输入框正常
- 测试连接按钮可点
- 报错显示是否正常

### 5. DSM 真实联调
准备一个真实 DSM 7 设备，测试顺序建议：

#### 第一步：测试连接
确认：
- 地址正确
- 端口正确
- HTTPS 是否匹配
- basePath 是否需要

#### 第二步：登录
确认：
- 用户名密码是否可用
- SID 是否成功建立

#### 第三步：文件模块
确认：
- 文件列表能不能拉出来
- 新建文件夹是否成功
- 重命名 / 删除是否成功

#### 第四步：下载模块
确认：
- 是否能拉取任务列表
- 新增下载任务是否成功
- 暂停 / 恢复 / 删除是否成功

---

## 九、最可能遇到的问题

### 1. `AppLocalizations` 相关报错
比如：

- `Target of URI doesn't exist: ...app_localizations.dart`
- `Undefined name AppLocalizations`

解决思路：
先跑：

```bash
flutter gen-l10n
```

如果还不行，把错误贴我。

---

### 2. Flutter analyze 报类型错误
因为之前没法本地编译，可能会出现：

- 某些 import 路径问题
- `const` 使用不合法
- 某些 Widget 参数类型不匹配
- provider / future provider 调用方式细节问题

这个很正常，直接把错误贴给我，我来逐条修。

---

### 3. DSM API 登录成功，但文件/下载失败
这通常不是 App 骨架问题，而是：

- DSM API 参数名不完全匹配
- 账号权限不足
- 某模块未启用
- 不同 DSM 版本字段差异
- 路径/basePath/反向代理不一致

这是后面联调的重点。

---

### 4. HTTPS / 证书问题
如果你是自签证书、内网、反代，很可能遇到：

- certificate error
- connection error
- timeout

这时候重点检查：

- DSM 地址是否对
- 端口是否对
- HTTPS 是否必须
- 证书是否受信任
- 反代是否正确转发 `/webapi/*`

---

## 十、推荐的实际执行顺序

如果你想最省事，按这个顺序直接跑：

```bash
cd /root/.openclaw/project/qunhuimanage
flutter pub get
flutter gen-l10n
dart format .
flutter analyze
flutter run
```

如果 `flutter analyze` 报错，就先别继续硬跑，直接把输出发我。

---

## 十一、你跑完后优先发我什么

最有价值的是这几类输出：

### A. 依赖问题
```bash
flutter pub get
```
的完整报错

### B. 国际化问题
```bash
flutter gen-l10n
```
的完整报错

### C. 编译/静态检查问题
```bash
flutter analyze
```
的完整报错

### D. 运行时报错
```bash
flutter run
```
里的红字报错

### E. DSM 联调问题
比如：
- 登录失败返回什么
- 文件列表接口失败返回什么
- 下载任务接口失败返回什么

---

## 十二、建议你先执行这 5 条

```bash
cd /root/.openclaw/project/qunhuimanage
flutter pub get
flutter gen-l10n
dart format .
flutter analyze
flutter run
```

你跑完后，把输出贴给我。  
下一步就可以开始按真正的错误日志帮你修，而不是盲写了。
