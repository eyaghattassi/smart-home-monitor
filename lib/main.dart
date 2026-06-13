import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ── change this to your PC's local IP const String serverUrl = 'http://192.168.1.106:3000'; ──

const String serverUrl = 'http://localhost:3000';
// ────────────────────────────────────────

void main() {
  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4AA),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double temperature = 0;
  double humidity    = 0;
  bool   relayOn     = false;
  String status      = 'loading...';
  String lastTime    = '--';
  bool   isLoading   = true;
  String errorMsg    = '';

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchData();
    // fetch every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final res = await http
          .get(Uri.parse('$serverUrl/api/sensor'))
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          temperature = (d['temperature'] as num?)?.toDouble() ?? 0.0;
          humidity    = (d['humidity'] as num?)?.toDouble() ?? 0.0;
          relayOn     = d['relay'] as bool? ?? false;
          status      = d['status']?.toString() ?? 'unknown';
          lastTime    = d['time']?.toString() ?? '--';
          isLoading   = false;
          errorMsg    = '';
        });
      } else {
        setState(() {
          errorMsg  = 'Server error: ${res.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMsg  = 'Cannot connect to server.\nCheck IP and make sure server is running.';
        isLoading = false;
      });
    }
  }

  Future<void> toggleRelay() async {
    final newState = relayOn ? 'OFF' : 'ON';
    try {
      await http.post(
        Uri.parse('$serverUrl/api/relay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'state': newState}),
      );
      if (!mounted) return;
      setState(() => relayOn = !relayOn);
    } catch (e) {
      debugPrint('Relay toggle failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (errorMsg.isNotEmpty) _buildError(),
            if (isLoading && errorMsg.isEmpty) _buildLoading(),
            if (!isLoading && errorMsg.isEmpty) ...[
              const SizedBox(height: 20),
              _buildSensorCards(),
              const SizedBox(height: 20),
              _buildRelayCard(),
              const SizedBox(height: 20),
              _buildStatusBar(),
            ],
          ],
        ),
      ),
    );
  }

  // ── header ───────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A4A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '🏠 Smart Home Monitor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500,
                color: Color(0xFF00D4AA)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A2E),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Text(
              '● $status',
              style: const TextStyle(fontSize: 12, color: Color(0xFF00D4AA)),
            ),
          ),
        ],
      ),
    );
  }

  // ── sensor cards ─────────────────────
  Widget _buildSensorCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _sensorCard('TEMPERATURE',
              '${temperature.toStringAsFixed(1)}°C', const Color(0xFFFF6B6B))),
          const SizedBox(width: 12),
          Expanded(child: _sensorCard('HUMIDITY',
              '${humidity.toStringAsFixed(1)}%', const Color(0xFF00D4AA))),
        ],
      ),
    );
  }

  Widget _sensorCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w300,
                  color: color)),
        ],
      ),
    );
  }

  // ── relay card ───────────────────────
  Widget _buildRelayCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Column(
          children: [
            const Text('RELAY / DEVICE',
                style: TextStyle(fontSize: 11, color: Colors.grey,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Text(
              relayOn ? 'ON' : 'OFF',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: relayOn ? const Color(0xFF00D4AA) : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: toggleRelay,
              style: ElevatedButton.styleFrom(
                backgroundColor: relayOn
                    ? const Color(0xFF00D4AA)
                    : const Color(0xFF2A2A4A),
                foregroundColor: relayOn
                    ? const Color(0xFF0F0F1A)
                    : Colors.grey,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(
                relayOn ? 'Turn OFF' : 'Turn ON',
                style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── status bar ───────────────────────
  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Text(
          'Last update: $lastTime',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ── loading / error ──────────────────
  Widget _buildLoading() {
    return const Expanded(
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
      ),
    );
  }

  Widget _buildError() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text(errorMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchData,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA)),
                child: const Text('Retry',
                    style: TextStyle(color: Color(0xFF0F0F1A))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}