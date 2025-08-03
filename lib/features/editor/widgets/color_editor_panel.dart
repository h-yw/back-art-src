// File: lib/features/editor/widgets/color_editor_panel.dart
import 'dart:math';

import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/editor/widgets/compact-alignment-selector.dart';
import 'package:BackArt/utils/gradients.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ColorEditorPanel extends ConsumerStatefulWidget {
  const ColorEditorPanel({Key? key}) : super(key: key);

  @override
  _ColorEditorPanelState createState() => _ColorEditorPanelState();
}

class _ColorEditorPanelState extends ConsumerState<ColorEditorPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GradientsGenerator _gradientsGenerator = GradientsGenerator();

  final List<Alignment> _alignments = [
    Alignment.topLeft, Alignment.topCenter, Alignment.topRight,
    Alignment.centerLeft, Alignment.center, Alignment.centerRight,
    Alignment.bottomLeft, Alignment.bottomCenter, Alignment.bottomRight,
  ];

  Alignment _selectedBeginAlignment = Alignment.topLeft;
  Alignment _selectedEndAlignment = Alignment.bottomRight;
  GradientType _selectedGradientType = GradientType.linear;
  Alignment _selectedCenterAlignment = Alignment.center; // 新增，用于径向和扫描渐变

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasNotifier = ref.read(canvasStateProvider.notifier);
    final backgroundLayer = ref.watch(canvasStateProvider).layers.firstWhere(
          (l) => l is BackgroundLayer,
      orElse: () => BackgroundLayer.initial(),
    ) as BackgroundLayer;

    final solidPickerColor = backgroundLayer.color;
    final gradientPickerColors = (backgroundLayer.gradient is LinearGradient)
        ? (backgroundLayer.gradient as LinearGradient).colors
        : (backgroundLayer.gradient is RadialGradient)
        ? (backgroundLayer.gradient as RadialGradient).colors
        : (backgroundLayer.gradient is SweepGradient)
        ? (backgroundLayer.gradient as SweepGradient).colors
        : <Color>[Colors.blue, Colors.red];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Solid'),
              Tab(text: 'Gradient'),
            ],
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: [
                _buildSolidColorPicker(backgroundLayer, canvasNotifier, solidPickerColor),
                _buildGradientPicker(backgroundLayer, canvasNotifier, gradientPickerColors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolidColorPicker(BackgroundLayer layer, CanvasStateNotifier notifier, Color solidPickerColor) {
    return SlidePicker(
      pickerColor: solidPickerColor,
      onColorChanged: (newColor) {
        notifier.updateLayer(
          layer.copyWith(color: newColor, gradient: null, setGradient: true),
        );
      },
    );
  }

  Widget _buildGradientPicker(BackgroundLayer layer, CanvasStateNotifier notifier, List<Color> gradientPickerColors) {
    return ListView(
      padding: const EdgeInsets.only(top: 16.0),
      children: [
        _buildSectionTitle('渐变形状'),
        Center(
          child: ToggleButtons(
            isSelected: GradientType.values.map((type) => type == _selectedGradientType).toList(),
            onPressed: (index) {
              final newType = GradientType.values[index];
              setState(() {
                _selectedGradientType = newType;
              });
              _updateGradient(notifier, layer, gradientPickerColors, newType);
            },
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('线性')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('径向')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('扫描')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.shuffle),
            label: const Text("随机生成渐变"),
            onPressed: () {
              _gradientsGenerator.generateRandomPalette();
              if (_gradientsGenerator.palette.isNotEmpty) {
                final newGradientColors = _gradientsGenerator.palette.map((e) => e.toColor()).toList();

                Gradient newGradient;
                if (_selectedGradientType == GradientType.linear) {
                  newGradient = LinearGradient(
                    colors: newGradientColors,
                    begin: _selectedBeginAlignment,
                    end: _selectedEndAlignment,
                  );
                } else if (_selectedGradientType == GradientType.radial) {
                  newGradient = RadialGradient(
                    colors: newGradientColors,
                    center: _alignments[_gradientsGenerator.generatorRandomInt(min: 0, max: _alignments.length)],
                  );
                } else {
                  newGradient = SweepGradient(
                    colors: newGradientColors,
                    center: _alignments[_gradientsGenerator.generatorRandomInt(min: 0, max: _alignments.length)],
                  );
                }

                notifier.updateLayer(
                  layer.copyWith(gradient: newGradient, setGradient: true),
                );
              }
            },
          ),
        ),
        _buildSectionTitle('起始颜色'),
        SlidePicker(
          pickerColor: gradientPickerColors[0],
          onColorChanged: (newColor) {
            final newColors = List<Color>.from(gradientPickerColors);
            newColors[0] = newColor;
            _updateGradient(notifier, layer, newColors, _selectedGradientType);
          },
        ),
        if (gradientPickerColors.length > 2) ...[
          _buildSectionTitle('中间颜色'),
          for (int i = 1; i < gradientPickerColors.length - 1; i++)
            _buildColorPicker(i, gradientPickerColors, notifier, layer),
        ],
        _buildSectionTitle('结束颜色'),
        SlidePicker(
          pickerColor: gradientPickerColors.last,
          onColorChanged: (newColor) {
            final newColors = List<Color>.from(gradientPickerColors);
            newColors[gradientPickerColors.length - 1] = newColor;
            _updateGradient(notifier, layer, newColors, _selectedGradientType);
          },
        ),
        if (_selectedGradientType == GradientType.linear) Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("其实方向"),
                CompactAlignmentSelector(
                  // '起始方向',
                  selectedAlignment:_selectedBeginAlignment,
                  onAlignmentSelected:   (newAlignment) {
                    setState(() => _selectedBeginAlignment = newAlignment);
                    _updateGradient(notifier, layer, gradientPickerColors, GradientType.linear);
                  },
                ),
              ],
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("结束方向"),
                CompactAlignmentSelector(
                  // '结束方向',
                  selectedAlignment: _selectedEndAlignment,
                  onAlignmentSelected:(newAlignment) {
                    setState(() => _selectedEndAlignment = newAlignment);
                    _updateGradient(notifier, layer, gradientPickerColors, GradientType.linear);
                  },
                ),
              ],
            )
          ],
        ),
        if (_selectedGradientType == GradientType.radial || _selectedGradientType == GradientType.sweep) Column(
         crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('中心点'),
            CompactAlignmentSelector(
              selectedAlignment:  _selectedCenterAlignment,
              onAlignmentSelected:    (newAlignment) {
                setState(() => _selectedCenterAlignment = newAlignment);
                _updateGradient(notifier, layer, gradientPickerColors, _selectedGradientType);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _updateGradient(CanvasStateNotifier notifier, BackgroundLayer layer, List<Color> colors, GradientType type) {
    Gradient newGradient;
    if (type == GradientType.linear) {
      newGradient = LinearGradient(
        colors: colors,
        begin: _selectedBeginAlignment,
        end: _selectedEndAlignment,
      );
    } else if (type == GradientType.radial) {
      newGradient = RadialGradient(
        colors: colors,
        center: Alignment.center,
      );
    } else { // SweepGradient
      newGradient = SweepGradient(
        colors: colors,
        center: Alignment.center,
      );
    }
    notifier.updateLayer(
      layer.copyWith(gradient: newGradient, setGradient: true),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildColorPicker(int index, List<Color> colors, CanvasStateNotifier notifier, BackgroundLayer layer) {
    return SlidePicker(
      pickerColor: colors[index],
      onColorChanged: (newColor) {
        final newColors = List<Color>.from(colors);
        newColors[index] = newColor;
        _updateGradient(notifier, layer, newColors, _selectedGradientType);
      },
    );
  }

  Widget _buildAlignmentSelector(String title, Alignment selectedAlignment, ValueChanged<Alignment> onAlignmentSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
          children: _alignments.map((alignment) {
            final isSelected = selectedAlignment == alignment;
            return InkWell(
              onTap: () => onAlignmentSelected(alignment),
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : null,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent),
                ),
                child: Icon(_getIconForAlignment(alignment)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getIconForAlignment(Alignment alignment) {
    if (alignment == Alignment.topLeft) return Icons.north_west_rounded;
    if (alignment == Alignment.topCenter) return Icons.north_rounded;
    if (alignment == Alignment.topRight) return Icons.north_east_rounded;
    if (alignment == Alignment.centerLeft) return Icons.west_rounded;
    if (alignment == Alignment.center) return Icons.center_focus_strong_rounded;
    if (alignment == Alignment.centerRight) return Icons.east_rounded;
    if (alignment == Alignment.bottomLeft) return Icons.south_west_rounded;
    if (alignment == Alignment.bottomCenter) return Icons.south_rounded;
    if (alignment == Alignment.bottomRight) return Icons.south_east_rounded;
    return Icons.place;
  }
}