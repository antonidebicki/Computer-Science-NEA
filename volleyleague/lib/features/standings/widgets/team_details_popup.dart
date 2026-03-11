import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../design/index.dart';
import '../../../state/cubits/player/player_data_state.dart';

class TeamDetailsPopup extends StatelessWidget {
  final StandingData team;
  final int position;

  const TeamDetailsPopup({
    super.key,
    required this.team,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: CupertinoPopupSurface(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Team Details',
                            style: AppTypography.title1.copyWith(
                              color: CupertinoColors.label,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: CupertinoColors.systemGrey,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getPositionColor(position),
                                    gradient: position == 1
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xffad9c00),
                                              Colors.yellow,
                                              Color(0xffad9c00),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$position',
                                      style: AppTypography.headline.copyWith(
                                        color: position == 1 || position == 2
                                            ? CupertinoColors.black
                                            : CupertinoColors.label,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        team.teamName,
                                        style: AppTypography.headline.copyWith(
                                          color: CupertinoColors.label,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: Spacing.xs),
                                      Text(
                                        '${team.points} pts • Position $position',
                                        style: AppTypography.caption.copyWith(
                                          color: CupertinoColors.secondaryLabel,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacing.lg),
                            const Divider(),
                            const SizedBox(height: Spacing.lg),
                            _buildSectionTitle('Match Statistics'),
                            const SizedBox(height: Spacing.md),
                            _buildStatRow(
                              label: 'Matches Played',
                              value: '${team.matchesPlayed}',
                            ),
                            const SizedBox(height: Spacing.sm),
                            _buildStatRow(
                              label: 'Wins',
                              value: '${team.wins}',
                              valueColor: CupertinoColors.activeGreen,
                            ),
                            const SizedBox(height: Spacing.sm),
                            _buildStatRow(
                              label: 'Losses',
                              value: '${team.losses}',
                              valueColor: CupertinoColors.systemRed,
                            ),
                            const SizedBox(height: Spacing.md),
                            const Divider(),
                            const SizedBox(height: Spacing.md),
                            _buildSectionTitle('Set Statistics'),
                            const SizedBox(height: Spacing.md),
                            _buildStatRow(
                              label: 'Sets Won',
                              value: '${team.setsWon}',
                            ),
                            const SizedBox(height: Spacing.sm),
                            _buildStatRow(
                              label: 'Sets Lost',
                              value: '${team.setsLost}',
                            ),
                            const SizedBox(height: Spacing.sm),
                            _buildStatRow(
                              label: 'Set Difference',
                              value:
                                  '${team.setDiff > 0 ? '+' : ''}${team.setDiff}',
                              valueColor: team.setDiff > 0
                                  ? CupertinoColors.activeGreen
                                  : (team.setDiff < 0
                                        ? CupertinoColors.systemRed
                                        : null),
                            ),
                            const SizedBox(height: Spacing.md),
                            const Divider(),
                            const SizedBox(height: Spacing.md),
                            _buildSectionTitle('Points Statistics'),
                            const SizedBox(height: Spacing.md),
                            _buildStatRow(
                              label: 'Points Scored',
                              value: '${team.pointsWon}',
                            ),
                            const SizedBox(height: Spacing.sm),
                            _buildStatRow(
                              label: 'Points Conceded',
                              value: '${team.pointsLost}',
                            ),
                            const SizedBox(height: Spacing.sm),
                            _buildStatRow(
                              label: 'Point Difference',
                              value:
                                  '${team.pointDiff > 0 ? '+' : ''}${team.pointDiff}',
                              valueColor: team.pointDiff > 0
                                  ? CupertinoColors.activeGreen
                                  : (team.pointDiff < 0
                                        ? CupertinoColors.systemRed
                                        : null),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.headline.copyWith(
        color: CupertinoColors.label,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.secondaryLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: AppTypography.headline.copyWith(
              color: valueColor ?? CupertinoColors.label,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.transparent; // Gold gradient is used
      case 2:
        return const Color(0xFFC0C0C0).withValues(alpha: 0.5); // Silver
      case 3:
        return const Color(0xFFCD7F32).withValues(alpha: 0.5); // Bronze
      default:
        return CupertinoColors.systemGrey5.withValues(alpha: 0.3);
    }
  }
}
