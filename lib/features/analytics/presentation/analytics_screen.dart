import 'package:flutter/material.dart';
import 'package:sunhabit/shared/widgets/placeholder_widget.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis')),
      body: const PlaceholderWidget(text: 'Seguimiento de hábitos'),
    );
  }
}
