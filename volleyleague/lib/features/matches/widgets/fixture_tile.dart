import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../design/index.dart';
import '../../../core/models/models.dart';

/// A single fixture row rendered on a liquid glass card.
class FixtureTile extends StatelessWidget {
  final Match match;
  final Map<int, Team> teams;

  const FixtureTile({super.key, required this.match, required this.teams});

  @override
  Widget build(BuildContext context) {
    final home = teams[match.homeTeamId];
    final away = teams[match.awayTeamId];
    final time = _formatTime(match.matchDatetime);
    final venue = match.venue ?? 'TBD';
    final statusText = _statusText(match.status);
    final statusColor = _statusColor(match.status);

    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 20,
      blur: 18,
      color: CupertinoColors.white.withValues(alpha: 0.20),
      borderColor: CupertinoColors.white.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _TimeBadge(text: time),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TeamLine(name: home?.name ?? 'Home', logoUrl: home?.logoUrl, alignRight: false),
                    const SizedBox(height: Spacing.xs),
                    _VsDivider(),
                    const SizedBox(height: Spacing.xs),
                    _TeamLine(name: away?.name ?? 'Away', logoUrl: away?.logoUrl, alignRight: false),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),
              _StatusPill(text: statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              const Icon(CupertinoIcons.location_solid, size: 16, color: CupertinoColors.systemGrey),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: AppText(
                  venue,
                  style: AppTypography.footnote.copyWith(color: CupertinoColors.systemGrey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime? dt) {
    if (dt == null) return 'TBD';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  static String _statusText(GameState s) {
    switch (s) {
      case GameState.scheduled:
      case GameState.unscheduled:
        return 'Upcoming';
      case GameState.finished:
        return 'Finished';
      case GameState.processed:
        return 'Processed';
    }
  }

  static Color _statusColor(GameState s) {
    switch (s) {
      case GameState.scheduled:
      case GameState.unscheduled:
        return CupertinoColors.activeBlue;
      case GameState.finished:
        return CupertinoColors.systemGreen;
      case GameState.processed:
        return CupertinoColors.systemGrey;
    }
  }
}

class _TimeBadge extends StatelessWidget {
  final String text;
  const _TimeBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: CupertinoColors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: AppText(
        text,
        style: AppTypography.subhead.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final bool alignRight;
  const _TeamLine({required this.name, required this.logoUrl, required this.alignRight});

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 14,
      backgroundColor: CupertinoColors.systemGrey.withOpacity(0.2),
      backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
      child: logoUrl == null ? AppText(name.isNotEmpty ? name[0].toUpperCase() : '?') : null,
    );

    final label = AppText(
      name,
      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
    );

    return Row(
      children: alignRight ? [Expanded(child: label), const SizedBox(width: Spacing.sm), avatar] : [avatar, const SizedBox(width: Spacing.sm), Expanded(child: label)],
    );
  }
}

class _VsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: CupertinoColors.systemGrey4.withOpacity(0.6))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
          child: AppText('VS', style: AppTypography.footnote),
        ),
        Expanded(child: Container(height: 1, color: CupertinoColors.systemGrey4.withOpacity(0.6))),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: AppText(
        text,
        style: AppTypography.footnote.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
