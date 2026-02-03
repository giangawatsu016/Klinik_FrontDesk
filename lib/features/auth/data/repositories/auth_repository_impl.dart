import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<AuthEntity> login(String email, String password) async {
    return await remoteDataSource.login(email, password);
  }

  @override
  Future<AuthEntity> register(String email, String password, String name, String phone) async {
    return await remoteDataSource.register(email, password, name, phone);
  }

  @override
  Future<AuthEntity> googleLogin(String googleToken, String email, String name, String photoUrl) async {
    return await remoteDataSource.googleLogin(googleToken, email, name, photoUrl);
  }
}
