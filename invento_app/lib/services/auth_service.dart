class AuthService {
  Future login(String email, String password) async {
    await Future.delayed(Duration(seconds: 1));
    return true; // fake login success
  }

  Future register(String email, String password) async {
    await Future.delayed(Duration(seconds: 1));
    return true;
  }
}