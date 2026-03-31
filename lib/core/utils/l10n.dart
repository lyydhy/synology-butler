import '../../l10n/app_localizations.dart';
import '../../app/router.dart';

/// 全局获取国际化字符串
///
/// 使用方式：l10n.someKey
///
/// 注意：需要在 MaterialApp 构建后才能使用（即 NavigatorKey 已挂载）
AppLocalizations? get l10nNullable {
  final context = appNavigatorKey.currentContext;
  return context != null ? AppLocalizations.of(context) : null;
}

AppLocalizations get l10n => l10nNullable!;
