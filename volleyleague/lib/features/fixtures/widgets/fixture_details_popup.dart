import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/models/match_data.dart';
import '../../../core/models/volleyball_set.dart';
import '../../../design/index.dart';
import '../../../services/api_client.dart';
import '../../../services/repositories/match_repository.dart';

class FixtureDetailsPopup extends StatefulWidget {
  final MatchData fixture;

  const FixtureDetailsPopup({super.key, required this.fixture});

  @override
  State<FixtureDetailsPopup> createState() => _FixtureDetailsPopupState();
}

class _FixtureDetailsPopupState extends State<FixtureDetailsPopup> {
  List<VolleyballSet>? _sets;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    try {
      final repository = MatchRepository(ApiClient());
      final sets = await repository.getMatchSets(widget.fixture.match.matchId);
      if (mounted) {
        setState(() {
          _sets = sets;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load set scores';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      minimum: const EdgeInsets.symmetric(vertical: Spacing.lg),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDialogHeight),
            child: AppGlassContainer(
              padding: const EdgeInsets.all(Spacing.xl),
              borderRadius: 32,
              blur: 15,
              color: CupertinoColors.white.withValues(alpha: 0.3),
              disableShadow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Match Details',
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

                  // Teams
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.fixture.homeTeamName,
                              style: AppTypography.headline.copyWith(
                                color: CupertinoColors.label,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              'Home',
                              style: AppTypography.caption.copyWith(
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${widget.fixture.match.homeSetsWon}',
                              style: AppTypography.largeTitle.copyWith(
                                color: CupertinoColors.label,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Text(
                              '-',
                              style: AppTypography.title1.copyWith(
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Text(
                              '${widget.fixture.match.awaySetsWon}',
                              style: AppTypography.largeTitle.copyWith(
                                color: CupertinoColors.label,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.fixture.awayTeamName,
                              style: AppTypography.headline.copyWith(
                                color: CupertinoColors.label,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              'Away',
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

                  // Date and Venue
                  if (widget.fixture.match.matchDatetime != null) ...[
                    _buildInfoRow(
                      icon: CupertinoIcons.calendar,
                      label: 'Date',
                      value: _formatDate(widget.fixture.match.matchDatetime!),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _buildInfoRow(
                      icon: CupertinoIcons.clock,
                      label: 'Time',
                      value: _formatTime(widget.fixture.match.matchDatetime!),
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],

                  if (widget.fixture.match.venue != null) ...[
                    _buildInfoRow(
                      icon: CupertinoIcons.location_solid,
                      label: 'Venue',
                      value: widget.fixture.match.venue!,
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],

                  _buildInfoRow(
                    icon: CupertinoIcons.info_circle,
                    label: 'Status',
                    value: _getStatusText(widget.fixture.match.status.value),
                  ),

                  const SizedBox(height: Spacing.lg),
                  const Divider(),
                  const SizedBox(height: Spacing.lg),

                  // Keep set rows in their own scroll region to avoid dialog overflow.
                  Text(
                    'Set Scores',
                    style: AppTypography.headline.copyWith(
                      color: CupertinoColors.label,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Flexible(child: _buildSetScoresContent()),

                  const SizedBox(height: Spacing.lg),

                  // Close Button
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
    );
  }

  Widget _buildSetScoresContent() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Spacing.lg),
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Text(
            _errorMessage!,
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.systemRed,
            ),
          ),
        ),
      );
    }

    if (_sets == null || _sets!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Text(
            'No set scores available',
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _sets!.length,
      itemBuilder: (context, index) => _buildSetScore(_sets![index]),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: CupertinoColors.systemGrey),
        const SizedBox(width: Spacing.sm),
        Text(
          '$label: ',
          style: AppTypography.callout.copyWith(
            color: CupertinoColors.secondaryLabel,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.callout.copyWith(color: CupertinoColors.label),
          ),
        ),
      ],
    );
  }

  Widget _buildSetScore(VolleyballSet set) {
    final homeWon = set.homeTeamScore > set.awayTeamScore;
    final awayWon = set.awayTeamScore > set.homeTeamScore;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Set ${set.setNumber}',
                style: AppTypography.body.copyWith(
                  color: CupertinoColors.label,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: homeWon
                    ? CupertinoColors.activeGreen.withValues(alpha: 0.2)
                    : CupertinoColors.systemGrey5.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${set.homeTeamScore}',
                style: AppTypography.headline.copyWith(
                  color: homeWon
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.label,
                  fontWeight: homeWon ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: Text(
                '-',
                style: AppTypography.body.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: awayWon
                    ? CupertinoColors.activeGreen.withValues(alpha: 0.2)
                    : CupertinoColors.systemGrey5.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${set.awayTeamScore}',
                style: AppTypography.headline.copyWith(
                  color: awayWon
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.label,
                  fontWeight: awayWon ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return 'Scheduled';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'FINISHED':
        return 'Finished';
      case 'PROCESSED':
        return 'Final';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final weekday = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][date.weekday - 1];
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][date.month - 1];
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
