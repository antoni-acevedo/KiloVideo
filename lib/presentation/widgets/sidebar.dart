import 'package:flutter/material.dart';

/// Item del sidebar de navegación.
class SidebarItem {
  /// Crea un item.
  const SidebarItem({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  /// Identificador único.
  final String id;

  /// Etiqueta principal.
  final String label;

  /// Subtítulo descriptivo.
  final String subtitle;

  /// Icono.
  final IconData icon;
}

/// Lista de items del sidebar.
const List<SidebarItem> sidebarItems = [
  SidebarItem(
    id: 'fixed',
    label: 'Tamaño fijo',
    subtitle: 'Tamaño exacto en MB',
    icon: Icons.crop,
  ),
  SidebarItem(
    id: 'percent',
    label: 'Porcentaje',
    subtitle: 'Porcentaje del bitrate',
    icon: Icons.percent,
  ),
  SidebarItem(
    id: 'quality',
    label: 'Calidad',
    subtitle: 'CRF (calidad fija)',
    icon: Icons.auto_awesome,
  ),
  SidebarItem(
    id: 'about',
    label: 'Acerca de',
    subtitle: 'Información de KiloVideo',
    icon: Icons.info_outline,
  ),
];

/// Sidebar de navegación lateral.
///
/// **Patrón:** Stateless Widget (presentación).
class Sidebar extends StatelessWidget {
  /// Crea el sidebar.
  const Sidebar({
    super.key,
    required this.selectedId,
    required this.onItemSelected,
    required this.onThemeToggle,
  });

  /// Id del item seleccionado.
  final String selectedId;

  /// Callback al seleccionar un item.
  final ValueChanged<String> onItemSelected;

  /// Callback al togglear tema.
  final VoidCallback onThemeToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 250,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          ...sidebarItems.map(
            (item) => _buildItem(item, theme),
          ),
          const Spacer(),
          _buildProCard(theme),
          const SizedBox(height: 8),
          _buildThemeToggle(theme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onThemeToggle,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  isDark ? 'Modo claro' : 'Modo oscuro',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.video_settings,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KiloVideo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Video Compressor',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(SidebarItem item, ThemeData theme) {
    final selected = selectedId == item.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => onItemSelected(item.id),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? theme.colorScheme.onPrimaryContainer
                              : null,
                        ),
                      ),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Donar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Apoya el proyecto',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}