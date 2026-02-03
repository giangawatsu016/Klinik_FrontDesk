import '../entities/auth_entity.dart';

abstract class AuthRepository {
  Future<AuthEntity> login(String email, String password);
  Future<AuthEntity> register(String email, String password, String name, String phone);
  Future<AuthEntity> googleLogin(String googleToken, String email, String name, String photoUrl);
}
