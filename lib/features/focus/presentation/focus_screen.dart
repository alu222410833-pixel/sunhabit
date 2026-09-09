import 'package:flutter/material.dart';
import 'package:sunhabit/core/services/focus_timer_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/shared/widgets/time_input_fields.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final TextEditingController _hoursController = TextEditingController(
    text: '00',
  );
  final TextEditingController _minutesController = TextEditingController(
    text: '25',
  );
  final TextEditingController _secondsController = TextEditingController(
    text: '00',
  );

  final _svc = FocusTimerService.instance;

  int _readInput() {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = (int.tryParse(_minutesController.text) ?? 0).clamp(0, 59);
    final seconds = (int.tryParse(_secondsController.text) ?? 0).clamp(0, 59);
    return hours * 3600 + minutes * 60 + seconds;
  }

  void _applyInput() {
    if (_svc.running) return;
    final value = _readInput();
    _svc.setInput(
      value ~/ 3600,
      (value % 3600) ~/ 60,
      value % 60,
    );
  }

  String _format(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

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
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = _svc.initialSeconds == 0
        ? 0.0
        : 1 - (_svc.remaining / _svc.initialSeconds);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Temporizador'),
        leading: const BackButton(),
      ),
      body: DecoratedBox(
        decoration: AppDecorations.pageBackground,
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Text(
                'Define la duración',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Escribe las horas, minutos y segundos.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              Container(
                decoration: AppDecorations.card,
                padding: const EdgeInsets.all(16),
                child: TimeInputFields(
                  hoursController: _hoursController,
                  minutesController: _minutesController,
                  secondsController: _secondsController,
                  enabled: !_svc.running,
                  onChanged: _applyInput,
                ),
              ),
              const SizedBox(height: 28),
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
                        color: AppColors.neonGreen,
                      ),
                      Center(
                        child: Text(
                          _format(_svc.remaining),
                          style: textTheme.displayLarge?.copyWith(fontSize: 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _svc.running || _svc.remaining > 0
                          ? _svc.reset
                          : null,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reiniciar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_svc.remaining <= 0) {
                          _svc.reset();
                          if (_svc.remaining <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Escribe una duración mayor que cero.'),
                              ),
                            );
                            return;
                          }
                          return;
                        }
                        FocusScope.of(context).unfocus();
                        _svc.toggle();
                      },
                      icon: Icon(
                        _svc.running
                            ? Icons.pause_rounded
                            : _svc.remaining > 0
                                ? Icons.play_arrow_rounded
                                : Icons.stop_rounded,
                      ),
                      label: Text(
                        _svc.running
                            ? 'Pausar'
                            : _svc.remaining > 0
                                ? 'Iniciar'
                                : 'Detener',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
