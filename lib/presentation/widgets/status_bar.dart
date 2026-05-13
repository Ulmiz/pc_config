import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../providers/build_state_provider.dart';

class StatusBar extends ConsumerWidget {
  final Color? backgroundColor;

  const StatusBar({Key? key, this.backgroundColor}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildState = ref.watch(buildStateProvider);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        border: const Border(top: BorderSide(color: Colors.black26, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.yellowAccent, size: 18),
              const Icon(Icons.flash_on, color: Colors.yellowAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                '${buildState.totalWatts} W / Max',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            'Total: \$${buildState.totalPrice.toStringAsFixed(2)}',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
