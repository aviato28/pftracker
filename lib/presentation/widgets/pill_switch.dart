import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A pill-style toggle matching the design mockups — the default Material
/// [Switch] reads as dated against the rest of this app's look.
class PillSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PillSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 42,
        height: 25,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: value ? AppColors.accent : AppColors.toggleOffTrack,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.onAccent : AppColors.toggleOffKnob,
            ),
          ),
        ),
      ),
    );
  }
}
