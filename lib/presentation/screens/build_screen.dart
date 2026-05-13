import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/pc_part_model.dart';
import '../../data/models/configuration_model.dart';
import '../../data/repositories/pc_part_repository.dart';
import '../../data/services/heuristic_builder_service.dart';
import '../providers/build_state_provider.dart';
import '../providers/isar_provider.dart';
import '../../data/services/voice_service.dart';
import '../widgets/ai_terminal_input.dart';
import 'saved_configs_screen.dart';

class BuildScreen extends ConsumerStatefulWidget {
  const BuildScreen({super.key});

  @override
  ConsumerState<BuildScreen> createState() => _BuildScreenState();
}

class _BuildScreenState extends ConsumerState<BuildScreen> with TickerProviderStateMixin {
  final TextEditingController _terminalController = TextEditingController();
  late AnimationController _rotationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Voice state
  bool _isListening = false;
  final VoiceService _voiceService = VoiceService();

  final List<String> _slots = [
    'CPU',
    'Motherboard',
    'RAM',
    'GPU',
    'Storage',
    'PSU',
    'Case',
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _terminalController.dispose();
    _rotationController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  void _toggleVoice() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      await _voiceService.startListening(
        onResult: (text) {
          setState(() {
            _terminalController.text = text;
          });
        },
        onDone: () {
          setState(() => _isListening = false);
          if (_terminalController.text.isNotEmpty) {
            _onTerminalSubmit();
          }
        },
      );
      setState(() => _isListening = true);
    }
  }

  Future<void> _onTerminalSubmit() async {
    final text = _terminalController.text;
    if (text.isEmpty) return;

    final currentState = ref.read(buildStateProvider);
    final isar = ref.read(isarProvider);
    final heuristicService = ref.read(heuristicBuilderServiceProvider);

    try {
      final partIds = await heuristicService.generateConfigFromPrompt(
        text, 
        currentState: currentState,
      );
      
      if (partIds.isNotEmpty) {
        await ref.read(buildStateProvider.notifier).loadFromPartIds(partIds, isar);
        _terminalController.clear();
      }
    } catch (e) {
      debugPrint('Error en búsqueda: $e');
    }
  }

  void _saveCurrentBuild() async {
    final buildState = ref.read(buildStateProvider);
    if (buildState.selectedParts.isEmpty) return;

    String suggestedName = "PC";
    final gpu = buildState.selectedParts['GPU'];
    
    String brand = "";
    if (gpu != null) {
      if (gpu.name.toLowerCase().contains('asus')) {
        brand = "Asus";
      } else if (gpu.name.toLowerCase().contains('gigabyte')) brand = "Gigabyte";
      else if (gpu.name.toLowerCase().contains('aorus')) brand = "Aorus";
      else if (gpu.name.toLowerCase().contains('msi')) brand = "MSI";
    }

    String type = "Gaming";
    if (buildState.selectedParts.values.any((p) => p.tags?.contains('diseño') ?? false)) type = "Diseño";
    if (buildState.selectedParts.values.any((p) => p.tags?.contains('economica') ?? false)) type = "Oficina";

    suggestedName = "PC $type ${brand.isNotEmpty ? "($brand)" : ""} - \$${buildState.totalPrice.toStringAsFixed(0)}";

    final nameController = TextEditingController(text: suggestedName);

    final String? finalName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Guardar Configuración', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nombre de la PC',
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
            child: const Text('Guardar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (finalName == null || finalName.isEmpty) return;

    final isar = ref.read(isarProvider);
    final repo = PCPartRepository(isar);

    final config = ConfigurationModel()
      ..name = finalName
      ..totalPrice = buildState.totalPrice
      ..createdAt = DateTime.now()
      ..partIds = buildState.selectedParts.values.map((e) => e.partId!).toList();

    await repo.saveConfiguration(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada exitosamente.')),
      );
    }
  }

  void _showDetailsModal() {
    final buildState = ref.read(buildStateProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Text('Detalles de la PC', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const Divider(color: Colors.white10),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: buildState.selectedParts.values.map((part) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(part.type, style: GoogleFonts.inter(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(part.name, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(part.description ?? '', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('\$${part.price.toStringAsFixed(2)} MXN', style: GoogleFonts.inter(color: AppColors.accent, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPartSelector(String slotType) async {
    final isar = ref.read(isarProvider);
    final repo = PCPartRepository(isar);
    final parts = await repo.getPartsByType(slotType);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Seleccionar $slotType',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: parts.isEmpty
                  ? const Center(child: Text('No hay componentes disponibles', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      itemCount: parts.length,
                      itemBuilder: (context, index) {
                        final part = parts[index];
                        return ListTile(
                          title: Text(part.name, style: const TextStyle(color: AppColors.textPrimary)),
                          subtitle: Text(part.description ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                          trailing: Text(
                            '\$${part.price.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            ref.read(buildStateProvider.notifier).selectPart(slotType, part);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final buildState = ref.watch(buildStateProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.laptop_mac, size: 40, color: AppColors.accent),
                    const SizedBox(height: 12),
                    Text(
                      'PC CONFIG',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined, color: Colors.white70),
              title: const Text('Menú Principal', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined, color: Colors.white70),
              title: const Text('Detalles Técnicos', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showDetailsModal();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmarks_outlined, color: Colors.white70),
              title: const Text('Configuraciones Guardadas', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedConfigsScreen()));
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable Content
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 220), // Adjusted for larger pill
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _HeaderButton(
                            icon: Icons.menu,
                            color: AppColors.surface,
                            onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          ),
                          _HeaderButton(
                            icon: Icons.save,
                            color: AppColors.accent,
                            iconColor: Colors.black,
                            onTap: _saveCurrentBuild,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Visual PC Area
                    SizedBox(
                      height: 280,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                            child: SvgPicture.asset(
                              'assets/303726.svg',
                              height: 180,
                              placeholderBuilder: (context) => const CircularProgressIndicator(color: AppColors.accent),
                            ),
                          ),
                          ...List.generate(_slots.length, (index) {
                            return AnimatedBuilder(
                              animation: _rotationController,
                              builder: (context, child) {
                                final double seed = index * 0.7;
                                final double time = _rotationController.value * 2 * math.pi;
                                final double driftX = math.sin(time + seed) * 40.0 + math.cos(time * 0.5 + seed) * 20.0;
                                final double driftY = math.cos(time * 0.7 + seed) * 35.0 + math.sin(time * 0.3 + seed) * 15.0;
                                final double angle = index * (2 * math.pi / _slots.length);
                                const double baseRadius = 100.0;
                                final double baseX = math.cos(angle) * baseRadius;
                                final double baseY = math.sin(angle) * baseRadius;
                                final double x = baseX + driftX;
                                final double y = baseY + driftY;
                                final slotType = _slots[index];
                                final isSelected = buildState.selectedParts.containsKey(slotType);
                                return Transform.translate(
                                  offset: Offset(x, y),
                                  child: GestureDetector(
                                    onTap: () => _showPartSelector(slotType),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.accent.withOpacity(0.9) : AppColors.surface.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isSelected ? AppColors.accent : Colors.blue).withOpacity(0.25),
                                            blurRadius: 15,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: Icon(
                                        _getIconForSlot(slotType),
                                        size: 18,
                                        color: isSelected ? Colors.black : Colors.white70,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (buildState.compatibilityErrors.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          border: Border.all(color: AppColors.error),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: buildState.compatibilityErrors
                              .map((err) => Text('• $err', style: const TextStyle(color: AppColors.error)))
                              .toList(),
                        ),
                      ),

                    // Slots List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _slots.length,
                      itemBuilder: (context, index) {
                        final slotType = _slots[index];
                        final selectedPart = buildState.selectedParts[slotType];
                        return Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: selectedPart != null ? AppColors.accent : Colors.black26,
                              width: selectedPart != null ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(_getIconForSlot(slotType), color: selectedPart != null ? AppColors.accent : AppColors.textSecondary),
                            title: Text(slotType, style: TextStyle(fontWeight: FontWeight.bold, color: selectedPart != null ? AppColors.textPrimary : AppColors.textSecondary)),
                            subtitle: selectedPart != null ? Text(selectedPart.name, style: const TextStyle(color: AppColors.textPrimary)) : const Text('Tap to select...'),
                            trailing: selectedPart != null ? Text('\$${selectedPart.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)) : const Icon(Icons.add_circle_outline),
                            onTap: () => _showPartSelector(slotType),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Refined Floating Chat Component
            Positioned(
              bottom: 40,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black, // Pure black as requested
                  borderRadius: BorderRadius.circular(20), // Reduced rounding
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: -2,
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stats Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt, color: AppColors.accent, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${buildState.totalWatts}W', 
                                style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                          Text(
                            'TOTAL: \$${buildState.totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.jetBrainsMono(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Input Row
                    Container(
                      height: 64, // Larger input
                      decoration: BoxDecoration(
                        color: Colors.black, // Match parent color
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.add, color: Colors.white.withOpacity(0.7), size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _terminalController,
                              onSubmitted: (_) => _onTerminalSubmit(),
                              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Ask anything...',
                                hintStyle: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 16),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none, 
                                color: _isListening ? AppColors.accent : Colors.white, 
                                size: 24
                              ),
                              onPressed: _toggleVoice,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForSlot(String slot) {
    switch (slot) {
      case 'CPU': return Icons.memory;
      case 'Motherboard': return Icons.developer_board;
      case 'RAM': return Icons.memory_outlined;
      case 'GPU': return Icons.videogame_asset;
      case 'Storage': return Icons.storage;
      case 'PSU': return Icons.power;
      case 'Case': return Icons.desktop_windows;
      default: return Icons.device_unknown;
    }
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.color,
    this.iconColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}
