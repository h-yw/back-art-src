
import 'package:BackArt/config/platform.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SizeSelectorPanel extends ConsumerWidget {
  const SizeSelectorPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPlatforms = {...platformSize, ...platformSizeChina};
    final platformNames = allPlatforms.keys.toList();

    // Get current device size
    final mediaQuery = MediaQuery.of(context);
    final deviceSize = mediaQuery.size * mediaQuery.devicePixelRatio;

    return ListView.builder(
      // Add 1 for the current device size option
      itemCount: platformNames.length + 1,
      itemBuilder: (context, index) {
        // First item is the current device size
        if (index == 0) {
          return ListTile(
            title: const Text('Current Device'),
            subtitle: Text('${deviceSize.width.toInt()} x ${deviceSize.height.toInt()}'),
            onTap: () {
              ref.read(canvasStateProvider.notifier).setCanvasSize(deviceSize);
              Navigator.of(context).pop();
            },
          );
        }

        // The rest are from the predefined list
        final platformName = platformNames[index - 1];
        final sizes = allPlatforms[platformName]!;

        return ExpansionTile(
          title: Text(platformName),
          children: sizes.map((sizeData) {
            final size = sizeData['size'] as Size;
            final name = sizeData['name'] as String;
            final ratio = sizeData['ratio'] as String? ?? '';

            return ListTile(
              title: Text(name),
              subtitle: Text('${size.width.toInt()} x ${size.height.toInt()}  ($ratio)'),
              onTap: () {
                ref.read(canvasStateProvider.notifier).setCanvasSize(size);
                Navigator.of(context).pop(); // Close the bottom sheet
              },
            );
          }).toList(),
        );
      },
    );
  }
}
