import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/local_app_logger.dart';
import '../../../../core/utils/server_url_helper.dart';
import '../../../../core/utils/toast.dart';
import '../../../../domain/entities/nas_server.dart';
import '../../../../core/network/app_dio.dart';
import '../providers/auth_providers.dart';
import '../providers/current_connection_readers.dart';

enum _LoginMode { quick, manual }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final serverNameController = TextEditingController();
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
  bool quickLoginEditUsername = false;
  _LoginMode loginMode = _LoginMode.manual;
  // 用于检测服务器列表是否变化，从而决定是否重新填充初始值
  List<String> _prevServerIds = [];

  @override
  void dispose() {
    serverNameController.dispose();
    hostController.dispose();
    portController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void _fillInitialValues(NasServer? server, String? savedUsername, List<NasServer> savedServers) {
    // 检测 savedServers 是否变化，变化则重置表单
    final currentIds = savedServers.map((s) => s.id).toList();
    if (currentIds != _prevServerIds) {
      _prevServerIds = currentIds;
      _resetForm();
    }

    if (server == null) {
      serverNameController.text = l10n.defaultDeviceName;
      hostController.text = '192.168.1.2';
      portController.text = '5001';
      usernameController.text = savedUsername ?? '';
      https = true;
      ignoreBadCertificate = false;
      return;
    }

    hostController.text = server.host;
    portController.text = server.port.toString();
    usernameController.text = savedUsername ?? '';
    https = server.https;
    ignoreBadCertificate = server.ignoreBadCertificate;
    selectedServerId = server.id;
  }

  void _resetForm() {
    serverNameController.clear();
    hostController.clear();
    portController.clear();
    usernameController.clear();
    passwordController.clear();
    selectedServerId = null;
    https = true;
    ignoreBadCertificate = false;
    quickLoginEditUsername = false;
    loginMode = _LoginMode.manual;
    errorText = null;
    infoText = null;
    hostError = null;
    portError = null;
    usernameError = null;
    passwordError = null;
  }

  void applyServerPreset(NasServer server, {String? username}) {
    setState(() {
      selectedServerId = server.id;
      serverNameController.text = server.name;
      hostController.text = server.host;
      portController.text = server.port.toString();
      https = server.https;
      ignoreBadCertificate = server.ignoreBadCertificate;
      loginMode = _LoginMode.quick;
      if (username != null && username.isNotEmpty) {
        usernameController.text = username;
      }
      quickLoginEditUsername = false;
      passwordController.clear();
      errorText = null;
      infoText = l10n.selectedEnterPassword(server.name);
      _clearFieldErrors();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) passwordFocusNode.requestFocus();
    });
  }

  Future<void> removeSavedServer(NasServer server) async {
    await ref.read(deleteServerProvider)(server);
    if (!mounted) return;

    final stillHasServers = ref.read(savedServersProvider).isNotEmpty;

    if (selectedServerId == server.id) {
      _resetForm();
      loginMode = stillHasServers ? _LoginMode.quick : _LoginMode.manual;
    }

    Toast.show(l10n.historyDeleted(server.name));
  }

  void _validateHost() {
    final host = hostController.text.trim();
    hostError = host.isEmpty ? l10n.enterNasAddress : null;
  }

  void _validatePort() {
    final portText = portController.text.trim();
    final parsed = int.tryParse(portText);
    portError = portText.isEmpty
        ? l10n.enterPort
        : (parsed == null || parsed <= 0 || parsed > 65535)
            ? l10n.portRange
            : null;
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

  bool get _canSubmit {
    return hostError == null &&
        portError == null &&
        usernameError == null &&
        passwordError == null &&
        !isLoading;
  }

  bool get _canQuickLogin {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    return selectedServerId != null && username.isNotEmpty && password.isNotEmpty && !isLoading;
  }

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

    await LocalAppLogger.log(
      level: 'info',
      module: 'auth',
      event: 'test_connection_start',
      extra: {
        'host': server.host,
        'port': server.port,
        'https': server.https,
        'ignoreBadCertificate': server.ignoreBadCertificate,
        'baseUrl': baseUrl,
      },
    );

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

      await LocalAppLogger.log(
        level: 'info',
        module: 'auth',
        event: 'test_connection_success',
        extra: {'baseUrl': baseUrl},
      );
      setState(() => infoText = l10n.connectionSuccess);
    } on DioException catch (e) {
      final details = [
        '测试连接失败',
        '类型: ${e.type.name}',
        '请求: ${e.requestOptions.uri}',
        if (e.response?.statusCode != null) '状态码: ${e.response?.statusCode}',
        if (e.error != null) '底层错误: ${e.error}',
        '异常: $e',
        if (e.response?.data != null) '响应: ${e.response?.data}',
      ].join('\n');
      await LocalAppLogger.log(
        level: 'error',
        module: 'auth',
        event: 'test_connection_failed',
        message: details,
      );
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.connectionTestFailed),
            content: SingleChildScrollView(child: SelectableText(details)),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: details));
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                child: Text(l10n.copy),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      }
      setState(() => errorText = ErrorMapper.map(e).message);
    } catch (e) {
      await LocalAppLogger.log(
        level: 'error',
        module: 'auth',
        event: 'test_connection_failed',
        message: e.toString(),
      );
      setState(() => errorText = ErrorMapper.map(e).message);
    } finally {
      if (mounted) setState(() => isTesting = false);
    }
  }

  Future<void> login() async {
    // 手动模式需要完整校验
    if (loginMode == _LoginMode.manual) {
      _validateHost();
      _validatePort();
      _validateUsername();
      _validatePassword();
      if (!_canSubmit) {
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

    await LocalAppLogger.log(
      level: 'info',
      module: 'auth',
      event: 'login_start',
      extra: {
        'host': server.host,
        'port': server.port,
        'https': server.https,
        'ignoreBadCertificate': server.ignoreBadCertificate,
        'username': username,
      },
    );

    try {
      final version = await ref.read(authRepositoryProvider).probeVersion(server: server);
      await LocalAppLogger.log(
        level: 'info',
        module: 'auth',
        event: 'probe_version_result',
        extra: {
          'displayText': version.displayText,
          'isDsm7OrAbove': version.isDsm7OrAbove,
        },
      );
      if (!version.isDsm7OrAbove) {
        setState(() => errorText = l10n.dsm6NotSupported(version.displayText));
        return;
      }

      final session = await ref.read(authRepositoryProvider).login(
            server: server,
            username: username,
            password: passwordController.text,
          );
      await LocalAppLogger.log(
        level: 'info',
        module: 'auth',
        event: 'login_success',
        extra: {
          'sidPresent': session.sid.isNotEmpty,
          'synoTokenPresent': session.synoToken != null && session.synoToken!.isNotEmpty,
        },
      );
      setSession(session);
      // 始终保存密码（用户去掉了"记住密码"勾选框，但行为不变）
      await ref.read(persistLoginProvider)(
        server,
        session,
        username,
        password: passwordController.text,
        rememberPassword: true,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      await LocalAppLogger.log(
        level: 'error',
        module: 'auth',
        event: 'login_failed',
        message: e.toString(),
      );
      setState(() => errorText = ErrorMapper.map(e).message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatLastUsed(int? timestampMs) {
    if (timestampMs == null || timestampMs <= 0) return l10n.noLoginTimeRecorded;
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
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.4),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: Colors.redAccent, width: 1.1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (errorText == null && infoText == null) return const SizedBox.shrink();
    final isError = errorText != null;
    final color = isError ? Colors.red : Colors.green;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;
    final text = errorText ?? infoText!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color.shade700, height: 1.35, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHttpsField() {
    final text = https ? 'HTTPS' : 'HTTP';
    final color = https ? const Color(0xFF2563EB) : Colors.orange.shade700;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            https = !https;
            if (!https) ignoreBadCertificate = false;
          });
          if (!https) Toast.show(l10n.switchedToHttp);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                https ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                color: const Color(0xFF2563EB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerSelector() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _showServerHistorySheet(
          ref.watch(savedServersProvider),
          ref.watch(savedServerUsernamesProvider),
          ref.watch(savedServerLastUsedProvider),
        ),
        icon: const Icon(Icons.history_rounded, size: 18),
        label: Text(l10n.selectFromHistory, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  void _showServerHistorySheet(
    List<NasServer> savedServers,
    Map<String, String> savedUsernames,
    Map<String, int> lastUsedMap,
  ) {
    final sortedServers = [...savedServers]
      ..sort((a, b) => (lastUsedMap[b.id] ?? 0).compareTo(lastUsedMap[a.id] ?? 0));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Text(l10n.historyDevices, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sortedServers.length,
                  itemBuilder: (_, index) {
                    final server = sortedServers[index];
                    final username = savedUsernames[server.id];
                    final lastUsed = _formatLastUsed(lastUsedMap[server.id]);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Text(
                          _buildServerInitials(server),
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      title: Text(server.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        [if (username != null && username.isNotEmpty) username, lastUsed].join(' · '),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        applyServerPreset(server, username: username);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedServerSummary(NasServer? server) {
    if (server == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.selectDeviceFirst, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF4FF), Color(0xFFF8FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.16)),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            _buildServerInitials(server),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(server.name, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              ServerUrlHelper.buildBaseUrl(server),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildQuickLoginCard(List<NasServer> savedServers) {
    final selectedServer = _findSelectedServer(savedServers);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 28, offset: const Offset(0, 12)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flash_on_rounded, color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.quickLogin, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 2),
              Text(
                selectedServerId == null ? l10n.selectDeviceThenPassword : l10n.deviceReadyEnterPassword,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
              ),
            ])),
          ]),
          const SizedBox(height: 14),
          _buildSelectedServerSummary(selectedServer),
          const SizedBox(height: 10),
          if (!quickLoginEditUsername)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Row(children: [
                const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.username, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text(
                    usernameController.text.trim().isEmpty ? l10n.noUsernameTapChange : usernameController.text.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ])),
                TextButton(
                  onPressed: () => setState(() => quickLoginEditUsername = true),
                  child: Text(usernameController.text.trim().isEmpty ? l10n.fill : l10n.changeAccount),
                ),
              ]),
            )
          else
            TextField(
              controller: usernameController,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration(
                label: l10n.username,
                icon: Icons.person_outline,
                suffixIcon: TextButton(
                  onPressed: () => setState(() => quickLoginEditUsername = false),
                  child: Text(l10n.done),
                ),
              ),
            ),
          const SizedBox(height: 10),
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
                onPressed: () => setState(() => obscurePassword = !obscurePassword),
                icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
            onSubmitted: (_) => isLoading ? null : login(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _canQuickLogin ? login : null,
              icon: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login_rounded),
              label: Text(isLoading ? l10n.loggingIn : l10n.loginDsm),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  loginMode = _LoginMode.manual;
                  quickLoginEditUsername = false;
                  errorText = null;
                  infoText = l10n.switchedToNewAccount;
                });
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(l10n.newAccountDevice),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildInputCard({required bool showBackToQuick}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 28, offset: const Offset(0, 12)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.connectionInfo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 2),
              Text(l10n.enterNasCredentials, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ])),
            if (showBackToQuick)
              TextButton(
                onPressed: () => setState(() => loginMode = _LoginMode.quick),
                child: Text(l10n.quickLogin),
              ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            _buildHttpsField(),
            const SizedBox(width: 12),
            Expanded(
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
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: portController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _validatePort()),
            decoration: _inputDecoration(
              label: l10n.port,
              icon: Icons.settings_ethernet_outlined,
              errorText: portError,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: ignoreBadCertificate,
              onChanged: https ? (value) => setState(() => ignoreBadCertificate = value) : null,
              title: Text(l10n.ignoreSslCert),
              subtitle: Text(
                https ? l10n.ignoreSslCertHint : l10n.httpsOnly,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
              ),
            ),
          ),
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
            focusNode: passwordFocusNode,
            obscureText: obscurePassword,
            onChanged: (_) => setState(() => _validatePassword()),
            decoration: _inputDecoration(
              label: l10n.password,
              icon: Icons.lock_outline,
              errorText: passwordError,
              suffixIcon: IconButton(
                onPressed: () => setState(() => obscurePassword = !obscurePassword),
                icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
            onSubmitted: (_) => isLoading ? null : login(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _canSubmit ? login : null,
              icon: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login_rounded),
              label: Text(isLoading ? l10n.loggingIn : l10n.loginDsm),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isTesting ? null : testConnection,
              icon: isTesting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_tethering_outlined),
              label: Text(isTesting ? l10n.testingConnection : l10n.testConnection),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(currentConnectionProvider);
    final currentServer = connection.server;
    final savedUsername = connection.username;
    final savedPassword = connection.password;
    final savedServers = ref.watch(savedServersProvider);
    final savedServerUsernames = ref.watch(savedServerUsernamesProvider);
    final savedServerLastUsed = ref.watch(savedServerLastUsedProvider);
    final sessionExpiredAsync = ref.watch(localStorageProvider).readString(AppConstants.sessionExpiredFlagKey);

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

    // 会话过期提示
    sessionExpiredAsync.then((flag) async {
      if (!mounted || flag != '1') return;
      setState(() {
        infoText = null;
        errorText = l10n.sessionExpired;
      });
      await ref.read(localStorageProvider).remove(AppConstants.sessionExpiredFlagKey);
    });

    final showQuickLogin = savedServers.isNotEmpty && loginMode == _LoginMode.quick;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F7FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.16),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.dns_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.appTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(l10n.dsm7Plus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    showQuickLogin ? l10n.quickLoginReady : l10n.connectToDsm,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.90), height: 1.35, fontSize: 13),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              _buildStatusBanner(),
              if (showQuickLogin) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.quickRelogin, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(l10n.quickReloginHint, style: TextStyle(color: Colors.grey.shade600)),
                  ]),
                ),
                _buildQuickLoginCard(savedServers),
                _buildServerSelector(),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.loginToNas, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(l10n.loginToNasHint, style: TextStyle(color: Colors.grey.shade600)),
                  ]),
                ),
                _buildInputCard(showBackToQuick: savedServers.isNotEmpty),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
