import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import '../../data/models/pc_part_model.dart';

class SampleSeeder {
  // Static memory storage for web fallback
  static final List<PCPartModel> memoryParts = [];

  static Future<void> seedParts(Isar? isar) async {
    try {
      final jsonString = await rootBundle.loadString('assets/sample_parts.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      final parts = jsonList.map((json) {
        return PCPartModel()
          ..partId = json['id']
          ..name = json['name']
          ..type = json['type']
          ..category = json['category']
          ..price = (json['price'] as num).toDouble()
          ..socketType = json['socketType']
          ..wattage = json['wattage']
          ..dimensions = json['dimensions']
          ..description = json['description']
          ..imageUrl = json['imageUrl']
          ..formFactor = json['formFactor']
          ..ramType = json['ramType']
          ..tags = (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList();
      }).toList();

      if (isar != null) {
        final count = await isar.pCPartModels.count();
        print('Current parts in database: $count');
        if (count == 0) {
          await isar.writeTxn(() async {
            await isar.pCPartModels.putAll(parts);
          });
          print('SUCCESS: Seeded ${parts.length} parts into Isar Database.');
        }
      } else {
        // Fallback for Web
        memoryParts.clear();
        memoryParts.addAll(parts);
        print('Seeded ${parts.length} parts into Memory Database (Web).');
      }
    } catch (e) {
      print('Error seeding parts: $e');
    }
  }
}
