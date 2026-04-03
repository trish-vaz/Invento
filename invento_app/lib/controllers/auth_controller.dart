import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future loginUser(String email, String password) async {
    return await _authService.login(email, password);
  }

  Future registerUser(String email, String password) async {
    return await _authService.register(email, password);
  }
}
