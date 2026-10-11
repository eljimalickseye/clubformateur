import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_notification_model.dart';
import '../services/app_notification_service.dart';
import '../theme/app_theme.dart';
import 'studio_svg_icon.dart';

class AppNotificationBell extends StatelessWidget {
  final String userId;
  final Function(AppNotificationModel)? onNotificationAction;

  const AppNotificationBell({
    super.key,
    required this.userId,
    this.onNotificationAction,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: AppNotificationService().getUnreadCountStream(userId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: StudioSvgIcon(
                iconKey: unreadCount > 0 ? StudioSvgIcon.sparkles : StudioSvgIcon.bell,
                size: 20,
                color: unreadCount > 0 ? const Color(0xFFEF4444) : AppTheme.ink,
              ),
              tooltip: 'Notifications',
              onPressed: () => AppNotificationDialog.show(
                context,
                userId: userId,
                onAction: onNotificationAction,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AppNotificationDialog extends StatelessWidget {
  final String userId;
  final Function(AppNotificationModel)? onAction;

  const AppNotificationDialog({
    super.key,
    required this.userId,
    this.onAction,
  });

  static void show(
    BuildContext context, {
    required String userId,
    Function(AppNotificationModel)? onAction,
  }) {
    showDialog(
      context: context,
      builder: (_) => AppNotificationDialog(userId: userId, onAction: onAction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifService = AppNotificationService();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 620),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const StudioSvgIcon(iconKey: StudioSvgIcon.sparkles, color: AppTheme.emeraldGreenDark, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Centre de Notifications',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => notifService.markAllAsRead(userId),
                  child: const Text('Tout marquer lu', style: TextStyle(fontSize: 12, color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 16),

            // Notification list
            Expanded(
              child: StreamBuilder<List<AppNotificationModel>>(
                stream: notifService.getUserNotificationsStream(userId),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];

                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const StudioSvgIcon(iconKey: StudioSvgIcon.check, size: 40, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          Text('Aucune notification pour le moment', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final n = list[i];
                      return _buildNotificationTile(context, n, notifService);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, AppNotificationModel n, AppNotificationService service) {
    Color typeColor;
    String typeIcon;
    switch (n.type) {
      case 'live_started':
        typeColor = const Color(0xFFEF4444);
        typeIcon = StudioSvgIcon.video;
        break;
      case 'enrollment':
        typeColor = const Color(0xFF10B981);
        typeIcon = StudioSvgIcon.check;
        break;
      case 'homework_submitted':
      case 'homework_graded':
        typeColor = const Color(0xFFF59E0B);
        typeIcon = StudioSvgIcon.book;
        break;
      default:
        typeColor = const Color(0xFF3B82F6);
        typeIcon = StudioSvgIcon.info;
    }

    final diff = DateTime.now().difference(n.timestamp);
    String timeStr;
    if (diff.inMinutes < 1) {
      timeStr = 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      timeStr = 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      timeStr = 'Il y a ${diff.inHours} h';
    } else {
      timeStr = '${n.timestamp.day}/${n.timestamp.month}';
    }

    return Container(
      color: n.isRead ? Colors.transparent : AppTheme.paleMint.withAlpha(50),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: typeColor.withAlpha(30),
          child: StudioSvgIcon(iconKey: typeIcon, color: typeColor, size: 18),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                n.title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                  fontSize: 13,
                  color: AppTheme.ink,
                ),
              ),
            ),
            Text(timeStr, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(n.message, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
            if (n.type == 'live_started') ...[
              const SizedBox(height: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const StudioSvgIcon(iconKey: StudioSvgIcon.play, size: 12, color: Colors.white),
                label: const Text('🔴 Rejoindre le Live', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  service.markAsRead(userId, n.id);
                  Navigator.pop(context);
                  if (onAction != null) {
                    onAction!(n);
                  }
                },
              ),
            ],
          ],
        ),
        onTap: () {
          service.markAsRead(userId, n.id);
          if (n.type == 'live_started' && onAction != null) {
            Navigator.pop(context);
            onAction!(n);
          }
        },
      ),
    );
  }
}
