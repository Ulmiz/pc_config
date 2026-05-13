import 'package:isar/isar.dart';

part 'configuration_model.g.dart';

@Name('Config38990')
@collection
class ConfigurationModel {
  Id id = Isar.autoIncrement;

  late String name;
  
  late double totalPrice;
  
  late DateTime createdAt;

  // Store the IDs of the selected parts
  List<String> partIds = [];
}
