import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<AuthModel> login(String email, String password) async {
    // MOCK LOGIN FOR DEV (Still active for demo@local)
    if (email == 'demo@local' && password == 'demo') {
      await Future.delayed(const Duration(seconds: 1));
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

    // 1. Authenticate (Session Cookie set continuously)
    await client.dio.post(
      ApiEndpoints.login,
      data: {'usr': email, 'pwd': password},
    );

    // 2. Fetch User Context (Company, Role, Full Name)
    final contextResponse = await client.dio.get(ApiEndpoints.getUserContext);
    final contextData = contextResponse.data['message'];

    if (contextData == null) {
      throw Exception('Failed to fetch user context');
    }

    // 3. Construct AuthModel from context
    return AuthModel(
      token: 'session', // Cookie is used for auth
      user: UserModel.fromJson(contextData),
    );
  }
}
