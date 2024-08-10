class SettingModel {
  static const String languageField = "language";
  static const String idField = "id";
  String? language;
  int? id;

  SettingModel({
    required this.id,
    this.language,
  });
  SettingModel.fromJson(Map<String, dynamic> json) {
    language = json['language'];
    id = json['id'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['language'] = language;
    data['id'] = id;
    return data;
  }
}
