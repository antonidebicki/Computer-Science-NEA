import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../core/models/invitation.dart';
import '../../../core/models/league.dart';
import '../../../core/models/season.dart';
import '../../../design/index.dart';
import '../../../services/api_client.dart';
import '../../../services/repositories/invitation_repository.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../state/providers/theme_provider.dart';
import '../widgets/league_invitation_input_widget.dart';
import '../widgets/league_pending_invitations_widget.dart';
import '../widgets/season_info.dart';

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

  List<LeagueJoinRequest> _pendingInvitations = [];
  Season? _currentSeason;
  bool _isLoadingInvitations = false;
  bool _isLoadingSeason = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _invitationRepository = InvitationRepository(ApiClient());
    _leagueRepository = LeagueRepository(ApiClient());
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCurrentSeason(),
      _loadPendingInvitations(),
    ]);
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

      Season? selected;
      if (active.isNotEmpty) {
        selected = active.first;
      } else {
        final nonArchived = seasons.where((s) => !s.isArchived).toList();
        nonArchived.sort((a, b) => b.startDate.compareTo(a.startDate));
        selected = nonArchived.isNotEmpty ? nonArchived.first : null;
      }

      setState(() => _currentSeason = selected);
    } catch (e) {
      setState(() => _currentSeason = null);
    } finally {
      if (mounted) {
        setState(() => _isLoadingSeason = false);
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final league = widget.league;
    final description = league.description?.trim();
    final rules = league.rules?.trim();

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
                  AppGlassContainer(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'League Overview',
                          style: AppTypography.headline.copyWith(
                            color: CupertinoColors.label,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          league.name,
                          style: AppTypography.body.copyWith(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        if (description != null && description.isNotEmpty) ...[
                          const SizedBox(height: Spacing.md),
                          Text(
                            'Description',
                            style: AppTypography.caption.copyWith(
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            description,
                            style: AppTypography.body.copyWith(
                              color: CupertinoColors.label,
                            ),
                          ),
                        ],
                        if (rules != null && rules.isNotEmpty) ...[
                          const SizedBox(height: Spacing.md),
                          Text(
                            'Rules',
                            style: AppTypography.caption.copyWith(
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            rules,
                            style: AppTypography.body.copyWith(
                              color: CupertinoColors.label,
                            ),
                          ),
                        ],
                        const SizedBox(height: Spacing.md),
                        if (_isLoadingSeason)
                          const CupertinoActivityIndicator(radius: 10)
                        else
                          SeasonInfo(season: _currentSeason),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      margin: const EdgeInsets.only(bottom: Spacing.lg),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CupertinoColors.systemRed.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.callout.copyWith(
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ),
                  LeagueInvitationInputWidget(
                    leagueId: league.leagueId,
                    seasonId: _currentSeason?.seasonId,
                    leagueName: league.name,
                    seasonName: _currentSeason?.name,
                    onSendInvitation: _handleSendInvitation,
                  ),
                  const SizedBox(height: Spacing.lg),
                  if (_isLoadingInvitations)
                    const Center(
                      child: CupertinoActivityIndicator(radius: 16),
                    )
                  else
                    LeaguePendingInvitationsWidget(
                      pendingInvitations: _pendingInvitations,
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
