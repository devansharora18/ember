import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import '../models/format_range.dart';

class EpubMetadata {
  final String title;
  final String author;
  final Uint8List? coverBytes;

  const EpubMetadata({required this.title, required this.author, this.coverBytes});
}

class EpubChapter {
  final String title;
  final String content;
  final String? spineHref;
  final List<FormatRange> formatRanges;

  const EpubChapter({required this.title, required this.content, this.spineHref, this.formatRanges = const []});
}

class EpubPageMap {
  final List<({String href, String label})> pages;

  const EpubPageMap({required this.pages});
}

class EpubParser {
  static EpubMetadata parse(String filePath) {
    final file = File(filePath);
    final bytes = file.readAsBytesSync();
    return _parse(bytes, _fileNameToTitle(filePath));
  }

  static EpubMetadata parseBytes(Uint8List bytes) {
    return _parse(bytes, 'Book');
  }

  static EpubMetadata _parse(Uint8List bytes, String fallbackTitle) {
    final archive = ZipDecoder().decodeBytes(bytes);

    String? opfPath;
    for (final entry in archive) {
      if (entry.name == 'META-INF/container.xml') {
        opfPath = _extractOpfPath(utf8.decode(entry.content as List<int>));
        break;
      }
    }

    String title = fallbackTitle;
    String author = 'Unknown';
    Uint8List? coverBytes;

    if (opfPath != null) {
      final opfDir = opfPath.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';
      final opfEntry = archive.findFile(opfPath);
      if (opfEntry != null) {
        final opfXml = utf8.decode(opfEntry.content as List<int>);
        title = _extractTag(opfXml, 'dc:title') ?? title;
        title = _extractTag(opfXml, 'title') ?? title;
        author = _extractTag(opfXml, 'dc:creator') ?? author;
        author = _extractTag(opfXml, 'creator') ?? author;
        coverBytes = _extractCover(opfXml, opfDir, archive);
      }
    }

    return EpubMetadata(title: title, author: author, coverBytes: coverBytes);
  }

  static List<EpubChapter> extractChapters(String filePath) {
    final file = File(filePath);
    final bytes = file.readAsBytesSync();
    return _extractChapters(bytes);
  }

  static List<EpubChapter> extractChaptersFromBytes(Uint8List bytes) {
    return _extractChapters(bytes);
  }

