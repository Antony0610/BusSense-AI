import 'package:flutter/material.dart';
import '../theme/obsidian_theme.dart';

class ObsidianBottomDock extends StatelessWidget {
  final String currentRoute;
  final String role; // 'passenger' or 'authority'
  final Function(String route) onNavigate;

  const ObsidianBottomDock({
    super.key,
    required this.currentRoute,
    required this.role,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPassenger = role != 'authority';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xEE050811),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: isPassenger
              ? ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.3)
              : ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (isPassenger ? ObsidianTransitTheme.cyanGlow : ObsidianTransitTheme.emeraldGreen)
                .withValues(alpha: 0.15),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: isPassenger ? _buildPassengerItems() : _buildAuthorityItems(),
      ),
    );
  }

  List<Widget> _buildPassengerItems() {
    return [
      _buildDockItem(
        icon: Icons.radar,
        label: 'Radar',
        route: '/passenger',
        isActive: currentRoute == '/passenger',
      ),
      _buildDockItem(
        icon: Icons.confirmation_number_outlined,
        label: 'Pass',
        route: '/passenger/ticket',
        isActive: currentRoute == '/passenger/ticket',
      ),
      _buildDockItem(
        icon: Icons.eco,
        label: 'EcoPass',
        route: '/passenger/wallet',
        isActive: currentRoute == '/passenger/wallet',
        activeColor: ObsidianTransitTheme.emeraldGreen,
      ),
      _buildDockItem(
        icon: Icons.tune,
        label: 'Settings',
        route: '/passenger/settings',
        isActive: currentRoute == '/passenger/settings',
      ),
      _buildDockItem(
        icon: Icons.shield,
        label: 'SOS',
        route: '/sos',
        isActive: currentRoute == '/sos',
        isDanger: true,
      ),
    ];
  }

  List<Widget> _buildAuthorityItems() {
    return [
      _buildDockItem(
        icon: Icons.dashboard_outlined,
        label: 'HUD',
        route: '/authority/command',
        isActive: currentRoute == '/authority/command',
        activeColor: ObsidianTransitTheme.emeraldGreen,
      ),
      _buildDockItem(
        icon: Icons.qr_code_scanner,
        label: 'Verify QR',
        route: '/authority/verify',
        isActive: currentRoute == '/authority/verify',
        activeColor: ObsidianTransitTheme.emeraldGreen,
      ),
      _buildDockItem(
        icon: Icons.settings_suggest,
        label: 'Config',
        route: '/authority/settings',
        isActive: currentRoute == '/authority/settings',
        activeColor: ObsidianTransitTheme.emeraldGreen,
      ),
      _buildDockItem(
        icon: Icons.logout,
        label: 'Exit',
        route: '/',
        isActive: false,
        activeColor: Colors.redAccent,
      ),
    ];
  }

  Widget _buildDockItem({
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    bool isDanger = false,
    Color activeColor = ObsidianTransitTheme.cyanGlow,
  }) {
    final Color itemColor = isDanger
        ? (isActive ? ObsidianTransitTheme.crimsonDanger : const Color(0xFFFF6B6B))
        : (isActive ? activeColor : const Color(0xFF94A3B8));

    return InkWell(
      onTap: () => onNavigate(route),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDanger
                  ? ObsidianTransitTheme.crimsonDanger.withValues(alpha: 0.15)
                  : activeColor.withValues(alpha: 0.14))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive
                ? (isDanger
                    ? ObsidianTransitTheme.crimsonDanger.withValues(alpha: 0.4)
                    : activeColor.withValues(alpha: 0.35))
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: itemColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
