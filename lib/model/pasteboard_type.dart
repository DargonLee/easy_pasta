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


enum NSPboardType {
  stringType(name: 'public.utf8-plain-text'),
  rtfType(name: 'public.rtf'),
  tiffType(name: 'public.tiff'),
  fileUrlType(name: 'public.file-url'),
  htmlType(name: 'public.html'),
  pngType(name: 'public.png'),
  textRtfType(name: 'com.trolltech.anymime.text--rtf'),
  appleNotesTypeType(name: 'com.apple.notes.richtext'),
  appNameType(name: 'appName'),
  appIdType(name: 'appId'),
  appIconType(name: 'appIcon');

  const NSPboardType({required this.name});
  final String name;
}