import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../auth/data/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getProfile();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient client;

  ProfileRemoteDataSourceImpl(this.client);

  @override
  Future<UserModel> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');

    // MOCK DATA FOR DEV
    if (email == 'demo@local') {
      await Future.delayed(const Duration(milliseconds: 500));
      return UserModel(
        id: prefs.getInt('user_id') ?? 123,
        email: email!,
        name: prefs.getString('user_name') ?? 'Demo Admin',
        role: prefs.getString('user_role') ?? 'ADMIN',
        tier: prefs.getString('user_tier') ?? 'PREMIUM',
        staffId: prefs.getString('user_staff_id') ?? 'STF-ADMIN-001',
        photoProfile:
            prefs.getString('user_photo') ?? 'https://i.pravatar.cc/300',
        phone: prefs.getString('user_phone') ?? '081234567890',
        nik: prefs.getString('user_nik') ?? '1234567890123456',
        address: prefs.getString('user_address') ?? 'Jakarta, Indonesia',
      );
    }

    final response = await client.dio.get(ApiEndpoints.profile);
    return UserModel.fromJson(response.data);
  }
}
