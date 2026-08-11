import '../core/constants/strings.dart';

/// Stored at ecard_templates/{templateId}. Admin/seed-managed reference
/// data — read-only from the client (see firestore.rules), analogous to
/// skills/ and blogCategories/. Defines which occasion a template is
/// for and which field keys its form/card should render, so new
/// designs can be added by writing a new document rather than shipping
/// a new build.
class EcardTemplate {
  final String id;
  final EcardOccasion occasion;
  final String name;
  final String? previewImageUrl;

  /// Ordered list of field keys this template's create-form and card
  /// layout expect inside an Ecard.fields map, e.g. for a wedding
  /// template: ['bride_name', 'groom_name', 'wedding_date', 'venue',
  /// 'bride_image_url', 'groom_image_url', 'single_amount',
  /// 'double_amount'].
  final List<String> fieldSchema;
  final bool isActive;

  const EcardTemplate({
    required this.id,
    required this.occasion,
    required this.name,
    this.previewImageUrl,
    required this.fieldSchema,
    this.isActive = true,
  });

  factory EcardTemplate.fromMap(String id, Map<String, dynamic> map) {
    return EcardTemplate(
      id: id,
      occasion: EcardOccasionX.fromString(map['occasion'] as String?),
      name: map['name'] ?? '',
      previewImageUrl: map['preview_image_url'],
      fieldSchema: List<String>.from(map['field_schema'] ?? const []),
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'occasion': occasion.value,
      'name': name,
      'preview_image_url': previewImageUrl,
      'field_schema': fieldSchema,
      'is_active': isActive,
    };
  }
}
