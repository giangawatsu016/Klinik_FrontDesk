import '../repositories/auth_repository.dart';
import '../entities/auth_entity.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthEntity> execute(String email, String password) {
    return repository.login(email, password);
  }
}
