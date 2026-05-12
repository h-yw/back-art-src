import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SelectedLayerType { none, text, image, shape, background }

final selectedLayerProvider = StateProvider<String?>((ref) {
  final layers = ref.read(canvasStateProvider).layers;
  final firstEditableLayer = layers.firstWhere(
    (layer) => layer is! BackgroundLayer,
    orElse: () => layers.last,
  );
  return firstEditableLayer.id;
});
