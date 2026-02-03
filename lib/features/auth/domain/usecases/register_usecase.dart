import '../repositories/auth_repository.dart';
import '../entities/auth_entity.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<AuthEntity> execute(String email, String password, String name, String phone) {
    return repository.register(email, password, name, phone);
  }
}
