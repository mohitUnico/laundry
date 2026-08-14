import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_colors.dart';

class OtpInputRow extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const OtpInputRow({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
  });

  @override
  State<OtpInputRow> createState() => OtpInputRowState();
}

class OtpInputRowState extends State<OtpInputRow> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;
  String _lastCompletedValue = '';

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  void focusFirst() {
    if (_nodes.isNotEmpty) {
      _nodes[0].requestFocus();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final value = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(value);

    final isComplete = _controllers.every((c) => c.text.length == 1);
    if (isComplete &&
        value.length == widget.length &&
        value != _lastCompletedValue) {
      _lastCompletedValue = value;
      widget.onCompleted?.call(value);
    }
  }

  void _applyPaste({required int startIndex, required String text}) {
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return;

    var index = startIndex;
    for (final ch in digitsOnly.split('')) {
      if (index >= widget.length) break;
      _controllers[index].text = ch;
      index++;
    }

    if (index >= widget.length) {
      FocusScope.of(context).unfocus();
    } else {
      _nodes[index].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: 44,
          height: 52,
          child: TextField(
            controller: _controllers[i],
            focusNode: _nodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AuthColors.border, width: 1.6),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AuthColors.border, width: 1.6),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AuthColors.border, width: 2.0),
              ),
            ),
            onChanged: (v) {
              if (v.length > 1) {
                _applyPaste(startIndex: i, text: v);
                _emit();
                return;
              }

              if (v.isNotEmpty && i < widget.length - 1) {
                _nodes[i + 1].requestFocus();
              }
              if (v.isEmpty && i > 0) {
                _nodes[i - 1].requestFocus();
              }
              _emit();
            },
          ),
        );
      }),
    );
  }
}


