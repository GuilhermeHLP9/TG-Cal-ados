import 'package:flutter/material.dart';

import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../data/note_store.dart';

enum _NoteSort {
  createdAsc,
  createdDesc,
  nameAsc,
  nameDesc,
}

enum _TimeFilter {
  all,
  yesterday,
  last7Days,
  last30Days,
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({
    super.key,
    required this.store,
    required this.subtitle,
  });

  final NoteStore store;
  final String subtitle;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  _NoteSort _sort = _NoteSort.createdDesc;
  _TimeFilter _timeFilter = _TimeFilter.all;
  bool _favoritesOnly = false;
  bool _favoritesOnTop = false;
  bool _selecting = false;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final notes = _visibleNotes(widget.store.notes);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                if (widget.store.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 86, 24, 28),
                        sliver: SliverToBoxAdapter(
                          child: _Header(
                            count: notes.length,
                            selecting: _selecting,
                            selectedCount: _selectedIds.length,
                            onCancelSelection: _exitSelection,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          0,
                          24,
                          _selecting ? 120 : 28,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _Toolbar(
                            favoritesOnTop: _favoritesOnTop,
                            onFilter: _showFilterSheet,
                            onEdit: _enterSelection,
                            onSort: _showSortSheet,
                            onToggleFavoritesTop: () {
                              setState(() {
                                _favoritesOnTop = !_favoritesOnTop;
                              });
                            },
                          ),
                        ),
                      ),
                      if (widget.store.error != null)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              widget.store.error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (notes.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'Nenhuma nota',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._buildSections(notes),
                    ],
                  ),
                if (_selecting)
                  _SelectionActionBar(
                    selectedCount: _selectedIds.length,
                    onDeleteSelected: _deleteSelected,
                    onFavoriteSelected: _favoriteSelected,
                    onDuplicateSelected: _duplicateSelected,
                  )
                else
                  _CreateNoteButton(onCreate: _createNote),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSections(List<NoteItem> notes) {
    final sections = <_NoteSection>[];
    final remaining = [...notes];

    if (_favoritesOnTop) {
      final favorites = remaining.where((note) => note.isFavorite).toList();
      remaining.removeWhere((note) => note.isFavorite);

      if (favorites.isNotEmpty) {
        sections.add(_NoteSection('Favoritos', favorites));
      }
    }

    String? currentLabel;
    final groupedNotes = <NoteItem>[];

    void flush() {
      final label = currentLabel;
      if (label != null && groupedNotes.isNotEmpty) {
        sections.add(_NoteSection(label, [...groupedNotes]));
        groupedNotes.clear();
      }
    }

    for (final note in remaining) {
      final label = _sectionLabel(note.createdAt);
      if (currentLabel != label) {
        flush();
        currentLabel = label;
      }
      groupedNotes.add(note);
    }
    flush();

    return sections
        .map(
          (section) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 34),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      section.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SliverGrid.builder(
                  itemCount: section.notes.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 26,
                    childAspectRatio: 0.74,
                  ),
                  itemBuilder: (context, index) {
                    final note = section.notes[index];
                    return _NoteTile(
                      note: note,
                      selecting: _selecting,
                      selected: _selectedIds.contains(note.id),
                      onTap: () => _onNoteTap(note),
                      onLongPress: () => _toggleSelection(note.id),
                    );
                  },
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  List<NoteItem> _visibleNotes(List<NoteItem> source) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var notes = source.where((note) {
      if (_favoritesOnly && !note.isFavorite) {
        return false;
      }

      final created = DateTime(
        note.createdAt.year,
        note.createdAt.month,
        note.createdAt.day,
      );

      switch (_timeFilter) {
        case _TimeFilter.all:
          return true;
        case _TimeFilter.yesterday:
          return created == today.subtract(const Duration(days: 1));
        case _TimeFilter.last7Days:
          return !created.isBefore(today.subtract(const Duration(days: 7)));
        case _TimeFilter.last30Days:
          return !created.isBefore(today.subtract(const Duration(days: 30)));
      }
    }).toList();

    notes.sort((a, b) {
      switch (_sort) {
        case _NoteSort.createdAsc:
          return a.createdAt.compareTo(b.createdAt);
        case _NoteSort.createdDesc:
          return b.createdAt.compareTo(a.createdAt);
        case _NoteSort.nameAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case _NoteSort.nameDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
      }
    });

    return notes;
  }

  Future<void> _createNote() async {
    final draft = await widget.store.create(title: 'Sem titulo');

    if (!mounted || draft == null) {
      _showStoreError();
      return;
    }

    await _openEditor(draft);
  }

  Future<void> _openEditor(NoteItem note) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _NoteEditorScreen(
          note: note,
          store: widget.store,
        ),
      ),
    );
  }

  void _onNoteTap(NoteItem note) {
    if (_selecting) {
      _toggleSelection(note.id);
      return;
    }

    _openEditor(note);
  }

  void _enterSelection() {
    setState(() => _selecting = true);
  }

  void _exitSelection() {
    setState(() {
      _selecting = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      _selecting = true;
      if (!_selectedIds.add(id)) {
        _selectedIds.remove(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final ids = _selectedIds.toList();
    final deleted = await widget.store.deleteMany(ids);

    if (!mounted) {
      return;
    }

    if (deleted) {
      _exitSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notas excluidas.')),
      );
    } else {
      _showStoreError();
    }
  }

  Future<void> _favoriteSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final favorited = await widget.store.favoriteMany(_selectedIds.toList());

    if (!mounted) {
      return;
    }

    if (favorited) {
      _exitSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notas adicionadas aos favoritos.')),
      );
    } else {
      _showStoreError();
    }
  }

  Future<void> _duplicateSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final duplicated = await widget.store.duplicateMany(_selectedIds.toList());

    if (!mounted) {
      return;
    }

    if (duplicated) {
      _exitSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notas duplicadas.')),
      );
    } else {
      _showStoreError();
    }
  }

  void _showStoreError() {
    final message = widget.store.error ?? 'Nao foi possivel concluir a acao.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showSortSheet() async {
    final selected = await showModalBottomSheet<_NoteSort>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SortSheet(selected: _sort),
    );

    if (selected != null) {
      setState(() => _sort = selected);
    }
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        timeFilter: _timeFilter,
        favoritesOnly: _favoritesOnly,
      ),
    );

    if (result != null) {
      setState(() {
        _timeFilter = result.timeFilter;
        _favoritesOnly = result.favoritesOnly;
      });
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.selecting,
    required this.selectedCount,
    required this.onCancelSelection,
  });

  final int count;
  final bool selecting;
  final int selectedCount;
  final VoidCallback onCancelSelection;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (selecting) {
      return Row(
        children: [
          IconButton(
            tooltip: 'Cancelar selecao',
            onPressed: onCancelSelection,
            icon: Icon(Icons.close, color: colors.onSurface),
          ),
          const SizedBox(width: 10),
          Text(
            '$selectedCount selecionada${selectedCount == 1 ? '' : 's'}',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'Todas as notas',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 38,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$count nota${count == 1 ? '' : 's'}',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.favoritesOnTop,
    required this.onFilter,
    required this.onEdit,
    required this.onSort,
    required this.onToggleFavoritesTop,
  });

  final bool favoritesOnTop;
  final VoidCallback onFilter;
  final VoidCallback onEdit;
  final VoidCallback onSort;
  final VoidCallback onToggleFavoritesTop;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        const Spacer(),
        IconButton(
          tooltip: 'Filtros',
          onPressed: onFilter,
          icon: Icon(Icons.tune, color: colors.primary, size: 34),
        ),
        PopupMenuButton<String>(
          tooltip: 'Mais opcoes',
          color: colors.surface,
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            }
            if (value == 'sort') {
              onSort();
            }
            if (value == 'favorites') {
              onToggleFavoritesTop();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: _MenuText('Editar')),
            const PopupMenuItem(value: 'sort', child: _MenuText('Ordenar')),
            PopupMenuItem(
              value: 'favorites',
              child: _MenuText(
                favoritesOnTop
                    ? 'Desafixar favoritos do topo'
                    : 'Fixar favoritos no topo',
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.more_vert, color: colors.primary, size: 34),
          ),
        ),
      ],
    );
  }
}

