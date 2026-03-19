import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/server_url_helper.dart';
import '../../../../domain/entities/nas_server.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';

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
  bool https = true;
  bool isLoading = false;
  bool isTesting = false;
  String? errorText;
  String? infoText;
  bool initialized = false;

  @override
  void dispose() {
    serverNameController.dispose();
    hostController.dispose();
    portController.dispose();
    basePathController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void fillInitialValues(NasServer? server, String? savedUsername) {
    if (initialized) return;
    initialized = true;

    if (server == null) {
      serverNameController.text = '我的 NAS';
      hostController.text = '192.168.1.2';
      portController.text = '5001';
      usernameController.text = savedUsername ?? '';
      https = true;
      return;
    }

    initialized = true;
    serverNameController.text = server.name;
    hostController.text = server.host;
    portController.text = server.port.toString();
    basePathController.text = server.basePath ?? '';
    usernameController.text = savedUsername ?? '';
    https = server.https;
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
    setState(() {
      isLoading = true;
      errorText = null;
      infoText = null;
    });

    final server = buildServer();
    final username = usernameController.text.trim();
    ref.read(currentServerProvider.notifier).state = server;

    try {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentServer = ref.watch(currentServerProvider);
    final savedUsername = ref.watch(savedUsernameProvider);
    fillInitialValues(currentServer, savedUsername);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            Text(l10n.loginTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: serverNameController, decoration: InputDecoration(labelText: l10n.deviceName)),
            const SizedBox(height: 12),
            TextField(controller: hostController, decoration: InputDecoration(labelText: l10n.addressOrHost)),
            const SizedBox(height: 12),
            TextField(controller: portController, decoration: InputDecoration(labelText: l10n.port)),
            const SizedBox(height: 12),
            TextField(controller: basePathController, decoration: InputDecoration(labelText: l10n.basePathOptional)),
            const SizedBox(height: 12),
            SwitchListTile(
              value: https,
              onChanged: (value) => setState(() => https = value),
              title: Text(l10n.useHttps),
            ),
            const SizedBox(height: 12),
            TextField(controller: usernameController, decoration: InputDecoration(labelText: l10n.username)),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.password),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Text(errorText!, style: const TextStyle(color: Colors.red)),
            ],
            if (infoText != null) ...[
              const SizedBox(height: 12),
              Text(infoText!, style: const TextStyle(color: Colors.green)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : login,
              child: Text(isLoading ? l10n.loggingIn : l10n.login),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isTesting ? null : testConnection,
              child: Text(isTesting ? l10n.testingConnection : l10n.testConnection),
            ),
          ],
        ),
      ),
    );
  }
}
    ],
        ),
      ),
    );
  }
}
