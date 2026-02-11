import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../services/api_client.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../services/repositories/invitation_repository.dart';
import '../../../core/models/invitation.dart';
import '../../../core/models/league.dart';
import '../../../core/models/season.dart';
import '../widgets/league_invitation_input_widget.dart';
import '../widgets/league_pending_invitations_widget.dart';
import '../widgets/league_picker.dart';
import '../widgets/season_info.dart';
import '../widgets/league_admin_leagues_header_card.dart';
import '../widgets/new_league.dart';

class LeagueAdminLeaguesScreen extends StatefulWidget {
  const LeagueAdminLeaguesScreen({super.key});

  @override
  State<LeagueAdminLeaguesScreen> createState() =>
      _LeagueAdminLeaguesScreenState();
}

class _LeagueAdminLeaguesScreenState extends State<LeagueAdminLeaguesScreen> {
  late InvitationRepository _invitationRepository;
  late LeagueRepository _leagueRepository;
  List<LeagueJoinRequest> _pendingInvitations = [];
  bool _isLoadingInvitations = false;
  String? _errorMessage;
  List<League> _leagues = [];
  League? _selectedLeague;
  Season? _currentSeason;
  bool _isLoadingLeagues = false;

  @override
  void initState() {
    super.initState();
    _invitationRepository = InvitationRepository(ApiClient());
    _leagueRepository = LeagueRepository(ApiClient());
    _loadPendingInvitations();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    setState(() => _isLoadingLeagues = true);
    try {
      final leagues = await _leagueRepository.getLeagues();
      setState(() {
        _leagues = leagues;
        _selectedLeague = leagues.isNotEmpty ? leagues.first : null;
      });
      await _loadCurrentSeason();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load leagues: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLeagues = false);
      }
    }
  }

  Future<void> _loadCurrentSeason() async {
    final league = _selectedLeague;
    if (league == null) {
      setState(() => _currentSeason = null);
      return;
    }

    try {
      final seasons = await _leagueRepository.getSeasons(league.leagueId);
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
    }
  }

  Future<void> _loadPendingInvitations() async {
    setState(() => _isLoadingInvitations = true);
    try {
      final invitations =
          await _invitationRepository.getSentLeagueInvitations();
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

    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              heroTag: 'league_admin_leagues_nav_bar',
              largeTitle: const Text('My Leagues'),
              automaticBackgroundVisibility: false,
              backgroundColor: CupertinoColors.transparent,
              border: null,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  _loadPendingInvitations();
                  _loadLeagues();
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
                  LeaguesHeaderCard(
                    leaguesContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LeaguePicker(
                          isLoading: _isLoadingLeagues,
                          leagues: _leagues,
                          selectedLeague: _selectedLeague,
                          onSelected: (league) async {
                            setState(() => _selectedLeague = league);
                            await _loadCurrentSeason();
                          },
                        ),
                        const SizedBox(height: Spacing.md),
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
                  NewLeague(
                    onLeagueCreated: (league) async {
                      setState(() {
                        _leagues = [..._leagues, league];
                        _selectedLeague = league;
                      });
                      await _loadCurrentSeason();
                    },
                  ),
                  const SizedBox(height: Spacing.lg),
                  LeagueInvitationInputWidget(
                    leagueId: _selectedLeague?.leagueId,
                    seasonId: _currentSeason?.seasonId,
                    leagueName: _selectedLeague?.name,
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
                  const SizedBox(height: Spacing.xxxl*3),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
