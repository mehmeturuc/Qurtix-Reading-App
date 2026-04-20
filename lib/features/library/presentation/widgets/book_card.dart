import 'package:flutter/material.dart';

import '../../../../shared/design/app_design.dart';
import '../../domain/book.dart';

enum BookCardAction { organize, removeFromCollection, delete }

class BookCard extends StatelessWidget {
  const BookCard({
    required this.book,
    required this.onTap,
    required this.onActionSelected,
    this.collectionName,
    super.key,
  });

  final Book book;
  final VoidCallback onTap;
  final ValueChanged<BookCardAction> onActionSelected;
  final String? collectionName;

  static const double horizontalPadding = AppSpacing.x3;
  static const double verticalPadding = AppSpacing.x3;
  static const double coverAspectRatio = 3 / 4;
  static const double sectionGap = AppSpacing.x3;
  static const double titleHeight = 44;
  static const double collectionHeight = 22;

  static double heightForWidth(double width) {
    final coverWidth = width - (horizontalPadding * 2);
    final coverHeight = coverWidth / coverAspectRatio;

    return (verticalPadding * 2) +
        coverHeight +
        sectionGap +
        titleHeight +
        sectionGap +
        collectionHeight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      label: '${book.title} by ${book.displayAuthor}',
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(verticalPadding),
        backgroundColor: colors.surfaceContainerLowest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: coverAspectRatio,
                  child: _BookCover(
                    book: book,
                    color: _coverColor(book.coverPath, colors),
                    icon: _iconFor(book.sourceType),
                  ),
                ),
                Positioned(
                  top: AppSpacing.x2,
                  right: AppSpacing.x2,
                  child: _BookActionsButton(
                    onSelected: onActionSelected,
                    showRemoveFromCollection: collectionName != null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: sectionGap),
            SizedBox(
              height: titleHeight,
              child: Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.18,
                ),
              ),
            ),
            const SizedBox(height: sectionGap),
            SizedBox(
              height: collectionHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppPill(
                  backgroundColor: collectionName == null
                      ? colors.surfaceContainerLow
                      : colors.secondaryContainer,
                  foregroundColor: collectionName == null
                      ? colors.onSurfaceVariant
                      : colors.onSecondaryContainer,
                  child: Text(
                    collectionName ?? 'Unsorted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _coverColor(String? coverPath, ColorScheme colors) {
    return switch (coverPath) {
      'cover-blue' => const Color(0xFF3269A8),
      'cover-red' => const Color(0xFFA8473B),
      'cover-purple' => const Color(0xFF7350A2),
      'cover-yellow' => const Color(0xFFC69125),
      'cover-teal' => const Color(0xFF2A8278),
      _ => colors.primary,
    };
  }

  IconData _iconFor(BookFileType fileType) {
    return switch (fileType) {
      BookFileType.pdf => Icons.picture_as_pdf_rounded,
      BookFileType.epub => Icons.menu_book_rounded,
      BookFileType.plainText => Icons.article_rounded,
    };
  }
}

class _BookActionsButton extends StatelessWidget {
  const _BookActionsButton({
    required this.onSelected,
    required this.showRemoveFromCollection,
  });

  final ValueChanged<BookCardAction> onSelected;
  final bool showRemoveFromCollection;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface.withValues(alpha: 0.72),
      borderRadius: AppCorners.pill,
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(
        dimension: 34,
        child: PopupMenuButton<BookCardAction>(
          tooltip: 'Book actions',
          padding: EdgeInsets.zero,
          icon: Icon(Icons.more_horiz_rounded, color: colors.onSurfaceVariant),
          onSelected: onSelected,
          itemBuilder: (context) => [
            const PopupMenuItem<BookCardAction>(
              value: BookCardAction.organize,
              child: Text('Move to folder'),
            ),
            if (showRemoveFromCollection)
              const PopupMenuItem<BookCardAction>(
                value: BookCardAction.removeFromCollection,
                child: Text('Remove from folder'),
              ),
            const PopupMenuItem<BookCardAction>(
              value: BookCardAction.delete,
              child: Text('Delete book completely'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.book,
    required this.color,
    required this.icon,
  });

  final Book book;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, colors.onSurface, 0.18) ?? color],
        ),
        borderRadius: AppCorners.md,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 22,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.08),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 42, color: colors.onPrimary),
                const SizedBox(height: AppSpacing.x3),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.9),
                    borderRadius: AppCorners.sm,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x3,
                      vertical: AppSpacing.x1,
                    ),
                    child: Text(
                      book.fileType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
