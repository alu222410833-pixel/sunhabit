import 'package:flutter/material.dart';
import 'package:sunhabit/shared/widgets/placeholder_widget.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recompensas')),
      body: const PlaceholderWidget(text: 'Sistema de recompensas'),
    );
  }
}
