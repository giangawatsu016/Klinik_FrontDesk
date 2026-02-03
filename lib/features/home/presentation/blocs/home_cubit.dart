import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/usecases/get_services_usecase.dart';

// STATES (reused from HomeBloc)
abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<ServiceEntity> services;
  const HomeLoaded(this.services);

  @override
  List<Object?> get props => [services];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// CUBIT (simplified from Bloc - no Events needed)
class HomeCubit extends Cubit<HomeState> {
  final GetServicesUseCase getServicesUseCase;

  HomeCubit({required this.getServicesUseCase}) : super(HomeInitial());

  /// Fetch services from the repository
  Future<void> getServices() async {
    emit(HomeLoading());
    final result = await getServicesUseCase.execute();
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (services) => emit(HomeLoaded(services)),
    );
  }
}
