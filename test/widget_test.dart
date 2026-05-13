import 'dart:io';
import 'dart:ui' as ui;

import 'package:BackArt/config/templates.dart';
import 'package:BackArt/features/canvas/data/canvas_draft_repository.dart';
import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/canvas/view/canvas_view.dart';
import 'package:BackArt/features/editor/state/editor_state.dart';
import 'package:BackArt/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<ui.Image> createSizedTestImage(int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.blue;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );
    final picture = recorder.endRecording();
    return picture.toImage(width, height);
  }

  Future<ui.Image> createTestImage() async {
    return createSizedTestImage(40, 40);
  }

  setUp(() {
    resetLayerIdCounterForTest();
  });

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

  test('fits and fills image layers relative to the canvas', () async {
    final notifier = CanvasStateNotifier(
      initialState: CanvasState(
        canvasSize: const Size(1080, 1920),
        layers: [
          const BackgroundLayer(id: 'background'),
          ImageLayer(
            id: 'image',
            image: await createTestImage(),
            rect: const Rect.fromLTWH(0, 0, 40, 40),
          ),
        ],
      ),
    );

    expect(notifier.fitImageLayerToCanvas('image'), isTrue);
    final fittedLayer = notifier.state.layers[1] as ImageLayer;
    expect(fittedLayer.rect.width, 1080);
    expect(fittedLayer.rect.height, 1080);
    expect(fittedLayer.rect.center, const Offset(540, 960));
    expect(fittedLayer.scale, 1.0);

    expect(notifier.fitImageLayerToCanvas('image', cover: true), isTrue);
    final filledLayer = notifier.state.layers[1] as ImageLayer;
    expect(filledLayer.rect.width, 1920);
    expect(filledLayer.rect.height, 1920);
    expect(filledLayer.rect.center, const Offset(540, 960));
  });

  test('adds imported images without enlarging smaller sources', () async {
    final notifier = CanvasStateNotifier(
      initialState: const CanvasState(
        canvasSize: Size(1080, 1920),
        layers: [BackgroundLayer(id: 'background')],
      ),
    );

    notifier.addImageFromImage(await createSizedTestImage(200, 100));

    final imageLayer = notifier.state.layers[1] as ImageLayer;
    expect(imageLayer.rect.size, const Size(200, 100));
    expect(imageLayer.rect.center, const Offset(540, 960));
    expect(imageLayer.scale, 1.0);
  });

  test('computes image source rects for framing controls', () {
    final sourceRect = sourceRectForImageFrame(
      imageSize: const Size(200, 100),
      frameSize: const Size(100, 100),
    );
    expect(sourceRect, const Rect.fromLTWH(50, 0, 100, 100));

    final zoomedRect = sourceRectForImageFrame(
      imageSize: const Size(200, 100),
      frameSize: const Size(100, 100),
      cropScale: 2.0,
      cropAlignment: Alignment.topLeft,
    );
    expect(zoomedRect, const Rect.fromLTWH(0, 0, 50, 50));
  });

  test('resets image layers to their intrinsic size', () async {
    final notifier = CanvasStateNotifier(
      initialState: CanvasState(
        layers: [
          const BackgroundLayer(id: 'background'),
          ImageLayer(
            id: 'image',
            image: await createTestImage(),
            rect: const Rect.fromLTWH(100, 200, 400, 600),
            scale: 2.0,
          ),
        ],
      ),
    );

    expect(notifier.resetImageLayerToIntrinsicSize('image'), isTrue);
    final imageLayer = notifier.state.layers[1] as ImageLayer;
    expect(imageLayer.rect.size, const Size(40, 40));
    expect(imageLayer.rect.center, const Offset(300, 500));
    expect(imageLayer.scale, 1.0);
  });

  test('replaces image layers with explicit layout strategies', () async {
    final notifier = CanvasStateNotifier(
      initialState: CanvasState(
        canvasSize: const Size(1080, 1920),
        layers: [
          const BackgroundLayer(id: 'background'),
          ImageLayer(
            id: 'image',
            image: await createSizedTestImage(40, 40),
            rect: const Rect.fromLTWH(100, 200, 300, 500),
            scale: 1.5,
            alignment: Alignment.bottomRight,
          ),
        ],
      ),
    );
    final replacement = await createSizedTestImage(200, 100);

    expect(notifier.replaceImageLayer('image', replacement), isTrue);
    var imageLayer = notifier.state.layers[1] as ImageLayer;
    expect(imageLayer.rect, const Rect.fromLTWH(100, 200, 300, 500));
    expect(imageLayer.scale, 1.5);
    expect(imageLayer.alignment, Alignment.bottomRight);
    expect(imageLayer.image.width, 200);
    expect(imageLayer.image.height, 100);

    expect(
      notifier.replaceImageLayer(
        'image',
        replacement,
        mode: ImageReplacementMode.fitCanvas,
      ),
      isTrue,
    );
    imageLayer = notifier.state.layers[1] as ImageLayer;
    expect(imageLayer.rect.width, 1080);
    expect(imageLayer.rect.height, 540);
    expect(imageLayer.rect.center, const Offset(540, 960));
    expect(imageLayer.scale, 1.0);
    expect(imageLayer.alignment, isNull);

    expect(
      notifier.replaceImageLayer(
        'image',
        replacement,
        mode: ImageReplacementMode.fillCanvas,
      ),
      isTrue,
    );
    imageLayer = notifier.state.layers[1] as ImageLayer;
    expect(imageLayer.rect.width, 3840);
    expect(imageLayer.rect.height, 1920);
    expect(imageLayer.rect.center, const Offset(540, 960));
  });

  test('syncs the layer id counter with restored draft ids', () {
    final notifier = CanvasStateNotifier(
      initialState: CanvasState(
        layers: [
          const BackgroundLayer(id: 'layer_8'),
          TextLayer.initial().copyWith(id: 'layer_9', text: 'Restored'),
        ],
      ),
    );

    notifier.addLayer(TextLayer.initial().copyWith(text: 'New layer'));

    final ids = notifier.state.layers.map((layer) => layer.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids.last, 'layer_10');
  });

  test('normalizes duplicate ids from initial state', () {
    final notifier = CanvasStateNotifier(
      initialState: CanvasState(
        layers: [
          const BackgroundLayer(id: 'layer_1'),
          TextLayer.initial().copyWith(id: 'layer_2', text: 'First'),
          TextLayer.initial().copyWith(id: 'layer_2', text: 'Second'),
        ],
      ),
    );

    final ids = notifier.state.layers.map((layer) => layer.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, containsAll(['layer_1', 'layer_2', 'layer_3']));
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

  testWidgets('delete handle has a larger tap target', (tester) async {
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
    await tester.tapAt(const Offset(41, 25));
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      container.read(canvasStateProvider).layers.whereType<TextLayer>(),
      isEmpty,
    );
  });

  testWidgets('double tap on a text layer opens inline text editing', (
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

    expect(find.byKey(const ValueKey('inline-text-editor')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('inline-text-editor')),
      'Edited inline',
    );
    await tester.pump();

    expect(container.read(selectedLayerProvider), 'text');
    expect(
      (container.read(canvasStateProvider).layers[1] as TextLayer).text,
      'Edited inline',
    );
  });

  testWidgets('single tap switches layers without waiting for double tap', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        initialCanvasStateProvider.overrideWithValue(
          CanvasState(
            layers: [
              const BackgroundLayer(id: 'background'),
              TextLayer.initial().copyWith(
                id: 'first',
                rect: const Rect.fromLTWH(100, 100, 200, 100),
              ),
              TextLayer.initial().copyWith(
                id: 'second',
                rect: const Rect.fromLTWH(500, 100, 200, 100),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildCanvasTestApp(container));
    expect(container.read(selectedLayerProvider), 'first');

    await tester.tapAt(const Offset(140, 37.5));
    await tester.pump();

    expect(container.read(selectedLayerProvider), 'second');
  });

  test('snaps a dragged layer to the canvas center line', () {
    final layer = TextLayer.initial().copyWith(
      id: 'text',
      rect: const Rect.fromLTWH(100, 100, 200, 100),
    );
    final result = applySnapToRect(
      const Rect.fromLTWH(430, 100, 200, 100),
      layer,
      [const BackgroundLayer(id: 'background'), layer],
      const Size(1080, 1920),
      0.25,
    );

    expect(result.rect.center.dx, 540);
    expect(
      result.guides,
      contains(
        isA<SnapGuide>()
            .having((guide) => guide.axis, 'axis', SnapGuideAxis.vertical)
            .having((guide) => guide.coordinate, 'coordinate', 540),
      ),
    );
  });

  test('only enables snapping for translation-like transforms', () {
    expect(shouldSnapForTransform(scaleDelta: 1.0, rotationDelta: 0.0), isTrue);
    expect(
      shouldSnapForTransform(scaleDelta: 1.02, rotationDelta: 0.02),
      isTrue,
    );
    expect(
      shouldSnapForTransform(scaleDelta: 1.1, rotationDelta: 0.0),
      isFalse,
    );
    expect(
      shouldSnapForTransform(scaleDelta: 1.0, rotationDelta: 0.08),
      isFalse,
    );
  });

  test('updates image crop framing from canvas gestures', () async {
    final initialLayer = ImageLayer(
      id: 'image',
      image: await createSizedTestImage(200, 100),
      rect: const Rect.fromLTWH(100, 100, 100, 100),
      cropScale: 2.0,
      cropAlignment: Alignment.center,
    );

    final updatedLayer = applyCropGestureToImageLayer(
      initialLayer: initialLayer,
      translationInCanvas: const Offset(25, 10),
      scaleDelta: 1.5,
    );

    expect(updatedLayer.cropScale, 3.0);
    expect(updatedLayer.cropAlignment.x, closeTo(-0.1, 0.01));
    expect(updatedLayer.cropAlignment.y, closeTo(-0.1, 0.01));
  });

  testWidgets('renders the editor toolbar', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BackArtApp()));

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.text('添加'), findsOneWidget);
    expect(find.text('发布'), findsOneWidget);
    expect(find.text('更多'), findsOneWidget);
  });

  testWidgets('opens the layer drawer from the bottom toolbar button', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: BackArtApp()));

    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Background'), findsOneWidget);
  });

  testWidgets('opens the publish sheet with export presets', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BackArtApp()));

    await tester.tap(find.text('发布'));
    await tester.pumpAndSettle();

    expect(find.text('发布画布'), findsOneWidget);
    expect(find.text('PNG'), findsOneWidget);
    expect(find.text('JPG'), findsOneWidget);
    expect(find.text('标准'), findsOneWidget);
    expect(find.text('高清'), findsOneWidget);
    expect(find.text('超清'), findsOneWidget);
    expect(find.textContaining('输出 '), findsOneWidget);
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

  testWidgets('image layers expose the image editor as the primary action', (
    tester,
  ) async {
    final image = await createTestImage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialCanvasStateProvider.overrideWithValue(
            CanvasState(
              layers: [
                const BackgroundLayer(id: 'background'),
                ImageLayer(id: 'image', image: image),
              ],
            ),
          ),
        ],
        child: const BackArtApp(),
      ),
    );

    expect(find.text('图片'), findsOneWidget);

    await tester.tap(find.text('图片'));
    await tester.pumpAndSettle();

    expect(find.text('编辑图片'), findsOneWidget);
    expect(find.text('替换图片'), findsOneWidget);
    expect(find.text('保持当前框'), findsOneWidget);
    expect(find.text('替换后适应'), findsOneWidget);
    expect(find.text('替换后铺满'), findsOneWidget);
    expect(find.text('取景'), findsOneWidget);
    expect(find.text('进入取景模式'), findsOneWidget);
    await tester.tap(find.text('进入取景模式'));
    await tester.pumpAndSettle();
    expect(find.text('结束取景模式'), findsOneWidget);
    expect(find.text('重置取景'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('适应画布'), 200);
    await tester.pumpAndSettle();
    expect(find.text('适应画布'), findsOneWidget);
    expect(find.text('铺满画布'), findsOneWidget);
    expect(find.text('原始尺寸'), findsOneWidget);
    expect(find.text('透明度'), findsOneWidget);
  });
}
