import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const LiquidGlassCalculatorApp());
}

class LiquidGlassCalculatorApp extends StatelessWidget {
  const LiquidGlassCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090A10),
        fontFamily: 'Roboto',
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _displayResult = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  void _onButtonPressed(String label) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (label) {
        case 'AC':
          _clearAll();
          break;
        case '⌫':
          _deleteLast();
          break;
        case '±':
          _toggleSign();
          break;
        case '%':
          _applyPercentage();
          break;
        case '÷':
        case '×':
        case '−':
        case '+':
          _setOperator(label);
          break;
        case '=':
          _calculateResult();
          break;
        case '.':
          _inputDecimal();
          break;
        default:
          _inputDigit(label);
      }
    });
  }

  void _clearAll() {
    _expression = '';
    _displayResult = '0';
    _firstOperand = null;
    _operator = null;
    _shouldResetDisplay = false;
  }

  void _deleteLast() {
    if (_shouldResetDisplay) return;
    if (_displayResult.length > 1) {
      _displayResult = _displayResult.substring(0, _displayResult.length - 1);
    } else {
      _displayResult = '0';
    }
  }

  void _toggleSign() {
    if (_displayResult == '0' || _displayResult == 'Error') return;
    if (_displayResult.startsWith('-')) {
      _displayResult = _displayResult.substring(1);
    } else {
      _displayResult = '-$_displayResult';
    }
  }

  void _applyPercentage() {
    final value = double.tryParse(_displayResult);
    if (value != null) {
      final res = value / 100.0;
      _displayResult = _formatNumber(res);
    }
  }

  void _setOperator(String op) {
    final currentValue = double.tryParse(_displayResult);
    if (currentValue == null) return;

    if (_firstOperand != null && _operator != null && !_shouldResetDisplay) {
      _calculateResult();
      _firstOperand = double.tryParse(_displayResult);
    } else {
      _firstOperand = currentValue;
    }

    _operator = op;
    _expression = '${_formatNumber(_firstOperand!)} $op';
    _shouldResetDisplay = true;
  }

  void _calculateResult() {
    if (_firstOperand == null || _operator == null) return;
    final secondOperand = double.tryParse(_displayResult);
    if (secondOperand == null) return;

    double result = 0;
    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '−':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
        if (secondOperand == 0) {
          _displayResult = 'Error';
          _expression = '';
          _firstOperand = null;
          _operator = null;
          _shouldResetDisplay = true;
          return;
        }
        result = _firstOperand! / secondOperand;
        break;
    }

    _expression = '${_formatNumber(_firstOperand!)} $_operator ${_formatNumber(secondOperand)} =';
    _displayResult = _formatNumber(result);
    _firstOperand = null;
    _operator = null;
    _shouldResetDisplay = true;
  }

  void _inputDigit(String digit) {
    if (_shouldResetDisplay || _displayResult == '0' || _displayResult == 'Error') {
      _displayResult = digit;
      _shouldResetDisplay = false;
    } else {
      if (_displayResult.length < 12) {
        _displayResult += digit;
      }
    }
  }

  void _inputDecimal() {
    if (_shouldResetDisplay || _displayResult == 'Error') {
      _displayResult = '0.';
      _shouldResetDisplay = false;
      return;
    }
    if (!_displayResult.contains('.')) {
      _displayResult += '.';
    }
  }

  String _formatNumber(double number) {
    if (number.isNaN || number.isInfinite) return 'Error';
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    String str = number.toStringAsFixed(6);
    str = str.replaceAll(RegExp(r'0+$'), '');
    str = str.replaceAll(RegExp(r'\.$'), '');
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color(0xFF090A10),
          ),
          Positioned(
            top: -60,
            left: -40,
            child: _buildGlowSphere(
              color: const Color(0xFF4A00E0).withOpacity(0.55),
              size: size.width * 0.9,
            ),
          ),
          Positioned(
            top: size.height * 0.28,
            right: -80,
            child: _buildGlowSphere(
              color: const Color(0xFF00D2FF).withOpacity(0.45),
              size: size.width * 0.85,
            ),
          ),
          Positioned(
            bottom: -50,
            left: size.width * 0.1,
            child: _buildGlowSphere(
              color: const Color(0xFFFF2A85).withOpacity(0.35),
              size: size.width * 0.8,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildDisplayPanel(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildKeypadGrid(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowSphere({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Liquid Glass',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        LiquidGlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: const [
              Icon(Icons.opacity, color: Colors.cyanAccent, size: 14),
              SizedBox(width: 6),
              Text(
                'v1.0',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayPanel() {
    return LiquidGlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 24,
            alignment: Alignment.centerRight,
            child: Text(
              _expression,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 18,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            alignment: Alignment.centerRight,
            fit: BoxFit.scaleDown,
            child: Text(
              _displayResult,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 54,
                fontWeight: FontWeight.w300,
                letterSpacing: -1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadGrid() {
    final List<List<KeypadButtonConfig>> layout = [
      [
        KeypadButtonConfig(label: 'AC', type: ButtonGlassType.warning),
        KeypadButtonConfig(label: '±', type: ButtonGlassType.action),
        KeypadButtonConfig(label: '%', type: ButtonGlassType.action),
        KeypadButtonConfig(label: '÷', type: ButtonGlassType.operatorKey),
      ],
      [
        KeypadButtonConfig(label: '7', type: ButtonGlassType.digit),
        KeypadButtonConfig(label: '8', type: ButtonGlassType.digit),
        KeypadButtonConfig(label: '9', type: ButtonGlassType.digit),
        KeypadButtonConfig(label: '×', type: ButtonGlassType.operatorKey),
      ],
      [
        KeypadButtonConfig(label: '4', type: ButtonGlassType.digit),
        KeypadButtonConfig(label: '5', type: ButtonGlassType.digit),
        KeypadButtonConfig(label: '6', type: ButtonGlassType.digit),
        KeypadButtonConfig(label: '−', type: ButtonGlassType.operatorKey),
      ],
      [
        KeypadButtonConfig(label: '1', type: ButtonGlassType.digit),
        KeypadButtonConfig(label: '2', type: ButtonGlassType.digit),
        KeypadButtonConfig(label: '3', type: ButtonGlassType.digit),
        KeypadButtonConfig(label: '+', type: ButtonGlassType.operatorKey),
      ],
      [
        KeypadButtonConfig(label: '0', type: ButtonGlassType.digit, flex: 2),
        KeypadButtonConfig(label: '.', type: ButtonGlassType.digit),
        KeypadButtonConfig(label: '=', type: ButtonGlassType.equalKey),
      ],
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: layout.map((row) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              children: row.map((btn) {
                return Expanded(
                  flex: btn.flex,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: GlassButton(
                      label: btn.label,
                      type: btn.type,
                      onTap: () => _onButtonPressed(btn.label),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }
}

enum ButtonGlassType { digit, action, operatorKey, equalKey, warning }

class KeypadButtonConfig {
  final String label;
  final ButtonGlassType type;
  final int flex;

  KeypadButtonConfig({
    required this.label,
    required this.type,
    this.flex = 1,
  });
}

class GlassButton extends StatefulWidget {
  final String label;
  final ButtonGlassType type;
  final VoidCallback onTap;

  const GlassButton({
    super.key,
    required this.label,
    required this.type,
    required this.onTap,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color textColor = Colors.white;
    Color topGlowColor = Colors.white.withOpacity(0.25);
    Color fillColor = Colors.white.withOpacity(0.06);
    List<BoxShadow> shadows = [];

    switch (widget.type) {
      case ButtonGlassType.digit:
        textColor = Colors.white.withOpacity(0.92);
        fillColor = Colors.white.withOpacity(0.07);
        topGlowColor = Colors.white.withOpacity(0.30);
        break;
      case ButtonGlassType.action:
        textColor = const Color(0xFF64D2FF);
        fillColor = const Color(0xFF007AFF).withOpacity(0.12);
        topGlowColor = const Color(0xFF64D2FF).withOpacity(0.4);
        break;
      case ButtonGlassType.operatorKey:
        textColor = const Color(0xFF70E1FF);
        fillColor = const Color(0xFF00C6FF).withOpacity(0.18);
        topGlowColor = const Color(0xFF00E5FF).withOpacity(0.5);
        shadows = [
          BoxShadow(
            color: const Color(0xFF00B4D8).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case ButtonGlassType.equalKey:
        textColor = Colors.white;
        fillColor = const Color(0xFFFF2A85).withOpacity(0.32);
        topGlowColor = const Color(0xFFFF80BF).withOpacity(0.7);
        shadows = [
          BoxShadow(
            color: const Color(0xFFFF2A85).withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ];
        break;
      case ButtonGlassType.warning:
        textColor = const Color(0xFFFF7B7B);
        fillColor = const Color(0xFFFF3B30).withOpacity(0.15);
        topGlowColor = const Color(0xFFFF7B7B).withOpacity(0.45);
        break;
    }

    if (_isPressed) {
      fillColor = fillColor.withOpacity(0.4);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutQuad,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: fillColor,
                  border: Border.all(
                    color: _isPressed ? topGlowColor : topGlowColor.withOpacity(0.3),
                    width: 1.2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      topGlowColor.withOpacity(_isPressed ? 0.45 : 0.22),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.18),
                Colors.white.withOpacity(0.03),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
