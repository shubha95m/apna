import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class ApnaApp extends ConsumerWidget {
  const ApnaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Apna — Personal & Shared Workspace',
      debugShowCheckedModeBanner: false,
      theme: ApnaTheme.lightTheme,
      routerConfig: router,
    );
  }
}
