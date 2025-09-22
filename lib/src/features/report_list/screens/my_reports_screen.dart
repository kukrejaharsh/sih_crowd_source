import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sih_crowd_source/src/data/models/report_model.dart';
import 'package:sih_crowd_source/src/data/providers/auth_state_provider.dart';
import 'package:sih_crowd_source/src/data/providers/report_state_provider.dart';
import 'package:sih_crowd_source/src/features/report_list/widgets/report_grid_item.dart';
import 'package:sih_crowd_source/src/features/report_list/widgets/report_list_item.dart';

enum ViewMode { list, grid }

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  // --- UNCHANGED STATE ---
  ViewMode _viewMode = ViewMode.list;
  Future<List<ReportModel>>? _myReportsFuture;

  // --- NEW STATE FOR SEARCH AND FILTER ---
  final TextEditingController _searchController = TextEditingController();
  List<ReportModel> _allReports = [];
  List<ReportModel> _filteredReports = [];
  
  // Filter state
  Set<String> _selectedStatuses = {}; // Using a Set for efficient lookups
  bool _sortAscending = false; // false for newest first (descending)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthStateProvider>(context, listen: false);
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        final future = reportProvider.fetchMyReports(authProvider.user!.uid);
        setState(() {
          _myReportsFuture = future;
        });
        // When the future completes, populate our local lists.
        future.then((reports) {
          setState(() {
            _allReports = reports;
            _applyFiltersAndSearch();
          });
        });
      }
    });

    // Add listener to search controller to filter as user types.
    _searchController.addListener(_applyFiltersAndSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFiltersAndSearch);
    _searchController.dispose();
    super.dispose();
  }
  
  // --- UNCHANGED LOGIC ---
  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list;
    });
  }

  // --- NEW FILTERING AND SEARCHING LOGIC ---
  void _applyFiltersAndSearch() {
    List<ReportModel> tempReports = List.from(_allReports);

    // 1. Apply Search Query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempReports = tempReports.where((report) {
        return report.category.toLowerCase().contains(query) ||
               report.description.toLowerCase().contains(query) ||
               report.locationName.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Apply Status Filters
    if (_selectedStatuses.isNotEmpty) {
      tempReports = tempReports.where((report) {
        return _selectedStatuses.contains(report.status);
      }).toList();
    }

    // 3. Apply Sorting
    tempReports.sort((a, b) {
      if (_sortAscending) {
        return a.createdAt.compareTo(b.createdAt); // Oldest first
      } else {
        return b.createdAt.compareTo(a.createdAt); // Newest first
      }
    });
    
    setState(() {
      _filteredReports = tempReports;
    });
  }

  // --- NEW FILTER DIALOG ---
  void _showFilterDialog() {
    // Temporary state for the dialog
    Set<String> tempStatuses = Set.from(_selectedStatuses);
    bool tempSortAscending = _sortAscending;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter by Status', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: ['submitted', 'in_progress', 'resolved'].map((status) {
                      final isSelected = tempStatuses.contains(status);
                      return FilterChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              tempStatuses.add(status);
                            } else {
                              tempStatuses.remove(status);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(height: 32),
                  Text('Sort by Date', style: Theme.of(context).textTheme.titleLarge),
                  RadioListTile<bool>(
                    title: const Text('Newest First'),
                    value: false,
                    groupValue: tempSortAscending,
                    onChanged: (value) => setModalState(() => tempSortAscending = value!),
                  ),
                  RadioListTile<bool>(
                    title: const Text('Oldest First'),
                    value: true,
                    groupValue: tempSortAscending,
                    onChanged: (value) => setModalState(() => tempSortAscending = value!),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                             // Reset state and apply
                            setState(() {
                              _selectedStatuses = {};
                              _sortAscending = false;
                              _applyFiltersAndSearch();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            // Apply the selected filters
                            setState(() {
                              _selectedStatuses = tempStatuses;
                              _sortAscending = tempSortAscending;
                              _applyFiltersAndSearch();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // YOUR APPBAR IS UNCHANGED, I'VE ONLY ADDED THE FILTER BUTTON
        title: const Text('My Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(_viewMode == ViewMode.list ? Icons.grid_view_rounded : Icons.view_list_rounded),
            onPressed: _toggleViewMode,
            tooltip: 'Toggle View',
          ),
          // --- NEW FILTER BUTTON ---
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Reports',
          ),
        ],
      ),
      body: Column(
        children: [
          // --- NEW SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by category, location...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // The FutureBuilder now handles the initial data fetch.
          Expanded(
            child: FutureBuilder<List<ReportModel>>(
              future: _myReportsFuture,
              builder: (context, snapshot) {
                // YOUR FUTURE BUILDER LOGIC IS UNCHANGED
                if (snapshot.connectionState == ConnectionState.waiting && _allReports.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }
                if (_allReports.isEmpty) {
                  return _buildEmptyState();
                }
                // --- MODIFICATION: CHECK FILTERED RESULTS ---
                if (_filteredReports.isEmpty) {
                  return _buildEmptyState(isFilter: true); // Show a specific message
                }

                // YOUR ANIMATED SWITCHER IS UNCHANGED
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _viewMode == ViewMode.grid
                      ? _buildGridView(_filteredReports) // Use filtered list
                      : _buildListView(_filteredReports),  // Use filtered list
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- YOUR BUILD HELPERS ARE UNCHANGED, WITH A SMALL TWEAK TO _buildEmptyState ---

  Widget _buildListView(List<ReportModel> reports) {
    return ListView.builder(
      key: const ValueKey('list_view'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          child: ReportListItem(report: reports[index]),
        );
      },
    );
  }

  Widget _buildGridView(List<ReportModel> reports) {
    return GridView.builder(
      key: const ValueKey('grid_view'),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          child: ReportGridItem(report: reports[index]),
        );
      },
    );
  }

  Widget _buildEmptyState({bool isFilter = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFilter ? Icons.filter_drama_rounded : Icons.folder_off_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isFilter ? 'No Reports Match' : 'No Reports Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            isFilter ? 'Try adjusting your search or filters.' : 'You haven\'t submitted any reports yet.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 80, color: Colors.red[200]),
            const SizedBox(height: 16),
            Text(
              'Something Went Wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// YOUR ANIMATED LIST ITEM IS UNCHANGED
class AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;
  const AnimatedListItem({super.key, required this.index, required this.child});

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2 * widget.index, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

