import 'package:flutter/material.dart';
import '../models/notebook.dart';
import '../models/whisper_page.dart';
import '../models/page_element.dart';
import '../theme/whisper_colors.dart';
import '../widgets/whisper_preview.dart';
import 'canvas/canvas_screen.dart';
import '../utils/whisper_router.dart';

class NotebookScreen extends StatefulWidget {
  final Notebook notebook;
  final VoidCallback onChanged;

  const NotebookScreen({
    super.key,
    required this.notebook,
    required this.onChanged,
  });

  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> {
  void _createWhisper() {
    final now = DateTime.now();
    final page = WhisperPage(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
    );
    setState(() {
      widget.notebook.pages.add(page);
    });
    widget.onChanged();
    _showRenameWhisperDialog(page);
  }

  void _showWhisperOptions(WhisperPage page) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: WhisperColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              page.title.isEmpty ? 'untitled whisper' : page.title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showRenameWhisperDialog(page);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: WhisperColors.divider, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('rename',
                      style: TextStyle(
                          fontSize: 13, color: WhisperColors.inkLight)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteWhisper(page);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE07070).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('delete',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFFE07070))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameWhisperDialog(WhisperPage page) {
    final controller = TextEditingController(text: page.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: WhisperColors.surface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'name your whisper',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: WhisperColors.ink,
            letterSpacing: 1,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(
            fontSize: 16,
            color: WhisperColors.ink,
            fontWeight: FontWeight.w300,
          ),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: WhisperColors.divider),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: WhisperColors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel',
                style: TextStyle(
                    color: WhisperColors.inkFaint,
                    fontWeight: FontWeight.w300)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                page.title = controller.text.trim().isEmpty
                    ? 'untitled whisper'
                    : controller.text.trim();
              });
              widget.onChanged();
              Navigator.pop(context);
            },
            child: const Text('save',
                style: TextStyle(
                    color: WhisperColors.accent,
                    fontWeight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWhisper(WhisperPage page) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: WhisperColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('delete this whisper?',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              page.title.isEmpty ? 'untitled whisper' : page.title,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: WhisperColors.divider, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('cancel',
                            style: TextStyle(
                                fontSize: 13,
                                color: WhisperColors.inkLight)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        widget.notebook.pages.remove(page);
                      });
                      widget.onChanged();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE07070).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('delete',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE07070))),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: widget.notebook.pages.isEmpty
                  ? _buildEmptyState()
                  : _buildPageList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_back_ios,
                  size: 14,
                  color: WhisperColors.inkFaint,
                ),
                const SizedBox(width: 4),
                Text(
                  'notebooks',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.notebook.name,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.notebook.pages.length} whispers',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '·',
            style: TextStyle(fontSize: 48, color: WhisperColors.inkFaint),
          ),
          const SizedBox(height: 16),
          Text(
            'no whispers yet',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'tap + to write your first whisper',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPageList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: widget.notebook.pages.length,
      itemBuilder: (context, index) {
        final page = widget.notebook.pages[index];
        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              WhisperRouter.toCanvas(page),
            );
            setState(() {});
            widget.onChanged();
          },
          onLongPress: () => _showWhisperOptions(page),
          child: _WhisperCard(
            page: page,
            formatDate: _formatDate,
            formatTime: _formatTime,
          ),
        );
      },
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _createWhisper,
      backgroundColor: WhisperColors.accent,
      elevation: 0,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}

class _WhisperCard extends StatelessWidget {
  final WhisperPage page;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;

  const _WhisperCard({
    required this.page,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final hasElements = page.elements
        .where((e) => e.type != PageElementType.drawing)
        .isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: WhisperColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasElements)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: LayoutBuilder(
                builder: (context, constraints) => WhisperPreview(
                  page: page,
                  width: constraints.maxWidth,
                  height: 90,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        page.title.isEmpty
                            ? 'untitled whisper'
                            : page.title,
                        style:
                        Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatDate(page.createdAt)}  ·  ${formatTime(page.createdAt)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: WhisperColors.inkFaint,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}