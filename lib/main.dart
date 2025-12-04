import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// --- MAIN ENTRY ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // --- กรณีรันบนเว็บ (Web) ---
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyDrNr-tISlCjKDhjVFm32mWHQ-PcPPJFAA",
          authDomain: "gt7-tuner.firebaseapp.com",
          projectId: "gt7-tuner",
          storageBucket: "gt7-tuner.firebasestorage.app",
          messagingSenderId: "741464755928",
          appId: "1:741464755928:web:0e0bfee5ba9097204491ad",
          measurementId: "G-KCQ5P613NT",
      ),
    );
  } else {
    // --- กรณีรันบนมือถือ (Android/iOS) ---
    await Firebase.initializeApp();
  }

  runApp(const GT7CommunityApp());
}

class GT7CommunityApp extends StatelessWidget {
  const GT7CommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GT7 Tuning Club',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E1014), // สีพื้นหลัง GT7 (Dark Blue/Grey)
        primaryColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 20),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.black,
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
      home: const PostListPage(),
    );
  }
}

// --- LIST PAGE (หน้ารายการ) ---
class PostListPage extends StatelessWidget {
  const PostListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MY GARAGE')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostPage())),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tuning_posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('NO DATA', style: TextStyle(color: Colors.white54, letterSpacing: 2)));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final docId = snapshot.data!.docs[index].id;

              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailPage(data: data, docId: docId))),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2126),
                    border: Border(left: BorderSide(color: data['drivetrain'] == '4WD' ? Colors.blue : Colors.red, width: 4)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['car_model'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('PP ${data['pp'] ?? '-'}  |  ${data['horsepower'] ?? '-'} HP', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- DETAIL PAGE (หน้าดูรายละเอียด) ---
class PostDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const PostDetailPage({super.key, required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((data['car_model'] ?? 'SETTINGS').toUpperCase()),
        actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CreatePostPage(docId: docId, initialData: data))))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildGT7ReadonlySection('SUSPENSION', data['suspension']),
            _buildGT7ReadonlySection('DIFFERENTIAL GEAR', data['lsd']),
            _buildGT7ReadonlySection('AERODYNAMICS', data['aero']),
            _buildGT7ReadonlySection('PERFORMANCE', data['performance']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E2126),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("DRIVETRAIN", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text(data['drivetrain'] ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text("TIRES (F/R)", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text("${_shortTire(data['tires_front'])} / ${_shortTire(data['tires_rear'])}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  String _shortTire(String? t) => t?.replaceAll('Racing', 'RH').replaceAll('Sports', 'SH').replaceAll('Comfort', 'CH') ?? '-';

  Widget _buildGT7ReadonlySection(String title, Map<String, dynamic>? m) {
    if (m == null || m.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: Colors.black,
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        Container(
          color: const Color(0xFF16181C),
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: m.entries.map((e) {
              if (e.value is Map) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key.toUpperCase().replaceAll('_', ' '), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    Text(e.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// --- CREATE/EDIT PAGE (THE GT7 UI REPLICA) ---
class CreatePostPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initialData;
  const CreatePostPage({super.key, this.docId, this.initialData});
  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  // General
  final _carModel = TextEditingController();
  final _pp = TextEditingController();
  final _hp = TextEditingController();
  final _weight = TextEditingController();
  String _dt = 'FR';
  String _tf = 'Racing Hard';
  String _tr = 'Racing Hard';

  // Suspension
  final _sHeightF = TextEditingController(text: '100'); final _sHeightR = TextEditingController(text: '100');
  final _sAntiF = TextEditingController(text: '5'); final _sAntiR = TextEditingController(text: '5');
  final _sDampCompF = TextEditingController(text: '30'); final _sDampCompR = TextEditingController(text: '30');
  final _sDampExpF = TextEditingController(text: '40'); final _sDampExpR = TextEditingController(text: '40');
  final _sFreqF = TextEditingController(text: '2.50'); final _sFreqR = TextEditingController(text: '2.50');
  final _sCamberF = TextEditingController(text: '2.0'); final _sCamberR = TextEditingController(text: '1.0');
  final _sToeF = TextEditingController(text: '0.10'); final _sToeR = TextEditingController(text: '0.20');

  // Differential
  final _dInitF = TextEditingController(text: '0'); final _dInitR = TextEditingController(text: '10');
  final _dAccelF = TextEditingController(text: '0'); final _dAccelR = TextEditingController(text: '40');
  final _dBrakeF = TextEditingController(text: '0'); final _dBrakeR = TextEditingController(text: '20');

  // Aero
  final _aDownF = TextEditingController(text: '100'); final _aDownR = TextEditingController(text: '200');

  // ECU & Performance
  final _ecuOut = TextEditingController(text: '100');
  final _ballast = TextEditingController(text: '0');
  final _ballastPos = TextEditingController(text: '0');
  final _powerRest = TextEditingController(text: '100');
  final _topSpeed = TextEditingController(text: '300');

  final List<String> _tires = ['Racing Hard', 'Racing Medium', 'Racing Soft', 'Sports Hard', 'Sports Medium', 'Sports Soft', 'Comfort Hard', 'Comfort Medium', 'Comfort Soft'];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) _load(widget.initialData!);
  }

  void _load(Map<String, dynamic> d) {
    _carModel.text = d['car_model'] ?? ''; _dt = d['drivetrain'] ?? 'FR';
    _pp.text = '${d['pp']??''}'; _hp.text = '${d['horsepower']??''}'; _weight.text = '${d['weight']??''}';
    _tf = d['tires_front'] ?? 'Racing Hard'; _tr = d['tires_rear'] ?? 'Racing Hard';

    var s = d['suspension'] ?? {};
    _sHeightF.text = s['height_f']??''; _sHeightR.text = s['height_r']??'';
    _sAntiF.text = s['anti_f']??''; _sAntiR.text = s['anti_r']??'';
    _sDampCompF.text = s['damp_c_f']??''; _sDampCompR.text = s['damp_c_r']??'';
    _sDampExpF.text = s['damp_e_f']??''; _sDampExpR.text = s['damp_e_r']??'';
    _sFreqF.text = s['freq_f']??''; _sFreqR.text = s['freq_r']??'';
    _sCamberF.text = s['camber_f']??''; _sCamberR.text = s['camber_r']??'';
    _sToeF.text = s['toe_f']??''; _sToeR.text = s['toe_r']??'';

    var l = d['lsd'] ?? {};
    _dInitF.text = l['init_f']??''; _dInitR.text = l['init_r']??'';
    _dAccelF.text = l['accel_f']??''; _dAccelR.text = l['accel_r']??'';
    _dBrakeF.text = l['brake_f']??''; _dBrakeR.text = l['brake_r']??'';

    var a = d['aero'] ?? {};
    _aDownF.text = a['down_f']??''; _aDownR.text = a['down_r']??'';

    var p = d['performance'] ?? {};
    _ecuOut.text = p['ecu']??''; _ballast.text = p['ballast']??''; _ballastPos.text = p['ballast_pos']??''; _powerRest.text = p['restrictor']??'';
    _topSpeed.text = p['top_speed']??'';
  }

  Future<void> _save() async {
    if (_carModel.text.isEmpty) return;

    final data = {
      'car_model': _carModel.text, 'drivetrain': _dt,
      // 🟢 แก้ไข: ใช้ num.tryParse แทน int.tryParse เพื่อรองรับทศนิยม (Decimal)
      'pp': num.tryParse(_pp.text) ?? 0,
      'horsepower': num.tryParse(_hp.text) ?? 0,
      'weight': num.tryParse(_weight.text) ?? 0,

      'tires_front': _tf, 'tires_rear': _tr,
      'suspension': {
        'height_f': _sHeightF.text, 'height_r': _sHeightR.text,
        'anti_f': _sAntiF.text, 'anti_r': _sAntiR.text,
        'damp_c_f': _sDampCompF.text, 'damp_c_r': _sDampCompR.text,
        'damp_e_f': _sDampExpF.text, 'damp_e_r': _sDampExpR.text,
        'freq_f': _sFreqF.text, 'freq_r': _sFreqR.text,
        'camber_f': _sCamberF.text, 'camber_r': _sCamberR.text,
        'toe_f': _sToeF.text, 'toe_r': _sToeR.text,
      },
      'lsd': {
        'init_f': _dInitF.text, 'init_r': _dInitR.text,
        'accel_f': _dAccelF.text, 'accel_r': _dAccelR.text,
        'brake_f': _dBrakeF.text, 'brake_r': _dBrakeR.text,
      },
      'aero': {'down_f': _aDownF.text, 'down_r': _aDownR.text},
      'performance': {
        'ecu': _ecuOut.text, 'ballast': _ballast.text, 'ballast_pos': _ballastPos.text, 'restrictor': _powerRest.text, 'top_speed': _topSpeed.text
      },
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (widget.docId == null) await FirebaseFirestore.instance.collection('tuning_posts').add(data);
    else await FirebaseFirestore.instance.collection('tuning_posts').doc(widget.docId).update(data);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CAR SETTINGS SHEET'),
        actions: [TextButton(onPressed: _save, child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _buildCarHeader(),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildTiresSection()),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _buildAeroSection()),
              ],
            ),
            const SizedBox(height: 10),

            _buildSectionHeader("Suspension"),
            _gt7Row("Body Height Adj.", "mm", _sHeightF, _sHeightR),
            _gt7Row("Anti-Roll Bar", "Lv.", _sAntiF, _sAntiR),
            _gt7Row("Damping (Comp)", "%", _sDampCompF, _sDampCompR),
            _gt7Row("Damping (Exp)", "%", _sDampExpF, _sDampExpR),
            _gt7Row("Natural Freq.", "Hz", _sFreqF, _sFreqR),
            _gt7Row("Neg. Camber", "deg", _sCamberF, _sCamberR),
            _gt7Row("Toe Angle", "deg", _sToeF, _sToeR),

            const SizedBox(height: 10),

            _buildSectionHeader("Differential Gear"),
            _gt7Row("Initial Torque", "Lv.", _dInitF, _dInitR),
            _gt7Row("Accel Sensitivity", "Lv.", _dAccelF, _dAccelR),
            _gt7Row("Braking Sensitivity", "Lv.", _dBrakeF, _dBrakeR),

            const SizedBox(height: 10),

            _buildSectionHeader("Performance / ECU"),
            _gt7Single("ECU Output", "%", _ecuOut),
            _gt7Single("Ballast", "kg", _ballast),
            _gt7Single("Ballast Pos", "", _ballastPos),
            _gt7Single("Power Restrictor", "%", _powerRest),
            const SizedBox(height: 10),
            _gt7Single("Top Speed (Auto)", "km/h", _topSpeed),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---
  Widget _buildCarHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF16181C),
      child: Column(
        children: [
          TextField(controller: _carModel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), decoration: const InputDecoration(hintText: "Enter Car Name", filled: false, contentPadding: EdgeInsets.zero)),
          const SizedBox(height: 8),
          Row(
            children: [
              _headerInput("PP", _pp), const SizedBox(width: 10),
              _headerInput("HP", _hp), const SizedBox(width: 10),
              _headerInput("Kg", _weight), const SizedBox(width: 10),
              Expanded(child: DropdownButton<String>(
                value: _dt, dropdownColor: Colors.black, isExpanded: true, underline: Container(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                items: ['FR','FF','MR','RR','4WD'].map((e)=>DropdownMenuItem(value: e, child: Center(child: Text(e)))).toList(),
                onChanged: (v)=>setState(()=>_dt=v!),
              )),
            ],
          )
        ],
      ),
    );
  }
  Widget _headerInput(String label, TextEditingController c) => Expanded(child: Column(children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)), Container(height: 30, color: Colors.black, child: TextField(controller: c, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number))]));

  Widget _buildTiresSection() {
    return Container(
      padding: const EdgeInsets.all(8), color: const Color(0xFF16181C),
      child: Column(children: [
        const Align(alignment: Alignment.centerLeft, child: Text("Tyres", style: TextStyle(color: Colors.grey, fontSize: 12))),
        _tireDrop("Front", _tf, (v)=>setState(()=>_tf=v!)),
        const SizedBox(height: 4),
        _tireDrop("Rear", _tr, (v)=>setState(()=>_tr=v!)),
      ]),
    );
  }
  Widget _tireDrop(String l, String v, Function(String?) chg) => Row(children: [
    Text(l[0], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)), const SizedBox(width: 5),
    Expanded(child: Container(height: 28, color: Colors.black, padding: const EdgeInsets.only(left: 4), child: DropdownButtonHideUnderline(child: DropdownButton(value: v, isExpanded: true, dropdownColor: Colors.black, style: const TextStyle(fontSize: 11, color: Colors.white), items: _tires.map((t)=>DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: chg)))),
  ]);

  Widget _buildAeroSection() {
    return Container(
      padding: const EdgeInsets.all(8), color: const Color(0xFF16181C),
      child: Column(children: [
        const Align(alignment: Alignment.centerLeft, child: Text("Aerodynamics", style: TextStyle(color: Colors.grey, fontSize: 12))),
        Row(children: [
          Expanded(child: Column(children: [const Text("F", style: TextStyle(fontSize: 10, color: Colors.grey)), _gt7Input(_aDownF)])),
          const SizedBox(width: 4),
          Expanded(child: Column(children: [const Text("R", style: TextStyle(fontSize: 10, color: Colors.grey)), _gt7Input(_aDownR)])),
        ]),
      ]),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      width: double.infinity,
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const Text("Fully Customisable", style: TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _gt7Row(String label, String unit, TextEditingController f, TextEditingController r) {
    return Container(
      color: const Color(0xFF16181C),
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))),
          SizedBox(width: 30, child: Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: _gt7Input(f)),
          const SizedBox(width: 4),
          Expanded(flex: 2, child: _gt7Input(r)),
        ],
      ),
    );
  }

  Widget _gt7Single(String label, String unit, TextEditingController c) {
    return Container(
      color: const Color(0xFF16181C),
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))),
          SizedBox(width: 30, child: Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center)),
          Expanded(flex: 4, child: _gt7Input(c)),
        ],
      ),
    );
  }

  // 🟢 แก้ไข: ปรับกล่องข้อความให้ Font อยู่กึ่งกลางพอดี
  Widget _gt7Input(TextEditingController c) {
    return Container(
      height: 26,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      child: TextField(
        controller: c,
        textAlign: TextAlign.right,
        textAlignVertical: TextAlignVertical.center, // บังคับให้อยู่ตรงกลาง
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true, // ทำให้กล่องหดตัวพอดี
          contentPadding: EdgeInsets.zero, // ลบขอบในทิ้งให้หมด
          filled: false,
        ),
      ),
    );
  }
}