import '../../data/models/pc_part_model.dart';
import '../../presentation/providers/build_state_provider.dart';

class ValidationResult {
  final bool isCompatible;
  final String? errorMessage;

  ValidationResult({required this.isCompatible, this.errorMessage});
}

class CompatibilityValidator {
  /// Evaluates if adding a [newPart] to the [currentState] is valid.
  static ValidationResult validate(PCPartModel newPart, BuildState currentState) {
    if (newPart.type == 'CPU') {
      final currentMobo = currentState.selectedParts.values.firstWhere(
        (part) => part.type == 'Motherboard',
        orElse: () => PCPartModel()..id = -1, // Mock invalid part
      );
      
      if (currentMobo.id != -1 && currentMobo.socketType != null && newPart.socketType != null) {
        if (currentMobo.socketType != newPart.socketType) {
          return ValidationResult(
            isCompatible: false,
            errorMessage: 'Socket Incompatible: El procesador requiere ${newPart.socketType}, pero la tarjeta madre es ${currentMobo.socketType}',
          );
        }
      }
    }

    if (newPart.type == 'Motherboard') {
      final currentCpu = currentState.selectedParts.values.firstWhere(
        (part) => part.type == 'CPU',
        orElse: () => PCPartModel()..id = -1,
      );

      if (currentCpu.id != -1 && currentCpu.socketType != null && newPart.socketType != null) {
        if (currentCpu.socketType != newPart.socketType) {
          return ValidationResult(
            isCompatible: false,
            errorMessage: 'Socket Incompatible: La tarjeta madre es ${newPart.socketType}, pero el procesador requiere ${currentCpu.socketType}',
          );
        }
      }
    }

    if (newPart.type == 'Motherboard' || newPart.type == 'Case') {
      final currentMobo = newPart.type == 'Motherboard' 
          ? newPart 
          : currentState.selectedParts.values.firstWhere((p) => p.type == 'Motherboard', orElse: () => PCPartModel()..id = -1);
      
      final currentCase = newPart.type == 'Case'
          ? newPart
          : currentState.selectedParts.values.firstWhere((p) => p.type == 'Case', orElse: () => PCPartModel()..id = -1);

      if (currentMobo.id != -1 && currentCase.id != -1) {
        if (currentMobo.formFactor == 'ATX' && currentCase.formFactor == 'Micro-ATX') {
          return ValidationResult(
            isCompatible: false,
            errorMessage: 'Factor de Forma Incompatible: La tarjeta madre ATX no cabe en un gabinete Micro-ATX.',
          );
        }
        if (currentMobo.formFactor == 'E-ATX' && currentCase.formFactor != 'E-ATX') {
           // Basic check for E-ATX
           return ValidationResult(
            isCompatible: false,
            errorMessage: 'Factor de Forma Incompatible: La tarjeta madre E-ATX requiere un gabinete E-ATX.',
          );
        }
      }
    }

    return ValidationResult(isCompatible: true);
  }
}
