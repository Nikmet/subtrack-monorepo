import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../settings/presentation/settings_widgets.dart';

class AdminPageScaffold extends StatelessWidget {
  const AdminPageScaffold({
    super.key,
    required this.child,
    this.maxWidth = 1360,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF4),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 32),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class AdminHeader extends StatelessWidget {
  const AdminHeader({
    super.key,
    required this.backText,
    required this.backRoute,
    required this.title,
  });

  final String backText;
  final String backRoute;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: InkWell(
            onTap: () => context.go(backRoute),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                backText,
                style: const TextStyle(
                  color: Color(0xFF1A7F93),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF10233F),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.text, {super.key, this.top = 0});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF122842),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E0EC)),
      ),
      child: child,
    );
  }
}

class AdminFiltersPanel extends StatelessWidget {
  const AdminFiltersPanel({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class AdminEmptyText extends StatelessWidget {
  const AdminEmptyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF6B7F99),
        fontSize: 14,
        height: 1.35,
      ),
    );
  }
}

class AdminIconBox extends StatelessWidget {
  const AdminIconBox({
    super.key,
    required this.size,
    required this.radius,
    required this.imageUrl,
    required this.fallbackText,
    this.backgroundColor = const Color(0xFFE8ECF2),
    this.borderColor,
    this.textColor = const Color(0xFF8493A8),
    this.fontSize = 16,
  });

  final double size;
  final double radius;
  final String imageUrl;
  final String fallbackText;
  final Color backgroundColor;
  final Color? borderColor;
  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      clipBehavior: Clip.antiAlias,
      child: trimmedUrl.isEmpty
          ? Center(
              child: Text(
                fallbackText,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : Image.network(
              trimmedUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  fallbackText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
    );
  }
}

class AdminUploadButton extends StatelessWidget {
  const AdminUploadButton({
    super.key,
    required this.text,
    required this.onTap,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 134,
      child: SettingsActionButton(
        text: text,
        backgroundColor: const Color(0xFFE2F1FF),
        textColor: const Color(0xFF1F5D95),
        onTap: onTap,
        height: 34,
        enabled: enabled,
      ),
    );
  }
}

InputDecoration adminInputDecoration({String? hintText}) => settingsInputDecoration(hintText: hintText);
