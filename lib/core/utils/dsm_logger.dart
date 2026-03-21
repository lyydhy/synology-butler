import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'dsm_error_helper.dart';

class DsmLogger {
  static void request({
    required String module,
    required String action,
    String? method,
    String? path,
    Map<String, dynamic>? extra,
    String? sid,
    String? synoToken,
    String? cookieHeader,
  }) {
    final lines = <String>[
      '[DSM][$module.$action][REQ]',
      if (method != null) 'method=$method',
      if (path != null) 'path=$path',
      'sid=${_presence(sid)}',
      'synoToken=${_presence(synoToken)}',
      'cookie=${_presence(cookieHeader)}',
      if (extra != null && extra.isNotEmpty) 'extra=${_pretty(extra)}',
    ];

    debugPrint(lines.join('\n'));
  }

  static void success({
    required String module,
    required String action,
    String? path,
    Map<String, dynamic>? extra,
    dynamic response,
  }) {
    final lines = <String>[
      '[DSM][$module.$action][OK]',
      if (path != null) 'path=$path',
      if (extra != null && extra.isNotEmpty) 'extra=${_pretty(extra)}',
      if (response != null) 'response=${_pretty(response)}',
    ];

    debugPrint(lines.join('\n'));
  }

  static void failure({
    required String module,
    required String action,
    String? path,
    dynamic response,
    dynamic code,
    String? reason,
    Map<String, dynamic>? extra,
    String? sid,
    String? synoToken,
    String? cookieHeader,
  }) {
    final resolvedCode = code ?? DsmErrorHelper.extractErrorCode(response);
    final resolvedReason = reason ?? DsmErrorHelper.mapErrorCode(resolvedCode);

    final lines = <String>[
      '[DSM][$module.$action][FAIL]',
      if (path != null) 'path=$path',
      if (resolvedCode != null) 'code=$resolvedCode',
      if (resolvedReason != null && resolvedReason.isNotEmpty) 'reason=$resolvedReason',
      'sid=${_presence(sid)}',
      'synoToken=${_presence(synoToken)}',
      'cookie=${_presence(cookieHeader)}',
      if (extra != null && extra.isNotEmpty) 'extra=${_pretty(extra)}',
      if (response != null) 'response=${_pretty(response)}',
    ];

    debugPrint(lines.join('\n'));
  }

  static String buildFailureMessage({
    required String module,
    required String action,
    dynamic response,
    dynamic code,
  }) {
    final resolvedCode = code ?? DsmErrorHelper.extractErrorCode(response);
    final reason = DsmErrorHelper.mapErrorCode(resolvedCode);
    return '[DSM][$module.$action] failed, code=${resolvedCode ?? 'unknown'}, reason=${reason ?? 'unknown'}, response=${_pretty(response)}';
  }

  static String _presence(String? value) {
    return value != null && value.isNotEmpty ? 'present' : 'missing';
  }

  static String _pretty(dynamic value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}
