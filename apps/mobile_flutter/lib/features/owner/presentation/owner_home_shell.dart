import 'package:flutter/material.dart';

import 'owner_orders_screen.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_data.dart';
import '../../auth/presentation/logout.dart';
import '../../customers/data/customer_store.dart';
import '../../customers/presentation/customers_screen.dart';
import '../../notes/data/note_store.dart';
import '../../notes/presentation/notes_screen.dart';
import '../../profile/presentation/profile_settings_screen.dart';

class OwnerHomeShell extends StatefulWidget {
  const OwnerHomeShell({
    super.key,
    required this.apiClient,
    required this.token,
    required this.user,
    required this.noteStore,
  });

  final ApiClient apiClient;
  final String token;
  final AuthUser user;
  final NoteStore noteStore;

  @override
  State<OwnerHomeShell> createState() => _OwnerHomeShellState();
}

class _OwnerHomeShellState extends State<OwnerHomeShell> {
  int _currentIndex = 0;
  late AuthUser _user;
  late final CustomerStore _customerStore;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _customerStore = CustomerStore(
      apiClient: widget.apiClient,
      token: widget.token,
    );
  }

  @override
  void dispose() {
    _customerStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      NotesScreen(
        store: widget.noteStore,
        subtitle: 'Registre pendencias da producao, materiais e entregas.',
      ),
      CustomersScreen(store: _customerStore),
      OwnerOrdersScreen(customerStore: _customerStore),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _AppMenuDrawer(
        user: _user,
        onProfile: _openProfile,
        onSettings: _openSettings,
      ),
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        titleSpacing: 12,
        title: _OwnerHeader(
          user: _user,
        ),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: _OwnerBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileSettingsScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          user: _user,
          onUserChanged: (user) => setState(() => _user = user),
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppSettingsScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          user: _user,
          onUserChanged: (user) => setState(() => _user = user),
        ),
      ),
    );
  }
}

class _OwnerHeader extends StatelessWidget {
  const _OwnerHeader({
    required this.user,
  });

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.company?.name ?? 'Painel do fornecedor',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                user.name,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
        _UserAvatar(user: user, owner: true, radius: 22),
      ],
    );
  }
}

class _OwnerBottomNav extends StatelessWidget {
  const _OwnerBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const items = [
      (Icons.edit_note_outlined, 'NOTAS'),
      (Icons.people_alt_outlined, 'CLIENTES'),
      (Icons.assignment_outlined, 'PEDIDOS'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == currentIndex;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 4,
                      width: 58,
                      decoration: BoxDecoration(
                        color: selected ? colors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      item.$1,
                      color: selected ? colors.primary : colors.onSurfaceVariant,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? colors.primary : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _AppMenuDrawer extends StatelessWidget {
  const _AppMenuDrawer({
    required this.user,
    required this.onProfile,
    required this.onSettings,
  });

  final AuthUser user;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _UserAvatar(user: user, owner: true, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.company?.name ?? 'Solex',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              subtitle: const Text('Perfil, empresa e seguranca'),
              onTap: () {
                Navigator.of(context).pop();
                onProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuracoes'),
              subtitle: const Text('Dados, tema, privacidade e sobre'),
              onTap: () {
                Navigator.of(context).pop();
                onSettings();
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.user,
    required this.owner,
    required this.radius,
  });

  final AuthUser user;
  final bool owner;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytesFromDataUrl(user.profileImage);

    if (bytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Icon(
        owner ? Icons.factory_outlined : Icons.person,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
