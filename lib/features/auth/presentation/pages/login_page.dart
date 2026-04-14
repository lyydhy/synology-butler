import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/server_url_helper.dart';
import '../../../../domain/entities/nas_server.dart';
import '../../../../core/network/app_dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/auth_providers.dart';
import '../../../preferences/providers/preferences_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  final NasServer? initialServer;

  const LoginPage({super.key, this.initialServer});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final addressController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool https = true;
  bool ignoreBadCertificate = false;
  bool isLoading = false;
  bool isTesting = false;
  bool obscurePassword = true;
  String? addressError;
  String? usernameError;
  String? passwordError;
  String? errorText;
  String? infoText;
  String? selectedServerId;

  bool _autofilled = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autofilled) return;
      _autofilled = true;
      _autofillFromHistory();
    });

    _animController.forward();
  }

  Future<void> _autofillFromHistory() async {
    if (widget.initialServer != null) {
      _applyServer(widget.initialServer!);
      return;
    }

    final savedServers = ref.read(savedServersProvider);
    final savedServerLastUsed = ref.read(savedServerLastUsedProvider);
    final savedServerUsernames = ref.read(savedServerUsernamesProvider);

    if (savedServers.isEmpty) return;

    final sorted = [...savedServers]
      ..sort((a, b) => (savedServerLastUsed[b.id] ?? 0).compareTo(savedServerLastUsed[a.id] ?? 0));
    final latest = sorted.first;

    // 直接从 secureStorage 读取密码，确保拿到持久化数据
    final secureStorage = ref.read(secureStorageProvider);
    final savedPassword = await secureStorage.read('${AppConstants.savedPasswordPrefix}${latest.id}');

    if (!mounted) return;
    setState(() {
      selectedServerId = latest.id;
      https = latest.https;
      ignoreBadCertificate = latest.ignoreBadCertificate;
      final showPort = (latest.https && latest.port != 443) || (!latest.https && latest.port != 80);
      addressController.text = showPort ? '${latest.host}:${latest.port}' : latest.host;
      final savedUsername = savedServerUsernames[latest.id];
      if (savedUsername != null && savedUsername.isNotEmpty) {
        usernameController.text = savedUsername;
      }
      passwordController.text = savedPassword ?? '';
    });
  }

  void _applyServer(NasServer server) {
    setState(() {
      selectedServerId = server.id;
      https = server.https;
      ignoreBadCertificate = server.ignoreBadCertificate;
      final showPort = (server.https && server.port != 443) || (!server.https && server.port != 80);
      addressController.text = showPort ? '${server.host}:${server.port}' : server.host;
      passwordController.text = '';
      errorText = null;
      infoText = null;
      addressError = null;
      usernameError = null;
      passwordError = null;
    });
  }

  (String host, int port) _parseAddress(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return ('', 5001);
    if (trimmed.contains(':')) {
      final lastColon = trimmed.lastIndexOf(':');
      final host = trimmed.substring(0, lastColon);
      final portStr = trimmed.substring(lastColon + 1);
      final port = int.tryParse(portStr) ?? (https ? 443 : 80);
      return (host.trim(), port);
    }
    return (trimmed, https ? 443 : 80);
  }

  void _validateAddress() {
    final (host, port) = _parseAddress(addressController.text);
    addressError = host.isEmpty
        ? l10n.enterNasAddress
        : (port <= 0 || port > 65535 ? l10n.portRange : null);
  }

  void _validateUsername() {
    usernameError = usernameController.text.trim().isEmpty ? l10n.enterUsername : null;
  }

  void _validatePassword() {
    passwordError = passwordController.text.isEmpty ? l10n.enterPassword : null;
  }

  bool get _canSubmit =>
      addressError == null && usernameError == null && passwordError == null && !isLoading;

  NasServer buildServer() {
    final (host, port) = _parseAddress(addressController.text);
    final normalizedHost = ServerUrlHelper.normalizeHost(host);
    return NasServer(
      id: '$normalizedHost:$port:${https ? 'https' : 'http'}:${ignoreBadCertificate ? 'insecure' : 'strict'}',
      name: l10n.defaultDeviceName,
      host: normalizedHost,
      port: port,
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
    _validateAddress();
    _validateUsername();
    _validatePassword();
    if (!_canSubmit) {
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

  // ─── 状态提示条 ──────────────────────────────────────────────
  Widget _buildStatusBanner() {
    if (errorText == null && infoText == null) return const SizedBox.shrink();
    final isError = errorText != null;
    final color = isError ? Colors.red : Colors.green;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 14),
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

  // ─── 顶部品牌区 ──────────────────────────────────────────────
  Widget _buildHeader(Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 28),
      child: Column(children: [
        // Logo 圆角方块
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withValues(alpha: 0.85),
                primaryColor.withValues(alpha: 0.55),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.cloud_outlined, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 18),
        Text(
          '群晖管家',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.loginDsm,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ]),
    );
  }

  // ─── HTTP/HTTPS 切换 ──────────────────────────────────────────
  Widget _buildHttpsToggle(Color primaryColor) {
    final label = https ? 'HTTPS' : 'HTTP';
    final color = https ? primaryColor : Colors.orange.shade700;
    return GestureDetector(
      onTap: () => setState(() {
        https = !https;
        if (!https) ignoreBadCertificate = false;
      }),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(https ? Icons.lock_outline : Icons.lock_open_outlined, color: color, size: 18),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
        ]),
      ),
    );
  }

  // ─── 忽略证书 ─────────────────────────────────────────────────
  Widget _buildIgnoreCertToggle(Color primaryColor) {
    final enabled = https;
    return GestureDetector(
      onTap: enabled ? () => setState(() => ignoreBadCertificate = !ignoreBadCertificate) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? (ignoreBadCertificate ? primaryColor.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.05))
                : Colors.transparent,
          ),
        ),
        child: Row(children: [
          Icon(
            Icons.security_outlined,
            color: enabled
                ? (ignoreBadCertificate ? primaryColor : Theme.of(context).colorScheme.onSurfaceVariant)
                : Colors.grey.shade400,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                l10n.ignoreSslCert,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: enabled ? null : Colors.grey.shade400),
              ),
              Text(l10n.httpsOnly,
                  style: TextStyle(fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
          Container(
            width: 42,
            height: 24,
            decoration: BoxDecoration(
              color: ignoreBadCertificate ? primaryColor : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              alignment: ignoreBadCertificate ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── 输入字段（统一高度56） ────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String? errorText,
    required String labelText,
    required IconData icon,
    required Color primaryColor,
    bool obscureText = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    TextInputAction? textInputAction,
  }) {
    final hasError = errorText != null;
    final theme = Theme.of(context);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? Colors.redAccent.withValues(alpha: 0.60)
              : (controller.text.isNotEmpty
                  ? primaryColor.withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.05)),
          width: hasError ? 1.3 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onTap: onTap,
        onChanged: onChanged,
        textInputAction: textInputAction,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: labelText,
          hintStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: hasError
                ? Colors.redAccent.withValues(alpha: 0.70)
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 14, right: 4),
            child: Icon(
              icon,
              color: hasError
                  ? Colors.redAccent
                  : (controller.text.isNotEmpty
                      ? primaryColor.withValues(alpha: 0.80)
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.70)),
              size: 20,
            ),
          ),
          errorText: null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          suffixIcon: suffixIcon,
          isDense: true,
        ),
      ),
    );
  }

  // ─── 主表单 ────────────────────────────────────────────────────
  Widget _buildForm(Color primaryColor) {
    return Column(children: [
      // HTTPS + 地址
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHttpsToggle(primaryColor),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField(
            controller: addressController,
            errorText: null,
            labelText: l10n.addressOrHost,
            icon: Icons.language_outlined,
            primaryColor: primaryColor,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _validateAddress()),
          )),
        ],
      ),
      if (addressError != null) _errorRow(addressError!),
      const SizedBox(height: 10),
      // 忽略证书
      _buildIgnoreCertToggle(primaryColor),
      const SizedBox(height: 10),
      // 用户名
      _buildTextField(
        controller: usernameController,
        errorText: usernameError,
        labelText: l10n.username,
        icon: Icons.person_outline,
        primaryColor: primaryColor,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() => _validateUsername()),
      ),
      if (usernameError != null) _errorRow(usernameError!),
      const SizedBox(height: 10),
      // 密码
      _buildTextField(
        controller: passwordController,
        errorText: passwordError,
        labelText: l10n.password,
        icon: Icons.lock_outline,
        primaryColor: primaryColor,
        obscureText: obscurePassword,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() => _validatePassword()),
        suffixIcon: IconButton(
          icon: Icon(
            obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.60),
            size: 21,
          ),
          onPressed: () => setState(() => obscurePassword = !obscurePassword),
        ),
      ),
      if (passwordError != null) _errorRow(passwordError!),
      const SizedBox(height: 16),
      // 登录按钮（渐变色大按钮）
      _buildLoginButton(primaryColor),
    ]);
  }

  Widget _errorRow(String msg) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 5),
        child: Row(children: [
          Icon(Icons.error_outline, size: 13, color: Colors.redAccent.withValues(alpha: 0.80)),
          const SizedBox(width: 4),
          Text(msg,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent.withValues(alpha: 0.80),
                  fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _buildLoginButton(Color primaryColor) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.80),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canSubmit ? login : null,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : Text(
                    l10n.loginDsm,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeColorOption = ref.watch(themeColorProvider);
    final primaryColor = seedColorFor(themeColorOption);
    final savedServers = ref.watch(savedServersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? HSLColor.fromColor(primaryColor).withLightness(0.06).toColor()
        : HSLColor.fromColor(primaryColor).withLightness(0.93).withSaturation(0.25).toColor();

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        // 背景装饰圆
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.14),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -80,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.10),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // 主内容
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      child: Column(children: [
                        _buildHeader(primaryColor),
                        // 表单卡片
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.40)
                                    : Colors.black.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(children: [
                            if (errorText != null || infoText != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildStatusBanner(),
                              ),
                            _buildForm(primaryColor),
                          ]),
                        ),
                        const Spacer(),
                        if (savedServers.isNotEmpty && widget.initialServer == null) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => context.push('/servers'),
                            icon: Icon(Icons.history_rounded,
                                color: primaryColor.withValues(alpha: 0.70), size: 18),
                            label: Text(l10n.historyDevices,
                                style: TextStyle(
                                    color: primaryColor.withValues(alpha: 0.70),
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    addressController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
