import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/services/auth_repository.dart';

class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  Future<User> call({required String email, required String password}) {
    return _repository.login(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }
}