  static List<EpubChapter> _extractChapters(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      String? opfPath;
      for (final entry in archive) {
        if (entry.name == 'META-INF/container.xml') {
          opfPath = _extractOpfPath(utf8.decode(entry.content as List<int>));
          break;
        }
      }
      if (opfPath == null) return [];

      final opfDir = opfPath.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';
      final opfEntry = archive.findFile(opfPath);
      if (opfEntry == null) return [];

      final opfXml = utf8.decode(opfEntry.content as List<int>);
      final spineHrefs = _extractSpineHrefs(opfXml);
      final spineIdrefs = _extractSpineIdrefs(opfXml);
      final ncxTitles = _extractNcxTitles(archive, opfDir, opfXml, spineIdrefs);

      final chapters = <EpubChapter>[];
      for (var i = 0; i < spineHrefs.length; i++) {
        final href = spineHrefs[i];
        final path = _resolvePath(opfDir, href);
        final entry = archive.findFile(path);
        if (entry != null) {
          final html = utf8.decode(entry.content as List<int>);
          var title = i < ncxTitles.length ? ncxTitles[i] : '';
          if (title.isEmpty) title = _extractTitleFromHtml(html);
          if (title.isEmpty) title = 'Chapter ${i + 1}';
          final parsed = _parseFormattedText(html);
          chapters.add(EpubChapter(title: title, content: parsed.text, spineHref: href, formatRanges: parsed.ranges));
        }
      }
      return chapters;
    } catch (_) {
      return [];
    }
  }

  static EpubPageMap extractPageMap(String filePath) {
    try {
      final file = File(filePath);
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      String? opfPath;
      for (final entry in archive) {
        if (entry.name == 'META-INF/container.xml') {
          opfPath = _extractOpfPath(utf8.decode(entry.content as List<int>));
          break;
        }
      }
      if (opfPath == null) return const EpubPageMap(pages: []);

      final opfDir = opfPath.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';
      final opfEntry = archive.findFile(opfPath);
      if (opfEntry == null) return const EpubPageMap(pages: []);

      final opfXml = utf8.decode(opfEntry.content as List<int>);
      final pages = <({String href, String label})>[];

      final navHref = _extractNavHref(opfXml);
      if (navHref != null) {
        final navPath = _resolvePath(opfDir, navHref);
        final navEntry = archive.findFile(navPath);
        if (navEntry != null) {
          final navHtml = utf8.decode(navEntry.content as List<int>);
          for (final p in _extractNavPages(navHtml)) {
            pages.add((href: p['href']!, label: p['label']!));
          }
        }
      }

      if (pages.isEmpty) {
        final manifestItems = _parseManifestItems(opfXml);
        for (final mi in manifestItems.entries) {
          if (mi.key.toLowerCase().contains('ncx') || mi.value.endsWith('.ncx')) {
            final ncxPath = _resolvePath(opfDir, mi.value);
            final ncxEntry = archive.findFile(ncxPath);
            if (ncxEntry != null) {
              final ncxXml = utf8.decode(ncxEntry.content as List<int>);
              for (final p in _extractNcxPages(ncxXml)) {
                pages.add((href: p['href']!, label: p['label']!));
              }
            }
          }
        }
      }

      return EpubPageMap(pages: pages);
    } catch (_) {
      return const EpubPageMap(pages: []);
    }
  }

  static Uint8List? _extractCover(String opfXml, String opfDir, Archive archive) {
    final manifestItems = _parseManifestItems(opfXml);

    String? coverId = _extractMetaCoverId(opfXml);
    if (coverId == null) {
      coverId = manifestItems.keys.firstWhere((id) => id.toLowerCase().contains('cover'), orElse: () => '');
      if (coverId.isEmpty) coverId = null;
    }

    if (coverId != null) {
      final href = manifestItems[coverId];
      if (href != null) {
        final path = _resolvePath(opfDir, href);
        final entry = archive.findFile(path);
        if (entry != null) return Uint8List.fromList(entry.content as List<int>);
      }
    }

    for (final e in manifestItems.entries) {
      if (_isImage(e.key) || _isImage(e.value)) {
        final path = _resolvePath(opfDir, e.value);
        final f = archive.findFile(path);
        if (f != null) return Uint8List.fromList(f.content as List<int>);
      }
    }

    for (final entry in archive) {
      final name = entry.name.toLowerCase();
      if (_isImageExt(name) && !name.startsWith('mimetype') && !name.startsWith('meta-inf')) {
        return Uint8List.fromList(entry.content as List<int>);
      }
    }

    return null;
  }

  static Map<String, String> _parseManifestItems(String xml) {
    final items = <String, String>{};
    final re = RegExp(r'<item\s+([^>]+)/?>', caseSensitive: false);
    for (final match in re.allMatches(xml)) {
      final attrs = match.group(1)!;
      final idMatch = RegExp(r'id="([^"]+)"', caseSensitive: false).firstMatch(attrs);
      final hrefMatch = RegExp(r'href="([^"]+)"', caseSensitive: false).firstMatch(attrs);
      if (idMatch != null && hrefMatch != null) items[idMatch.group(1)!] = hrefMatch.group(1)!;
    }
    return items;
  }

  static String? _extractMetaCoverId(String xml) {
    final patterns = [
      RegExp(r'<meta\s+[^>]*name="cover"[^>]*content="([^"]+)"[^>]*/?>', caseSensitive: false),
      RegExp(r'<meta\s+[^>]*content="([^"]+)"[^>]*name="cover"[^>]*/?>', caseSensitive: false),
    ];
    for (final re in patterns) {
      final match = re.firstMatch(xml);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static bool _isImage(String s) {
    final lower = s.toLowerCase();
    return _isImageExt(lower) || lower.startsWith('cover') || lower.startsWith('image');
  }

  static bool _isImageExt(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.gif') || lower.endsWith('.webp') || lower.endsWith('.svg');
  }

  static String _resolvePath(String dir, String href) {
    if (href.startsWith('/')) return href.substring(1);
    if (href.startsWith('./')) return dir + href.substring(2);
    if (href.contains('://')) return href;
    var path = dir + href;
    final segments = <String>[];
    for (final seg in path.split('/')) {
      if (seg == '..') { if (segments.isNotEmpty) { segments.removeLast(); } } else if (seg != '.' && seg.isNotEmpty) { segments.add(seg); }
    }
    return segments.join('/');
  }

  static String _fileNameToTitle(String path) {
    final name = path.split('/').last.split('\\').last;
    final dotIndex = name.lastIndexOf('.');
    return dotIndex > 0 ? name.substring(0, dotIndex) : name;
  }

  static String? _extractOpfPath(String xml) {
    final match = RegExp(r'full-path="([^"]+)"').firstMatch(xml);
    return match?.group(1);
  }

  static String? _extractTag(String xml, String tag) {
    final match = RegExp('<$tag[^>]*>([^<]+)</$tag>', caseSensitive: false).firstMatch(xml);
    return match?.group(1)?.trim();
  }

  static List<String> _extractSpineIdrefs(String opfXml) {
    final re = RegExp(r'<itemref\s+[^>]*idref="([^"]+)"[^>]*/?>', caseSensitive: false);
    return re.allMatches(opfXml).map((m) => m.group(1)!).toList();
  }

  static List<String> _extractNcxTitles(Archive archive, String opfDir, String opfXml, List<String> spineIdrefs) {
    final navHref = _extractNavHref(opfXml);
    if (navHref != null) {
      final navPath = _resolvePath(opfDir, navHref);
      final navEntry = archive.findFile(navPath);
      if (navEntry != null) {
        final titles = _extractNavTitles(utf8.decode(navEntry.content as List<int>));
        if (titles.isNotEmpty) return titles;
      }
    }
    final manifestItems = _parseManifestItems(opfXml);
    for (final e in manifestItems.entries) {
      if (e.key.toLowerCase().contains('ncx') || e.value.endsWith('.ncx')) {
        final ncxPath = _resolvePath(opfDir, e.value);
        final ncxEntry = archive.findFile(ncxPath);
        if (ncxEntry != null) {
          final titles = _extractNcxNavPoints(utf8.decode(ncxEntry.content as List<int>));
          if (titles.isNotEmpty) return titles;
        }
      }
    }
    return [];
  }

  static String? _extractNavHref(String opfXml) {
    final manifestItems = _parseManifestItems(opfXml);
    for (final e in manifestItems.entries) {
      if (e.key.toLowerCase().contains('nav') || e.value.contains('nav')) return e.value;
    }
    return null;
  }

  static List<String> _extractNavTitles(String html) {
    final titles = <String>[];
    final navRe = RegExp(r'<nav[^>]*epub:type="toc"[^>]*>(.*?)</nav>', dotAll: true, caseSensitive: false);
    final navMatch = navRe.firstMatch(html);
    final navContent = navMatch?.group(1) ?? html;
    final linkRe = RegExp(r'<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', dotAll: true, caseSensitive: false);
    for (final m in linkRe.allMatches(navContent)) {
      final label = _stripHtml(m.group(2)!);
      if (label.isNotEmpty) titles.add(label);
    }
    return titles;
  }

  static List<String> _extractNcxNavPoints(String xml) {
    final titles = <String>[];
    final re = RegExp(r'<navPoint[^>]*>.*?<navLabel>.*?<text>(.*?)</text>', dotAll: true, caseSensitive: false);
    for (final m in re.allMatches(xml)) {
      final title = m.group(1)!.trim();
      if (title.isNotEmpty) titles.add(title);
    }
    return titles;
  }

  static String _extractTitleFromHtml(String html) {
    final match = RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true, caseSensitive: false).firstMatch(html);
    return match != null ? _stripHtml(match.group(1)!) : '';
  }

  static List<String> _extractSpineHrefs(String opfXml) {
    final manifestItems = _parseManifestItems(opfXml);
    final re = RegExp(r'<itemref\s+[^>]*idref="([^"]+)"[^>]*/?>', caseSensitive: false);
    final hrefs = <String>[];
    for (final m in re.allMatches(opfXml)) {
      final href = manifestItems[m.group(1)!];
      if (href != null && (href.endsWith('.xhtml') || href.endsWith('.html') || href.endsWith('.htm'))) hrefs.add(href);
    }
    return hrefs;
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#\d+;'), '')
        .replaceAll(RegExp(r'&[a-z]+;'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static ({String text, List<FormatRange> ranges}) _parseFormattedText(String html) {
    var cleaned = html
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '');

    final buffer = StringBuffer();
    var ranges = <FormatRange>[];

    var bold = false;
    var italic = false;
    int? headingLevel;
    var rangeStart = 0;

    var prevBold = false;
    var prevItalic = false;
    int? prevHeading;

    bool stylingChanged() {
      return bold != prevBold || italic != prevItalic || headingLevel != prevHeading;
    }

    final tagRe = RegExp(r'(<[^>]+>)|([^<]+)');

    for (final match in tagRe.allMatches(cleaned)) {
      final tag = match.group(1);
      final rawText = match.group(2);

      if (tag != null) {
        final lower = tag.toLowerCase();
        if (lower.startsWith('</')) {
          final name = lower.substring(2, lower.length - (lower.endsWith('>') ? 1 : 0)).trim();
          if (name == 'b' || name == 'strong') bold = false;
          if (name == 'i' || name == 'em') italic = false;
          if (name == 'h1' || name == 'h2' || name == 'h3' || name == 'h4' || name == 'h5' || name == 'h6') headingLevel = null;
        } else if (lower.endsWith('/>')) {
          continue;
        } else {
          final spaceIdx = lower.indexOf(RegExp(r'[\s/>]'));
          String name;
          if (spaceIdx > 0) {
            name = lower.substring(1, spaceIdx);
          } else {
            final closeIdx = lower.endsWith('>') ? lower.length - 1 : lower.length;
            name = lower.substring(1, closeIdx);
          }
          if (name == 'b' || name == 'strong') bold = true;
          if (name == 'i' || name == 'em') italic = true;
          if (name == 'h1') headingLevel = 1;
          if (name == 'h2') headingLevel = 2;
          if (name == 'h3') headingLevel = 3;
          if (name == 'h4') headingLevel = 4;
          if (name == 'h5') headingLevel = 5;
          if (name == 'h6') headingLevel = 6;
        }
      } else if (rawText != null) {
        var text = rawText
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll(RegExp(r'&#\d+;'), '')
            .replaceAll(RegExp(r'&[a-z]+;'), '');
        text = text.replaceAll(RegExp(r'\s+'), ' ');

        if (text.trim().isEmpty && buffer.isEmpty) continue;

        if (stylingChanged() && rangeStart < buffer.length) {
          ranges.add(FormatRange(
            start: rangeStart,
            end: buffer.length,
            bold: prevBold,
            italic: prevItalic,
            headingLevel: prevHeading,
          ));
          rangeStart = buffer.length;
        }

        prevBold = bold;
        prevItalic = italic;
        prevHeading = headingLevel;

        buffer.write(text);
      }
    }

    if (rangeStart < buffer.length && (bold || italic || headingLevel != null)) {
      ranges.add(FormatRange(
        start: rangeStart,
        end: buffer.length,
        bold: bold,
        italic: italic,
        headingLevel: headingLevel,
      ));
    }

    var plain = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();

    if (plain.isNotEmpty && ranges.isNotEmpty) {
      final lengthDiff = buffer.length - plain.length;
      if (lengthDiff > 0) {
        ranges = ranges.map((r) => FormatRange(
          start: (r.start - lengthDiff).clamp(0, plain.length),
          end: (r.end - lengthDiff).clamp(0, plain.length),
          bold: r.bold,
          italic: r.italic,
          headingLevel: r.headingLevel,
        )).where((r) => r.start < r.end).toList();
      }
    }

    return (text: plain, ranges: ranges);
  }

  static List<Map<String, String>> _extractNavPages(String html) {
    final pages = <Map<String, String>>[];
    final listRe = RegExp(r'<ol[^>]*epub:type="page-list"[^>]*>(.*?)</ol>', dotAll: true, caseSensitive: false);
    final listMatch = listRe.firstMatch(html);
    if (listMatch == null) return pages;
    final linkRe = RegExp(r'<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', dotAll: true, caseSensitive: false);
    for (final m in linkRe.allMatches(listMatch.group(1)!)) {
      pages.add({'href': m.group(1)!, 'label': _stripHtml(m.group(2)!).trim()});
    }
    return pages;
  }

  static List<Map<String, String>> _extractNcxPages(String xml) {
    final pages = <Map<String, String>>[];
    final listRe = RegExp(r'<pageList>(.*?)</pageList>', dotAll: true, caseSensitive: false);
    final listMatch = listRe.firstMatch(xml);
    if (listMatch == null) return pages;
    final targetRe = RegExp(r'<pageTarget[^>]*>(.*?)</pageTarget>', dotAll: true, caseSensitive: false);
    for (final m in targetRe.allMatches(listMatch.group(1)!)) {
      final pt = m.group(1)!;
      final hrefMatch = RegExp(r'<content[^>]*src="([^"]+)"', caseSensitive: false).firstMatch(pt);
      final labelMatch = RegExp(r'<navLabel>.*?<text>(.*?)</text>', dotAll: true, caseSensitive: false).firstMatch(pt);
      if (hrefMatch != null) pages.add({'href': hrefMatch.group(1)!, 'label': labelMatch != null ? _stripHtml(labelMatch.group(1)!) : '?'});
    }
    return pages;
  }
}
