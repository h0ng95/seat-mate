import 'package:go_router/go_router.dart';

import '../features/classroom/presentation/classroom_page.dart';
import '../features/classroom/presentation/create_classroom_page.dart';
import '../features/classroom/presentation/my_classrooms_page.dart';
import '../features/landing/presentation/landing_page.dart';
import '../features/sharing/domain/classroom_share_link.dart';
import '../shared/presentation/not_found_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => sharedClassroomPath(state.uri),
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/create',
      builder: (context, state) => const CreateClassroomPage(),
    ),
    GoRoute(path: '/my', builder: (context, state) => const MyClassroomsPage()),
    GoRoute(
      path: '/class/:shareCode',
      builder: (context, state) =>
          ClassroomPage(shareCode: state.pathParameters['shareCode'] ?? ''),
    ),
  ],
  errorBuilder: (context, state) => NotFoundPage(location: state.uri.path),
);
