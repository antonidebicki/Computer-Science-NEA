import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/league.dart';
import '../../../design/index.dart';
import '../../../services/api_client.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../state/cubits/auth/auth_cubit.dart';
import '../../../state/cubits/auth/auth_state.dart';

class NewLeague extends StatefulWidget {
  final ValueChanged<League>? onLeagueCreated;

  const NewLeague({super.key, this.onLeagueCreated});

  @override
  State<NewLeague> createState() => _NewLeagueState();
}

class _NewLeagueState extends State<NewLeague> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rulesController = TextEditingController();

  late final LeagueRepository _leagueRepository;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _leagueRepository = LeagueRepository(ApiClient());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final rules = _rulesController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'League name is required.');
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      setState(() => _errorMessage = 'Please sign in to create a league.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      final league = await _leagueRepository.createLeague(
        name: name,
        adminUserId: authState.user.userId,
        description: description.isEmpty ? null : description,
        rules: rules.isEmpty ? null : rules,
      );
      if (!mounted) return;
      widget.onLeagueCreated?.call(league);
      _nameController.clear();
      _descriptionController.clear();
      _rulesController.clear();
      _showSuccessMessage('League created successfully.');
    } catch (e) {
      if (!mounted) return;
      final message = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiException(unknown): ', '')
          .replaceFirst('ApiException(', '')
          .replaceFirst(')', '');
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create New League',
            style: AppTypography.headline.copyWith(
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Set up the league details so teams can join and play fixtures.',
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          _buildInputField(
            label: 'League Name',
            controller: _nameController,
            placeholder: 'e.g. Bucks County League',
          ),
          const SizedBox(height: Spacing.md),
          _buildInputField(
            label: 'Description (optional)',
            controller: _descriptionController,
            placeholder: 'Overview, age group, location',
            maxLines: 3,
          ),
          const SizedBox(height: Spacing.md),
          _buildInputField(
            label: 'Rules (optional)',
            controller: _rulesController,
            placeholder: 'Match format, points system, tie-breakers',
            maxLines: 4,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              _errorMessage!,
              style: AppTypography.callout.copyWith(
                color: CupertinoColors.systemRed,
              ),
            ),
          ],
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const CupertinoActivityIndicator(radius: 8)
                  : const Text('Create League'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        AppGlassContainer(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          borderRadius: 12,
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            decoration: const BoxDecoration(),
            style: AppTypography.body.copyWith(
              color: CupertinoColors.label,
            ),
            minLines: maxLines == 1 ? 1 : maxLines,
            maxLines: maxLines,
          ),
        ),
      ],
    );
  }
}