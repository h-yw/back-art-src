import 'dart:io';

import 'package:BackArt/config/templates.dart';
import 'package:BackArt/features/canvas/data/canvas_draft_repository.dart';
import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/canvas/view/canvas_view.dart';
import 'package:BackArt/features/editor/state/editor_state.dart';
import 'package:BackArt/features/editor/widgets/text_editor_panel.dart';
import 'package:BackArt/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildCanvasTestApp(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 270,
              height: 480,
              child: const CanvasView(canvasDisplaySize: Size(270, 480)),
            ),
          ),
        ),
      ),
    );
  }

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

  test('duplicates a text layer above the original with an offset', () {
    final notifier = CanvasStateNotifier();
    final originalLayer = TextLayer.initial().copyWith(
      id: 'original',
      text: 'Duplicate me',
      rect: const Rect.fromLTWH(100, 100, 200, 80),
    );
    notifier.addLayer(originalLayer);

    final duplicatedId = notifier.duplicateLayer('original');

    expect(duplicatedId, isNotNull);
    expect(notifier.state.layers.whereType<TextLayer>(), hasLength(3));

    final originalIndex = notifier.state.layers.indexWhere(
      (layer) => layer.id == 'original',
    );
    final duplicatedLayer =
        notifier.state.layers[originalIndex + 1] as TextLayer;
    expect(duplicatedLayer.id, duplicatedId);
    expect(duplicatedLayer.text, 'Duplicate me');
    expect(duplicatedLayer.rect.topLeft, const Offset(124, 124));
  });

  test('does not duplicate the background layer', () {
    final notifier = CanvasStateNotifier();

    final duplicatedId = notifier.duplicateLayer(
      notifier.state.layers.first.id,
    );

    expect(duplicatedId, isNull);
    expect(notifier.state.layers.whereType<BackgroundLayer>(), hasLength(1));
  });

  test('picks the previous editable layer after deleting the current one', () {
    final layers = [
      const BackgroundLayer(id: 'background'),
      TextLayer.initial().copyWith(id: 'first'),
      TextLayer.initial().copyWith(id: 'second'),
      ShapeLayer.initial().copyWith(id: 'third'),
    ];

    expect(nextEditableLayerId(layers, currentLayerId: 'third'), 'second');
    expect(nextEditableLayerId(layers, currentLayerId: 'first'), 'second');
    expect(
      nextEditableLayerId([
        const BackgroundLayer(id: 'background'),
        TextLayer.initial().copyWith(id: 'only'),
      ], currentLayerId: 'only'),
      isNull,
    );
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

  testWidgets('tap delete handle removes the selected layer', (tester) async {
    final container = ProviderContainer(
      overrides: [
        initialCanvasStateProvider.overrideWithValue(
          CanvasState(
            layers: [
              const BackgroundLayer(id: 'background'),
              TextLayer.initial().copyWith(
                id: 'text',
                rect: const Rect.fromLTWH(100, 100, 200, 100),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildCanvasTestApp(container));
    await tester.tapAt(const Offset(25, 25));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      container.read(canvasStateProvider).layers.whereType<TextLayer>(),
      isEmpty,
    );
    expect(container.read(selectedLayerProvider), isNull);
  });

  testWidgets('double tap on a text layer opens the text editor panel', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        initialCanvasStateProvider.overrideWithValue(
          CanvasState(
            layers: [
              const BackgroundLayer(id: 'background'),
              TextLayer.initial().copyWith(
                id: 'text',
                rect: const Rect.fromLTWH(100, 100, 200, 100),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildCanvasTestApp(container));
    await tester.tapAt(const Offset(50, 37.5));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(const Offset(50, 37.5));
    await tester.pumpAndSettle();

    expect(find.byType(TextEditorPanel), findsOneWidget);
    expect(container.read(selectedLayerProvider), 'text');
  });

  testWidgets('renders the editor toolbar', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BackArtApp()));

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.text('添加'), findsOneWidget);
    expect(find.text('发布'), findsOneWidget);
    expect(find.text('更多'), findsOneWidget);
  });

  testWidgets('opens the publish sheet with export presets', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BackArtApp()));

    await tester.tap(find.text('发布'));
    await tester.pumpAndSettle();

    expect(find.text('发布画布'), findsOneWidget);
    expect(find.text('快速分享'), findsOneWidget);
    expect(find.text('高清'), findsOneWidget);
    expect(find.text('打印级'), findsOneWidget);
    expect(find.text('保存到相册'), findsOneWidget);
    expect(find.text('分享'), findsOneWidget);
  });

  testWidgets('opens overflow actions from the compact toolbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialCanvasStateProvider.overrideWithValue(
            const CanvasState(layers: [BackgroundLayer(id: 'background')]),
          ),
        ],
        child: const BackArtApp(),
      ),
    );

    await tester.tap(find.text('更多'));
    await tester.pumpAndSettle();

    expect(find.text('模板'), findsOneWidget);
  });
}
