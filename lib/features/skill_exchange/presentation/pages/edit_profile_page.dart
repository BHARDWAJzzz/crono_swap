import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_providers.dart';
import '../../domain/entities/user.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final AppUser user;
  const EditProfilePage({super.key, required this.user});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _linkedinController;
  late List<String> _selectedInterests;
  bool _isLoading = false;
  XFile? _imageFile;
  File? _certificateFile;
  File? _resumeFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _availableInterests = [
    'Design', 'Coding', 'Cooking', 'Music', 'Fitness', 'Language', 'Marketing', 'Photography'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    _linkedinController = TextEditingController(text: widget.user.linkedinUrl);
    _selectedInterests = List.from(widget.user.interests);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _pickVerificationFile(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (type == 'certificate') {
          _certificateFile = File(result.files.single.path!);
        } else {
          _resumeFile = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      String? avatarUrl;
      String? certUrl;
      String? resumeUrl;

      if (_imageFile != null) {
        avatarUrl = await ref.read(authRepositoryProvider).uploadProfileImage(File(_imageFile!.path));
      }
      if (_certificateFile != null) {
        certUrl = await ref.read(authRepositoryProvider).uploadVerificationFile(_certificateFile!, 'certificate');
      }
      if (_resumeFile != null) {
        resumeUrl = await ref.read(authRepositoryProvider).uploadVerificationFile(_resumeFile!, 'resume');
      }

      await ref.read(authRepositoryProvider).updateUserProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        interests: _selectedInterests,
        avatarUrl: avatarUrl,
        certificateUrl: certUrl,
        resumeUrl: resumeUrl,
        linkedinUrl: _linkedinController.text.trim().isNotEmpty ? _linkedinController.text.trim() : null,
      );
      
      ref.invalidate(userDataProvider);
      if (mounted) Navigator.pop(context);
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
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: _save,
              child: Text('SAVE', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: _imageFile != null 
                        ? FileImage(File(_imageFile!.path)) 
                        : (widget.user.avatarUrl != null ? NetworkImage(widget.user.avatarUrl!) : null) as ImageProvider?,
                    child: _imageFile == null && widget.user.avatarUrl == null 
                        ? Icon(Icons.person_outline_rounded, size: 40, color: Colors.grey.shade400) 
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            _buildSectionTitle('Full Name'),
            const SizedBox(height: 8),
            _buildTextField(_nameController, 'Your Name', Icons.person_outline),
            const SizedBox(height: 24),
            _buildSectionTitle('Bio'),
            const SizedBox(height: 8),
            _buildTextField(_bioController, 'A bit about you...', Icons.edit_note_rounded, maxLines: 3),
            const SizedBox(height: 24),
            _buildSectionTitle('Interests'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.primary,
                );
              }).toList(),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('LinkedIn Profile'),
                const SizedBox(height: 8),
                _buildTextField(_linkedinController, 'linkedin.com/in/username', Icons.link_rounded),
                const SizedBox(height: 32),
                _buildSectionTitle('Professional Verification'),
                const SizedBox(height: 12),
                _buildFileUploadTile(
                  title: 'Certificate (PDF)',
                  file: _certificateFile,
                  existingUrl: widget.user.certificateUrl,
                  onTap: () => _pickVerificationFile('certificate'),
                  icon: Icons.verified_user_outlined,
                ),
                const SizedBox(height: 16),
                _buildFileUploadTile(
                  title: 'Resume / CV (PDF)',
                  file: _resumeFile,
                  existingUrl: widget.user.resumeUrl,
                  onTap: () => _pickVerificationFile('resume'),
                  icon: Icons.description_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadTile({
    required String title,
    File? file,
    String? existingUrl,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file != null 
                        ? file.path.split('/').last 
                        : (existingUrl != null ? 'Credential Uploaded' : 'Select PDF'),
                    style: TextStyle(
                      color: (file != null || existingUrl != null) ? Colors.black87 : Colors.grey.shade400,
                      fontWeight: (file != null || existingUrl != null) ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (file != null || existingUrl != null)
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
