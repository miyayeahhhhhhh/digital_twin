// ============================================================
// HEART//TWIN  ·  main.dart  (complete)
//
// Patient onboarding now asks for:
//   • Resting heart rate (BPM)
//   • ECG samples (paste raw values or a CSV export) + sampling rate + unit
//   • Optional MIT-BIH record number (loads the record's ECG & clinical data)
//
// ECG source priority for every patient:
//   1. ECG samples the patient pasted
//   2. MIT-BIH record ECG from the backend (offline: simulated at the
//      record's rhythm/BPM)
//   3. Simulated ECG at the BPM the patient entered (labelled SIMULATED)
//
// Backend contract (all optional; the app never breaks if it is missing):
//   GET {baseUrl}/ecg?record=100&seconds=10
//       -> JSON list of numbers  OR  a map such as
//          { "values": [...], "fs": 360, "gain": 200, "baseline": 1024,
//            "annotations": [ {"sample": 77, "symbol": "N"}, ... ] }
//   GET {baseUrl}/record/100
//       -> { "age": 69, "sex": "M", "bpm": 75, "medications": "...",
//            "history": "..." }
//   GET {baseUrl}/records
//       -> [ {"record": "100", "age": 69, "sex": "M"}, ... ]
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:model_viewer_plus/model_viewer_plus.dart';

void main() => runApp(const HeartTwinApp());

const Color bgColor = Color(0xFF101629);
const Color panelColor = Color(0xFF192238);
const Color cyanColor = Color(0xFF3DE0FF);
const Color pinkColor = Color(0xFFFF3DCB);
const Color mutedColor = Color(0xFF9AA9C5);
const Color violetColor = Color(0xFFB79CFF);
const Color amberColor = Color(0xFFFFB86B);
const Color greenColor = Color(0xFF5DE3A0);

class HeartTwinApp extends StatelessWidget {
  const HeartTwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HEART//TWIN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cyanColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panelColor,
          labelStyle: const TextStyle(color: mutedColor),
          prefixIconColor: cyanColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: cyanColor),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ============================================================
// DATA MODELS
// ============================================================

enum Rhythm { normal, apc, pvc, bigeminy, afib }

class EcgSignal {
  final List<double> samples; // millivolts
  final double fs; // sampling rate (Hz)
  final String source;
  final bool measured; // true = real data, false = simulated
  final String? recordId;
  final List<int> annPeaks; // optional annotated beat positions (samples)
  final List<String> annSymbols; // 'N' | 'A' | 'V'

  EcgSignal({
    required this.samples,
    required this.fs,
    required this.source,
    required this.measured,
    this.recordId,
    this.annPeaks = const [],
    this.annSymbols = const [],
  });

  double get duration => samples.length / fs;
}

class PatientProfile {
  final String id;
  String name;
  int? age;
  String sex;
  double? heightCm;
  double? weightKg;
  double? restingBpm; // patient-reported / record resting heart rate
  List<double>? ecgSamples; // patient-supplied ECG samples
  double ecgFs; // sampling rate of ecgSamples
  String ecgUnit; // 'auto' | 'mv' | 'adc'
  String bloodPressure;
  double? oxygen;
  double? sleepHours;
  String activity;
  String heartHistory;
  String medications;
  String allergies;
  String symptoms;
  String diabetes;
  String hypertension;
  String familyHistory;
  String smoking;
  String? recordId;

  PatientProfile({
    required this.id,
    required this.name,
    this.age,
    this.sex = 'Prefer not to say',
    this.heightCm,
    this.weightKg,
    this.restingBpm,
    this.ecgSamples,
    this.ecgFs = 360,
    this.ecgUnit = 'auto',
    this.bloodPressure = '',
    this.oxygen,
    this.sleepHours,
    this.activity = '',
    this.heartHistory = '',
    this.medications = '',
    this.allergies = '',
    this.symptoms = '',
    this.diabetes = 'No',
    this.hypertension = 'No',
    this.familyHistory = 'Unknown',
    this.smoking = 'No',
    this.recordId,
  });

  double? get bmi {
    if (heightCm == null || weightKg == null || heightCm! < 50) return null;
    final m = heightCm! / 100;
    return weightKg! / (m * m);
  }

  int? get systolic {
    final m = RegExp(r'(\d{2,3})\s*/\s*(\d{2,3})').firstMatch(bloodPressure);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  bool get hasUserEcg =>
      ecgSamples != null && ecgSamples!.length >= (2 * ecgFs).round();
}

class PatientStore {
  // Patients who registered during this app session (visible to the doctor).
  static final List<PatientProfile> registered = [];
}

String ecgSourceLabel(PatientProfile p) {
  if (p.hasUserEcg) {
    return 'Pasted · ${p.ecgSamples!.length} samples @ ${p.ecgFs.round()} Hz';
  }
  if (p.recordId != null) return 'MIT-BIH record ${p.recordId}';
  return 'None · simulated from BPM';
}

// ---- MIT-BIH catalog ----------------------------------------------------

class MitbihRecord {
  final String id;
  final int age;
  final String sex; // 'Male' | 'Female'
  final String heartHistory;
  final String medications;
  final String symptoms;
  final Rhythm rhythm;
  final double bpm;

  const MitbihRecord({
    required this.id,
    required this.age,
    required this.sex,
    this.heartHistory = '',
    this.medications = '',
    this.symptoms = '',
    this.rhythm = Rhythm.normal,
    this.bpm = 75,
  });

  static String _str(Map m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is List) {
        final s = v.map((e) => '$e').where((e) => e.isNotEmpty).join(', ');
        if (s.isNotEmpty) return s;
      } else {
        final s = '$v'.trim();
        if (s.isNotEmpty && s != 'null') return s;
      }
    }
    return '';
  }

  static MitbihRecord? fromMap(Map m, {String? fallbackId}) {
    final rawId = _str(m, ['record', 'record_id', 'id', 'name']);
    final id =
        MitbihCatalog.normalizeId(rawId.isEmpty ? (fallbackId ?? '') : rawId);
    final ageVal = EcgApi.toNum(m['age']);
    if (id == null || ageVal == null) return null;

    final sx = _str(m, ['sex', 'gender']).toLowerCase();
    final sex = sx.startsWith('f') ? 'Female' : 'Male';

    final rhythmText = _str(m, ['rhythm', 'diagnosis', 'notes']).toLowerCase();
    Rhythm r = Rhythm.normal;
    if (rhythmText.contains('bigem')) {
      r = Rhythm.bigeminy;
    } else if (rhythmText.contains('fibril')) {
      r = Rhythm.afib;
    } else if (rhythmText.contains('pvc') || rhythmText.contains('ventric')) {
      r = Rhythm.pvc;
    } else if (rhythmText.contains('apc') || rhythmText.contains('atrial')) {
      r = Rhythm.apc;
    }

    return MitbihRecord(
      id: id,
      age: ageVal.round(),
      sex: sex,
      heartHistory: _str(m, ['history', 'diagnosis', 'conditions', 'notes']),
      medications: _str(m, ['medications', 'meds', 'drugs']),
      symptoms: _str(m, ['symptoms']),
      rhythm: r,
      bpm: EcgApi.toNum(m['bpm'] ?? m['hr'] ?? m['heart_rate']) ?? 75,
    );
  }
}

class MitbihCatalog {
  // Built-in fallback entries (used when the backend is unreachable).
  // Age/sex follow the MIT-BIH record headers; verify against your files.
  static final Map<String, MitbihRecord> _cache = {
    '100': const MitbihRecord(
      id: '100',
      age: 69,
      sex: 'Male',
      heartHistory: 'Occasional atrial premature beats',
      medications: 'Aldomet, Inderal',
      rhythm: Rhythm.apc,
      bpm: 75,
    ),
    '106': const MitbihRecord(
      id: '106',
      age: 24,
      sex: 'Female',
      heartHistory: 'Frequent ventricular premature beats',
      rhythm: Rhythm.pvc,
      bpm: 78,
    ),
    '119': const MitbihRecord(
      id: '119',
      age: 51,
      sex: 'Female',
      heartHistory: 'Ventricular bigeminy',
      rhythm: Rhythm.bigeminy,
      bpm: 70,
    ),
    '200': const MitbihRecord(
      id: '200',
      age: 64,
      sex: 'Male',
      heartHistory: 'Frequent ventricular ectopy',
      rhythm: Rhythm.pvc,
      bpm: 82,
    ),
  };

  static bool _remoteLoaded = false;

  static String? normalizeId(String text) {
    final d = RegExp(r'\d+').firstMatch(text);
    if (d == null) return null;
    final s = d.group(0)!;
    return s.length >= 3 ? s : s.padLeft(3, '0');
  }

  static MitbihRecord? cached(String id) => _cache[id];

  /// Looks in cache, then asks the backend.
  static Future<MitbihRecord?> resolve(String id) async {
    if (_cache.containsKey(id)) return _cache[id];
    final info = await EcgApi.fetchRecordInfo(id);
    if (info == null) return null;
    final rec = MitbihRecord.fromMap(info, fallbackId: id);
    if (rec != null) _cache[rec.id] = rec;
    return rec;
  }

  /// Merges the backend record list (if available) into the cache.
  static Future<void> loadRemote() async {
    if (_remoteLoaded) return;
    final list = await EcgApi.fetchRecordList();
    if (list == null) return;
    _remoteLoaded = true;
    for (final item in list) {
      if (item is Map) {
        final rec = MitbihRecord.fromMap(item);
        if (rec != null && !_cache.containsKey(rec.id)) _cache[rec.id] = rec;
      }
    }
  }

  /// Records with the same age and sex; closest BPM first when BPM is known.
  static List<MitbihRecord> findByDemographics(int age, String sex,
      {double? bpm}) {
    if (sex != 'Male' && sex != 'Female') return [];
    final list =
        _cache.values.where((r) => r.age == age && r.sex == sex).toList();
    if (bpm != null) {
      list.sort((a, b) => (a.bpm - bpm).abs().compareTo((b.bpm - bpm).abs()));
    }
    return list;
  }
}

// ---- Analysis models ---------------------------------------------------

class Finding {
  final String title;
  final String detail;
  final int level; // 0 normal, 1 watch, 2 attention
  const Finding(this.title, this.detail, this.level);
}

class EcgAnalysis {
  final List<int> peaks;
  final List<String> symbols;
  final double? heartRate;
  final double? sdnn;
  final double? rmssd;
  final double? pnn50;
  final int beatCount;
  final int pvcCount;
  final int apcCount;
  final bool bigeminy;
  final bool irregular;
  final double duration;
  final List<Finding> findings;

  const EcgAnalysis({
    required this.peaks,
    required this.symbols,
    required this.heartRate,
    required this.sdnn,
    required this.rmssd,
    required this.pnn50,
    required this.beatCount,
    required this.pvcCount,
    required this.apcCount,
    required this.bigeminy,
    required this.irregular,
    required this.duration,
    required this.findings,
  });
}

class ConditionInsight {
  final String name;
  final String likelihood; // Low | Possible | Elevated
  final String reason;
  const ConditionInsight(this.name, this.likelihood, this.reason);
}

class RiskReport {
  final double score;
  final String level; // Low | Moderate | High
  final List<String> factors;
  final List<ConditionInsight> conditions;
  const RiskReport(this.score, this.level, this.factors, this.conditions);
}

class PatientCase {
  final PatientProfile profile;
  final EcgSignal signal;
  final EcgAnalysis analysis;
  final RiskReport risk;
  const PatientCase(this.profile, this.signal, this.analysis, this.risk);
}

