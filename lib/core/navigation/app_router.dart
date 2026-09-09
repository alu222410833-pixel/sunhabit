import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sunhabit/features/alarms/presentation/alarm_ringing_screen.dart';
import 'package:sunhabit/features/eve/presentation/eve_profile_screen.dart';
import 'package:sunhabit/features/eye_care/presentation/eye_care_screen.dart';
import 'package:sunhabit/features/focus/presentation/focus_screen.dart';
import 'package:sunhabit/features/habits/presentation/habit_detail_screen.dart';
import 'package:sunhabit/features/habits/presentation/habits_screen.dart';
import 'package:sunhabit/features/home/presentation/home_screen.dart';
import 'package:sunhabit/features/profile/presentation/user_profile_screen.dart';
import 'package:sunhabit/features/rewards/presentation/rewards_screen.dart';
import 'package:sunhabit/features/settings/presentation/settings_screen.dart';
import 'package:sunhabit/features/utilities/presentation/interval_timer_screen.dart';
import 'package:sunhabit/features/utilities/presentation/stopwatch_screen.dart';
import 'package:sunhabit/features/utilities/presentation/utilities_screen.dart';

/// Configuración centralizada de rutas usando [GoRouter].
///
/// Cada feature expone sus rutas agrupadas, evitando que el núcleo
/// conozca los detalles de cada pantalla.
class AppRouter {
  // Llave raíz del navegador para control de diálogos/sheets si es necesario.
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Llave raíz del navegador para acceder al [NavigatorState] global.
  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

  // Rutas principales de la aplicación.
  static const String home = '/';
  static const String alarm = '/alarm';
  static const String habits = '/habits';
  static const String habitDetail = '/habits';
  static const String focus = '/focus';
  static const String eyeCare = '/eye-care';
  static const String utilities = '/utilities';
  static const String stopwatch = '/utilities/stopwatch';
  static const String intervals = '/utilities/intervals';
  static const String profile = '/profile';
  static const String rewards = '/rewards';
  static const String settings = '/settings';
  static const String eve = '/eve';

  /// Instancia global del enrutador.
  ///
  /// Las rutas están organizadas por feature usando sub-rutas anidadas.
  /// Esto permite navegaciones como `/habits/:habitId` o `/utilities/stopwatch`.
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: home,
    routes: [
      _homeRoute,
      _alarmRoute,
      _habitsRoute,
      _focusRoute,
      _eyeCareRoute,
      _utilitiesRoute,
      _profileRoute,
      _rewardsRoute,
      _settingsRoute,
      _eveRoute,
    ],
  );

  // --- Rutas por feature ---------------------------------------------------

  static final GoRoute _homeRoute = GoRoute(
    path: home,
    builder: (context, state) => const HomeScreen(),
  );

  static final GoRoute _alarmRoute = GoRoute(
    path: alarm,
    builder: (context, state) {
      final settings = state.extra as AlarmSettings?;
      return AlarmRingingScreen(alarmSettings: settings);
    },
  );

  static final GoRoute _habitsRoute = GoRoute(
    path: habits,
    builder: (context, state) => const HabitsScreen(),
    routes: [
      GoRoute(
        path: ':habitId',
        builder: (context, state) {
          final habitId = state.pathParameters['habitId'] ?? '';
          return HabitDetailScreen(habitId: habitId);
        },
      ),
    ],
  );

  static final GoRoute _focusRoute = GoRoute(
    path: focus,
    builder: (context, state) => const FocusScreen(),
  );

  static final GoRoute _eyeCareRoute = GoRoute(
    path: eyeCare,
    builder: (context, state) => const EyeCareScreen(),
  );

  static final GoRoute _utilitiesRoute = GoRoute(
    path: utilities,
    builder: (context, state) => const UtilitiesScreen(),
    routes: [
      GoRoute(
        path: 'stopwatch',
        builder: (context, state) => const StopwatchScreen(),
      ),
      GoRoute(
        path: 'intervals',
        builder: (context, state) => const IntervalTimerScreen(),
      ),
    ],
  );

  static final GoRoute _profileRoute = GoRoute(
    path: profile,
    builder: (context, state) => const UserProfileScreen(),
  );

  static final GoRoute _rewardsRoute = GoRoute(
    path: rewards,
    builder: (context, state) => const RewardsScreen(),
  );

  static final GoRoute _settingsRoute = GoRoute(
    path: settings,
    builder: (context, state) => const SettingsScreen(),
  );

  static final GoRoute _eveRoute = GoRoute(
    path: eve,
    builder: (context, state) => const EveProfileScreen(),
  );

  // --- Helpers de navegación -----------------------------------------------

  /// Navega a una ruta reemplazando la pila actual.
  static void goHome(BuildContext context) => context.go(home);

  /// Navega al detalle de un hábito.
  static void goHabitDetail(BuildContext context, String habitId) =>
      context.go('$habits/$habitId');

  /// Navega al perfil de usuario.
  static void goProfile(BuildContext context) => context.go(profile);

  /// Navega al perfil de Eve.
  static void goEve(BuildContext context) => context.go(eve);
}
