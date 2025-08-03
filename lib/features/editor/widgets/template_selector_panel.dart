// lib/features/editor/widgets/template_selector_panel.dart
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/config/templates.dart'; // 导入模板函数
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../canvas/model/layer.dart';
import '../view/editor_screen.dart';

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