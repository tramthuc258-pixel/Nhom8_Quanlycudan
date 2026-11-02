import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Khung giao diện thống nhất cho các màn hình phía cư dân.
///
/// Widget chỉ đảm nhiệm phần trình bày chung; nội dung và nghiệp vụ vẫn thuộc
/// từng feature để tránh trộn logic giữa các phân hệ.
class ResidentPageScaffold extends StatelessWidget {
  const ResidentPageScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.body,
    this.actions = const <Widget>[],
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.accentColor = AppColors.primary,
    this.accentSoftColor = AppColors.primaryLight,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color accentColor;
  final Color accentSoftColor;

  @override
  Widget build(BuildContext context) {
    // Mốc 900 px giữ bố cục tablet gần với mobile, tránh thanh tiêu đề cao
    // chiếm không gian nội dung trên các cửa sổ thấp.
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final canPop = Navigator.of(context).canPop();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: isWide ? 88 : 78,
        leadingWidth: canPop ? (isWide ? 76 : 62) : 12,
        leading: canPop
            ? Padding(
                padding: EdgeInsets.only(
                  left: isWide ? 20 : 12,
                  top: 10,
                  bottom: 10,
                ),
                child: IconButton.filledTonal(
                  tooltip: 'Quay lại',
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: IconButton.styleFrom(
                    foregroundColor: accentColor,
                    backgroundColor: accentSoftColor,
                    side: BorderSide(color: accentColor.withValues(alpha: .12)),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              )
            : null,
        titleSpacing: canPop ? 6 : (isWide ? 24 : 12),
        title: _ResidentPageTitle(
          title: title,
          subtitle: subtitle,
          icon: icon,
          accentColor: accentColor,
          accentSoftColor: accentSoftColor,
          isWide: isWide,
        ),
        actions: <Widget>[
          if (actions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: isWide ? 16 : 8),
              child: IconButtonTheme(
                data: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    foregroundColor: accentColor,
                    backgroundColor: accentSoftColor,
                    disabledForegroundColor: AppColors.textDisabled,
                    disabledBackgroundColor: AppColors.surfaceMuted,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: actions),
              ),
            ),
        ],
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                scheme.surface,
                isDark
                    ? scheme.surfaceContainerHigh
                    : accentSoftColor.withValues(alpha: .62),
                isDark ? scheme.surfaceContainer : const Color(0xFFF7FAFF),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: accentColor.withValues(alpha: .12)),
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              isDark
                  ? scheme.surfaceContainerHigh
                  : accentSoftColor.withValues(alpha: .30),
              isDark ? scheme.surfaceContainer : const Color(0xFFF8FAFF),
              scheme.surface,
            ],
            stops: const <double>[0, .24, 1],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -110,
              right: -70,
              child: IgnorePointer(
                child: Container(
                  width: isWide ? 310 : 220,
                  height: isWide ? 310 : 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: .045),
                  ),
                ),
              ),
            ),
            Positioned(
              top: isWide ? 220 : 300,
              left: -120,
              child: IgnorePointer(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withValues(alpha: .035),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: SizedBox.expand(child: body),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _ResidentPageTitle extends StatelessWidget {
  const _ResidentPageTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.accentSoftColor,
    required this.isWide,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color accentSoftColor;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: isWide ? 48 : 42,
          height: isWide ? 48 : 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accentSoftColor,
                Color.lerp(accentSoftColor, Colors.white, .52)!,
              ],
            ),
            borderRadius: BorderRadius.circular(isWide ? 16 : 14),
            border: Border.all(color: accentColor.withValues(alpha: .14)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accentColor.withValues(alpha: .10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: accentColor, size: isWide ? 24 : 21),
        ),
        SizedBox(width: isWide ? 14 : 11),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: isWide ? 18 : 16,
                  letterSpacing: -0.35,
                ),
              ),
              SizedBox(height: isWide ? 3 : 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: isWide ? 12 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ResidentFloatingAction extends StatelessWidget {
  const ResidentFloatingAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.primary,
    this.endColor = AppColors.secondary,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color endColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: <Color>[color, endColor]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: .28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
