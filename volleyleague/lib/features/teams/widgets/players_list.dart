import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../core/models/team_member.dart';
import '../../../state/providers/theme_provider.dart';

class PlayersList extends StatelessWidget {
  final List<TeamMember> players;
  final Future<void> Function(TeamMember player, int playerNumber)?
      onUpdatePlayerNumber;
  
  const PlayersList({
    super.key,
    required this.players,
    this.onUpdatePlayerNumber,
  });

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
          ...players.map((player) => _buildPlayerCard(player, isDark, context)),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(
    TeamMember player,
    bool isDark,
    BuildContext context,
  ) {
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
                    const SizedBox(width: Spacing.sm),
                    Builder(
                      builder: (buttonContext) {
                        return CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: onUpdatePlayerNumber == null
                              ? null
                              : () {
                                  final box = buttonContext.findRenderObject()
                                      as RenderBox;
                                  final overlay = Overlay.of(buttonContext)
                                      .context
                                      .findRenderObject() as RenderBox;
                                  final offset = box.localToGlobal(
                                    Offset.zero,
                                    ancestor: overlay,
                                  );
                                  final rect = offset & box.size;
                                  _showPlayerNumberPopover(
                                    buttonContext,
                                    player,
                                    rect,
                                  );
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.sm,
                              vertical: Spacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  player.playerNumber != null
                                      ? '#${player.playerNumber}'
                                      : 'Set #',
                                  style: AppTypography.caption.copyWith(
                                    color: CupertinoColors.activeBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  CupertinoIcons.chevron_down,
                                  size: 12,
                                  color: CupertinoColors.activeBlue,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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

  Future<void> _showPlayerNumberPopover(
    BuildContext context,
    TeamMember player,
    Rect anchorRect,
  ) async {
    if (onUpdatePlayerNumber == null) {
      return;
    }

    final controller = TextEditingController(
      text: player.playerNumber?.toString() ?? '',
    );
    final focusNode = FocusNode();
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final screenSize = overlay.size;
    const popoverWidth = 220.0;
    const popoverHeight = 170.0;
    const padding = 12.0;
    final left = (anchorRect.left)
        .clamp(padding, screenSize.width - popoverWidth - padding)
        .toDouble();
    final top = (anchorRect.bottom + Spacing.xs)
        .clamp(padding, screenSize.height - popoverHeight - padding)
        .toDouble();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: CupertinoColors.black.withValues(alpha: 0.15),
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Color(0x00000000),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: CupertinoPopupSurface(
                child: SizedBox(
                  width: popoverWidth,
                  height: popoverHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Player Number',
                          style: AppTypography.subhead.copyWith(
                            color: CupertinoColors.label,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        CupertinoTextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          placeholder: 'Enter Player Number',
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: CupertinoButton.filled(
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  final raw = controller.text.trim();
                                  final parsed = int.tryParse(raw);
                                  if (parsed == null || parsed <= 0) {
                                    return;
                                  }

                                  Navigator.pop(context);
                                  await onUpdatePlayerNumber!(player, parsed);
                                },
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
    );

    controller.dispose();
    focusNode.dispose();
  }
}