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
import '../widgets/league_invitations_section.dart';
import '../widgets/league_overview_card.dart';
import '../widgets/season_planner_card.dart';
import '../widgets/season_status_card.dart';
import '../widgets/section_title.dart';

class LeagueAdminLeagueSettingsScreen extends StatefulWidget {
  final League league;

  const LeagueAdminLeagueSettingsScreen({
    super.key,
    required this.league,
  });

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
  int? _seasonTeamCount;
  bool _isLoadingSeasonTeams = false;
  int _matchesPerWeekPerTeam = 1;
  int _weeksBetweenMatches = 1;
  bool _doubleRoundRobin = false;
  List<int> _allowedWeekdays = const [1, 3, 5];

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

  Future<void> _loadCurrentSeason() async {
    setState(() => _isLoadingSeason = true);
    try {
      final seasons =
          await _leagueRepository.getSeasons(widget.league.leagueId);
      final now = DateTime.now();
      final active = seasons.where((season) {
        return !season.isArchived &&
            now.isAfter(season.startDate) &&
            now.isBefore(season.endDate.add(const Duration(days: 1)));
      }).toList();
      final plannedSeasons = seasons.where((season) {
        return !season.isArchived && season.startDate.isAfter(now);
      }).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      final planned = plannedSeasons.isNotEmpty ? plannedSeasons.first : null;

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

      setState(() {
        _plannedSeason = planned;
        _currentSeason = selected;
        _applySeasonPlannerSettings(planned ?? selected);
      });
      await _loadSeasonTeamsCount();
      await _loadSeasonStarted();
    } catch (e) {
      setState(() {
        _currentSeason = null;
        _isSeasonStarted = false;
        _seasonTeamCount = null;
        _plannedSeason = null;
        _applySeasonPlannerSettings(null);
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
    final season = _currentSeason;
    if (season == null) {
      setState(() => _seasonTeamCount = null);
      return;
    }

    setState(() => _isLoadingSeasonTeams = true);
    try {
      final teams = await _leagueRepository.getSeasonTeams(season.seasonId);
      if (!mounted) return;
      setState(() => _seasonTeamCount = teams.length);
    } catch (e) {
      if (!mounted) return;
      setState(() => _seasonTeamCount = null);
    } finally {
      if (mounted) {
        setState(() => _isLoadingSeasonTeams = false);
      }
    }
  }

  Future<void> _loadPendingInvitations() async {
    setState(() => _isLoadingInvitations = true);
    try {
      final invitations = await _invitationRepository
          .getSentLeagueInvitations(leagueId: widget.league.leagueId);
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
      final invitation =
          await _invitationRepository.createLeagueInvitation(request);
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
        _pendingInvitations
            .removeWhere((inv) => inv.joinRequestId == joinRequestId);
        _errorMessage = null;
      });
      _showSuccessMessage('Invitation cancelled');
    } catch (e) {
      _showErrorMessage('Failed to cancel invitation: $e');
    }
  }

  void _showErrorMessage(String message) {
    setState(() => _errorMessage = message);
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
  }) async {
    try {
      final now = DateTime.now();
      final planned = _plannedSeason;
      final isEditingPlanned =
          planned != null && planned.startDate.isAfter(now);

      final season = isEditingPlanned
          ? await _leagueRepository.updateSeason(
              seasonId: planned.seasonId,
              name: seasonName,
              startDate: startDate,
              endDate: endDate,
              matchesPerWeekPerTeam: matchesPerWeekPerTeam,
              weeksBetweenMatches: weeksBetweenMatches,
              doubleRoundRobin: doubleRoundRobin,
              allowedWeekdays: allowedWeekdays,
            )
          : await _leagueRepository.createSeason(
              leagueId: widget.league.leagueId,
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
        _currentSeason = season;
        _isSeasonStarted = false;
        _seasonTeamCount = 0;
        _matchesPerWeekPerTeam = matchesPerWeekPerTeam;
        _weeksBetweenMatches = weeksBetweenMatches;
        _doubleRoundRobin = doubleRoundRobin;
        _allowedWeekdays = allowedWeekdays;
        _errorMessage = null;
        _plannedSeason =
            (!season.isArchived && season.startDate.isAfter(now))
                ? season
                : null;
      });
      await _loadSeasonTeamsCount();
      await _loadPendingInvitations();
      _showSuccessMessage('Season saved successfully.');
    } catch (e) {
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
    final now = DateTime.now();
    final season = _currentSeason;
    final hasActiveSeason = season != null &&
        now.isBefore(season.endDate.add(const Duration(days: 1)));
    final canCreateSeason = !(_isSeasonStarted && hasActiveSeason);
    final teamCount = _seasonTeamCount;
    final canStartSeason = season != null &&
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
                    currentSeason: _currentSeason,
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
                    SeasonPlannerCard(
                      plannedSeason: _plannedSeason,
                      matchesPerWeekPerTeam: _matchesPerWeekPerTeam,
                      weeksBetweenMatches: _weeksBetweenMatches,
                      doubleRoundRobin: _doubleRoundRobin,
                      allowedWeekdays: _allowedWeekdays,
                      onSaveSeason: _handleSaveSeason,
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
                    currentSeason: _currentSeason,
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
