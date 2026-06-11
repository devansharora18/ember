import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';

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

  const EpubChapter({required this.title, required this.content, this.spineHref});
}

class EpubPageMap {
  final List<({String href, String label})> pages;

  const EpubPageMap({required this.pages});
}

class EpubParser {
  static EpubMetadata parse(String filePath) {
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

    String title = _fileNameToTitle(filePath);
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
          chapters.add(EpubChapter(title: title, content: _stripHtml(html), spineHref: href));
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