// ============================================================
// ECG TEXT PARSER (pasted samples / CSV exports)
// ============================================================

class EcgText {
  /// Accepts: one long comma/space separated line, one value per line, or a
  /// multi-column CSV (e.g. MIT-BIH `rdsamp -c` export). In multi-column data
  /// an increasing first column is treated as the sample index / time and the
  /// second column is used. Header lines without numbers are ignored.
  static List<double> parse(String text) {
    final rows = <List<double>>[];
    for (final line in text.split(RegExp(r'[\r\n]+'))) {
      final l = line.trim();
      if (l.isEmpty) continue;
      final nums = <double>[];
      for (final tok in l.split(RegExp(r'[,;\s\[\]]+'))) {
        if (tok.isEmpty) continue;
        final v = double.tryParse(tok.replaceAll("'", ''));
        if (v != null && v.isFinite) nums.add(v);
      }
      if (nums.isNotEmpty) rows.add(nums);
    }
    if (rows.isEmpty) return [];

    if (rows.length >= 20) {
      final widths = rows.map((r) => r.length).toList()..sort();
      final med = widths[widths.length ~/ 2];
      if (med >= 2) {
        bool indexCol = true;
        for (int i = 1; i < math.min(rows.length, 20); i++) {
          if (rows[i].length < 2 || rows[i][0] <= rows[i - 1][0]) {
            indexCol = false;
            break;
          }
        }
        final col = indexCol ? 1 : 0;
        return [
          for (final r in rows)
            if (r.length > col) r[col]
        ];
      }
    }
    return [for (final r in rows) ...r];
  }
}

// ============================================================
// API SERVICE
// ============================================================

class EcgApi {
  // Change this to your laptop's current Wi-Fi IPv4 address.
  // Android emulator normally reaches the host computer via
  // http://10.0.2.2:8000 instead.
  static const String baseUrl = 'http://192.168.0.107:8000';
  static const String endpoint = '/ecg';
  static const String recordEndpoint = '/record';
  static const String recordListEndpoint = '/records';

  static const String _beatSymbols = 'NLRBAaJSVrFejnE/fQ?';

  static double? toNum(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  static Future<EcgSignal> fetchEcg({String? record}) async {
    final base = Uri.parse('$baseUrl$endpoint');
    final uri = base.replace(queryParameters: {
      if (record != null) 'record': record,
      'seconds': '10',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw Exception('ECG API returned ${response.statusCode}');
    }
    return parse(jsonDecode(response.body), record: record);
  }

  static Future<Map<String, dynamic>?> fetchRecordInfo(String id) async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl$recordEndpoint/$id'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode != 200) return null;
      final d = jsonDecode(r.body);
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>?> fetchRecordList() async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl$recordListEndpoint'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode != 200) return null;
      final d = jsonDecode(r.body);
      if (d is List) return d;
      if (d is Map && d['records'] is List) return d['records'] as List;
    } catch (_) {}
    return null;
  }

  static String _group(String s) {
    if (s.isNotEmpty && 'VEF'.contains(s)) return 'V';
    if (s.isNotEmpty && 'AaSJ'.contains(s)) return 'A';
    return 'N';
  }

  /// Builds a signal from samples the patient typed/pasted.
  static EcgSignal fromUser(List<double> raw, double fs, String unit) {
    final maxN = (fs * 30).round();
    var s = raw.length > maxN ? raw.sublist(0, maxN) : List<double>.from(raw);
    if (s.length < 2) throw Exception('ECG too short');

    final sorted = List<double>.from(s)..sort();
    final range = sorted.last - sorted.first;
    final adc = unit == 'adc' || (unit == 'auto' && range > 30);
    if (adc) {
      final med = sorted[sorted.length ~/ 2];
      s = s.map((v) => (v - med) / 200).toList(); // MIT-BIH ≈ 200 units/mV
    }
    return EcgSignal(
      samples: s,
      fs: fs,
      source: 'Your ECG samples · ${s.length} points @ ${fs.round()} Hz'
          '${adc ? ' · raw units ÷ 200 → mV' : ' · mV'}',
      measured: true,
    );
  }

  static EcgSignal parse(dynamic data, {String? record}) {
    List? raw;
    double fs = 360;
    double? gain;
    double? baseline;
    final annPairs = <MapEntry<int, String>>[];
    double offset = 0;

    if (data is List) {
      raw = data;
    } else if (data is Map) {
      for (final key in [
        'values',
        'ecg',
        'signal',
        'samples',
        'data',
        'record'
      ]) {
        final v = data[key];
        if (v is List && v.isNotEmpty) {
          raw = v;
          break;
        }
      }
      for (final k in [
        'fs',
        'sampling_rate',
        'sample_rate',
        'sampling_frequency',
        'frequency'
      ]) {
        final v = toNum(data[k]);
        if (v != null && v > 10) {
          fs = v;
          break;
        }
      }
      gain = toNum(data['gain'] ?? data['adc_gain']);
      baseline = toNum(data['baseline'] ?? data['adc_zero']);
      offset = toNum(data['start'] ?? data['offset']) ?? 0;

      final ann = data['annotations'] ?? data['annotation'] ?? data['beats'];
      if (ann is List) {
        for (final a in ann) {
          if (a is Map) {
            final idx =
                toNum(a['sample'] ?? a['index'] ?? a['idx'] ?? a['position']);
            if (idx == null) continue;
            final sym = '${a['symbol'] ?? a['type'] ?? a['label'] ?? 'N'}';
            annPairs.add(MapEntry(idx.round(), sym));
          }
        }
      }
      final pk = data['r_peaks'] ?? data['rpeaks'] ?? data['peaks'];
      if (annPairs.isEmpty && pk is List) {
        for (final v in pk) {
          final idx = toNum(v);
          if (idx != null) annPairs.add(MapEntry(idx.round(), 'N'));
        }
      }
    }

    if (raw == null || raw.length < 2) {
      throw Exception('No ECG values found in response');
    }

    var samples = <double>[];
    for (final v in raw) {
      double? d;
      if (v is num) {
        d = v.toDouble();
      } else if (v is List && v.isNotEmpty && v.first is num) {
        d = (v.first as num).toDouble(); // first channel
      } else if (v is String) {
        d = double.tryParse(v);
      }
      samples.add(d != null && d.isFinite ? d : 0);
    }

    final maxN = (fs * 30).round();
    if (samples.length > maxN) samples = samples.sublist(0, maxN);
    if (samples.length < 2) throw Exception('ECG response too short');

    // Convert to millivolts.
    if (gain != null && gain != 0) {
      final b = baseline ?? 0;
      final g = gain;
      samples = samples.map((v) => (v - b) / g).toList();
    } else {
      final sorted = List<double>.from(samples)..sort();
      final range = sorted.last - sorted.first;
      if (range > 30) {
        // Looks like raw ADC units; MIT-BIH uses ~200 units/mV.
        final med = sorted[sorted.length ~/ 2];
        samples = samples.map((v) => (v - med) / 200).toList();
      }
    }

    // Beat annotations (optional).
    final n = samples.length;
    final valid = annPairs
        .map((e) => MapEntry((e.key - offset).round(), e.value))
        .where((e) =>
            e.key >= 0 &&
            e.key < n &&
            e.value.isNotEmpty &&
            _beatSymbols.contains(e.value[0]))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return EcgSignal(
      samples: samples,
      fs: fs,
      source: record != null
          ? 'MIT-BIH record $record · backend data'
          : 'Backend ECG feed',
      measured: true,
      recordId: record,
      annPeaks: valid.map((e) => e.key).toList(),
      annSymbols: valid.map((e) => _group(e.value[0])).toList(),
    );
  }
}

// ============================================================
// ECG SIMULATOR (fallback; physiologically shaped PQRST)
// ============================================================

class _SimBeat {
  final double t;
  final String type; // N, A, V
  _SimBeat(this.t, this.type);
}

class EcgSimulator {
  static double _gauss(math.Random r) {
    final u1 = math.max(1e-9, r.nextDouble());
    final u2 = r.nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }

  static double _g(double dt, double a, double c, double s) {
    final z = (dt - c) / s;
    return a * math.exp(-0.5 * z * z);
  }

  static EcgSignal generate({
    required double bpm,
    Rhythm rhythm = Rhythm.normal,
    double seconds = 12,
    double fs = 360,
    int seed = 1,
    String source = 'Simulated ECG',
    String? recordId,
  }) {
    final rng = math.Random(seed);
    final base = 60 / bpm;
    final beats = <_SimBeat>[];

    double t = 0.55;
    double pause = 1.0;
    int k = 0;
    beats.add(_SimBeat(t, 'N'));

    while (true) {
      final rr = base * (1 + _gauss(rng) * 0.025);
      String type = 'N';
      switch (rhythm) {
        case Rhythm.normal:
          break;
        case Rhythm.apc:
          if (k >= 3 && rng.nextDouble() < 0.13) type = 'A';
          break;
        case Rhythm.pvc:
          if (k >= 2 && rng.nextDouble() < 0.2) type = 'V';
          break;
        case Rhythm.bigeminy:
          if (k.isOdd) type = 'V';
          break;
        case Rhythm.afib:
          break;
      }

      double gap;
      if (rhythm == Rhythm.afib) {
        gap = base * (0.55 + rng.nextDouble() * 0.8);
      } else if (type == 'N') {
        gap = rr * pause;
        pause = 1.0;
      } else if (type == 'A') {
        gap = rr * 0.7;
        pause = 1.08;
      } else {
        gap = rr * 0.62;
        pause = 1.35;
      }

      t += gap;
      if (t > seconds - 0.45) break;
      beats.add(_SimBeat(t, type));
      k++;
    }

    final n = (seconds * fs).round();
    final x = List<double>.filled(n, 0);
    final tCenter = 0.25 * math.sqrt(base).clamp(0.55, 1.2);
    final half = (0.55 * fs).round();

    for (final b in beats) {
      final c = (b.t * fs).round();
      final lo = math.max(0, c - half);
      final hi = math.min(n - 1, c + half);
      for (int i = lo; i <= hi; i++) {
        final dt = i / fs - b.t;
        double v;
        if (b.type == 'V') {
          v = _g(dt, 1.35, 0.0, 0.032) +
              _g(dt, -0.35, 0.075, 0.030) +
              _g(dt, -0.45, 0.27, 0.060);
        } else {
          final hasP = rhythm != Rhythm.afib;
          v = (hasP
                  ? _g(dt, b.type == 'A' ? 0.07 : 0.12,
                      b.type == 'A' ? -0.12 : -0.16, 0.025)
                  : 0) +
              _g(dt, -0.12, -0.035, 0.010) +
              _g(dt, 1.0, 0.0, 0.011) +
              _g(dt, -0.22, 0.032, 0.012) +
              _g(dt, 0.30, tCenter, 0.045);
        }
        x[i] += v;
      }
    }

    final ph1 = rng.nextDouble() * 6.28;
    final ph2 = rng.nextDouble() * 6.28;
    for (int i = 0; i < n; i++) {
      final tt = i / fs;
      x[i] += 0.04 * math.sin(2 * math.pi * 0.22 * tt + ph1) +
          0.012 * math.sin(2 * math.pi * 0.5 * tt + ph2) +
          _gauss(rng) * 0.008;
      if (rhythm == Rhythm.afib) {
        x[i] += 0.03 * math.sin(2 * math.pi * 6.3 * tt + ph1) +
            0.02 * math.sin(2 * math.pi * 8.1 * tt + ph2);
      }
    }

    return EcgSignal(
      samples: x,
      fs: fs,
      source: source,
      measured: false,
      recordId: recordId,
    );
  }

