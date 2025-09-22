import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sih_crowd_source/src/data/models/report_model.dart';
import 'package:sih_crowd_source/src/data/providers/auth_state_provider.dart';
import 'package:sih_crowd_source/src/data/providers/report_state_provider.dart';
import 'package:sih_crowd_source/src/data/repositories/classification_repository.dart';
import 'package:sih_crowd_source/src/utils/location_service.dart';

class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  _SubmitReportScreenState createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _classificationRepo = ClassificationRepository();
  final _locationService = LocationService();
  final _picker = ImagePicker();
  final _descriptionController = TextEditingController();

  XFile? _imageFile;
  Position? _currentPosition;
  Map<String, String?>? _address;
  String? _locationName;
  String? _selectedCategory;
  bool _isClassifying = false;
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;

  late AnimationController _animationController;

  final List<String> _issueCategories = [
    'Pothole', 'Garbage', 'Broken Streetlight', 'Water Logging', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadModel();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _classificationRepo.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      await _classificationRepo.loadModel();
    } catch (e) {
      _showErrorSnackbar('Failed to load AI model: $e');
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (image == null) return;

      setState(() {
        _imageFile = image;
        _selectedCategory = null;
      });
    } catch (e) {
      _showErrorSnackbar('Error taking photo: $e');
    }
  }

  Future<void> _getAISuggestion() async {
    if (_imageFile == null) return;
    setState(() => _isClassifying = true);
    try {
      final category = await _classificationRepo.classifyImage(_imageFile!);
      if (_issueCategories.contains(category)) {
        setState(() => _selectedCategory = category);
      } else {
        setState(() => _selectedCategory = 'Other');
      }
    } catch (e) {
      _showErrorSnackbar('Error processing image: $e');
    } finally {
      if (mounted) {
        setState(() => _isClassifying = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final position = await _locationService.getCurrentLocation();
      final address = await _locationService.getAddressFromPosition(position);
      
      setState(() {
        _currentPosition = position;
        _address = address;
        _locationName = [address['subLocality'], address['locality'], address['city']]
            .where((s) => s != null && s.isNotEmpty)
            .take(2)
            .join(', ');
      });
    } catch (e) {
      _showErrorSnackbar('Failed to get location: $e');
    } finally {
      if(mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || _imageFile == null || _currentPosition == null) {
      _showErrorSnackbar('Please complete all steps before submitting.');
      return;
    }
    
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final authProvider = Provider.of<AuthStateProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      _showErrorSnackbar('Could not get user details. Please try again.');
      return;
    }

    setState(() => _isSubmitting = true);

    final newReport = ReportModel(
      submittedBy: user.uid,
      submittedByName: user.displayName,
      submittedByPhotoUrl: user.photoURL,
      createdAt: Timestamp.now(),
      coordinates: GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
      address: _address!,
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      status: 'submitted',
    );

    final error = await reportProvider.submitReport(newReport, File(_imageFile!.path));

    if (mounted) {
      if (error == null) {
        _showSuccessDialogAndPop();
      } else {
        _showErrorSnackbar('Failed to submit report: $error');
      }
      setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showSuccessDialogAndPop() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Report Submitted'),
          content: const Text('Thank you! Your issue has been submitted successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                Navigator.of(context).pop(); 
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Report a New Issue'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0), // Padding for the floating button
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimatedSlideFade(delay: 0.1, controller: _animationController, child: _buildStepHeader(context, '1', 'Capture')),
                  const SizedBox(height: 8),
                  _AnimatedSlideFade(delay: 0.2, controller: _animationController, child: _buildImagePickerCard()),
                  const SizedBox(height: 24),
                  
                  _AnimatedSlideFade(delay: 0.3, controller: _animationController, child: _buildStepHeader(context, '2', 'Describe')),
                  const SizedBox(height: 8),
                  _AnimatedSlideFade(delay: 0.4, controller: _animationController, child: _buildDescriptionCard()),
                  const SizedBox(height: 24),

                  _AnimatedSlideFade(delay: 0.5, controller: _animationController, child: _buildStepHeader(context, '3', 'Locate')),
                  const SizedBox(height: 8),
                  _AnimatedSlideFade(delay: 0.6, controller: _animationController, child: _buildLocationCard()),
                ],
              ),
            ),
          ),
          // Floating Submit Button
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _AnimatedSlideFade(delay: 0.7, controller: _animationController, child: _buildSubmitButton()),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context, String step, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildImagePickerCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: InkWell(
                onTap: _takePicture,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: _imageFile == null
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text('Tap to capture photo', style: TextStyle(color: Colors.grey.shade700)),
                        ]))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_imageFile!.path), fit: BoxFit.cover)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Issue Category', border: OutlineInputBorder()),
              items: _issueCategories.map((String category) => DropdownMenuItem<String>(value: category, child: Text(category))).toList(),
              onChanged: (newValue) => setState(() => _selectedCategory = newValue),
              validator: (value) => value == null ? 'Please select a category.' : null,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _imageFile == null || _isClassifying ? null : _getAISuggestion,
                icon: _isClassifying 
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_rounded),
                label: const Text('Get AI Suggestion'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'Add extra details here...', border: OutlineInputBorder()),
              maxLines: 4,
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description.' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isFetchingLocation 
          ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
          : (_locationName == null 
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Get My Location'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                )
              : ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.green)),
                  title: Text(_locationName!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}'),
                  trailing: IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _getCurrentLocation, tooltip: 'Refresh Location'),
                )
      ),
    )
    );
  }

  Widget _buildSubmitButton() {
    bool isFormComplete = _imageFile != null && _selectedCategory != null && _currentPosition != null;
    return ElevatedButton(
      onPressed: _isSubmitting || !isFormComplete ? null : _submitReport,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSubmitting
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
          : const Text('Submit Issue Report'),
    );
  }
}

class _AnimatedSlideFade extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const _AnimatedSlideFade({required this.controller, required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }
}

