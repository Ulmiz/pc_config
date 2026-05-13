import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/pc_part_model.dart';
import '../../data/repositories/pc_part_repository.dart';
import '../../domain/usecases/compatibility_validator.dart';

class BuildState {
  final Map<String, PCPartModel> selectedParts; // Key: Slot Type (e.g. 'CPU')
  final double totalPrice;
  final int totalWatts;
  final List<String> compatibilityErrors;

  BuildState({
    required this.selectedParts,
    required this.totalPrice,
    required this.totalWatts,
    required this.compatibilityErrors,
  });

  BuildState copyWith({
    Map<String, PCPartModel>? selectedParts,
    double? totalPrice,
    int? totalWatts,
    List<String>? compatibilityErrors,
  }) {
    return BuildState(
      selectedParts: selectedParts ?? this.selectedParts,
      totalPrice: totalPrice ?? this.totalPrice,
      totalWatts: totalWatts ?? this.totalWatts,
      compatibilityErrors: compatibilityErrors ?? this.compatibilityErrors,
    );
  }
}

class BuildStateNotifier extends StateNotifier<BuildState> {
  BuildStateNotifier()
      : super(BuildState(
          selectedParts: {},
          totalPrice: 0.0,
          totalWatts: 0,
          compatibilityErrors: [],
        ));

  void selectPart(String slotType, PCPartModel part) {
    // 1. Validate Compatibility
    final validation = CompatibilityValidator.validate(part, state);
    
    // 2. Update Map
    final newParts = Map<String, PCPartModel>.from(state.selectedParts);
    newParts[slotType] = part;

    // 3. Recalculate Totals
    double newPrice = 0;
    int newWatts = 0;
    for (var p in newParts.values) {
      newPrice += p.price;
      newWatts += (p.wattage ?? 0);
    }

    // 4. Update Errors list
    List<String> newErrors = List.from(state.compatibilityErrors);
    if (!validation.isCompatible && validation.errorMessage != null) {
      if (!newErrors.contains(validation.errorMessage)) {
        newErrors.add(validation.errorMessage!);
      }
    } else {
      // Logic to clear specific errors could go here
      newErrors.clear(); // Simplifying for the baseline
    }

    // 5. Emit new State
    state = state.copyWith(
      selectedParts: newParts,
      totalPrice: newPrice,
      totalWatts: newWatts,
      compatibilityErrors: newErrors,
    );
  }

  void removePart(String slotType) {
    final newParts = Map<String, PCPartModel>.from(state.selectedParts);
    newParts.remove(slotType);

    double newPrice = 0;
    int newWatts = 0;
    for (var p in newParts.values) {
      newPrice += p.price;
      newWatts += (p.wattage ?? 0);
    }

    state = state.copyWith(
      selectedParts: newParts,
      totalPrice: newPrice,
      totalWatts: newWatts,
      compatibilityErrors: [], // Re-validate all might be needed here in a real app
    );
  }
  Future<void> loadFromPartIds(List<String> partIds, Isar? isar) async {
    final Map<String, PCPartModel> newParts = {};
    double newPrice = 0;
    int newWatts = 0;
    List<String> errors = [];

    // Reset current state
    state = BuildState(
      selectedParts: {},
      totalPrice: 0,
      totalWatts: 0,
      compatibilityErrors: [],
    );

    // Import the repository inside this file (or assume it's imported)
    // Actually we will just instantiate it here directly:
    final repo = PCPartRepository(isar);

    for (final id in partIds) {
      final part = await repo.getPartById(id);
      if (part != null) {
        // Validate against what we have built so far
        final validation = CompatibilityValidator.validate(part, state);
        
        newParts[part.type] = part;
        newPrice += part.price;
        newWatts += (part.wattage ?? 0);

        if (!validation.isCompatible && validation.errorMessage != null) {
          if (!errors.contains(validation.errorMessage)) {
            errors.add(validation.errorMessage!);
          }
        }
        
        // Temporarily update state for the next validation check
        state = state.copyWith(selectedParts: newParts);
      }
    }

    state = state.copyWith(
      selectedParts: newParts,
      totalPrice: newPrice,
      totalWatts: newWatts,
      compatibilityErrors: errors,
    );
  }
}
final buildStateProvider = StateNotifierProvider<BuildStateNotifier, BuildState>((ref) {
  return BuildStateNotifier();
});
