import 'package:flutter/material.dart';
import 'package:sunhabit/core/services/interval_timer_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';

class IntervalTimerScreen extends StatefulWidget {
  const IntervalTimerScreen({super.key});

  @override
  State<IntervalTimerScreen> createState() => _IntervalTimerScreenState();
}

class _IntervalTimerScreenState extends State<IntervalTimerScreen> {
  final _svc = IntervalTimerService.instance;

  @override
  void initState() {
    super.initState();
    _svc.syncFromWallClock();
    _svc.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _svc.removeListener(_onChanged);
    super.dispose();
  }

  String _format(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final phaseTotal = _svc.isWork ? _svc.workSeconds : _svc.restSeconds;
    final progress = phaseTotal == 0 ? 0.0 : 1 - (_svc.remaining / phaseTotal);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Intervalos'),
        leading: const BackButton(),
      ),
      body: DecoratedBox(
        decoration: AppDecorations.pageBackground,
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Text(
                _svc.finished
                    ? 'Entrenamiento completado'
                    : _svc.isWork
                    ? 'Tiempo de actividad'
                    : 'Tiempo de descanso',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: _svc.isWork ? AppColors.neonGreen : AppColors.water,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ronda ${_svc.currentRound} de ${_svc.rounds}',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.surfaceHighest,
                        color: _svc.isWork ? AppColors.neonGreen : AppColors.water,
                      ),
                      Center(
                        child: Text(
                          _format(_svc.remaining),
                          style: textTheme.displayLarge?.copyWith(fontSize: 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _svc.running || !_svc.finished
                          ? _svc.reset
                          : null,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reiniciar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _svc.toggle,
                      icon: Icon(
                        _svc.running
                            ? Icons.pause_rounded
                            : _svc.finished
                                ? Icons.replay_rounded
                                : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        _svc.running
                            ? 'Pausar'
                            : _svc.finished
                                ? 'Reiniciar'
                                : 'Iniciar',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: AppDecorations.card,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _IntervalSetting(
                      label: 'Actividad',
                      valueLabel: '${_svc.workSeconds} s',
                      value: _svc.workSeconds.toDouble(),
                      min: 10,
                      max: 300,
                      divisions: 29,
                      enabled: !_svc.running,
                      onChanged: (v) => _svc.updateWork(v.round()),
                    ),
                    const Divider(height: 24),
                    _IntervalSetting(
                      label: 'Descanso',
                      valueLabel: '${_svc.restSeconds} s',
                      value: _svc.restSeconds.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      enabled: !_svc.running,
                      onChanged: (v) => _svc.updateRest(v.round()),
                    ),
                    const Divider(height: 24),
                    _IntervalSetting(
                      label: 'Rondas',
                      valueLabel: '${_svc.rounds}',
                      value: _svc.rounds.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      enabled: !_svc.running,
                      onChanged: (v) => _svc.updateRounds(v.round()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntervalSetting extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _IntervalSetting({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: textTheme.titleMedium),
            Text(
              valueLabel,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.neonGreen,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
