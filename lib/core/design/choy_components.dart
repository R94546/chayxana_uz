import 'package:flutter/material.dart';
import 'choy_tokens.dart';

/// 🍵 CHOYXONA.UZ — komponentlar kutubxonasi (Faza 4 redesign)
///
/// Yagona, qayta ishlatiladigan UI komponentlari. Barcha redizayn ekranlar
/// shu komponentlardan foydalanadi (tarqoq `ultra_button`/`ethereal_*` o'rniga).

enum ChoyButtonVariant { primary, secondary, ghost, danger }

/// Asosiy tugma — premium choyxona uslubi.
class ChoyButton extends StatelessWidget {
  const ChoyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = ChoyButtonVariant.primary,
    this.expanded = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ChoyButtonVariant variant;
  final bool expanded;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    final disabled = onPressed == null || loading;

    late final Color bg;
    late final Color fg;
    late final Border? border;
    switch (variant) {
      case ChoyButtonVariant.primary:
        bg = c.primary;
        fg = Colors.white;
        border = null;
        break;
      case ChoyButtonVariant.secondary:
        bg = c.primaryContainer;
        fg = c.primary;
        border = null;
        break;
      case ChoyButtonVariant.ghost:
        bg = Colors.transparent;
        fg = c.primary;
        border = Border.all(color: c.border, width: 1.5);
        break;
      case ChoyButtonVariant.danger:
        bg = ChoyPalette.danger;
        fg = Colors.white;
        border = null;
        break;
    }

    final child = AnimatedOpacity(
      duration: ChoyMotion.fast,
      opacity: disabled ? 0.55 : 1,
      child: Container(
        height: 54,
        width: expanded ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: expanded ? 0 : ChoySpace.xl),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: ChoyRadius.all(ChoyRadius.lg),
          border: border,
          boxShadow: variant == ChoyButtonVariant.primary && !disabled
              ? [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(fg),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: fg, size: 20),
                      const SizedBox(width: ChoySpace.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: ChoyRadius.all(ChoyRadius.lg),
        child: child,
      ),
    );
  }
}

/// Yumshoq soyali, katta radiusli karta konteyneri.
class ChoyCard extends StatelessWidget {
  const ChoyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ChoySpace.lg),
    this.onTap,
    this.color,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    final radius = borderRadius ?? ChoyRadius.xl;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: ChoyRadius.all(radius),
        border: Border.all(color: c.border, width: 1),
        boxShadow: ChoyShadow.card(c.isDark),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: ChoyRadius.all(radius),
        child: content,
      ),
    );
  }
}

/// Tanlanadigan / ko'rsatma chip (kategoriya, filtr).
class ChoyChip extends StatelessWidget {
  const ChoyChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: ChoyRadius.all(ChoyRadius.pill),
        child: AnimatedContainer(
          duration: ChoyMotion.fast,
          padding: const EdgeInsets.symmetric(
              horizontal: ChoySpace.lg, vertical: ChoySpace.sm + 2),
          decoration: BoxDecoration(
            color: selected ? c.primary : c.surface,
            borderRadius: ChoyRadius.all(ChoyRadius.pill),
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16,
                    color: selected ? Colors.white : c.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : c.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ChoyStatusTone { success, warning, danger, neutral, info }

/// Holat belgisi (bron holati, xona bandligi va h.k.).
class ChoyStatusBadge extends StatelessWidget {
  const ChoyStatusBadge({
    super.key,
    required this.label,
    this.tone = ChoyStatusTone.neutral,
    this.icon,
  });

  final String label;
  final ChoyStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    late final Color base;
    switch (tone) {
      case ChoyStatusTone.success:
        base = ChoyPalette.success;
        break;
      case ChoyStatusTone.warning:
        base = ChoyPalette.warning;
        break;
      case ChoyStatusTone.danger:
        base = ChoyPalette.danger;
        break;
      case ChoyStatusTone.info:
        base = ChoyPalette.info;
        break;
      case ChoyStatusTone.neutral:
        base = c.textMuted;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.14),
        borderRadius: ChoyRadius.all(ChoyRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: base),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: base, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: base,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bo'lim sarlavhasi (+ ixtiyoriy "Hammasi" amali).
class ChoySectionHeader extends StatelessWidget {
  const ChoySectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                color: c.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}

/// Bo'sh holat (empty state).
class ChoyEmptyState extends StatelessWidget {
  const ChoyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ChoySpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: c.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: c.primary),
            ),
            const SizedBox(height: ChoySpace.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: ChoySpace.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: ChoySpace.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
