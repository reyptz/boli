import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/rides/presentation/providers/ride_provider.dart';
import '../network/websocket_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationState {
  final List<NotificationItem> notifications;
  final NotificationItem? latestNotification;

  NotificationState({this.notifications = const [], this.latestNotification});

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    NotificationItem? latestNotification,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      latestNotification: latestNotification,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final WebSocketService _wsService;

  NotificationNotifier(this._wsService) : super(NotificationState()) {
    _wsService.events.listen((event) {
      _handleIncomingEvent(event);
    });
  }

  void _handleIncomingEvent(Map<String, dynamic> event) {
    final type = event['type'] ?? '';
    String title = 'Notification';
    String message = '';

    if (type == 'NEW_RIDE_AVAILABLE') {
      title = 'Nouvelle course VTC';
      message = 'Une course VTC de ${(event['price'] as num?)?.toDouble() ?? 2500} XOF est disponible.';
    } else if (type == 'DRIVER_ASSIGNED') {
      title = 'Chauffeur Assigné';
      message = 'Un chauffeur a accepté votre course VTC.';
    } else if (type == 'RIDE_STATUS_UPDATED') {
      title = 'Statut Course';
      final status = event['status'];
      if (status == 'going_to_pickup') {
        message = 'Votre chauffeur est en route.';
      } else if (status == 'arrived') {
        message = 'Votre chauffeur est arrivé au point de départ.';
      } else if (status == 'processing') {
        message = 'Votre trajet a commencé.';
      } else if (status == 'completed') {
        message = 'Trajet terminé avec succès. Merci d\'utiliser Boli !';
      } else if (status == 'cancelled') {
        message = 'Votre course VTC a été annulée.';
      }
    } else if (type == 'WALLET_DEPOSIT') {
      title = 'Dépôt Réussi';
      message = 'Votre dépôt de ${(event['amount'] as num?)?.toDouble() ?? 0} XOF a été validé.';
    } else {
      // Ignorer les messages génériques ou non-client
      return;
    }

    addNotification(title, message);
  }

  void addNotification(String title, String message) {
    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      notifications: [newItem, ...state.notifications],
      latestNotification: newItem,
    );
  }

  void markAllAsRead() {
    final updatedList = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updatedList);
  }

  void clearAll() {
    state = NotificationState();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.watch(webSocketServiceProvider));
});
