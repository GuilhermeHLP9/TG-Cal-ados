import 'package:flutter/material.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/services/notification_service.dart';
import '../../client/presentation/client_home_shell.dart';
import '../../notes/data/note_store.dart';
import '../../orders/data/order_store.dart';
import '../../owner/presentation/owner_home_shell.dart';

void openAuthenticatedHome(
  BuildContext context, {
  required ApiClient apiClient,
  required AuthSession session,
}) {
  NotificationService.registerDevice(
    apiClient: apiClient,
    token: session.token,
  );

  final store = OrderStore.api(
    apiClient: apiClient,
    token: session.token,
  );
  final nextPage = session.user.isOwner
      ? OwnerHomeShell(
          apiClient: apiClient,
          token: session.token,
          user: session.user,
          noteStore: NoteStore(
            apiClient: apiClient,
            token: session.token,
          ),
        )
      : ClientHomeShell(
          apiClient: apiClient,
          token: session.token,
          user: session.user,
        );

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => OrderScope(
        store: store,
        child: nextPage,
      ),
    ),
  );
}
