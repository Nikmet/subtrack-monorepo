import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/ui_kit/tokens.dart';
import '../../../app/widgets/app_bottom_menu.dart';
import 'settings_models.dart';

const Color _settingsBackground = Color(0xFFE8EDF4);
const Color _settingsHeaderBackground = Color(0xFFF5F8FC);
const Color _settingsHeaderBorder = Color(0xFFDDE5EF);
const Color _settingsCardBackground = Color(0xFFF6F9FC);
const Color _settingsCardBorder = Color(0xFFDCE4EE);
const Color _settingsDivider = Color(0xFFE2E9F2);
const Color _settingsTitle = Color(0xFF0F2742);
const Color _settingsText = Color(0xFF10253F);
const Color _settingsMuted = Color(0xFF92A2B8);
const Color _settingsLabel = Color(0xFF7E91A9);
const Color _settingsIconWrap = Color(0xFFEDF2F7);
const Color _settingsButtonGreen = Color(0xFFDEF8E8);
const Color _settingsButtonGreenText = Color(0xFF0F7A3F);
const Color _settingsButtonBlue = Color(0xFFE2F1FF);
const Color _settingsButtonBlueText = Color(0xFF1F5D95);
const Color _settingsButtonRed = Color(0xFFFFE6EA);
const Color _settingsButtonRedText = Color(0xFFBD2D45);
const Color _settingsPlanBorder = Color(0xFF98DFBA);
const Color _settingsPlanBg = Color(0xFFDAF8E8);
const Color _settingsPlanText = Color(0xFF15974B);

void showSettingsSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
}

class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.location,
    required this.backRoute,
    required this.child,
  });

  final String title;
  final String location;
  final String backRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      backgroundColor: _settingsBackground,
      body: Stack(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                SettingsHeader(
                  title: title,
                  onBackTap: () => context.go(backRoute),
                ),
                Expanded(child: child),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppBottomMenu(
              location: location,
              bottomInset: viewPadding.bottom,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/');
                    break;
                  case 1:
                    context.go('/calendar');
                    break;
                  case 2:
                    context.go('/search');
                    break;
                  case 3:
                    context.go('/profile');
                    break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    super.key,
    required this.title,
    required this.onBackTap,
  });

  final String title;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: _settingsHeaderBackground,
        border: Border(
          bottom: BorderSide(color: _settingsHeaderBorder),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onBackTap,
                borderRadius: BorderRadius.circular(8),
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 24,
                    color: _settingsTitle,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _settingsTitle,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }
}

class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle({
    super.key,
    required this.text,
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 8),
  });

  final String text;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _settingsMuted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.96,
          height: 1.2,
        ),
      ),
    );
  }
}

class SettingsCardBox extends StatelessWidget {
  const SettingsCardBox({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 12),
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: _settingsCardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _settingsCardBorder),
      ),
      child: child,
    );
  }
}

class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      items.add(children[index]);
      if (index != children.length - 1) {
        items.add(const Divider(height: 1, thickness: 1, color: _settingsDivider));
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _settingsCardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _settingsCardBorder),
      ),
      child: Column(children: items),
    );
  }
}

class SettingsAvatar extends StatelessWidget {
  const SettingsAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    this.size = 86,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = _SettingsAvatarFallback(
      initials: settingsInitials(name),
      size: size,
    );
    final trimmed = imageUrl?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: trimmed.isEmpty
            ? fallback
            : Image.network(
                trimmed,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }
}

class _SettingsAvatarFallback extends StatelessWidget {
  const _SettingsAvatarFallback({
    required this.initials,
    required this.size,
  });

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: const Color(0xFFB8F0E5), width: 3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF244B7D),
            Color(0xFF0F1F34),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: const Color(0xFFEBF5FF),
            fontSize: size >= 86 ? 30 : 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.value,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _settingsIconWrap,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: _settingsText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: _settingsMuted,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (value != null && value!.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _settingsMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFC3CEDD),
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsFormLabel extends StatelessWidget {
  const SettingsFormLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _settingsLabel,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.96,
        height: 1.2,
      ),
    );
  }
}

InputDecoration settingsInputDecoration({String? hintText}) {
  return InputDecoration(
    isDense: true,
    hintText: hintText,
    hintStyle: const TextStyle(
      color: _settingsMuted,
      fontSize: 14,
      height: 1.2,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD4DEEA)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD4DEEA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _settingsTitle),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _settingsButtonRedText),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _settingsButtonRedText),
    ),
  );
}

class SettingsActionButton extends StatelessWidget {
  const SettingsActionButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.height = 42,
    this.enabled = true,
    this.alignment = Alignment.center,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;
  final double height;
  final bool enabled;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && onTap != null;

    return InkWell(
      onTap: effectiveEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: effectiveEnabled ? 1 : 0.7,
        child: Container(
          height: height,
          alignment: alignment,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsPrimaryButton extends StatelessWidget {
  const SettingsPrimaryButton({
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
    return SettingsActionButton(
      text: text,
      backgroundColor: _settingsButtonGreen,
      textColor: _settingsButtonGreenText,
      onTap: onTap,
      enabled: enabled,
    );
  }
}

class SettingsSecondaryButton extends StatelessWidget {
  const SettingsSecondaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.enabled = true,
    this.fullWidth = true,
  });

  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = SettingsActionButton(
      text: text,
      backgroundColor: _settingsButtonBlue,
      textColor: _settingsButtonBlueText,
      onTap: onTap,
      height: 36,
      enabled: enabled,
    );
    if (fullWidth) {
      return button;
    }
    return IntrinsicWidth(child: button);
  }
}

class SettingsDeleteButton extends StatelessWidget {
  const SettingsDeleteButton({
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
    return IntrinsicWidth(
      child: SettingsActionButton(
        text: text,
        backgroundColor: _settingsButtonRed,
        textColor: _settingsButtonRedText,
        onTap: onTap,
        height: 36,
        enabled: enabled,
      ),
    );
  }
}

class SettingsPlanBadge extends StatelessWidget {
  const SettingsPlanBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _settingsPlanBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _settingsPlanBorder),
      ),
      alignment: Alignment.center,
      child: const Text(
        'FREE план',
        style: TextStyle(
          color: _settingsPlanText,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class SettingsFooter extends StatelessWidget {
  const SettingsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: Column(
        children: <Widget>[
          Text(
            'SubTrack App © 2026',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF97A7BC),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          Text(
            'Сделано с заботой о подписках',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF97A7BC),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsLoadingView extends StatelessWidget {
  const SettingsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class SettingsErrorView extends StatelessWidget {
  const SettingsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _settingsCardBackground,
            borderRadius: UiTokens.radius12,
            border: Border.all(color: _settingsCardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _settingsText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              SettingsSecondaryButton(
                text: 'Повторить',
                onTap: onRetry,
                fullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
