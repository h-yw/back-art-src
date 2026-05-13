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
    ImageLayer imageLayer, {
    ImageReplacementMode mode = ImageReplacementMode.preserveFrame,
  }) async {
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
        .replaceImageLayer(imageLayer.id, image, mode: mode);
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
        Text('替换图片', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => _replaceImage(context, ref, layer),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('保持当前框'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _replaceImage(
                context,
                ref,
                layer,
                mode: ImageReplacementMode.fitCanvas,
              ),
              icon: const Icon(Icons.fit_screen_outlined),
              label: const Text('替换后适应'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _replaceImage(
                context,
                ref,
                layer,
                mode: ImageReplacementMode.fillCanvas,
              ),
              icon: const Icon(Icons.crop_free_outlined),
              label: const Text('替换后铺满'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('布局', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => canvasNotifier.fitImageLayerToCanvas(layer.id),
              icon: const Icon(Icons.fit_screen_outlined),
              label: const Text('适应画布'),
            ),
            FilledButton.tonalIcon(
              onPressed: () =>
                  canvasNotifier.fitImageLayerToCanvas(layer.id, cover: true),
              icon: const Icon(Icons.crop_free_outlined),
              label: const Text('铺满画布'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  canvasNotifier.resetImageLayerToIntrinsicSize(layer.id),
              icon: const Icon(Icons.aspect_ratio_outlined),
              label: const Text('原始尺寸'),
            ),
          ],
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
