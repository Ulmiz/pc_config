import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/heuristic_builder_service.dart';
import '../providers/build_state_provider.dart';
import '../providers/isar_provider.dart';
import '../../data/services/voice_service.dart';
import '../widgets/ai_terminal_input.dart';
import '../widgets/status_bar.dart';
import 'build_screen.dart';

class PromptScreen extends ConsumerStatefulWidget {
  const PromptScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends ConsumerState<PromptScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  bool _isListening = false;

  final List<String> _suggestions = [
    'PC GAMING 20000 PESOS',
    'ESTACIÓN PARA DISEÑO',
    'PC ECONÓMICA',
    'PC GAMING 4K',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    final voiceService = ref.read(voiceServiceProvider);

    if (_isListening) {
      await voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      final initialized = await voiceService.initialize();
      if (!initialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo inicializar el micrófono o faltan permisos.')),
          );
        }
        return;
      }

      setState(() => _isListening = true);
      await voiceService.startListening(
        onResult: (text) {
          setState(() => _promptController.text = text);
        },
        onDone: () {
          setState(() => _isListening = false);
          if (_promptController.text.isNotEmpty) {
            _submitPrompt();
          }
        },
      );
    }
  }

  Future<void> _submitPrompt([String? text]) async {
    final finalText = text ?? _promptController.text;
    if (finalText.isEmpty || _isGenerating) return;

    if (_isListening) {
      await ref.read(voiceServiceProvider).stopListening();
      setState(() => _isListening = false);
    }

    setState(() => _isGenerating = true);
    
    try {
      final heuristicService = ref.read(heuristicBuilderServiceProvider);
      final partIds = await heuristicService.generateConfigFromPrompt(finalText);
      
      if (partIds.isNotEmpty) {
        final isar = ref.read(isarProvider);
        await ref.read(buildStateProvider.notifier).loadFromPartIds(partIds, isar);
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BuildScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron componentes compatibles.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Widget _buildReadyScreen() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const Icon(
                Icons.laptop_mac,
                size: 64,
                color: Colors.white70,
              ),
              const SizedBox(height: 16),
              // Title with Glow
              Text(
                'PC Config',
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Terminal Input
              if (_isGenerating)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              else
                AiTerminalInput(
                  controller: _promptController,
                  backgroundColor: AppColors.promptSurface,
                  borderColor: AppColors.promptBorder,
                  onSubmitted: _submitPrompt,
                  isListening: _isListening,
                  onVoicePressed: _toggleVoice,
                ),
              const SizedBox(height: 32),

              // Suggestions Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SUGERENCIAS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Suggestion Chips
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions.map((suggestion) {
                    return OutlinedButton(
                      onPressed: () {
                        _promptController.text = suggestion;
                        _submitPrompt(suggestion);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.promptBorder),
                        backgroundColor: AppColors.promptBackground,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.promptBackground,
      body: SafeArea(
        child: _buildReadyScreen(),
      ),
    );
  }
}
