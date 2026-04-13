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

// ─── 内部路由状态：showHistory 控制显示哪个页面 ────────────────────
enum _LoginView { manual, history }

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
  String? selectedServerId;
  String? hostError;
  String? portError;
  String? usernameError;
  String? passwordError;
  String? errorText;
  String? infoText;
  bool quickLoginExpanded = false;
  List<String> _prevServerIds = [];
  bool _initialized = false;
  // 当前视图：manual 或 history
  _LoginView _view = _LoginView.manual;

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

  void _applyServerAndEnterQuickLogin(NasServer server, {String? username}) {
    setState(() {
      selectedServerId = server.id;
      hostController.text = server.host;
      portController.text = server.port.toString();
      https = server.https;
      ignoreBadCertificate = server.ignoreBadCertificate;
      quickLoginExpanded = true;
      if (username != null && username.isNotEmpty) {
        usernameController.text = username;
      }
      passwordController.clear();
      errorText = null;
      infoText = null;
      _clearFieldErrors();
      _view = _LoginView.manual;
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
      hostError == null && portError == null && usernameError == null && passwordError == null && !isLoading;

  bool get _canQuickLogin =>
      selectedServerId != null && usernameController.text.trim().isNotEmpty && passwordController.text.isNotEmpty && !isLoading;

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
    _validateHost();
    _validatePort();
    _validateUsername();
    _validatePassword();
    if (!_canManualSubmit) {
      setState(() {});
      return;
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
      // HTTPS 行
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
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
            Icon(https ? Icons.lock_outline : Icons.lock_open_outlined, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  // ─── 历史登录设备列表 ──────────────────────────────────────────
  Widget _buildHistoryList(
    List<NasServer> savedServers,
    Map<String, String> savedUsernames,
    Map<String, int> lastUsedMap,
    Color primaryColor,
  ) {
    if (savedServers.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.history_rounded, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(l10n.noHistory, style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant, fontSize: 15)),
        ]),
      );
    }

    final sortedServers = [...savedServers]
      ..sort((a, b) => (lastUsedMap[b.id] ?? 0).compareTo(lastUsedMap[a.id] ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedServers.length,
      itemBuilder: (_, index) {
        final server = sortedServers[index];
        final username = savedUsernames[server.id];
        final lastUsed = _formatLastUsed(lastUsedMap[server.id]);
        final isSelected = selectedServerId == server.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _applyServerAndEnterQuickLogin(server, username: username),
              onLongPress: () => _showDeleteServerDialog(server),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.10)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: isSelected ? Border.all(color: primaryColor.withValues(alpha: 0.35), width: 1.5) : null,
                ),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _buildServerInitials(server),
                      style: TextStyle(
                        color: isSelected ? primaryColor : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        server.name,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isSelected ? primaryColor : null),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [if (username != null && username.isNotEmpty) username, lastUsed].where((e) => e.isNotEmpty).join(' · '),
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ]),
              ),
            ),
          ),
        );
      },
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

  // ─── 快速登录面板 ──────────────────────────────────────────────
  Widget _buildQuickLoginPanel(Color primaryColor, NasServer? selectedServer) {
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
              selectedServer != null ? l10n.loginToNas(selectedServer.name) : l10n.enterPasswordToLogin,
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
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.loginDsm, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
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

    // 没有已选服务器时，自动选中最近使用的并展开快速登录
    if (selectedServerId == null && currentServer == null && savedServers.isNotEmpty && !quickLoginExpanded) {
      final sortedServers = [...savedServers]
        ..sort((a, b) => (savedServerLastUsed[b.id] ?? 0).compareTo(savedServerLastUsed[a.id] ?? 0));
      final latest = sortedServers.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || selectedServerId != null) return;
        _applyServerAndEnterQuickLogin(latest, username: savedServerUsernames[latest.id]);
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedServer = _findSelectedServer(savedServers);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _view == _LoginView.history
            ? IconButton(
                onPressed: () => setState(() => _view = _LoginView.manual),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Text(
          _view == _LoginView.manual ? l10n.loginDsm : l10n.historyDevices,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: primaryColor),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
          child: _view == _LoginView.history
              ? _buildHistoryList(savedServers, savedServerUsernames, savedServerLastUsed, primaryColor)
              : Column(
                  children: [
                    _buildStatusBanner(),
                    if (quickLoginExpanded && selectedServer != null)
                      _buildQuickLoginPanel(primaryColor, selectedServer)
                    else
                      Expanded(child: _buildManualForm(primaryColor)),
                    const SizedBox(height: 12),
                    // 底部：历史登录设备入口
                    if (!_initialized && savedServers.isNotEmpty) const SizedBox.shrink()
                    else if (savedServers.isNotEmpty && _view == _LoginView.manual)
                      _buildHistoryButton(primaryColor)
                    else if (savedServers.isEmpty)
                      _buildHistoryButton(primaryColor),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHistoryButton(Color primaryColor) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _view = _LoginView.history),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: primaryColor.withValues(alpha: 0.30)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history_rounded, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(l10n.historyDevices, style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor)),
            ]),
          ),
        ),
      ),
    );
  }
}
