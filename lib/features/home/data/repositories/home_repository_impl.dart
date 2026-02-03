import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_formatter.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices() async {
    try {
      final services = await remoteDataSource.getServices();
      return Right(services);
    } catch (e) {
      return Left(ServerFailure(ErrorFormatter.format(e)));
    }
  }
}
