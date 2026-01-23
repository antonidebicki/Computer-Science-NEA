import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import '../icons/app_icons.dart';

/// Custom dropdown widget with glassmorphism design
class AppDropdown<T> extends StatefulWidget {
  final T value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final String? placeholder;
  final double? width;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.placeholder,
    this.width,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  bool _isExpanded = false;
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isExpanded) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _showOverlay() {
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          _removeOverlay();
          setState(() {
            _isExpanded = false;
          });
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: CupertinoColors.black.withValues(alpha: 0.0),
              ),
            ),
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + Spacing.xs),
                child: Material(
                  color: CupertinoColors.transparent,
                  child: _buildDropdownMenu(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => widget.items.first,
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: _buildDropdownButton(selectedItem),
      ),
    );
  }

  Widget _buildDropdownButton(DropdownItem<T> selectedItem) {
    return ClipRRect(
      key: _buttonKey,
      borderRadius: BorderRadius.circular(16),
      child: FakeGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 16),
        settings: const LiquidGlassSettings(
          blur: 10,
          glassColor: Color(0x33FFFFFF),
          lightIntensity: 1.5,
        ),
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x44FFFFFF), width: 1.5),
          ),
          child: Row(
            mainAxisSize: widget.width != null
                ? MainAxisSize.max
                : MainAxisSize.min,
            children: [
              if (selectedItem.icon != null) ...[
                selectedItem.icon!,
                const SizedBox(width: Spacing.sm),
              ],
              Expanded(
                child: Text(
                  selectedItem.label,
                  style: AppTypography.callout.copyWith(
                    color: CupertinoColors.label,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: AppIcons.chevronDown(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownMenu() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FakeGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 16),
        settings: const LiquidGlassSettings(
          blur: 10,
          glassColor: Color(0x44FFFFFF),
          lightIntensity: 1.5,
        ),
        child: Container(
          width: widget.width,
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x44FFFFFF), width: 1.5),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            itemCount: widget.items.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              color: CupertinoColors.separator.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final isSelected = item.value == widget.value;

              return CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
                onPressed: () {
                  widget.onChanged(item.value);
                  _removeOverlay();
                  setState(() {
                    _isExpanded = false;
                  });
                },
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      item.icon!,
                      const SizedBox(width: Spacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTypography.callout.copyWith(
                          color: CupertinoColors.label,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      AppIcons.checkmark(
                        fontSize: 16,
                        color: CupertinoColors.label,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dropdown item model
class DropdownItem<T> {
  final T value;
  final String label;
  final Widget? icon;

  const DropdownItem({required this.value, required this.label, this.icon});
}
