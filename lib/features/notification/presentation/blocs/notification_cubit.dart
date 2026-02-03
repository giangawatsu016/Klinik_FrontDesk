import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/error_formatter.dart';
import '../../../../injection_container.dart';

// Entity
class NotificationEntity {
  final int id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

// State
abstract class NotificationState {}

class NotificationInitial extends NotificationState {}
class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final int page;
  final int totalPages;
  final bool hasMore;
  final bool isLoadingMore;

  NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
    required this.page,
    required this.totalPages,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  NotificationLoaded copyWith({
    List<NotificationEntity>? notifications,
    int? unreadCount,
    int? page,
    int? totalPages,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);
}

// Cubit
class NotificationCubit extends Cubit<NotificationState> {
  final DioClient _dioClient = sl<DioClient>();

  NotificationCubit() : super(NotificationInitial());

  Future<void> getNotifications({bool refresh = false}) async {
    try {
      if (refresh || state is NotificationInitial || state is NotificationError) {
        emit(NotificationLoading());
      }

      final response = await _dioClient.dio.get('/notifications', queryParameters: {
        'page': 1,
        'limit': 50,
      });

      final data = response.data;
      final notifications = (data['notifications'] as List)
          .map((json) => NotificationEntity.fromJson(json))
          .toList();

      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: data['unreadCount'] ?? 0,
        page: data['pagination']?['page'] ?? 1,
        totalPages: data['pagination']?['totalPages'] ?? 1,
        hasMore: data['pagination']?['hasMore'] ?? false,
      ));
    } catch (e) {
      if (kDebugMode) print('[NotificationCubit] Error: $e');
      emit(NotificationError(ErrorFormatter.format(e)));
    }
  }

  Future<void> loadMore() async {
    if (state is! NotificationLoaded) return;
    final currentState = state as NotificationLoaded;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    try {
      emit(currentState.copyWith(isLoadingMore: true));

      final nextPage = currentState.page + 1;
      final response = await _dioClient.dio.get('/notifications', queryParameters: {
        'page': nextPage,
        'limit': 50,
      });

      final data = response.data;
      final newNotifications = (data['notifications'] as List)
          .map((json) => NotificationEntity.fromJson(json))
          .toList();

      emit(NotificationLoaded(
        notifications: [...currentState.notifications, ...newNotifications],
        unreadCount: data['unreadCount'] ?? 0,
        page: nextPage,
        totalPages: data['pagination']?['totalPages'] ?? 1,
        hasMore: data['pagination']?['hasMore'] ?? false,
      ));
    } catch (e) {
      if (kDebugMode) print('[NotificationCubit] LoadMore Error: $e');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _dioClient.dio.patch('/notifications/$notificationId/read');
      
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        final updatedList = currentState.notifications.map((n) {
          if (n.id == notificationId) {
            return NotificationEntity(
              id: n.id,
              type: n.type,
              title: n.title,
              message: n.message,
              data: n.data,
              isRead: true,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList();

        emit(currentState.copyWith(
          notifications: updatedList,
          unreadCount: (currentState.unreadCount - 1).clamp(0, 999),
        ));
      }
    } catch (e) {
      if (kDebugMode) print('[NotificationCubit] MarkAsRead Error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dioClient.dio.patch('/notifications/read-all');
      
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        final updatedList = currentState.notifications.map((n) {
          return NotificationEntity(
            id: n.id,
            type: n.type,
            title: n.title,
            message: n.message,
            data: n.data,
            isRead: true,
            createdAt: n.createdAt,
          );
        }).toList();

        emit(currentState.copyWith(
          notifications: updatedList,
          unreadCount: 0,
        ));
      }
    } catch (e) {
      if (kDebugMode) print('[NotificationCubit] MarkAllAsRead Error: $e');
    }
  }

  int get unreadCount {
    if (state is NotificationLoaded) {
      return (state as NotificationLoaded).unreadCount;
    }
    return 0;
  }
}
