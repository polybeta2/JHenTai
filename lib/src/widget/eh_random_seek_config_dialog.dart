import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jhentai/src/extension/widget_extension.dart';
import 'package:jhentai/src/model/random_seek_range.dart';
import 'package:jhentai/src/utils/route_util.dart';
import 'package:jhentai/src/widget/eh_wheel_speed_controller.dart';

import '../config/ui_config.dart';
import '../setting/random_seek_setting.dart';

class EHRandomSeekConfigDialog extends StatefulWidget {
  final List<RandomSeekRange> initialRanges;

  const EHRandomSeekConfigDialog({Key? key, required this.initialRanges}) : super(key: key);

  @override
  _EHRandomSeekConfigDialogState createState() => _EHRandomSeekConfigDialogState();
}

class _EHRandomSeekConfigDialogState extends State<EHRandomSeekConfigDialog> {
  final ScrollController _bodyScrollController = ScrollController();

  late final List<RandomSeekRange> ranges = widget.initialRanges
      .map((range) => RandomSeekRange(startYear: range.startYear, endYear: range.endYear, weight: range.weight))
      .toList();

  @override
  void dispose() {
    _bodyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 350,
        constraints: const BoxConstraints(maxHeight: 480),
        padding: const EdgeInsets.only(top: 20, bottom: 20, left: 12, right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildHeader(),
            buildHint(),
            Flexible(
              child: EHWheelSpeedController(
                controller: _bodyScrollController,
                child: ListView(
                  controller: _bodyScrollController,
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (int index = 0; index < ranges.length; index++) _buildRangeItem(index),
                  ],
                ),
              ),
            ),
            buildAddButton(),
          ],
        ),
      ),
    ).enableMouseDrag(withScrollBar: false);
  }

  Widget buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const IconButton(icon: Icon(Icons.close), onPressed: backRoute),
        Text('randomSeekSetting'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.check), onPressed: _checkAndBack),
      ],
    );
  }

  Widget buildHint() {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        'randomSeekSettingHint'.tr,
        style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
      ),
    );
  }

  Widget _buildRangeItem(int index) {
    RandomSeekRange range = ranges[index];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: UIConfig.groupListColor(context),
        boxShadow: [if (!Get.isDarkMode) UIConfig.groupListShadow(context)],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildYearField(range, isStart: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('to'.tr, style: const TextStyle(fontSize: 13)),
          ),
          _buildYearField(range, isStart: false),
          const Spacer(),
          _buildWeightDropdown(range),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: UIConfig.alertColor(context)),
            onPressed: () => setState(() => ranges.removeAt(index)),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildYearField(RandomSeekRange range, {required bool isStart}) {
    return SizedBox(
      width: 48,
      child: CupertinoTextField(
        controller: TextEditingController(text: (isStart ? range.startYear : range.endYear).toString()),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d'))],
        maxLength: 4,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
        onChanged: (value) {
          int? year = int.tryParse(value);
          if (year == null) {
            return;
          }
          setState(() {
            if (isStart) {
              range.startYear = year;
            } else {
              range.endYear = year;
            }
          });
        },
      ),
    );
  }

  Widget _buildWeightDropdown(RandomSeekRange range) {
    return DropdownButton<int>(
      value: range.weight,
      elevation: 4,
      onChanged: (int? newValue) => setState(() => range.weight = newValue!),
      items: RandomSeekWeight.values
          .map(
            (weight) => DropdownMenuItem(
              value: weight.value,
              child: Text(_weightLabel(weight), style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
    );
  }

  String _weightLabel(RandomSeekWeight weight) {
    switch (weight) {
      case RandomSeekWeight.disabled:
        return 'randomSeekDisabled'.tr;
      case RandomSeekWeight.low:
        return 'randomSeekWeightLow'.tr;
      case RandomSeekWeight.medium:
        return 'randomSeekWeightMedium'.tr;
      case RandomSeekWeight.high:
        return 'randomSeekWeightHigh'.tr;
    }
  }

  Widget buildAddButton() {
    return Container(
      margin: const EdgeInsets.only(top: 14, left: 8, right: 8),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add, size: 18),
        label: Text('addRange'.tr),
        onPressed: () => setState(() {
          int currentYear = DateTime.now().year;
          ranges.add(RandomSeekRange(startYear: currentYear - 2, endYear: currentYear));
        }),
      ),
    );
  }

  void _checkAndBack() {
    int currentYear = DateTime.now().year;

    List<RandomSeekRange> normalizedRanges = ranges.map((range) {
      int start = range.startYear.clamp(RandomSeekSetting.minSeekYear, currentYear);
      int end = range.endYear.clamp(start, currentYear);
      return RandomSeekRange(startYear: start, endYear: end, weight: range.weight);
    }).toList();

    backRoute(result: normalizedRanges);
  }
}
