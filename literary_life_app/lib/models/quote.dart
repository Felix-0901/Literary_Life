class Quote {
  final int id;
  final String content;
  final String author;
  final String source;
  final String category;

  Quote({
    required this.id,
    required this.content,
    required this.author,
    this.source = '',
    this.category = '',
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'],
      content: json['content'],
      author: json['author'] ?? '佚名',
      source: json['source'] ?? '',
      category: json['category'] ?? '',
    );
  }
}
