// lib/features/editor/widgets/unicode_emoji_selector_panel.dart

import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnicodeEmojiSelectorPanel extends ConsumerWidget {
  const UnicodeEmojiSelectorPanel({Key? key}) : super(key: key);

  // 定义一个常用的 Unicode Emoji 列表
  // 您可以随意增删这里的表情
  static const List<String> _emojis = [
    '😂', '😍', '😭', '😊', '🤔', '🔥', '💯', '👍', '🎉', '❤️',
    '💀', '✨', '⭐', '🚀', '👋', '🙏', '🤯', '🥳', '😇', '😎',
    '😜', '🙈', '💰', '🍓', '🥑', '🍔', '🍕', '🍦', '🍺', '🎁',
  ];

  void _addEmojiToCanvas(String emoji, WidgetRef ref, BuildContext context) {
    // 创建一个特殊的 TextLayer 来承载 Emoji
    final emojiLayer = TextLayer.initial().copyWith(
      text: emoji,
      // 为 Emoji 设置一个默认的大尺寸和样式
      // 关键：将颜色设为透明，这样才能显示 Emoji 的原生色彩
      style: const TextStyle(
        fontSize: 150,
        backgroundColor: Colors.transparent,
      ),
      // 将初始位置设置在画布中心
      rect: const Rect.fromLTWH(400, 800, 150, 150),
    );

    ref.read(canvasStateProvider.notifier).addLayer(emojiLayer);

    // 添加后关闭面板
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6, // 每行显示更多 emoji
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _emojis.length,
      itemBuilder: (context, index) {
        final emoji = _emojis[index];
        return GestureDetector(
          onTap: () => _addEmojiToCanvas(emoji, ref, context),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 32), // 面板中预览的字号
            ),
          ),
        );
      },
    );
  }
}