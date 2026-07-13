class XtreamCategory {
  const XtreamCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory XtreamCategory.fromJson(Map<String, dynamic> json) => XtreamCategory(
        id: json['category_id'].toString(),
        name: (json['category_name'] as String?)?.trim() ?? 'Senza nome',
      );
}
