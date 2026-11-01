import 'package:get/get.dart';

class GalleryCount {
  final String? count;
  final GalleryCountType type;

  /// galleries excluded by search exclude terms (f_search `-` terms), parsed from searchtext
  final int? excludedCount;

  /// galleries filtered by account-level settings (e.g. mytags hide), parsed from searchtext
  final int? filteredCount;

  const GalleryCount({this.count, required this.type, this.excludedCount, this.filteredCount});

  String toPrintString() {
    String countString = switch (type) {
      GalleryCountType.accurate => 'accurateCountTemplate'.trArgs([count!]),
      GalleryCountType.hundreds => 'hundredsOfCountTemplate'.tr,
      GalleryCountType.thousands => 'thousandsOfCountTemplate'.tr,
    };

    List<String> filters = [
      if ((excludedCount ?? 0) > 0) 'excludedCountTemplate'.trArgs(['$excludedCount']),
      if ((filteredCount ?? 0) > 0) 'filteredCountTemplate'.trArgs(['$filteredCount']),
    ];

    return filters.isEmpty ? countString : '$countString(${filters.join(', ')})';
  }

  @override
  String toString() {
    return 'GalleryCount{count: $count, type: $type, excludedCount: $excludedCount, filteredCount: $filteredCount}';
  }
}

enum GalleryCountType {
  /// 1,465,200
  /// about 232,805
  /// 50,000+
  accurate,

  /// hundreds of
  hundreds,

  /// thousands of
  thousands,
  ;
}
