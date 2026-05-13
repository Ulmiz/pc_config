import 'package:isar/isar.dart';
import '../models/pc_part_model.dart';
import '../models/configuration_model.dart';
import '../../core/utils/sample_seeder.dart';

class PCPartRepository {
  final Isar? isar;
  
  // Static memory configurations for Web (will persist as long as the tab is open)
  static final List<ConfigurationModel> _memoryConfigs = [];

  PCPartRepository(this.isar);

  Future<void> saveParts(List<PCPartModel> parts) async {
    if (isar != null) {
      await isar!.writeTxn(() async {
        await isar!.pCPartModels.putAll(parts);
      });
    } else {
      SampleSeeder.memoryParts.clear();
      SampleSeeder.memoryParts.addAll(parts);
    }
  }

  Future<List<PCPartModel>> getAllParts() async {
    if (isar != null) {
      return await isar!.pCPartModels.where().findAll();
    }
    return SampleSeeder.memoryParts.toList();
  }

  Future<List<PCPartModel>> getPartsByType(String type) async {
    if (isar != null) {
      return await isar!.pCPartModels.filter().typeEqualTo(type).findAll();
    }
    return SampleSeeder.memoryParts.where((p) => p.type == type).toList();
  }
  
  Future<PCPartModel?> getPartById(String partId) async {
    if (isar != null) {
      return await isar!.pCPartModels.filter().partIdEqualTo(partId).findFirst();
    }
    try {
      return SampleSeeder.memoryParts.firstWhere((p) => p.partId == partId);
    } catch (_) {
      return null;
    }
  }
  
  Future<void> updateConfigurationName(Id id, String newName) async {
    if (isar != null) {
      await isar!.writeTxn(() async {
        final config = await isar!.configurationModels.get(id);
        if (config != null) {
          config.name = newName;
          await isar!.configurationModels.put(config);
        }
      });
    } else {
      final index = _memoryConfigs.indexWhere((c) => c.id == id);
      if (index != -1) {
        _memoryConfigs[index].name = newName;
      }
    }
  }

  Future<void> saveConfiguration(ConfigurationModel config) async {
    if (isar != null) {
      await isar!.writeTxn(() async {
        await isar!.configurationModels.put(config);
      });
    } else {
      // Simulate auto-increment for memory
      if (config.id == Isar.autoIncrement || config.id == 0) {
        config.id = _memoryConfigs.length + 1;
      }
      _memoryConfigs.add(config);
    }
  }
  
  Future<List<ConfigurationModel>> getAllConfigurations() async {
    if (isar != null) {
      return await isar!.configurationModels.where().findAll();
    }
    return _memoryConfigs.toList();
  }
}
