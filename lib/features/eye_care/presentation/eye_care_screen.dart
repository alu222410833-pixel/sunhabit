import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/services/eye_care_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';

class EyeCareScreen extends StatefulWidget {
  const EyeCareScreen({super.key});

  @override
  State<EyeCareScreen> createState() => _EyeCareScreenState();
}

class _EyeCareScreenState extends State<EyeCareScreen> {
  final _svc = EyeCareService.instance;

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
    final phaseTotal = _svc.isWorkPhase
        ? AppConstants.eyeCareWorkSeconds
        : _svc.restSeconds;
    final progress = phaseTotal == 0
        ? 0.0
        : 1 - (_svc.remaining / phaseTotal);
    final accent =
        _svc.isWorkPhase ? AppColors.neonGreen : AppColors.water;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Regla 20-20-20'),
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
                _svc.isWorkPhase
                    ? 'Tiempo de pantalla'
                    : 'Descanso visual',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(color: accent),
              ),
              const SizedBox(height: 8),
              Text(
                _svc.isWorkPhase
                    ? 'Trabaja con normalidad. Te avisaremos cuando sea momento de descansar.'
                    : 'Mira un objeto a 6 metros (20 pies) y parpadea suavemente.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              Center(
                child: SizedBox(
                  width: 230,
                  height: 230,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.surfaceHighest,
                        color: accent,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _svc.isWorkPhase
                                  ? Icons.visibility_outlined
                                  : Icons.remove_red_eye_outlined,
                              color: accent,
                              size: 34,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _format(_svc.remaining),
                              style: textTheme.displayLarge?.copyWith(
                                fontSize: 48,
                              ),
                            ),
                            Text(
                              'Ciclos completados: ${_svc.completedCycles}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                        _svc.running
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(_svc.running ? 'Pausar' : 'Iniciar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                decoration: AppDecorations.card,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Regla 20-20-20', style: textTheme.titleLarge),
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RuleChip(icon: Icons.schedule, label: '20 minutos'),
                        _RuleChip(
                          icon: Icons.landscape_outlined,
                          label: '20 pies / 6 m',
                        ),
                        _RuleChip(
                          icon: Icons.visibility_outlined,
                          label: 'Descanso visual',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Duración del descanso',
                          style: textTheme.titleMedium,
                        ),
                        Text(
                          '${_svc.restSeconds} s',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.neonGreen,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _svc.restSeconds.toDouble(),
                      min: 10,
                      max: 60,
                      divisions: 50,
                      label: '${_svc.restSeconds} segundos',
                      onChanged: _svc.running
                          ? null
                          : (v) => _svc.updateRestSeconds(v.round()),
                    ),
                    Text(
                      _svc.running
                          ? 'Pausa el ciclo para cambiar la duración.'
                          : 'Puedes elegir entre 10 y 60 segundos.',
                      style: textTheme.bodySmall,
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

class _RuleChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RuleChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.neonGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 17),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
