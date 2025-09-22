import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sih_crowd_source/src/data/models/report_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportDetailsScreen extends StatelessWidget {
  final ReportModel report;
  const ReportDetailsScreen({super.key, required this.report});

  // Helper to launch Google Maps
  Future<void> _launchMaps(BuildContext context) async {
    final lat = report.coordinates.latitude;
    final lng = report.coordinates.longitude;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildDetailsCard(context),
                const SizedBox(height: 16),
                _buildLocationCard(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300.0,
      backgroundColor: Colors.grey[200],
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: report.imageUrl != null
            ? Image.network(
                report.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 80, color: Colors.grey),
              )
            : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.category,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              report.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            ),
            const Divider(height: 32),
            _buildInfoRow(context, Icons.calendar_today_rounded, 'Reported on',
                DateFormat.yMMMMd().add_jm().format(report.createdAt.toDate())),
            const SizedBox(height: 12),
            _buildInfoRow(
                context, Icons.info_outline_rounded, 'Status', report.status.toUpperCase(),
                statusColor: _getStatusColor(report.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.location_on_rounded, color: Theme.of(context).primaryColor)),
              title: Text(report.locationName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Pincode: ${report.address['postalCode'] ?? 'N/A'}\nCity: ${report.address['city'] ?? 'N/A'}'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchMaps(context),
                icon: const Icon(Icons.map_rounded),
                label: const Text('View on Map'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {Color? statusColor}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Text('$label:', style: TextStyle(color: Colors.grey.shade700)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor ?? Colors.black87),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'resolved': return Colors.green;
      default: return Colors.grey;
    }
  }
}
