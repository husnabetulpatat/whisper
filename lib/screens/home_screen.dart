import 'package:flutter/material.dart';
import '../models/notebook.dart';
import '../theme/whisper_colors.dart';
import '../services/storage_service.dart';
import 'notebook_screen.dart';
import '../utils/whisper_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Notebook> _notebooks = [];

  @override
  void initState() {
    super.initState();
    _loadNotebooks();
  }

  Future<void> _loadNotebooks() async {
    final notebooks = await StorageService.loadNotebooks();
    setState(() {
      _notebooks.addAll(notebooks);
    });
  }

  Future<void> _save() async {
    await StorageService.saveNotebooks(_notebooks);
  }

  void _createNotebook() {
    final now = DateTime.now();
    final notebook = Notebook(
      id: now.millisecondsSinceEpoch.toString(),
      name: 'new notebook',
      createdAt: now,
      updatedAt: now,
    );
    setState(() {
      _notebooks.add(notebook);
    });
    _save();
    _showRenameDialog(notebook);
  }

  void _showRenameDialog(Notebook notebook) {
    final controller = TextEditingController(text: notebook.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: WhisperColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'name your notebook',
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
            child: const Text(
              'cancel',
              style: TextStyle(
                color: WhisperColors.inkFaint,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                notebook.name = controller.text.trim().isEmpty
                    ? 'new notebook'
                    : controller.text.trim();
              });
              _save();
              Navigator.pop(context);
            },
            child: const Text(
              'save',
              style: TextStyle(
                color: WhisperColors.accent,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotebookOptions(Notebook notebook) {
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
              notebook.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(notebook);
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
                _confirmDeleteNotebook(notebook);
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

  void _confirmDeleteNotebook(Notebook notebook) {
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
              'delete "${notebook.name}"?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${notebook.pages.length} whispers will be lost',
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
                        _notebooks.remove(notebook);
                      });
                      _save();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _notebooks.isEmpty
                  ? _buildEmptyState()
                  : _buildNotebookList(),
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
          Text(
            'whisper.',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'your quiet space',
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
            'no notebooks yet',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'tap + to begin',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildNotebookList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _notebooks.length,
      itemBuilder: (context, index) {
        final notebook = _notebooks[index];
        return _NotebookCard(
          notebook: notebook,
          onLongPress: () => _showNotebookOptions(notebook),
          onTap: () async {
            await Navigator.push(
              context,
              WhisperRouter.toNotebook(notebook, _save),
            );
            setState(() {});
          },
        );
      },
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _createNotebook,
      backgroundColor: WhisperColors.accent,
      elevation: 0,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}

class _NotebookCard extends StatelessWidget {
  final Notebook notebook;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _NotebookCard({
    required this.notebook,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WhisperColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: notebook.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notebook.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${notebook.pages.length} whispers',
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
    );
  }
}