  /// Heartbeat simulation driven by the patient's own BPM and history.
  static EcgSignal forProfile(PatientProfile p) {
    final reported = p.restingBpm;
    double bpm;
    if (reported != null && reported >= 30) {
      bpm = reported;
    } else {
      bpm = 72;
      final age = p.age ?? 40;
      if (age >= 60) bpm -= 2;
      if (p.smoking == 'Yes') bpm += 5;
      if ((p.sleepHours ?? 7) < 5) bpm += 3;
      if ((p.oxygen ?? 98) < 94) bpm += 6;
      final act = p.activity.toLowerCase();
      if (['daily', 'run', 'gym', 'yoga', 'jog', 'swim', 'cycl']
          .any((w) => act.contains(w))) {
        bpm -= 5;
      }
    }
    bpm = bpm.clamp(35.0, 180.0).toDouble();

    final txt = '${p.symptoms} ${p.heartHistory}'.toLowerCase();
    Rhythm rhythm = Rhythm.normal;
    if (txt.contains('bigem')) {
      rhythm = Rhythm.bigeminy;
    } else if (txt.contains('fibril') || txt.contains('afib')) {
      rhythm = Rhythm.afib;
    } else if (txt.contains('pvc') || txt.contains('ventric')) {
      rhythm = Rhythm.pvc;
    } else if (txt.contains('palpit') ||
        txt.contains('skip') ||
        txt.contains('atrial') ||
        txt.contains('apc')) {
      rhythm = Rhythm.apc;
    }

    final seed = p.name.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0xFFFF);

    return generate(
      bpm: bpm,
      rhythm: rhythm,
      seed: seed + 1,
      source: reported != null
          ? 'SIMULATED at your reported ${bpm.round()} BPM · not a measurement'
          : 'SIMULATED from your profile · not a measurement',
    );
  }
}

// ============================================================
// ECG ANALYSIS (R-peak detection, HRV, ectopy screening)
// ============================================================

double _mean(List<double> v) =>
    v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

double _std(List<double> v) {
  if (v.length < 2) return 0;
  final m = _mean(v);
  double s = 0;
  for (final x in v) {
    s += (x - m) * (x - m);
  }
  return math.sqrt(s / (v.length - 1));
}

class EcgAnalyzer {
  static List<double> _detrend(List<double> x, double fs) {
    final n = x.length;
    final win = math.max(3, (0.5 * fs).round());
    final prefix = List<double>.filled(n + 1, 0);
    for (int i = 0; i < n; i++) {
      prefix[i + 1] = prefix[i] + x[i];
    }
    final y = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final a = math.max(0, i - win ~/ 2);
      final b = math.min(n, i + win ~/ 2 + 1);
      y[i] = x[i] - (prefix[b] - prefix[a]) / (b - a);
    }
    return y;
  }

  /// Derivative -> squaring -> moving-window integration (Pan-Tompkins style).
  static List<int> detectRPeaks(List<double> x, double fs) {
    final n = x.length;
    if (n < fs * 2) return [];
    final y = _detrend(x, fs);

    final sq = List<double>.filled(n, 0);
    for (int i = 2; i < n - 2; i++) {
      final d = (2 * y[i + 2] + y[i + 1] - y[i - 1] - 2 * y[i - 2]) / 8;
      sq[i] = d * d;
    }

    final half = math.max(1, (0.06 * fs).round());
    final pre = List<double>.filled(n + 1, 0);
    for (int i = 0; i < n; i++) {
      pre[i + 1] = pre[i] + sq[i];
    }
    final mwi = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final a = math.max(0, i - half);
      final b = math.min(n, i + half + 1);
      mwi[i] = (pre[b] - pre[a]) / (b - a);
    }

    final cand = <int>[];
    for (int i = 1; i < n - 1; i++) {
      if (mwi[i] > mwi[i - 1] && mwi[i] >= mwi[i + 1] && mwi[i] > 0) {
        cand.add(i);
      }
    }
    cand.sort((a, b) => mwi[b].compareTo(mwi[a]));

    final minDist = (0.25 * fs).round();
    final kept = <int>[];
    for (final c in cand) {
      if (kept.every((k) => (k - c).abs() >= minDist)) kept.add(c);
    }
    if (kept.isEmpty) return [];

    kept.sort((a, b) => mwi[b].compareTo(mwi[a]));
    final dur = n / fs;
    final k = math.min(kept.length, math.max(3, (dur * 0.6).round()));
    final top = kept.take(k).map((i) => mwi[i]).toList()..sort();
    final ref = top[top.length ~/ 2];
    final thr = 0.25 * ref;

    final sel = kept.where((i) => mwi[i] >= thr).toList()..sort();

    // Refine each beat to the true |R| maximum in the detrended signal.
    final r = (0.07 * fs).round();
    final refined = <int>[];
    for (final c in sel) {
      int best = c;
      double bv = y[c].abs();
      for (int j = math.max(0, c - r); j <= math.min(n - 1, c + r); j++) {
        if (y[j].abs() > bv) {
          bv = y[j].abs();
          best = j;
        }
      }
      refined.add(best);
    }
    refined.sort();

    final res = <int>[];
    for (final p in refined) {
      if (res.isNotEmpty && p - res.last < minDist * 0.8) {
        if (y[p].abs() > y[res.last].abs()) res[res.length - 1] = p;
      } else {
        res.add(p);
      }
    }
    return res;
  }

  static void _markWide(
      List<double> x, List<int> peaks, List<String> syms, double fs) {
    if (peaks.length < 3) return;
    final y = _detrend(x, fs);
    final n = x.length;
    final maxW = (0.2 * fs).round();
    final widths = <double>[];
    for (final p in peaks) {
      final thr = 0.3 * y[p].abs();
      int l = p;
      int r = p;
      while (l > 0 && p - l < maxW && y[l - 1].abs() >= thr) {
        l--;
      }
      while (r < n - 1 && r - p < maxW && y[r + 1].abs() >= thr) {
        r++;
      }
      widths.add((r - l + 1) / fs);
    }
    final sorted = List<double>.from(widths)..sort();
    final med = sorted[sorted.length ~/ 2];
    for (int i = 0; i < peaks.length; i++) {
      final w = widths[i];
      final wide = (w > 0.095 && w > 1.6 * med) || w > 0.14;
      if (wide) syms[i] = 'V';
    }
  }

  static EcgAnalysis analyze(EcgSignal s, {double? reportedBpm}) {
    final fs = s.fs;
    final dur = s.duration;
    List<int> peaks;
    List<String> syms;
    final annotated = s.annPeaks.length >= 2;

    if (annotated) {
      peaks = List<int>.from(s.annPeaks);
      syms = List<String>.from(s.annSymbols);
    } else {
      peaks = detectRPeaks(s.samples, fs);
      syms = List<String>.filled(peaks.length, 'N');
      _markWide(s.samples, peaks, syms, fs);
    }

    final n = peaks.length;
    final findings = <Finding>[];

    if (n < 3) {
      findings.add(const Finding(
        'Not enough beats to analyse',
        'Fewer than 3 heartbeats were detected in this segment. Try '
            'refreshing or supplying a longer recording.',
        1,
      ));
      return EcgAnalysis(
        peaks: peaks,
        symbols: syms,
        heartRate: null,
        sdnn: null,
        rmssd: null,
        pnn50: null,
        beatCount: n,
        pvcCount: 0,
        apcCount: 0,
        bigeminy: false,
        irregular: false,
        duration: dur,
        findings: findings,
      );
    }

    final rr = <double>[
      for (int i = 1; i < n; i++) (peaks[i] - peaks[i - 1]) / fs
    ];
    final sortedRR = List<double>.from(rr)..sort();
    final medRR = sortedRR[sortedRR.length ~/ 2];
    final meanRR = _mean(rr);
    final cvAll = meanRR == 0 ? 0.0 : _std(rr) / meanRR;
    final shortCount = rr.where((v) => v < 0.8 * medRR).length;
    final vCount0 = syms.where((e) => e == 'V').length;
    final aCount0 = syms.where((e) => e == 'A').length;

    final afLike = n >= 10 &&
        cvAll > 0.18 &&
        vCount0 <= 0.1 * n &&
        aCount0 <= 0.1 * n &&
        shortCount >= 0.2 * rr.length;

    // Timing-based premature narrow-complex beats (when not annotated).
    if (!annotated && !afLike) {
      for (int i = 1; i < n; i++) {
        if (rr[i - 1] < 0.8 * medRR && syms[i] == 'N') syms[i] = 'A';
      }
    }

    final pvc = syms.where((e) => e == 'V').length;
    final apc = syms.where((e) => e == 'A').length;

    // Bigeminy: N, X, N, X, N, X
    bool bigeminy = false;
    for (int i = 0; i + 5 < n; i++) {
      if (syms[i] == 'N' &&
          syms[i + 1] != 'N' &&
          syms[i + 2] == 'N' &&
          syms[i + 3] != 'N' &&
          syms[i + 4] == 'N' &&
          syms[i + 5] != 'N') {
        bigeminy = true;
        break;
      }
    }

    // HRV on normal-to-normal intervals.
    final nn = <double>[];
    for (int i = 1; i < n; i++) {
      if (syms[i] == 'N' && syms[i - 1] == 'N') nn.add(rr[i - 1]);
    }
    final basis = nn.length >= 3 ? nn : rr;
    final sdnn = _std(basis) * 1000;

    final diffs = <double>[];
    for (int i = 2; i < n; i++) {
      if (syms[i] == 'N' && syms[i - 1] == 'N' && syms[i - 2] == 'N') {
        diffs.add((rr[i - 1] - rr[i - 2]).abs());
      }
    }
    double? rmssd;
    double? pnn50;
    if (diffs.length >= 2) {
      rmssd = math.sqrt(_mean(diffs.map((d) => d * d).toList())) * 1000;
      pnn50 = diffs.where((d) => d > 0.05).length / diffs.length * 100;
    }

    final hr = meanRR > 0 ? 60 / meanRR : null;

    // ---- Findings ----
    if (hr != null) {
      if (hr < 50) {
        findings.add(Finding('Marked slow heart rate · ${hr.round()} bpm',
            'Rate is well below 60 bpm (bradycardia range).', 2));
      } else if (hr < 60) {
        findings.add(Finding(
            'Slow heart rate · ${hr.round()} bpm',
            'Rate is just under 60 bpm. Common in athletes or during sleep.',
            1));
      } else if (hr > 120) {
        findings.add(Finding('Marked fast heart rate · ${hr.round()} bpm',
            'Rate is well above 100 bpm (tachycardia range).', 2));
      } else if (hr > 100) {
        findings.add(Finding('Fast heart rate · ${hr.round()} bpm',
            'Rate is above 100 bpm (tachycardia range).', 1));
      } else {
        findings.add(Finding('Heart rate in normal range · ${hr.round()} bpm',
            'Average rate is within 60–100 bpm.', 0));
      }

      // Cross-check the reported BPM against the measured ECG.
      if (reportedBpm != null && s.measured) {
        final diff = (hr - reportedBpm).abs();
        if (diff > math.max(10, 0.15 * reportedBpm)) {
          findings.add(Finding(
            'Reported rate differs from ECG',
            'Reported ${reportedBpm.round()} bpm, but this ECG segment '
                'averages ${hr.round()} bpm. Activity level, ectopic beats '
                'or beat-detection errors can explain a gap.',
            1,
          ));
        } else {
          findings.add(Finding(
            'Reported rate matches ECG',
            'Reported ${reportedBpm.round()} bpm vs ${hr.round()} bpm '
                'measured on this segment.',
            0,
          ));
        }
      }
    }

    if (afLike) {
      findings.add(const Finding(
        'Irregularly irregular rhythm',
        'RR intervals vary widely without a repeating pattern, which can be '
            'seen in atrial fibrillation. A 12-lead ECG and clinician review '
            'are needed to confirm.',
        2,
      ));
    } else if (bigeminy) {
      findings.add(const Finding(
        'Bigeminy pattern',
        'Every second beat is premature or abnormal. Needs clinical '
            'correlation.',
        2,
      ));
    } else if (pvc == 0 && apc == 0 && cvAll < 0.12) {
      findings.add(const Finding(
        'Regular rhythm',
        'Beat-to-beat intervals are consistent; no premature beats were '
            'detected in this segment.',
        0,
      ));
    }

    if (pvc > 0) {
      final frequent = pvc >= 3 || pvc > 0.1 * n;
      findings.add(Finding(
        'Wide-complex premature beats ($pvc of $n)',
        'Beats with a broad QRS arriving early may represent premature '
            'ventricular contractions (PVCs). '
            '${frequent ? 'Frequent ectopy warrants clinical review.' : 'Occasional PVCs are common.'}',
        frequent ? 2 : 1,
      ));
    }
    if (apc > 0) {
      findings.add(Finding(
        'Premature narrow-complex beats ($apc of $n)',
        'Early beats with a normal-width QRS may be atrial premature '
            'contractions. Usually benign but can trigger palpitations.',
        1,
      ));
    }

    findings.add(Finding(
      'Segment length',
      'Analysis covers ${dur.toStringAsFixed(1)} s ($n beats'
          '${annotated ? ', using annotated beat labels' : ', beats detected automatically'}'
          '). Short segments can miss intermittent events.',
      0,
    ));

    return EcgAnalysis(
      peaks: peaks,
      symbols: syms,
      heartRate: hr,
      sdnn: sdnn,
      rmssd: rmssd,
      pnn50: pnn50,
      beatCount: n,
      pvcCount: pvc,
      apcCount: apc,
      bigeminy: bigeminy,
      irregular: afLike,
      duration: dur,
      findings: findings,
    );
  }
}

