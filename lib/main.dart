import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _previousNumber = '';
  String _operation = '';
  bool _waitingForOperand = false;
  bool _justCalculated = false;
  
  void _inputNumber(String number) {
    setState(() {
      if (_waitingForOperand || _justCalculated) {
        _display = number;
        _waitingForOperand = false;
        _justCalculated = false;
      } else {
        _display = _display == '0' ? number : _display + number;
      }
    });
  }
  
  void _inputOperation(String nextOperation) {
    setState(() {
      if (_previousNumber.isEmpty) {
        _previousNumber = _display;
      } else if (!_waitingForOperand) {
        _calculate();
      }
      
      _waitingForOperand = true;
      _operation = nextOperation;
      _justCalculated = false;
    });
  }
  
  // NEW: Square function for immediate calculation
  void _square() {
    setState(() {
      double current = double.tryParse(_display) ?? 0;
      double result = current * current;
      
      if (result == result.toInt()) {
        _display = result.toInt().toString();
      } else {
        _display = result.toStringAsFixed(8).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      
      _previousNumber = '';
      _operation = '';
      _waitingForOperand = true;
      _justCalculated = true;
    });
  }
  
  void _calculate() {
    if (_previousNumber.isEmpty || _operation.isEmpty) return;
    
    double prev = double.tryParse(_previousNumber) ?? 0;
    double current = double.tryParse(_display) ?? 0;
    double result = 0;
    
    switch (_operation) {
      case '+':
        result = prev + current;
        break;
      case '-':
        result = prev - current;
        break;
      case '×':
        result = prev * current;
        break;
      case '÷':
        if (current != 0) {
          result = prev / current;
        } else {
          setState(() {
            _display = 'Error';
            _previousNumber = '';
            _operation = '';
            _waitingForOperand = false;
            _justCalculated = false;
          });
          return;
        }
        break;
      case '%':
        result = prev % current;
        break;
    }
    
    setState(() {
      if (result == result.toInt()) {
        _display = result.toInt().toString();
      } else {
        _display = result.toStringAsFixed(8).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    });
  }
  
  void _equals() {
    setState(() {
      if (_previousNumber.isNotEmpty && _operation.isNotEmpty && !_waitingForOperand) {
        _calculate();
        _previousNumber = '';
        _operation = '';
        _waitingForOperand = true;
        _justCalculated = true;
      }
    });
  }
  
  void _clear() {
    setState(() {
      _display = '0';
      _previousNumber = '';
      _operation = '';
      _waitingForOperand = false;
      _justCalculated = false;
    });
  }
  
  void _backspace() {
    setState(() {
      if (_display.length > 1 && _display != 'Error') {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }
  
  void _inputDecimal() {
    setState(() {
      if (_waitingForOperand || _justCalculated) {
        _display = '0.';
        _waitingForOperand = false;
        _justCalculated = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }
  
  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    Color backgroundColor = Colors.white,
    Color textColor = const Color(0xFF2E2E2E),
    double fontSize = 18,
  }) {
    return Container(
      margin: const EdgeInsets.all(1),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(8),
          elevation: 2,
          minimumSize: const Size(40, 40),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  String _getDisplayExpression() {
    if (_previousNumber.isNotEmpty && _operation.isNotEmpty && !_justCalculated) {
      return '$_previousNumber $_operation ${_waitingForOperand ? '' : _display}';
    }
    return '';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9539EF),
        title: const Text(
          'Calculator',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        elevation: 2,
      ),
      body: Center(
        child: Container(
          width: 350,
          height: 600,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 150,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_getDisplayExpression().isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            _getDisplayExpression(),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          _display.isEmpty ? '0' : _display,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.count(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                    children: [
                      _buildButton(
                        text: 'C',
                        onPressed: _clear,
                        backgroundColor: const Color(0xFFDBDBDB),
                      ),
                      _buildButton(
                        text: 'x²',
                        onPressed: _square,
                        backgroundColor: const Color(0xFFDBDBDB),
                        fontSize: 16,
                      ),
                      _buildButton(
                        text: '⌫',
                        onPressed: _backspace,
                        backgroundColor: const Color(0xFFDBDBDB),
                        fontSize: 16,
                      ),
                      _buildButton(
                        text: '÷',
                        onPressed: () => _inputOperation('÷'),
                        backgroundColor: const Color(0xFFDBDBDB),
                      ),
                      _buildButton(
                        text: '7',
                        onPressed: () => _inputNumber('7'),
                      ),
                      _buildButton(
                        text: '8',
                        onPressed: () => _inputNumber('8'),
                      ),
                      _buildButton(
                        text: '9',
                        onPressed: () => _inputNumber('9'),
                      ),
                      _buildButton(
                        text: '×',
                        onPressed: () => _inputOperation('×'),
                        backgroundColor: const Color(0xFFDBDBDB),
                      ),
                      _buildButton(
                        text: '4',
                        onPressed: () => _inputNumber('4'),
                      ),
                      _buildButton(
                        text: '5',
                        onPressed: () => _inputNumber('5'),
                      ),
                      _buildButton(
                        text: '6',
                        onPressed: () => _inputNumber('6'),
                      ),
                      _buildButton(
                        text: '-',
                        onPressed: () => _inputOperation('-'),
                        backgroundColor: const Color(0xFFDBDBDB),
                      ),
                      _buildButton(
                        text: '1',
                        onPressed: () => _inputNumber('1'),
                      ),
                      _buildButton(
                        text: '2',
                        onPressed: () => _inputNumber('2'),
                      ),
                      _buildButton(
                        text: '3',
                        onPressed: () => _inputNumber('3'),
                      ),
                      _buildButton(
                        text: '+',
                        onPressed: () => _inputOperation('+'),
                        backgroundColor: const Color(0xFFDBDBDB),
                      ),
                      _buildButton(
                        text: '%',
                        onPressed: () => _inputOperation('%'),
                        backgroundColor: const Color(0xFFDBDBDB),
                      ),
                      _buildButton(
                        text: '0',
                        onPressed: () => _inputNumber('0'),
                      ),
                      _buildButton(
                        text: '.',
                        onPressed: _inputDecimal,
                      ),
                      _buildButton(
                        text: '=',
                        onPressed: _equals,
                        backgroundColor: const Color(0xFF07FF00),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}