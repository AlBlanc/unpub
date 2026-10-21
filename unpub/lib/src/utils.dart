import 'package:yaml/yaml.dart';

dynamic convertYaml(dynamic value) => switch (value) {
  YamlMap map => map.cast<String, dynamic>().map(
    (k, v) => MapEntry(k, convertYaml(v)),
  ),
  YamlList list => list.map(convertYaml).toList(),
  _ => value,
};

Map<String, dynamic>? loadYamlAsMap(dynamic value) {
  final yamlMap = loadYaml(value) as YamlMap?;
  if (yamlMap == null) return null;
  return (convertYaml(yamlMap) as Map).cast<String, dynamic>();
}

List<String> getPackageTags(Map<String, dynamic> pubspec) {
  // TODO: web and other tags
  if (pubspec['flutter'] != null) {
    return ['flutter'];
  } else {
    return ['flutter', 'web', 'other'];
  }
}
