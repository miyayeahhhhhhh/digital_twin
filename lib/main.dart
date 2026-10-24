import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

void main() => runApp(const HeartTwinApp());

const ink = Color(0xFF080B18);
const panel = Color(0xFF11172B);
const panel2 = Color(0xFF171F38);
const cyan = Color(0xFF56F0E0);
const pink = Color(0xFFFF5DA2);
const violet = Color(0xFF9A82FF);
const muted = Color(0xFF8D9AB8);

class HeartTwinApp extends StatelessWidget {
  const HeartTwinApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'HEART//TWIN',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: ink,
          colorScheme: const ColorScheme.dark(primary: cyan, secondary: pink),
          textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: 'doctor@hearttwin.ai');
  final password = TextEditingController(text: 'demo1234');
  bool obscure = true;
  bool busy = false;

  Future<void> enter() async {
    setState(() => busy = true);
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          const Positioned.fill(
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: RadialGradient(
                          center: Alignment(-.8, -.8),
                          radius: 1.25,
                          colors: [Color(0xFF25204A), ink, ink],
                          stops: [0, .48, 1])))),
          Positioned(
              right: -90,
              top: 80,
              child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pink.withOpacity(.07),
                      boxShadow: [
                        BoxShadow(
                            color: pink.withOpacity(.15),
                            blurRadius: 100,
                            spreadRadius: 25)
                      ]))),
          SafeArea(
              child: Center(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 28),
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                              colors: [cyan, violet]),
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: const Icon(
                                          Icons.monitor_heart_rounded,
                                          color: ink,
                                          size: 26)),
                                  const SizedBox(width: 12),
                                  Text('HEART',
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 3)),
                                  Text('//TWIN',
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: cyan,
                                          letterSpacing: 2)),
                                ]),
                                const SizedBox(height: 46),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                        color: cyan.withOpacity(.08),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                            color: cyan.withOpacity(.25))),
                                    child: const Text(
                                        '●  CARDIOVASCULAR DIGITAL TWIN',
                                        style: TextStyle(
                                            color: cyan,
                                            fontSize: 10,
                                            letterSpacing: 1.4,
                                            fontWeight: FontWeight.w800))),
                                const SizedBox(height: 20),
                                Text('See risk\\nbefore it\\nbecomes real.',
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 45,
                                        height: 1.02,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.7)),
                                const SizedBox(height: 16),
                                const Text(
                                    'A living cardiovascular model. One patient, two data streams, a clearer view of what could happen next.',
                                    style: TextStyle(
                                        color: muted,
                                        fontSize: 14,
                                        height: 1.7)),
                                const SizedBox(height: 30),
                                Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                        color: panel.withOpacity(.92),
                                        borderRadius: BorderRadius.circular(26),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(.09)),
                                        boxShadow: [
                                          BoxShadow(
                                              color: violet.withOpacity(.08),
                                              blurRadius: 36,
                                              spreadRadius: 1)
                                        ]),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('WELCOME BACK',
                                              style: TextStyle(
                                                  color: muted,
                                                  fontSize: 10,
                                                  letterSpacing: 2,
                                                  fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 8),
                                          Text('Sign in to your workspace',
                                              style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 22),
                                          _Field(
                                              label: 'EMAIL ADDRESS',
                                              controller: email,
                                              icon: Icons
                                                  .alternate_email_rounded),
                                          const SizedBox(height: 15),
                                          _Field(
                                              label: 'PASSWORD',
                                              controller: password,
                                              icon: Icons.lock_outline_rounded,
                                              obscure: obscure,
                                              suffix: IconButton(
                                                  onPressed: () => setState(
                                                      () => obscure = !obscure),
                                                  icon: Icon(
                                                      obscure
                                                          ? Icons
                                                              .visibility_off_rounded
                                                          : Icons
                                                              .visibility_rounded,
                                                      color: muted))),
                                          const SizedBox(height: 22),
                                          SizedBox(
                                              width: double.infinity,
                                              height: 54,
                                              child: FilledButton(
                                                  onPressed:
                                                      busy ? null : enter,
                                                  style: FilledButton.styleFrom(
                                                      backgroundColor: cyan,
                                                      foregroundColor: ink,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          15))),
                                                  child: busy
                                                      ? const SizedBox(
                                                          width: 22,
                                                          height: 22,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: ink))
                                                      : Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                              Text(
                                                                  'ENTER THE TWIN',
                                                                  style: GoogleFonts.spaceGrotesk(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w900,
                                                                      letterSpacing:
                                                                          1)),
                                                              const SizedBox(
                                                                  width: 9),
                                                              const Icon(
                                                                  Icons
                                                                      .arrow_forward_rounded,
                                                                  size: 18)
                                                            ]))),
                                          const SizedBox(height: 13),
                                          const Center(
                                              child: Text(
                                                  'DEMO MODE  •  SYNTHETIC PATIENT DATA',
                                                  style: TextStyle(
                                                      color: muted,
                                                      fontSize: 9,
                                                      letterSpacing: 1.1))),
                                        ])),
                                const SizedBox(height: 20),
                                const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shield_outlined,
                                          size: 14, color: cyan),
                                      SizedBox(width: 7),
                                      Text(
                                          'Privacy-first prototype · No real patient data',
                                          style: TextStyle(
                                              color: muted, fontSize: 11))
                                    ])
                              ])))))
        ]),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  const _Field(
      {required this.label,
      required this.controller,
      required this.icon,
      this.obscure = false,
      this.suffix});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: muted,
                fontSize: 9,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
                prefixIcon: Icon(icon, size: 18, color: muted),
                suffixIcon: suffix,
                filled: true,
                fillColor: const Color(0xFF090E20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(.06))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(.07))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: cyan, width: 1.2)))),
      ]);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selected = 0;
  bool live = true;
  bool showModel = false;
  double activity = 68;
  Timer? timer;
  int pulse = 0;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && live) setState(() => pulse++);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 850;
    return Scaffold(
      body: SafeArea(
          child: Row(children: [
        if (wide)
          _Sidebar(
              selected: selected,
              onSelect: (i) => setState(() => selected = i),
              onLogout: logout),
        Expanded(
            child: Column(children: [
          _TopBar(
              live: live,
              onLive: () => setState(() => live = !live),
              onLogout: logout),
          Expanded(child: selected == 0 ? dashboard(wide) : secondaryPage()),
        ]))
      ])),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              backgroundColor: panel,
              indicatorColor: cyan.withOpacity(.16),
              selectedIndex: selected,
              onDestinationSelected: (i) => setState(() => selected = i),
              destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.grid_view_rounded), label: 'Twin'),
                  NavigationDestination(
                      icon: Icon(Icons.timeline_rounded), label: 'Trends'),
                  NavigationDestination(
                      icon: Icon(Icons.assignment_outlined), label: 'Cases'),
                  NavigationDestination(
                      icon: Icon(Icons.settings_outlined), label: 'Settings'),
                ]),
    );
  }

  void logout() => Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));

  Widget dashboard(bool wide) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(wide ? 30 : 18, 20, wide ? 30 : 18, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('SATURDAY, OCTOBER 24  •  PATIENT SPACE / 001',
                      style: TextStyle(
                          color: muted,
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 9),
                  Text('Your patient,\\nin a new dimension.',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: wide ? 34 : 29,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1)),
                ])),
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(.08))),
                child:
                    const Icon(Icons.notifications_none_rounded, color: muted))
          ]),
          const SizedBox(height: 22),
          _PatientStrip(),
          const SizedBox(height: 18),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 6, child: heartCard()),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: riskCard()),
            ])
          else
            Column(children: [
              heartCard(),
              const SizedBox(height: 16),
              riskCard()
            ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _MetricCard(
                    title: 'RESTING HEART RATE',
                    value: '${68 + pulse % 3}',
                    unit: 'bpm',
                    delta: '−4 bpm this week',
                    color: cyan,
                    icon: Icons.favorite_rounded)),
            const SizedBox(width: 12),
            Expanded(
                child: _MetricCard(
                    title: 'HRV / VARIABILITY',
                    value: '${52 + pulse % 4}',
                    unit: 'ms',
                    delta: 'within baseline',
                    color: violet,
                    icon: Icons.waves_rounded)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _MetricCard(
                    title: 'SLEEP QUALITY',
                    value: '82',
                    unit: '/100',
                    delta: '7h 24m last night',
                    color: pink,
                    icon: Icons.nightlight_round)),
            const SizedBox(width: 12),
            Expanded(
                child: _MetricCard(
                    title: 'DAILY MOVEMENT',
                    value: '${(activity * 100).round()}',
                    unit: 'steps ×10',
                    delta: 'Goal: 10,000 steps',
                    color: const Color(0xFFFFC56B),
                    icon: Icons.directions_walk_rounded)),
          ]),
          const SizedBox(height: 20),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 7, child: trendsCard()),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: insightCard()),
            ])
          else
            Column(children: [
              trendsCard(),
              const SizedBox(height: 16),
              insightCard()
            ]),
          const SizedBox(height: 18),
          _DataFusionCard(),
          const SizedBox(height: 20),
          const Center(
              child: Text(
                  'HEART//TWIN IS A RESEARCH PROTOTYPE · NOT FOR CLINICAL DECISIONS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF5F6A86),
                      fontSize: 9,
                      letterSpacing: 1.1))),
        ]),
      );

  Widget heartCard() => Container(
      height: 365,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF191C3A),
                Color(0xFF101629),
                Color(0xFF0D1324)
              ]),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: violet.withOpacity(.22))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.blur_on_rounded, color: cyan, size: 17),
          const SizedBox(width: 8),
          const Expanded(
              child: Text('LIVE DIGITAL TWIN',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w900))),
          _StatusPill(
              text: live ? 'SYNCED' : 'PAUSED', color: live ? cyan : pink)
        ]),
        const SizedBox(height: 6),
        const Text('Patient-specific cardiac simulation',
            style: TextStyle(color: muted, fontSize: 11)),
        Expanded(
            child: Stack(alignment: Alignment.center, children: [
          Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: violet.withOpacity(.12), width: 1),
                  boxShadow: [
                    BoxShadow(
                        color: pink.withOpacity(.08),
                        blurRadius: 40,
                        spreadRadius: 15)
                  ])),
          Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cyan.withOpacity(.18), width: 1))),
          ...List.generate(
              12,
              (i) => Transform.rotate(
                  angle: i * math.pi / 6,
                  child: Container(
                      width: 1,
                      height: 230,
                      alignment: Alignment.topCenter,
                      child: Container(
                          width: 2,
                          height: 5,
                          decoration: BoxDecoration(
                              color: cyan.withOpacity(.5),
                              borderRadius: BorderRadius.circular(2)))))),
          if (showModel)
            ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: const ModelViewer(
                  src: 'assets/models/heart.glb',
                  alt: 'Interactive 3D heart model',
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: Color(0x00101629),
                ))
          else
            _NeonHeart(beat: live),
          Positioned(
              left: 0,
              top: 30,
              child:
                  _OrbitLabel(label: 'RHYTHM', value: 'STABLE', color: cyan)),
          Positioned(
              right: 0,
              bottom: 28,
              child: _OrbitLabel(
                  label: 'RISK INDEX', value: 'LOW–MOD', color: pink)),
          Positioned(
              bottom: 0,
              child: Text(
                  showModel
                      ? '3D MODEL VIEW  •  DRAG TO ROTATE'
                      : 'CARDIAC DIGITAL REPRESENTATION',
                  style: const TextStyle(
                      color: Color(0xFF6E7A9A),
                      fontSize: 8,
                      letterSpacing: 1.2))),
        ])),
        Row(children: [
          const Icon(Icons.touch_app_rounded, color: muted, size: 14),
          const SizedBox(width: 6),
          const Expanded(
              child: Text('Explore the virtual heart',
                  style: TextStyle(color: muted, fontSize: 10))),
          TextButton(
              onPressed: () => setState(() => showModel = !showModel),
              child: Text(showModel ? 'NEON VIEW' : '3D MODEL',
                  style: const TextStyle(
                      color: cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)))
        ])
      ]));

  Widget riskCard() => Container(
      height: 365,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(.07))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
              child: Text('PREDICTIVE OUTLOOK',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900))),
          Icon(Icons.auto_awesome_rounded, color: violet, size: 18)
        ]),
        const SizedBox(height: 22),
        Center(
            child: SizedBox(
                width: 174,
                height: 174,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                      child: CircularProgressIndicator(
                          value: .28,
                          strokeWidth: 10,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withOpacity(.06),
                          valueColor: const AlwaysStoppedAnimation(cyan))),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('28',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                height: 1)),
                        const Text('/100',
                            style: TextStyle(color: muted, fontSize: 12)),
                        const SizedBox(height: 5),
                        const Text('RISK SCORE',
                            style: TextStyle(
                                color: cyan,
                                fontSize: 9,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w900))
                      ])
                ]))),
        const SizedBox(height: 20),
        const Row(children: [
          Icon(Icons.check_circle_rounded, color: cyan, size: 17),
          SizedBox(width: 8),
          Expanded(
              child: Text(
                  'No acute anomaly detected in current simulated window.',
                  style: TextStyle(fontSize: 11, height: 1.5)))
        ]),
        const SizedBox(height: 13),
        const Row(children: [
          Icon(Icons.access_time_rounded, color: violet, size: 17),
          SizedBox(width: 8),
          Expanded(
              child: Text('Forecast horizon: next 2 hours',
                  style: TextStyle(color: muted, fontSize: 11)))
        ]),
        const Spacer(),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: cyan.withOpacity(.07),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: cyan.withOpacity(.14))),
            child: const Text(
                'MODEL NOTE  ·  Score is illustrative and not a validated clinical prediction.',
                style: TextStyle(color: cyan, fontSize: 9, height: 1.5)))
      ]));

  Widget trendsCard() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: Colors.white.withOpacity(.07))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
              child: Text('SIGNAL TIMELINE',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900))),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: panel2, borderRadius: BorderRadius.circular(8)),
              child: const Text('LAST 24H  ▾',
                  style: TextStyle(
                      color: muted, fontSize: 9, fontWeight: FontWeight.w800)))
        ]),
        const SizedBox(height: 6),
        const Text('Heart rate · wearable stream',
            style: TextStyle(color: muted, fontSize: 11)),
        const SizedBox(height: 18),
        SizedBox(
            height: 165,
            child: LineChart(LineChartData(
                minY: 48,
                maxY: 110,
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.white.withOpacity(.05), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, _) => Text('${v.toInt()}',
                                style: const TextStyle(
                                    color: muted, fontSize: 9)))),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            interval: 2,
                            getTitlesWidget: (v, _) => Text(
                                [
                                  '00h',
                                  '04h',
                                  '08h',
                                  '12h',
                                  '16h',
                                  '20h',
                                  '24h'
                                ][v.toInt().clamp(0, 6)],
                                style: const TextStyle(
                                    color: muted, fontSize: 8))))),
                lineBarsData: [
                  LineChartBarData(
                      isCurved: true,
                      barWidth: 3,
                      color: cyan,
                      dotData: const FlDotData(show: false),
                      belowBarData:
                          BarAreaData(show: true, color: cyan.withOpacity(.08)),
                      spots: const [
                        FlSpot(0, 62),
                        FlSpot(1, 59),
                        FlSpot(2, 55),
                        FlSpot(3, 57),
                        FlSpot(4, 68),
                        FlSpot(5, 83),
                        FlSpot(6, 76),
                        FlSpot(7, 70),
                        FlSpot(8, 64),
                        FlSpot(9, 61),
                        FlSpot(10, 66),
                        FlSpot(11, 74),
                        FlSpot(12, 68)
                      ]),
                  LineChartBarData(
                      isCurved: true,
                      barWidth: 1.5,
                      color: pink.withOpacity(.7),
                      dotData: const FlDotData(show: false),
                      spots: const [
                        FlSpot(0, 78),
                        FlSpot(1, 76),
                        FlSpot(2, 73),
                        FlSpot(3, 74),
                        FlSpot(4, 80),
                        FlSpot(5, 91),
                        FlSpot(6, 87),
                        FlSpot(7, 79),
                        FlSpot(8, 75),
                        FlSpot(9, 72),
                        FlSpot(10, 77),
                        FlSpot(11, 82),
                        FlSpot(12, 78)
                      ])
                ]))),
        const SizedBox(height: 12),
        const Row(children: [
          _LegendDot(color: cyan),
          SizedBox(width: 6),
          Text('Heart rate', style: TextStyle(color: muted, fontSize: 10)),
          SizedBox(width: 18),
          _LegendDot(color: pink),
          SizedBox(width: 6),
          Text('Upper reference band',
              style: TextStyle(color: muted, fontSize: 10))
        ])
      ]));

  Widget insightCard() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [violet.withOpacity(.12), panel],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: violet.withOpacity(.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_awesome, color: violet, size: 18),
          const SizedBox(width: 8),
          const Text('TWIN INSIGHTS',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900))
        ]),
        const SizedBox(height: 18),
        _InsightRow(
            number: '01',
            title: 'Recovery looks steady',
            body:
                'Sleep duration and overnight heart-rate pattern are close to the synthetic baseline.',
            color: cyan),
        const Divider(color: Colors.white12, height: 26),
        _InsightRow(
            number: '02',
            title: 'Activity is the lever',
            body:
                'A short, low-intensity walk may help reach the daily movement target.',
            color: pink),
        const Divider(color: Colors.white12, height: 26),
        _InsightRow(
            number: '03',
            title: 'Keep monitoring',
            body:
                'The model will flag changes that persist across multiple data windows.',
            color: violet),
        const SizedBox(height: 14),
        const Text('These are demo insights, not medical advice.',
            style: TextStyle(color: muted, fontSize: 9))
      ]));

  Widget secondaryPage() => Center(
      child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white10)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                    [
                      Icons.timeline_rounded,
                      Icons.assignment_outlined,
                      Icons.settings_outlined
                    ][(selected - 1).clamp(0, 2)],
                    color: cyan,
                    size: 42),
                const SizedBox(height: 16),
                Text(
                    [
                      'Signal explorer',
                      'Clinical casebook',
                      'Twin settings'
                    ][(selected - 1).clamp(0, 2)],
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text(
                    'Prototype workspace — designed to expand with additional patient signals, explainable model outputs, and clinician review workflows.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, height: 1.6)),
                const SizedBox(height: 22),
                FilledButton(
                    onPressed: () => setState(() => selected = 0),
                    child: const Text('RETURN TO TWIN DASHBOARD'))
              ]))));
}

