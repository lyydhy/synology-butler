# Android HTTP 与启动页说明

## 已处理内容

### 1. 允许 HTTP 明文连接
已在 Android 应用配置中开启：
- `android:usesCleartextTraffic="true"`
- `android:networkSecurityConfig="@xml/network_security_config"`

并新增：
- `android/app/src/main/res/xml/network_security_config.xml`

这使应用可以连接局域网中常见的 DSM HTTP 地址，例如：
- `http://192.168.1.2:5000`

> 注意：HTTP 仅适合内网或测试环境，正式使用仍建议优先 HTTPS。

### 2. 原生启动页风格调整
已修改：
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`

目标：
- 让 Android 原生冷启动界面更接近 Flutter 内部的 splash 风格
- 避免启动瞬间出现 Flutter 默认白屏模板感

## 为什么“第一瞬间不是 Flutter SplashPage”

这是 Flutter Android 的正常机制：
- 系统先显示 Android 原生启动主题（LaunchTheme）
- Flutter engine 初始化完成后，才进入 Flutter 的 `SplashPage`

因此如果原生启动页没有做品牌化，就会感觉“第一瞬间不是你写的页面”。

## 当前效果

现在已经做到：
- 启动第一屏不再是默认白底模板
- 视觉上更接近应用内蓝白风格

如果后续还要继续统一，可以再补：
- 原生 logo 资源精细化
- 深色模式单独启动页
- Android 12+ splash API 专门适配
