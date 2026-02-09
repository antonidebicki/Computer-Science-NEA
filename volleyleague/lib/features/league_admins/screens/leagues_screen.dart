import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../services/api_client.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../core/models/league.dart';
import '../widgets/league_admin_leagues_header_card.dart';
import '../widgets/new_league.dart';
import 'league_settings_screen.dart';

class LeagueAdminLeaguesScreen extends StatefulWidget {
  const LeagueAdminLeaguesScreen({super.key});

  @override
  State<LeagueAdminLeaguesScreen> createState() =>
      _LeagueAdminLeaguesScreenState();
}

class _LeagueAdminLeaguesScreenState extends State<LeagueAdminLeaguesScreen> {
  late LeagueRepository _leagueRepository;
  String? _errorMessage;
  List<League> _leagues = [];
  bool _isLoadingLeagues = false;

  @override
  void initState() {
    super.initState();
    _leagueRepository = LeagueRepository(ApiClient());
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    setState(() => _isLoadingLeagues = true);
    try {
      final leagues = await _leagueRepository.getLeagues();
      setState(() {
        _leagues = leagues;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load leagues: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLeagues = false);
      }
    }
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
                  LeagueAdminLeaguesHeaderCard(
                    leaguesContent: _buildLeagueButtons(context),
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
                      });
                    },
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

  Widget _buildLeagueButtons(BuildContext context) {
    if (_isLoadingLeagues) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_leagues.isEmpty) {
      return Text(
        'No leagues available yet. Create your first league below.',
        style: AppTypography.callout.copyWith(
          color: CupertinoColors.secondaryLabel,
        ),
      );
    }

    return Column(
      children: _leagues.map((league) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: AppGlassContainer(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            borderRadius: 12,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => LeagueAdminLeagueSettingsScreen(
                      league: league,
                    ),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      league.name,
                      style: AppTypography.body.copyWith(
                        color: CupertinoColors.label,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_forward,
                    color: CupertinoColors.activeBlue,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
