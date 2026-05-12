import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SelectedLayerType { none, text, image, shape, background }

String? nextEditableLayerId(
  List<Layer> layers, {
  required String currentLayerId,
}) {
  final currentIndex = layers.indexWhere((layer) => layer.id == currentLayerId);
  if (currentIndex == -1) return null;

  for (var index = currentIndex - 1; index >= 0; index--) {
    final layer = layers[index];
    if (layer is! BackgroundLayer) return layer.id;
  }
  for (var index = currentIndex + 1; index < layers.length; index++) {
    final layer = layers[index];
    if (layer is! BackgroundLayer) return layer.id;
  }
  return null;
}

final selectedLayerProvider = StateProvider<String?>((ref) {
  final layers = ref.read(canvasStateProvider).layers;
  final firstEditableLayer = layers.firstWhere(
    (layer) => layer is! BackgroundLayer,
    orElse: () => layers.last,
  );
  return firstEditableLayer.id;
});
