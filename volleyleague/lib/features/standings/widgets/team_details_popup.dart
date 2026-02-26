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
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: AppGlassContainer(
            padding: const EdgeInsets.all(Spacing.lg),
            borderRadius: 24,
            blur: 15,
            color: CupertinoColors.white.withValues(alpha: 0.3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Team Details',
                      style: AppTypography.headline.copyWith(
                        color: CupertinoColors.label,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: CupertinoColors.systemGrey,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),

                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Team name and position
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
                                        colors: [Color(0xffad9c00), Colors.yellow, Color(0xffad9c00)],
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.teamName,
                                    style: AppTypography.body.copyWith(
                                      color: CupertinoColors.label,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Position $position • ${team.points} pts',
                                    style: AppTypography.footnote.copyWith(
                                      color: CupertinoColors.secondaryLabel,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: Spacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: Spacing.md),

                        // Match Statistics
                        _buildSectionTitle('Match Statistics'),
                        const SizedBox(height: Spacing.sm),
                        _buildStatRow(
                          label: 'Matches Played',
                          value: '${team.matchesPlayed}',
                          icon: CupertinoIcons.calendar,
                        ),
                        const SizedBox(height: Spacing.xs),
                        _buildStatRow(
                          label: 'Wins',
                          value: '${team.wins}',
                          icon: CupertinoIcons.checkmark_circle,
                          valueColor: CupertinoColors.activeGreen,
                        ),
                        const SizedBox(height: Spacing.xs),
                        _buildStatRow(
                          label: 'Losses',
                          value: '${team.losses}',
                          icon: CupertinoIcons.xmark_circle,
                          valueColor: CupertinoColors.systemRed,
                        ),

                        const SizedBox(height: Spacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: Spacing.md),

                        // Set Statistics
                        _buildSectionTitle('Set Statistics'),
                        const SizedBox(height: Spacing.sm),
                        _buildStatRow(
                          label: 'Sets Won',
                          value: '${team.setsWon}',
                        ),
                        const SizedBox(height: Spacing.xs),
                        _buildStatRow(
                          label: 'Sets Lost',
                          value: '${team.setsLost}',
                        ),
                        const SizedBox(height: Spacing.xs),
                        _buildStatRow(
                          label: 'Set Difference',
                          value: '${team.setDiff > 0 ? '+' : ''}${team.setDiff}',
                          valueColor: team.setDiff > 0
                              ? CupertinoColors.activeGreen
                              : (team.setDiff < 0 ? CupertinoColors.systemRed : null),
                        ),

                        const SizedBox(height: Spacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: Spacing.md),

                        // Points Statistics
                        _buildSectionTitle('Points Statistics'),
                        const SizedBox(height: Spacing.sm),
                        _buildStatRow(
                          label: 'Points Scored',
                          value: '${team.pointsWon}',
                        ),
                        const SizedBox(height: Spacing.xs),
                        _buildStatRow(
                          label: 'Points Conceded',
                          value: '${team.pointsLost}',
                        ),
                        const SizedBox(height: Spacing.xs),
                        _buildStatRow(
                          label: 'Point Difference',
                          value: '${team.pointDiff > 0 ? '+' : ''}${team.pointDiff}',
                          valueColor: team.pointDiff > 0
                              ? CupertinoColors.activeGreen
                              : (team.pointDiff < 0 ? CupertinoColors.systemRed : null),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: Spacing.md),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.callout.copyWith(
        color: CupertinoColors.label,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    IconData? icon,
    Color? valueColor,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(width: Spacing.xs),
        ],
        Expanded(
          child: Text(
            label,
            style: AppTypography.footnote.copyWith(
              color: CupertinoColors.secondaryLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: AppTypography.callout.copyWith(
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
