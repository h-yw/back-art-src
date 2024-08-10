import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SlidePicker extends StatefulWidget {
  const SlidePicker(
      {Key? key, required this.pickerColor, required this.onColorChanged})
      : super(key: key);
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  @override
  State<StatefulWidget> createState() => _SlidePickerState();
}

class _SlidePickerState extends State<SlidePicker> {
  HSVColor currentHsvColor = const HSVColor.fromAHSV(0.0, 0.0, 0.0, 0.0);

  @override
  void initState() {
    super.initState();
    currentHsvColor = HSVColor.fromColor(widget.pickerColor);
  }

  @override
  void didUpdateWidget(SlidePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    currentHsvColor = HSVColor.fromColor(widget.pickerColor);
  }

  String getColorParams(int pos) {
    final Color color = currentHsvColor.toColor();
    return [
      color.red.toString(),
      color.green.toString(),
      color.blue.toString(),
      '${(color.opacity * 100).round()}',
    ][pos];
  }

  @override
  Widget build(BuildContext context) {
    final List<TrackType> trackTypes = [
      TrackType.red,
      TrackType.green,
      TrackType.blue
    ];
    List<SizedBox> sliders = [
      for (TrackType trackType in trackTypes)
        SizedBox(
          width: 260,
          height: 40,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  trackType.toString().split('.').last[0].toUpperCase(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Expanded(child: colorPickerSlider(trackType)),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 14 * 2 + 5),
                child: Text(
                  getColorParams(trackTypes.indexOf(trackType)),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
    ];

    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      // crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        indicator(),
        ...sliders,
        const SizedBox(height: 20.0),
      ],
    );
  }

  Widget colorPickerSlider(TrackType trackType) {
    return ColorPickerSlider(
      trackType,
      currentHsvColor,
      (HSVColor color) {
        setState(() => currentHsvColor = color);
        widget.onColorChanged(currentHsvColor.toColor());
      },
      displayThumbColor: true,
      fullThumbColor: true,
    );
  }

  Widget indicator() {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.zero),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: GestureDetector(
        onTap: () {
          setState(
              () => currentHsvColor = HSVColor.fromColor(widget.pickerColor));
          widget.onColorChanged(currentHsvColor.toColor());
        },
        child: Container(
          width: 280,
          height: 40,
          margin: const EdgeInsets.only(bottom: 15),
          foregroundDecoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  widget.pickerColor,
                  widget.pickerColor,
                  currentHsvColor.toColor(),
                  currentHsvColor.toColor()
                ],
                begin: const Alignment(-1, -3),
                end: const Alignment(1, 3),
                stops: const [0.0, 0.5, 0.5, 1]),
          ),
          child: const CustomPaint(
            painter: CheckerPainter(),
          ),
        ),
      ),
    );
  }
}
