import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class AiTerminalInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final VoidCallback? onVoicePressed;
  final bool isListening;
  final Color? backgroundColor;
  final Color? borderColor;

  const AiTerminalInput({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.onVoicePressed,
    this.isListening = false,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.background,
        border: Border.all(
          color: isListening ? AppColors.accent : (borderColor ?? Colors.black38),
          width: isListening ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isListening ? [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ] : null,
      ),
      child: Row(
        children: [
          Text(
            '> ',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.accent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              cursorColor: Colors.white,
              cursorWidth: 8, // Block cursor effect
              cursorRadius: const Radius.circular(0),
              decoration: InputDecoration(
                hintText: isListening ? 'Escuchando...' : 'Ej. "Quiero una PC para jugar a 4K por menos de \$2000"',
                hintStyle: GoogleFonts.jetBrainsMono(
                  color: isListening ? AppColors.accent.withOpacity(0.5) : AppColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
          if (onVoicePressed != null)
            IconButton(
              icon: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: isListening ? Colors.redAccent : AppColors.textSecondary,
              ),
              onPressed: onVoicePressed,
              tooltip: 'Dictar por voz',
            ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.accent),
            onPressed: onSubmitted,
          ),
        ],
      ),
    );
  }
}
