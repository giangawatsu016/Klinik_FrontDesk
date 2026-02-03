import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/auth_entity.dart';
import '../../domain/usecases/get_profile_usecase.dart';

// STATES (reused from ProfileBloc)
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserEntity user;
  const ProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

// CUBIT (simplified from Bloc - no Events needed)
class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileUseCase getProfileUseCase;

  ProfileCubit({required this.getProfileUseCase}) : super(ProfileInitial());

  /// Fetch user profile from the repository
  Future<void> getProfile() async {
    emit(ProfileLoading());
    final result = await getProfileUseCase.execute();
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (user) => emit(ProfileLoaded(user)),
    );
  }
}
