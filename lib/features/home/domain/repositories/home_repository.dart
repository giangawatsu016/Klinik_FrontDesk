import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_entity.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<ServiceEntity>>> getServices();
}
