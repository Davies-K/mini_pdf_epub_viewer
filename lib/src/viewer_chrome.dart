import 'package:flutter/material.dart';

import 'viewer_style.dart';

/// Lays out the parts shared by every document type: a header across the
/// top, an optional sidebar, the document itself and a bottom navigation bar.
class ViewerScaffold extends StatelessWidget {
  const ViewerScaffold({
    super.key,
    required this.style,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.sidebar,
    this.sidebarWidth = 200,
    this.navigationLabel,
    this.onPrevious,
    this.onNext,
  });

  final ViewerStyle style;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget body;
  final Widget? sidebar;
  final double sidebarWidth;

  /// When null the bottom navigation bar is hidden.
  final String? navigationLabel;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: style.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                if (sidebar != null)
                  Container(
                    width: sidebarWidth,
                    decoration: BoxDecoration(
                      color: style.surfaceColor,
                      border: Border(
                        right: BorderSide(color: style.borderColor),
                      ),
                    ),
                    child: sidebar,
                  ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          navigationLabel == null ? null : _buildNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: style.surfaceColor,
        border: Border(bottom: BorderSide(color: style.borderColor)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: style.textColor,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: style.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      color: style.surfaceColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.navigate_before),
                color: style.textColor,
                disabledColor: style.secondaryTextColor.withValues(alpha: 0.4),
                onPressed: onPrevious,
              ),
              Text(navigationLabel!, style: TextStyle(color: style.textColor)),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                color: style.textColor,
                disabledColor: style.secondaryTextColor.withValues(alpha: 0.4),
                onPressed: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A header action button coloured for the current [ViewerStyle].
class ViewerIconButton extends StatelessWidget {
  const ViewerIconButton({
    super.key,
    required this.style,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final ViewerStyle style;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      color: style.textColor,
      disabledColor: style.secondaryTextColor.withValues(alpha: 0.4),
      onPressed: onPressed,
    );
  }
}

/// Shows a dialog listing [details] (label → value) about the open document.
void showDocumentInfo(
  BuildContext context, {
  required ViewerStyle style,
  required Map<String, String> details,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: style.backgroundColor,
      title: Text('General Info', style: TextStyle(color: style.textColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in details.entries)
            Text(
              '${entry.key}: ${entry.value}',
              style: TextStyle(color: style.textColor),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: style.accentColor)),
        ),
      ],
    ),
  );
}

class ViewerLoadingView extends StatelessWidget {
  const ViewerLoadingView({
    super.key,
    required this.style,
    required this.label,
    this.progress,
  });

  final ViewerStyle style;
  final String label;

  /// Download progress between 0 and 1, or null when unknown.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: style.accentColor, value: progress),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(color: style.textColor)),
        ],
      ),
    );
  }
}

class ViewerErrorView extends StatelessWidget {
  const ViewerErrorView({
    super.key,
    required this.style,
    required this.title,
    required this.error,
    required this.onRetry,
  });

  final ViewerStyle style;
  final String title;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: style.isDark ? Colors.red[300] : Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(color: style.textColor),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: style.secondaryTextColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: style.accentColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
