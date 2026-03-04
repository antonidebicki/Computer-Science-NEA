import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../core/models/invitation.dart';
import '../../../core/models/league.dart';
import '../../../core/models/season.dart';
import '../../../design/index.dart';
import '../../../services/api_client.dart';
import '../../../services/repositories/invitation_repository.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../services/repositories/match_repository.dart';
import '../../../state/providers/theme_provider.dart';
import '../widgets/league_invitations.dart';
import '../widgets/league_overview_card.dart';
import '../widgets/season_planner_card.dart';
import '../widgets/season_status_card.dart';
import '../widgets/section_title.dart';

class LeagueAdminLeagueSettingsScreen extends StatefulWidget {
  final League league;

  const LeagueAdminLeagueSettingsScreen({super.key, required this.league});

  @override
  State<LeagueAdminLeagueSettingsScreen> createState() =>
      _LeagueAdminLeagueSettingsScreenState();
}

class _LeagueAdminLeagueSettingsScreenState
    extends State<LeagueAdminLeagueSettingsScreen> {
  late final InvitationRepository _invitationRepository;
  late final LeagueRepository _leagueRepository;
  late final MatchRepository _matchRepository;

  List<LeagueJoinRequest> _pendingInvitations = [];
  Season? _currentSeason;
  Season? _plannedSeason;
  bool _isLoadingInvitations = false;
  bool _isLoadingSeason = false;
  bool _isSeasonStarted = false;
  bool _isStartingSeason = false;
  String? _errorMessage;
  String? _seasonPlannerErrorMessage;
  int? _seasonTeamCount;
  List<Map<String, dynamic>> _seasonTeams = [];
  bool _isLoadingSeasonTeams = false;
  int _matchesPerWeekPerTeam = 1;
  int _weeksBetweenMatches = 1;
  bool _doubleRoundRobin = false;
  List<int> _allowedWeekdays = const [1, 3, 5];
  int? _roundsPerWeek;

  @override
  void initState() {
    super.initState();
    _invitationRepository = InvitationRepository(ApiClient());
    _leagueRepository = LeagueRepository(ApiClient());
    _matchRepository = MatchRepository(ApiClient());
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadCurrentSeason();
    await _loadPendingInvitations();
  }

  Future<Season?> _createPlannedSeasonIfMissing({
    required DateTime now,
    Season? sourceSeason,
  }) async {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final sourceEnd = sourceSeason == null
        ? null
        : DateTime(
            sourceSeason.endDate.year,
            sourceSeason.endDate.month,
            sourceSeason.endDate.day,
          );

    final startDate = sourceEnd == null
        ? tomorrow
        : sourceEnd.add(const Duration(days: 1)).isAfter(tomorrow)
        ? sourceEnd.add(const Duration(days: 1))
        : tomorrow;
    final endDate = startDate.add(const Duration(days: 120));
    final seasonName = startDate.year == endDate.year
        ? '${startDate.year} season'
        : '${startDate.year}/${endDate.year} season';

    return _leagueRepository.createSeason(
      leagueId: widget.league.leagueId,
      name: seasonName,
      startDate: startDate,
      endDate: endDate,
      matchesPerWeekPerTeam:
          sourceSeason?.matchesPerWeekPerTeam ?? _matchesPerWeekPerTeam,
      weeksBetweenMatches: sourceSeason?.weeksBetweenMatches ?? _weeksBetweenMatches,
      doubleRoundRobin: sourceSeason?.doubleRoundRobin ?? _doubleRoundRobin,
      allowedWeekdays: sourceSeason == null
          ? List<int>.from(_allowedWeekdays)
          : List<int>.from(sourceSeason.allowedWeekdays),
    );
  }

  Future<void> _loadCurrentSeason() async {
    setState(() => _isLoadingSeason = true);
    try {
      final seasons = await _leagueRepository.getSeasons(
        widget.league.leagueId,
      );
      final now = DateTime.now();
      final active = seasons.where((season) {
        return !season.isArchived &&
            now.isAfter(season.startDate) &&
            now.isBefore(season.endDate.add(const Duration(days: 1)));
      }).toList();
      final plannedSeasons = seasons.where((season) {
        return !season.isArchived && season.startDate.isAfter(now);
      }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));

      Season? planned = plannedSeasons.isNotEmpty ? plannedSeasons.first : null;

      Season? selected;
      if (active.isNotEmpty) {
        selected = active.first;
      } else if (planned != null) {
        selected = planned;
      } else {
        final nonArchived = seasons.where((s) => !s.isArchived).toList();
        nonArchived.sort((a, b) => b.startDate.compareTo(a.startDate));
        selected = nonArchived.isNotEmpty ? nonArchived.first : null;
      }

      if (planned == null) {
        try {
          planned = await _createPlannedSeasonIfMissing(
            now: now,
            sourceSeason: selected,
          );
          selected = planned ?? selected;
        } catch (e) {
          setState(() {
            _seasonPlannerErrorMessage =
                'Unable to create planned season in the database: $e';
            _errorMessage = _seasonPlannerErrorMessage;
          });
        }
      }

      setState(() {
        _plannedSeason = planned;
        _currentSeason = selected;
        _applySeasonPlannerSettings(planned ?? selected);
        _seasonPlannerErrorMessage = planned == null
            ? 'No planned season found in the database.'
            : null;
      });
      await _loadSeasonTeamsCount();
      await _loadSeasonStarted();
    } catch (e) {
      setState(() {
        _currentSeason = null;
        _isSeasonStarted = false;
        _seasonTeamCount = null;
        _seasonTeams = [];
        _plannedSeason = null;
        _applySeasonPlannerSettings(null);
        _seasonPlannerErrorMessage =
            'Unable to access planned season data from the database.';
        _errorMessage = _seasonPlannerErrorMessage;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingSeason = false);
      }
    }
  }

  void _applySeasonPlannerSettings(Season? season) {
    if (season == null) {
      _matchesPerWeekPerTeam = 1;
      _weeksBetweenMatches = 1;
      _doubleRoundRobin = false;
      _allowedWeekdays = [1, 3, 5];
      return;
    }

    _matchesPerWeekPerTeam = season.matchesPerWeekPerTeam;
    _weeksBetweenMatches = season.weeksBetweenMatches;
    _doubleRoundRobin = season.doubleRoundRobin;
    _allowedWeekdays = List<int>.from(season.allowedWeekdays);
  }

  Future<void> _loadSeasonStarted() async {
    final season = _currentSeason;
    if (season == null) {
      setState(() => _isSeasonStarted = false);
      return;
    }

    try {
      final matches = await _matchRepository.getMatches(
        seasonId: season.seasonId,
      );
      if (!mounted) return;
      setState(() => _isSeasonStarted = matches.isNotEmpty);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSeasonStarted = false);
    }
  }

  Future<void> _loadSeasonTeamsCount() async {
    final season = _plannedSeason ?? _currentSeason;
    if (season == null) {
      setState(() {
        _seasonTeamCount = null;
        _seasonTeams = [];
      });
      return;
    }

    setState(() => _isLoadingSeasonTeams = true);
    try {
      final teams = await _leagueRepository.getSeasonTeams(season.seasonId);
      if (!mounted) return;
      setState(() {
        _seasonTeamCount = teams.length;
        _seasonTeams = teams;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _seasonTeamCount = null;
        _seasonTeams = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingSeasonTeams = false);
      }
    }
  }

  Future<void> _loadPendingInvitations() async {
    setState(() => _isLoadingInvitations = true);
    try {
      final invitations = await _invitationRepository.getSentLeagueInvitations(
        leagueId: widget.league.leagueId,
      );
      setState(() {
        _pendingInvitations = invitations;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load invitations: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingInvitations = false);
      }
    }
  }

  Future<void> _handleSendInvitation({
    required int leagueId,
    required int seasonId,
    required String invitationCode,
  }) async {
    try {
      final request = CreateLeagueInvitationRequest(
        leagueId: leagueId,
        seasonId: seasonId,
        invitationCode: invitationCode,
      );
      final invitation = await _invitationRepository.createLeagueInvitation(
        request,
      );
      setState(() {
        _pendingInvitations.add(invitation);
        _errorMessage = null;
      });
      _showSuccessMessage('League invitation sent successfully!');
    } catch (e) {
      _showErrorMessage('Failed to send invitation: $e');
    }
  }

  Future<void> _handleCancelInvitation(int joinRequestId) async {
    try {
      await _invitationRepository.deleteLeagueInvitation(joinRequestId);
      setState(() {
        _pendingInvitations.removeWhere(
          (inv) => inv.joinRequestId == joinRequestId,
        );
        _errorMessage = null;
      });
      _showSuccessMessage('Invitation cancelled');
    } catch (e) {
      _showErrorMessage('Failed to cancel invitation: $e');
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _seasonPlannerErrorMessage = message;
    });
  }

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDateForApi(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  int _requiredPeriods({
    required int teamCount,
    required int matchesPerWeekPerTeam,
    required bool doubleRoundRobin,
  }) {
    final rounds = doubleRoundRobin ? 2 : 1;
    final matchesPerTeam = (teamCount - 1) * rounds;
    return (matchesPerTeam / matchesPerWeekPerTeam).ceil();
  }

  DateTime? _nextAllowedWeekday(DateTime date, Set<int> allowed) {
    for (var i = 0; i < 7; i++) {
      final candidate = date.add(Duration(days: i));
      if (allowed.contains(candidate.weekday)) {
        return DateTime(candidate.year, candidate.month, candidate.day);
      }
    }
    return null;
  }

  int _availablePeriods({
    required DateTime startDate,
    required DateTime endDate,
    required int weeksBetweenMatches,
    required List<int> allowedWeekdays,
  }) {
    if (allowedWeekdays.isEmpty) {
      return 0;
    }

    final allowed = allowedWeekdays.toSet();
    var periods = 0;
    var periodIndex = 0;

    while (true) {
      final baseDate = startDate.add(
        Duration(days: 7 * weeksBetweenMatches * periodIndex),
      );
      final matchDate = _nextAllowedWeekday(baseDate, allowed);
      if (matchDate == null || matchDate.isAfter(endDate)) {
        break;
      }
      periods += 1;
      periodIndex += 1;
    }

    return periods;
  }

  Future<void> _handleSaveSeason({
    required DateTime startDate,
    required DateTime endDate,
    required String seasonName,
    required int matchesPerWeekPerTeam,
    required int weeksBetweenMatches,
    required bool doubleRoundRobin,
    required List<int> allowedWeekdays,
    int? roundsPerWeek,
  }) async {
    try {
      final editableSeason = _plannedSeason;
      if (editableSeason == null) {
        _showErrorMessage(
          'Cannot save season because planned season data is not loaded from the database.',
        );
        return;
      }

      await _leagueRepository.updateSeason(
        seasonId: editableSeason.seasonId,
        name: seasonName,
        startDate: startDate,
        endDate: endDate,
        matchesPerWeekPerTeam: matchesPerWeekPerTeam,
        weeksBetweenMatches: weeksBetweenMatches,
        doubleRoundRobin: doubleRoundRobin,
        allowedWeekdays: allowedWeekdays,
      );

      if (!mounted) return;
      setState(() {
        _matchesPerWeekPerTeam = matchesPerWeekPerTeam;
        _weeksBetweenMatches = weeksBetweenMatches;
        _doubleRoundRobin = doubleRoundRobin;
        _allowedWeekdays = allowedWeekdays;
        _roundsPerWeek = roundsPerWeek;
        _errorMessage = null;
        _seasonPlannerErrorMessage = null;
      });
      await _loadCurrentSeason();
      await _loadPendingInvitations();
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      
      // Handle past date validation error by automatically retrying with today's date
      if (errorMessage.contains('season start date cannot be in the past')) {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        
        // Only retry if the passed startDate is actually in the past
        final passedDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
        if (passedDateOnly.isBefore(todayDate)) {
          // Show the error message temporarily in red
          if (mounted) {
            setState(() {
              _seasonPlannerErrorMessage = 'Start date was in the past. Adjusted to today.';
            });
          }
          
          // Retry with today's date
          Future.delayed(const Duration(milliseconds: 500), () async {
            if (!mounted) return;
            
            // Calculate new end date to maintain season length
            final seasonLength = endDate.difference(startDate);
            final newEndDate = todayDate.add(seasonLength);
            
            // Clear the temporary error message and retry
            if (mounted) {
              setState(() {
                _seasonPlannerErrorMessage = null;
              });
            }
            
            await _handleSaveSeason(
              startDate: todayDate,
              endDate: newEndDate,
              seasonName: seasonName,
              matchesPerWeekPerTeam: matchesPerWeekPerTeam,
              weeksBetweenMatches: weeksBetweenMatches,
              doubleRoundRobin: doubleRoundRobin,
              allowedWeekdays: allowedWeekdays,
            );
          });
          return;
        }
      }
      
      _showErrorMessage('Failed to save season: $e');
    }
  }

  Future<void> _handleStartSeason() async {
    final season = _currentSeason;
    if (season == null || _isSeasonStarted) {
      return;
    }

    if (_isLoadingSeasonTeams) {
      _showErrorMessage('Checking team count. Please try again in a moment.');
      return;
    }

    final teamCount = _seasonTeamCount;
    if (teamCount == null) {
      _showErrorMessage('Unable to verify team count for this season.');
      return;
    }

    if (teamCount < 2 || teamCount > 24) {
      _showErrorMessage('Season must have between 2 and 24 teams to start.');
      return;
    }

    if (_allowedWeekdays.isEmpty) {
      _showErrorMessage('Select at least one allowed match weekday.');
      return;
    }

    final requiredPeriods = _requiredPeriods(
      teamCount: teamCount,
      matchesPerWeekPerTeam: _matchesPerWeekPerTeam,
      doubleRoundRobin: _doubleRoundRobin,
    );
    final availablePeriods = _availablePeriods(
      startDate: season.startDate,
      endDate: season.endDate,
      weeksBetweenMatches: _weeksBetweenMatches,
      allowedWeekdays: _allowedWeekdays,
    );

    if (availablePeriods < requiredPeriods) {
      _showErrorMessage(
        'Not enough allowed match days to finish this season. '
        'Extend the season or adjust match days/fixtures per week.',
      );
      return;
    }

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Start season?'),
        content: const Text(
          'Starting the season will lock team invites and generate fixtures.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isStartingSeason = true;
      _errorMessage = null;
    });

    try {
      await _matchRepository.generateFixtures(
        seasonId: season.seasonId,
        startDate: _formatDateForApi(season.startDate),
        matchesPerWeekPerTeam: _matchesPerWeekPerTeam,
        weeksBetweenMatches: _weeksBetweenMatches,
        doubleRoundRobin: _doubleRoundRobin,
        allowedWeekdays: _allowedWeekdays,
        roundsPerWeek: _roundsPerWeek,
      );

      if (!mounted) return;
      setState(() => _isSeasonStarted = true);
      _showSuccessMessage('Season started and fixtures generated.');
    } catch (e) {
      _showErrorMessage('Failed to start season: $e');
    } finally {
      if (mounted) {
        setState(() => _isStartingSeason = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final league = widget.league;
    final description = league.description?.trim();
    final rules = league.rules?.trim();
    final seasonForManagement = _plannedSeason ?? _currentSeason;
    final now = DateTime.now();
    final season = _currentSeason;
    final hasActiveSeason =
        season != null &&
        now.isBefore(season.endDate.add(const Duration(days: 1)));
    final canCreateSeason = !(_isSeasonStarted && hasActiveSeason);
    final teamCount = _seasonTeamCount;
    final canStartSeason =
        season != null &&
        !_isSeasonStarted &&
        !_isStartingSeason &&
        !_isLoadingSeasonTeams &&
        teamCount != null &&
        teamCount >= 2 &&
        teamCount <= 24;

    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              heroTag: 'league_admin_settings_nav_bar_${league.leagueId}',
              largeTitle: Text(league.name),
              automaticBackgroundVisibility: false,
              backgroundColor: CupertinoColors.transparent,
              border: null,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  _loadData();
                },
                child: const Icon(CupertinoIcons.refresh),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SectionTitle(title: 'League overview'),
                  const SizedBox(height: Spacing.sm),
                  LeagueOverviewCard(
                    league: league,
                    description: description,
                    rules: rules,
                    isLoadingSeason: _isLoadingSeason,
                    currentSeason: seasonForManagement,
                    seasonStatus: SeasonStatusCard(
                      hasSeason: _currentSeason != null,
                      isSeasonStarted: _isSeasonStarted,
                      isStartingSeason: _isStartingSeason,
                      isLoadingTeams: _isLoadingSeasonTeams,
                      teamCount: _seasonTeamCount,
                      canStartSeason: canStartSeason,
                      onStartSeason: _handleStartSeason,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  if (canCreateSeason) ...[
                    const SectionTitle(title: 'Season setup'),
                    const SizedBox(height: Spacing.sm),
                    if (_seasonPlannerErrorMessage != null)
                      AppGlassContainer(
                        padding: const EdgeInsets.all(Spacing.lg),
                        borderRadius: 20,
                        child: Text(
                          _seasonPlannerErrorMessage!,
                          style: AppTypography.callout.copyWith(
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      )
                    else if (_plannedSeason != null)
                      SeasonPlannerCard(
                        plannedSeason: _plannedSeason!,
                        matchesPerWeekPerTeam: _matchesPerWeekPerTeam,
                        weeksBetweenMatches: _weeksBetweenMatches,
                        doubleRoundRobin: _doubleRoundRobin,
                        allowedWeekdays: _allowedWeekdays,
                        onSaveSeason: _handleSaveSeason,
                      )
                    else
                      AppGlassContainer(
                        padding: const EdgeInsets.all(Spacing.lg),
                        borderRadius: 20,
                        child: Text(
                          'No planned season found in the database.',
                          style: AppTypography.callout.copyWith(
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      ),
                    const SizedBox(height: Spacing.lg),
                  ] else ...[
                    const SectionTitle(title: 'Season setup'),
                    const SizedBox(height: Spacing.sm),
                    AppGlassContainer(
                      padding: const EdgeInsets.all(Spacing.lg),
                      borderRadius: 20,
                      child: Text(
                        'Season in progress. You can create a new season once the current one ends.',
                        style: AppTypography.callout.copyWith(
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                  ],
                  const SectionTitle(title: 'Invitations'),
                  const SizedBox(height: Spacing.sm),
                  LeagueInvitationsSection(
                    league: league,
                    currentSeason: seasonForManagement,
                    seasonTeams: _seasonTeams,
                    errorMessage: _errorMessage,
                    isSeasonStarted: _isSeasonStarted,
                    isLoadingInvitations: _isLoadingInvitations,
                    pendingInvitations: _pendingInvitations,
                    onSendInvitation: _handleSendInvitation,
                    onCancelInvitation: _handleCancelInvitation,
                  ),
                  const SizedBox(height: Spacing.xxxl * 3),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
