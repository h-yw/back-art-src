import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/editor/state/editor_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ImageEditorPanel extends ConsumerWidget {
  const ImageEditorPanel({Key? key}) : super(key: key);

  Future<void> _replaceImage(
    BuildContext context,
    WidgetRef ref,
    ImageLayer imageLayer,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }

    final data = await pickedFile.readAsBytes();
    final image = await _bytesToImage(data);
    if (!context.mounted) {
      return;
    }

    ref
        .read(canvasStateProvider.notifier)
        .updateLayer(imageLayer.copyWith(image: image));
  }

  Future<ui.Image> _bytesToImage(Uint8List data) async {
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLayerId = ref.watch(selectedLayerProvider);
    final canvasNotifier = ref.read(canvasStateProvider.notifier);
    final layer = ref
        .watch(canvasStateProvider)
        .layers
        .firstWhere(
          (l) => l.id == selectedLayerId,
          orElse: () => TextLayer.initial(),
        );

    if (layer is! ImageLayer) {
      return const Center(child: Text('Please select an image layer.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('编辑图片', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _replaceImage(context, ref, layer),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('替换图片'),
        ),
        const SizedBox(height: 24),
        Text('透明度', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: layer.opacity.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: '${(layer.opacity * 100).round()}%',
                onChanged: (value) {
                  canvasNotifier.updateLayerLive(
                    layer.copyWith(opacity: value),
                  );
                },
                onChangeEnd: (_) {
                  canvasNotifier.commitLiveUpdate();
                },
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '${(layer.opacity * 100).round()}%',
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
