import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'features/auth/state/auth_controller.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        // Wire the API client's 401 hook to sign the user out.
        onUnauthorizedProvider.overrideWith(
          (ref) => () => ref.read(authControllerProvider.notifier).logout(),
        ),
      ],
      child: const TeacherTrackerApp(),
    ),
  );
}
