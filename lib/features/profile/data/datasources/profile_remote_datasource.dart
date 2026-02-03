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
    final response = await client.dio.get(ApiEndpoints.profile);
    return UserModel.fromJson(response.data);
  }
}
