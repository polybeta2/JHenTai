# JHenTai 搜索「随机探索」功能实现方案

## Context（背景与调研结论）

**问题**：E-Hentai/EXHentai 搜索结果只能按发布时间排列，用户想随机浏览来发现内容，但官方没有随机排序接口。

**HAR 分析关键发现**（`D:\Analyze\exhentai.org_2026_10_31_22_55_16.har`，95 条 exhentai 请求）：
- ExHentai 现已改为**游标式分页**：`next=<gid>` / `prev=<gid>`，HTML 中**完全没有** `page=N` 数字分页、没有 `.ptt` 页码表格、`Last>>` 链接是写死的 `prev=1` → 「随机页码」路线不可行
- 搜索表单只有 `f_search`/`f_cats` 两个字段，全站无任何排序参数
- 结果总数文本在 `<div class="searchtext"><p>Found 277,185 results.</p></div>`（JHenTai 已解析此节点）

**可行方案**：E-Hentai 支持 `seek=日期` 参数（按发布时间定位结果游标），JHenTai 的「按日期跳页」按钮（`Icons.restore`）已在用它。**随机生成一个日期去 seek = 在结果时间轴上随机落点**，之后可正常无限滚动浏览、再点一次换一个随机落点。这就是「随机排列寻找」的正确实现。

## 代码调研结论（改动点）

搜索链路：搜索页 AppBar（`search_page_mixin.dart:31` buildActionButtons，移动端/桌面端共用）→ `BasePageLogic`（`base_page_logic.dart`）→ `jumpPage(DateTime)`（`:285`，现成的按日期跳转：清列表、带 seek 请求、更新游标和 `state.seek`）→ `requestGalleryPage`（`eh_request.dart:331`，seek 格式化为 `yyyy-MM-dd`）。

## 实现步骤

### 1. `lib/src/pages/base/base_page_logic.dart`
在 `handleTapJumpButton`（`:347-360`）之后新增：
- `DateTime _randomSeekDate()`：用 `Random()` 在 `[DateTime(2007), DateTime.now()]` 中随机取一天（`DateTime(2007)` 与现有 DatePicker 的 `firstDate`（`:352`）保持一致；seek 只精确到日）
- `Future<void> handleTapRandomJumpButton()`：随机取日期 → 调用现有 `jumpPage(date)`；**空结果自动重掷**（最多 3 次）：若 `state.galleries.isEmpty` 且 `state.totalCount` 不是 accurate 类型或 `int.tryParse(count) != 0`（即查询本身非空、只是落点没命中）且 `state.loadingState != LoadingState.error`，则换一个随机日期重试；结束后用现有 `snack()`（`:303` 同款）提示落点日期。需要时补 `intl` 的 `DateFormat` import

### 2. `lib/src/pages/search/mixin/search_page_mixin.dart`
在 `buildActionButtons`（`:35-71`）的「按日期跳页」按钮（`Icons.restore`，`:43-49`）后面插入一个骰子按钮：`Icons.casino_outlined` → `logic.handleTapRandomJumpButton`，其余参数（visualDensity/constraints/padding）照抄相邻按钮。移动端和桌面端搜索页自动同时获得此按钮。

### 3. l18n（6 个语言文件各加 2 个 key）
`lib/src/l18n/{zh_CN,zh_TW,en_US,ko_KR,pt_BR,ru_RU}.dart`，插到 `jumpPageTo`（zh_CN.dart:117）附近：
- `randomSeek`：随机探索 / 隨機探索 / Random seek / 랜덤 탐색 / Explorar aleatoriamente / Случайный поиск
- `randomSeekLanded`：`'已随机跳转到 @date'` 等（用 GetX `.trArgs([date])` 占位符风格，参照 `accurateCountTemplate` 的用法）

## 不改的东西（明确边界）
- 不新增任何 URL 参数模型改动（`SearchConfig` 无需变动，seek 是独立参数）
- 刷新后回到最新一页是现有 seek 语义（`handleRefresh:96` 不带 seek），保持一致
- 收藏页/订阅页不适用（无 seek 支持），骰子按钮只出现在搜索页

## 验证
1. 本地 `flutter analyze`（若本机无 Flutter SDK，则以下一步 CI 作为编译门禁）
2. 提交推送到 Fork（polybeta2/JHenTai master），触发已有的 `Build iOS` workflow 作为编译+打包门禁
3. 手动验证路径：搜索任意关键词 → 点骰子按钮 → 应随机落到某日期附近并 toast 提示日期 → 下拉加载更多可继续浏览 → 再点骰子换新落点；配合高级搜索过滤条件重复验证空结果重掷