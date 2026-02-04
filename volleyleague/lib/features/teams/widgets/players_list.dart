import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../core/models/team_member.dart';
import '../../../state/providers/theme_provider.dart';

class PlayersList extends StatelessWidget {
  final List<TeamMember> players;
  
  const PlayersList({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    if (players.isEmpty) {
      return AppGlassContainer(
        padding: const EdgeInsets.all(Spacing.lg),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Players',
              style: AppTypography.headline.copyWith(
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: Spacing.md),
            Center(
              child: Text(
                'No players in this team yet',
                style: AppTypography.callout.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team Players',
                style: AppTypography.headline.copyWith(
                  color: CupertinoColors.label,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${players.length}',
                  style: AppTypography.callout.copyWith(
                    color: CupertinoColors.activeBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          ...players.map((player) => _buildPlayerCard(player, isDark)),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(TeamMember player, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CupertinoColors.systemGrey6.withValues(alpha: 0.3),
            CupertinoColors.systemGrey6.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          //container for profile, actual images will be implemented later
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.person_fill,
                  color: CupertinoColors.systemGrey,
                  size: 20,
                ),
              ),
            ),
          const SizedBox(width: Spacing.md),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.fullName?.isNotEmpty == true 
                          ? player.fullName!
                          : player.username,
                      style: AppTypography.body.copyWith(
                        color: CupertinoColors.label,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (player.playerNumber != null) ...[
                      const SizedBox(width: Spacing.sm),
                      Text(
                        '#${player.playerNumber}',
                        style: AppTypography.body.copyWith(
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Row(
                  children: [
                    Text(
                      player.roleInTeam,
                      style: AppTypography.caption.copyWith(
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    if (player.isCaptain) ...[
                      const SizedBox(width: Spacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemYellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Captain',
                          style: AppTypography.caption.copyWith(
                            color: CupertinoColors.systemYellow,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (player.isLibero) ...[
                      const SizedBox(width: Spacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Libero',
                          style: AppTypography.caption.copyWith(
                            color: CupertinoColors.systemPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}