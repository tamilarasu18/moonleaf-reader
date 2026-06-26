import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../models/book.dart';
import '../../utils/constants.dart';
import '../../utils/extensions.dart';

/// A dedicated reader view for imported PDF books, powered by pdfrx.
/// Provides a full-screen, dark-themed PDF viewing experience.
class PdfReaderView extends StatefulWidget {
  const PdfReaderView({super.key, required this.book});

  final Book book;

  @override
  State<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<PdfReaderView> {
  bool _controlsVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!widget.book.isPdf) {
      return const Scaffold(
        body: Center(child: Text('Error: Not a PDF book.')),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.surface,
      extendBodyBehindAppBar: true,
      appBar: _controlsVisible
          ? AppBar(
              backgroundColor: context.colors.surface.withValues(alpha: 0.9),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.book.title,
                style: TextStyle(
                  fontFamily: AppConstants.fontUi,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.colors.onSurface,
                ),
              ),
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _controlsVisible = !_controlsVisible),
        child: PdfViewer.file(
          widget.book.pdfPath!,
          params: PdfViewerParams(
            backgroundColor: context.colors.surface,
            // Night mode could be implemented here using color filters if desired,
            // but for now we just show the PDF as-is on a dark background.
          ),
        ),
      ),
    );
  }
}
