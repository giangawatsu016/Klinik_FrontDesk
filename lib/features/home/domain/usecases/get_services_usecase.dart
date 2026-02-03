import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/home_repository.dart';
import '../entities/service_entity.dart';

class GetServicesUseCase {
  final HomeRepository repository;

  GetServicesUseCase(this.repository);

  Future<Either<Failure, List<ServiceEntity>>> execute() {
    return repository.getServices();
  }
}
