import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/sample_seeder.dart';
import '../../presentation/providers/isar_provider.dart';
import '../repositories/pc_part_repository.dart';
import '../models/pc_part_model.dart';
import '../../presentation/providers/build_state_provider.dart';

final heuristicBuilderServiceProvider = Provider<HeuristicBuilderService>((ref) {
  final isar = ref.watch(isarProvider);
  return HeuristicBuilderService(PCPartRepository(isar));
});

class HeuristicBuilderService {
  final PCPartRepository _repository;

  HeuristicBuilderService(this._repository);

  /// Genera una configuración basada en perfiles expertos (Gaming, Diseño, Industrial, Aeronáutica)
  Future<List<String>> generateConfigFromPrompt(String prompt, {BuildState? currentState}) async {
    final lowerPrompt = prompt.toLowerCase();
    
    // 1. Extraer presupuesto
    double? userBudget = _extractBudget(lowerPrompt);
    
    // 2. Determinar el perfil
    String profile = 'generico';
    if (lowerPrompt.contains('gaming') || lowerPrompt.contains('jugar') || lowerPrompt.contains('gamer')) {
      profile = 'gaming';
    } else if (lowerPrompt.contains('diseño') || lowerPrompt.contains('grafico') || lowerPrompt.contains('render')) {
      profile = 'diseño';
    } else if (lowerPrompt.contains('industrial') || lowerPrompt.contains('ingenieria') || lowerPrompt.contains('trabajo')) {
      profile = 'industrial';
    } else if (lowerPrompt.contains('aeronautica') || lowerPrompt.contains('simulacion') || lowerPrompt.contains('avion')) {
      profile = 'aeronautica';
    }

    // 3. Obtener todas las piezas
    var allParts = await _repository.getAllParts();
    if (allParts.isEmpty) {
      await SampleSeeder.seedParts(_repository.isar);
      allParts = await _repository.getAllParts();
    }
    if (allParts.isEmpty) return [];

    // 4. Mapeo de categorías requeridas
    final categories = ['CPU', 'Motherboard', 'RAM', 'GPU', 'PSU', 'Storage', 'Case'];
    List<String> selectedPartIds = [];
    
    // Distribución de presupuesto según perfil
    final Map<String, double> budgetWeights = {
      'gaming': 0.40, // Mucho a GPU
      'diseño': 0.25, // Balance CPU/GPU
      'industrial': 0.20, // Balance
      'aeronautica': 0.35, // Mucho a CPU/RAM
      'generico': 0.25
    };

    double totalSpent = 0;
    
    for (final category in categories) {
      final partsInCategory = allParts.where((p) => p.type == category).toList();
      if (partsInCategory.isEmpty) continue;

      // Puntuación de piezas según el perfil y el presupuesto
      List<Map<String, dynamic>> scoredParts = partsInCategory.map((part) {
        double score = 0;
        
        // Bonus por perfil (usando tags del JSON)
        if (part.tags != null) {
          if (part.tags!.contains(profile)) score += 100;
          if (profile == 'aeronautica' && part.tags!.contains('entusiasta')) score += 80;
          if (profile == 'generico' && part.tags!.contains('calidad precio')) score += 50;
        }

        // Ajuste por presupuesto si el usuario dio uno
        if (userBudget != null) {
          // Intentamos que la pieza no exceda una fracción del presupuesto
          double idealPrice = userBudget * 0.15; // Estimación simple por pieza
          if (category == 'GPU' && profile == 'gaming') idealPrice = userBudget * 0.4;
          if (category == 'CPU' && profile == 'aeronautica') idealPrice = userBudget * 0.3;

          double diff = (part.price - idealPrice).abs();
          score += (1.0 / (diff + 1)) * 1000; // Cuanto más cerca del precio ideal, mejor
        }

        return {'part': part, 'score': score};
      }).toList();

      scoredParts.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      // Seleccionamos la mejor pieza que no rompa el presupuesto total (si hay uno)
      PCPartModel bestPart = scoredParts.first['part'];
      
      if (userBudget != null && totalSpent + bestPart.price > userBudget * 1.1) {
        // Si la mejor se pasa del presupuesto, buscamos la más barata compatible
        for (var item in scoredParts.reversed) {
          if (totalSpent + (item['part'] as PCPartModel).price <= userBudget * 1.1) {
            bestPart = item['part'];
            break;
          }
        }
      }

      selectedPartIds.add(bestPart.partId!);
      totalSpent += bestPart.price;
    }

    return selectedPartIds;
  }

  double? _extractBudget(String prompt) {
    final cleanPrompt = prompt.replaceAll(' mil', '000').replaceAll('k', '000').replaceAll('k', '000');
    final RegExp budgetRegex = RegExp(r'(\d+(?:,\d{3})*(?:\.\d+)?)');
    final matches = budgetRegex.allMatches(cleanPrompt);
    for (final match in matches) {
      final valueStr = match.group(1)?.replaceAll(',', '');
      if (valueStr != null) {
        final val = double.tryParse(valueStr);
        if (val != null && val > 500) return val;
      }
    }
    return null;
  }

  List<String> _extractTags(String prompt) {
    List<String> activeTags = [];
    final tagKeywords = {
      'gaming': ['jugar', 'juegos', 'gaming', 'gamer', 'videojuegos'],
      'diseño': ['diseño', 'render', 'edicion', 'autocad', 'blender', '3d'],
      'economica': ['barata', 'economica', 'bajo presupuesto', 'estudio', 'ofimatica', 'basica'],
      '4k': ['4k', 'ultra', 'maximo', 'entusiasta', 'high end'],
      '1080p': ['1080p', 'full hd', 'calidad precio', 'media'],
      'ssd': ['ssd', 'rapido', 'veloz', 'm.2', 'nvme'],
      'espacioso': ['espacio', 'grande', 'gabinete', 'espacioso', 'atx', 'flujo', 'aire'],
      'blanco': ['blanco', 'white', 'estetica'],
      'rgb': ['rgb', 'luces', 'colores', 'gamer']
    };

    tagKeywords.forEach((tag, keywords) {
      for (final kw in keywords) {
        if (prompt.contains(kw)) {
          activeTags.add(tag);
          break;
        }
      }
    });
    return activeTags;
  }

  List<String> _extractBrands(String prompt) {
    final brands = ['asus', 'gigabyte', 'aorus', 'xpg', 'nzxt', 'samsung', 'kingston', 'intel', 'amd', 'nvidia', 'corsair'];
    List<String> detected = [];
    for (final brand in brands) {
      if (prompt.contains(brand)) {
        detected.add(brand);
      }
    }
    return detected;
  }
}
