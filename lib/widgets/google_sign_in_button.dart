import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum GoogleSignInButtonStyle { auto, light, dark, neutral }

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Sign in with Google',
    this.styleType = GoogleSignInButtonStyle.auto,
  });

  final VoidCallback? onPressed;
  final String label;
  final GoogleSignInButtonStyle styleType;

  static const String _googleSvgString = '''
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" xmlns:xlink="http://www.w3.org/1999/xlink" style="display: block;">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"></path>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"></path>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"></path>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"></path>
  <path fill="none" d="M0 0h48v48H0z"></path>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final _GoogleButtonPalette palette = _paletteFor(context, styleType);

    return Material(
      color: palette.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: palette.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 220),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.string(_googleSvgString),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: palette.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _GoogleButtonPalette _paletteFor(
    BuildContext context,
    GoogleSignInButtonStyle style,
  ) {
    final GoogleSignInButtonStyle resolvedStyle =
        style == GoogleSignInButtonStyle.auto
        ? Theme.of(context).brightness == Brightness.dark
              ? GoogleSignInButtonStyle.dark
              : GoogleSignInButtonStyle.light
        : style;

    switch (resolvedStyle) {
      case GoogleSignInButtonStyle.auto:
        return const _GoogleButtonPalette(
          background: Color(0xFFFFFFFF),
          border: Color(0xFF747775),
          foreground: Color(0xFF1F1F1F),
        );
      case GoogleSignInButtonStyle.dark:
        return const _GoogleButtonPalette(
          background: Color(0xFF131314),
          border: Color(0xFF8E918F),
          foreground: Color(0xFFE3E3E3),
        );
      case GoogleSignInButtonStyle.neutral:
        return const _GoogleButtonPalette(
          background: Color(0xFFE9E9E9),
          border: Color(0xFFE9E9E9),
          foreground: Color(0xFF1F1F1F),
        );
      case GoogleSignInButtonStyle.light:
        return const _GoogleButtonPalette(
          background: Color(0xFFFFFFFF),
          border: Color(0xFF747775),
          foreground: Color(0xFF1F1F1F),
        );
    }
  }
}

class _GoogleButtonPalette {
  const _GoogleButtonPalette({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
