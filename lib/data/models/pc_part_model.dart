import 'package:isar/isar.dart';

part 'pc_part_model.g.dart';

@Name('PCPart7690')
@collection
class PCPartModel {
  Id id = Isar.autoIncrement;

  @Name('partId10530')
  @Index(unique: true, replace: true)
  String? partId; // String ID for easier importing from JSON

  late String name;
  
  @Name('type1020')
  @Index()
  late String type; // e.g., 'CPU', 'GPU', 'Motherboard', 'RAM', 'Storage', 'PSU', 'Case'
  
  late String category;
  
  late double price;
  
  String? socketType; // Important for CPU and Motherboard
  
  int? wattage; // Important for PSU (max output) and others (TDP/consumption)
  
  String? dimensions;
  
  String? description;
  
  String? imageUrl;

  // Additional technical specs as JSON string or specific fields
  String? formFactor; // e.g., ATX, Micro-ATX (Motherboard, Case)
  String? ramType; // e.g., DDR4, DDR5 (Motherboard, RAM)

  List<String>? tags; // For heuristic matching (e.g. "gaming", "diseño")
}