// ============================================================
// RISK ENGINE (rule-based screening; NOT a diagnosis)
// ============================================================

class RiskEngine {
  static RiskReport assess(PatientProfile p, EcgAnalysis a) {
    double score = 0;
    final factors = <String>[];
    void add(double v, String why) {
      score += v;
      factors.add(why);
    }

    final age = p.age ?? 0;
    final sym = p.symptoms.toLowerCase();
    bool has(List<String> k) => k.any((w) => sym.contains(w));

    if (age >= 65) {
      add(2, 'Age 65 or older');
    } else if (age >= 50) {
      add(1, 'Age 50–64');
    }
    if (p.hypertension == 'Yes' || (p.systolic ?? 0) >= 140) {
      add(2, 'High blood pressure');
    }
    if (p.diabetes == 'Yes') add(1.5, 'Diabetes');
    if (p.smoking == 'Yes') {
      add(2, 'Current smoker');
    } else if (p.smoking == 'Former smoker') {
      add(0.5, 'Former smoker');
    }
    if (p.familyHistory == 'Yes') add(1, 'Family history of heart disease');
    final bmi = p.bmi;
    if (bmi != null && bmi >= 30) {
      add(1, 'BMI ${bmi.toStringAsFixed(1)} (obesity range)');
    } else if (bmi != null && bmi >= 25) {
      add(0.5, 'BMI ${bmi.toStringAsFixed(1)} (overweight range)');
    }
    if (p.oxygen != null && p.oxygen! < 94) {
      add(2, 'Low oxygen saturation (${p.oxygen!.toStringAsFixed(0)}%)');
    }
    if (has(['chest', 'faint', 'syncope', 'breathless', 'short of breath'])) {
      add(2, 'Concerning symptoms reported');
    } else if (has(['dizz', 'palpit', 'fatigue', 'swelling', 'skip'])) {
      add(1, 'Symptoms reported');
    }
    final hh = p.heartHistory.trim().toLowerCase();
    if (hh.isNotEmpty && hh != 'none' && hh != 'no' && hh != 'nil') {
      add(2, 'Existing heart condition');
    }
    if ((p.sleepHours ?? 7) < 5) add(0.5, 'Short sleep (<5 h)');

    final hr = a.heartRate ?? p.restingBpm;
    if (hr != null && (hr > 100 || hr < 50)) {
      add(1.5, 'Abnormal heart rate (${hr.round()} bpm)');
    }
    if (a.irregular) add(2, 'Irregular rhythm on ECG');
    if (a.pvcCount >= 2 || a.apcCount >= 3) {
      add(1.5, 'Frequent premature beats on ECG');
    }
    if (a.bigeminy) add(1, 'Bigeminy pattern on ECG');

    final level = score < 3 ? 'Low' : (score < 7 ? 'Moderate' : 'High');
    return RiskReport(score, level, factors, _conditions(p, a, has));
  }

  static String _lvl(int s, int possible, int elevated) =>
      s >= elevated ? 'Elevated' : (s >= possible ? 'Possible' : 'Low');

  static List<ConditionInsight> _conditions(
      PatientProfile p, EcgAnalysis a, bool Function(List<String>) has) {
    final out = <ConditionInsight>[];
    final age = p.age ?? 0;
    final hr = a.heartRate ?? p.restingBpm;
    final bmi = p.bmi;

    // Arrhythmia
    {
      int s = 0;
      final r = <String>[];
      if (a.irregular) {
        s += 3;
        r.add('irregular RR intervals');
      }
      if (a.bigeminy) {
        s += 2;
        r.add('bigeminy pattern');
      }
      if (a.pvcCount >= 2) {
        s += 2;
        r.add('${a.pvcCount} wide premature beats');
      } else if (a.pvcCount == 1) {
        s += 1;
        r.add('1 wide premature beat');
      }
      if (a.apcCount >= 3) {
        s += 1;
        r.add('${a.apcCount} early narrow beats');
      }
      if (has(['palpit', 'skip', 'flutter', 'faint', 'syncope'])) {
        s += 1;
        r.add('palpitation-type symptoms');
      }
      out.add(ConditionInsight(
        'Cardiac arrhythmia',
        _lvl(s, 2, 4),
        r.isEmpty ? 'No rhythm irregularities detected.' : r.join(', '),
      ));
    }

    // Rate disorders
    if (hr != null) {
      String l = 'Low';
      String why = 'Average rate ${hr.round()} bpm is within 60–100.';
      if (hr < 50 || hr > 120) {
        l = 'Elevated';
        why = 'Average rate ${hr.round()} bpm is well outside 60–100.';
      } else if (hr < 60 || hr > 100) {
        l = 'Possible';
        why = 'Average rate ${hr.round()} bpm is outside 60–100.';
      }
      out.add(ConditionInsight('Bradycardia / tachycardia', l, why));
    }

    // Hypertensive heart strain
    {
      int s = 0;
      final r = <String>[];
      if (p.hypertension == 'Yes') {
        s += 2;
        r.add('hypertension history');
      }
      final sys = p.systolic ?? 0;
      if (sys >= 160) {
        s += 2;
        r.add('systolic BP $sys mmHg');
      } else if (sys >= 140) {
        s += 1;
        r.add('systolic BP $sys mmHg');
      }
      if (age >= 60) {
        s += 1;
        r.add('age 60+');
      }
      if (p.diabetes == 'Yes') {
        s += 1;
        r.add('diabetes');
      }
      out.add(ConditionInsight(
        'Hypertensive heart disease',
        _lvl(s, 2, 4),
        r.isEmpty ? 'No contributing factors identified.' : r.join(', '),
      ));
    }

    // Coronary artery disease risk
    {
      int s = 0;
      final r = <String>[];
      if (age >= 55) {
        s += 1;
        r.add('age 55+');
      }
      if (p.sex == 'Male') {
        s += 1;
        r.add('male sex');
      }
      if (p.smoking == 'Yes') {
        s += 2;
        r.add('smoking');
      }
      if (p.diabetes == 'Yes') {
        s += 1;
        r.add('diabetes');
      }
      if (p.hypertension == 'Yes') {
        s += 1;
        r.add('hypertension');
      }
      if (p.familyHistory == 'Yes') {
        s += 1;
        r.add('family history');
      }
      if (bmi != null && bmi >= 30) {
        s += 1;
        r.add('obesity');
      }
      if (has(['chest'])) {
        s += 2;
        r.add('chest discomfort');
      }
      out.add(ConditionInsight(
        'Coronary artery disease',
        _lvl(s, 3, 6),
        r.isEmpty ? 'No contributing factors identified.' : r.join(', '),
      ));
    }

    // Heart failure
    {
      int s = 0;
      final r = <String>[];
      if (has(['breathless', 'short of breath', 'swelling'])) {
        s += 2;
        r.add('breathlessness / swelling');
      } else if (has(['fatigue'])) {
        s += 1;
        r.add('fatigue');
      }
      if (age >= 65) {
        s += 1;
        r.add('age 65+');
      }
      if (p.hypertension == 'Yes') {
        s += 1;
        r.add('hypertension');
      }
      if (p.diabetes == 'Yes') {
        s += 1;
        r.add('diabetes');
      }
      if (p.oxygen != null && p.oxygen! < 94) {
        s += 1;
        r.add('low oxygen');
      }
      if (p.heartHistory.toLowerCase().contains('failure')) {
        s += 3;
        r.add('prior heart failure');
      }
      out.add(ConditionInsight(
        'Heart failure',
        _lvl(s, 3, 5),
        r.isEmpty ? 'No contributing factors identified.' : r.join(', '),
      ));
    }

    // Oxygenation
    if (p.oxygen != null) {
      final o = p.oxygen!;
      out.add(ConditionInsight(
        'Low blood oxygen',
        o < 90 ? 'Elevated' : (o < 94 ? 'Possible' : 'Low'),
        'Reported SpO₂ ${o.toStringAsFixed(0)}%.',
      ));
    }

    return out;
  }
}

// ============================================================
// CASE SERVICE
// ============================================================

class CaseService {
  static Future<PatientCase> build(PatientProfile p) async {
    EcgSignal? sig;

    // 1) ECG samples supplied by the patient.
    if (p.hasUserEcg) {
      try {
        sig = EcgApi.fromUser(p.ecgSamples!, p.ecgFs, p.ecgUnit);
      } catch (_) {
        sig = null;
      }
    }

    // 2) MIT-BIH record (backend, else simulated at the record's rhythm/BPM).
    if (sig == null && p.recordId != null) {
      try {
        sig = await EcgApi.fetchEcg(record: p.recordId);
      } catch (_) {
        final rec = MitbihCatalog.cached(p.recordId!);
        sig = EcgSimulator.generate(
          bpm: p.restingBpm ?? rec?.bpm ?? 75,
          rhythm: rec?.rhythm ?? Rhythm.normal,
          seed: int.tryParse(p.recordId!) ?? 7,
          source: 'SIMULATED · MIT-BIH record ${p.recordId} rhythm '
              '(backend unavailable)',
          recordId: p.recordId,
        );
      }
    }

    // 3) Simulation at the BPM the patient entered.
    sig ??= EcgSimulator.forProfile(p);

    final analysis = EcgAnalyzer.analyze(sig, reportedBpm: p.restingBpm);
    final risk = RiskEngine.assess(p, analysis);
    return PatientCase(p, sig, analysis, risk);
  }
}

