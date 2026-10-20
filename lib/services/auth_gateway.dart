abstract interface class AuthGateway {
  Future<void> login({required String email, required String password});

  Future<void> register({
    required String name,
    required String email,
    required String password,
  });
}

class SimulatedAuthGateway implements AuthGateway {
  const SimulatedAuthGateway({this.delay = const Duration(milliseconds: 700)});

  final Duration delay;

  @override
  Future<void> login({required String email, required String password}) async {
    await Future<void>.delayed(delay);
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
  }
}
