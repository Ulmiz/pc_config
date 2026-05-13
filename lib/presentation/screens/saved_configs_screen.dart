import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/pc_part_repository.dart';
import '../providers/isar_provider.dart';
import '../providers/build_state_provider.dart';
import 'build_screen.dart';

class SavedConfigsScreen extends ConsumerWidget {
  const SavedConfigsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isar = ref.watch(isarProvider);
    final repo = PCPartRepository(isar);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Configuraciones Guardadas', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: repo.getAllConfigurations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          
          final configs = snapshot.data ?? [];
          
          if (configs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes configuraciones guardadas.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: configs.length,
            itemBuilder: (context, index) {
              final config = configs[index];
              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    config.name,
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${config.createdAt.day}/${config.createdAt.month}/${config.createdAt.year} - \$${config.totalPrice.toStringAsFixed(2)} MXN',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                        onPressed: () async {
                          final nameController = TextEditingController(text: config.name);
                          final String? newName = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              title: Text('Renombrar PC', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                              content: TextField(
                                controller: nameController,
                                autofocus: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Nuevo Nombre',
                                  labelStyle: TextStyle(color: AppColors.accent),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, nameController.text),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                                  child: const Text('Actualizar', style: TextStyle(color: Colors.black)),
                                ),
                              ],
                            ),
                          );

                          if (newName != null && newName.isNotEmpty) {
                            await repo.updateConfigurationName(config.id, newName);
                            // Refresh
                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.accent),
                    ],
                  ),
                  onTap: () async {
                    await ref.read(buildStateProvider.notifier).loadFromPartIds(config.partIds, isar);
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const BuildScreen()),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
