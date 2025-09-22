import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sih_crowd_source/src/data/models/report_model.dart';
import 'package:sih_crowd_source/src/features/report_detail/screens/report_detail_screen.dart';

class ReportListItem extends StatelessWidget {
  final ReportModel report;
  const ReportListItem({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(report.status);

    // ADDED WRAPPER: InkWell makes the card tappable
    return InkWell(
      onTap: () {
        // ADDED LOGIC: Navigate to the details screen on tap
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailsScreen(report: report),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12), // Match the card's border radius
      child: Card(
        // YOUR CARD UI IS UNCHANGED
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: report.imageUrl != null
                    ? Image.network(
                        report.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null ? child : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.locationName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                       overflow: TextOverflow.ellipsis,
                    ),
                     const SizedBox(height: 8),
                     Text(
                      DateFormat.yMMMd().format(report.createdAt.toDate()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

