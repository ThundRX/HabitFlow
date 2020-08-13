import 'package:flutter/material.dart';

import 'package:habitflow/resources/icons.dart';

/// Widget to indicate something to user such as no habits, rewards, or active habits.
class NoPossesion extends StatelessWidget {
  /// Constructs.
  const NoPossesion({
    @required this.text,
    this.icon = addIcon,
  });

  /// Icon to show.
  final IconData icon;

  /// Text to show.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.6,
        child: Column(
          children: [
            Icon(
              icon,
              size: 96,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                text,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
