import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/book.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import 'i_pdf_service.dart';
import 'i_preferences_service.dart';

/// Manages PDF imports: copies files to app storage, persists metadata as JSON.
/// The pages themselves are rendered on demand from the file by the PDF reader.
class PdfService implements IPdfService {
  PdfService(this._prefs) {
    _load();
  }

  final IPreferencesService _prefs;
  final List<_PdfMeta> _imported = [];

  // ── Persistence ───────────────────────────────────────────────────────

  void _load() {
    final raw = _prefs.getString(PrefKeys.importedPdfs);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _imported.addAll(
        list.map((e) => _PdfMeta.fromJson(e as Map<String, dynamic>)),
      );
    } catch (_) {
      _imported.clear();
    }
  }

  Future<void> _persist() {
    final payload = jsonEncode(_imported.map((m) => m.toJson()).toList());
    return _prefs.setString(PrefKeys.importedPdfs, payload);
  }

  // ── Directory ─────────────────────────────────────────────────────────

  Future<Directory> _pdfDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/pdfs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // ── IPdfService ───────────────────────────────────────────────────────

  @override
  Future<Book> import(String sourcePath, {String? category}) async {
    final source = File(sourcePath);
    final dir = await _pdfDir();

    // Generate a unique filename.
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalName = source.uri.pathSegments.last;
    final sanitized = originalName
        .replaceAll(RegExp(r'[^\w.\-]'), '_')
        .toLowerCase();
    final destPath = '${dir.path}/${timestamp}_$sanitized';

    // Copy file.
    await source.copy(destPath);

    // Get page count from the PDF.
    int pages = 0;
    try {
      final doc = await PdfDocument.openFile(destPath);
      pages = doc.pages.length;
      doc.dispose();
    } catch (_) {
      // If we can't read the PDF, default to 0.
    }

    // Build metadata.
    final title = originalName
        .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[_\-]'), ' ')
        .trim();
    final id = 'pdf_$timestamp';
    final gradientIndex = _imported.length % AppColors.pdfGradients.length;

    final meta = _PdfMeta(
      id: id,
      title: title.isEmpty ? 'Imported PDF' : title,
      filePath: destPath,
      gradientIndex: gradientIndex,
      importedAt: timestamp,
      category: category ?? 'Imported',
      pageCount: pages,
    );

    _imported.add(meta);
    await _persist();

    return _metaToBook(meta);
  }

  @override
  List<Book> getImportedBooks() {
    return _imported.map(_metaToBook).toList();
  }

  @override
  Future<void> delete(String bookId) async {
    final idx = _imported.indexWhere((m) => m.id == bookId);
    if (idx == -1) return;

    // Remove file from disk.
    final file = File(_imported[idx].filePath);
    if (await file.exists()) {
      await file.delete();
    }

    _imported.removeAt(idx);
    await _persist();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Book _metaToBook(_PdfMeta meta) {
    final gradient = AppColors.pdfGradients[
        meta.gradientIndex % AppColors.pdfGradients.length];
    return Book(
      id: meta.id,
      title: meta.title,
      author: 'PDF Import',
      synopsis: 'Imported PDF document.',
      coverGradient: gradient,
      chapters: const [],
      category: meta.category,
      pdfPath: meta.filePath,
      pageCount: meta.pageCount,
    );
  }

  @override
  Future<void> updateCategory(String bookId, String category) async {
    final idx = _imported.indexWhere((m) => m.id == bookId);
    if (idx == -1) return;
    final old = _imported[idx];
    _imported[idx] = _PdfMeta(
      id: old.id,
      title: old.title,
      filePath: old.filePath,
      gradientIndex: old.gradientIndex,
      importedAt: old.importedAt,
      category: category,
      pageCount: old.pageCount,
    );
    await _persist();
  }
}

/// Internal metadata for a single imported PDF.
class _PdfMeta {
  const _PdfMeta({
    required this.id,
    required this.title,
    required this.filePath,
    required this.gradientIndex,
    required this.importedAt,
    this.category = 'Imported',
    this.pageCount = 0,
  });

  final String id;
  final String title;
  final String filePath;
  final int gradientIndex;
  final int importedAt;
  final String category;
  final int pageCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'gradientIndex': gradientIndex,
        'importedAt': importedAt,
        'category': category,
        'pageCount': pageCount,
      };

  factory _PdfMeta.fromJson(Map<String, dynamic> json) => _PdfMeta(
        id: json['id'] as String,
        title: json['title'] as String,
        filePath: json['filePath'] as String,
        gradientIndex: (json['gradientIndex'] as num).toInt(),
        importedAt: (json['importedAt'] as num).toInt(),
        category: json['category'] as String? ?? 'Imported',
        pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
      );
}