class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.selected,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[
      (Icons.grid_view_rounded, 'Twin overview'),
      (Icons.timeline_rounded, 'Signal explorer'),
      (Icons.assignment_outlined, 'Casebook'),
      (Icons.settings_outlined, 'Settings'),
    ];

    return Container(
      width: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1020),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [cyan, violet]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: ink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HEART//TWIN',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const Text(
                    'CARDIO LAB  /  BETA',
                    style: TextStyle(
                      color: muted,
                      fontSize: 8,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'WORKSPACE',
            style: TextStyle(
              color: muted,
              fontSize: 9,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 13),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = selected == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelect(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? cyan.withOpacity(.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? cyan.withOpacity(.18)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(item.$1, size: 17, color: isSelected ? cyan : muted),
                      const SizedBox(width: 11),
                      Text(
                        item.$2,
                        style: TextStyle(
                          color: isSelected ? Colors.white : muted,
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(.06)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.hub_rounded, color: cyan, size: 14),
                    SizedBox(width: 7),
                    Text(
                      'DATA FUSION',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'EHR + wearable\nstreams connected',
                  style: TextStyle(color: muted, fontSize: 10, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Sign out'),
            style: TextButton.styleFrom(foregroundColor: muted),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool live;
  final VoidCallback onLive;
  final VoidCallback onLogout;
  const _TopBar(
      {required this.live, required this.onLive, required this.onLogout});
  @override
  Widget build(BuildContext context) => Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
          color: ink.withOpacity(.85),
          border:
              Border(bottom: BorderSide(color: Colors.white.withOpacity(.06)))),
      child: Row(children: [
        const Icon(Icons.circle, size: 6, color: cyan),
        const SizedBox(width: 8),
        const Text('SYSTEM ONLINE',
            style: TextStyle(
                color: muted,
                fontSize: 9,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w900)),
        const Spacer(),
        InkWell(
            onTap: onLive,
            borderRadius: BorderRadius.circular(30),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                    color: live ? cyan.withOpacity(.08) : pink.withOpacity(.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: (live ? cyan : pink).withOpacity(.25))),
                child: Row(children: [
                  Icon(
                      live ? Icons.sensors_rounded : Icons.pause_circle_outline,
                      size: 14,
                      color: live ? cyan : pink),
                  const SizedBox(width: 6),
                  Text(live ? 'LIVE SYNC' : 'PAUSED',
                      style: TextStyle(
                          color: live ? cyan : pink,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1))
                ]))),
        const SizedBox(width: 12),
        CircleAvatar(
            radius: 17,
            backgroundColor: violet.withOpacity(.2),
            child: const Icon(Icons.person_rounded, color: violet, size: 18)),
        if (MediaQuery.sizeOf(context).width > 650) ...[
          const SizedBox(width: 9),
          const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dr. Alex Morgan',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                Text('CARDIOLOGIST',
                    style:
                        TextStyle(color: muted, fontSize: 8, letterSpacing: 1))
              ]),
          const SizedBox(width: 12),
          IconButton(
              tooltip: 'Sign out',
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, color: muted, size: 18))
        ]
      ]));
}