// ============================================================
// DEMO PATIENTS (doctor's hard-coded list)
// ============================================================

List<PatientProfile> demoPatients() => [
      PatientProfile(
        id: 'demo-1',
        name: 'Rohan Deshmukh',
        age: 69,
        sex: 'Male',
        heightCm: 172,
        weightKg: 78,
        restingBpm: 75,
        bloodPressure: '148/92 mmHg',
        oxygen: 96,
        sleepHours: 6,
        activity: 'Light walking, 20 min daily',
        heartHistory: 'Hypertension; occasional atrial premature beats',
        medications: 'Aldomet, Inderal',
        allergies: 'Penicillin',
        symptoms: 'Occasional palpitations',
        diabetes: 'No',
        hypertension: 'Yes',
        familyHistory: 'Yes',
        smoking: 'Former smoker',
        recordId: '100',
      ),
      PatientProfile(
        id: 'demo-2',
        name: 'Ananya Kulkarni',
        age: 24,
        sex: 'Female',
        heightCm: 163,
        weightKg: 56,
        restingBpm: 78,
        bloodPressure: '110/70 mmHg',
        oxygen: 99,
        sleepHours: 7,
        activity: 'Yoga 3 times a week',
        heartHistory: 'Frequent PVCs found on a routine check-up',
        medications: 'None',
        allergies: 'None',
        symptoms: 'Skipped beats, mild dizziness',
        diabetes: 'No',
        hypertension: 'No',
        familyHistory: 'Unknown',
        smoking: 'No',
        recordId: '106',
      ),
      PatientProfile(
        id: 'demo-3',
        name: 'Meera Joshi',
        age: 51,
        sex: 'Female',
        heightCm: 158,
        weightKg: 71,
        restingBpm: 70,
        bloodPressure: '136/86 mmHg',
        oxygen: 95,
        sleepHours: 5,
        activity: 'Mostly sedentary',
        heartHistory: 'Ventricular bigeminy under observation',
        medications: 'Metoprolol 25 mg',
        allergies: 'None known',
        symptoms: 'Fatigue, chest discomfort on exertion',
        diabetes: 'Yes',
        hypertension: 'Yes',
        familyHistory: 'Yes',
        smoking: 'No',
        recordId: '119',
      ),
      PatientProfile(
        id: 'demo-4',
        name: 'Sunil Patil',
        age: 64,
        sex: 'Male',
        heightCm: 168,
        weightKg: 86,
        restingBpm: 82,
        bloodPressure: '152/96 mmHg',
        oxygen: 93,
        sleepHours: 5,
        activity: 'None',
        heartHistory: 'Prior ventricular ectopy; type 2 diabetes',
        medications: 'Amlodipine, Metformin',
        allergies: 'Sulfa drugs',
        symptoms: 'Breathlessness on stairs, ankle swelling',
        diabetes: 'Yes',
        hypertension: 'Yes',
        familyHistory: 'Yes',
        smoking: 'Yes',
        recordId: '200',
      ),
    ];

// ============================================================
// LIVE PLAYBACK (shared clock for ECG trace + beating heart)
// ============================================================

class EcgPlayback {
  EcgPlayback(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick)..start();
  }

  late final Ticker _ticker;
  EcgSignal signal =
      EcgSignal(samples: [0.0, 0.0], fs: 360, source: '', measured: false);
  List<int> peaks = const [];
  List<String> symbols = const [];
  double lo = -1;
  double hi = 1;
  bool paused = false;

  final ValueNotifier<double> head = ValueNotifier<double>(0);
  final ValueNotifier<double> pulse = ValueNotifier<double>(5);

  double _pos = 0;
  int _next = 0;
  double _sinceBeat = 5;
  Duration _last = Duration.zero;

  void load(EcgSignal s, List<int> p, List<String> sym) {
    signal = s;
    peaks = p;
    symbols = sym;
    _pos = 0;
    _next = 0;
    _sinceBeat = 5;
    head.value = 0;
    pulse.value = 5;

    final sorted = List<double>.from(s.samples)..sort();
    final lo0 = sorted[(sorted.length * 0.005).floor()];
    final hi0 = sorted[((sorted.length - 1) * 0.995).floor()];
    var span = hi0 - lo0;
    if (span < 0.2) span = 0.2;
    lo = lo0 - span * 0.15;
    hi = hi0 + span * 0.15;
  }

  void togglePause() => paused = !paused;

  void _fire() {
    _sinceBeat = math.max(0.0, (_pos - peaks[_next]) / signal.fs);
    _next++;
  }

  void _onTick(Duration elapsed) {
    var dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (paused || dt <= 0) return;
    if (dt > 0.1) dt = 0.1;

    final n = signal.samples.length;
    _sinceBeat += dt;
    _pos += dt * signal.fs;

    if (_pos >= n) {
      while (_next < peaks.length) {
        _fire();
      }
      _pos -= n;
      _next = 0;
    }
    while (_next < peaks.length && peaks[_next] <= _pos) {
      _fire();
    }

    head.value = _pos;
    pulse.value = _sinceBeat;
  }

  void dispose() {
    _ticker.dispose();
    head.dispose();
    pulse.dispose();
  }
}

// ============================================================
// LOGIN: DOCTOR OR PATIENT
// ============================================================

enum UserRole { doctor, patient }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole role = UserRole.patient;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (role == UserRole.doctor) {
      if (email.isEmpty || passwordController.text.isEmpty) {
        message('Enter your doctor email and password.');
        return;
      }
      final docName = email.contains('@') ? email.split('@').first : email;

