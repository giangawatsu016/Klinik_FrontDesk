import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/features/home/presentation/blocs/home_cubit.dart';
import 'package:app/features/home/domain/usecases/get_services_usecase.dart';
import 'package:app/features/home/domain/entities/service_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/error/failures.dart';

// Mocks
class MockGetServicesUseCase extends Mock implements GetServicesUseCase {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late HomeCubit homeCubit;
  late MockGetServicesUseCase mockGetServicesUseCase;

  setUp(() {
    mockGetServicesUseCase = MockGetServicesUseCase();
    homeCubit = HomeCubit(getServicesUseCase: mockGetServicesUseCase);
  });

  tearDown(() {
    homeCubit.close();
  });

  group('HomeCubit', () {
    test('initial state is HomeInitial', () {
      expect(homeCubit.state, isA<HomeInitial>());
    });

    final List<ServiceEntity> mockServices = [
      const ServiceEntity(
        id: 1,
        name: 'General Checkup',
        description: 'Basic health checkup',
        finalPrice: 100000,
        details: [],
      ),
      const ServiceEntity(
        id: 2,
        name: 'Dental Care',
        description: 'Dental examination',
        finalPrice: 150000,
        details: [],
      ),
    ];

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoading, HomeLoaded] when getServices succeeds',
      build: () {
        when(
          () => mockGetServicesUseCase.execute(),
        ).thenAnswer((_) async => Right(mockServices));
        return homeCubit;
      },
      act: (cubit) => cubit.getServices(),
      expect: () => [isA<HomeLoading>(), isA<HomeLoaded>()],
    );

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoading, HomeError] when getServices fails',
      build: () {
        when(() => mockGetServicesUseCase.execute()).thenAnswer(
          (_) async => const Left(ServerFailure('Failed to load services')),
        );
        return homeCubit;
      },
      act: (cubit) => cubit.getServices(),
      expect: () => [isA<HomeLoading>(), isA<HomeError>()],
    );
  });
}
