import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Branded splash screen shown briefly on app startup while the session
/// state (signed in / signed out) is being resolved, before routing to
/// either the login screen or the dashboard.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/logo.png',
                width: 136,
                height: 136,
                fit: BoxFit.contain,
                semanticLabel: 'Sales CRM logo',
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
