import 'package:dartz/dartz.dart';
import '../../data/datasources/google_auth_datasource.dart';
import '../repositories/auth_repository.dart';
import '../entities/auth_entity.dart';

class GoogleLoginUseCase {
  final GoogleAuthDataSource _googleAuthDataSource;
  final AuthRepository _authRepository;

  GoogleLoginUseCase(this._googleAuthDataSource, this._authRepository);

  Future<Either<String, AuthEntity>> execute() async {
    try {
      final googleUser = await _googleAuthDataSource.signIn();

      if (googleUser == null) {
        return const Left('Google Sign-In was cancelled');
      }

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return const Left('Failed to get Google ID Token');
      }

      // Call backend to verify token and get user/jwt
      final authEntity = await _authRepository.googleLogin(
        idToken,
        googleUser.email,
        googleUser.displayName ?? 'Google User',
        googleUser.photoUrl ?? '',
      );

      return Right(authEntity);
    } catch (e) {
      return Left('Google Sign-In failed: ${e.toString()}');
    }
  }
}
