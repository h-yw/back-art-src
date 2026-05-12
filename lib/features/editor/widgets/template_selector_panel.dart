import 'package:BackArt/config/templates.dart'; // 导入模板函数
import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/editor/state/editor_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TemplateSelectorPanel extends ConsumerWidget {
  const TemplateSelectorPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasNotifier = ref.read(canvasStateProvider.notifier);

    final templates = {
      TemplateEnum.blank.label: () => blankTemplate(),
      TemplateEnum.emoji.label: () => playfulEmojiTemplate(),
      TemplateEnum.modern.label: () => modernMinimalistTemplate(),
      TemplateEnum.sunset.label: () => sunsetGradientTemplate(),
      TemplateEnum.tech.label: () => techTitleTemplate(),
      TemplateEnum.abstract.label: () => abstractGeometryTemplate(),
      TemplateEnum.cyberpunk.label: () => cyberpunkTemplate(),
      TemplateEnum.retro.label: () => retroPosterTemplate(),
    };

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('选择模板', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: templates.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  subtitle: Text('这是一个${entry.key}模板'),
                  onTap: () {
                    final templateContent = entry.value();
                    canvasNotifier.applyTemplate(templateContent);
                    final firstEditableLayer = templateContent.contentLayers
                        .firstWhere(
                          (layer) => layer is! BackgroundLayer,
                          orElse: () => templateContent.background,
                        );
                    ref.read(selectedLayerProvider.notifier).state =
                        firstEditableLayer.id;
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