      // Prototype-only navigation. No server authentication occurs.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorDashboard(doctorName: docName),
        ),
      );
    } else {
      if (name.isEmpty) {
        message('Enter your name to continue.');
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PatientProfileScreen(patientName: name),
        ),
      );
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF101629),
              Color(0xFF201333),
              Color(0xFF101629),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.monitor_heart_rounded,
                      size: 76,
                      color: cyanColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'HEART//TWIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'YOUR CARDIAC DIGITAL TWIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: cyanColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          roleButton(UserRole.patient, 'Patient'),
                          roleButton(UserRole.doctor, 'Doctor'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      role == UserRole.patient
                          ? 'Your health journey starts here.'
                          : 'Welcome to your clinical workspace.',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to the HEART//TWIN prototype.',
                      style: TextStyle(color: mutedColor),
                    ),
                    const SizedBox(height: 24),
                    if (role == UserRole.patient) ...[
                      TextField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email (optional)',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Doctor email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: obscure,
                        onSubmitted: (_) => login(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(
                              obscure ? Icons.visibility_off : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: login,
                        style: FilledButton.styleFrom(
                          backgroundColor: cyanColor,
                          foregroundColor: bgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          role == UserRole.patient
                              ? 'CONTINUE AS PATIENT'
                              : 'OPEN DOCTOR DASHBOARD',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'DEMO MODE · NOT A SECURE AUTHENTICATION SYSTEM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 9,
                        letterSpacing: 0.8,
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

  Widget roleButton(UserRole value, String label) {
    final active = role == value;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => role = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: active ? cyanColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? bgColor : mutedColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PATIENT INFORMATION FORM
// ============================================================

class PatientProfileScreen extends StatefulWidget {
  final String patientName;

  const PatientProfileScreen({
    super.key,
    required this.patientName,
  });

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController name;
  final recordId = TextEditingController();
  final age = TextEditingController();
  final height = TextEditingController();
  final weight = TextEditingController();
  final bpm = TextEditingController();
  final ecgText = TextEditingController();
  final ecgFs = TextEditingController(text: '360');
  final heartHistory = TextEditingController();
  final medications = TextEditingController();
  final allergies = TextEditingController();
  final symptoms = TextEditingController();
  final sleep = TextEditingController();
  final activity = TextEditingController();
  final bloodPressure = TextEditingController();
  final oxygen = TextEditingController();

  String sex = 'Prefer not to say';
  String smoking = 'No';
  String diabetes = 'No';
  String hypertension = 'No';
  String familyHistory = 'Unknown';
  String ecgUnit = 'auto';
  int ecgCount = 0;

  MitbihRecord? matched;
  bool lookingUp = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.patientName);
    MitbihCatalog.loadRemote();
  }

  @override
  void dispose() {
    name.dispose();
    recordId.dispose();
    age.dispose();
    height.dispose();
    weight.dispose();
    bpm.dispose();
    ecgText.dispose();
    ecgFs.dispose();
    heartHistory.dispose();
    medications.dispose();
    allergies.dispose();
    symptoms.dispose();
    sleep.dispose();
    activity.dispose();
    bloodPressure.dispose();
    oxygen.dispose();
    super.dispose();
  }

  void toast(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  bool _noRecord() => MitbihCatalog.normalizeId(recordId.text) == null;

  void applyRecord(MitbihRecord r, {required bool overwrite}) {
    setState(() {
      matched = r;
      recordId.text = r.id;
      age.text = r.age.toString();
      sex = r.sex;
      if (overwrite || bpm.text.trim().isEmpty) {
        bpm.text = r.bpm.round().toString();
      }
      if (overwrite || heartHistory.text.trim().isEmpty) {
        if (r.heartHistory.isNotEmpty) heartHistory.text = r.heartHistory;
      }
      if (overwrite || medications.text.trim().isEmpty) {
        if (r.medications.isNotEmpty) medications.text = r.medications;
      }
      if (overwrite || symptoms.text.trim().isEmpty) {
        if (r.symptoms.isNotEmpty) symptoms.text = r.symptoms;
      }
    });
  }

  Future<void> lookupRecord() async {
    final id = MitbihCatalog.normalizeId(recordId.text);
    if (id == null) {
      toast('Enter a MIT-BIH record number, e.g. 100.');
      return;
    }
    setState(() => lookingUp = true);
    final rec = await MitbihCatalog.resolve(id);
    if (!mounted) return;
    setState(() => lookingUp = false);

    if (rec == null) {
      toast('Record $id was not found in the dataset or backend.');
    } else {
      applyRecord(rec, overwrite: true);
      toast('Matched MIT-BIH record ${rec.id}. Details loaded.');
    }
  }

  Future<bool?> askMatch(MitbihRecord r) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panelColor,
        title: const Text('Matching MIT-BIH record found'),
        content: Text(
          'The age and sex you entered match MIT-BIH record ${r.id} '
          '(${r.age}, ${r.sex}, ~${r.bpm.round()} BPM).\n\nLoad its ECG and '
          'clinical details into your profile? Fields you already filled '
          'in are kept.',
          style: const TextStyle(color: mutedColor, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NO, KEEP MINE'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: cyanColor,
              foregroundColor: bgColor,
            ),
            child: const Text('USE RECORD'),
          ),
        ],
      ),
    );
  }

  Future<void> pasteEcg() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final t = data?.text ?? '';
    if (t.trim().isEmpty) {
      toast('Clipboard is empty.');
      return;
    }
    ecgText.text = t;
    setState(() => ecgCount = EcgText.parse(t).length);
  }

  @override
  Widget build(BuildContext context) {
    final fsNow = double.tryParse(ecgFs.text.trim()) ?? 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient onboarding'),
        backgroundColor: bgColor,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(
              Icons.health_and_safety_outlined,
              color: cyanColor,
              size: 44,
            ),
            const SizedBox(height: 12),
            const Text(
              'Build your patient profile',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This information drives your heartbeat simulation, ECG '
              'waveform and risk screening. Details stay in this app '
              'session and are shared only with the demo doctor view.',
              style: TextStyle(color: mutedColor, height: 1.5),
            ),
            const SizedBox(height: 24),
            sectionHeader('00 · MIT-BIH DATA MATCH (OPTIONAL)'),
            const SizedBox(height: 10),
            const Text(
              'If you are a test subject from the MIT-BIH Arrhythmia '
              'Database, enter the record number to load that record’s real '
              'ECG, heart rate and clinical details.',
              style: TextStyle(color: mutedColor, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: recordId,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      matched = null;
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      labelText: 'Record number',
                      hintText: 'e.g. 100',
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: lookingUp ? null : lookupRecord,
                    style: FilledButton.styleFrom(
                      backgroundColor: cyanColor,
                      foregroundColor: bgColor,
                    ),
                    child: lookingUp
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('LOOK UP'),
                  ),
                ),
              ],
            ),
            if (matched != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: greenColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: greenColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: greenColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Matched MIT-BIH record ${matched!.id} · '
                        '${matched!.age} · ${matched!.sex} · '
                        '${matched!.bpm.round()} BPM. Your dashboard will '
                        'use this record’s ECG unless you paste your own '
                        'samples below.',
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            sectionHeader('01 · GENERAL INFORMATION'),
            const SizedBox(height: 14),
            field(name, 'Full name', Icons.person_outline, requiredField: true),
            field(age, 'Age (years)', Icons.cake_outlined,
                numeric: true,
                requiredIf: _noRecord,
                min: 1,
                max: 120,
                integer: true),
            DropdownButtonFormField<String>(
              initialValue: sex,
              decoration: const InputDecoration(labelText: 'Sex'),
              items: const [
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
                DropdownMenuItem(
                  value: 'Prefer not to say',
                  child: Text('Prefer not to say'),
                ),
              ],
              onChanged: (v) => setState(() => sex = v!),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: field(height, 'Height (cm)', Icons.height,
                      numeric: true, min: 50, max: 250),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: field(
                      weight, 'Weight (kg)', Icons.monitor_weight_outlined,
                      numeric: true, min: 2, max: 400),
                ),
              ],
            ),
            const SizedBox(height: 24),
            sectionHeader('02 · HEART RATE & ECG'),
            const SizedBox(height: 10),
            const Text(
              'Your resting heart rate sets the speed of your beating-heart '
              'simulation. If you also have ECG samples, paste them and the '
              'real waveform is analysed. Without samples, a clearly '
              'labelled simulated ECG is drawn at your BPM.',
              style: TextStyle(color: mutedColor, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 14),
            field(bpm, 'Resting heart rate (BPM)', Icons.favorite_outline,
                numeric: true,
                integer: true,
                min: 30,
                max: 220,
                requiredIf: _noRecord,
                hint: 'e.g. 72'),
            TextFormField(
              controller: ecgText,
              keyboardType: TextInputType.multiline,
              minLines: 4,
              maxLines: 6,
              onChanged: (t) =>
                  setState(() => ecgCount = EcgText.parse(t).length),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                final vals = EcgText.parse(t);
                final fs = double.tryParse(ecgFs.text.trim()) ?? 360;
                final need = (2 * fs).round();
                if (vals.length < need) {
                  return 'Found ${vals.length} numeric samples; need at '
                      'least $need (2 s at ${fs.round()} Hz).';
                }
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'ECG samples (optional)',
                hintText: 'Paste values separated by commas, spaces or '
                    'new lines, or a CSV export',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 70),
                  child: Icon(Icons.show_chart),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: pasteEcg,
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: const Text('PASTE'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: ecgText.text.isEmpty
                      ? null
                      : () {
                          ecgText.clear();
                          setState(() => ecgCount = 0);
                        },
                  child: const Text('CLEAR'),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ecgCount == 0
                        ? 'No samples yet'
                        : '$ecgCount samples · '
                            '${(ecgCount / fsNow).toStringAsFixed(1)} s '
                            '@ ${fsNow.round()} Hz',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: ecgCount >= 2 * fsNow ? greenColor : mutedColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: field(
                      ecgFs, 'Sampling rate (Hz)', Icons.timer_outlined,
                      numeric: true,
                      min: 50,
                      max: 2000,
                      onChanged: () => setState(() {})),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: ecgUnit,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'ECG unit'),
                    items: const [
                      DropdownMenuItem(value: 'auto', child: Text('Auto')),
                      DropdownMenuItem(value: 'mv', child: Text('mV')),
                      DropdownMenuItem(
                          value: 'adc', child: Text('Raw ADC (÷200)')),
                    ],
                    onChanged: (v) => setState(() => ecgUnit = v ?? 'auto'),
                  ),
                ),
              ],
            ),
            const Text(
              'MIT-BIH data is sampled at 360 Hz. For a multi-column CSV an '
              'increasing first column is treated as the sample index and '
              'the second column is used as the ECG lead.',
              style: TextStyle(color: mutedColor, fontSize: 11, height: 1.5),
            ),
            const SizedBox(height: 24),
            sectionHeader('03 · HEALTH MEASUREMENTS'),
            const SizedBox(height: 14),
            field(bloodPressure, 'Blood pressure (optional)', Icons.speed,
                hint: 'e.g. 120/80 mmHg'),
            field(oxygen, 'Oxygen saturation % (optional)', Icons.air,
                numeric: true, hint: 'e.g. 98', min: 50, max: 100),
            field(sleep, 'Average sleep (hours/night)', Icons.bedtime_outlined,
                numeric: true, min: 0, max: 24),
            field(activity, 'Physical activity', Icons.directions_walk_outlined,
                hint: 'e.g. 30 minutes of walking daily'),
            const SizedBox(height: 24),
            sectionHeader('04 · MEDICAL HISTORY'),
            const SizedBox(height: 14),
            field(heartHistory, 'Heart conditions / previous procedures',
                Icons.monitor_heart_outlined,
                maxLines: 3, hint: 'Enter details or write None'),
            field(medications, 'Current medications', Icons.medication_outlined,
                maxLines: 2, hint: 'Names and doses, if known'),
            field(allergies, 'Allergies', Icons.warning_amber_outlined,
                maxLines: 2, hint: 'Include known medication allergies'),
            field(symptoms, 'Current symptoms', Icons.notes_outlined,
                maxLines: 3, hint: 'e.g. fatigue, dizziness, chest discomfort'),
            const SizedBox(height: 12),
            dropdown(
              'Diabetes history',
              diabetes,
              ['No', 'Yes', 'Unknown'],
              (v) => setState(() => diabetes = v),
            ),
            const SizedBox(height: 14),
            dropdown(
              'High blood pressure history',
              hypertension,
              ['No', 'Yes', 'Unknown'],
              (v) => setState(() => hypertension = v),
            ),
            const SizedBox(height: 14),
            dropdown(
              'Family history of heart disease',
              familyHistory,
              ['No', 'Yes', 'Unknown'],
              (v) => setState(() => familyHistory = v),
            ),
            const SizedBox(height: 14),
            dropdown(
              'Do you currently smoke?',
              smoking,
              ['No', 'Yes', 'Former smoker', 'Prefer not to say'],
              (v) => setState(() => smoking = v),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF251B32),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: pinkColor.withValues(alpha: 0.35),
                ),
              ),
              child: const Text(
                'Important: This is a research prototype. Entered '
                'measurements are self-reported, not independently verified. '
                'The app does not diagnose conditions or provide emergency '
                'medical advice.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: saving ? null : continueToDashboard,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: const Text('SAVE PROFILE & CONTINUE'),
                style: FilledButton.styleFrom(
                  backgroundColor: cyanColor,
                  foregroundColor: bgColor,
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget sectionHeader(String text) => Text(
        text,
        style: const TextStyle(
          color: cyanColor,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      );

  static String _n(double x) =>
      x == x.roundToDouble() ? x.toInt().toString() : x.toString();

  Widget field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool numeric = false,
    bool requiredField = false,
    bool Function()? requiredIf,
    bool integer = false,
    double? min,
    double? max,
    int maxLines = 1,
    String? hint,
    VoidCallback? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: numeric
            ? TextInputType.numberWithOptions(decimal: !integer)
            : TextInputType.text,
        maxLines: maxLines,
        onChanged: onChanged == null ? null : (_) => onChanged(),
        validator: (v) {
          final t = v?.trim() ?? '';
          if (t.isEmpty) {
            final req = requiredField || (requiredIf?.call() ?? false);
            return req ? 'This field is required' : null;
          }
          if (numeric) {
            final n = double.tryParse(t);
            if (n == null) return 'Enter a number';
            if (min != null && n < min) return 'Must be at least ${_n(min)}';
            if (max != null && n > max) return 'Must be at most ${_n(max)}';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Widget dropdown(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values.map((v) {
        return DropdownMenuItem(value: v, child: Text(v));
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Future<void> continueToDashboard() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);

    // Match against MIT-BIH data if the user has not already done so.
    if (matched == null) {
      final id = MitbihCatalog.normalizeId(recordId.text);
      if (id != null) {
        final r = await MitbihCatalog.resolve(id);
        if (!mounted) return;
        if (r == null) {
          setState(() => saving = false);
          toast('Record $id was not found. Clear the record number or '
              'check the backend.');
          return;
        }
        applyRecord(r, overwrite: true);
      } else {
        final a = int.tryParse(age.text.trim());
        if (a != null) {
          final m = MitbihCatalog.findByDemographics(a, sex,
              bpm: double.tryParse(bpm.text.trim()));
          if (m.isNotEmpty) {
            final use = await askMatch(m.first);
            if (!mounted) return;
            if (use == true) applyRecord(m.first, overwrite: false);
          }
        }
      }
    }

    if (!mounted) return;

    // Patient-supplied ECG samples.
    List<double>? ecg;
    final fsv = double.tryParse(ecgFs.text.trim()) ?? 360;
    final raw = ecgText.text.trim();
    if (raw.isNotEmpty) {
      final v = EcgText.parse(raw);
      if (v.length >= (2 * fsv).round()) ecg = v;
    }

    final profile = PatientProfile(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: name.text.trim(),
      age: int.tryParse(age.text.trim()),
      sex: sex,
      heightCm: double.tryParse(height.text.trim()),
      weightKg: double.tryParse(weight.text.trim()),
      restingBpm: double.tryParse(bpm.text.trim()),
      ecgSamples: ecg,
      ecgFs: fsv,
      ecgUnit: ecgUnit,
      bloodPressure: bloodPressure.text.trim(),
      oxygen: double.tryParse(oxygen.text.trim()),
      sleepHours: double.tryParse(sleep.text.trim()),
      activity: activity.text.trim(),
      heartHistory: heartHistory.text.trim(),
      medications: medications.text.trim(),
      allergies: allergies.text.trim(),
      symptoms: symptoms.text.trim(),
      diabetes: diabetes,
      hypertension: hypertension,
      familyHistory: familyHistory,
      smoking: smoking,
      recordId: matched?.id ?? MitbihCatalog.normalizeId(recordId.text),
    );

    PatientStore.registered.add(profile);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDashboard(patient: profile),
      ),
    );
  }
}

// ============================================================
// SHARED DASHBOARD WIDGETS
// ============================================================

BoxDecoration panelDecoration() => BoxDecoration(
      color: panelColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    );

Widget sectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: mutedColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.5,
        ),
      ),
    );

