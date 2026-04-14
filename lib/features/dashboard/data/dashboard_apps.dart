import 'package:flutter/material.dart';

/// 首页应用入口条目
class DashboardAppEntry {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const DashboardAppEntry({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}

/// 首页显示的应用列表（硬编码顺序）
/// 运行时是否显示由 dashboard_page.dart 里的条件决定
const List<DashboardAppEntry> dashboardHomeApps = [
  DashboardAppEntry(
    icon: Icons.inventory_2_outlined,
    label: '容器管理',
    color: Colors.blueGrey,
    route: '/container-management',
  ),
  DashboardAppEntry(
    icon: Icons.apps_rounded,
    label: '套件中心',
    color: Colors.amber.shade700,
    route: '/packages',
  ),
  DashboardAppEntry(
    icon: Icons.sync_alt_rounded,
    label: '传输中心',
    color: Colors.deepOrange,
    route: '/transfers',
  ),
  DashboardAppEntry(
    icon: Icons.tune_rounded,
    label: '控制面板',
    color: Colors.deepPurple,
    route: '/control-panel',
  ),
  DashboardAppEntry(
    icon: Icons.info_outline_rounded,
    label: '信息中心',
    color: Colors.indigo,
    route: '/information-center',
  ),
  DashboardAppEntry(
    icon: Icons.monitor_heart_outlined,
    label: '性能监控',
    color: Colors.teal,
    route: '/performance',
  ),
];
