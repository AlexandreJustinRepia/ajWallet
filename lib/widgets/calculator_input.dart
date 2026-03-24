import 'package:flutter/material.dart';

class CalculatorInputField extends StatefulWidget {
  final String label;
  final String prefix;
  final double? initialValue;
  final ValueChanged<double> onChanged;
  final FormFieldValidator<String>? validator;

  const CalculatorInputField({
    super.key,
    required this.label,
    this.prefix = '₱',
    this.initialValue,
    required this.onChanged,
    this.validator,
  });

  @override
  State<CalculatorInputField> createState() => _CalculatorInputFieldState();
}

class _CalculatorInputFieldState extends State<CalculatorInputField> {
  late TextEditingController _controller;
  String _currentExpression = '0';

  @override
  void initState() {
    super.initState();
    _currentExpression = widget.initialValue?.toStringAsFixed(2) ?? '0';
    if (_currentExpression.endsWith('.00')) {
      _currentExpression = _currentExpression.substring(
        0,
        _currentExpression.length - 3,
      );
    }
    _controller = TextEditingController(text: _currentExpression);
  }

  void _showCalculator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CalculatorKeyboard(
        initialValue: _currentExpression,
        onChanged: (val) {
          final result = _evaluate(val);
          setState(() {
            _currentExpression = val;
            _controller.text = result.toStringAsFixed(2);
            if (_controller.text.endsWith('.00')) {
              _controller.text = _controller.text.substring(
                0,
                _controller.text.length - 3,
              );
            }
          });
          widget.onChanged(result);
        },
      ),
    );
  }

  double _evaluate(String expression) {
    try {
      final tokens = RegExp(
        r'([0-9.]+)|([+\-*/])',
      ).allMatches(expression).map((m) => m.group(0)!).toList();
      if (tokens.isEmpty) return 0.0;

      double res = double.tryParse(tokens[0]) ?? 0;
      for (int i = 1; i < tokens.length; i += 2) {
        if (i + 1 >= tokens.length) break;
        final op = tokens[i];
        final val = double.tryParse(tokens[i + 1]) ?? 0;

        switch (op) {
          case '+':
            res += val;
            break;
          case '-':
            res -= val;
            break;
          case '*':
            res *= val;
            break;
          case '/':
            res = val != 0 ? res / val : 0;
            break;
        }
      }
      return res;
    } catch (_) {
      return double.tryParse(expression) ?? 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showCalculator,
          borderRadius: BorderRadius.circular(12),
          child: IgnorePointer(
            child: TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                prefixText: '${widget.prefix} ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.dividerColor, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.dividerColor, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calculate_outlined,
                              size: 16,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Calc',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              validator: widget.validator,
              readOnly: true,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class CalculatorKeyboard extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const CalculatorKeyboard({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<CalculatorKeyboard> createState() => _CalculatorKeyboardState();
}

class _CalculatorKeyboardState extends State<CalculatorKeyboard> {
  late String _buffer;

  bool _hasOperator = false;

  @override
  void initState() {
    super.initState();
    _buffer = widget.initialValue == '0' ? '0' : widget.initialValue;
    _hasOperator = _buffer.contains(RegExp(r'[+\-*/]'));
  }

  void _onPress(String char) {
    setState(() {
      if (char == 'AC') {
        _buffer = '0';
        _hasOperator = false;
      } else if (char == '⌫') {
        if (_buffer.length > 1) {
          _buffer = _buffer.substring(0, _buffer.length - 1);
          _hasOperator = _buffer.contains(RegExp(r'[+\-*/]'));
        } else {
          _buffer = '0';
          _hasOperator = false;
        }
      } else if (char == '=') {
        _buffer = _calculateResult(_buffer);
        _hasOperator = false;
      } else if (RegExp(r'[+\-*/]').hasMatch(char)) {
        if (_buffer == '0' || _buffer == '0.0' || _buffer == '0.00') return;
        // If already has an operator at reaching end, replace it
        if (RegExp(r'[+\-*/]$').hasMatch(_buffer)) {
          _buffer = _buffer.substring(0, _buffer.length - 1) + char;
        } else {
          // If already has an operator middle, evaluate first
          if (_hasOperator) {
            _buffer = _calculateResult(_buffer);
          }
          _buffer += char;
          _hasOperator = true;
        }
      } else {
        // Number or Dot
        final isZero = _buffer == '0' || _buffer == '0.0' || _buffer == '0.00';
        if (isZero && char != '.') {
          _buffer = char;
        } else {
          _buffer += char;
        }
      }
    });
    // If it's just a number, notify parent
    if (!_hasOperator && !RegExp(r'[+\-*/]$').hasMatch(_buffer)) {
      widget.onChanged(_buffer);
    }
  }

  String _calculateResult(String expression) {
    try {
      // Very basic iterative evaluator
      // 1. Separate tokens
      final tokens = RegExp(
        r'([0-9.]+)|([+\-*/])',
      ).allMatches(expression).map((m) => m.group(0)!).toList();
      if (tokens.isEmpty) return expression;

      double res = double.tryParse(tokens[0]) ?? 0;
      for (int i = 1; i < tokens.length; i += 2) {
        if (i + 1 >= tokens.length) break;
        final op = tokens[i];
        final val = double.tryParse(tokens[i + 1]) ?? 0;

        switch (op) {
          case '+':
            res += val;
            break;
          case '-':
            res -= val;
            break;
          case '*':
            res *= val;
            break;
          case '/':
            res = val != 0 ? res / val : 0;
            break;
        }
      }

      String s = res.toStringAsFixed(2);
      if (s.endsWith('.00')) s = s.substring(0, s.length - 3);
      return s;
    } catch (_) {
      return expression;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _buffer,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                      fontSize: _buffer.length > 10 ? 28 : 36,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final btnWidth = (constraints.maxWidth - 36) / 4;
              return Column(
                children: [
                  _buildRow(['AC', '⌫', '/', '*'], btnWidth),
                  _buildRow(['7', '8', '9', '-'], btnWidth),
                  _buildRow(['4', '5', '6', '+'], btnWidth),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildRow(['1', '2', '3'], btnWidth),
                            _buildRow(
                              ['0', '.', '='],
                              btnWidth,
                              showThird: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: btnWidth,
                        height: 132,
                        child: ElevatedButton(
                          onPressed: () {
                            // Final evaluation before done
                            final res = _calculateResult(_buffer);
                            widget.onChanged(res);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 4,
                            shadowColor: theme.primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 32),
                              SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys, double width, {bool showThird = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: keys.map((key) {
          final isNumber = RegExp(r'[0-9.]').hasMatch(key);
          final isOperator = RegExp(r'[+\-*/=]').hasMatch(key);
          final isAC = key == 'AC' || key == '⌫';

          return SizedBox(
            width: width,
            height: 60,
            child: ElevatedButton(
              onPressed: () => _onPress(key),
              style: ElevatedButton.styleFrom(
                backgroundColor: isNumber
                    ? theme.cardColor
                    : (isAC
                          ? Colors.orange.withOpacity(0.1)
                          : theme.primaryColor.withOpacity(0.1)),
                foregroundColor: isNumber
                    ? theme.textTheme.bodyLarge?.color ??
                          (theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87)
                    : (isAC ? Colors.orange : theme.primaryColor),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isNumber
                      ? BorderSide(color: theme.dividerColor, width: 0.5)
                      : BorderSide.none,
                ),
              ),
              child: Text(
                key,
                style: TextStyle(
                  fontSize: isOperator ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
