import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/home/explore_screen.dart';
import '../screens/home/clubs_screen.dart';
import '../screens/home/meetups_screen.dart';
import '../screens/home/profile_screen.dart';
import '../screens/club/club_detail_screen.dart';
import '../screens/meetup/meetup_detail_screen.dart';
import '../screens/meetup/create_meetup_screen.dart';
import '../screens/chat/chat_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/explore',
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/explore';
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main app shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExploreScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/clubs',
              builder: (context, state) => const ClubsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => ClubDetailScreen(
                    clubId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/meetups',
              builder: (context, state) => const MeetupsScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const CreateMeetupScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => MeetupDetailScreen(
                    meetupId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // Chat (full-screen overlay)
      GoRoute(
        path: '/chat/:roomId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ChatScreen(
          roomId: state.pathParameters['roomId']!,
          meetupTitle: state.uri.queryParameters['title'] ?? 'Chat',
        ),
      ),
    ],
  );
}
