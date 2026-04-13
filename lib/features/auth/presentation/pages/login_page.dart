import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/server_url_helper.dart';
import '../../../../core/utils/toast.dart';
import '../../../../domain/entities/nas_server.dart';
import '../../../../core/network/app_dio.dart';
import '../providers/auth_providers.dart';
import '../providers/current_connection_readers.dart';
import '../../../preferences/providers/preferences_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final hostController = TextEditingController();
  final portController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocusNode = FocusNode();

  bool https = true;
  bool ignoreBadCertificate = false;
  bool isLoading = false;
  bool isTesting = false;
  bool obscurePassword = true;
  bool showManualForm = false;
  bool quickLoginExpanded = false;
  String? selectedServerId;
  String? hostError;
  String? portError;
  String? usernameError;
  String? passwordError;
  String? errorText;
  String? infoText;
  List<String> _prevServerIds = [];
  bool _initialized = false;

  @override
  void dispose() {
    hostController.dispose();
    portController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void _resetForm() {
    hostController.clear();
    portController.clear();
    usernameController.clear();
    passwordController.clear();
    selectedServerId = null;
    https = true;
    ignoreBadCertificate = false;
    quickLoginExpanded = false;
    errorText = null;
    infoText = null;
    hostError = null;
    portError = null;
    usernameError = null;
    passwordError = null;
  }

  void _fillInitialValues(NasServer? server, String? savedUsername, List<NasServer> savedServers) {
    final currentIds = savedServers.map((s) => s.id).toList();
    if (currentIds != _prevServerIds) {
      _prevServerIds = currentIds;
      _resetForm();
    }

    if (server == null || _initialized) return;
    _initialized = true;
    selectedServerId = server.id;
    hostController.text = server.host;
    portController.text = server.port.toString();
    https = server.https;
    ignoreBadCertificate = server.ignoreBadCertificate;
    if (savedUsername != null && savedUsername.isNotEmpty) {
      usernameController.text = savedUsername;
    }
  }

  void applyServerPreset(NasServer server, {String? username}) {
    setState(() {
      selectedServerId = server.id;
      hostController.text = server.host;
      portController.text = server.port.toString();
      https = server.https;
      ignoreBadCertificate = server.ignoreBadCertificate;
      // 不再强制切换模式，由用户通过切换按钮控制
      quickLoginExpanded = true;
      if (username != null && username.isNotEmpty) {
        usernameController.text = username;
      }
      passwordController.clear();
      errorText = null;
      infoText = null;
      _clearFieldErrors();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) passwordFocusNode.requestFocus();
    });
  }

  Future<void> removeSavedServer(NasServer server) async {
    await ref.read(deleteServerProvider)(server);
    if (!mounted) return;
    if (selectedServerId == server.id) {
      _resetForm();
    }
    Toast.show(l10n.historyDeleted(server.name));
  }

  void _validateHost() {
    hostError = hostController.text.trim().isEmpty ? l10n.enterNasAddress : null;
  }

  void _validatePort() {
    final parsed = int.tryParse(portController.text.trim());
    portError = portController.text.trim().isEmpty
        ? l10n.enterPort
        : (parsed == null || parsed <= 0 || parsed > 65535) ? l10n.portRange : null;
  }

  void _validateUsername() {
    usernameError = usernameController.text.trim().isEmpty ? l10n.enterUsername : null;
  }

  void _validatePassword() {
    passwordError = passwordController.text.isEmpty ? l10n.enterPassword : null;
  }

  void _clearFieldErrors() {
    hostError = null;
    portError = null;
    usernameError = null;
    passwordError = null;
  }

  bool get _canManualSubmit =>
      hostError == null &&
      portError == null &&
      usernameError == null &&
      passwordError == null &&
      !isLoading;

  bool get _canQuickLogin =>
      selectedServerId != null &&
      usernameController.text.trim().isNotEmpty &&
      passwordController.text.isNotEmpty &&
      !isLoading;

  NasServer buildServer() {
    final normalizedHost = ServerUrlHelper.normalizeHost(hostController.text.trim());
    return NasServer(
      id: '$normalizedHost:${portController.text.trim()}:${https ? 'https' : 'http'}:${ignoreBadCertificate ? 'insecure' : 'strict'}',
      name: l10n.defaultDeviceName,
      host: normalizedHost,
      port: int.tryParse(portController.text.trim()) ?? 5001,
      https: https,
      basePath: null,
      ignoreBadCertificate: ignoreBadCertificate,
    );
  }

  Future<void> testConnection() async {
    setState(() {
      isTesting = true;
      errorText = null;
      infoText = null;
    });

    final server = buildServer();
    final baseUrl = ServerUrlHelper.buildBaseUrl(server);

    try {
      final client = DioClient(baseUrl: baseUrl, ignoreBadCertificate: server.ignoreBadCertificate).dio;
      await client.get(
        '/webapi/query.cgi',
        queryParameters: {
          'api': 'SYNO.API.Info',
          'version': '1',
          'method': 'query',
          'query': 'SYNO.API.Auth',
        },
      );
      setState(() => infoText = l10n.connectionSuccess);
    } on DioException catch (e) {
      setState(() => errorText = ErrorMapper.map(e).message);
    } catch (e) {
      setState(() => errorText = ErrorMapper.map(e).message);
    } finally {
      if (mounted) setState(() => isTesting = false);
    }
  }

  Future<void> login() async {
    if (showManualForm) {
      _validateHost();
      _validatePort();
      _validateUsername();
      _validatePassword();
      if (!_canManualSubmit) {
        setState(() {});
        return;
      }
    } else {
      _validateUsername();
      _validatePassword();
      if (!_canQuickLogin) return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
      errorText = null;
      infoText = null;
    });

    final server = buildServer();
    final username = usernameController.text.trim();
    setServer(server);

    try {
      final version = await ref.read(authRepositoryProvider).probeVersion(server: server);
      if (!version.isDsm7OrAbove) {
        setState(() => errorText = l10n.dsm6NotSupported(version.displayText));
        return;
      }

      final session = await ref.read(authRepositoryProvider).login(
            server: server,
            username: username,
            password: passwordController.text,
          );
      setSession(session);
      await ref.read(persistLoginProvider)(
        server,
        session,
        username,
        password: passwordController.text,
        rememberPassword: true,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => errorText = ErrorMapper.map(e).message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatLastUsed(int? timestampMs) {
    if (timestampMs == null || timestampMs <= 0) return '';
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestampMs));
    if (diff.inMinutes < 1) return l10n.justUsed;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 30) return l10n.daysAgo(diff.inDays);
    return l10n.usedEarlier;
  }

  String _buildServerInitials(NasServer server) {
    final value = server.name.trim();
    if (value.isEmpty) return 'N';
    return value.characters.first.toUpperCase();
  }

  NasServer? _findSelectedServer(List<NasServer> savedServers) {
    if (selectedServerId == null) return null;
    for (final server in savedServers) {
      if (server.id == selectedServerId) return server;
    }
    return null;
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }

  // ─── 顶部标题栏 ────────────────────────────────────────────────
  Widget _buildHeader(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.dns_rounded, color: primaryColor, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.appTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
        const Spacer(),
        // 手动/快速切换
        _buildModeToggle(),
      ]),
    );
  }

  Widget _buildModeToggle() {
    final savedServers = ref.watch(savedServersProvider);
    if (savedServers.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _toggleBtn(
          label: l10n.quickLogin,
          selected: !showManualForm,
          onTap: () => setState(() => showManualForm = false),
        ),
        _toggleBtn(
          label: l10n.manual,
          selected: showManualForm,
          onTap: () => setState(() => showManualForm = true),
        ),
      ]),
    );
  }

  Widget _toggleBtn({required String label, required bool selected, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ─── 状态提示条 ────────────────────────────────────────────────
  Widget _buildStatusBanner() {
    if (errorText == null && infoText == null) return const SizedBox.shrink();
    final isError = errorText != null;
    final color = isError ? Colors.red : Colors.green;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            errorText ?? infoText!,
            style: TextStyle(color: color.shade700, fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ]),
    );
  }

  // ─── 服务器历史列表 ────────────────────────────────────────────
  Widget _buildServerHistoryList(
    List<NasServer> savedServers,
    Map<String, String> savedUsernames,
    Map<String, int> lastUsedMap,
    Color primaryColor,
  ) {
    final sortedServers = [...savedServers]
      ..sort((a, b) => (lastUsedMap[b.id] ?? 0).compareTo(lastUsedMap[a.id] ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            l10n.historyDevices,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...sortedServers.map((server) {
          final isSelected = selectedServerId == server.id;
          final username = savedUsernames[server.id];
          final lastUsed = _formatLastUsed(lastUsedMap[server.id]);

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => applyServerPreset(server, username: username),
                onLongPress: () => _showDeleteServerDialog(server),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.10)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: primaryColor.withValues(alpha: 0.30), width: 1.5)
                        : null,
                  ),
                  child: Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.15)
                            : Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _buildServerInitials(server),
                        style: TextStyle(
                          color: isSelected ? primaryColor : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          server.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isSelected ? primaryColor : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (lastUsed.isNotEmpty || (username != null && username.isNotEmpty))
                          Text(
                            [username ?? '', lastUsed].where((e) => e.isNotEmpty).join(' · '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ]),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: primaryColor, size: 20)
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ]),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showDeleteServerDialog(NasServer server) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirm),
        content: Text(l10n.deleteConfirmHint(server.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              removeSavedServer(server);
            },
            child: Text(l10n.deleteConfirm),
          ),
        ],
      ),
    );
  }

  // ─── 快速登录展开面板 ──────────────────────────────────────────
  Widget _buildQuickLoginExpandPanel(Color primaryColor) {
    final savedServers = ref.watch(savedServersProvider);
    final selectedServer = _findSelectedServer(savedServers);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.lock_outline, color: primaryColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selectedServer != null
                  ? l10n.loginToNas(selectedServer.name)
                  : l10n.enterPasswordToLogin,
              style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => setState(() => quickLoginExpanded = false),
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          obscureText: obscurePassword,
          onChanged: (_) => setState(() => _validatePassword()),
          decoration: _inputDecoration(
            label: l10n.password,
            icon: Icons.lock_outline,
            errorText: passwordError,
            suffixIcon: IconButton(
              icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => obscurePassword = !obscurePassword),
            ),
          ),
          onSubmitted: (_) => isLoading ? null : login(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canQuickLogin ? login : null,
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.loginDsm, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  // ─── 手动登录表单 ──────────────────────────────────────────────
  Widget _buildManualForm(Color primaryColor) {
    return Column(children: [
      // 地址 + 端口一行
      Row(children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: hostController,
            onChanged: (_) => setState(() => _validateHost()),
            decoration: _inputDecoration(
              label: l10n.addressOrHost,
              icon: Icons.language_outlined,
              errorText: hostError,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: TextField(
            controller: portController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _validatePort()),
            decoration: _inputDecoration(
              label: l10n.port,
              icon: Icons.settings_ethernet_outlined,
              errorText: portError,
            ),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      // SSL 行：HTTPS 切换 + 忽略证书
      Row(children: [
        _buildHttpsToggle(primaryColor),
        const SizedBox(width: 10),
        if (https)
          Expanded(
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                dense: true,
                value: ignoreBadCertificate,
                onChanged: (v) => setState(() => ignoreBadCertificate = v),
                title: Text(l10n.ignoreSslCert, style: const TextStyle(fontSize: 13)),
                subtitle: Text(l10n.httpsOnly, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      TextField(
        controller: usernameController,
        onChanged: (_) => setState(() => _validateUsername()),
        decoration: _inputDecoration(
          label: l10n.username,
          icon: Icons.person_outline,
          errorText: usernameError,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: passwordController,
        obscureText: obscurePassword,
        onChanged: (_) => setState(() => _validatePassword()),
        decoration: _inputDecoration(
          label: l10n.password,
          icon: Icons.lock_outline,
          errorText: passwordError,
          suffixIcon: IconButton(
            icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => obscurePassword = !obscurePassword),
          ),
        ),
        onSubmitted: (_) => isLoading ? null : login(),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isTesting ? null : testConnection,
            icon: isTesting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.wifi_tethering_outlined, size: 18),
            label: Text(isTesting ? l10n.testingConnection : l10n.testConnection),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: _canManualSubmit ? login : null,
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.loginDsm, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ]);
  }

  Widget _buildHttpsToggle(Color primaryColor) {
    final label = https ? 'HTTPS' : 'HTTP';
    final color = https ? primaryColor : Colors.orange.shade700;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            https = !https;
            if (!https) ignoreBadCertificate = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              https ? Icons.lock_outline : Icons.lock_open_outlined,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeColorOption = ref.watch(themeColorProvider);
    final primaryColor = seedColorFor(themeColorOption);
    final connection = ref.watch(currentConnectionProvider);
    final currentServer = connection.server;
    final savedUsername = connection.username;
    final savedPassword = connection.password;
    final savedServers = ref.watch(savedServersProvider);
    final savedServerUsernames = ref.watch(savedServerUsernamesProvider);
    final savedServerLastUsed = ref.watch(savedServerLastUsedProvider);

    _fillInitialValues(currentServer, savedUsername, savedServers);

    // 自动填入已保存的密码
    if (passwordController.text.isEmpty && (savedPassword?.isNotEmpty ?? false)) {
      passwordController.text = savedPassword!;
    }

    // 没有选中服务器且有历史记录时，自动选中最近使用的
    if (selectedServerId == null && currentServer == null && savedServers.isNotEmpty) {
      final sortedServers = [...savedServers]
        ..sort((a, b) => (savedServerLastUsed[b.id] ?? 0).compareTo(savedServerLastUsed[a.id] ?? 0));
      final latest = sortedServers.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || selectedServerId != null) return;
        applyServerPreset(latest, username: savedServerUsernames[latest.id]);
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            // 顶部标题栏
            _buildHeader(primaryColor),
            const SizedBox(height: 20),

            // 状态提示
            _buildStatusBanner(),

            // 服务器历史列表（始终显示）
            _buildServerHistoryList(
              savedServers,
              savedServerUsernames,
              savedServerLastUsed,
              primaryColor,
            ),

            const SizedBox(height: 12),

            // 快速登录展开面板 或 手动表单
            if (!showManualForm)
              quickLoginExpanded || selectedServerId != null
                  ? _buildQuickLoginExpandPanel(primaryColor)
                  : _buildAddDeviceCard(primaryColor, cardColor)
            else
              _buildManualForm(primaryColor),

            const SizedBox(height: 16),

            // 底部切换入口（手动模式时显示返回快速登录）
            if (showManualForm && ref.watch(savedServersProvider).isNotEmpty)
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => showManualForm = false),
                  icon: const Icon(Icons.flash_on_rounded, size: 18),
                  label: Text(l10n.quickLogin),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddDeviceCard(Color primaryColor, Color cardColor) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => showManualForm = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.20),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_circle_outline, color: primaryColor),
              const SizedBox(width: 10),
              Text(
                l10n.addDevice,
                style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
