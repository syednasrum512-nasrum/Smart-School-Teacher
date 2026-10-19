import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartSchoolTeacherApp());
}

class SmartSchoolTeacherApp extends StatelessWidget {
  const SmartSchoolTeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart School Teacher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087E8B)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SchoolHome(),
    );
  }
}

class SchoolHome extends StatefulWidget {
  const SchoolHome({super.key});

  @override
  State<SchoolHome> createState() => _SchoolHomeState();
}

class _SchoolHomeState extends State<SchoolHome> {
  int _tab = 0;
  bool _loading = true;
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> questions = [];
  List<Map<String, dynamic>> attendance = [];

  static const classes = [
    'نرسری', 'جماعت اول', 'جماعت دوم', 'جماعت سوم', 'جماعت چہارم',
    'جماعت پنجم', 'جماعت ششم', 'جماعت ہفتم', 'جماعت ہشتم'
  ];
  static const subjects = [
    'اردو', 'انگریزی', 'ریاضی', 'اسلامیات', 'جنرل نالج', 'سائنس', 'معاشرتی علوم'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      students = _decodeList(prefs.getString('students'));
      questions = _decodeList(prefs.getString('questions'));
      attendance = _decodeList(prefs.getString('attendance'));
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('students', jsonEncode(students));
    await prefs.setString('questions', jsonEncode(questions));
    await prefs.setString('attendance', jsonEncode(attendance));
    if (mounted) setState(() {});
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _studentDialog({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: existing?['name'] ?? '');
    final father = TextEditingController(text: existing?['father'] ?? '');
    final roll = TextEditingController(text: existing?['roll'] ?? '');
    final admission = TextEditingController(text: existing?['admission'] ?? '');
    final phone = TextEditingController(text: existing?['phone'] ?? '');
    String cls = existing?['class'] ?? classes[1];
    String section = existing?['section'] ?? 'A';
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
        title: Text(existing == null ? 'طالب علم شامل کریں' : 'ریکارڈ تبدیل کریں'),
        content: SizedBox(width: 440, child: SingleChildScrollView(
          child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'طالب علم کا نام *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'نام ضروری ہے' : null),
            TextField(controller: father, decoration: const InputDecoration(labelText: 'والد کا نام')),
            TextField(controller: roll, decoration: const InputDecoration(labelText: 'رول نمبر')),
            TextField(controller: admission, decoration: const InputDecoration(labelText: 'داخلہ نمبر')),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'رابطہ نمبر'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: cls, decoration: const InputDecoration(labelText: 'جماعت'),
              items: classes.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) => setDialog(() => cls = v ?? classes[1])),
            TextFormField(initialValue: section, decoration: const InputDecoration(labelText: 'سیکشن'),
              onChanged: (v) => section = v),
          ])),
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
          FilledButton(onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final record = <String, dynamic>{
              'id': existing?['id'] ?? _id(), 'name': name.text.trim(),
              'father': father.text.trim(), 'roll': roll.text.trim(),
              'admission': admission.text.trim(), 'phone': phone.text.trim(),
              'class': cls, 'section': section.trim(),
            };
            setState(() {
              if (existing == null) {
                students.add(record);
              } else {
                final i = students.indexWhere((s) => s['id'] == existing['id']);
                if (i >= 0) students[i] = record;
              }
            });
            await _save();
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('محفوظ کریں')),
        ],
      )),
    );
  }

  Future<void> _questionDialog() async {
    final text = TextEditingController();
    final chapter = TextEditingController();
    final answer = TextEditingController();
    final marks = TextEditingController(text: '1');
    String cls = classes[1], subject = subjects[0], type = 'MCQ';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
        title: const Text('سوال کی بینک میں سوال شامل کریں'),
        content: SizedBox(width: 450, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(value: cls, decoration: const InputDecoration(labelText: 'جماعت'),
            items: classes.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setDialog(() => cls = v ?? cls)),
          DropdownButtonFormField<String>(value: subject, decoration: const InputDecoration(labelText: 'مضمون'),
            items: subjects.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setDialog(() => subject = v ?? subject)),
          TextField(controller: chapter, decoration: const InputDecoration(labelText: 'سبق / باب')),
          DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'سوال کی قسم'),
            items: ['MCQ', 'درست / غلط', 'خالی جگہ پُر کریں', 'مختصر سوال', 'تفصیلی سوال']
              .map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setDialog(() => type = v ?? type)),
          TextField(controller: marks, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'نمبر')),
          TextField(controller: text, maxLines: 3, decoration: const InputDecoration(labelText: 'سوال *')),
          TextField(controller: answer, maxLines: 2, decoration: const InputDecoration(labelText: 'جواب (اختیاری)')),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
          FilledButton(onPressed: () async {
            if (text.text.trim().isEmpty) { _message('سوال کا متن درج کریں'); return; }
            setState(() => questions.add({
              'id': _id(), 'class': cls, 'subject': subject, 'chapter': chapter.text.trim(),
              'type': type, 'marks': int.tryParse(marks.text) ?? 1,
              'text': text.text.trim(), 'answer': answer.text.trim()
            }));
            await _save();
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('محفوظ کریں')),
        ],
      )),
    );
  }

  Future<void> _deleteStudent(Map<String, dynamic> s) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('ریکارڈ حذف کریں؟'),
      content: Text('کیا ${s['name']} کا ریکارڈ حذف کرنا چاہتے ہیں؟'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('نہیں')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف کریں'))],
    ));
    if (ok == true) { setState(() => students.removeWhere((x) => x['id'] == s['id'])); await _save(); }
  }

  Widget _dashboard() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Smart School Teacher', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    const Text('Teach Smart. Track Progress.'),
    const SizedBox(height: 16),
    Wrap(spacing: 12, runSpacing: 12, children: [
      _stat('کل طلبہ', students.length), _stat('محفوظ سوالات', questions.length), _stat('حاضری اندراجات', attendance.length),
    ]),
    const SizedBox(height: 16),
    const Card(child: Padding(padding: EdgeInsets.all(16), child: Text(
      'یہ ابتدائی Android ایپ ہے۔ پنجاب ٹیکسٹ بک بورڈ کے اصل سوالات ابھی شامل نہیں ہیں۔ کتابوں کی PDF ملنے پر سبق وار سوالات کی بینک تیار کی جائے گی۔',
      style: TextStyle(height: 1.6)))),
  ]);

  Widget _stat(String label, int value) => SizedBox(width: 155, child: Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label), const SizedBox(height: 8), Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))
    ]))));

  Widget _studentsPage() => Column(children: [
    Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      const Expanded(child: Text('طلبہ کا ریکارڈ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      FilledButton.icon(onPressed: () => _studentDialog(), icon: const Icon(Icons.person_add), label: const Text('نیا طالب علم')),
    ])),
    Expanded(child: students.isEmpty ? const Center(child: Text('ابھی کوئی طالب علم درج نہیں۔'))
      : ListView.builder(itemCount: students.length, itemBuilder: (ctx, i) {
        final s = students[i];
        return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: ListTile(
          leading: CircleAvatar(child: Text('${i + 1}')),
          title: Text('${s['name']}'),
          subtitle: Text('والد: ${s['father']} • ${s['class']} • رول: ${s['roll']}'),
          trailing: Wrap(spacing: 0, children: [
            IconButton(onPressed: () => _studentDialog(existing: s), icon: const Icon(Icons.edit_outlined)),
            IconButton(onPressed: () => _deleteStudent(s), icon: const Icon(Icons.delete_outline, color: Colors.red)),
          ]),
        ));
      })),
  ]);

  Widget _questionsPage() => Column(children: [
    Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      const Expanded(child: Text('سوالات کی بینک', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      FilledButton.icon(onPressed: _questionDialog, icon: const Icon(Icons.add), label: const Text('سوال شامل کریں')),
    ])),
    Expanded(child: questions.isEmpty ? const Center(child: Text('ابھی سوالات موجود نہیں۔'))
      : ListView.builder(itemCount: questions.length, itemBuilder: (ctx, i) {
        final q = questions[i];
        return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: ListTile(
          title: Text('${q['text']}'),
          subtitle: Text('${q['class']} • ${q['subject']} • ${q['chapter']} • ${q['type']} • ${q['marks']} نمبر'),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
            setState(() => questions.removeWhere((x) => x['id'] == q['id'])); await _save();
          }),
        ));
      })),
  ]);

  Widget _testPage() {
    final total = questions.fold<int>(0, (sum, q) => sum + ((q['marks'] as num?)?.toInt() ?? 0));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('ٹیسٹ بنانے کا نظام', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      const Text('فی الحال بینک میں موجود تمام سوالات کا خلاصہ دکھایا جا رہا ہے۔ اگلے مرحلے میں جماعت، مضمون، سبق، کل نمبر اور پرنٹ/PDF کے فلٹر شامل کیے جائیں گے۔'),
      const SizedBox(height: 14),
      Card(child: ListTile(title: const Text('سوالات کی تعداد'), trailing: Text('${questions.length}'))),
      Card(child: ListTile(title: const Text('تمام سوالات کے مجموعی نمبر'), trailing: Text('$total'))),
      const SizedBox(height: 8),
      ...questions.map((q) => Card(child: ListTile(title: Text('${q['text']}'), subtitle: Text('${q['class']} • ${q['subject']} • ${q['marks']} نمبر'))),
    ]);
  }

  Widget _attendancePage() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('حاضری', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    const Text('طلبہ شامل کرنے کے بعد اگلے مرحلے میں روزانہ حاضر، غیر حاضر اور رخصت کی مارکنگ شامل کی جائے گی۔'),
    const SizedBox(height: 12),
    if (students.isEmpty) const Text('پہلے طلبہ کے ریکارڈ شامل کریں۔'),
    ...students.map((s) => Card(child: ListTile(leading: const Icon(Icons.person_outline), title: Text('${s['name']}'), subtitle: Text('${s['class']}')))),
  ]);

  Widget _backupPage() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('بیک اَپ اور بحالی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    const Card(child: Padding(padding: EdgeInsets.all(16), child: Text(
      'یہ ورژن ڈیٹا کو اسی Android ڈیوائس کی ایپ میں محفوظ کرتا ہے۔ فائل کی صورت میں بیک اَپ/بحالی اگلے مرحلے میں شامل کی جائے گی۔ ایپ کا ڈیٹا حذف کرنے سے مقامی ریکارڈ ختم ہو سکتا ہے۔',
      style: TextStyle(height: 1.6)))),
    FilledButton.icon(onPressed: () => _message('ڈیٹا اسی ڈیوائس پر محفوظ ہے۔ فائل بیک اَپ فیچر اگلے مرحلے میں شامل ہوگا۔'),
      icon: const Icon(Icons.info_outline), label: const Text('ڈیٹا کی معلومات')),
  ]);

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _studentsPage(), _questionsPage(), _testPage(), _attendancePage(), _backupPage()];
    final titles = ['ڈیش بورڈ', 'طلبہ', 'سوالات کی بینک', 'ٹیسٹ بنائیں', 'حاضری', 'بیک اَپ'];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: Text(titles[_tab]), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      drawer: Drawer(child: SafeArea(child: Column(children: [
        const ListTile(title: Text('Smart School Teacher', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          subtitle: Text('Teach Smart. Track Progress.')),
        const Divider(),
        ...List.generate(titles.length, (i) => ListTile(
          leading: Icon([Icons.dashboard_outlined, Icons.people_outline, Icons.quiz_outlined, Icons.assignment_outlined, Icons.fact_check_outlined, Icons.backup_outlined][i]),
          title: Text(titles[i]), selected: _tab == i,
          onTap: () { setState(() => _tab = i); Navigator.pop(context); },
        )),
      ]))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'ہوم'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'طلبہ'),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), label: 'سوالات'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'ٹیسٹ'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'حاضری'),
          NavigationDestination(icon: Icon(Icons.backup_outlined), label: 'بیک اَپ'),
        ]),
    ));
  }
}
