// lib/helpers/file_helper.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/note.dart';

class FileHelper {
  static final FileHelper _instance = FileHelper._internal();
  FileHelper._internal();
  factory FileHelper() => _instance;

  static const int maxImages = 3;

  Future<Directory> _getNotesDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final notesDir = Directory(join(docsDir.path, 'notes'));
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    return notesDir;
  }

  String generateNoteId() {
    return 'note_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Baris 1: judul | Baris 2: lastModified (ISO 8601) | Baris 3+: isi
  Future<void> saveNote(String noteId, String title, String content) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));

    if (!await noteDir.exists()) {
      await noteDir.create(recursive: true);
    }

    final lastModified = DateTime.now().toIso8601String();
    final file = File(join(noteDir.path, 'content.txt'));
    await file.writeAsString('$title\n$lastModified\n$content');
  }

  Future<Note?> readNote(String noteId) async {
    final notesDir = await _getNotesDirectory();
    final file = File(join(notesDir.path, noteId, 'content.txt'));

    if (!await file.exists()) return null;

    final rawContent = await file.readAsString();
    final lines = rawContent.split('\n');

    final title = lines.isNotEmpty ? lines[0] : '';
    final lastModified = lines.length > 1 ? lines[1] : '';
    final content = lines.length > 2 ? lines.sublist(2).join('\n') : '';

    // Hitung jumlah gambar yang ada (image_1.jpg, image_2.jpg, image_3.jpg)
    int count = 0;
    for (int i = 1; i <= maxImages; i++) {
      final imageFile = File(join(notesDir.path, noteId, 'image_$i.jpg'));
      if (await imageFile.exists()) count++;
    }

    return Note(
      id: noteId,
      title: title,
      content: content,
      hasImage: count > 0,
      lastModified: lastModified,
      imageCount: count,
    );
  }

  Future<List<Note>> getAllNotes() async {
    final notesDir = await _getNotesDirectory();
    final List<String> noteIds = [];

    await for (final entity in notesDir.list()) {
      if (entity is Directory) {
        noteIds.add(entity.path.split(Platform.pathSeparator).last);
      }
    }

    noteIds.sort((a, b) => b.compareTo(a));

    final List<Note> notes = [];
    for (final id in noteIds) {
      final note = await readNote(id);
      if (note != null) notes.add(note);
    }

    return notes;
  }

  /// Menyimpan gambar berdasarkan indeks (1, 2, atau 3).
  Future<void> saveNoteImage(String noteId, int index, String sourcePath) async {
    assert(index >= 1 && index <= maxImages,
    'index harus antara 1 dan $maxImages');

    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));

    if (!await noteDir.exists()) {
      await noteDir.create(recursive: true);
    }

    final originalBytes = await File(sourcePath).readAsBytes();
    final compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: 70,
      minWidth: 1080,
      minHeight: 1080,
      format: CompressFormat.jpeg,
    );

    final imageFile = File(join(noteDir.path, 'image_$index.jpg'));
    await imageFile.writeAsBytes(compressedBytes);
  }

  /// Menghapus satu gambar berdasarkan indeks tanpa memengaruhi gambar lainnya.
  Future<void> deleteNoteImage(String noteId, int index) async {
    assert(index >= 1 && index <= maxImages,
    'index harus antara 1 dan $maxImages');

    final notesDir = await _getNotesDirectory();
    final imageFile = File(join(notesDir.path, noteId, 'image_$index.jpg'));
    if (await imageFile.exists()) {
      await imageFile.delete();
    }
  }

  /// Mengembalikan File gambar berdasarkan indeks, atau null jika tidak ada.
  Future<File?> getNoteImageFile(String noteId, int index) async {
    assert(index >= 1 && index <= maxImages,
    'index harus antara 1 dan $maxImages');

    final notesDir = await _getNotesDirectory();
    final imageFile = File(join(notesDir.path, noteId, 'image_$index.jpg'));
    if (!await imageFile.exists()) return null;
    return imageFile;
  }

  /// Mengembalikan semua File gambar yang ada untuk sebuah catatan.
  Future<List<File?>> getAllNoteImageFiles(String noteId) async {
    final List<File?> files = [];
    for (int i = 1; i <= maxImages; i++) {
      files.add(await getNoteImageFile(noteId, i));
    }
    return files;
  }

  Future<void> deleteNote(String noteId) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));
    if (await noteDir.exists()) {
      await noteDir.delete(recursive: true);
    }
  }
}