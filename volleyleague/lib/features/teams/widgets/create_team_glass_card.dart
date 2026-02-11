import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

class CreateTeamGlassCard extends StatefulWidget {
  final bool isDark;
  final Future<void> Function(String teamName, String? logoUrl) onCreateTeam;

  const CreateTeamGlassCard({
    super.key,
    required this.isDark,
    required this.onCreateTeam,
  });

  @override
  State<CreateTeamGlassCard> createState() => _CreateTeamGlassCardState();
}

class _CreateTeamGlassCardState extends State<CreateTeamGlassCard> {
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _teamNameController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final teamName = _teamNameController.text.trim();
    final logoUrl = _logoUrlController.text.trim();

    if (teamName.isEmpty) {
      setState(() => _errorMessage = 'Team name is required.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      await widget.onCreateTeam(
        teamName,
        logoUrl.isEmpty ? null : logoUrl,
      );
      if (mounted) {
        _teamNameController.clear();
        _logoUrlController.clear();
      }
    } catch (e) {
      if (mounted) {
        final message = e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('ApiException(unknown): ', '')
            .replaceFirst('ApiException(', '');
        setState(() => _errorMessage = message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // colours are the same bc isDark has been implemented for future development, not for right now
    final glassColor = widget.isDark
        ? const Color(0x33FFFFFF)
        : const Color(0x33FFFFFF);
    final borderColor = widget.isDark
        ? const Color(0x44FFFFFF)
        : const Color(0x44FFFFFF);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),
        Positioned(
          right: -40,
          top: -50,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
          ),
        ),
        AppGlassContainer(
          borderRadius: 32,
          color: glassColor,
          borderColor: borderColor,
          blur: 18,
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CupertinoColors.systemTeal.withOpacity(0.2),
                    ),
                    child: const Icon(
                      CupertinoIcons.group_solid,
                      color: CupertinoColors.systemTeal,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      'Create Your Team',
                      style: AppTypography.headline.copyWith(
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Set up the basics so you can invite players and join leagues.',
                style: AppTypography.callout.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'Team Name',
                style: AppTypography.subhead.copyWith(
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              AppTextField(
                controller: _teamNameController,
                placeholder: 'e.g. South Bucks',
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Logo URL (optional)',
                style: AppTypography.subhead.copyWith(
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              AppTextField(
                controller: _logoUrlController,
                placeholder: 'https://',
                keyboardType: TextInputType.url,
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
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CupertinoActivityIndicator(radius: 8),
                        )
                      : const Text('Create Team'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
