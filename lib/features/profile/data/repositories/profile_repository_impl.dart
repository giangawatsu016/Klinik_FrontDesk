import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_formatter.dart';
import '../../../auth/domain/entities/auth_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> getProfile() async {
    try {
      final user = await remoteDataSource.getProfile();
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(ErrorFormatter.format(e)));
    }
  }
}
