import 'package:flutter/material.dart';

class PosTopHeader extends StatelessWidget {
  const PosTopHeader({
    super.key,
    required this.left,
    this.center,
    this.onNotificationsTap,
    this.onMenuTap,
    this.userName,
    this.statusLabel,
    this.showNotificationBadge = true,
    this.showStatusIndicator = false,
  });

  final Widget left;
  final Widget? center;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onMenuTap;
  final String? userName;
  final String? statusLabel;
  final bool showNotificationBadge;
  final bool showStatusIndicator;

  @override
  Widget build(BuildContext context) {
    final displayUser = (userName ?? '').trim().isEmpty ? 'Usuario' : userName!;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(flex: 6, child: Align(alignment: Alignment.centerLeft, child: left)),
          Expanded(
            flex: 3,
            child: Center(
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w600,
                ),
                child: center ?? const SizedBox.shrink(),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      IconButton(
                        onPressed: onNotificationsTap ?? () {},
                        icon: const Icon(Icons.notifications_none, color: Color(0xFF4B5563)),
                        tooltip: 'Notificaciones',
                      ),
                      if (showNotificationBadge)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    onPressed: onMenuTap ?? () {},
                    icon: const Icon(Icons.menu, color: Color(0xFF4B5563)),
                    tooltip: 'Menú',
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Color(0xFF4B5563)),
                        const SizedBox(width: 8),
                        Text(
                          displayUser,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if ((statusLabel ?? '').trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            statusLabel!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (showStatusIndicator) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
