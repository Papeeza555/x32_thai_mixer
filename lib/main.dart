import 'dart:math';
import 'package:flutter/material.dart';
import 'x32_service.dart';

void main() => runApp(const MaterialApp(home: X32ControlScreen(), debugShowCheckedModeBanner: false));

class X32ControlScreen extends StatefulWidget {
  const X32ControlScreen({super.key});

  @override
  State<X32ControlScreen> createState() => _X32ControlScreenState();
}

class _X32ControlScreenState extends State<X32ControlScreen> {
  final X32Service _x32 = X32Service();
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.100');
  
  bool _isConnected = false;
  double _faderVal = 0.75;
  bool _eqEnabled = true;
  double _eqFreq = 0.5;
  double _eqGain = 0.5;

  int _calculateHz(double val) {
    return (20 * pow(10, 3 * val)).round();
  }

  String _calculateDb(double val) {
    double db = (val - 0.5) * 30.0;
    return '${db >= 0 ? '+' : ''}${db.toStringAsFixed(1)} dB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C20),
      appBar: AppBar(
        title: const Text('คุมมิกซ์ X32 (ช่องที่ 1)', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF25282E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'ไอพีแอดเดรส (IP) ของมิกเซอร์',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.green : Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                  onPressed: () async {
                    await _x32.connect(_ipController.text);
                    setState(() => _isConnected = true);
                  },
                  child: Text(_isConnected ? 'เชื่อมต่อแล้ว' : 'เชื่อมต่อ', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('กราฟอีคิว (EQ ย่านที่ 1)', style: TextStyle(color: Colors.white, fontSize: 18)),
                Switch(
                  value: _eqEnabled,
                  activeColor: Colors.amber,
                  onChanged: (val) {
                    setState(() => _eqEnabled = val);
                    _x32.setEqOn(1, val);
                  },
                ),
              ],
            ),
            Text(
              'ความถี่: ${_calculateHz(_eqFreq)} Hz  |  ความดัง (Gain): ${_calculateDb(_eqGain)}',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onPanUpdate: (details) {
                  RenderBox box = context.findRenderObject() as RenderBox;
                  double newFreq = (_eqFreq + details.delta.dx / box.size.width).clamp(0.0, 1.0);
                  double newGain = (_eqGain - details.delta.dy / 200).clamp(0.0, 1.0);
                  setState(() {
                    _eqFreq = newFreq;
                    _eqGain = newGain;
                  });
                  _x32.setEqParam(1, 1, 'f', _eqFreq);
                  _x32.setEqParam(1, 1, 'g', _eqGain);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121316),
                    border: Border.all(color: Colors.grey.shade800),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: EqCurvePainter(_eqFreq, _eqGain, _eqEnabled),
                    child: Container(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('ระดับเสียงหลัก (Fader): ${(_faderVal * 100).round()}%', style: const TextStyle(color: Colors.white)),
            Slider(
              value: _faderVal,
              activeColor: Colors.cyanAccent,
              onChanged: (val) {
                setState(() => _faderVal = val);
                _x32.setFader(1, val);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EqCurvePainter extends CustomPainter {
  final double freq;
  final double gain;
  final bool isEnabled;

  EqCurvePainter(this.freq, this.gain, this.isEnabled);

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final gridPaint = Paint()..color = Colors.white12..strokeWidth = 1;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), gridPaint);

    final pointX = freq * size.width;
    final pointY = size.height - (gain * size.height);

    final curvePaint = Paint()
      ..color = isEnabled ? Colors.amber : Colors.grey
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(0, centerY);
    for (double x = 0; x <= size.width; x += 2) {
      double dist = (x - pointX) / 40.0;
      double yOffset = (pointY - centerY) * exp(-dist * dist);
      path.lineTo(x, centerY + yOffset);
    }
    canvas.drawPath(path, curvePaint);

    final dotPaint = Paint()..color = isEnabled ? Colors.amberAccent : Colors.grey;
    canvas.drawCircle(Offset(pointX, pointY), 12, dotPaint);
  }

  @override
  bool shouldRepaint(covariant EqCurvePainter oldDelegate) => true;
}