class _MenuText extends StatelessWidget {
  const _MenuText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 20,
      ),
    );
  }
}

class _CreateNoteButton extends StatelessWidget {
  const _CreateNoteButton({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 24,
      child: FloatingActionButton(
        heroTag: 'create-note',
        tooltip: 'Nova nota',
        onPressed: onCreate,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit_outlined, size: 30),
      ),
    );
  }
}

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.selectedCount,
    required this.onDeleteSelected,
    required this.onFavoriteSelected,
    required this.onDuplicateSelected,
  });

  final int selectedCount;
  final VoidCallback onDeleteSelected;
  final VoidCallback onFavoriteSelected;
  final VoidCallback onDuplicateSelected;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    final colors = Theme.of(context).colorScheme;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _SelectionActionButton(
                icon: Icons.delete_outline,
                label: 'Apagar',
                enabled: hasSelection,
                color: AppColors.danger,
                onTap: onDeleteSelected,
              ),
              _SelectionActionButton(
                icon: Icons.star_border,
                label: 'Favoritar',
                enabled: hasSelection,
                color: const Color(0xFFE2A800),
                onTap: onFavoriteSelected,
              ),
              _SelectionActionButton(
                icon: Icons.copy_outlined,
                label: 'Duplicar',
                enabled: hasSelection,
                color: AppColors.primary,
                onTap: onDuplicateSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionActionButton extends StatelessWidget {
  const _SelectionActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        enabled ? color : Theme.of(context).colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: effectiveColor),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.note,
    required this.selecting,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final NoteItem note;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        selecting ? 48 : 16,
                        selecting ? 22 : 16,
                        16,
                        16,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: selected
                            ? Border.all(color: colors.primary, width: 2)
                            : Border.all(color: colors.outlineVariant),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _previewText(note),
                        maxLines: 8,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 16,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
                if (note.isFavorite)
                  const Positioned(
                    top: 10,
                    right: 10,
                    child: Icon(Icons.star, color: Color(0xFFFFD33D)),
                  ),
                if (selecting)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _SelectionBadge(selected: selected),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            note.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatNoteDate(note.createdAt),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? colors.primary : colors.onSurface.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? colors.primary : colors.onSurfaceVariant,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : null,
    );
  }
}

