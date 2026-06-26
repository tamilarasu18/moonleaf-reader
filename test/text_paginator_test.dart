import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moonleaf/src/utils/text_paginator.dart';

void main() {
  const text =
      'It is a truth universally acknowledged, that a single man in possession '
      'of a good fortune, must be in want of a wife.\n\n'
      'However little known the feelings or views of such a man may be on his '
      'first entering a neighbourhood, this truth is so well fixed in the minds '
      'of the surrounding families, that he is considered the rightful property '
      'of some one or other of their daughters.\n\n'
      'My dear Mr. Bennet, said his lady to him one day, have you heard that '
      'Netherfield Park is let at last? Mr. Bennet replied that he had not. '
      'But it is, returned she; for Mrs. Long has just been here.';
  const style = TextStyle(fontSize: 19, height: 1.6);

  test('splits long text into multiple non-empty pages', () {
    final pages = TextPaginator.paginate(
      text: text,
      style: style,
      maxWidth: 300,
      firstPageHeight: 180,
      otherPageHeight: 220,
    );
    expect(pages.length, greaterThan(1));
    expect(pages.every((p) => p.trim().isNotEmpty), isTrue);
    // No content is lost or duplicated across pages (ignoring whitespace, since
    // page breaks fall on word boundaries).
    final joined = pages.join().replaceAll(RegExp(r'\s+'), '');
    final original = text.replaceAll(RegExp(r'\s+'), '');
    expect(joined, original);
  });

  test('returns a single page when everything fits', () {
    final pages = TextPaginator.paginate(
      text: 'Short.',
      style: style,
      maxWidth: 300,
      firstPageHeight: 400,
      otherPageHeight: 400,
    );
    expect(pages, ['Short.']);
  });
}
