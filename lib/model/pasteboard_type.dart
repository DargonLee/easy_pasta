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
  htmlType(name: 'public.html'),
  tiffType(name: 'public.tiff'),
  fileUrlType(name: 'public.file-url'),
  sourceCode(name: 'com.apple.dt.source-code'),
  webURL(name: 'public.url'), 
  pdfType(name: 'com.adobe.pdf');

  const NSPboardType({required this.name});
  final String name;
}

/// 剪贴板应用信息相关常量
enum NSPboardTypeAppInfo {
  appName,
  appId,
  appIcon;
}

/// 剪贴板排序类型
enum NSPboardSortType {
  allType,
  textType,
  imageType,
  fileType,
  urlType,
  favoriteType;
}

enum NSPboardItemType {
  text,
  rtf,
  html,
  tiff,
  url,
  file;
}