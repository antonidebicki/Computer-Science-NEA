import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/season.dart';
import '../../../design/index.dart';
import 'date_row.dart';
import '../helpers/helpers.dart';


// i need to refactor some of these widgets into different files as this is getting a bit long
// also need to add an option someday to allow 3 or 5 set matches but for 50 hour nea i might add justification for not adding
class SeasonPlannerCard extends StatefulWidget {
  final Season? plannedSeason;
  final int matchesPerWeekPerTeam;
  final int weeksBetweenMatches;
  final bool doubleRoundRobin;
  final List<int> allowedWeekdays;
  final Future<void> Function({
    required DateTime startDate,
    required DateTime endDate,
    required String seasonName,
    required int matchesPerWeekPerTeam,
    required int weeksBetweenMatches,
    required bool doubleRoundRobin,
    required List<int> allowedWeekdays,
  }) onSaveSeason;

  const SeasonPlannerCard({
    super.key,
    required this.plannedSeason,
    this.matchesPerWeekPerTeam = 1,
    this.weeksBetweenMatches = 1,
    this.doubleRoundRobin = false,
    this.allowedWeekdays = const [1, 3, 5],
    required this.onSaveSeason,
  });

  @override
  State<SeasonPlannerCard> createState() => _SeasonPlannerCardState();
}

