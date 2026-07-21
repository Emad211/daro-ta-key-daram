import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/medication_inventory/presentation/screens/add_medication_screen.dart';
import '../features/medication_inventory/presentation/screens/archived_medications_screen.dart';
import '../features/medication_inventory/presentation/screens/edit_medication_screen.dart';
import '../features/medication_inventory/presentation/screens/medication_details_screen.dart';
import '../features/medication_inventory/presentation/screens/medication_list_screen.dart';
import '../features/privacy/presentation/privacy_center_screen.dart';

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
        GoRoute(
          path: 'archive',
          name: 'archived-medications',
          builder: (BuildContext context, GoRouterState state) {
            return const ArchivedMedicationsScreen();
          },
        ),
        GoRoute(
          path: 'privacy',
          name: 'privacy-center',
          builder: (BuildContext context, GoRouterState state) {
            return const PrivacyCenterScreen();
          },
        ),
        GoRoute(
          path: 'medications/:medicationId',
          name: 'medication-details',
          builder: (BuildContext context, GoRouterState state) {
            return MedicationDetailsScreen(
              medicationId: state.pathParameters['medicationId'] ?? '',
            );
          },
        ),
        GoRoute(
          path: 'medications/:medicationId/edit',
          name: 'edit-medication',
          builder: (BuildContext context, GoRouterState state) {
            return EditMedicationScreen(
              medicationId: state.pathParameters['medicationId'] ?? '',
            );
          },
        ),
      ],
    ),
  ],
);
