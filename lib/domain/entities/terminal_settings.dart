/// 终端设置模型
class TerminalSettings {
  /// 是否启用 SSH
  final bool sshEnabled;

  /// 是否启用 Telnet
  final bool telnetEnabled;

  /// SSH 端口
  final int sshPort;

  const TerminalSettings({
    required this.sshEnabled,
    required this.telnetEnabled,
    required this.sshPort,
  });

  factory TerminalSettings.fromApiResponse(Map<String, dynamic>? data) {
    if (data == null) {
      return const TerminalSettings(
        sshEnabled: false,
        telnetEnabled: false,
        sshPort: 22,
      );
    }

    return TerminalSettings(
      sshEnabled: data['enable_ssh'] as bool? ?? false,
      telnetEnabled: data['enable_telnet'] as bool? ?? false,
      sshPort: data['ssh_port'] as int? ?? 22,
    );
  }

  TerminalSettings copyWith({
    bool? sshEnabled,
    bool? telnetEnabled,
    int? sshPort,
  }) {
    return TerminalSettings(
      sshEnabled: sshEnabled ?? this.sshEnabled,
      telnetEnabled: telnetEnabled ?? this.telnetEnabled,
      sshPort: sshPort ?? this.sshPort,
    );
  }
}
