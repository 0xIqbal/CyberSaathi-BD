import 'package:flutter/material.dart';

import '../core/network/api_service.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import 'router.dart';

class CyberSaathiApp extends StatefulWidget {
  const CyberSaathiApp({super.key});

  @override
  State<CyberSaathiApp> createState() => _CyberSaathiAppState();
}

class _CyberSaathiAppState extends State<CyberSaathiApp> {
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel(
      AuthRepository(ApiService()),
    )..restoreSession();
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyberSaathi BD',
      theme: AppRouter.theme,
      debugShowCheckedModeBanner: false,
      home: AppRouter.buildHome(_authViewModel),
    );
  }
}
