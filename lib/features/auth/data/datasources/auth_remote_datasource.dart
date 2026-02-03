import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> login(String email, String password);
  Future<AuthModel> register(
    String email,
    String password,
    String name,
    String phone,
  );
  Future<AuthModel> googleLogin(
    String googleToken,
    String email,
    String name,
    String photoUrl,
  );
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<AuthModel> login(String email, String password) async {
    // MOCK LOGIN FOR DEV
    if (email == 'demo@local' && password == 'demo') {
      await Future.delayed(const Duration(seconds: 1)); // Simulate latency
      return const AuthModel(
        token: 'mock-token-12345',
        user: UserModel(
          id: 123,
          email: 'demo@local',
          name: 'Demo Admin',
          role: 'ADMIN',
          tier: 'PREMIUM',
          photoProfile: 'https://i.pravatar.cc/300',
          phone: '081234567890',
          nik: '1234567890123456',
          address: 'Jakarta, Indonesia',
        ),
      );
    }

    final response = await client.dio.post(
      ApiEndpoints.login,
      data: {'usr': email, 'pwd': password},
    );
    return AuthModel.fromJson(response.data);
  }

  @override
  Future<AuthModel> register(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    final response = await client.dio.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
      },
    );
    return AuthModel.fromJson(response.data);
  }

  @override
  Future<AuthModel> googleLogin(
    String googleToken,
    String email,
    String name,
    String photoUrl,
  ) async {
    final response = await client.dio.post(
      ApiEndpoints.googleLogin,
      data: {
        'googleToken': googleToken,
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
      },
    );
    return AuthModel.fromJson(response.data);
  }
}
