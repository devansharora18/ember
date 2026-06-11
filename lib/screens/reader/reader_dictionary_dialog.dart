import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/dictionary_service.dart';

class DictionaryDialog extends StatefulWidget {
  final String word;

  const DictionaryDialog({super.key, required this.word});

  @override
  State<DictionaryDialog> createState() => _DictionaryDialogState();
}

class _DictionaryDialogState extends State<DictionaryDialog> {
  String? _definition;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    final def = await DictionaryService.lookup(widget.word);
    if (mounted) setState(() { _definition = def; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.word, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (_loading)
              const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF333333)))))
            else if (_definition != null)
              Text(_definition!, style: GoogleFonts.inter(color: const Color(0xFFBBBBBB), fontSize: 14, height: 1.5))
            else
              Text('No definition found.', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 14)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
