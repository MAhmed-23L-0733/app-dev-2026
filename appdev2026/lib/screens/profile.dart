// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/signin.dart';
import '../widgets/neon_surface.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String name = _displayName(user);
    final String email = user?.email ?? 'No email linked';
    final String provider = _providerLabel(user);
    final String joined = _formatDate(user?.metadata.creationTime);
    final String lastSignIn = _formatDate(user?.metadata.lastSignInTime);
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassCard(
            child: Row(
              children: <Widget>[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: <Color>[
                        Theme.of(context).colorScheme.primary,
                        Colors.blueAccent,
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: user?.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoURL!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          _initials(user),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        user?.uid ?? 'No user id available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: onSurface.withOpacity(0.58),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Account details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                _SummaryRow(label: 'Authentication', value: provider),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                _SummaryRow(label: 'Joined', value: joined),
                const SizedBox(height: 12),
                _SummaryRow(label: 'Last sign-in', value: lastSignIn),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Security',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.security_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text('Session', style: TextStyle(color: onSurface)),
                  subtitle: Text(
                    'Manage the signed-in account from this device',
                    style: TextStyle(color: onSurface.withOpacity(0.68)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool shouldSignOut =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Sign out?'),
              content: const Text(
                'You will need to sign in again to access your account.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Sign out'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldSignOut) {
      return;
    }

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      SignInScreen.routeName,
      (Route<dynamic> route) => false,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onSurface.withOpacity(0.68),
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
      ],
    );
  }
}

String _displayName(User? user) {
  final String? displayName = user?.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final String? email = user?.email?.trim();
  if (email != null && email.isNotEmpty) {
    return email.split('@').first;
  }

  return 'User';
}

String _initials(User? user) {
  final String name = _displayName(user).trim();
  if (name.isEmpty) {
    return 'U';
  }

  final List<String> parts = name
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return name.substring(0, 1).toUpperCase();
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String _providerLabel(User? user) {
  final List<String> providers =
      user?.providerData
          .map((UserInfo info) => info.providerId)
          .where((String providerId) => providerId.isNotEmpty)
          .toSet()
          .toList() ??
      <String>[];

  if (providers.isEmpty) {
    return 'Email';
  }

  return providers
      .map((String providerId) {
        switch (providerId) {
          case 'google.com':
            return 'Google';
          case 'password':
            return 'Email';
          default:
            return providerId;
        }
      })
      .join(', ');
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return 'Unavailable';
  }

  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
