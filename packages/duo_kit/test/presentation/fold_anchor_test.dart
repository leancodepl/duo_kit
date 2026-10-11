import 'dart:async';

import 'package:duo_kit/duo_kit.dart';
import 'package:duo_kit/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _homeKey = ValueKey('home');
const _routeKey = ValueKey('route');

/// Where the fold of the inner display starts and ends, from its top or left
/// edge.
const _foldStart = 455.5;
const _foldEnd = 495.5;

void main() {
  testWidgets('opens content in the trailing half across a vertical fold', (
    tester,
  ) async {
    await _pumpPose(tester, FoldTestPose.duoHalfOpenedLandscape);
    await _openDialog(tester, FoldAnchor.content);

    expect(_getRouteRect(tester).left, greaterThanOrEqualTo(_foldEnd));
  });

  testWidgets('opens content in the left half in right-to-left text', (
    tester,
  ) async {
    await _pumpPose(
      tester,
      FoldTestPose.duoHalfOpenedLandscape,
      textDirection: TextDirection.rtl,
    );
    await _openDialog(tester, FoldAnchor.content);

    expect(_getRouteRect(tester).right, lessThanOrEqualTo(_foldStart));
  });

  testWidgets('opens content above a horizontal fold', (tester) async {
    await _pumpPose(tester, FoldTestPose.duoHalfOpenedPortrait);
    await _openDialog(tester, FoldAnchor.content);

    expect(_getRouteRect(tester).bottom, lessThanOrEqualTo(_foldStart));
  });

  testWidgets('opens controls below a horizontal fold', (tester) async {
    await _pumpPose(tester, FoldTestPose.duoHalfOpenedPortrait);
    await _openSheet(tester, FoldAnchor.controls);

    expect(_getRouteRect(tester).top, greaterThanOrEqualTo(_foldEnd));
  });

  testWidgets('moves to its half when the device folds after it opened', (
    tester,
  ) async {
    await _pumpPose(tester, FoldTestPose.duoInnerLandscape);
    await _openDialog(tester, FoldAnchor.content);

    final flatRect = _getRouteRect(tester);
    expect(flatRect.left, lessThan(_foldStart));
    expect(flatRect.right, greaterThan(_foldEnd));

    await _pumpPose(tester, FoldTestPose.duoHalfOpenedLandscape);

    expect(_getRouteRect(tester).left, greaterThanOrEqualTo(_foldEnd));
  });
}

Future<void> _pumpPose(
  WidgetTester tester,
  FoldTestPose pose, {
  TextDirection textDirection = TextDirection.ltr,
}) async {
  tester.view
    ..physicalSize = pose.data.size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: pose.data,
        child: Directionality(
          textDirection: textDirection,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const SizedBox.expand(key: _homeKey),
    ),
  );
  await tester.pump();
}

Future<void> _openDialog(WidgetTester tester, FoldAnchor anchor) async {
  final context = tester.element(find.byKey(_homeKey));

  unawaited(
    showDialog<void>(
      context: context,
      anchorPoint: anchor.resolvePoint(context),
      builder: (_) => const SizedBox.expand(key: _routeKey),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester, FoldAnchor anchor) async {
  final context = tester.element(find.byKey(_homeKey));

  unawaited(
    showModalBottomSheet<void>(
      context: context,
      anchorPoint: anchor.resolvePoint(context),
      builder: (_) => const SizedBox.expand(key: _routeKey),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _getRouteRect(WidgetTester tester) =>
    tester.getRect(find.byKey(_routeKey));
