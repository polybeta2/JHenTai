import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:jhentai/src/enum/config_enum.dart';
import 'package:jhentai/src/model/random_seek_range.dart';
import 'package:jhentai/src/service/log.dart';

import '../service/jh_service.dart';

RandomSeekSetting randomSeekSetting = RandomSeekSetting();

class RandomSeekSetting with JHLifeCircleBeanWithConfigStorage implements JHLifeCircleBean {
  /// Earliest year E-Hentai galleries exist, aligned with the date picker's firstDate.
  static const int minSeekYear = 2007;

  /// Empty list means uniform sampling over [minSeekYear, current year].
  RxList<RandomSeekRange> ranges = <RandomSeekRange>[].obs;

  @override
  ConfigEnum get configEnum => ConfigEnum.randomSeekSetting;

  @override
  void applyBeanConfig(String configString) {
    try {
      List list = jsonDecode(configString);
      ranges.value = list.map((element) => RandomSeekRange.fromJson(element)).toList();
    } catch (e) {
      log.error('parse randomSeekSetting failed', e.toString());
      ranges.clear();
    }
  }

  @override
  String toConfigString() {
    return jsonEncode(ranges.map((range) => range.toJson()).toList());
  }

  @override
  Future<void> doInitBean() async {}

  @override
  void doAfterBeanReady() {}

  Future<void> saveRanges(List<RandomSeekRange> ranges) async {
    log.debug('saveRanges:$ranges');
    this.ranges.value = ranges;
    await saveBeanConfig();
  }

  /// Sample a random date: years are weighted by configured ranges (weights
  /// accumulate on overlap), the day is then sampled uniformly within the
  /// sampled year. Falls back to uniform sampling over [minSeekYear, current
  /// year] when no valid weight is configured.
  DateTime randomDate() {
    final int currentYear = DateTime.now().year;

    Map<int, int> yearWeights = {};
    for (RandomSeekRange range in ranges) {
      int start = range.startYear.clamp(minSeekYear, currentYear);
      int end = range.endYear.clamp(start, currentYear);
      for (int year = start; year <= end; year++) {
        yearWeights[year] = (yearWeights[year] ?? 0) + range.weight;
      }
    }

    int totalWeight = yearWeights.values.fold(0, (sum, weight) => sum + weight);
    if (totalWeight <= 0) {
      return _uniformRandomDate(minSeekYear, currentYear);
    }

    Random random = Random();
    int point = random.nextInt(totalWeight);
    for (MapEntry<int, int> entry in yearWeights.entries) {
      point -= entry.value;
      if (point < 0) {
        return _uniformRandomDate(entry.key, entry.key, random: random);
      }
    }

    /// Unreachable
    return _uniformRandomDate(minSeekYear, currentYear);
  }

  DateTime _uniformRandomDate(int startYear, int endYear, {Random? random}) {
    random ??= Random();

    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(startYear);
    final DateTime lastDate = endYear >= now.year ? now : DateTime(endYear, 12, 31);
    final int totalDays = lastDate.difference(firstDate).inDays;

    return firstDate.add(Duration(days: random.nextInt(totalDays + 1)));
  }
}
