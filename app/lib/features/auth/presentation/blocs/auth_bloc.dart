import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/error_formatter.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/usecases/login_usecase.dart';

// EVENTS
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class CheckAuthStatus extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

/// Logout from all devices - invalidates all sessions
class LogoutAllDevicesRequested extends AuthEvent {}

class UserUpdated extends AuthEvent {
  final UserEntity user;
  UserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

// STATES
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final AuthEntity auth;
  AuthAuthenticated(this.auth);

  @override
  List<Object?> get props => [auth];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLOC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final DioClient dioClient;

  AuthBloc({required this.loginUseCase, required this.dioClient})
    : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LogoutRequested>(_onLogoutRequested);
    on<LogoutAllDevicesRequested>(_onLogoutAllDevicesRequested);
    on<UserUpdated>(_onUserUpdated);
  }

  Future<void> _saveAuthData(AuthEntity auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', auth.token);
    await prefs.setInt('user_id', auth.user.id);
    await prefs.setString('user_email', auth.user.email);
    await prefs.setString('user_name', auth.user.name);
    await prefs.setString('user_role', auth.user.role);
    await prefs.setString('user_tier', auth.user.tier);
    if (auth.user.photoProfile != null) {
      await prefs.setString('user_photo', auth.user.photoProfile!);
    }
    if (auth.user.phone != null) {
      await prefs.setString('user_phone', auth.user.phone!);
    }
    if (auth.user.address != null) {
      await prefs.setString('user_address', auth.user.address!);
    }
    if (auth.user.nik != null) {
      await prefs.setString('user_nik', auth.user.nik!);
    }
    if (auth.user.locationNote != null) {
      await prefs.setString('user_location_note', auth.user.locationNote!);
    }
    if (auth.user.staffId != null) {
      await prefs.setString('user_staff_id', auth.user.staffId!);
    }
    if (auth.user.company != null) {
      await prefs.setString('user_company', auth.user.company!);
    }
    if (auth.user.facility != null) {
      await prefs.setString('user_facility', auth.user.facility!);
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        final user = UserEntity(
          id: prefs.getInt('user_id') ?? 0,
          email: prefs.getString('user_email') ?? '',
          name: prefs.getString('user_name') ?? '',
          role: prefs.getString('user_role') ?? '',
          tier: prefs.getString('user_tier') ?? 'basic',
          photoProfile: prefs.getString('user_photo'),
          phone: prefs.getString('user_phone'),
          address: prefs.getString('user_address'),
          nik: prefs.getString('user_nik'),
          locationNote: prefs.getString('user_location_note'),
          staffId: prefs.getString('user_staff_id'),
          company: prefs.getString('user_company'),
          facility: prefs.getString('user_facility'),
        );
        final auth = AuthEntity(token: token, user: user);
        dioClient.setToken(token);
        emit(AuthAuthenticated(auth));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    dioClient.clearToken();
    emit(AuthUnauthenticated());
  }

  /// Logout from all devices - calls backend to invalidate all sessions
  Future<void> _onLogoutAllDevicesRequested(
    LogoutAllDevicesRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Call backend API to invalidate all sessions (mock for now)
      // await dioClient.dio.post('/method/frappe.sessions.clear_all_sessions');

      // For now, just do regular logout
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      dioClient.clearToken();
      emit(AuthUnauthenticated());
    } catch (e) {
      // Still logout locally even if API fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      dioClient.clearToken();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await loginUseCase.execute(event.email, event.password);
      dioClient.setToken(result.token);
      await _saveAuthData(result);
      emit(AuthAuthenticated(result));
    } catch (e) {
      emit(AuthError(ErrorFormatter.format(e)));
    }
  }

  Future<void> _onUserUpdated(
    UserUpdated event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      final updatedAuth = AuthEntity(
        token: currentState.auth.token,
        user: event.user,
      );

      // Update persistent storage
      await _saveAuthData(updatedAuth);

      // Emit new state with updated user
      emit(AuthAuthenticated(updatedAuth));
    }
  }
}
