import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class GlassDropdownEntry<T> {
  const GlassDropdownEntry({required this.value, required this.label, this.trailing});

  final T value;
  final String label;

  /// Optional secondary text shown right-aligned in the menu (e.g. "10 ep.").
  final String? trailing;
}

/// A dropdown styled like the player's dark rounded panels — a translucent
/// black field and a rounded, glass-bordered menu — instead of the dated
/// default Material dropdown. The menu scrolls when there are many entries.
class GlassDropdown<T> extends StatelessWidget {
  const GlassDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.leadingIcon,
    this.expand = false,
  });

  final T value;
  final List<GlassDropdownEntry<T>> items;
  final ValueChanged<T> onChanged;
  final IconData? leadingIcon;

  /// When true the field stretches to fill its parent's width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final current = items.firstWhere((e) => e.value == value, orElse: () => items.first);

    // Cap the menu width to the screen so it never gets clipped on the left, and
    // ellipsize long labels within that width.
    final screenW = MediaQuery.of(context).size.width;
    final menuMaxW = (screenW - 40).clamp(200.0, 400.0);
    final labelMaxW = menuMaxW - 96;

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Color(0xF01C1C1E)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
        ),
        maximumSize: WidgetStatePropertyAll(Size(menuMaxW, 460)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
      ),
      menuChildren: [
        for (final e in items)
          MenuItemButton(
            onPressed: () => onChanged(e.value),
            leadingIcon: Icon(
              Icons.check,
              size: 18,
              color: e.value == value ? Colors.white : Colors.transparent,
            ),
            style: MenuItemButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: labelMaxW),
                  child: Text(
                    e.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: e.value == value ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                if (e.trailing != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    e.trailing!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
      ],
      builder: (context, controller, _) {
        final label = Text(
          current.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        );
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                ],
                expand ? Expanded(child: label) : Flexible(child: label),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more, color: Colors.white70, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
