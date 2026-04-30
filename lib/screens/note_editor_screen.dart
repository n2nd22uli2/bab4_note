// lib/screens/note_editor_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/note.dart';
import '../helpers/file_helper.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final FileHelper _fileHelper = FileHelper();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isSaving = false;

  // Slot gambar: index 0 = image_1.jpg, index 1 = image_2.jpg, index 2 = image_3.jpg
  // null  → slot kosong
  // File  → gambar (bisa file baru dari galeri atau file lama dari disk)
  final List<File?> _imageSlots = [null, null, null];

  // Melacak apakah slot sudah tersimpan di disk (bukan file baru dari galeri)
  final List<bool> _isExistingImage = [false, false, false];

  bool get _isEditMode => widget.note != null;

  late final String _resolvedNoteId;

  int get _imageCount => _imageSlots.where((f) => f != null).length;
  bool get _canAddImage => _imageCount < FileHelper.maxImages;

  @override
  void initState() {
    super.initState();
    _resolvedNoteId =
        widget.note?.id ?? _fileHelper.generateNoteId();
    if (_isEditMode) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _loadExistingImages();
    }
  }

  Future<void> _loadExistingImages() async {
    final files = await _fileHelper.getAllNoteImageFiles(_resolvedNoteId);
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < files.length; i++) {
        _imageSlots[i] = files[i];
        _isExistingImage[i] = files[i] != null;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Menambah gambar baru ke slot kosong pertama yang tersedia.
  Future<void> _pickImage() async {
    if (!_canAddImage) return;

    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (xFile == null || !mounted) return;

    // Cari slot kosong pertama
    final emptyIndex = _imageSlots.indexWhere((f) => f == null);
    if (emptyIndex == -1) return;

    setState(() {
      _imageSlots[emptyIndex] = File(xFile.path);
      _isExistingImage[emptyIndex] = false;
    });
  }

  /// Menghapus gambar pada slot tertentu.
  Future<void> _removeImage(int slotIndex) async {
    setState(() {
      _imageSlots[slotIndex] = null;
      _isExistingImage[slotIndex] = false;
    });
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Judul atau isi catatan tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _fileHelper.saveNote(
        _resolvedNoteId,
        _titleController.text.trim(),
        _contentController.text.trim(),
      );

      for (int i = 0; i < FileHelper.maxImages; i++) {
        final fileInSlot = _imageSlots[i];
        final diskIndex = i + 1; // image_1.jpg … image_3.jpg

        if (fileInSlot == null) {
          // Slot dikosongkan → hapus dari disk jika sebelumnya ada
          if (_isExistingImage[i]) {
            await _fileHelper.deleteNoteImage(_resolvedNoteId, diskIndex);
          }
        } else {
          // Slot berisi gambar baru (bukan dari disk) → simpan
          final isNew = !_isExistingImage[i];
          if (isNew) {
            await _fileHelper.saveNoteImage(
                _resolvedNoteId, diskIndex, fileInSlot.path);
          }
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan catatan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Catatan' : 'Catatan Baru'),
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Simpan',
            onPressed: _saveNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Judul catatan',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Tulis catatanmu di sini...',
                border: InputBorder.none,
              ),
              maxLines: null,
              minLines: 8,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // ── Area Gambar ──────────────────────────────────────────────
            _buildImageSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final hasAnyImage = _imageSlots.any((f) => f != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Baris horizontal yang dapat digulir untuk menampilkan gambar
        if (hasAnyImage) ...[
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: FileHelper.maxImages,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final file = _imageSlots[i];
                if (file == null) return const SizedBox.shrink();
                return _buildImageTile(file, i);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Tombol tambah gambar — nonaktif jika kuota sudah penuh
        OutlinedButton.icon(
          onPressed: _canAddImage ? _pickImage : null,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text(
            _canAddImage
                ? 'Tambah Gambar ($_imageCount/${FileHelper.maxImages})'
                : 'Kuota Gambar Penuh (${FileHelper.maxImages}/${FileHelper.maxImages})',
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(File file, int slotIndex) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 140,
            height: 160,
            fit: BoxFit.cover,
          ),
        ),
        // Tombol hapus di sudut kanan atas
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeImage(slotIndex),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}