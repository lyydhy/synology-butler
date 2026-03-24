import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/local_app_logger.dart';
import '../../../../core/utils/server_url_helper.dart';
import '../../../../domain/entities/nas_server.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';

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
  bool rememberPassword = false;
  bool isLoading = false;
  bool isTesting = false;
  bool obscurePassword = true;
  bool initialized = false;
  bool handledExpiredMessage = false;
  String? selectedServerId;
  String? hostValidationText;
  String? portValidationText;
  String? usernameValidationText;
  String? passwordValidationText;
  String? errorText;
  String? infoText;
  bool quickLoginEditUsername = false;
  _LoginMode loginMode = _LoginMode.manual;

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

  void fillInitialValues(NasServer? server, String? savedUsername, bool hasSavedServers) {
    if (initialized) return;
    initialized = true;
    loginMode = hasSavedServers ? _LoginMode.quick : _LoginMode.manual;

    if (server == null) {
      serverNameController.text = '我的 NAS';
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
    _validateFields();
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
      infoText = '已选择 ${server.name}，输入密码即可重新登录';
      _validateFields();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        passwordFocusNode.requestFocus();
      }
    });
  }

  Future<void> removeSavedServer(NasServer server) async {
    await ref.read(deleteServerProvider)(server);
    if (!mounted) return;

    final stillHasSavedServers = ref.read(savedServersProvider).isNotEmpty;

    if (selectedServerId == server.id) {
      setState(() {
        selectedServerId = null;
        if (serverNameController.text == server.name) serverNameController.clear();
        if (hostController.text == server.host) hostController.clear();
        if (portController.text == server.port.toString()) portController.clear();
        usernameController.clear();
        passwordController.clear();
        quickLoginEditUsername = false;
        loginMode = stillHasSavedServers ? _LoginMode.quick : _LoginMode.manual;
        _validateFields();
      });
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text('已删除 ${server.name} 的历史记录')));
  }

  void _validateFields() {
    final host = hostController.text.trim();
    final portText = portController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final parsedPort = int.tryParse(portText);

    hostValidationText = host.isEmpty ? '请输入 NAS 地址或域名' : null;
    portValidationText = portText.isEmpty
        ? '请输入端口'
        : (parsedPort == null || parsedPort <= 0 || parsedPort > 65535)
            ? '端口范围应为 1 - 65535'
            : null;
    usernameValidationText = username.isEmpty ? '请输入用户名' : null;
    passwordValidationText = password.isEmpty ? '请输入密码' : null;
  }

  bool get _canSubmit {
    _validateFields();
    return hostValidationText == null &&
        portValidationText == null &&
        usernameValidationText == null &&
        passwordValidationText == null &&
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
      name: '我的 NAS',
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
      setState(() {
        infoText = '连接成功：已探测到 DSM Web API';
      });
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
            title: const Text('测试连接失败'),
            content: SingleChildScrollView(child: SelectableText(details)),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: details));
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                child: const Text('复制'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
      setState(() {
        errorText = ErrorMapper.map(e).message;
      });
    } catch (e) {
      await LocalAppLogger.log(
        level: 'error',
        module: 'auth',
        event: 'test_connection_failed',
        message: e.toString(),
      );
      setState(() {
        errorText = ErrorMapper.map(e).message;
      });
    } finally {
      if (mounted) setState(() => isTesting = false);
    }
  }

  Future<void> login() async {
    _validateFields();
    final canSubmit = loginMode == _LoginMode.quick ? _canQuickLogin : _canSubmit;
    if (!canSubmit) {
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
    ref.read(currentServerProvider.notifier).state = server;

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
        setState(() {
          errorText = '检测到当前设备为 ${version.displayText}。本应用当前仅支持 DSM 7，暂不支持 DSM 6 登录。';
        });
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
      ref.read(currentSessionProvider.notifier).state = session;
      await ref.read(persistLoginProvider)(server, session, username, password: passwordController.text, rememberPassword: rememberPassword);
      if (mounted) context.go('/home');
    } catch (e) {
      await LocalAppLogger.log(
        level: 'error',
        module: 'auth',
        event: 'login_failed',
        message: e.toString(),
      );
      setState(() {
        errorText = ErrorMapper.map(e).message;
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _formatLastUsed(int? timestampMs) {
    if (timestampMs == null || timestampMs <= 0) return '未记录登录时间';
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestampMs));
    if (diff.inMinutes < 1) return '刚刚使用';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前使用';
    if (diff.inDays < 1) return '${diff.inHours} 小时前使用';
    if (diff.inDays < 30) return '${diff.inDays} 天前使用';
    return '较早前使用';
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

  InputDecoration _inputDecoration({required String label, required IconData icon, Widget? suffixIcon, String? errorText}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.4)),
      errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide(color: Colors.redAccent, width: 1.1)),
      focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide(color: Colors.redAccent, width: 1.4)),
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
          Expanded(child: Text(text, style: TextStyle(color: color.shade700, height: 1.35, fontWeight: FontWeight.w500))),
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
          if (!https) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(const SnackBar(content: Text('已切换为 HTTP，请仅在可信局域网中使用')));
          }
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
              Icon(https ? Icons.lock_outline_rounded : Icons.lock_open_rounded, color: const Color(0xFF2563EB), size: 18),
              const SizedBox(width: 8),
              Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerSelector(List<NasServer> savedServers, Map<String, String> savedUsernames, Map<String, int> lastUsedMap) {
    if (savedServers.isEmpty) return const SizedBox.shrink();
    final sortedServers = [...savedServers]..sort((a, b) => (lastUsedMap[b.id] ?? 0).compareTo(lastUsedMap[a.id] ?? 0));
    return DropdownButtonFormField<String>(
      initialValue: selectedServerId != null && sortedServers.any((server) => server.id == selectedServerId) ? selectedServerId : null,
      decoration: _inputDecoration(label: '历史设备', icon: Icons.history_rounded),
      items: sortedServers.map((server) {
        final username = savedUsernames[server.id];
        final lastUsed = _formatLastUsed(lastUsedMap[server.id]);
        final subtitle = [if (username != null && username.isNotEmpty) username, lastUsed].join(' · ');
        return DropdownMenuItem<String>(
          value: server.id,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(server.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(subtitle, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        final matched = sortedServers.where((server) => server.id == value);
        if (matched.isEmpty) return;
        applyServerPreset(matched.first, username: savedUsernames[matched.first.id]);
      },
    );
  }

  Widget _buildSelectedServerSummary(NasServer? server) {
    if (server == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF2563EB))),
          const SizedBox(width: 12),
          const Expanded(child: Text('请选择一个历史设备后再快速登录', style: TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEEF4FF), Color(0xFFF8FBFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.16)),
      ),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(14)), alignment: Alignment.center, child: Text(_buildServerInitials(server), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(server.name, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(ServerUrlHelper.buildBaseUrl(server), style: TextStyle(color: Colors.grey.shade700, fontSize: 12), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _buildQuickLoginCard(AppLocalizations l10n, List<NasServer> savedServers) {
    final selectedServer = _findSelectedServer(savedServers);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 28, offset: const Offset(0, 12))]),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFEEF4FF), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.flash_on_rounded, color: Color(0xFF2563EB), size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('快速登录', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 2),
              Text(selectedServerId == null ? '选择设备后输入密码即可登录' : '设备已就绪，输入密码即可登录', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            ])),
          ]),
          const SizedBox(height: 14),
          _buildSelectedServerSummary(selectedServer),
          const SizedBox(height: 12),
          _buildServerSelector(ref.watch(savedServersProvider), ref.watch(savedServerUsernamesProvider), ref.watch(savedServerLastUsedProvider)),
          const SizedBox(height: 10),
          if (!quickLoginEditUsername)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
              child: Row(children: [
                const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('用户名', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text(usernameController.text.trim().isEmpty ? '未记录用户名，请点击更换账号' : usernameController.text.trim(), style: const TextStyle(fontWeight: FontWeight.w700)),
                ])),
                TextButton(onPressed: () => setState(() => quickLoginEditUsername = true), child: Text(usernameController.text.trim().isEmpty ? '填写' : '更换账号')),
              ]),
            )
          else
            TextField(
              controller: usernameController,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration(label: l10n.username, icon: Icons.person_outline, suffixIcon: TextButton(onPressed: () => setState(() => quickLoginEditUsername = false), child: const Text('完成'))),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            obscureText: obscurePassword,
            onChanged: (_) => setState(() => _validateFields()),
            decoration: _inputDecoration(
              label: l10n.password,
              icon: Icons.lock_outline,
              errorText: passwordValidationText,
              suffixIcon: IconButton(onPressed: () => setState(() => obscurePassword = !obscurePassword), icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined)),
            ),
            onSubmitted: (_) => isLoading ? null : login(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _canQuickLogin ? login : null,
              icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.login_rounded),
              label: Text(isLoading ? l10n.loggingIn : '登录 DSM'),
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
                  infoText = '已切换到新账号 / 新设备登录';
                });
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('新账号 / 新设备登录'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildInputCard(AppLocalizations l10n, {required bool showBackToQuick}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 28, offset: const Offset(0, 12))]),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEEF4FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF2563EB))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('连接信息', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 2),
              Text('填写 NAS 地址与 DSM 账号信息', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ])),
            if (showBackToQuick) TextButton(onPressed: () => setState(() => loginMode = _LoginMode.quick), child: const Text('快速登录')),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            _buildHttpsField(),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: hostController, onChanged: (_) => setState(() => _validateFields()), decoration: _inputDecoration(label: l10n.addressOrHost, icon: Icons.language_outlined, errorText: hostValidationText))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: portController, keyboardType: TextInputType.number, onChanged: (_) => setState(() => _validateFields()), decoration: _inputDecoration(label: l10n.port, icon: Icons.settings_ethernet_outlined, errorText: portValidationText)),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: ignoreBadCertificate,
              onChanged: https ? (value) => setState(() => ignoreBadCertificate = value) : null,
              title: const Text('忽略 SSL 证书'),
              subtitle: Text(https ? '仅适用于自签名或异常证书场景' : '仅 HTTPS 下可用', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: usernameController, onChanged: (_) => setState(() => _validateFields()), decoration: _inputDecoration(label: l10n.username, icon: Icons.person_outline, errorText: usernameValidationText)),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            obscureText: obscurePassword,
            onChanged: (_) => setState(() => _validateFields()),
            decoration: _inputDecoration(label: l10n.password, icon: Icons.lock_outline, errorText: passwordValidationText, suffixIcon: IconButton(onPressed: () => setState(() => obscurePassword = !obscurePassword), icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
            onSubmitted: (_) => isLoading ? null : login(),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: rememberPassword,
              onChanged: (value) => setState(() => rememberPassword = value ?? false),
              title: const Text('记住密码'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _canSubmit ? login : null, icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.login_rounded), label: Text(isLoading ? l10n.loggingIn : '登录 DSM'))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: isTesting ? null : testConnection, icon: isTesting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_tethering_outlined), label: Text(isTesting ? l10n.testingConnection : '测试连接'))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentServer = ref.watch(currentServerProvider);
    final savedUsername = ref.watch(savedUsernameProvider);
    final savedPassword = ref.watch(savedPasswordProvider);
    final savedRememberPassword = ref.watch(savedRememberPasswordProvider);
    final savedServers = ref.watch(savedServersProvider);
    final savedServerUsernames = ref.watch(savedServerUsernamesProvider);
    final savedServerLastUsed = ref.watch(savedServerLastUsedProvider);
    final sessionExpiredAsync = ref.watch(localStorageProvider).readString(AppConstants.sessionExpiredFlagKey);
    fillInitialValues(currentServer, savedUsername, savedServers.isNotEmpty);
    if (passwordController.text.isEmpty && (savedPassword?.isNotEmpty ?? false)) {
      passwordController.text = savedPassword!;
      rememberPassword = savedRememberPassword;
    }

    if (selectedServerId == null && currentServer == null && savedServers.isNotEmpty) {
      final sortedServers = [...savedServers]..sort((a, b) => (savedServerLastUsed[b.id] ?? 0).compareTo(savedServerLastUsed[a.id] ?? 0));
      final latest = sortedServers.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || selectedServerId != null) return;
        applyServerPreset(latest, username: savedServerUsernames[latest.id]);
      });
    }

    sessionExpiredAsync.then((flag) {
      if (!mounted || handledExpiredMessage || flag != '1') return;
      handledExpiredMessage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        setState(() {
          infoText = null;
          errorText = '登录状态已过期，请重新登录以恢复实时连接。';
        });
        await ref.read(localStorageProvider).remove(AppConstants.sessionExpiredFlagKey);
      });
    });

    final showQuickLogin = savedServers.isNotEmpty && loginMode == _LoginMode.quick;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF3F7FF), Color(0xFFFFFFFF)])),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.16), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.dns_rounded, color: Colors.white, size: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.appTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)), child: const Text('DSM 7+', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                  ]),
                  const SizedBox(height: 10),
                  Text(showQuickLogin ? '已为你准备好快速登录。' : '连接你的群晖 DSM。', style: TextStyle(color: Colors.white.withValues(alpha: 0.90), height: 1.35, fontSize: 13)),
                  const SizedBox(height: 4),
                ]),
              ),
              const SizedBox(height: 18),
              _buildStatusBanner(),
              if (showQuickLogin) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('快速重新登录', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('有历史记录时优先显示这个界面，减少输入内容。', style: TextStyle(color: Colors.grey.shade600)),
                  ]),
                ),
                _buildQuickLoginCard(l10n, savedServers),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('登录到 NAS', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('支持局域网 IP、域名和端口。', style: TextStyle(color: Colors.grey.shade600)),
                  ]),
                ),
                _buildInputCard(l10n, showBackToQuick: savedServers.isNotEmpty),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
