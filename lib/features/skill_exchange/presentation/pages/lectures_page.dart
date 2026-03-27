import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/lecture_providers.dart';
import '../../domain/entities/lecture.dart';
import 'lecture_detail_page.dart';
import 'lecture_upload_page.dart';
import '../../../../core/widgets/shimmer_loader.dart';

class LecturesPage extends ConsumerStatefulWidget {
  const LecturesPage({super.key});

  @override
  ConsumerState<LecturesPage> createState() => _LecturesPageState();
}

class _LecturesPageState extends ConsumerState<LecturesPage> {
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text('Knowledge Hub', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LectureUploadPage())),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.outfit(),
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'Marketplace'),
              Tab(text: 'My Library'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLectureList(ref.watch(lectureListProvider), 'No lectures found'),
            _buildLectureList(ref.watch(myPurchasedLecturesProvider), 'You haven\'t purchased any lectures yet'),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureList(AsyncValue<List<Lecture>> lecturesAsync, String emptyMessage) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search title or content...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: lecturesAsync.when(
            data: (lectures) {
              final filtered = lectures.where((l) => 
                l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                l.description.toLowerCase().contains(_searchQuery.toLowerCase())
              ).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(emptyMessage, style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _LectureCard(lecture: filtered[index]),
              );
            },
            loading: () => GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75,
              ),
              itemCount: 4,
              itemBuilder: (e, i) => const ShimmerLoader(width: 150, height: 200, borderRadius: 20),
            ),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _LectureCard extends StatelessWidget {
  final Lecture lecture;
  const _LectureCard({required this.lecture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LectureDetailPage(lecture: lecture))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 100,
                width: double.infinity,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Icon(
                  lecture.type == LectureType.video ? Icons.play_circle_filled_rounded : Icons.description_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${lecture.providerName}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${lecture.priceInHours} Hrs',
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${lecture.durationMinutes}m)',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
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
}
