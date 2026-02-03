import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/features/appointment/presentation/blocs/medical_record_bloc.dart';
import 'package:app/features/appointment/domain/repositories/appointment_repository.dart';
import 'package:app/features/appointment/domain/entities/appointment_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/error/failures.dart';

// Mocks
class MockAppointmentRepository extends Mock implements AppointmentRepository {}

void main() {
  late MedicalRecordBloc medicalRecordBloc;
  late MockAppointmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAppointmentRepository();
    medicalRecordBloc = MedicalRecordBloc(repository: mockRepository);
  });

  tearDown(() {
    medicalRecordBloc.close();
  });

  group('MedicalRecordBloc', () {
    test('initial state is MedicalRecordInitial', () {
      expect(medicalRecordBloc.state, isA<MedicalRecordInitial>());
    });

    final mockRecords = [
      AppointmentEntity(
        id: 1,
        date: DateTime(2024, 1, 15),
        status: 'COMPLETED',
        serviceName: 'General Checkup',
        doctorName: 'Dr. Smith',
        doctorTitlePrefix: 'dr.',
        finalPrice: 100000,
        paymentStatus: 'PAID',
        patientDetail: {'fullname': 'John Doe'},
        serviceId: 1,
        doctorId: 1,
      ),
    ];

    blocTest<MedicalRecordBloc, MedicalRecordState>(
      'emits [MedicalRecordLoading, MedicalRecordLoaded] when fetch succeeds',
      build: () {
        when(
          () => mockRepository.getMedicalRecords(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
          ),
        ).thenAnswer(
          (_) async => Right({
            'data': mockRecords,
            'meta': {'total': 1},
          }),
        );
        return medicalRecordBloc;
      },
      act: (bloc) => bloc.add(GetMedicalRecordsRequested()),
      expect: () => [isA<MedicalRecordLoading>(), isA<MedicalRecordLoaded>()],
    );

    blocTest<MedicalRecordBloc, MedicalRecordState>(
      'emits [MedicalRecordLoading, MedicalRecordError] when fetch fails',
      build: () {
        when(
          () => mockRepository.getMedicalRecords(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure('Failed to load records')),
        );
        return medicalRecordBloc;
      },
      act: (bloc) => bloc.add(GetMedicalRecordsRequested()),
      expect: () => [isA<MedicalRecordLoading>(), isA<MedicalRecordError>()],
    );
  });
}
