class FormatRange {
  final int start;
  final int end;
  final bool bold;
  final bool italic;
  final int? headingLevel;

  const FormatRange({
    required this.start,
    required this.end,
    this.bold = false,
    this.italic = false,
    this.headingLevel,
  });
}
