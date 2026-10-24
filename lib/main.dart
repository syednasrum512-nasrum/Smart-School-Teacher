import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'data/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B55)),
        useMaterial3: true,
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
  int _selectedIndex = 0;
  final _titles = const ['ڈیش بورڈ', 'طلبہ', 'حاضری', 'مزید', 'ترتیبات'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardPage(),
      const StudentsPage(),
      const AttendancePage(),
      const PlaceholderPage(
        title: 'بعد کے فیچرز',
        message: 'امتحانات، سوالات، نتائج اور رزلٹ کارڈ بعد کے مرحلے میں شامل کیے جائیں گے۔',
        icon: Icons.more_horiz,
      ),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Smart School Teacher • ${_titles[_selectedIndex]}'),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'ڈیش بورڈ'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'طلبہ'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'حاضری'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'مزید'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'ترتیبات'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<int> _studentCount() => AppDatabase.instance.countStudents();

  @override
  Widget build(BuildContext context) {
    final tiles = const [
      _FeatureInfo('طلبہ کا ریکارڈ', 'طلبہ شامل کریں، ترمیم کریں اور حذف کریں۔', Icons.people_alt_outlined),
      _FeatureInfo('حاضری', 'طلبہ کی روزانہ حاضری درج کریں۔', Icons.fact_check_outlined),
      _FeatureInfo('ڈیٹا بیک اپ', 'طلبہ اور حاضری کا ڈیٹا محفوظ کریں۔', Icons.backup_outlined),
      _FeatureInfo('آف لائن ڈیٹا', 'ریکارڈ فون میں محفوظ رہتا ہے۔', Icons.phone_android_outlined),
      _FeatureInfo('جماعت وار ریکارڈ', 'نرسری سے جماعت ہشتم تک۔', Icons.class_outlined),
      _FeatureInfo('اگلے مراحل', 'اسٹاف، ٹائم ٹیبل اور نوٹس بعد میں۔', Icons.more_horiz),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Smart School Teacher', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Teach Smart. Track Progress.'),
                const SizedBox(height: 16),
                FutureBuilder<int>(
                  future: _studentCount(),
                  builder: (context, snapshot) => Text(
                    'درج شدہ طلبہ: ${snapshot.data ?? 0}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final item = tiles[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, size: 30),
                    const SizedBox(height: 10),
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Expanded(child: Text(item.description, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const Text('ابتدائی ورژن: طلبہ کا ریکارڈ فعال ہے۔ باقی فیچرز اسی پروجیکٹ میں مرحلہ وار شامل ہوں گے۔'),
      ],
    );
  }
}

class _FeatureInfo {
  final String title;
  final String description;
  final IconData icon;
  const _FeatureInfo(this.title, this.description, this.icon);
}

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  String _className = 'جماعت اول';
  final _classes = const ['نرسری', 'جماعت اول', 'جماعت دوم', 'جماعت سوم', 'جماعت چہارم', 'جماعت پنجم', 'جماعت ششم', 'جماعت ہفتم', 'جماعت ہشتم'];
  late Future<List<Map<String, Object?>>> _students;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _students = AppDatabase.instance.getStudents(className: _className);
  }

  Future<void> _openStudentForm({Map<String, Object?>? student}) async {
    final name = TextEditingController(text: student?['name'] as String? ?? '');
    final father = TextEditingController(text: student?['father_name'] as String? ?? '');
    final roll = TextEditingController(text: student?['roll_no'] as String? ?? '');
    final admission = TextEditingController(text: student?['admission_no'] as String? ?? '');
    final phone = TextEditingController(text: student?['phone'] as String? ?? '');
    String formClass = student?['class_name'] as String? ?? _className;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(student == null ? 'نیا طالب علم' : 'طالب علم میں ترمیم'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: name, decoration: const InputDecoration(labelText: 'طالب علم کا نام *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'نام درج کریں' : null),
                    TextFormField(controller: father, decoration: const InputDecoration(labelText: 'والد کا نام')),
                    TextFormField(controller: roll, decoration: const InputDecoration(labelText: 'رول نمبر')),
                    TextFormField(controller: admission, decoration: const InputDecoration(labelText: 'داخلہ نمبر')),
                    TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'فون نمبر')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: formClass,
                      decoration: const InputDecoration(labelText: 'جماعت'),
                      items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setDialogState(() => formClass = v ?? formClass),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('منسوخ')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final record = <String, Object?>{
                  'name': name.text.trim(),
                  'father_name': father.text.trim(),
                  'roll_no': roll.text.trim(),
                  'admission_no': admission.text.trim(),
                  'phone': phone.text.trim(),
                  'class_name': formClass,
                };
                if (student == null) {
                  await AppDatabase.instance.insertStudent(record);
                } else {
                  await AppDatabase.instance.updateStudent(student['id'] as int, record);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              },
              child: const Text('محفوظ کریں'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _className = formClass;
        _reload();
      });
    }
  }

  Future<void> _deleteStudent(Map<String, Object?> student) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طالب علم حذف کریں؟'),
        content: Text('کیا آپ ${student['name']} کا ریکارڈ حذف کرنا چاہتے ہیں؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('نہیں')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف کریں')),
        ],
      ),
    );
    if (ok == true) {
      await AppDatabase.instance.deleteStudent(student['id'] as int);
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Text('جماعت:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _className,
                  items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() { _className = v ?? _className; _reload(); }),
                ),
              ),
              IconButton(onPressed: () => _openStudentForm(), icon: const Icon(Icons.person_add_alt_1), tooltip: 'نیا طالب علم'),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, Object?>>>(
            future: _students,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('ڈیٹا لوڈ نہیں ہو سکا: ${snapshot.error}'));
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) return const Center(child: Text('اس جماعت میں ابھی کوئی طالب علم درج نہیں۔ + سے نیا ریکارڈ شامل کریں۔', textAlign: TextAlign.center));
              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final s = rows[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(child: Text((s['name'] as String).isNotEmpty ? (s['name'] as String).characters.first : '?')),
                      title: Text(s['name'] as String),
                      subtitle: Text('والد: ${s['father_name']}  •  رول نمبر: ${s['roll_no']}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _openStudentForm(student: s);
                          if (v == 'delete') _deleteStudent(s);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('ترمیم')),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _classes = const ['نرسری', 'جماعت اول', 'جماعت دوم', 'جماعت سوم', 'جماعت چہارم', 'جماعت پنجم', 'جماعت ششم', 'جماعت ہفتم', 'جماعت ہشتم'];
  String _className = 'جماعت اول';
  DateTime _date = DateTime.now();
  late Future<List<Map<String, Object?>>> _records;
  bool _saving = false;

  String get _dateKey => '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _records = AppDatabase.instance.getAttendanceForClass(className: _className, date: _dateKey);
  }

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'حاضری کی تاریخ منتخب کریں',
    );
    if (picked != null && mounted) setState(() { _date = picked; _reload(); });
  }

  Future<void> _setStatus(int studentId, String status) async {
    setState(() => _saving = true);
    try {
      await AppDatabase.instance.saveAttendance(studentId: studentId, date: _dateKey, status: status);
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حاضری محفوظ نہیں ہو سکی: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = '${_date.day.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.year}';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _className,
              decoration: const InputDecoration(labelText: 'جماعت', border: OutlineInputBorder(), isDense: true),
              items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: _saving ? null : (v) { if (v != null) setState(() { _className = v; _reload(); }); },
            )),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: _chooseDate, icon: const Icon(Icons.calendar_month), label: Text(dateLabel)),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text('ہر طالب علم کے سامنے حاضر، غیر حاضر یا چھٹی منتخب کریں۔ تبدیلی خود محفوظ ہو جاتی ہے۔', textAlign: TextAlign.center),
        ),
        if (_saving) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: FutureBuilder<List<Map<String, Object?>>>(
          future: _records,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('حاضری لوڈ نہیں ہو سکی: ${snapshot.error}'));
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('اس جماعت میں طلبہ درج نہیں۔ پہلے طلبہ والے حصے میں ریکارڈ شامل کریں۔', textAlign: TextAlign.center)));
            final marked = rows.where((r) => r['attendance_status'] != null).length;
            final present = rows.where((r) => r['attendance_status'] == 'present').length;
            final absent = rows.where((r) => r['attendance_status'] == 'absent').length;
            final leave = rows.where((r) => r['attendance_status'] == 'leave').length;
            return Column(children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Wrap(spacing: 8, runSpacing: 4, children: [
                Chip(label: Text('کل ${rows.length}')),
                Chip(label: Text('حاضر $present')),
                Chip(label: Text('غیر حاضر $absent')),
                Chip(label: Text('چھٹی $leave')),
                Chip(label: Text('باقی ${rows.length - marked}')),
              ])),
              Expanded(child: ListView.builder(itemCount: rows.length, itemBuilder: (context, index) {
                final row = rows[index];
                final id = row['id'] as int;
                final status = row['attendance_status'] as String?;
                return Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${index + 1}. ${row['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if ((row['roll_no'] as String? ?? '').isNotEmpty) Text('رول نمبر: ${row['roll_no']}'),
                    Wrap(spacing: 0, runSpacing: 0, children: [
                      _AttendanceChoice(label: 'حاضر', value: 'present', selected: status == 'present', color: Colors.green, onTap: () => _setStatus(id, 'present')),
                      _AttendanceChoice(label: 'غیر حاضر', value: 'absent', selected: status == 'absent', color: Colors.red, onTap: () => _setStatus(id, 'absent')),
                      _AttendanceChoice(label: 'چھٹی', value: 'leave', selected: status == 'leave', color: Colors.orange, onTap: () => _setStatus(id, 'leave')),
                    ]),
                  ]),
                ));
              })),
            ]);
          },
        )),
      ],
    );
  }
}

