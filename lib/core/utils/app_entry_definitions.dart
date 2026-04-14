import 'package:flutter/material.dart';

/// 应用入口条目，支持首页展示和完整列表页
class AppEntry {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final bool Function() isAvailable; // 运行时条件判断

  const AppEntry({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    required this.isAvailable,
  });

  /// 首页显示的条目（按顺序）
  static List<AppEntry> get homeEntries => [
        AppEntry(
          icon: Icons.inventory_2_outlined,
          label: '容器管理',
          color: Colors.blueGrey,
          route: '/container-management',
          isAvailable: () => true, // 实际由 dockerInstalledAsync 控制
        ),
        AppEntry(
          icon: Icons.apps_rounded,
          label: '套件中心',
          color: Colors.amber.shade700,
          route: '/packages',
          isAvailable: () => true,
        ),
        AppEntry(
          icon: Icons.sync_alt_rounded,
          label: '传输中心',
          color: Colors.deepOrange,
          route: '/transfers',
          isAvailable: () => true,
        ),
        AppEntry(
          icon: Icons.tune_rounded,
          label: '控制面板',
          color: Colors.deepPurple,
          route: '/control-panel',
          isAvailable: () => true,
        ),
        AppEntry(
          icon: Icons.info_outline_rounded,
          label: '信息中心',
          color: Colors.indigo,
          route: '/information-center',
          isAvailable: () => true,
        ),
        AppEntry(
          icon: Icons.monitor_heart_outlined,
          label: '性能监控',
          color: Colors.teal,
          route: '/performance',
          isAvailable: () => true,
        ),
      ];

  /// 所有可用条目（用于"更多"完整列表）
  static List<AppEntry> get allEntries => homeEntries;
}
