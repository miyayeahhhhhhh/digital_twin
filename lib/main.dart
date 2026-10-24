import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:model_viewer_plus/model_viewer_plus.dart';

void main() => runApp(const HeartTwinApp());

const ink = Color(0xFF080B18);
const panel = Color(0xFF11172B);
const cyan = Color(0xFF56F0E0);
const pink = Color(0xFFFF5DA2);
const violet = Color(0xFF9A82FF);
const muted = Color(0xFF8D9AB8);

// ============================================================
// APP
// ============================================================

class HeartTwinApp extends StatelessWidget {
  const HeartTwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HEART//TWIN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(
          primary: cyan,
          secondary: pink,
        ),
        textTheme: GoogleFonts.manropeTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ============================================================
// ECG API
// ============================================================

class EcgApi {
  // Android emulator accesses the laptop through this address.
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<Map<String, dynamic>> fetchEcg() async {
    final uri = Uri.parse(
      '$baseUrl/api/ecg?start=0&count=500&lead=MLII',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('API returned ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(
    text: 'doctor@hearttwin.ai',
  );

  final password = TextEditingController(
    text: 'demo1234',
  );

  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-.8, -.8),
            radius: 1.3,
            colors: [
              Color(0xFF25204A),
              ink,
              ink,
            ],
            stops: [0, .48, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.monitor_heart_rounded,
                          color: cyan,
                          size: 38,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'HEART',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '//TWIN',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: cyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    const Tag(
                      text: 'CARDIOVASCULAR DIGITAL TWIN',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'See risk\nbefore it\nbecomes real.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 45,
                        height: 1.04,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'A cardiovascular research prototype '
                      'connecting ECG signals with a patient-focused '
                      'digital view.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: panel,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WELCOME BACK',
                            style: TextStyle(
                              color: muted,
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sign in to your workspace',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _LoginField(
                            label: 'EMAIL ADDRESS',
                            controller: email,
                            icon: Icons.alternate_email,
                          ),
                          const SizedBox(height: 16),
                          _LoginField(
                            label: 'PASSWORD',
                            controller: password,
                            icon: Icons.lock_outline,
                            obscure: obscure,
                            suffix: IconButton(
                              onPressed: () {
                                setState(() => obscure = !obscure);
                              },
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: cyan,
                                foregroundColor: ink,
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DashboardScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'ENTER THE TWIN  →',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Center(
                            child: Text(
                              'DEMO MODE · SYNTHETIC PATIENT PROFILE',
                              style: TextStyle(
                                color: muted,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Research prototype · Not for clinical decisions',
                        style: TextStyle(
                          color: muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;

  const Tag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: cyan.withOpacity(.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cyan.withOpacity(.25)),
      ),
      child: Text(
        '●  $text',
        style: const TextStyle(
          color: cyan,
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;

  const _LoginField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: muted,
            fontSize: 9,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: muted),
            suffixIcon: suffix,
            filled: true,
            fillColor: ink,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool loading = true;
  bool showModel = false;

  String? error;
  List<FlSpot> spots = [];
  List<Map<String, dynamic>> annotations = [];

  int selected = 0;

  Future<void> loadEcg() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await EcgApi.fetchEcg();

      final values = (result['values'] as List)
          .map((value) => (value as num).toDouble())
          .toList();

      final rawAnnotations = result['annotations'] as List? ?? [];

      if (!mounted) return;

      setState(() {
        spots = List.generate(
          values.length,
          (index) => FlSpot(
            index.toDouble(),
            values[index],
          ),
        );

        annotations = rawAnnotations
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();

        loading = false;

        if (values.isEmpty) {
          error = 'The API returned no ECG samples.';
        }
      });
    } catch (exception) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Cannot connect to ECG API. Check that the Python backend '
            'is running on port 8000.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadEcg();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 760;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ink,
        title: Text(
          'HEART//TWIN',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        actions: [
          const Icon(
            Icons.circle,
            size: 8,
            color: cyan,
          ),
          const SizedBox(width: 7),
          const Center(
            child: Text(
              'DEMO',
              style: TextStyle(
                color: muted,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 18),
        ],
      ),
      body: selected == 0 ? dashboard(wide) : secondaryPage(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        indicatorColor: cyan.withOpacity(.15),
        selectedIndex: selected,
        onDestinationSelected: (index) {
          setState(() => selected = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Twin',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_rounded),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Cases',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget dashboard(bool wide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PATIENT SPACE / 001',
            style: TextStyle(
              color: muted,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your patient,\nin a new dimension.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          patientCard(),
          const SizedBox(height: 16),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: heartCard()),
                const SizedBox(width: 14),
                Expanded(child: metricsCard()),
              ],
            )
          else
            Column(
              children: [
                heartCard(),
                const SizedBox(height: 14),
                metricsCard(),
              ],
            ),
          const SizedBox(height: 16),
          ecgCard(),
          const SizedBox(height: 16),
          fusionCard(),
          const SizedBox(height: 22),
          const Center(
            child: Text(
              'RESEARCH PROTOTYPE · NOT FOR CLINICAL DECISIONS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: muted,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget patientCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0x339A82FF),
            child: Icon(
              Icons.person,
              color: violet,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PATIENT 001 · SYNTHETIC PROFILE',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Aarav Mehta',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '42 years · Demo profile',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget heartCard() {
    return Container(
      height: 330,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF191C3A),
            Color(0xFF101629),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: violet.withOpacity(.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DIGITAL HEART VIEW',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Illustrative cardiac representation',
            style: TextStyle(
              color: muted,
              fontSize: 11,
            ),
          ),
          Expanded(
            child: Center(
              child: showModel
                  ? const ModelViewer(
                      src: 'assets/models/heart.glb',
                      alt: '3D heart model',
                      autoRotate: true,
                      cameraControls: true,
                      backgroundColor: Color(0x00101629),
                    )
                  : const NeonHeart(),
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() => showModel = !showModel);
              },
              icon: const Icon(
                Icons.threed_rotation,
                color: cyan,
              ),
              label: Text(
                showModel ? 'NEON HEART' : 'EXPLORE 3D HEART',
                style: const TextStyle(color: cyan),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget metricsCard() {
    return Column(
      children: [
        metric(
          'RESTING HEART RATE',
          '68',
          'bpm',
          cyan,
          Icons.favorite,
        ),
        const SizedBox(height: 12),
        metric(
          'HEART RATE VARIABILITY',
          '52',
          'ms',
          violet,
          Icons.waves,
        ),
        const SizedBox(height: 12),
        metric(
          'SLEEP QUALITY',
          '82',
          '/100',
          pink,
          Icons.nightlight_round,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ILLUSTRATIVE RISK SCORE',
                style: TextStyle(
                  color: muted,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '28 / 100',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  color: cyan,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Demo value only. No validated predictive model '
                'is connected.',
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget metric(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        unit,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // REAL ECG CHART
  // ==========================================================

  Widget ecgCard() {
    final values = spots.map((spot) => spot.y).toList();

    final minY = values.isEmpty ? 0.0 : values.reduce(math.min) - 20;

    final maxY = values.isEmpty ? 100.0 : values.reduce(math.max) + 20;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ECG SIGNAL TIMELINE',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh ECG',
                onPressed: loading ? null : loadEcg,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: cyan,
                ),
              ),
            ],
          ),
          const Text(
            'Public MIT-BIH record 100 · MLII lead',
            style: TextStyle(
              color: muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This public ECG is not linked to the synthetic patient above.',
            style: TextStyle(
              color: pink,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: cyan,
                    ),
                  )
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: pink,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: loadEcg,
                              child: const Text('TRY AGAIN'),
                            ),
                          ],
                        ),
                      )
                    : spots.isEmpty
                        ? const Center(
                            child: Text(
                              'No ECG samples available.',
                              style: TextStyle(color: muted),
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: math.max(
                                1,
                                (spots.length - 1).toDouble(),
                              ),
                              minY: minY,
                              maxY: maxY,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) {
                                  return FlLine(
                                    color: Colors.white.withOpacity(.05),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 200,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 8,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 100,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 8,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: false,
                                  barWidth: 1.5,
                                  color: cyan,
                                  dotData: const FlDotData(
                                    show: false,
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: cyan.withOpacity(.06),
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.circle,
                color: cyan,
                size: 8,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ECG amplitude · dataset units',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ),
              Text(
                loading
                    ? 'LOADING'
                    : error == null
                        ? 'CONNECTED'
                        : 'OFFLINE',
                style: TextStyle(
                  color: error == null ? cyan : pink,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (!loading && error == null) ...[
            const SizedBox(height: 8),
            Text(
              '${spots.length} samples loaded · '
              '${annotations.length} annotations in this window',
              style: const TextStyle(
                color: muted,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget fusionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THE FUSION ENGINE',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The integration of clinical history and ECG is planned; '
            'it is not yet a working prediction pipeline.',
            style: TextStyle(
              color: muted,
              fontSize: 11,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          fusionNode(
            'STATIC / EHR',
            'Clinical history · labs · risk factors',
            violet,
            Icons.folder_copy_outlined,
          ),
          const Center(
            child: Icon(
              Icons.add,
              color: muted,
            ),
          ),
          fusionNode(
            'DYNAMIC / ECG',
            'MIT-BIH samples loaded from Python API',
            cyan,
            Icons.sensors,
          ),
          const Center(
            child: Icon(
              Icons.arrow_downward,
              color: muted,
            ),
          ),
          fusionNode(
            'TWIN + FORECAST',
            'Data fusion and predictive model: future work',
            pink,
            Icons.auto_graph,
          ),
        ],
      ),
    );
  }

  Widget fusionNode(
    String title,
    String description,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget secondaryPage() {
    final titles = [
      '',
      'Signal Explorer',
      'Clinical Casebook',
      'Twin Settings',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction,
                color: cyan,
                size: 40,
              ),
              const SizedBox(height: 14),
              Text(
                titles[selected],
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This workspace is a prototype placeholder. '
                'Additional signal analysis and clinical review '
                'features will be implemented next.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() => selected = 0);
                },
                child: const Text('RETURN TO DASHBOARD'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ANIMATED HEART
// ============================================================

class NeonHeart extends StatefulWidget {
  const NeonHeart({super.key});

  @override
  State<NeonHeart> createState() => _NeonHeartState();
}

class _NeonHeartState extends State<NeonHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + controller.value * .04,
          child: CustomPaint(
            size: const Size(190, 190),
            painter: HeartPainter(controller.value),
          ),
        );
      },
    );
  }
}

class HeartPainter extends CustomPainter {
  final double glow;

  HeartPainter(this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * .5, h * .82)
      ..cubicTo(
        w * .39,
        h * .71,
        w * .12,
        h * .52,
        w * .13,
        h * .32,
      )
      ..cubicTo(
        w * .14,
        h * .12,
        w * .39,
        h * .10,
        w * .5,
        h * .27,
      )
      ..cubicTo(
        w * .61,
        h * .10,
        w * .86,
        h * .12,
        w * .87,
        h * .32,
      )
      ..cubicTo(
        w * .88,
        h * .52,
        w * .61,
        h * .71,
        w * .5,
        h * .82,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = pink.withOpacity(.2 + glow * .2)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          15,
        ),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFF9BC6),
            Color(0xFFFF4E92),
            Color(0xFF7E3DCE),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFFFC6DE),
    );

    final veins = Path()
      ..moveTo(w * .48, h * .32)
      ..cubicTo(
        w * .47,
        h * .22,
        w * .55,
        h * .17,
        w * .58,
        h * .08,
      )
      ..moveTo(w * .49, h * .36)
      ..cubicTo(
        w * .39,
        h * .29,
        w * .33,
        h * .31,
        w * .25,
        h * .22,
      )
      ..moveTo(w * .52, h * .35)
      ..cubicTo(
        w * .61,
        h * .29,
        w * .69,
        h * .29,
        w * .74,
        h * .22,
      )
      ..moveTo(w * .48, h * .48)
      ..cubicTo(
        w * .40,
        h * .45,
        w * .36,
        h * .54,
        w * .32,
        h * .58,
      )
      ..moveTo(w * .55, h * .46)
      ..cubicTo(
        w * .63,
        h * .43,
        w * .67,
        h * .49,
        w * .70,
        h * .54,
      );

    canvas.drawPath(
      veins,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = cyan,
    );
  }

  @override
  bool shouldRepaint(covariant HeartPainter oldDelegate) {
    return oldDelegate.glow != glow;
  }
}
