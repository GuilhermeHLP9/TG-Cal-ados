import 'package:flutter/material.dart';

import 'owner_orders_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

class OwnerHomeShell extends StatefulWidget {
  const OwnerHomeShell({super.key});

  @override
  State<OwnerHomeShell> createState() => _OwnerHomeShellState();
}

class _OwnerHomeShellState extends State<OwnerHomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = const [
      OwnerChatScreen(),
      OwnerOrdersScreen(),
      OwnerSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F4),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        titleSpacing: 12,
        title: const _OwnerHeader(),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: _OwnerBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class OwnerChatScreen extends StatelessWidget {
  const OwnerChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFF0F3F4),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              children: const [
                _IncomingBubble(
                  title: 'Novo pedido recebido',
                  subtitle: 'Cliente enviou uma solicitacao',
                ),
                SizedBox(height: 14),
                _OutgoingBubble(
                  text: 'Vou conferir as informacoes\ne confirmar a producao.',
                ),
                SizedBox(height: 14),
                _IncomingBubble(
                  title: '60%',
                  subtitle: 'Progresso do Pedido',
                ),
              ],
            ),
          ),
        ),
        const _OwnerComposerBar(),
      ],
    );
  }
}

class _IncomingBubble extends StatelessWidget {
  const _IncomingBubble({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 210,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.chatIncomingAccent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutgoingBubble extends StatelessWidget {
  const _OutgoingBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 230),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.chatOutgoing,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _OwnerComposerBar extends StatelessWidget {
  const _OwnerComposerBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Anexar arquivo',
              onPressed: () {},
              icon: const Icon(Icons.attach_file, color: AppColors.primary),
            ),
            IconButton(
              tooltip: 'Enviar imagem',
              onPressed: () {},
              icon: const Icon(Icons.image_outlined, color: AppColors.primary),
            ),
            Expanded(
              child: TextField(
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Mensagem',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFCED7DE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFCED7DE)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              tooltip: 'Enviar mensagem',
              onPressed: () {},
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerHeader extends StatelessWidget {
  const _OwnerHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Painel do fornecedor',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2),
              Text(
                'Gestao da fabrica',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Menu do perfil',
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'profile') {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                builder: (context) => const _OwnerProfileSheet(),
              );
            }

            if (value == 'logout') {
              Navigator.of(context).pop();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 10),
                  Text('Perfil'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 10),
                  Text('Sair'),
                ],
              ),
            ),
          ],
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Icon(Icons.factory_outlined, color: AppColors.primary),
          ),
        ),
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
    const items = [
      (Icons.chat_bubble, 'CHAT'),
      (Icons.assignment_outlined, 'PEDIDOS'),
      (Icons.settings_outlined, 'CONFIGURACOES'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
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
                      color: selected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    item.$1,
                    color: selected ? AppColors.primary : Colors.black87,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class OwnerSettingsScreen extends StatelessWidget {
  const OwnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuracoes',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 18),
            _OwnerInfoLine(label: 'Versao do app', value: '0.1.0 MVP'),
            _OwnerInfoLine(label: 'Tipo de usuario', value: 'Fornecedor'),
            _OwnerInfoLine(label: 'Modulo ativo', value: 'Gestao da fabrica'),
            _OwnerInfoLine(label: 'Plataforma', value: 'Flutter'),
            _OwnerInfoLine(label: 'Ambiente', value: 'Desenvolvimento'),
            _OwnerInfoLine(label: 'API', value: 'Aguardando integracao'),
          ],
        ),
      ),
    );
  }
}

class _OwnerProfileSheet extends StatelessWidget {
  const _OwnerProfileSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.factory_outlined, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Fornecedor',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 4),
                    Text('dono@calcados.com'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _OwnerInfoLine(label: 'Nome exibido', value: 'Pai'),
          const _OwnerInfoLine(label: 'Perfil', value: 'Proprietario'),
          const _OwnerInfoLine(label: 'Empresa', value: 'Fabrica de solados'),
          const _OwnerInfoLine(label: 'Permissoes', value: 'Pedidos e producao'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar perfil'),
          ),
        ],
      ),
    );
  }
}

class _OwnerInfoLine extends StatelessWidget {
  const _OwnerInfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
