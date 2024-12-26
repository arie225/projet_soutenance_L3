import 'package:flutter/material.dart';

class LargeTextArea extends StatefulWidget {
  final String hint;
  final int maxLines;
  final Function(String)? onChanged;

  const LargeTextArea({
    Key? key,
    this.hint = 'Entrez votre texte ici',
    this.maxLines = 1000,
    this.onChanged,
  }) : super(key: key);

  @override
  _LargeTextAreaState createState() => _LargeTextAreaState();
}

class _LargeTextAreaState extends State<LargeTextArea> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500.0,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controller,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          hintText: widget.hint,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
        style: TextStyle(fontSize: 16),
        onChanged: widget.onChanged,
      ),
    );
  }
}