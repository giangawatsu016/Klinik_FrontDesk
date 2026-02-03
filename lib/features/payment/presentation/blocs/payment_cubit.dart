import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';

// States
abstract class PaymentState extends Equatable {
  const PaymentState();
  
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentsLoaded extends PaymentState {
  final List<PaymentEntity> payments;
  
  const PaymentsLoaded(this.payments);
  
  @override
  List<Object?> get props => [payments];
}

class PaymentError extends PaymentState {
  final String message;
  
  const PaymentError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Cubit
class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository repository;

  PaymentCubit({required this.repository}) : super(PaymentInitial());

  Future<void> getAllPayments({String? status}) async {
    emit(PaymentLoading());
    try {
      final payments = await repository.getAllPayments(status: status);
      emit(PaymentsLoaded(payments));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> getPaymentHistory(int appointmentId) async {
    emit(PaymentLoading());
    try {
      final payments = await repository.getPaymentHistory(appointmentId);
      emit(PaymentsLoaded(payments));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}
