import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/domain/entities/user_entity.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/bills/presentation/pages/bills_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/documents/domain/entities/document_entity.dart';
import '../../features/documents/presentation/pages/add_document_page.dart';
import '../../features/documents/presentation/pages/documents_page.dart';
import '../../features/documents/presentation/providers/document_providers.dart';
import '../../features/expenses/presentation/pages/expenses_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../features/warranties/presentation/pages/warranties_page.dart';
import '../../shared/widgets/responsive_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<UserEntity?>(ref.read(authControllerProvider).valueOrNull);
  ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (_, next) {
    authNotifier.value = next.valueOrNull;
  });
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authUser = authNotifier.value;
      final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/register';
      if (authUser == null && !isAuthRoute) {
        return '/login';
      }
      if (authUser != null && isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          int calculateIndex(String path) {
            if (path.startsWith('/documents')) return 1;
            if (path.startsWith('/bills')) return 2;
            if (path.startsWith('/tasks')) return 3;
            if (path.startsWith('/expenses')) return 4;
            if (path.startsWith('/warranty')) return 5;
            if (path.startsWith('/notes')) return 6;
            if (path.startsWith('/calendar')) return 7;
            if (path.startsWith('/health')) return 8;
            if (path.startsWith('/assets')) return 9;
            if (path.startsWith('/grocery')) return 10;
            if (path.startsWith('/contacts')) return 11;
            if (path.startsWith('/memories')) return 12;
            return 0;
          }

          return Consumer(
            builder: (context, ref, _) {
              final workspaceName = ref.watch(activeWorkspaceNameProvider);
              return ApnaResponsiveScaffold(
                selectedIndex: calculateIndex(state.uri.path),
                workspaceName: workspaceName,
                onWorkspaceToggle: () {
                  final workspaces = ref.read(userWorkspacesProvider).valueOrNull ?? [];
                  final active = ref.read(activeWorkspaceProvider);
                  if (active?.isFamily == true) {
                    final personal = workspaces.where((w) => w.isPersonal).firstOrNull;
                    if (personal != null) {
                      ref.read(selectedWorkspaceIdProvider.notifier).state = personal.id;
                    }
                  } else {
                    final family = workspaces.where((w) => w.isFamily).firstOrNull;
                    if (family != null) {
                      ref.read(selectedWorkspaceIdProvider.notifier).state = family.id;
                    }
                  }
                },
                onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
                onDestinationSelected: (index) {
                  if (index < ApnaResponsiveScaffold.destinations.length) {
                    final targetRoute = ApnaResponsiveScaffold.destinations[index].route;
                    context.go(targetRoute);
                  }
                },
                body: child,
              );
            },
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/documents',
            builder: (context, state) {
              final catParam = state.uri.queryParameters['category'];
              DocumentCategory? initialCat;
              if (catParam != null) {
                try {
                  initialCat = DocumentCategory.values.firstWhere(
                    (c) => c.name.toLowerCase() == catParam.toLowerCase(),
                  );
                } catch (_) {}
              }
              return DocumentsPage(initialCategory: initialCat);
            },
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddDocumentPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksPage(),
          ),
          GoRoute(
            path: '/notes',
            builder: (context, state) => _buildPlaceholder(context, 'Notes & Documentation'),
          ),
          GoRoute(
            path: '/bills',
            builder: (context, state) => const BillsPage(),
          ),
          GoRoute(
            path: '/warranty',
            builder: (context, state) => const WarrantiesPage(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpensesPage(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => _buildPlaceholder(context, 'Calendar & Reminders'),
          ),
          GoRoute(
            path: '/health',
            builder: (context, state) => _buildPlaceholder(context, 'Health & Medical Vault'),
          ),
          GoRoute(
            path: '/assets',
            builder: (context, state) => _buildPlaceholder(context, 'Property & Assets Registry'),
          ),
          GoRoute(
            path: '/grocery',
            builder: (context, state) => _buildPlaceholder(context, 'Grocery & Shopping Lists'),
          ),
          GoRoute(
            path: '/contacts',
            builder: (context, state) => _buildPlaceholder(context, 'Important & Emergency Contacts'),
          ),
          GoRoute(
            path: '/memories',
            builder: (context, state) => _buildPlaceholder(context, 'Family Memories & Milestones'),
          ),
        ],
      ),
    ],
  );
});

Widget _buildPlaceholder(BuildContext context, String moduleName) {
  return Scaffold(
    appBar: AppBar(title: Text(moduleName)),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(moduleName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Modular Monolith Architecture Ready • Contract-Driven Integration', style: TextStyle(color: Colors.grey)),
        ],
      ),
    ),
  );
}
