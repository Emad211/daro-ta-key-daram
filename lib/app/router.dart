import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/medication_inventory/presentation/screens/add_medication_screen.dart';
import '../features/medication_inventory/presentation/screens/medication_list_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'medications',
      builder: (BuildContext context, GoRouterState state) {
        return const MedicationListScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'add',
          name: 'add-medication',
          builder: (BuildContext context, GoRouterState state) {
            return const AddMedicationScreen();
          },
        ),
      ],
    ),
  ],
);
