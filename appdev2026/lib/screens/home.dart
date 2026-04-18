// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/neon_surface.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: <Color>[
                            Theme.of(context).colorScheme.primary,
                            Colors.deepPurpleAccent,
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(user),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Welcome back, $name',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: onSurface.withOpacity(0.74)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Signed in through Firebase Auth and ready to use your live account data.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onSurface.withOpacity(0.74),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricTile(
                        label: 'Verified',
                        value: user?.emailVerified == true ? 'Yes' : 'No',
                        icon: Icons.verified_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        label: 'Provider',
                        value: provider,
                        icon: Icons.manage_accounts_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _ActionChipCard(
                  icon: Icons.login_rounded,
                  title: 'Last sign-in',
                  subtitle: lastSignIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionChipCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Joined',
                  subtitle: joined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Account activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                _ActivityRow(
                  icon: Icons.person_rounded,
                  title: 'Signed in as $name',
                  subtitle: email,
                ),
                const SizedBox(height: 12),
                _ActivityRow(
                  icon: Icons.verified_user_rounded,
                  title: 'Authentication provider',
                  subtitle: provider,
                ),
                const SizedBox(height: 12),
                _ActivityRow(
                  icon: Icons.sync_rounded,
                  title: 'Email verification',
                  subtitle: user?.emailVerified == true
                      ? 'Verified'
                      : 'Not verified',
                ),
              ],
            ),
          ),
        ],
      ),
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onSurface.withOpacity(0.70),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChipCard extends StatelessWidget {
  const _ActionChipCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.16),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: onSurface.withOpacity(0.72)),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.14),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: onSurface.withOpacity(0.68),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
