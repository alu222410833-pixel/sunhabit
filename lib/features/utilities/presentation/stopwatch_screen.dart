import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sunhabit/core/services/stopwatch_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  final _svc = StopwatchService.instance;

  /// Ticker solo para repintar la UI mientras el cronómetro corre.
  /// El estado real vive en [StopwatchService] y sobrevive a la navegación.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onChanged);
    _syncTicker();
  }

  void _onChanged() {
    if (!mounted) return;
    _syncTicker();
    setState(() {});
  }

  void _syncTicker() {
    if (_svc.isRunning) {
      _ticker ??= Timer.periodic(const Duration(milliseconds: 30), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _svc.removeListener(_onChanged);
    super.dispose();
  }

  String _format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final centiseconds = duration.inMilliseconds.remainder(1000) ~/ 10;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${centiseconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final laps = _svc.laps;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Cronómetro'),
        leading: const BackButton(),
      ),
      body: DecoratedBox(
        decoration: AppDecorations.pageBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundDark,
                    border: Border.all(
                      color: AppColors.neonGreen.withValues(alpha: 0.45),
                      width: 2,
                    ),
                    boxShadow: AppDecorations.neonGlowSoft,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _format(_svc.elapsed),
                    style: textTheme.displayLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 34,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _svc.reset,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reiniciar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _svc.toggle,
                        icon: Icon(
                          _svc.isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          _svc.isRunning ? 'Pausar' : 'Iniciar',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _svc.addLap,
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Registrar vuelta'),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Vueltas', style: textTheme.titleLarge),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: laps.isEmpty
                      ? Center(
                          child: Text(
                            'Todavía no hay vueltas registradas.',
                            style: textTheme.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          itemCount: laps.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: AppDecorations.card,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.neonGlowSoft,
                                  child: Text('${laps.length - index}'),
                                ),
                                title: Text('Vuelta ${laps.length - index}'),
                                trailing: Text(
                                  _format(laps[index]),
                                  style: textTheme.titleMedium,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
