# PROJECT_STATUS

## 本轮阶段目标
对项目进行第一阶段精简与收口，重点是：

1. 减少 Riverpod / provider 在页面局部状态中的滥用
2. 尽量把页面局部状态回归 Flutter 原生 State
3. 将 presentation 层中的状态类/模型类逐步归位
4. 每一步都保持 `flutter analyze` 全绿

---

## 本轮已完成内容

### 1. performance 模块
- 去掉 `performance_page.dart` 内部的 Riverpod 局部历史状态
- 页面历史缓存改回 Flutter 原生 `State`
- 新增并后续归位：
  - `lib/features/performance/presentation/state/performance_history.dart`
- `performance_page.dart` 补充了适度中文注释

### 2. packages 模块
- 页面筛选 tab 改回页面本地状态
- 删除：
  - `packageTabProvider`
  - `visiblePackagesProvider`
- 安装流程状态从多个分散 provider 收敛为：
  - `packageInstallStateProvider`
- 抽出状态类：
  - `lib/features/packages/presentation/state/package_install_state.dart`
- 列表页与详情页补充了适度中文注释

### 3. downloads 模块
- 删除页面局部筛选 provider：
  - `downloadFilterProvider`
- `DownloadsPage` 改为本地 State 管理筛选
- `downloadListProvider` 只负责原始任务列表，不再耦合 UI 筛选逻辑
- 页面补充了适度中文注释

### 4. files 模块
#### 第一刀
- 删除：
  - `selectedFilePathsProvider`
  - `fileSelectionModeProvider`
- 文件多选状态改回 `FilesPage` 本地 State
- `file_page_actions.dart` 不再直接持有页面选择状态

#### 第二刀
- 删除：
  - `currentPathProvider`
  - `fileSortProvider`
- 路径与排序改回 `FilesPage` 本地 State
- `fileListProvider` 改为：
  - `FutureProvider.family<List<FileItem>, FileListQuery>`
- `diagnostics` 页面已适配新的 `fileListProvider` 调用方式

### 5. presentation 层收尾整理
- `performance_history.dart` 从 `presentation/pages` 移到 `presentation/state`
- `PackageInstallState` 从 provider 文件中抽离到独立状态文件

### 6. 静态检查收尾
- 额外修复了项目原有 analyze 遗留项：
  - 删除无用 import
  - 删除无用变量
  - 删除未用私有函数
  - 补少量 if 花括号
- 当前状态：
  - `flutter analyze` -> `No issues found!`

---

## 当前明确结论

### 已适合继续保持的原则
- 页面局部状态：优先 Flutter 原生 `State`
- provider：主要保留给
  - repository / service 注入
  - 跨页面共享业务状态
  - 按参数取数的数据源 provider

### 当前不建议继续硬改的部分
- `transfers`
  - 当前 provider 承担跨页面共享任务队列、持久化、恢复、重试等职责，属于合理使用
- `auth`
  - 涉及会话恢复、存储、桥接、连接同步，影响面大
- `data model / domain entity` 直接合并
  - 目前没有足够证据证明应该统一收并，贸然处理风险大

---

## 后续建议顺序

### 优先级高
1. 继续保持新增页面不要把局部状态挂到 provider
2. 新增状态类时优先放到 `presentation/state/`，不要塞回页面或 provider 文件

### 优先级中
3. 后续如果要继续优化，建议先做 `auth / preferences` 的“小范围审计”，不要直接改
4. 如需处理模型合并，先做审计清单，再决定是否动手

### 暂不建议
5. 不建议为了“更少 provider”而改动 `transfers` 这类跨页面业务状态模块

---

## 当前验证状态
已使用绝对路径执行：

```bash
/home/node/.openclaw/projectEnv/flutter-sdk/bin/flutter analyze
```

结果：

```text
No issues found!
```
