import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/match_data.dart';
import '../../../core/models/volleyball_set.dart';
import '../../../design/index.dart';
import '../../../services/api_client.dart';
import '../../../services/repositories/match_repository.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../main.dart';

class LeagueAdminMatchScoreEntryScreen extends StatefulWidget {
  final MatchData fixture;

  const LeagueAdminMatchScoreEntryScreen({super.key, required this.fixture});

  @override
  State<LeagueAdminMatchScoreEntryScreen> createState() =>
      _LeagueAdminMatchScoreEntryScreenState();
}

class _LeagueAdminMatchScoreEntryScreenState
    extends State<LeagueAdminMatchScoreEntryScreen> {
  late final MatchRepository _matchRepository;
  late final List<TextEditingController> _homeScoreControllers;
  late final List<TextEditingController> _awayScoreControllers;

  bool _loadingExisting = false;
  bool _saving = false;
  String? _errorMessage;
  List<VolleyballSet> _existingSets = [];

  @override
  void initState() {
    super.initState();
    _matchRepository = MatchRepository(ApiClient());
    _homeScoreControllers = List.generate(
      5,
      (_) => TextEditingController(text: ''),
    );
    _awayScoreControllers = List.generate(
      5,
      (_) => TextEditingController(text: ''),
    );
    _loadExistingSets();
  }

  @override
  void dispose() {
    for (final controller in _homeScoreControllers) {
      controller.dispose();
    }
    for (final controller in _awayScoreControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingSets() async {
    final matchId = widget.fixture.match.matchId;
    if (matchId <= 0) {
      setState(() {
        _errorMessage =
            'This fixture cannot be edited because it is missing a valid match ID.';
      });
      return;
    }

    setState(() {
      _loadingExisting = true;
      _errorMessage = null;
    });

    try {
      final sets = await _matchRepository.getMatchSets(matchId);
      if (!mounted) return;

      sets.sort((a, b) => a.setNumber.compareTo(b.setNumber));
      for (final setItem in sets) {
        final index = setItem.setNumber - 1;
        if (index >= 0 && index < 5) {
          _homeScoreControllers[index].text = setItem.homeTeamScore.toString();
          _awayScoreControllers[index].text = setItem.awayTeamScore.toString();
        }
      }

      setState(() {
        _existingSets = sets;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load existing sets: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingExisting = false;
        });
      }
    }
  }

  bool _isSetLocked(int setNumber) {
    return _existingSets.any((setItem) => setItem.setNumber == setNumber);
  }

  int? _parseScore(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  void _validateSetScore({
    required int setNumber,
    required int homeScore,
    required int awayScore,
  }) {
    final winningScore = homeScore > awayScore ? homeScore : awayScore;
    final losingScore = homeScore > awayScore ? awayScore : homeScore;
    final minimumWinningScore = setNumber == 5 ? 15 : 25;

    if (winningScore < minimumWinningScore) {
      throw Exception(
        'Set $setNumber winner must have at least $minimumWinningScore points.',
      );
    }

    if (winningScore - losingScore < 2) {
      throw Exception('Set $setNumber must be won by 2 clear points.');
    }

    if (winningScore > minimumWinningScore &&
        losingScore < minimumWinningScore - 1) {
      throw Exception(
        'Set $setNumber score is invalid. Scores above $minimumWinningScore '
        'are only valid after deuce (for example ${minimumWinningScore + 2}-$minimumWinningScore).',
      );
    }

    if (winningScore > minimumWinningScore && winningScore - losingScore != 2) {
      throw Exception(
        'Set $setNumber score is invalid. Once play goes past '
        '$minimumWinningScore, the set must end immediately at a 2-point lead '
        '(for example ${minimumWinningScore + 2}-$minimumWinningScore).',
      );
    }
  }

  Future<void> _saveMatchResult() async {
    final matchId = widget.fixture.match.matchId;
    if (matchId <= 0) {
      setState(() {
        _errorMessage =
            'Cannot save score because this fixture has no valid match ID.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final enteredSets = <Map<String, int>>[];

      for (var index = 0; index < 5; index++) {
        final setNumber = index + 1;
        final homeValue = _parseScore(_homeScoreControllers[index].text);
        final awayValue = _parseScore(_awayScoreControllers[index].text);

        final bothEmpty = homeValue == null && awayValue == null;
        if (bothEmpty) {
          continue;
        }

        if (homeValue == null || awayValue == null) {
          throw Exception('Set $setNumber requires both team scores.');
        }

        if (homeValue < 0 || awayValue < 0) {
          throw Exception('Set $setNumber cannot have negative scores.');
        }

        if (homeValue == awayValue) {
          throw Exception('Set $setNumber cannot end in a tie.');
        }

        _validateSetScore(
          setNumber: setNumber,
          homeScore: homeValue,
          awayScore: awayValue,
        );

        if (_isSetLocked(setNumber)) {
          final existing = _existingSets.firstWhere(
            (setItem) => setItem.setNumber == setNumber,
          );
          if (existing.homeTeamScore != homeValue ||
              existing.awayTeamScore != awayValue) {
            throw Exception(
              'Set $setNumber is already saved and cannot be modified from this screen.',
            );
          }
        } else {
          enteredSets.add({
            'set_number': setNumber,
            'home_score': homeValue,
            'away_score': awayValue,
          });
        }
      }

      final allSets = <Map<String, int>>[];
      for (final existing in _existingSets) {
        allSets.add({
          'set_number': existing.setNumber,
          'home_score': existing.homeTeamScore,
          'away_score': existing.awayTeamScore,
        });
      }
      allSets.addAll(enteredSets);
      allSets.sort((a, b) => a['set_number']!.compareTo(b['set_number']!));

      if (allSets.isEmpty) {
        throw Exception('Enter at least one completed set score.');
      }

      var homeSetsWon = 0;
      var awaySetsWon = 0;
      int? decisiveSetNumber;
      for (final setItem in allSets) {
        final setNumber = setItem['set_number']!;
        if (decisiveSetNumber != null) {
          throw Exception(
            'Cannot record Set $setNumber because the match was already won in Set $decisiveSetNumber.',
          );
        }

        final homeScore = setItem['home_score']!;
        final awayScore = setItem['away_score']!;
        if (homeScore > awayScore) {
          homeSetsWon += 1;
        } else {
          awaySetsWon += 1;
        }

        if (homeSetsWon == 3 || awaySetsWon == 3) {
          decisiveSetNumber = setNumber;
        }
      }

      final oneTeamReachedThree = homeSetsWon == 3 || awaySetsWon == 3;
      final bothReachedThree = homeSetsWon == 3 && awaySetsWon == 3;
      if (!oneTeamReachedThree || bothReachedThree) {
        throw Exception('Invalid result: exactly one team must win 3 sets.');
      }

      for (final setItem in enteredSets) {
        await _matchRepository.createSet(
          matchId: matchId,
          setNumber: setItem['set_number']!,
          homeTeamScore: setItem['home_score']!,
          awayTeamScore: setItem['away_score']!,
        );
      }

      final winnerTeamId = homeSetsWon > awaySetsWon
          ? widget.fixture.match.homeTeamId
          : widget.fixture.match.awayTeamId;

      await _matchRepository.updateMatch(
        matchId: matchId,
        status: GameState.finished.value,
        winnerTeamId: winnerTeamId,
        homeSetsWon: homeSetsWon,
        awaySetsWon: awaySetsWon,
      );

      try {
        await _matchRepository.processMatch(matchId);
      } catch (_) {
        // Keep this non-blocking so score save still succeeds if standings were
        // already processed.
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to save match score: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildSetRow(int setNumber) {
    final index = setNumber - 1;
    final isLocked = _isSetLocked(setNumber);

    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.md),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Set $setNumber',
                style: AppTypography.callout.copyWith(
                  color: CupertinoColors.label,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isLocked)
                Text(
                  'Saved',
                  style: AppTypography.caption.copyWith(
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _homeScoreControllers[index],
                  enabled: !isLocked,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  placeholder: widget.fixture.homeTeamName,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(Spacing.md),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: CupertinoTextField(
                  controller: _awayScoreControllers[index],
                  enabled: !isLocked,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  placeholder: widget.fixture.awayTeamName,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(Spacing.md),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final match = widget.fixture.match;
    final matchDate = match.matchDatetime;
    final matchDateText = matchDate == null
        ? 'Unscheduled'
        : '${matchDate.day.toString().padLeft(2, '0')}/'
              '${matchDate.month.toString().padLeft(2, '0')}/'
              '${matchDate.year}';

    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              heroTag: 'league_admin_score_entry_${match.matchId}',
              largeTitle: const Text('Record Score'),
              automaticBackgroundVisibility: false,
              backgroundColor: CupertinoColors.transparent,
              border: null,
            ),
            SliverPadding(
              padding: const EdgeInsets.only(
                left: Spacing.lg,
                right: Spacing.lg,
                top: Spacing.lg,
                bottom: 120,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AppGlassContainer(
                    padding: const EdgeInsets.all(Spacing.lg),
                    borderRadius: 20,
                    child: KeyboardDismissArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          '${widget.fixture.homeTeamName} vs ${widget.fixture.awayTeamName}',
                          style: AppTypography.headline.copyWith(
                            color: CupertinoColors.label,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          'Date: $matchDateText',
                          style: AppTypography.callout.copyWith(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        if (match.venue != null &&
                            match.venue!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: Spacing.xs),
                            child: Text(
                              'Venue: ${match.venue}',
                              style: AppTypography.callout.copyWith(
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: Spacing.xs),
                          child: Text(
                            'Status: ${match.status.value}',
                            style: AppTypography.callout.copyWith(
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ),
                        const SizedBox(height: Spacing.md),
                        if (_loadingExisting)
                          const Center(child: CupertinoActivityIndicator())
                        else ...[
                          Text(
                            'Enter each set score (best of 5).',
                            style: AppTypography.callout.copyWith(
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: Spacing.md),
                          for (
                            var setNumber = 1;
                            setNumber <= 5;
                            setNumber++
                          ) ...[
                            _buildSetRow(setNumber),
                            if (setNumber < 5)
                              const SizedBox(height: Spacing.sm),
                          ],
                        ],
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
                            onPressed: (_saving || _loadingExisting)
                                ? null
                                : _saveMatchResult,
                            child: _saving
                                ? const CupertinoActivityIndicator(radius: 8)
                                : const Text('Save Result'),
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
