import 'package:flutter/material.dart';
import 'package:ir_sensor_plugin/ir_sensor_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controls',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Controls'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _platformVersion = 'Unknown';
  bool _hasIrEmitter = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    bool hasIrEmitter;

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await IrSensorPlugin.platformVersion;
      hasIrEmitter = await IrSensorPlugin.hasIrEmitter;
    } catch (e) {
      platformVersion = 'Failed to get data';
      hasIrEmitter = false;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _hasIrEmitter = hasIrEmitter;
    });
  }

  Future<void> _sendIrCode(String code) async {
    if (_hasIrEmitter) {
      try {
        await IrSensorPlugin.transmitString(pattern: code);
        setState(() {
          _message = 'Sent IR code: $code';
        });
      } catch (e) {
        setState(() {
          _message = 'Failed to send IR code: $e';
        });
      }
    } else {
      setState(() {
        _message = 'No IR emitter found on this device.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Running on: $_platformVersion\n'),
            Text('Has IR Emitter: $_hasIrEmitter\n'),
            ElevatedButton(
              onPressed: () => _sendIrCode('0xFF00FF'), // Example IR code for Power
              child: const Text('Power'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _sendIrCode('0xFFA25D'), // Example IR code for Volume Up
              child: const Text('Volume Up'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _sendIrCode('0xFF629D'), // Example IR code for Volume Down
              child: const Text('Volume Down'),
            ),
            const SizedBox(height: 20),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
