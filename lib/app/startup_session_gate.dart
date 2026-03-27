class StartupSessionGateResult {
  const StartupSessionGateResult({required this.initialLocation});

  final String initialLocation;
}

class StartupSessionGate {
  Future<StartupSessionGateResult> resolve() async {
    return const StartupSessionGateResult(initialLocation: '/splash');
  }
}
