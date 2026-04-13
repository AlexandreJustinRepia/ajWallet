import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onCompleted;
  final int length;
  final bool enabled;

  const PinInputWidget({
    super.key,
    required this.controller,
    this.onCompleted,
    this.length = 4,
    this.enabled = true,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        // Hidden TextField to capture input
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 0,
            width: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              autofocus: true,
              enabled: widget.enabled,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                setState(() {}); // Redraw bars
                if (value.length == widget.length && widget.onCompleted != null) {
                  widget.onCompleted!(value);
                }
              },
              decoration: const InputDecoration(counterText: ""),
            ),
          ),
        ),
        
        // Visual Boxes
        GestureDetector(
          onTap: () {
            if (widget.enabled) {
              _focusNode.requestFocus();
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (index) {
              final val = widget.controller.text;
              final isFocused = _focusNode.hasFocus && val.length == index;
              final hasValue = val.length > index;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 56,
                height: 64,
                decoration: BoxDecoration(
                  color: isFocused 
                      ? theme.primaryColor.withValues(alpha: 0.05) 
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isFocused 
                        ? theme.primaryColor 
                        : theme.dividerColor,
                    width: isFocused ? 2 : 1,
                  ),
                  boxShadow: isFocused ? [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ] : [],
                ),
                child: Center(
                  child: hasValue
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface,
                            shape: BoxShape.circle,
                          ),
                        )
                      : Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
