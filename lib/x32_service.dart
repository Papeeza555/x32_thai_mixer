import 'dart:async';
import 'dart:io';
import 'osc_builder.dart';

class X32Service {
  RawDatagramSocket? _socket;
  InternetAddress? _mixerIp;
  final int _port = 10023;
  Timer? _keepAliveTimer;

  Future<void> connect(String ipAddress) async {
    _mixerIp = InternetAddress(ipAddress);
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    _socket?.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket?.receive();
        if (datagram != null) {
          print('รับข้อมูลจาก X32 จำนวน ${datagram.data.length} bytes');
        }
      }
    });

    _sendKeepAlive();
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendKeepAlive();
    });
  }

  void _sendKeepAlive() {
    if (_socket != null && _mixerIp != null) {
      final packet = OscBuilder.buildCommandPacket('/xremote');
      _socket!.send(packet, _mixerIp!, _port);
    }
  }

  void setFader(int channel, double value) {
    final ch = channel.toString().padLeft(2, '0');
    final packet = OscBuilder.buildFloatPacket('/ch/$ch/mix/fader', value);
    _socket?.send(packet, _mixerIp!, _port);
  }

  void setEqOn(int channel, bool isOn) {
    final ch = channel.toString().padLeft(2, '0');
    final packet = OscBuilder.buildIntPacket('/ch/$ch/eq/on', isOn ? 1 : 0);
    _socket?.send(packet, _mixerIp!, _port);
  }

  void setEqParam(int channel, int band, String param, double value) {
    final ch = channel.toString().padLeft(2, '0');
    final packet = OscBuilder.buildFloatPacket('/ch/$ch/eq/$band/$param', value);
    _socket?.send(packet, _mixerIp!, _port);
  }

  void dispose() {
    _keepAliveTimer?.cancel();
    _socket?.close();
  }
}
