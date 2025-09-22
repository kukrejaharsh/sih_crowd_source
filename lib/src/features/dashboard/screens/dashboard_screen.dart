import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sih_crowd_source/src/data/models/report_model.dart';
import 'package:sih_crowd_source/src/data/models/user_model.dart';
import 'package:sih_crowd_source/src/data/providers/auth_state_provider.dart';
import 'package:sih_crowd_source/src/data/providers/report_state_provider.dart';
import 'package:sih_crowd_source/src/features/issue_reporting/screens/report_issue_screen.dart';
import 'package:sih_crowd_source/src/features/profile/screens/profile_screen.dart';
import 'package:sih_crowd_source/src/features/report_detail/screens/report_detail_screen.dart';
import 'package:sih_crowd_source/src/features/report_list/screens/my_reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final GlobalKey<_RecentActivityWidgetState> _recentActivityKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This logic is unchanged.
    final authProvider = Provider.of<AuthStateProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, user, authProvider),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _AnimatedSlideFade(
                    controller: _animationController,
                    delay: 0.2,
                    child: _buildActionGrid(context),
                  ),
                  const SizedBox(height: 24),
                  _AnimatedSlideFade(
                    controller: _animationController,
                    delay: 0.3,
                    child: _buildStatsCard(context, user),
                  ),
                  const SizedBox(height: 24),
                  _AnimatedSlideFade(
                    controller: _animationController,
                    delay: 0.4,
                    // THIS IS THE ONLY CHANGE: The placeholder is replaced
                    // with the new, fully functional widget.
                    child: _RecentActivityWidget(key: _recentActivityKey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER WIDGETS (UNCHANGED) ---

// --- THIS IS THE ONLY METHOD THAT HAS BEEN UPDATED ---
  SliverAppBar _buildSliverAppBar(BuildContext context, UserModel user, AuthStateProvider authProvider) {
    return SliverAppBar(
      expandedHeight: 180.0,
      backgroundColor: const Color(0xFF6C63FF),
      pinned: true,
      elevation: 4,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        centerTitle: false,
        title: Text(
          'Welcome, ${user.displayName?.split(' ').first ?? 'Citizen'}!',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color.fromARGB(255, 4, 129, 167)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 60,
                left: 16,
                child: _AnimatedSlideFade(
                  controller: _animationController,
                  delay: 0.1,
                  // --- WRAPPED THE ROW IN AN INKWELL TO MAKE IT TAPPABLE ---
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(100), // for a nice ripple effect
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                            child: user.photoURL == null
                                ? const Icon(Icons.person, size: 40, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? 'Citizen',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                user.email,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Logout',
          onPressed: () async {
            // I'm assuming you have a logout confirmation dialog in your app
            // For now, it logs out directly.
            await authProvider.signOut();
          },
        ),
      ],
    );
  }
  

  // --- UPDATED ACTION GRID with refresh logic ---
  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildActionButton(
          context: context,
          icon: Icons.add_location_alt_rounded,
          label: 'Report Issue',
          gradient: const LinearGradient(colors: [Color(0xFF007BFF), Color(0xFF00C6FF)]),
          // --- NEW: Added async and await ---
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitReportScreen()));
            // When we come back, refresh the activity widget.
            _recentActivityKey.currentState?.refreshActivity();
          },
        ),
        _buildActionButton(
          context: context,
          icon: Icons.history_rounded,
          label: 'My Reports',
          gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
           // --- NEW: Added async and await ---
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReportsScreen()));
            // When we come back, refresh the activity widget.
             _recentActivityKey.currentState?.refreshActivity();
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: gradient,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, UserModel user) {
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
              'Your Contributions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                children: [
                  _StatItem(icon: Icons.star_rounded, color: Colors.amber, label: 'Points', value: user.points.toString()),
                  const VerticalDivider(width: 32),
                  _StatItem(icon: Icons.shield_rounded, color: Colors.blueGrey, label: 'Badges', value: user.badges.length.toString()),
                ],
              ),
            ),
             if (user.badges.isNotEmpty) ...[
              const Divider(height: 32),
              Wrap(
                spacing: 12.0,
                runSpacing: 8.0,
                children: user.badges.map<Widget>((badge) {
                  return Chip(
                    label: Text(badge, style: const TextStyle(fontWeight: FontWeight.bold)),
                    avatar: Icon(_getBadgeIcon(badge), size: 18),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2))
                    ),
                  );
                }).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    // Replaced the old placeholder Card with the new, smart widget.
    return const _RecentActivityWidget();
  }

  IconData _getBadgeIcon(String badgeName) {
    if (badgeName.toLowerCase().contains('pothole')) return Icons.remove_road_rounded;
    if (badgeName.toLowerCase().contains('garbage')) return Icons.recycling_rounded;
    if (badgeName.toLowerCase().contains('community')) return Icons.groups_rounded;
    return Icons.verified_user_rounded;
  }
}


// --- NEW WIDGET ADDED HERE ---
// This new widget is self-contained and fetches its own data.
class _RecentActivityWidget extends StatefulWidget {
  const _RecentActivityWidget({super.key});

  @override
  State<_RecentActivityWidget> createState() => _RecentActivityWidgetState();
}

class _RecentActivityWidgetState extends State<_RecentActivityWidget> {
  Future<ReportModel?>? _latestReportFuture;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  // NEW: Extracted data fetching into its own method.
  void _fetchData() {
    final authProvider = Provider.of<AuthStateProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      setState(() {
        _latestReportFuture = reportProvider.getLatestReport(authProvider.user!.uid);
      });
    }
  }
  
  // NEW: Public method that the parent can call via the GlobalKey.
  void refreshActivity() {
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
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
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<ReportModel?>(
              future: _latestReportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LinearProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const ListTile(
                    leading: CircleAvatar(child: Icon(Icons.error_outline, color: Colors.red)),
                    title: Text("Could not load activity"),
                  );
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const ListTile(
                    leading: CircleAvatar(child: Icon(Icons.notifications_off_rounded)),
                    title: Text("No Recent Activity"),
                    subtitle: Text("Report an issue to see it here."),
                  );
                }

                final report = snapshot.data!;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: report.imageUrl != null ? NetworkImage(report.imageUrl!) : null,
                    child: report.imageUrl == null ? const Icon(Icons.image) : null,
                  ),
                  title: Text(report.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Status: ${report.status}"),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ReportDetailsScreen(report: report),
                    ));
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


// --- OTHER HELPER WIDGETS (UNCHANGED) ---

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSlideFade extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const _AnimatedSlideFade({
    required this.controller,
    required this.delay,
    required this.child,
  });

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
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

