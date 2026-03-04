import 'package:flutter/cupertino.dart';
import '../../design/index.dart';
import '../../state/cubits/player/player_data_state.dart';
import 'standings_table_header.dart';
import 'modern_standing_row.dart';

class LeagueStandingsData {
  final String leagueName;
  final List<StandingData> standings;

  const LeagueStandingsData({
    required this.leagueName,
    required this.standings,
  });
}


class StandingsWidget extends StatefulWidget {
  final List<LeagueStandingsData> leagues;

  const StandingsWidget({super.key, required this.leagues});

  @override
  State<StandingsWidget> createState() => _StandingsWidgetState();
}

class _StandingsWidgetState extends State<StandingsWidget> {
  int _selectedLeagueIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.leagues.isEmpty) {
      return const NoLeagueWidget();
    }

    final currentLeague = widget.leagues[_selectedLeagueIndex];

    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.leagues.length > 1) ...[
            AppDropdown<int>(
              value: _selectedLeagueIndex,
              width: double.infinity,
              items: widget.leagues.asMap().entries.map((entry) {
                return DropdownItem<int>(
                  value: entry.key,
                  label: entry.value.leagueName,
                );
              }).toList(),
              onChanged: (index) {
                setState(() {
                  _selectedLeagueIndex = index;
                });
              },
            ),
            const SizedBox(height: Spacing.lg),
          ] else ...[
            Text(
              currentLeague.leagueName,
              style: AppTypography.headline.copyWith(
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: Spacing.lg),
          ],
          //temporary hardcoded pixel values just to make it look nice on the main testing device
          const StandingsTableHeader(cellWidthMultiplier: 1, leftPadding: 25.0, rightPadding: 15.0),
          const SizedBox(height: Spacing.sm),

          ...currentLeague.standings.asMap().entries.map((entry) {
            final index = entry.key;
            final standing = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < currentLeague.standings.length - 1
                    ? Spacing.sm
                    : 0,
              ),
              child: ModernStandingRow(
                position: index + 1,
                teamName: standing.teamName,
                matchesPlayed: standing.matchesPlayed,
                wins: standing.wins,
                losses: standing.losses,
                points: standing.points,
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// shown when user doesn't belong to any league
class NoLeagueWidget extends StatelessWidget {
  const NoLeagueWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        children: [
          AppIcons.league(fontSize: 48, color: CupertinoColors.systemGrey),
          const SizedBox(height: Spacing.lg),
          Text(
            'No League',
            style: AppTypography.headline.copyWith(
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'You are not part of any league yet',
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
