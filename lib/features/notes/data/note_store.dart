import 'package:flutter/material.dart';

import '../../../core/services/api_client.dart';

class NoteStore extends ChangeNotifier {
  NoteStore.demo()
      : _apiClient = ApiClient(),
        _token = '',
        _notes = [];

  NoteStore({
    required ApiClient apiClient,
    required String token,
  })  : _apiClient = apiClient,
        _token = token {
    load();
  }

  final ApiClient _apiClient;
  final String _token;
  List<NoteItem> _notes = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<NoteItem> get notes => List.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _apiClient.listNotes(_token);
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Nao foi possivel carregar as notas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<NoteItem?> create({
    String? title,
    String? content,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final note = await _apiClient.createNote(
        token: _token,
        title: title,
        content: content,
      );
      _notes = [note, ..._notes];
      return note;
    } on ApiException catch (error) {
      _error = error.message;
      return null;
    } catch (_) {
      _error = 'Nao foi possivel criar a nota.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> update({
    required String id,
    String? title,
    String? content,
    bool? isFavorite,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final note = await _apiClient.updateNote(
        token: _token,
        id: id,
        title: title,
        content: content,
        isFavorite: isFavorite,
      );
      _notes = _notes.map((item) => item.id == id ? note : item).toList();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'Nao foi possivel salvar a nota.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMany(List<String> ids) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _apiClient.deleteNotes(token: _token, ids: ids);
      final selected = ids.toSet();
      _notes = _notes.where((note) => !selected.contains(note.id)).toList();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'Nao foi possivel excluir as notas.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> favoriteMany(List<String> ids) async {
    if (ids.isEmpty) {
      return true;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final selected = ids.toSet();
      final updatedNotes = <NoteItem>[];

      for (final note in _notes.where((note) => selected.contains(note.id))) {
        final updated = await _apiClient.updateNote(
          token: _token,
          id: note.id,
          isFavorite: true,
        );
        updatedNotes.add(updated);
      }

      _notes = _notes.map((note) {
        return updatedNotes.firstWhere(
          (updated) => updated.id == note.id,
          orElse: () => note,
        );
      }).toList();

      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'Nao foi possivel favoritar as notas.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> duplicateMany(List<String> ids) async {
    if (ids.isEmpty) {
      return true;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final selected = ids.toSet();
      final copies = <NoteItem>[];
      final notesToCopy = _notes.where((note) => selected.contains(note.id));

      for (final note in notesToCopy) {
        final title = note.title.trim().isEmpty ? 'Sem titulo' : note.title;
        var copy = await _apiClient.createNote(
          token: _token,
          title: '$title (copia)',
          content: note.content,
        );

        if (note.isFavorite) {
          copy = await _apiClient.updateNote(
            token: _token,
            id: copy.id,
            isFavorite: true,
          );
        }

        copies.add(copy);
      }

      _notes = [...copies, ..._notes];
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'Nao foi possivel duplicar as notas.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
