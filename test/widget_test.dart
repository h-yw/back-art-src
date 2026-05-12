import 'package:BackArt/config/templates.dart';
import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reorders editable layers from the top-to-bottom drawer order', () {
    final notifier = CanvasStateNotifier();
    notifier
      ..addLayer(TextLayer.initial().copyWith(text: 'Middle'))
      ..addLayer(TextLayer.initial().copyWith(text: 'Top'));

    final topToBottom = notifier.state.layers
        .where((layer) => layer is! BackgroundLayer)
        .toList()
        .reversed
        .toList();
    final movedTopToBottom = List<Layer>.from(topToBottom);
    final movedLayer = movedTopToBottom.removeAt(0);
    movedTopToBottom.add(movedLayer);

    notifier.reorderLayersTopToBottom(
      movedTopToBottom.map((layer) => layer.id).toList(),
    );

    final bottomToTopIds = notifier.state.layers
        .where((layer) => layer is! BackgroundLayer)
        .map((layer) => layer.id);
    expect(bottomToTopIds, movedTopToBottom.reversed.map((layer) => layer.id));
  });

  test('template application keeps a single background layer', () {
    final notifier = CanvasStateNotifier();

    notifier.applyTemplate(retroPosterTemplate());

    expect(notifier.state.layers.whereType<BackgroundLayer>(), hasLength(1));
  });

  testWidgets('renders the editor toolbar', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BackArtApp()));

    expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}