class _PatientStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(.07))),
      child: Row(children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: violet.withOpacity(.16),
                borderRadius: BorderRadius.circular(14)),
            child:
                const Icon(Icons.person_pin_rounded, color: violet, size: 23)),
        const SizedBox(width: 12),
        const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PATIENT 001  ·  SYNTHETIC PROFILE',
              style: TextStyle(
                  color: muted,
                  fontSize: 8,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900)),
          SizedBox(height: 4),
          Text('Aarav Mehta',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          SizedBox(height: 3),
          Text('42 years  /  Male  /  Cardiovascular risk monitoring',
              style: TextStyle(color: muted, fontSize: 10))
        ])),
        if (MediaQuery.sizeOf(context).width > 520)
          const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('PROFILE COMPLETENESS',
                style: TextStyle(color: muted, fontSize: 8, letterSpacing: 1)),
            SizedBox(height: 7),
            SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                    value: .86,
                    minHeight: 4,
                    backgroundColor: Colors.white10,
                    color: cyan)),
            SizedBox(height: 5),
            Text('86%  ·  EHR + IOT',
                style: TextStyle(
                    color: cyan, fontSize: 8, fontWeight: FontWeight.w800))
          ])
      ]));
}

class _MetricCard extends StatelessWidget {
  final String title, value, unit, delta;
  final Color color;
  final IconData icon;
  const _MetricCard(
      {required this.title,
      required this.value,
      required this.unit,
      required this.delta,
      required this.color,
      required this.icon});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 7),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: muted,
                      fontSize: 8,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w900)))
        ]),
        const SizedBox(height: 15),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(
              child: Text(value,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 29, fontWeight: FontWeight.w800, height: 1))),
          const SizedBox(width: 5),
          Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(unit,
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.w800)))
        ]),
        const SizedBox(height: 10),
        Text(delta, style: const TextStyle(color: muted, fontSize: 9))
      ]));
}

