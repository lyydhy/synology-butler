import 'package:characters/characters.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/server_url_helper.dart';
import '../../../../domain/entities/nas_server.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';

enum _LoginMode {
  quick,
  manual,
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final serverNameController = TextEditingController();
  final hostController = TextEditingController();
  final portController = TextEditingController();
  final basePathController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocusNode = FocusNode();

  bool https = true;
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
  _LoginMode loginMode = _LoginMode.manual;

  @override
  void dispose() {
    serverNameController.dispose();
    hostController.dispose();
    portController.dispose();
    basePathController.dispose();
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
      return;
    }

    serverNameController.text = server.name;
    hostController.text = server.host;
    portController.text = server.port.toString();
    basePathController.text = server.basePath ?? '';
    usernameController.text = savedUsername ?? '';
    https = server.https;
    selectedServerId = server.id;
    _validateFields();
  }

  void applyServerPreset(NasServer server, {String? username}) {
    setState(() {
      selectedServerId = server.id;
      serverNameController.text = server.name;
      hostController.text = server.host;
      portController.text = server.port.toString();
      basePathController.text = server.basePath ?? '';
      https = server.https;
      loginMode = _LoginMode.quick;
      if (username != null && username.isNotEmpty) {
        usernameController.text = username;
      }
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
        if ((basePathController.text.isEmpty ? null : basePathController.text) == server.basePath) {
          basePathController.clear();
        }
        usernameController.clear();
        passwordController.clear();
        loginMode = stillHasSavedServers ? _LoginMode.quick : _LoginMode.manual;
        _validateFields();
      });
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text('已删除 ${server.name} 的历史记录')),
    );
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
    _validateFields();
    return selectedServerId != null &&
        usernameValidationText == null &&
        passwordValidationText == null &&
        !isLoading;
  }

  NasServer buildServer() {
    final normalizedHost = ServerUrlHelper.normalizeHost(hostController.text.trim());
    final basePath = basePathController.text.trim();

    return NasServer(
      id: '$normalizedHost:${portController.text.trim()}:$basePath',
      name: serverNameController.text.trim().isEmpty ? '我的 NAS' : serverNameController.text.trim(),
      host: normalizedHost,
      port: int.tryParse(portController.text.trim()) ?? 5001,
      https: https,
      basePath: basePath.isEmpty ? null : (basePath.startsWith('/') ? basePath : '/$basePath'),
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
      final client = DioClient(baseUrl: baseUrl).dio;
      await client.get(
        '/webapi/query.cgi',
        queryParameters: {
          'api': 'SYNO.API.Info',
          'version': '1',
          'method': 'query',
          'query': 'SYNO.API.Auth',
        },
      );

      setState(() {
        infoText = '连接成功：已探测到 DSM Web API';
      });
    } on DioException catch (e) {
      setState(() {
        errorText = ErrorMapper.map(e).message;
      });
    } catch (e) {
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

    try {
      final version = await ref.read(authRepositoryProvider).probeVersion(server: server);
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
      ref.read(currentSessionProvider.notifier).state = session;
      await ref.read(persistLoginProvider)(server, session, username);
      if (mounted) context.go('/home');
    } catch (e) {
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

  Widget _buildStatusBanner() {
    if (errorText == null && infoText == null) {
      return const SizedBox.shrink();
    }

    final isError = errorText != null;
    final color = isError ? Colors.red : Colors.green;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;
    final text = errorText ?? infoText!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.20)),
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

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedServerSection(
    List<NasServer> savedServers,
    Map<String, String> savedUsernames,
    Map<String, int> lastUsedMap,
  ) {
    if (savedServers.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedServers = [...savedServers]
      ..sort((a, b) => (lastUsedMap[b.id] ?? 0).compareTo(lastUsedMap[a.id] ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '快速重新登录',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            if (selectedServerId != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedServerId = null;
                    infoText = '已取消选择历史设备';
                    if (savedServers.isNotEmpty) {
                      loginMode = _LoginMode.manual;
                    }
                  });
                },
                child: const Text('取消选择'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '点击条目自动回填；长按或点右侧按钮可删除该历史记录',
          style: TextStyle(color: Colors.grey.shade600, height: 1.35),
        ),
        const SizedBox(height: 12),
        ...sortedServers.map((server) {
          final username = savedUsernames[server.id];
          final lastUsed = lastUsedMap[server.id];
          final isSelected = server.id == selectedServerId;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFEEF4FF), Color(0xFFF8FBFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2563EB).withOpacity(0.45) : Colors.black.withOpacity(0.06),
                  width: isSelected ? 1.4 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? const Color(0xFF2563EB).withOpacity(0.10) : Colors.black.withOpacity(0.04),
                    blurRadius: isSelected ? 18 : 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => applyServerPreset(server, username: username),
                  onLongPress: () => removeSavedServer(server),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _buildServerInitials(server),
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF2563EB),
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      server.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? const Color(0xFF0F172A) : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFDBEAFE) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _formatLastUsed(lastUsed),
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF1D4ED8) : Colors.grey.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ServerUrlHelper.buildBaseUrl(server),
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      (username != null && username.isNotEmpty) ? username : '未记录用户名',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 18),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: '删除历史记录',
                          onPressed: () => removeSavedServer(server),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: Colors.grey.shade500,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 18),
      ],
    );
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
        borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
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

  Widget _buildQuickLoginCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '快速登录',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedServerId == null ? '先选择一个历史设备，然后输入密码即可登录' : '已选中历史设备，输入密码即可登录',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: usernameController,
              onChanged: (_) => setState(() => _validateFields()),
              decoration: _inputDecoration(
                label: l10n.username,
                icon: Icons.person_outline,
                errorText: usernameValidationText,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              obscureText: obscurePassword,
              onChanged: (_) => setState(() => _validateFields()),
              decoration: _inputDecoration(
                label: l10n.password,
                icon: Icons.lock_outline,
                errorText: passwordValidationText,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                  icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              onSubmitted: (_) => isLoading ? null : login(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canQuickLogin ? login : null,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(isLoading ? l10n.loggingIn : '登录 DSM'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    loginMode = _LoginMode.manual;
                    errorText = null;
                    infoText = '已切换到新账号 / 新设备登录';
                  });
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('使用新账号 / 新设备登录'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: BorderSide(color: const Color(0xFF2563EB).withOpacity(0.18)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(AppLocalizations l10n, {required bool showBackToQuick}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '连接信息',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '填写 NAS 地址与 DSM 账号信息',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (showBackToQuick)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        loginMode = _LoginMode.quick;
                        errorText = null;
                        infoText = '已切换回快速登录';
                      });
                    },
                    child: const Text('快速登录'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: serverNameController,
              decoration: _inputDecoration(label: '设备名称', icon: Icons.badge_outlined),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hostController,
              onChanged: (_) => setState(() => _validateFields()),
              decoration: _inputDecoration(
                label: l10n.addressOrHost,
                icon: Icons.language_outlined,
                errorText: hostValidationText,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: portController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() => _validateFields()),
                    decoration: _inputDecoration(
                      label: l10n.port,
                      icon: Icons.settings_ethernet_outlined,
                      errorText: portValidationText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'HTTPS',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Switch.adaptive(
                          value: https,
                          onChanged: (value) => setState(() => https = value),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: basePathController,
              decoration: _inputDecoration(label: l10n.basePathOptional, icon: Icons.route_outlined),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              onChanged: (_) => setState(() => _validateFields()),
              decoration: _inputDecoration(
                label: l10n.username,
                icon: Icons.person_outline,
                errorText: usernameValidationText,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              obscureText: obscurePassword,
              onChanged: (_) => setState(() => _validateFields()),
              decoration: _inputDecoration(
                label: l10n.password,
                icon: Icons.lock_outline,
                errorText: passwordValidationText,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                  icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              onSubmitted: (_) => isLoading ? null : login(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canSubmit ? login : null,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(isLoading ? l10n.loggingIn : '登录 DSM'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isTesting ? null : testConnection,
                icon: isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering_outlined),
                label: Text(isTesting ? l10n.testingConnection : '测试连接'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: BorderSide(color: const Color(0xFF2563EB).withOpacity(0.18)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentServer = ref.watch(currentServerProvider);
    final savedUsername = ref.watch(savedUsernameProvider);
    final savedServers = ref.watch(savedServersProvider);
    final savedServerUsernames = ref.watch(savedServerUsernamesProvider);
    final savedServerLastUsed = ref.watch(savedServerLastUsedProvider);
    final sessionExpiredAsync = ref.watch(localStorageProvider).readString(AppConstants.sessionExpiredFlagKey);
    fillInitialValues(currentServer, savedUsername, savedServers.isNotEmpty);

    if (selectedServerId == null && currentServer == null && savedServers.isNotEmpty) {
      final sortedServers = [...savedServers]
        ..sort((a, b) => (savedServerLastUsed[b.id] ?? 0).compareTo(savedServerLastUsed[a.id] ?? 0));
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
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.28),
                      blurRadius: 34,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.dns_rounded, color: Colors.white, size: 30),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'DSM 7+',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.appTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      showQuickLogin
                          ? '优先展示历史设备快速登录；如需切换服务器，可进入新账号登录。'
                          : '连接你的群晖 DSM，查看系统状态、文件与下载任务。',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        height: 1.45,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildQuickActionChip(
                          icon: showQuickLogin ? Icons.lock_open_outlined : Icons.bolt_outlined,
                          label: showQuickLogin ? '输入密码登录' : '快速登录',
                          onTap: () {
                            passwordFocusNode.requestFocus();
                          },
                        ),
                        _buildQuickActionChip(
                          icon: Icons.wifi_tethering_outlined,
                          label: '测试连接',
                          onTap: isTesting ? () {} : () => testConnection(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildStatusBanner(),
              _buildSavedServerSection(savedServers, savedServerUsernames, savedServerLastUsed),
              if (showQuickLogin) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '快速重新登录',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '有历史记录时优先显示这个界面，减少输入内容。',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _buildQuickLoginCard(l10n),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '登录到 NAS',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '支持局域网 IP、域名、端口和自定义基础路径。',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
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
