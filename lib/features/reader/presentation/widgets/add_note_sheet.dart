import 'package:flutter/material.dart';

import '../../domain/annotation_color.dart';

class AnnotationDraft {
  const AnnotationDraft({
    required this.colorId,
    required this.isFavorite,
    this.noteText = '',
  });

  final String noteText;
  final String colorId;
  final bool isFavorite;
}

class AddNoteSheet extends StatefulWidget {
  const AddNoteSheet({
    required this.selectedText,
    required this.onSave,
    this.includeNoteField = true,
    this.title = 'Add note',
    this.saveLabel = 'Save note',
    super.key,
  });

  final String selectedText;
  final ValueChanged<AnnotationDraft> onSave;
  final bool includeNoteField;
  final String title;
  final String saveLabel;

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final TextEditingController _controller = TextEditingController();
  String _colorId = annotationColors.first.id;
  bool _isFavorite = false;

  bool get _canSave {
    return !widget.includeNoteField || _controller.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.selectedText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in annotationColors)
                  ChoiceChip(
                    selected: _colorId == item.id,
                    onSelected: (_) => setState(() => _colorId = item.id),
                    label: Text(item.label),
                    avatar: CircleAvatar(backgroundColor: item.color),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isFavorite,
              onChanged: (value) => setState(() => _isFavorite = value),
              title: const Text('Favorite'),
              secondary: const Icon(Icons.star_border_rounded),
            ),
            if (widget.includeNoteField) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 4,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Write a note...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: Text(widget.saveLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTextChanged() {
    setState(() {});
  }

  void _save() {
    widget.onSave(
      AnnotationDraft(
        noteText: _controller.text.trim(),
        colorId: _colorId,
        isFavorite: _isFavorite,
      ),
    );
    Navigator.of(context).pop();
  }
}