class _NeonHeart extends StatefulWidget {
  final bool beat;
  const _NeonHeart({required this.beat});
  @override
  State<_NeonHeart> createState() => _NeonHeartState();
}

class _NeonHeartState extends State<_NeonHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final scale = widget.beat ? 1 + controller.value * .045 : 1.0;
        return Transform.scale(
            scale: scale,
            child: SizedBox(
                width: 155,
                height: 155,
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pink.withOpacity(.1),
                          boxShadow: [
                            BoxShadow(
                                color: pink
                                    .withOpacity(.22 + controller.value * .1),
                                blurRadius: 35,
                                spreadRadius: 5)
                          ])),
                  CustomPaint(
                      size: const Size(150, 150),
                      painter: _HeartPainter(glow: controller.value)),
                  const Positioned(
                      bottom: 5,
                      child: Text('♥',
                          style: TextStyle(color: pink, fontSize: 12)))
                ])));
      });
}

class _HeartPainter extends CustomPainter {
  final double glow;
  _HeartPainter({required this.glow});
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width, h = size.height;
    path.moveTo(w * .5, h * .82);
    path.cubicTo(w * .39, h * .71, w * .12, h * .52, w * .13, h * .32);
    path.cubicTo(w * .14, h * .12, w * .39, h * .10, w * .5, h * .27);
    path.cubicTo(w * .61, h * .10, w * .86, h * .12, w * .87, h * .32);
    path.cubicTo(w * .88, h * .52, w * .61, h * .71, w * .5, h * .82);
    path.close();
    final glowPaint = Paint()
      ..color = pink.withOpacity(.2 + glow * .2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(path, glowPaint);
    final fill = Paint()
      ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF9BC6), Color(0xFFFF4E92), Color(0xFF7E3DCE)])
          .createShader(Offset.zero & size);
    canvas.drawPath(path, fill);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFFFC6DE).withOpacity(.8);
    canvas.drawPath(path, outline);
    final vessel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = cyan;
    final veins = Path()
      ..moveTo(w * .48, h * .32)
      ..cubicTo(w * .47, h * .22, w * .55, h * .17, w * .58, h * .08)
      ..moveTo(w * .49, h * .36)
      ..cubicTo(w * .39, h * .29, w * .33, h * .31, w * .25, h * .22)
      ..moveTo(w * .52, h * .35)
      ..cubicTo(w * .61, h * .29, w * .69, h * .29, w * .74, h * .22)
      ..moveTo(w * .48, h * .48)
      ..cubicTo(w * .40, h * .45, w * .36, h * .54, w * .32, h * .58)
      ..moveTo(w * .55, h * .46)
      ..cubicTo(w * .63, h * .43, w * .67, h * .49, w * .70, h * .54);
    canvas.drawPath(veins, vessel);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) =>
      oldDelegate.glow != glow;
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusPill({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(.09),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(.25))),
      child: Text('●  $text',
          style: TextStyle(
              color: color,
              fontSize: 8,
              letterSpacing: .8,
              fontWeight: FontWeight.w900)));
}

