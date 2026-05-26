import '../services/auth_service.dart';

class AuthController {
  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<void> loginUser(String email, String password) async {
    await _authService.login(email, password);
  }

  Future<void> registerUser(String email, String password) async {
    await _authService.register(email, password);
  }

  Future<void> logout() => _authService.logout();
}
