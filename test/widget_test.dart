import 'dart:io';

import 'package:BackArt/config/templates.dart';
import 'package:BackArt/features/canvas/data/canvas_draft_repository.dart';
import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/editor/state/editor_state.dart';
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

  test('saves and restores a text and shape draft', () async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'back_art_draft_test_',
    );
    addTearDown(() => tempDirectory.deleteSync(recursive: true));

    final repository = CanvasDraftRepository(baseDirectory: tempDirectory);
    final state = CanvasState(
      canvasSize: const Size(800, 1200),
      layers: [
        const BackgroundLayer(id: 'background', color: Colors.black),
        TextLayer.initial().copyWith(id: 'title', text: 'Restored draft'),
        ShapeLayer.initial().copyWith(
          id: 'shape',
          shapeType: ShapeType.circle,
          color: Colors.red,
          paintStyle: PaintingStyle.stroke,
          strokeWidth: 8,
        ),
      ],
    );

    await repository.save(state);
    final restored = await repository.load();

    expect(restored, isNotNull);
    expect(restored!.canvasSize, const Size(800, 1200));
    expect(restored.layers, hasLength(3));
    expect((restored.layers[1] as TextLayer).text, 'Restored draft');
    expect((restored.layers[2] as ShapeLayer).shapeType, ShapeType.circle);
    expect((restored.layers[2] as ShapeLayer).paintStyle, PaintingStyle.stroke);
  });

  test('canvas provider can start from a restored draft', () {
    final initialState = CanvasState(
      layers: [
        const BackgroundLayer(id: 'background'),
        TextLayer.initial().copyWith(id: 'selected', text: 'Draft'),
      ],
    );
    final container = ProviderContainer(
      overrides: [initialCanvasStateProvider.overrideWithValue(initialState)],
    );
    addTearDown(container.dispose);

    expect(
      (container.read(canvasStateProvider).layers[1] as TextLayer).text,
      'Draft',
    );
    expect(container.read(selectedLayerProvider), 'selected');
  });

  testWidgets('renders the editor toolbar', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BackArtApp()));

    expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}