class _NoteEditorScreen extends StatefulWidget {
  const _NoteEditorScreen({
    required this.note,
    required this.store,
  });

  final NoteItem note;
  final NoteStore store;

  @override
  State<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<_NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late bool _favorite;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _favorite = widget.note.isFavorite;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: colors.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _favorite ? 'Remover favorito' : 'Favoritar',
            onPressed: () => setState(() => _favorite = !_favorite),
            icon: Icon(_favorite ? Icons.star : Icons.star_border),
          ),
          TextButton(
            onPressed: _save,
            child: const Text('Salvar'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  hintText: 'Sem titulo',
                  hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    height: 1.45,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escreva aqui...',
                    hintStyle: TextStyle(color: colors.onSurfaceVariant),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final saved = await widget.store.update(
      id: widget.note.id,
      title: _titleController.text.trim().isEmpty
          ? 'Sem titulo'
          : _titleController.text,
      content: _contentController.text,
      isFavorite: _favorite,
    );

    if (!mounted) {
      return;
    }

    if (saved) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.store.error ?? 'Nao foi possivel salvar a nota.'),
        ),
      );
    }
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.selected});

  final _NoteSort selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = [
      (_NoteSort.createdAsc, 'Data de criacao (crescente)'),
      (_NoteSort.createdDesc, 'Data de criacao (decrescente)'),
      (_NoteSort.nameAsc, 'Nome (A a Z)'),
      (_NoteSort.nameDesc, 'Nome (Z a A)'),
    ];

    return _BottomPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ordenar por',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          ...items.map((item) {
            final isSelected = item.$1 == selected;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
              title: Text(
                item.$2,
                style: TextStyle(color: colors.onSurface, fontSize: 20),
              ),
              onTap: () => Navigator.of(context).pop(item.$1),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.timeFilter,
    required this.favoritesOnly,
  });

  final _TimeFilter timeFilter;
  final bool favoritesOnly;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _TimeFilter _timeFilter;
  late bool _favoritesOnly;

  @override
  void initState() {
    super.initState();
    _timeFilter = widget.timeFilter;
    _favoritesOnly = widget.favoritesOnly;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _BottomPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filtros',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Concluir',
                onPressed: () => Navigator.of(context).pop(
                  _FilterResult(_timeFilter, _favoritesOnly),
                ),
                icon: Icon(Icons.check, color: colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _FilterLabel('Hora'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FilterChipButton(
                label: 'Todos',
                selected: _timeFilter == _TimeFilter.all,
                onTap: () => setState(() => _timeFilter = _TimeFilter.all),
              ),
              _FilterChipButton(
                label: 'Ontem',
                selected: _timeFilter == _TimeFilter.yesterday,
                onTap: () => setState(() => _timeFilter = _TimeFilter.yesterday),
              ),
              _FilterChipButton(
                label: 'Ultimos 7 dias',
                selected: _timeFilter == _TimeFilter.last7Days,
                onTap: () => setState(() => _timeFilter = _TimeFilter.last7Days),
              ),
              _FilterChipButton(
                label: 'Ultimos 30 dias',
                selected: _timeFilter == _TimeFilter.last30Days,
                onTap: () => setState(() => _timeFilter = _TimeFilter.last30Days),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _FilterLabel('Tipo'),
          const SizedBox(height: 12),
          _FilterChipButton(
            label: 'Favoritos',
            selected: _favoritesOnly,
            onTap: () => setState(() => _favoritesOnly = !_favoritesOnly),
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      text,
      style: TextStyle(
        color: colors.onSurfaceVariant,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.onPrimary : colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FilterResult {
  const _FilterResult(this.timeFilter, this.favoritesOnly);

  final _TimeFilter timeFilter;
  final bool favoritesOnly;
}

class _NoteSection {
  const _NoteSection(this.title, this.notes);

  final String title;
  final List<NoteItem> notes;
}

String _previewText(NoteItem note) {
  final content = note.content.trim();
  if (content.isNotEmpty) {
    return content;
  }

  return note.title == 'Sem titulo' ? '' : note.title;
}

String _formatNoteDate(DateTime date) {
  return '${date.day} de ${_monthLabel(date.month)}.';
}

String _sectionLabel(DateTime date) {
  final now = DateTime.now();
  if (date.year != now.year) {
    return date.year.toString();
  }

  return '${_monthLabel(date.month)}.';
}

String _monthLabel(int month) {
  const labels = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  return labels[month - 1];
}
