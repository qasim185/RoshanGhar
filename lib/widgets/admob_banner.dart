import 'package:flutter/material.dart';

/// AdMob Banner widget - Currently disabled per user configuration.
/// Set to return SizedBox.shrink() so zero ad space or network calls are made.
class AdmobBanner extends StatelessWidget {
  const AdmobBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Ads removed for now
    return const SizedBox.shrink();
  }
}
