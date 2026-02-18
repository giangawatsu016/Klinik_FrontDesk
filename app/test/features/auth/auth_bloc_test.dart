import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:app/features/auth/domain/usecases/login_usecase.dart';
import 'package:app/features/auth/domain/entities/auth_entity.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mocks
class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockDioClient extends Mock implements DioClient {}

void main() {
  // Initialize binding for SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockDioClient mockDioClient;

  setUpAll(() async {
    // Mock SharedPreferences for all tests
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockDioClient = MockDioClient();

    // Stub DioClient methods
    when(() => mockDioClient.setToken(any())).thenAnswer((_) {});
    when(() => mockDioClient.clearToken()).thenAnswer((_) {});

    authBloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      dioClient: mockDioClient,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        when(() => mockLoginUseCase.execute(any(), any())).thenAnswer(
          (_) async => AuthEntity(
            token: 'test-token',
            user: UserEntity(
              id: 1,
              email: 'test@test.com',
              name: 'Test User',
              role: 'patient',
              tier: 'care',
            ),
          ),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(LoginRequested('test@test.com', 'password123')),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
      verify: (_) {
        verify(
          () => mockLoginUseCase.execute('test@test.com', 'password123'),
        ).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(
          () => mockLoginUseCase.execute(any(), any()),
        ).thenThrow(Exception('Invalid credentials'));
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(LoginRequested('wrong@test.com', 'wrongpassword')),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );
    group('Logout', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when LogoutRequested',
        build: () => authBloc,
        act: (bloc) => bloc.add(LogoutRequested()),
        expect: () => [isA<AuthUnauthenticated>()],
      );
    });
  });
}
