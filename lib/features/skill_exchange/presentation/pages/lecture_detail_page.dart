import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/lecture.dart';
import '../providers/auth_providers.dart';
import '../providers/lecture_providers.dart';

class LectureDetailPage extends ConsumerStatefulWidget {
  final Lecture lecture;
  const LectureDetailPage({super.key, required this.lecture});

  @override
  ConsumerState<LectureDetailPage> createState() => _LectureDetailPageState();
}

class _LectureDetailPageState extends ConsumerState<LectureDetailPage> {
  bool _isLoading = false;

  Future<void> _buyLecture() async {
    final user = ref.read(userDataProvider).value;
    if (user == null) return;

    if (user.timeBalance < widget.lecture.priceInHours) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. You need ${widget.lecture.priceInHours} hours.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(lectureRepositoryProvider).buyLecture(user.id, widget.lecture);
      ref.invalidate(userDataProvider); // Refresh balance and bought ids
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase successful! Item added to your library.')),
        );
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

  Future<void> _launchContent() async {
    final url = Uri.parse(widget.lecture.contentUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open content. The URL might be invalid.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(userDataProvider).value;
    final isBought = user?.boughtLectureIds.contains(widget.lecture.id) ?? false;
    final isOwner = user?.id == widget.lecture.providerId;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: Text('Lecture Details', style: GoogleFonts.outfit())),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 240,
              width: double.infinity,
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              child: Center(
                child: Icon(
                  widget.lecture.type == LectureType.video ? Icons.play_circle_fill_rounded : Icons.description_rounded,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.lecture.type.name.toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.lecture.priceInHours} Hours',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.lecture.durationMinutes} min)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.lecture.title,
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Published by ${widget.lecture.providerName}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const Divider(height: 48),
                  Text(
                    'About this lecture',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.lecture.description,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 15),
                  ),
                  const SizedBox(height: 80), // Space for bottom button
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10))],
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: (isBought || isOwner) ? _launchContent : _buyLecture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isBought || isOwner) ? Colors.green.shade600 : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  (isBought || isOwner) ? 'ACCESS CONTENT' : 'UNLOCK FOR ${widget.lecture.priceInHours} HOURS',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
        ),
      ),
    );
  }
}

