import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/features/front_desk/presentation/bloc/front_desk_bloc.dart';
import 'package:app/features/front_desk/presentation/bloc/front_desk_event.dart';
import 'package:app/features/front_desk/presentation/bloc/front_desk_state.dart';
import 'package:app/features/front_desk/domain/repositories/front_desk_repository.dart';
import 'package:app/features/front_desk/data/models/patient_model.dart';
import 'package:app/features/front_desk/data/models/queue_entry_model.dart';

class MockFrontDeskRepository extends Mock implements FrontDeskRepository {}

void main() {
  late FrontDeskBloc frontDeskBloc;
  late MockFrontDeskRepository mockRepository;

  setUp(() {
    mockRepository = MockFrontDeskRepository();
    frontDeskBloc = FrontDeskBloc(repository: mockRepository);
  });

  registerFallbackValue(
    const PatientModel(
      firstName: '',
      email: '',
      nik: '',
      phone: '',
      birthday: '',
      gender: '',
      religion: '',
      maritalStatus: '',
      education: '',
      province: '',
      city: '',
      district: '',
      subdistrict: '',
      fullAddress: '',
    ),
  );

  registerFallbackValue(
    const QueueEntryModel(
      patient: '',
      patientName: '',
      status: '',
      queueType: '',
    ),
  );

  const tPatientModel = PatientModel(
    firstName: 'John',
    lastName: 'Doe',
    email: 'john@example.com',
    nik: '1234567890123456',
    phone: '08123456789',
    birthday: '1990-01-01',
    gender: 'Male',
    religion: 'Islam',
    maritalStatus: 'Belum Menikah',
    education: 'S1',
    province: 'Jawa Barat',
    city: 'Bandung',
    district: 'Cicendo',
    subdistrict: 'Pasir Kaliki',
    fullAddress: 'Street 1',
  );

  const tQueueEntry = QueueEntryModel(
    patient: 'PAT-001',
    patientName: 'John Doe',
    status: 'Waiting',
    queueType: 'Doctor',
    practitioner: 'PRAC-001',
  );

  group('RegisterAndAddQueueEvent', () {
    blocTest<FrontDeskBloc, FrontDeskState>(
      'should emit [FrontDeskLoading, FrontDeskSuccess] when registration and adding to queue is successful',
      build: () {
        when(() => mockRepository.registerPatient(any())).thenAnswer(
          (_) async => Right(tPatientModel.copyWith(name: 'PAT-001')),
        );
        when(
          () => mockRepository.addToQueue(any()),
        ).thenAnswer((_) async => const Right(tQueueEntry));
        when(() => mockRepository.getQueue()).thenAnswer(
          (_) async => const Right({
            'active': <QueueEntryModel>[],
            'today_completed': 0,
          }),
        );
        return frontDeskBloc;
      },
      act: (bloc) => bloc.add(
        const RegisterAndAddQueueEvent(
          patient: tPatientModel,
          queueType: 'Doctor',
          selectedId: 'PRAC-001',
          isPriority: false,
        ),
      ),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        FrontDeskLoading(),
        const FrontDeskSuccess('Registered and added to queue successfully'),
        FrontDeskLoading(), // triggered by LoadQueueEvent
        const FrontDeskLoaded(activeQueue: []),
      ],
      verify: (_) {
        verify(() => mockRepository.registerPatient(tPatientModel)).called(1);
        verify(() => mockRepository.addToQueue(any())).called(1);
      },
    );
  });
}