class _AttendanceChoice extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _AttendanceChoice({required this.label, required this.value, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, top: 4),
    child: ChoiceChip(label: Text(label), selected: selected, selectedColor: color.withOpacity(0.18), onSelected: (_) => onTap(),
      side: BorderSide(color: selected ? color : Theme.of(context).colorScheme.outlineVariant)),
  );
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  const PlaceholderPage({super.key, required this.title, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 58),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;

  Future<void> _makeBackup() async {
    setState(() => _busy = true);
    try {
      final data = await AppDatabase.instance.exportBackupData();
      final bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(data)));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'بیک اپ محفوظ کریں',
        fileName: 'smart_school_teacher_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      if (!mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بیک اپ فائل محفوظ کرنے کا عمل مکمل ہوگیا۔')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بیک اپ محفوظ کرنے کا عمل منسوخ ہوگیا۔')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('بیک اپ نہیں بن سکا: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بیک اپ بحال کریں؟'),
        content: const Text(
          'بیک اپ بحال کرنے سے موجودہ طلبہ کا ریکارڈ بیک اپ والے ریکارڈ سے بدل جائے گا۔ '
          'اگر موجودہ ڈیٹا محفوظ رکھنا ہے تو پہلے بیک اپ بنائیں۔ کیا آپ جاری رکھنا چاہتے ہیں؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('منسوخ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('جاری رکھیں')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'بیک اپ JSON فائل منتخب کریں',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.single.bytes;
      if (bytes == null) throw const FormatException('فائل کا مواد پڑھا نہیں جا سکا۔');
      final count = await AppDatabase.instance.restoreBackupData(utf8.decode(bytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بیک اپ بحال ہوگیا۔ $count طلبہ کے ریکارڈ درآمد ہوئے۔')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('بیک اپ بحال نہیں ہو سکا: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.backup_outlined, size: 32),
            title: Text('ڈیٹا بیک اپ اور بحالی', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('طلبہ اور حاضری کو JSON فائل میں محفوظ کریں اور ضرورت پر واپس لائیں۔'),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _makeBackup,
          icon: const Icon(Icons.download_outlined),
          label: const Text('بیک اپ فائل محفوظ کریں'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy ? null : _restoreBackup,
          icon: const Icon(Icons.restore_outlined),
          label: const Text('بیک اپ سے ڈیٹا بحال کریں'),
        ),
        if (_busy) const Padding(
          padding: EdgeInsets.all(18),
          child: Center(child: CircularProgressIndicator()),
        ),
        const SizedBox(height: 18),
        const Text(
          'اہم: بیک اپ فائل کو فون کے Downloads فولڈر، میموری کارڈ یا کسی محفوظ جگہ پر رکھیں۔ '
          'بحالی کے دوران موجودہ طلبہ اور حاضری کا ڈیٹا بیک اپ والے ڈیٹا سے بدل جائے گا۔ پرانے بیک اپ جن میں صرف طلبہ ہوں، وہ بھی بحال کیے جا سکتے ہیں۔ امتحانات اور نتائج بعد کے مرحلے میں شامل ہوں گے۔',
        ),
      ],
    );
  }
}
