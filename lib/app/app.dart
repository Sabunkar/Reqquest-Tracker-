import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/requests/domain/repositories/request_repository.dart';
import '../features/requests/presentation/cubit/request_list_cubit.dart';
import '../features/settings/domain/repositories/settings_repository.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../features/settings/presentation/cubit/settings_state.dart';
import '../injection/dependency_injection.dart';
import 'constants/app_constants.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class RequestFlowApp extends StatelessWidget {
  const RequestFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(
          create: (_) =>
              SettingsCubit(sl<SettingsRepository>())..loadSettings(),
        ),
        BlocProvider<AuthCubit>(
          create: (ctx) => AuthCubit(
            repository: sl<AuthRepository>(),
            settingsCubit: ctx.read<SettingsCubit>(),
          ),
        ),
        BlocProvider<RequestListCubit>(
          create: (_) => RequestListCubit(sl<RequestRepository>()),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
