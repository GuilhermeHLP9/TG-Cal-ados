import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/app/app_widget.dart';
import 'package:mobile_flutter/core/services/api_client.dart';
import 'package:mobile_flutter/features/auth/presentation/register_screen.dart';
import 'package:mobile_flutter/features/client/presentation/client_home_shell.dart';
import 'package:mobile_flutter/features/owner/presentation/owner_home_shell.dart';
import 'package:mobile_flutter/features/notes/data/note_store.dart';
import 'package:mobile_flutter/features/orders/data/order_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('login screen is rendered', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SolexApp());
    await tester.pumpAndSettle();

    expect(find.text('Solex'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta de cliente'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(find.text('Use dono@calcados.com / 123456 para o proprietario.'),
        findsNothing);
    expect(find.text('Use cliente@calcados.com / 123456 para cliente.'),
        findsNothing);
  });

  testWidgets('register screen only creates client accounts', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(apiClient: ApiClient()),
      ),
    );

    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Tipo de acesso'), findsNothing);
    expect(find.text('Proprietario'), findsNothing);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('client shell exposes orders and menu settings', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderScope(
          store: OrderStore.demo(),
          child: ClientHomeShell(
            apiClient: ApiClient(),
            token: 'token',
            user: const AuthUser(
              id: 'client',
              name: 'Cliente Teste',
              email: 'cliente@calcados.com',
              role: 'CLIENT',
            ),
          ),
        ),
      ),
    );

    expect(find.text('PEDIDOS'), findsOneWidget);
    expect(find.text('CONFIGURACOES'), findsNothing);
    expect(find.text('NOTAS'), findsNothing);
    expect(find.text('CLIENTES'), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Configuracoes'), findsOneWidget);
  });

  testWidgets('owner shell exposes notes customers orders and menu settings',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderScope(
          store: OrderStore.demo(),
          child: OwnerHomeShell(
            apiClient: ApiClient(),
            token: 'token',
            user: const AuthUser(
              id: 'owner',
              name: 'Dono Teste',
              email: 'dono@calcados.com',
              role: 'OWNER',
            ),
            noteStore: NoteStore.demo(),
          ),
        ),
      ),
    );

    expect(find.text('NOTAS'), findsOneWidget);
    expect(find.text('CLIENTES'), findsOneWidget);
    expect(find.text('PEDIDOS'), findsOneWidget);
    expect(find.text('CONFIGURACOES'), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Configuracoes'), findsOneWidget);
  });
}
