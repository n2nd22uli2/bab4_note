class Note {
  final String id;
  final String title;
  final String content;
  final bool hasImage;
  final String lastModified;
  final int imageCount; // Jumlah lampiran gambar (0–3)

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.hasImage = false,
    this.lastModified = '',
    this.imageCount = 0,
  });
}