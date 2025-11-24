// lib/src/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/auth/auth_provider.dart';
import 'package:voley_app/src/screens/coach_athletes_screen.dart';
import 'package:voley_app/src/screens/coach_dashboard_screen.dart';
import 'package:voley_app/src/screens/coach_evaluations_screen.dart';
import 'package:voley_app/src/screens/coach_programs_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentUserAppUserProvider);
    final isLoggingOut = ref.watch(isLoggingOutProvider);
    final theme = Theme.of(context);

    return appUserAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        body: Center(child: Text('Error al cargar perfil: $e')),
      ),
      data: (appUser) {
        if (appUser == null) {
          return const Scaffold(
            body: Center(child: Text('Error al cargar el perfil de usuario.')),
          );
        }

        final pages = const [
          CoachDashboardScreen(),
          CoachAthletesScreen(),
          CoachProgramsScreen(),
          CoachEvaluationsScreen(),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedIndex == 0
                      ? '¡Hola, ${appUser.name}!'
                      : 'Panel de Coach',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _tabSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            toolbarHeight: 70,
            actions: [
              IconButton(
                icon: isLoggingOut
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.logout),
                tooltip: 'Cerrar Sesión',
                onPressed: isLoggingOut ? null : () => _handleLogout(context, ref),
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            onDestinationSelected: _onItemTapped,
            selectedIndex: _selectedIndex,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: 'Atletas',
              ),
              NavigationDestination(
                icon: Icon(Icons.view_module_outlined),
                selectedIcon: Icon(Icons.view_module),
                label: 'Programas',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_turned_in_outlined),
                selectedIcon: Icon(Icons.assignment_turned_in),
                label: 'Evaluaciones',
              ),
            ],
          ),
        );
      },
    );
  }

  String get _tabSubtitle {
    switch (_selectedIndex) {
      case 0:
        return 'Bienvenido a tu panel de control.';
      case 1:
        return 'Gestiona y acompaña a tus atletas';
      case 2:
        return 'Biblioteca y programas asignados';
      case 3:
        return 'Evalúa, agenda y registra resultados';
      default:
        return '';
    }
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    ref.read(isLoggingOutProvider.notifier).state = true;
    try {
      await ref.read(authServiceProvider).logout();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}