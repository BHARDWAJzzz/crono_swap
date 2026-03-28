import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/lecture.dart';
import '../providers/auth_providers.dart';
import '../providers/lecture_providers.dart';

class LectureUploadPage extends ConsumerStatefulWidget {
  const LectureUploadPage({super.key});

  @override
  ConsumerState<LectureUploadPage> createState() => _LectureUploadPageState();
}

class _LectureUploadPageState extends ConsumerState<LectureUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  LectureType _selectedType = LectureType.video;
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  int _calculatedPrice = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _calculatePrice(String durationStr) {
    final duration = int.tryParse(durationStr) ?? 0;
    if (duration == 0) {
      setState(() {
        _calculatedPrice = 0;
        _priceController.text = '';
      });
      return;
    }
    
    // Rule: 1 hour (60 min) = 1 credit. Use ceil to favor the creator.
    final price = (duration / 60).ceil();
    setState(() {
      _calculatedPrice = price;
      _priceController.text = price.toString();
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: _selectedType == LectureType.video ? FileType.video : FileType.custom,
      allowedExtensions: _selectedType == LectureType.video ? null : ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file to upload.')));
      return;
    }

    final user = ref.read(userDataProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final String lectureId = const Uuid().v4();
      
      // 1. Upload file to Storage
      final contentUrl = await ref.read(lectureRepositoryProvider).uploadLectureFile(
        _selectedFile!.path!, 
        '${lectureId}_${_selectedFile!.name}'
      );

      // 2. Save metadata to Firestore
      final lecture = Lecture(
        id: lectureId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        providerId: user.id,
        providerName: user.name,
        priceInHours: double.parse(_priceController.text.trim()),
        durationMinutes: int.parse(_durationController.text.trim()),
        type: _selectedType,
        contentUrl: contentUrl,
        createdAt: DateTime.now(),
        categories: ['General'],
      );

      await ref.read(lectureRepositoryProvider).uploadLecture(lecture);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lecture published successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: Text('Share Your Knowledge', style: GoogleFonts.outfit())),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lecture Details',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Monetize your expertise by setting a price in Crono Hours.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),
              _buildTextField(_titleController, 'Lecture Title', Icons.title_rounded, (v) => v!.isEmpty ? 'Please enter a title' : null),
              const SizedBox(height: 20),
              _buildTextField(_descriptionController, 'What will students learn?', Icons.description_outlined, (v) => v!.isEmpty ? 'Please enter a description' : null, maxLines: 4),
              const SizedBox(height: 20),
              _buildTextField(_durationController, 'Duration (in Minutes)', Icons.hourglass_bottom_rounded, (v) {
                if (v == null || v.isEmpty) return 'Please enter duration';
                if (int.tryParse(v) == null) return 'Enter a valid number';
                return null;
              }, keyboardType: TextInputType.number, onChanged: _calculatePrice),
              const SizedBox(height: 20),
              _buildTextField(_priceController, 'Price (in Hours) - Auto-calculated', Icons.timer_outlined, (v) {
                if (v == null || v.isEmpty) return 'Please set a price';
                if (int.tryParse(v) == null) return 'Enter a valid number';
                return null;
              }, keyboardType: TextInputType.number, readOnly: true),
              const SizedBox(height: 8),
              Text(
                'Fair Pricing: 1 credit per 60 mins of content.',
                style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Text(
                'Content Type',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TypeChip(
                    label: 'Video',
                    icon: Icons.play_circle_outline,
                    isSelected: _selectedType == LectureType.video,
                    onTap: () => setState(() => _selectedType = LectureType.video),
                  ),
                  const SizedBox(width: 12),
                  _TypeChip(
                    label: 'Document',
                    icon: Icons.article_outlined,
                    isSelected: _selectedType == LectureType.document,
                    onTap: () => setState(() => _selectedType = LectureType.document),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Upload Content',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                        color: _selectedFile != null ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _selectedFile?.name ?? 'Select ${_selectedType.name} file',
                          style: TextStyle(color: _selectedFile != null ? Colors.black87 : Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_selectedFile != null)
                        Text(
                          '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(1)} MB',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _upload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('PUBLISH LECTURE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String? Function(String?)? validator, {int maxLines = 1, TextInputType? keyboardType, bool readOnly = false, Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.grey)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.grey.shade200),
          boxShadow: isSelected ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
