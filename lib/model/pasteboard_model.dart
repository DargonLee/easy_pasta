// Replaces NSStringPboardType
// Replaces NSPDFPboardType
// Replaces NSTIFFPboardType
// Replaces NSRTFPboardType
// Replaces NSRTFDPboardType
// Replaces NSHTMLPboardType
// Replaces NSTabularTextPboardType
// Replaces NSFontPboardType
// Replaces NSRulerPboardType
// Replaces NSColorPboardType
// Replaces NSSoundPboardType
// Replaces NSMultipleTextSelectionPboardType
// Replaces NSPasteboardTypeFindPanelSearchOptions
// Equivalent to kUTTypeURL
// Equivalent to kUTTypeFileURL

import 'dart:typed_data';

enum NSPboardType {
  stringType(name: 'public.utf8-plain-text'),
  rtfType(name: 'public.rtf'),
  fileUrlType(name: 'public.file-url'),
  htmlType(name: 'public.html'),
  textRtfType(name: 'com.trolltech.anymime.text--rtf'),
  appleNotesTypeType(name: 'com.apple.notes.richtext');

  const NSPboardType({required this.name});
  final String name;
}

class NSPboardTypeModel {
  String? rawType;
  var rawValue;

  NSPboardTypeModel.fromItemArray(List<Map<String, Uint8List>> itemArray) {
    print('In Point.fromJson(): ($itemArray)');
  }
}