class _OrbitLabel extends StatelessWidget {
  final String label, value;
  final Color color;
  const _OrbitLabel(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
          color: ink.withOpacity(.78),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                const TextStyle(color: muted, fontSize: 7, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .6))
      ]));
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _InsightRow extends StatelessWidget {
  final String number, title, body;
  final Color color;
  const _InsightRow(
      {required this.number,
      required this.title,
      required this.body,
      required this.color});
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color.withOpacity(.1),
                borderRadius: BorderRadius.circular(9)),
            child: Text(number,
                style: TextStyle(
                    color: color, fontSize: 9, fontWeight: FontWeight.w900))),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(body,
              style: const TextStyle(color: muted, fontSize: 10, height: 1.6))
        ]))
      ]);
}

class _DataFusionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(.07))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('THE FUSION ENGINE',
            style: TextStyle(
                fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        const Text('Two streams become one patient-specific view.',
            style: TextStyle(color: muted, fontSize: 11)),
        const SizedBox(height: 17),
        LayoutBuilder(builder: (context, c) {
          final vertical = c.maxWidth < 500;
          final staticBox = _FusionNode(
              icon: Icons.folder_copy_outlined,
              title: 'STATIC / EHR',
              details: 'Age · history · labs · risk factors',
              color: violet);
          final dynamicBox = _FusionNode(
              icon: Icons.sensors_rounded,
              title: 'DYNAMIC / IOT',
              details: 'HR · HRV · sleep · movement',
              color: cyan);
          final outputBox = _FusionNode(
              icon: Icons.auto_graph_rounded,
              title: 'TWIN + FORECAST',
              details: 'Fused features · risk outlook',
              color: pink);
          if (vertical)
            return Column(children: [
              staticBox,
              const Icon(Icons.south_rounded, color: muted),
              dynamicBox,
              const Icon(Icons.south_rounded, color: muted),
              outputBox
            ]);
          return Row(children: [
            Expanded(child: staticBox),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.add_rounded, color: muted)),
            Expanded(child: dynamicBox),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded, color: muted)),
            Expanded(child: outputBox)
          ]);
        })
      ]));
}

class _FusionNode extends StatelessWidget {
  final IconData icon;
  final String title, details;
  final Color color;
  const _FusionNode(
      {required this.icon,
      required this.title,
      required this.details,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: color.withOpacity(.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(.2))),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 9,
                  letterSpacing: .7,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(details,
              style: const TextStyle(color: muted, fontSize: 9, height: 1.4))
        ]))
      ]));
}