Widget infoRow(String title, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(title, style: const TextStyle(color: mutedColor)),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );

Widget badge(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );

Color riskColor(String level) {
  switch (level) {
    case 'High':
    case 'Elevated':
      return pinkColor;
    case 'Moderate':
    case 'Possible':
      return amberColor;
    default:
      return greenColor;
  }
}

String fmt(double? v, [int d = 0]) => v == null ? '--' : v.toStringAsFixed(d);

void logout(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}

// ============================================================
// CASE BODY: heart simulation, ECG, metrics, findings, risk
// ============================================================

class CaseBody extends StatefulWidget {
  final PatientCase data;

  const CaseBody({super.key, required this.data});

  @override
  State<CaseBody> createState() => _CaseBodyState();
}

class _CaseBodyState extends State<CaseBody>
    with SingleTickerProviderStateMixin {
  late final EcgPlayback pb;
  bool showModel = false;

  @override
  void initState() {
    super.initState();
    pb = EcgPlayback(this);
    _load();
  }

  void _load() {
    final d = widget.data;
    pb.load(d.signal, d.analysis.peaks, d.analysis.symbols);
  }

  @override
  void didUpdateWidget(covariant CaseBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) _load();
  }

  @override
  void dispose() {
    pb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final p = d.profile;
    final a = d.analysis;
    final sig = d.signal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!sig.measured) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: amberColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: amberColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.science_outlined, color: amberColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Showing a SIMULATED waveform. ${sig.source}. Paste ECG '
                    'samples, enter a MIT-BIH record number, or connect the '
                    'backend to display real data.',
                    style: const TextStyle(fontSize: 12, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // ---------- Heart simulation ----------
        sectionTitle('CARDIAC DIGITAL TWIN'),
        Container(
          height: 290,
          padding: const EdgeInsets.all(12),
          decoration: panelDecoration(),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: showModel
                            ? const ModelViewer(
                                src: 'assets/models/heart.glb',
                                alt: '3D heart model',
                                autoRotate: true,
                                cameraControls: true,
                                backgroundColor: Color(0xFF192238),
                              )
                            : Container(
                                color: const Color(0xFF151D33),
                                child: CustomPaint(
                                  painter: HeartPainter(pb),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                      ),
                      if (!showModel)
                        Positioned(
                          left: 12,
                          top: 10,
                          child: Row(
                            children: [
                              const Icon(Icons.favorite,
                                  color: pinkColor, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${fmt(a.heartRate ?? p.restingBpm)} BPM',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!showModel)
                        const Positioned(
                          left: 12,
                          bottom: 10,
                          child: Text(
                            'BEAT-SYNCED TO ECG BELOW',
                            style: TextStyle(
                              color: cyanColor,
                              fontSize: 9,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => showModel = !showModel),
                icon: const Icon(Icons.view_in_ar),
                label: Text(
                  showModel ? 'SHOW BEATING HEART' : 'EXPLORE 3D MODEL',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ---------- ECG ----------
        sectionTitle('ECG WAVEFORM'),
        _ecgCard(d),
        const SizedBox(height: 22),

        // ---------- Metrics ----------
        sectionTitle('ECG METRICS'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            SummaryCard(
              title: 'HEART RATE',
              value: fmt(a.heartRate),
              subtitle: p.restingBpm == null
                  ? 'beats per minute'
                  : 'reported ${fmt(p.restingBpm)} bpm',
              icon: Icons.favorite_outline,
              color: pinkColor,
            ),
            SummaryCard(
              title: 'SDNN (HRV)',
              value: a.sdnn == null ? '--' : '${fmt(a.sdnn)} ms',
              subtitle: 'RR variability',
              icon: Icons.stacked_line_chart,
              color: cyanColor,
            ),
            SummaryCard(
              title: 'RMSSD',
              value: a.rmssd == null ? '--' : '${fmt(a.rmssd)} ms',
              subtitle: a.pnn50 == null
                  ? 'beat-to-beat change'
                  : 'pNN50 ${fmt(a.pnn50)}%',
              icon: Icons.show_chart,
              color: violetColor,
            ),
            SummaryCard(
              title: 'BEATS ANALYSED',
              value: '${a.beatCount}',
              subtitle:
                  '${a.duration.toStringAsFixed(1)} s @ ${sig.fs.round()} Hz',
              icon: Icons.timer_outlined,
              color: greenColor,
            ),
            SummaryCard(
              title: 'PREMATURE BEATS',
              value: '${a.pvcCount + a.apcCount}',
              subtitle: 'V: ${a.pvcCount} · A: ${a.apcCount}',
              icon: Icons.flash_on_outlined,
              color: amberColor,
            ),
            SummaryCard(
              title: 'RHYTHM',
              value: a.irregular
                  ? 'Irregular'
                  : (a.bigeminy ? 'Bigeminy' : 'Regular'),
              subtitle: 'automated screen',
              icon: Icons.graphic_eq,
              color: a.irregular || a.bigeminy ? pinkColor : cyanColor,
            ),
          ],
        ),
        const SizedBox(height: 22),

        // ---------- Findings ----------
        sectionTitle('ECG FINDINGS'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: panelDecoration(),
          child: Column(
            children: [
              for (final f in a.findings) _findingRow(f),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ---------- Risk ----------
        sectionTitle('RISK SCREENING (RULE-BASED)'),
        _riskCard(d),
        const SizedBox(height: 22),

        // ---------- Profile ----------
        sectionTitle('PROFILE'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: panelDecoration(),
          child: Column(
            children: [
              infoRow('Age', p.age?.toString() ?? ''),
              infoRow('Sex', p.sex),
              infoRow(
                  'Height', p.heightCm == null ? '' : '${fmt(p.heightCm)} cm'),
              infoRow(
                  'Weight', p.weightKg == null ? '' : '${fmt(p.weightKg)} kg'),
              infoRow('BMI', p.bmi == null ? '' : fmt(p.bmi, 1)),
              infoRow('Resting heart rate',
                  p.restingBpm == null ? '' : '${fmt(p.restingBpm)} bpm'),
              infoRow('ECG data', ecgSourceLabel(p)),
              infoRow('Blood pressure', p.bloodPressure),
              infoRow('Oxygen saturation',
                  p.oxygen == null ? '' : '${fmt(p.oxygen)}%'),
              infoRow('Sleep',
                  p.sleepHours == null ? '' : '${fmt(p.sleepHours, 1)} hours'),
              infoRow('Physical activity', p.activity),
              if (p.recordId != null) infoRow('MIT-BIH record', p.recordId!),
            ],
          ),
        ),
        const SizedBox(height: 22),
        sectionTitle('DETAILED HEALTH HISTORY'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: panelDecoration(),
          child: Column(
            children: [
              infoRow('Heart history', p.heartHistory),
              infoRow('Medications', p.medications),
              infoRow('Allergies', p.allergies),
              infoRow('Current symptoms', p.symptoms),
              infoRow('Diabetes', p.diabetes),
              infoRow('Hypertension', p.hypertension),
              infoRow('Family heart history', p.familyHistory),
              infoRow('Smoking', p.smoking),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const PrototypeNotice(),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _ecgCard(PatientCase d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.signal.measured ? 'Recorded ECG' : 'Simulated ECG',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              badge(d.signal.measured ? 'MEASURED' : 'SIMULATED',
                  d.signal.measured ? greenColor : amberColor),
              IconButton(
                tooltip: pb.paused ? 'Play' : 'Pause',
                onPressed: () => setState(pb.togglePause),
                icon: Icon(pb.paused ? Icons.play_arrow : Icons.pause,
                    color: cyanColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            d.signal.source,
            style: const TextStyle(color: mutedColor, fontSize: 11),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: const Color(0xFF0E1527),
                child: CustomPaint(
                  painter: EcgMonitorPainter(pb: pb, windowSec: 5),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legend(cyanColor, 'Normal beat'),
              _legend(amberColor, 'Premature narrow (A)'),
              _legend(pinkColor, 'Wide / ventricular (V)'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Grid: small box = 0.04 s and 0.1 mV; large box = 0.2 s and '
            '0.5 mV. The trace is not rescaled per window, so amplitude and '
            'timing are preserved. Beat markers come from automated '
            'detection. This is not a diagnostic ECG.',
            style: TextStyle(color: mutedColor, fontSize: 10.5, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(color: mutedColor, fontSize: 11)),
        ],
      );

  Widget _findingRow(Finding f) {
    final color =
        f.level == 2 ? pinkColor : (f.level == 1 ? amberColor : greenColor);
    final icon = f.level == 2
        ? Icons.error_outline
        : (f.level == 1
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(f.detail,
                    style: const TextStyle(
                        color: mutedColor, fontSize: 12, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskCard(PatientCase d) {
    final r = d.risk;
    final color = riskColor(r.level);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Overall cardiovascular risk',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              badge('${r.level.toUpperCase()} RISK', color),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (r.score / 14).clamp(0.03, 1.0).toDouble(),
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          if (r.factors.isEmpty)
            const Text('No risk factors identified from the entered data.',
                style: TextStyle(color: mutedColor, fontSize: 12))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in r.factors)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(f, style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          const SizedBox(height: 18),
          const Text(
            'CONDITIONS TO DISCUSS WITH A CLINICIAN',
            style: TextStyle(
              color: mutedColor,
              fontSize: 10,
              letterSpacing: 1.3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          for (final c in r.conditions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(c.reason,
                            style: const TextStyle(
                                color: mutedColor, fontSize: 12, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  badge(c.likelihood.toUpperCase(), riskColor(c.likelihood)),
                ],
              ),
            ),
          const SizedBox(height: 4),
          const Text(
            'Scores come from simple transparent rules combining the '
            'profile with automated ECG measurements. They are screening '
            'hints, not diagnoses or validated risk predictions.',
            style: TextStyle(color: mutedColor, fontSize: 10.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PATIENT DASHBOARD
// ============================================================

class PatientDashboard extends StatefulWidget {
  final PatientProfile patient;

  const PatientDashboard({super.key, required this.patient});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  PatientCase? data;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final c = await CaseService.build(widget.patient);
      if (!mounted) return;
      setState(() => data = c);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not build your dashboard.')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MY HEART//TWIN'),
        backgroundColor: bgColor,
        actions: [
          IconButton(
            tooltip: 'Refresh ECG',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PATIENT DASHBOARD',
                  style: TextStyle(
                    color: cyanColor,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hello, ${p.name}',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.recordId != null
                      ? 'Linked to MIT-BIH record ${p.recordId}'
                      : 'Your profile and cardiac data overview',
                  style: const TextStyle(color: mutedColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (loading && data == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: cyanColor),
              ),
            )
          else if (data != null) ...[
            if (loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(color: cyanColor),
              ),
            CaseBody(data: data!),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// DOCTOR DASHBOARD
// ============================================================

class DoctorDashboard extends StatefulWidget {
  final String doctorName;

  const DoctorDashboard({super.key, this.doctorName = 'doctor'});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  late List<PatientProfile> patients;
  final Map<String, PatientCase> cases = {};
  bool loading = false;

  @override
  void initState() {
    super.initState();
    patients = [...demoPatients(), ...PatientStore.registered];
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() {
      loading = true;
      patients = [...demoPatients(), ...PatientStore.registered];
      cases.clear();
    });

    await Future.wait(patients.map((p) async {
      try {
        final c = await CaseService.build(p);
        if (!mounted) return;
        setState(() => cases[p.id] = c);
      } catch (_) {}
    }));

    if (mounted) setState(() => loading = false);
  }

  int get highRiskCount =>
      cases.values.where((c) => c.risk.level == 'High').length;

  int get measuredCount => cases.values.where((c) => c.signal.measured).length;

  @override
  Widget build(BuildContext context) {
    final sorted = [...patients]..sort((a, b) {
        final sa = cases[a.id]?.risk.score ?? -1;
        final sb = cases[b.id]?.risk.score ?? -1;
        return sb.compareTo(sa);
      });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text('HEART//TWIN · CLINICIAN'),
        actions: [
          IconButton(
            tooltip: 'Reload all ECGs',
            onPressed: loading ? null : loadAll,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CLINICAL WORKSPACE',
                  style: TextStyle(
                    color: cyanColor,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Dr. ${widget.doctorName}',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a patient to review their ECG, cardiac twin and '
                  'automated risk screening.',
                  style: TextStyle(color: mutedColor, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          sectionTitle('WORKSPACE SUMMARY'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              SummaryCard(
                title: 'MY PATIENTS',
                value: '${patients.length}',
                subtitle: 'under your care',
                icon: Icons.people_outline,
                color: cyanColor,
              ),
              SummaryCard(
                title: 'HIGH RISK',
                value: loading && cases.isEmpty ? '…' : '$highRiskCount',
                subtitle: 'need attention',
                icon: Icons.priority_high,
                color: pinkColor,
              ),
              SummaryCard(
                title: 'MEASURED ECG',
                value: loading && cases.isEmpty
                    ? '…'
                    : '$measuredCount/${patients.length}',
                subtitle: 'real data (not simulated)',
                icon: Icons.sensors,
                color: violetColor,
              ),
              const SummaryCard(
                title: 'ANALYSIS',
                value: 'Screening',
                subtitle: 'rule-based, not diagnostic',
                icon: Icons.analytics_outlined,
                color: amberColor,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: cyanColor),
                ),
            ],
          ),
          sectionTitle('PATIENT LIST · SORTED BY RISK'),
          for (final p in sorted) _patientTile(p),
          const SizedBox(height: 22),
          const PrototypeNotice(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _patientTile(PatientProfile p) {
    final c = cases[p.id];
    final initials = p.name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: c == null
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PatientAnalysisScreen(data: c),
                  ),
                ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: panelDecoration(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: cyanColor.withValues(alpha: 0.15),
                child: Text(initials,
                    style: const TextStyle(
                        color: cyanColor, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(
                      '${p.age ?? '--'} · ${p.sex}'
                      '${p.recordId != null ? ' · MIT-BIH ${p.recordId}' : ''}',
                      style: const TextStyle(color: mutedColor, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    if (c == null)
                      const Text('Loading ECG…',
                          style: TextStyle(color: mutedColor, fontSize: 12))
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          badge(
                              '${fmt(c.analysis.heartRate ?? p.restingBpm)} BPM',
                              cyanColor),
                          badge('${c.risk.level.toUpperCase()} RISK',
                              riskColor(c.risk.level)),
                          if (c.analysis.pvcCount + c.analysis.apcCount > 0)
                            badge(
                                '${c.analysis.pvcCount + c.analysis.apcCount} ECTOPIC',
                                amberColor),
                          if (!c.signal.measured)
                            badge('SIMULATED', mutedColor),
                        ],
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: c == null ? Colors.white24 : mutedColor),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DOCTOR: PATIENT ANALYSIS
// ============================================================

class PatientAnalysisScreen extends StatelessWidget {
  final PatientCase data;

  const PatientAnalysisScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final p = data.profile;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(p.name),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PATIENT ANALYSIS',
                  style: TextStyle(
                    color: cyanColor,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${p.age ?? '--'} years · ${p.sex}'
                  '${p.recordId != null ? ' · MIT-BIH record ${p.recordId}' : ''}',
                  style: const TextStyle(color: mutedColor),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    badge('${data.risk.level.toUpperCase()} RISK',
                        riskColor(data.risk.level)),
                    badge(
                        data.signal.measured ? 'MEASURED ECG' : 'SIMULATED ECG',
                        data.signal.measured ? greenColor : amberColor),
                    if (p.restingBpm != null)
                      badge('REPORTED ${fmt(p.restingBpm)} BPM', cyanColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          CaseBody(data: data),
        ],
      ),
    );
  }
}

// ============================================================
// SUMMARY CARDS
// ============================================================

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 9, color: mutedColor)),
          Text(subtitle,
              style: const TextStyle(fontSize: 10, color: mutedColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ============================================================
// ECG MONITOR PAINTER (scrolling, true time/amplitude grid)
// ============================================================

class EcgMonitorPainter extends CustomPainter {
  final EcgPlayback pb;
  final double windowSec;

  EcgMonitorPainter({required this.pb, required this.windowSec})
      : super(repaint: pb.head);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sig = pb.signal;
    final fs = sig.fs;
    final x = sig.samples;
    final n = x.length;
    if (n < 2 || w <= 0 || h <= 0) return;

    final win = math.min(windowSec, n / fs * 0.9);
    final wSamp = win * fs;
    final head = pb.head.value;
    final headT = head / fs;
    final pxPerSec = w / win;
    final span = pb.hi - pb.lo;

    double yOf(double v) => h * (1 - (v - pb.lo) / span);

    // ---- grid ----
    final small = Paint()
      ..color = const Color(0xFF26324E)
      ..strokeWidth = 0.5;
    final big = Paint()
      ..color = const Color(0xFF3A4C72)
      ..strokeWidth = 1.0;

    final k0 = ((headT - win) / 0.04).floor();
    final k1 = (headT / 0.04).ceil();
    for (int k = k0; k <= k1; k++) {
      final gx = w - (headT - k * 0.04) * pxPerSec;
      if (gx < 0 || gx > w) continue;
      canvas.drawLine(Offset(gx, 0), Offset(gx, h), k % 5 == 0 ? big : small);
    }

    double step = 0.1;
    while (span / step > 70) {
      step *= 5;
    }
    final m0 = (pb.lo / step).floor();
    final m1 = (pb.hi / step).ceil();
    for (int m = m0; m <= m1; m++) {
      final gy = yOf(m * step);
      if (gy < 0 || gy > h) continue;
      canvas.drawLine(Offset(0, gy), Offset(w, gy), m % 5 == 0 ? big : small);
    }

    // ---- trace ----
    final line = Paint()
      ..color = cyanColor
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final i0 = (head - wSamp).ceil();
    final i1 = head.floor();
    bool started = false;
    for (int i = i0; i <= i1; i++) {
      final idx = i < 0 ? i + n : i;
      if (idx < 0 || idx >= n) continue;
      final px = w - (head - i) * w / wSamp;
      final py = yOf(x[idx]);
      if (!started || i == 0) {
        path.moveTo(px, py);
        started = true;
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, line);

    // ---- beat markers ----
    for (int k = 0; k < pb.peaks.length; k++) {
      final p = pb.peaks[k];
      var d = head - p;
      if (d < 0) d += n;
      if (d > wSamp) continue;
      final px = w - d * w / wSamp;
      final py = yOf(x[p]);
      final sym = k < pb.symbols.length ? pb.symbols[k] : 'N';
      final color =
          sym == 'V' ? pinkColor : (sym == 'A' ? amberColor : cyanColor);

      canvas.drawCircle(Offset(px, py), 4, Paint()..color = color);
      canvas.drawCircle(
        Offset(px, py),
        7,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      if (sym != 'N') {
        final tp = TextPainter(
          text: TextSpan(
            text: sym,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w900),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(px - tp.width / 2, math.max(0, py - 24)));
      }
    }

    // ---- leading dot ----
    final hi = math.min(n - 1, math.max(0, head.floor()));
    canvas.drawCircle(
        Offset(w, yOf(x[hi])), 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant EcgMonitorPainter oldDelegate) => true;
}

// ============================================================
// BEATING HEART PAINTER
// ============================================================

Path buildHeartPath(Offset center, double scale) {
  return Path()
    ..moveTo(center.dx, center.dy + 45 * scale)
    ..cubicTo(
      center.dx - 80 * scale,
      center.dy - 10 * scale,
      center.dx - 65 * scale,
      center.dy - 75 * scale,
      center.dx - 25 * scale,
      center.dy - 62 * scale,
    )
    ..cubicTo(
      center.dx - 5 * scale,
      center.dy - 55 * scale,
      center.dx,
      center.dy - 35 * scale,
      center.dx,
      center.dy - 35 * scale,
    )
    ..cubicTo(
      center.dx + 25 * scale,
      center.dy - 80 * scale,
      center.dx + 80 * scale,
      center.dy - 55 * scale,
      center.dx + 65 * scale,
      center.dy - 10 * scale,
    )
    ..cubicTo(
      center.dx + 55 * scale,
      center.dy + 20 * scale,
      center.dx + 20 * scale,
      center.dy + 45 * scale,
      center.dx,
      center.dy + 45 * scale,
    )
    ..close();
}

class HeartPainter extends CustomPainter {
  final EcgPlayback pb;

  HeartPainter(this.pb) : super(repaint: pb.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final s = pb.pulse.value;

    // "Lub-dub" envelope: strong first sound, softer second.
    final lub = math.exp(-math.pow((s - 0.05) / 0.06, 2).toDouble());
    final dub = 0.55 * math.exp(-math.pow((s - 0.30) / 0.07, 2).toDouble());
    final env = (lub + dub).clamp(0.0, 1.2).toDouble();
    final envN = env.clamp(0.0, 1.0).toDouble();

    final center = Offset(size.width / 2, size.height * 0.5);
    final base = math.min(size.width, size.height) * 0.0062;
    final scale = base * (1 + 0.10 * env);

    // Expanding pulse ring.
    if (s < 0.7) {
      final t = s / 0.7;
      canvas.drawCircle(
        center,
        (55 + t * 120) * base,
        Paint()
          ..color = cyanColor.withValues(alpha: (1 - t) * 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final heart = buildHeartPath(center, scale);

    canvas.drawPath(
      heart,
      Paint()
        ..color = pinkColor.withValues(alpha: 0.18 + 0.30 * envN)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );
    canvas.drawPath(
      heart,
      Paint()..color = pinkColor.withValues(alpha: 0.10 + 0.18 * envN),
    );
    canvas.drawPath(
      heart,
      Paint()
        ..color = pinkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final pulse = Path()
      ..moveTo(center.dx - 38 * scale, center.dy - 22 * scale)
      ..lineTo(center.dx - 18 * scale, center.dy - 5 * scale)
      ..lineTo(center.dx - 6 * scale, center.dy - 35 * scale)
      ..lineTo(center.dx + 10 * scale, center.dy + 12 * scale)
      ..lineTo(center.dx + 24 * scale, center.dy - 5 * scale)
      ..lineTo(center.dx + 38 * scale, center.dy - 5 * scale);

    canvas.drawPath(
      pulse,
      Paint()
        ..color = cyanColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant HeartPainter oldDelegate) => true;
}

// ============================================================
// PROTOTYPE NOTICE
// ============================================================

class PrototypeNotice extends StatelessWidget {
  const PrototypeNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF251B32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pinkColor.withValues(alpha: 0.30),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: pinkColor),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Research prototype only. The 3D model is illustrative, '
              'the ECG may be a public sample or a simulation, and the '
              'displayed profile is not clinically verified. Risk '
              'screening uses simple rules, not a validated diagnostic '
              'algorithm. Do not use this app to make medical decisions.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
