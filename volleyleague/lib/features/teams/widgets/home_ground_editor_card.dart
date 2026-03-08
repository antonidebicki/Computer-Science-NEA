import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design/index.dart';
import '../../../services/repositories/team_repository.dart';
import '../../../services/api_client.dart';
import '../../../state/cubits/coach/team_data_cubit.dart';
import '../../../main.dart';

class HomeGroundEditorCard extends StatefulWidget {
  final int teamId;
  final String? homeGround;

  const HomeGroundEditorCard({
    super.key,
    required this.teamId,
    this.homeGround,
  });

  @override
  State<HomeGroundEditorCard> createState() => _HomeGroundEditorCardState();
}

class _HomeGroundEditorCardState extends State<HomeGroundEditorCard> {
  late TextEditingController _homeGroundController;
  late final TeamRepository _teamRepository;
  bool _isSavingHomeGround = false;
  int? _homeGroundTeamId;

  @override
  void initState() {
    super.initState();
    _homeGroundController = TextEditingController();
    _teamRepository = TeamRepository(ApiClient());
    _syncHomeGround(
      teamId: widget.teamId,
      homeGround: widget.homeGround,
    );
    _loadPersistedHomeGround();
  }

  @override
  void didUpdateWidget(HomeGroundEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamId != widget.teamId) {
      _syncHomeGround(
        teamId: widget.teamId,
        homeGround: widget.homeGround,
      );
      _loadPersistedHomeGround();
      return;
    }

    if (oldWidget.homeGround != widget.homeGround) {
      _syncHomeGround(
        teamId: widget.teamId,
        homeGround: widget.homeGround,
      );
    }
  }

  @override
  void dispose() {
    _homeGroundController.dispose();
    super.dispose();
  }

  void _syncHomeGround({required int teamId, String? homeGround}) {
    if (_homeGroundTeamId == teamId && homeGround == null) {
      return;
    }
    _homeGroundTeamId = teamId;
    _homeGroundController.text = homeGround ?? '';
  }

  Future<void> _loadPersistedHomeGround() async {
    try {
      final team = await _teamRepository.getTeamById(widget.teamId);
      if (!mounted) return;
      _syncHomeGround(
        teamId: widget.teamId,
        homeGround: team?.homeGround,
      );
    } catch (_) {
      // Keep current text if lookup fails.
    }
  }

  Future<void> _saveHomeGround() async {
    final value = _homeGroundController.text.trim();
    setState(() => _isSavingHomeGround = true);

    try {
      final updatedTeam = await _teamRepository.updateTeam(
        teamId: widget.teamId,
        homeGround: value,
      );
      if (!mounted) return;
      _syncHomeGround(
        teamId: widget.teamId,
        homeGround: updatedTeam.homeGround,
      );
      context.read<TeamDataCubit>().refresh();
      _loadPersistedHomeGround();
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Saved'),
          content: const Text('Home ground updated.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMessage =
          e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException(unknown): ', '').replaceFirst('ApiException(', '');
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Failed to save home ground: $errorMessage'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingHomeGround = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team home ground',
          style: AppTypography.headline.copyWith(
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: Spacing.md),
        AppGlassContainer(
          padding: const EdgeInsets.all(Spacing.lg),
          child: KeyboardDismissArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Venue name',
                style: AppTypography.callout.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              AppLiquidGlassTextField(
                controller: _homeGroundController,
                placeholder: 'e.g. Riverside Sports Hall',
              ),
              const SizedBox(height: Spacing.md),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isSavingHomeGround ? null : _saveHomeGround,
                  child: _isSavingHomeGround
                      ? const CupertinoActivityIndicator(
                          radius: 8,
                        )
                      : const Text('Save home ground'),
                ),
              ),
            ],
            ),
          ),
        ),
      ],
    );
  }
}
