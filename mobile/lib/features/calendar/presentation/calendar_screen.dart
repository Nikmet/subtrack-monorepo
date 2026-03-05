import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/ui_kit/skeleton_box.dart';
import '../../../app/ui_kit/tokens.dart';
import '../../../features/home/presentation/home_formatters.dart';
import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static const _weekdays = <String>['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
  static const _monthNamesPrepositional = <String>[
    'январе',
    'феврале',
    'марте',
    'апреле',
    'мае',
    'июне',
    'июле',
    'августе',
    'сентябре',
    'октябре',
    'ноябре',
    'декабре',
  ];
  static const _monthNamesShort = <String>[
    'янв.',
    'фев.',
    'мар.',
    'апр.',
    'мая',
    'июн.',
    'июл.',
    'авг.',
    'сент.',
    'окт.',
    'нояб.',
    'дек.',
  ];

  final _monthTitleFormat = DateFormat('MMMM y', 'ru_RU');
  final _dayTitleFormat = DateFormat('d MMMM', 'ru_RU');

  _CalendarState _state = _CalendarState.loading;
  DateTime _monthStart = _strip(DateTime.now()).copyWith(day: 1);
  DateTime _selectedDate = _strip(DateTime.now());
  String? _error;
  List<_BillingEventVm> _events = const <_BillingEventVm>[];
  Map<String, List<_BillingEventVm>> _eventsByDay =
      const <String, List<_BillingEventVm>>{};

  @override
  void initState() {
    super.initState();
    _loadMonth(_monthStart, selectedDate: _selectedDate);
  }

  Future<void> _loadMonth(DateTime month, {DateTime? selectedDate}) async {
    final normalizedMonth = _strip(month).copyWith(day: 1);
    final selected = _strip(selectedDate ?? normalizedMonth);

    setState(() {
      _state = _CalendarState.loading;
      _error = null;
    });

    try {
      final raw = await ref.read(apiClientProvider).getData(
        '/calendar/events',
        query: <String, dynamic>{'month': _monthParam(normalizedMonth)},
      );
      final eventsRaw = asMapList(asMap(raw)['events']);
      final events = eventsRaw.map(_BillingEventVm.fromMap).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final mapByDay = <String, List<_BillingEventVm>>{};
      for (final event in events) {
        final list = mapByDay[event.isoDate] ?? <_BillingEventVm>[];
        list.add(event);
        mapByDay[event.isoDate] = list;
      }

      final selectedInMonth = selected.year == normalizedMonth.year &&
          selected.month == normalizedMonth.month;

      if (!mounted) return;
      setState(() {
        _state = _CalendarState.loaded;
        _monthStart = normalizedMonth;
        _selectedDate = selectedInMonth
            ? selected
            : DateTime(normalizedMonth.year, normalizedMonth.month, 1);
        _events = events;
        _eventsByDay = mapByDay;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _CalendarState.error;
        _error = error.toString();
      });
    }
  }

  Future<void> _refresh() async {
    await _loadMonth(_monthStart, selectedDate: _selectedDate);
  }

  void _previousMonth() {
    final prev = DateTime(_monthStart.year, _monthStart.month - 1, 1);
    _loadMonth(prev, selectedDate: prev);
  }

  void _nextMonth() {
    final next = DateTime(_monthStart.year, _monthStart.month + 1, 1);
    _loadMonth(next, selectedDate: next);
  }

  List<_CalendarCellVm> _buildCells() {
    final selectedIso = _iso(_selectedDate);
    final todayIso = _iso(_strip(DateTime.now()));
    final daysInMonth =
        DateTime(_monthStart.year, _monthStart.month + 1, 0).day;
    final firstMondayIndex = (_monthStart.weekday + 6) % 7;
    final prevMonth = DateTime(_monthStart.year, _monthStart.month - 1, 1);
    final daysInPrevMonth =
        DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
    final visibleCells = ((firstMondayIndex + daysInMonth) / 7).ceil() * 7;

    final cells = <_CalendarCellVm>[];
    for (var i = 0; i < visibleCells; i++) {
      if (i < firstMondayIndex) {
        final day = daysInPrevMonth - firstMondayIndex + i + 1;
        final date = DateTime(prevMonth.year, prevMonth.month, day);
        final iso = _iso(date);
        cells.add(_CalendarCellVm(
          date: date,
          dayNumber: day,
          inCurrentMonth: false,
          hasEvents: false,
          isSelected: false,
          isToday: iso == todayIso,
        ));
        continue;
      }

      final dayInCurrent = i - firstMondayIndex + 1;
      if (dayInCurrent <= daysInMonth) {
        final date =
            DateTime(_monthStart.year, _monthStart.month, dayInCurrent);
        final iso = _iso(date);
        cells.add(_CalendarCellVm(
          date: date,
          dayNumber: dayInCurrent,
          inCurrentMonth: true,
          hasEvents: _eventsByDay.containsKey(iso),
          isSelected: iso == selectedIso,
          isToday: iso == todayIso,
        ));
        continue;
      }

      final day = dayInCurrent - daysInMonth;
      final nextMonth = DateTime(_monthStart.year, _monthStart.month + 1, 1);
      final date = DateTime(nextMonth.year, nextMonth.month, day);
      final iso = _iso(date);
      cells.add(_CalendarCellVm(
        date: date,
        dayNumber: day,
        inCurrentMonth: false,
        hasEvents: false,
        isSelected: false,
        isToday: iso == todayIso,
      ));
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents =
        _eventsByDay[_iso(_selectedDate)] ?? const <_BillingEventVm>[];
    final monthLabel = _capitalize(_monthTitleFormat.format(_monthStart));
    final dayLabel = _capitalize(_dayTitleFormat.format(_selectedDate));

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFE8EDF4)),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: UiTokens.pagePadding,
          children: <Widget>[
            if (_state == _CalendarState.loading)
              const _CalendarLoadingView()
            else if (_state == _CalendarState.error)
              _CalendarErrorView(
                message: _error ?? 'Не удалось загрузить календарь.',
                onRetry: () =>
                    _loadMonth(_monthStart, selectedDate: _selectedDate),
              )
            else ...<Widget>[
              _CalendarCard(
                monthTitle: monthLabel,
                weekdays: _weekdays,
                cells: _buildCells(),
                onPrevMonth: _previousMonth,
                onNextMonth: _nextMonth,
                onCellTap: (date) =>
                    setState(() => _selectedDate = _strip(date)),
              ),
              const SizedBox(height: 16),
              _MonthSummaryCard(
                monthStart: _monthStart,
                events: _events,
                monthNamesPrepositional: _monthNamesPrepositional,
                monthNamesShort: _monthNamesShort,
              ),
              const SizedBox(height: 16),
              _DaySection(title: dayLabel, events: selectedEvents),
            ],
          ],
        ),
      ),
    );
  }

  static DateTime _strip(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _iso(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _monthParam(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    return '${value.year}-$month';
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

enum _CalendarState { loading, loaded, error }

class _BillingEventVm {
  const _BillingEventVm({
    required this.id,
    required this.subscriptionId,
    required this.typeName,
    required this.typeIcon,
    required this.paymentCardLabel,
    required this.amount,
    required this.date,
    required this.isoDate,
  });

  final String id;
  final String subscriptionId;
  final String typeName;
  final String typeIcon;
  final String paymentCardLabel;
  final int amount;
  final DateTime date;
  final String isoDate;

  factory _BillingEventVm.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date']?.toString() ?? '';
    final rawIso = map['isoDate']?.toString() ?? '';
    final parsed = DateTime.tryParse(rawDate) ??
        DateTime.tryParse(rawIso) ??
        DateTime.now();
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    final iso = rawIso.isEmpty
        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
        : rawIso;
    return _BillingEventVm(
      id: map['id']?.toString() ?? '',
      subscriptionId: map['subscriptionId']?.toString() ?? '',
      typeName: (map['typeName']?.toString().trim().isNotEmpty ?? false)
          ? map['typeName'].toString().trim()
          : '-',
      typeIcon: map['typeIcon']?.toString() ?? map['imgLink']?.toString() ?? '',
      paymentCardLabel:
          (map['paymentCardLabel']?.toString().trim().isNotEmpty ?? false)
              ? map['paymentCardLabel'].toString().trim()
              : 'Автосписание',
      amount: map['amount'] is num ? (map['amount'] as num).round() : 0,
      date: date,
      isoDate: iso,
    );
  }
}

class _CalendarCellVm {
  const _CalendarCellVm({
    required this.date,
    required this.dayNumber,
    required this.inCurrentMonth,
    required this.hasEvents,
    required this.isSelected,
    required this.isToday,
  });

  final DateTime date;
  final int dayNumber;
  final bool inCurrentMonth;
  final bool hasEvents;
  final bool isSelected;
  final bool isToday;
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.monthTitle,
    required this.weekdays,
    required this.cells,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onCellTap,
  });

  final String monthTitle;
  final List<String> weekdays;
  final List<_CalendarCellVm> cells;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onCellTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: UiTokens.radius16,
        border: Border.all(color: const Color(0xFFDCE4EE)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D10233F),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: <Widget>[
          Container(
            height: 62,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Календарь оплат',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF0F2742),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                _MonthArrowButton(icon: '‹', onTap: onPrevMonth),
                const SizedBox(width: 6),
                SizedBox(
                  width: 150,
                  child: Text(
                    monthTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF0F2742),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _MonthArrowButton(icon: '›', onTap: onNextMonth),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: weekdays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.7,
            ),
            itemBuilder: (context, index) => Center(
              child: Text(
                weekdays[index],
                style: const TextStyle(
                  color: Color(0xFF95A6BC),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final cell = cells[index];
              final textColor = cell.inCurrentMonth
                  ? (cell.isSelected
                      ? const Color(0xFFF0F8FF)
                      : const Color(0xFF142845))
                  : const Color(0xFFD4DBE6);

              final dayContent = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '${cell.dayNumber}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 7,
                    height: 7,
                    child: cell.hasEvents && !cell.isSelected
                        ? Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF27BED4),
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                ],
              );

              final decoration = BoxDecoration(
                color: cell.isSelected
                    ? const Color(0xFF0B1E39)
                    : Colors.transparent,
                borderRadius: UiTokens.radius12,
                border: cell.isToday && !cell.isSelected
                    ? Border.all(color: const Color(0xFF20B9CD), width: 2)
                    : null,
                boxShadow: cell.isSelected
                    ? const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x330C1C35),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : null,
              );

              if (!cell.inCurrentMonth) {
                return Container(
                  decoration: decoration,
                  child: Center(child: dayContent),
                );
              }

              return InkWell(
                borderRadius: UiTokens.radius12,
                onTap: () => onCellTap(cell.date),
                child: Container(
                  decoration: decoration,
                  child: Center(child: dayContent),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonthArrowButton extends StatelessWidget {
  const _MonthArrowButton({
    required this.icon,
    required this.onTap,
  });

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: Text(
            icon,
            style: const TextStyle(
              color: Color(0xFF95A4B9),
              fontSize: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({
    required this.monthStart,
    required this.events,
    required this.monthNamesPrepositional,
    required this.monthNamesShort,
  });

  final DateTime monthStart;
  final List<_BillingEventVm> events;
  final List<String> monthNamesPrepositional;
  final List<String> monthNamesShort;

  @override
  Widget build(BuildContext context) {
    final total = events.fold<int>(0, (sum, item) => sum + item.amount);
    final uniqueCount = events
        .map((item) => item.subscriptionId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .length;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isCurrentMonth =
        monthStart.year == today.year && monthStart.month == today.month;

    _BillingEventVm? nextEvent;
    if (events.isNotEmpty) {
      if (isCurrentMonth) {
        nextEvent = events.firstWhere(
          (event) => !event.date.isBefore(today),
          orElse: () => events.first,
        );
      } else {
        nextEvent = events.first;
      }
    }

    final monthIndex = monthStart.month - 1;
    final nextText = nextEvent == null
        ? 'Нет оплат'
        : 'Следующая: ${nextEvent.date.day} ${monthNamesShort[nextEvent.date.month - 1]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'В этом месяце',
          style: TextStyle(
            color: Color(0xFF0F2742),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: const BoxDecoration(
            borderRadius: UiTokens.radius16,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF0A1E3C),
                Color(0xFF081D36),
                Color(0xFF0A3E56),
              ],
              stops: <double>[0, 0.48, 1],
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Всего к оплате в ${monthNamesPrepositional[monthIndex]}',
                style: const TextStyle(
                  color: Color(0xFFA5BFD8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatRub(total),
                style: const TextStyle(
                  color: Color(0xFFF4FBFF),
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 0.9,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  _Badge(
                    text: '$uniqueCount активных',
                    bg: const Color(0x596881A6),
                    textColor: const Color(0xFFE8F2FF),
                  ),
                  _Badge(
                    text: nextText,
                    bg: const Color(0x6B247880),
                    textColor: const Color(0xFF2CE1D3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.bg,
    required this.textColor,
  });

  final String text;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.title,
    required this.events,
  });

  final String title;
  final List<_BillingEventVm> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F2742),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${events.length} ${_subscriptionWord(events.length)}',
              style: const TextStyle(color: Color(0xFF9CAEC4), fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: UiTokens.radius14,
              border: Border.all(color: const Color(0xFFD9E2ED)),
              color: const Color(0xFFF5F7FB),
            ),
            child: const Column(
              children: <Widget>[
                _EmptyBell(),
                SizedBox(height: 10),
                Text(
                  'На этот день оплат не запланировано.\nОтличный день для экономии!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8DA1BA),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _EventCard(event: event),
            ),
          ),
      ],
    );
  }

  String _subscriptionWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return 'подписка';
    if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
      return 'подписки';
    }
    return 'подписок';
  }
}

class _EmptyBell extends StatelessWidget {
  const _EmptyBell();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFFEDF1F6),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.notifications_none_rounded,
        color: Color(0xFFC5CFDD),
        size: 24,
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
  });

  final _BillingEventVm event;

  @override
  Widget build(BuildContext context) {
    final iconUrl = event.typeIcon.trim();
    final fallbackLetter = event.typeName.trim().isEmpty
        ? '?'
        : event.typeName.trim().characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: UiTokens.radius12,
        border: Border.all(color: const Color(0xFFD7E0EB)),
        color: const Color(0xFFF5F8FB),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: UiTokens.radius10,
            child: SizedBox(
              width: 44,
              height: 44,
              child: iconUrl.isEmpty
                  ? _EventIconFallback(letter: fallbackLetter)
                  : Image.network(
                      iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) =>
                          _EventIconFallback(letter: fallbackLetter),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.typeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF122842),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event.paymentCardLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8498B1),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatRub(event.amount),
            style: const TextStyle(
              color: Color(0xFF112640),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventIconFallback extends StatelessWidget {
  const _EventIconFallback({
    required this.letter,
  });

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFEEF3F9), Color(0xFFDCE4EF)],
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Color(0xFF213755),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CalendarErrorView extends StatelessWidget {
  const _CalendarErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: UiTokens.radius14,
        border: Border.all(color: const Color(0xFFD9E2ED)),
        color: const Color(0xFFF7FAFD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Не удалось загрузить календарь',
            style: TextStyle(
              color: Color(0xFF132A43),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF6F8398), fontSize: 14),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF122A43),
              foregroundColor: const Color(0xFFF2FAFF),
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _CalendarLoadingView extends StatelessWidget {
  const _CalendarLoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: UiTokens.radius16,
            border: Border.all(color: const Color(0xFFDCE4EE)),
          ),
          padding: const EdgeInsets.all(12),
          child: const Column(
            children: <Widget>[
              SkeletonBox(
                  width: double.infinity,
                  height: 48,
                  borderRadius: UiTokens.radius12),
              SizedBox(height: 12),
              SkeletonBox(
                  width: double.infinity,
                  height: 22,
                  borderRadius: UiTokens.radius12),
              SizedBox(height: 12),
              SkeletonBox(
                  width: double.infinity,
                  height: 250,
                  borderRadius: UiTokens.radius12),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SkeletonBox(
            width: 170, height: 36, borderRadius: UiTokens.radius12),
        const SizedBox(height: 10),
        Container(
          decoration: const BoxDecoration(
            borderRadius: UiTokens.radius16,
            color: Color(0xFF10253F),
          ),
          padding: const EdgeInsets.all(14),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SkeletonBox(
                  width: 180, height: 14, borderRadius: UiTokens.radius10),
              SizedBox(height: 10),
              SkeletonBox(
                  width: 120, height: 52, borderRadius: UiTokens.radius10),
              SizedBox(height: 10),
              SkeletonBox(
                  width: 220,
                  height: 28,
                  borderRadius: BorderRadius.all(Radius.circular(999))),
            ],
          ),
        ),
      ],
    );
  }
}
