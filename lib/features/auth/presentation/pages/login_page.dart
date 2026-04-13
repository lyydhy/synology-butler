import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/server_url_helper.dart';
import '../../../../domain/entities/nas_server.dart';
import '../../../../core/network/app_dio.dart';
import '../providers/auth_providers.dart';
import '../providers/current_connection_readers.dart';
import '../../../preferences/providers/preferences_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  final NasServer? initialServer;

  const LoginPage({super.key, this.initialServer});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final addressController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocusNode = FocusNode();

  bool https = true;
  bool ignoreBadCertificate = false;
  bool isLoading = false;
  bool isTesting = false;
  bool obscurePassword = true;
  String? selectedServerId;
  String? addressError;
  String? usernameError;
  String? passwordError;
  String? errorText;
  String? infoText;

  @override
  void initState() {
    super.initState();
    if (widget.initialServer != null) {
      _applyServer(widget.initialServer!);
    } else {
      addressController.text = '192.168.1.2';
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void _resetForm() {
    addressController.clear();
    usernameController.clear();
    passwordController.clear();
    selectedServerId = null;
    https = true;
    ignoreBadCertificate = false;
    errorText = null;
    infoText = null;
    addressError = null;
    usernameError = null;
    passwordError = null;
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

  void _applyServer(NasServer server, {String? username}) {
    setState(() {
      selectedServerId = server.id;
      https = server.https;
      ignoreBadCertificate = server.ignoreBadCertificate;
      final showPort = (server.https && server.port != 443) || (!server.https && server.port != 80);
      addressController.text = showPort ? '${server.host}:${server.port}' : server.host;
      if (username != null && username.isNotEmpty) {
        usernameController.text = username;
      }
      passwordController.clear();
      errorText = null;
      infoText = null;
      addressError = null;
      usernameError = null;
      passwordError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) passwordFocusNode.requestFocus();
    });
  }

  String _buildServerInitials(NasServer server) {
    final value = server.name.trim();
    if (value.isEmpty) return 'N';
    return value.characters.first.toUpperCase();
  }

  void _validateAddress() {
    final (host, port) = _parseAddress(addressController.text);
    if (host.isEmpty) {
      addressError = l10n.enterNasAddress;
    } else if (port <= 0 || port > 65535) {
      addressError = l10n.portRange;
    } else {
      addressError = null;
    }
  }

  void _validateUsername() {
    usernameError = usernameController.text.trim().isEmpty ? l10n.enterUsername : null;
  }

  void _validatePassword() {
    passwordError = passwordController.text.isEmpty ? l10n.enterPassword : null;
  }

  void _clearFieldErrors() {
    addressError = null;
    usernameError = null;
    passwordError = null;
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


  // ─── 状态提示条 ────────────────────────────────────────────────
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

  // ─── HTTP/HTTPS 切换 ────────────────────────────────────────────
  Widget _buildHttpsToggle(Color primaryColor) {
    final label = https ? 'HTTPS' : 'HTTP';
    final color = https ? primaryColor : Colors.orange.shade700;
    return GestureDetector(
      onTap: () {
        setState(() {
          https = !https;
          if (!https) ignoreBadCertificate = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(https ? Icons.lock_outline : Icons.lock_open_outlined, color: color, size: 16),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
        ]),
      ),
    );
  }

  // ─── 忽略证书选项 ──────────────────────────────────────────────
  Widget _buildIgnoreCertToggle(Color primaryColor) {
    final enabled = https;
    return GestureDetector(
      onTap: enabled ? () => setState(() => ignoreBadCertificate = !ignoreBadCertificate) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? (ignoreBadCertificate ? primaryColor.withValues(alpha: 0.30) : Colors.black.withValues(alpha: 0.06))
                : Colors.transparent,
          ),
        ),
        child: Row(children: [
          Icon(
            Icons.security_outlined,
            color: enabled ? (ignoreBadCertificate ? primaryColor : Colors.grey.shade600) : Colors.grey.shade400,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ignoreSslCert,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: enabled ? null : Colors.grey.shade400,
                  ),
                ),
                Text(
                  l10n.httpsOnly,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 22,
            decoration: BoxDecoration(
              color: ignoreBadCertificate ? primaryColor : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(11),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              alignment: ignoreBadCertificate ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // ─── 主表单 ────────────────────────────────────────────────────
  Widget _buildForm(Color primaryColor) {
    return Column(children: [
      // HTTPS 切换 + 地址输入
      Row(children: [
        _buildHttpsToggle(primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: addressController,
            onChanged: (_) => setState(() => _validateAddress()),
            decoration: InputDecoration(
              labelText: l10n.addressOrHost,
              hintText: '192.168.1.2 或 192.168.1.2:5000',
              prefixIcon: const Icon(Icons.language_outlined),
              errorText: addressError,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
              ),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      // 忽略证书
      _buildIgnoreCertToggle(primaryColor),
      const SizedBox(height: 10),
      TextField(
        controller: usernameController,
        onChanged: (_) => setState(() => _validateUsername()),
        decoration: InputDecoration(
          labelText: l10n.username,
          prefixIcon: const Icon(Icons.person_outline),
          errorText: usernameError,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
          ),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: passwordController,
        obscureText: obscurePassword,
        onChanged: (_) => setState(() => _validatePassword()),
        decoration: InputDecoration(
          labelText: l10n.password,
          prefixIcon: const Icon(Icons.lock_outline),
          errorText: passwordError,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
          ),
          suffixIcon: IconButton(
            icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => obscurePassword = !obscurePassword),
          ),
        ),
        onSubmitted: (_) => isLoading ? null : login(),
      ),
      const SizedBox(height: 16),
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
            onPressed: _canSubmit ? login : null,
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.loginDsm, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ]),
    ]);
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeColorOption = ref.watch(themeColorProvider);
    final primaryColor = seedColorFor(themeColorOption);
    final savedServers = ref.watch(savedServersProvider);
    final savedServerLastUsed = ref.watch(savedServerLastUsedProvider);
    final savedServerUsernames = ref.watch(savedServerUsernamesProvider);

    // 没有initialServer时，自动填充最新一条历史记录（仅填地址和用户名）
    if (widget.initialServer == null && savedServers.isNotEmpty && addressController.text == '192.168.1.2') {
      final sorted = [...savedServers]
        ..sort((a, b) => (savedServerLastUsed[b.id] ?? 0).compareTo(savedServerLastUsed[a.id] ?? 0));
      final latest = sorted.first;
      final showPort = (latest.https && latest.port != 443) || (!latest.https && latest.port != 80);
      addressController.text = showPort ? '${latest.host}:${latest.port}' : latest.host;
      https = latest.https;
      ignoreBadCertificate = latest.ignoreBadCertificate;
      final savedUsername = savedServerUsernames[latest.id];
      if (savedUsername != null && savedUsername.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) usernameController.text = savedUsername;
        });
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          widget.initialServer != null ? l10n.loginToNas(widget.initialServer!.name) : l10n.loginDsm,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: primaryColor),
        ),
        centerTitle: true,
        leading: widget.initialServer != null
            ? IconButton(
                onPressed: () => context.pushReplacement('/servers'),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        actions: [
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          child: Column(
            children: [
              _buildStatusBanner(),
              Expanded(child: _buildForm(primaryColor)),
              if (savedServers.isNotEmpty && widget.initialServer == null) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/servers'),
                    icon: Icon(Icons.history_rounded, color: primaryColor.withValues(alpha: 0.7), size: 18),
                    label: Text(l10n.historyDevices, style: TextStyle(color: primaryColor.withValues(alpha: 0.7))),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