class _SeasonPlannerCardState extends State<SeasonPlannerCard> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSubmitting = false;
  String? _errorMessage;
  int _matchesPerWeekIndex = 2;
  bool _doubleRoundRobin = false;
  final Set<int> _allowedWeekdays = {1, 3, 5};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate.add(const Duration(days: 120));
    final maxEnd = seasonPlannerMaxEndDate(_startDate);
    if (_endDate.isAfter(maxEnd)) {
      _endDate = maxEnd;
    }

    final planned = widget.plannedSeason;
    if (planned != null) {
      _applyPlannedSeason(planned);
    }
    _applyPlannerSettingsFromWidget();
  }

  @override
  void didUpdateWidget(covariant SeasonPlannerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final plannedChanged =
        widget.plannedSeason?.seasonId != oldWidget.plannedSeason?.seasonId;
    final settingsChanged = widget.matchesPerWeekPerTeam !=
            oldWidget.matchesPerWeekPerTeam ||
        widget.weeksBetweenMatches != oldWidget.weeksBetweenMatches ||
        widget.doubleRoundRobin != oldWidget.doubleRoundRobin ||
        !listEquals(widget.allowedWeekdays, oldWidget.allowedWeekdays);

    if (plannedChanged || settingsChanged) {
      setState(() {
        final planned = widget.plannedSeason;
        if (plannedChanged && planned != null) {
          _applyPlannedSeason(planned);
        }
        _applyPlannerSettingsFromWidget();
      });
    }
  }

  void _applyPlannedSeason(Season season) {
    _startDate = DateTime(
      season.startDate.year,
      season.startDate.month,
      season.startDate.day,
    );
    _endDate = DateTime(
      season.endDate.year,
      season.endDate.month,
      season.endDate.day,
    );
    _errorMessage = null;
  }

  void _applyPlannerSettingsFromWidget() {
    _matchesPerWeekIndex = _deriveMatchesPerWeekIndex(
      matchesPerWeekPerTeam: widget.matchesPerWeekPerTeam,
      weeksBetweenMatches: widget.weeksBetweenMatches,
    );
    _doubleRoundRobin = widget.doubleRoundRobin;
    _allowedWeekdays
      ..clear()
      ..addAll(widget.allowedWeekdays);
  }

  int _deriveMatchesPerWeekIndex({
    required int matchesPerWeekPerTeam,
    required int weeksBetweenMatches,
  }) {
    final value = _deriveMatchesPerWeekValue(
      matchesPerWeekPerTeam: matchesPerWeekPerTeam,
      weeksBetweenMatches: weeksBetweenMatches,
    );
    final index = seasonPlannerMatchesPerWeekOptions.indexOf(value);
    if (index != -1) {
      return index;
    }

    var closestIndex = 0;
    var smallestDiff = double.infinity;
    for (var i = 0; i < seasonPlannerMatchesPerWeekOptions.length; i++) {
      final diff =
          (seasonPlannerMatchesPerWeekOptions[i] - value).abs();
      if (diff < smallestDiff) {
        smallestDiff = diff;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  double _deriveMatchesPerWeekValue({
    required int matchesPerWeekPerTeam,
    required int weeksBetweenMatches,
  }) {
    if (matchesPerWeekPerTeam == 1 && weeksBetweenMatches == 2) {
      return 0.5;
    }
    if (matchesPerWeekPerTeam == 1 && weeksBetweenMatches == 4) {
      return 0.25;
    }
    return matchesPerWeekPerTeam.toDouble();
  }

  String get _seasonName {
    return buildSeasonName(_startDate, _endDate);
  }

  bool get _isRangeValid {
    return isSeasonRangeValid(_startDate, _endDate);
  }

  double get _matchesPerWeekValue {
    return seasonPlannerMatchesPerWeekOptions[_matchesPerWeekIndex];
  }

  Future<DateTime?> _pickDate({
    required DateTime initialDate,
    DateTime? minimumDate,
    DateTime? maximumDate,
  }) async {
    DateTime selectedDate = initialDate;
    final result = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) {
        return Container(
          height: 320,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context, selectedDate),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: minimumDate,
                  maximumDate: maximumDate,
                  onDateTimeChanged: (date) {
                    selectedDate = DateTime(date.year, date.month, date.day);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    return result;
  }

  Future<void> _selectStartDate() async {
    final picked = await _pickDate(initialDate: _startDate);
    if (picked == null) return;

    final maxEnd = seasonPlannerMaxEndDate(picked);
    setState(() {
      _startDate = picked;
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      } else if (_endDate.isAfter(maxEnd)) {
        _endDate = maxEnd;
      }
      _errorMessage = null;
    });
  }

  Future<void> _selectEndDate() async {
    final maxEnd = seasonPlannerMaxEndDate(_startDate);
    final picked = await _pickDate(
      initialDate: _endDate,
      minimumDate: _startDate,
      maximumDate: maxEnd,
    );
    if (picked == null) return;

    setState(() {
      _endDate = picked;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_isRangeValid) {
      setState(() {
        _errorMessage = 'Season length must be 1 year or less.';
      });
      return;
    }

    if (_allowedWeekdays.isEmpty) {
      setState(() {
        _errorMessage = 'Select at least one allowed match weekday.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final matchesPerWeek = _matchesPerWeekValue < 1
          ? 1
          : _matchesPerWeekValue.round();
      final weeksBetweenMatches =
          deriveWeeksBetweenMatches(_matchesPerWeekValue);
      await widget.onSaveSeason(
        startDate: _startDate,
        endDate: _endDate,
        seasonName: _seasonName,
        matchesPerWeekPerTeam: matchesPerWeek,
        weeksBetweenMatches: weeksBetweenMatches,
        doubleRoundRobin: _doubleRoundRobin,
        allowedWeekdays: _allowedWeekdays.toList()..sort(),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save season: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxEnd = seasonPlannerMaxEndDate(_startDate);
    final lengthDays = _endDate.difference(_startDate).inDays + 1;

    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan Season',
            style: AppTypography.headline.copyWith(
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Pick the season dates. The season name will be generated for you.',
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          BuildDateRow(
            label: 'Start date',
            value: formatSeasonPlannerDate(_startDate),
            onTap: _selectStartDate,
          ),
          const SizedBox(height: Spacing.md),
          BuildDateRow(
            label: 'End date',
            value: formatSeasonPlannerDate(_endDate),
            onTap: _selectEndDate,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Season name: $_seasonName',
            style: AppTypography.body.copyWith(
              color: CupertinoColors.label,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Length: $lengthDays days (max end ${formatSeasonPlannerDate(maxEnd)})',
            style: AppTypography.caption.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Fixture options',
            style: AppTypography.caption.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Matches per week/team',
            style: AppTypography.body.copyWith(
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlider(
              value: _matchesPerWeekIndex.toDouble(),
              min: 0,
              max: (seasonPlannerMatchesPerWeekOptions.length - 1).toDouble(),
              divisions: seasonPlannerMatchesPerWeekOptions.length - 1,
              onChanged: (value) {
                setState(() {
                  _matchesPerWeekIndex = value.round().clamp(
                        0,
                    seasonPlannerMatchesPerWeekOptions.length - 1,
                      );
                });
              },
            ),
          ),
          // const SizedBox(height: Spacing.xs),
          // Text(
          //   _matchesPerWeekValue < 1
          //       ? _matchesPerWeekValue.toStringAsFixed(2)
          //       : _matchesPerWeekValue.toStringAsFixed(0),
          //   style: AppTypography.caption.copyWith(
          //     color: CupertinoColors.secondaryLabel,
          //   ),
          // ),
          const SizedBox(height: Spacing.xs),
          Text(
            matchesPerWeekTooltip(
              options: seasonPlannerMatchesPerWeekOptions,
              index: _matchesPerWeekIndex,
            ),
            style: AppTypography.caption.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Double round robin',
                style: AppTypography.body.copyWith(
                  color: CupertinoColors.label,
                ),
              ),
              CupertinoSwitch(
                value: _doubleRoundRobin,
                onChanged: (value) {
                  setState(() {
                    _doubleRoundRobin = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Allowed match days',
            style: AppTypography.caption.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xs,
            children: List.generate(seasonPlannerWeekdayLabels.length, (index) {
              final dayNumber = index + 1;
              final isSelected = _allowedWeekdays.contains(dayNumber);
              return CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs,
                ),
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey5.resolveFrom(context),
                onPressed: () {
                  setState(() {
                    if (isSelected) {
                      _allowedWeekdays.remove(dayNumber);
                    } else {
                      _allowedWeekdays.add(dayNumber);
                    }
                  });
                },
                child: Text(
                  seasonPlannerWeekdayLabels[index],
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? CupertinoColors.white
                        : CupertinoColors.label,
                  ),
                ),
              );
            }),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              _errorMessage!,
              style: AppTypography.callout.copyWith(
                color: CupertinoColors.systemRed,
              ),
            ),
          ],
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _isSubmitting || !_isRangeValid ? null : _submit,
              child: _isSubmitting
                  ? const CupertinoActivityIndicator(radius: 8)
                  : const Text('Save Season'),
            ),
          ),
        ],
      ),
    );
  }
}

