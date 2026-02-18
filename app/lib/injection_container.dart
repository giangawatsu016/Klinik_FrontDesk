import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'core/network/dio_client.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/profile/presentation/blocs/profile_cubit.dart';
import 'features/profile/domain/usecases/get_profile_usecase.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/home/presentation/blocs/home_cubit.dart';
import 'features/home/presentation/blocs/search_cubit.dart';
import 'features/home/domain/usecases/get_services_usecase.dart';
import 'features/home/domain/repositories/home_repository.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/data/datasources/home_remote_datasource.dart';

import 'features/appointment/presentation/blocs/appointment_bloc.dart';
import 'features/appointment/presentation/blocs/medical_record_bloc.dart';
import 'features/appointment/domain/usecases/create_appointment_usecase.dart';
import 'features/appointment/domain/usecases/get_doctors_usecase.dart';
import 'features/appointment/domain/usecases/get_appointments_usecase.dart';
import 'features/appointment/domain/usecases/create_invoice_usecase.dart';
import 'features/appointment/domain/usecases/get_availability_usecase.dart';
import 'features/appointment/domain/usecases/simulate_payment_usecase.dart';
import 'features/appointment/domain/usecases/cancel_appointment_usecase.dart';
import 'features/appointment/domain/repositories/appointment_repository.dart';
import 'features/appointment/data/repositories/appointment_repository_impl.dart';
import 'features/appointment/data/datasources/appointment_remote_datasource.dart';
import 'features/payment/presentation/blocs/payment_cubit.dart';
import 'features/payment/data/datasources/payment_remote_datasource.dart';
import 'features/payment/domain/repositories/payment_repository.dart';
import 'features/payment/data/repositories/payment_repository_impl.dart';
import 'features/notification/presentation/blocs/notification_cubit.dart';
import 'features/front_desk/presentation/bloc/front_desk_bloc.dart';
import 'features/front_desk/domain/repositories/front_desk_repository.dart';
import 'features/front_desk/data/repositories/front_desk_repository_impl.dart';
import 'features/front_desk/data/datasources/front_desk_remote_data_source.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => DioClient(sl()));

  // Features - Auth
  sl.registerFactory(() => AuthBloc(loginUseCase: sl(), dioClient: sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  // Features - Home
  sl.registerFactory(() => HomeCubit(getServicesUseCase: sl()));
  sl.registerFactory(() => SearchCubit());
  sl.registerLazySingleton(() => GetServicesUseCase(sl()));
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(sl()));
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(sl()),
  );

  // Features - Profile
  sl.registerFactory(() => ProfileCubit(getProfileUseCase: sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl()),
  );

  // Features - Appointment
  sl.registerFactory(
    () => AppointmentBloc(
      getDoctors: sl(),
      getAvailability: sl(),
      createAppointment: sl(),
      getAppointments: sl(),
      createInvoice: sl(),
      simulatePayment: sl(),
      cancelAppointment: sl(),
    ),
  );
  sl.registerFactory(() => MedicalRecordBloc(repository: sl()));
  sl.registerLazySingleton(() => CreateAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorsUseCase(sl()));
  sl.registerLazySingleton(() => GetAvailabilityUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetAppointmentsUseCase(sl()));
  sl.registerLazySingleton(() => CreateInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => SimulatePaymentUseCase(sl()));
  sl.registerLazySingleton(() => CancelAppointmentUseCase(sl()));
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AppointmentRemoteDataSource>(
    () => AppointmentRemoteDataSourceImpl(client: sl()),
  );

  // Features - Payment
  sl.registerFactory(() => PaymentCubit(repository: sl()));
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(sl()),
  );

  // Features - Notification
  sl.registerFactory(() => NotificationCubit());

  // Features - FrontDesk
  sl.registerFactory(() => FrontDeskBloc(repository: sl()));
  sl.registerLazySingleton<FrontDeskRepository>(
    () => FrontDeskRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<FrontDeskRemoteDataSource>(
    () => FrontDeskRemoteDataSourceImpl(sl()),
  );
}
