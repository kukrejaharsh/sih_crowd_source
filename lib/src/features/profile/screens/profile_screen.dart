import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sih_crowd_source/src/data/models/user_model.dart';
import 'package:sih_crowd_source/src/data/providers/auth_state_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // --- YOUR STATE AND LOGIC ARE 100% UNCHANGED ---
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showLogoutConfirmationDialog(BuildContext context, AuthStateProvider authProvider) {
    // This function is unchanged
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await authProvider.signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmationDialog(BuildContext context, AuthStateProvider authProvider) {
    // This function is unchanged
    final TextEditingController deleteController = TextEditingController();
    final ValueNotifier<bool> isButtonEnabled = ValueNotifier(false);

    deleteController.addListener(() {
      isButtonEnabled.value = (deleteController.text == 'DELETE');
    });

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account Permanently?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is irreversible. All your reports and data will be permanently erased.\n\nPlease type "DELETE" to confirm.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deleteController,
              decoration: const InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isButtonEnabled,
            builder: (context, isEnabled, child) {
              return ElevatedButton(
                onPressed: isEnabled
                    ? () async {
                        final error = await authProvider.deleteAccount();
                        if (mounted && error != null) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Account'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthStateProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // --- THE ENTIRE BUILD METHOD HAS BEEN REDESIGNED FOR A GOD-LEVEL UI/UX ---
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, user),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _AnimatedSlideFade(
                  controller: _animationController,
                  delay: 0.1,
                  child: _buildStatsGrid(context, user),
                ),
                const SizedBox(height: 24),
                _AnimatedSlideFade(
                  controller: _animationController,
                  delay: 0.2,
                  child: _buildDetailsCard(context, user),
                ),
                const SizedBox(height: 24),
                _AnimatedSlideFade(
                  controller: _animationController,
                  delay: 0.3,
                  child: _buildDangerZoneCard(context, authProvider),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, UserModel user) {
    return SliverAppBar(
      expandedHeight: 250.0,
      backgroundColor: const Color(0xFF6C63FF),
      pinned: true,
      elevation: 4,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color.fromARGB(255, 4, 129, 167)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30), // Space for status bar
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white.withOpacity(0.3),
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.displayName ?? 'Citizen',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                user.email,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 18),
              ),
            ],
          ),
        ),
      ),
       actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Edit Profile',
          onPressed: () {
            // TODO: Navigate to an Edit Profile Screen
          },
        ),
      ],
    );
  }
  
  Widget _buildStatsGrid(BuildContext context, UserModel user) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _StatTile(icon: Icons.star_rounded, label: 'Points', value: user.points.toString(), color: Colors.amber),
        _StatTile(icon: Icons.shield_rounded, label: 'Badges', value: user.badges.length.toString(), color: Colors.blueGrey),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context, UserModel user) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Account Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone_rounded, 'Phone Number', user.phoneNumber ?? 'Not provided'),
            _buildInfoRow(Icons.history_toggle_off_rounded, 'Joined on', DateFormat.yMMMMd().format(user.createdAt.toDate())),
             if (user.badges.isNotEmpty) ...[
                const Divider(height: 24),
                 Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: user.badges.map((badge) => Chip(label: Text(badge))).toList(),
                )
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 22),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.grey.shade800, fontSize: 16)),
        ],
      ),
    );
  }

   Widget _buildDangerZoneCard(BuildContext context, AuthStateProvider authProvider) {
    return Card(
      color: Colors.red.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.red.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.logout_rounded, color: Colors.red.shade700),
              title: const Text('Logout'),
              onTap: () => _showLogoutConfirmationDialog(context, authProvider),
            ),
             ListTile(
              leading: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700),
              title: const Text('Delete Account'),
              subtitle: const Text('This action is permanent.'),
              onTap: () => _showDeleteConfirmationDialog(context, authProvider),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0,4)
          )
        ]
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey.shade600)),
            ],
          )
        ],
      ),
    );
  }
}

class _AnimatedSlideFade extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const _AnimatedSlideFade(
      {required this.controller, required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

