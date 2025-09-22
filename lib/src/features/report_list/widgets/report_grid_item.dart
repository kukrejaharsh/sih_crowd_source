import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sih_crowd_source/src/data/models/report_model.dart';
import 'package:sih_crowd_source/src/features/report_detail/screens/report_detail_screen.dart';

class ReportGridItem extends StatelessWidget {
  final ReportModel report;
  const ReportGridItem({super.key, required this.report});

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
      borderRadius: BorderRadius.circular(12),
      child: Card(
        // YOUR CARD UI IS UNCHANGED
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: report.imageUrl != null
                    ? Image.network(
                        report.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null ? child : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      )
                    : const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.locationName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(
                        DateFormat.yMMMd().format(report.createdAt.toDate()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                         decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          report.status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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

