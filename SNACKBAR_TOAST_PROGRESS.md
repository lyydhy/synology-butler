# SnackBar → Toast 替换进度

## 状态：大部分完成

## 已完成文件
1. `lib/features/files/presentation/pages/files_page.dart` ✅
2. `lib/features/power/presentation/pages/power_page.dart` ✅
3. `lib/features/terminal/presentation/pages/terminal_page.dart` ✅
4. `lib/features/file_services/presentation/pages/file_services_page.dart` ✅
5. `lib/features/user_groups/presentation/pages/user_groups_page.dart` ✅
6. `lib/features/debug/presentation/pages/app_logs_page.dart` ✅
7. `lib/features/files/presentation/providers/file_page_actions.dart` ✅
8. `lib/features/server-management/presentation/pages/server_management_page.dart` ✅
9. `lib/features/settings/presentation/pages/settings_page.dart` ✅
10. `lib/features/transfers/presentation/pages/transfers_page.dart` ✅
11. `lib/features/files/presentation/pages/text_editor_page.dart` ✅
12. `lib/features/downloads/presentation/pages/downloads_page.dart` ✅
13. `lib/features/files/presentation/widgets/file_detail_sheet.dart` ✅
14. `lib/features/packages/presentation/pages/packages_page.dart` ✅
15. `lib/features/container_management/presentation/pages/container_detail_page.dart` ✅
16. `lib/features/container_management/presentation/pages/compose_project_detail_page.dart` ✅ (2026-04-03)
17. `lib/features/container_management/presentation/pages/compose_project_create_page.dart` ✅ (2026-04-03)
18. `lib/features/container_management/presentation/pages/container_management_page.dart` ✅ (2026-04-03)
19. `lib/features/index_service/presentation/pages/index_service_page.dart` ✅ (2026-04-03)
20. `lib/features/task_scheduler/presentation/pages/task_scheduler_page.dart` ✅ (2026-04-03)
21. `lib/features/external_devices/presentation/pages/external_devices_page.dart` ✅ (2026-04-03)
22. `lib/features/packages/presentation/pages/package_detail_page.dart` ✅ (2026-04-03)
23. `lib/features/files/presentation/pages/image_preview_page.dart` ✅ (2026-04-03)
24. `lib/features/external_share/pages/external_file_upload_page.dart` ✅ (2026-04-03)
25. `lib/features/auth/presentation/pages/login_page.dart` ✅ (2026-04-03)

## 保留 SnackBar 的场景
- `lib/app/app.dart` - 全局下载完成通知，需要带 action 按钮（"打开"）

## 替换规则
- 纯文字提示 → `Toast.show(message)`
- 成功提示 → `Toast.success(message)`
- 错误提示 → `Toast.error(message)`
- 警告提示 → `Toast.warning(message)`

## Toast 工具位置
`lib/core/utils/toast.dart`

## 需要添加的 import
```dart
import '../../../../core/utils/toast.dart';
// 或根据文件位置调整路径
```

## 备注
- 如需带交互按钮的通知，保留 SnackBar
- 新增文件应使用 Toast 而非 SnackBar
