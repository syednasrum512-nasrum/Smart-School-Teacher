import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    final path = p.join(root, 'smart_school_teacher.db');
    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            father_name TEXT NOT NULL DEFAULT '',
            roll_no TEXT NOT NULL DEFAULT '',
            admission_no TEXT NOT NULL DEFAULT '',
            phone TEXT NOT NULL DEFAULT '',
            class_name TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_students_class ON students(class_name)');
        await _createAttendanceTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createAttendanceTable(db);
      },
    );
    return _database!;
  }

  Future<void> _createAttendanceTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        attendance_date TEXT NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('present','absent','leave')),
        updated_at TEXT NOT NULL,
        UNIQUE(student_id, attendance_date),
        FOREIGN KEY(student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(attendance_date)');
  }

  Future<int> countStudents() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM students');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, Object?>>> getStudents({required String className}) async {
    final db = await database;
    return db.query('students', where: 'class_name = ?', whereArgs: [className], orderBy: 'name COLLATE NOCASE');
  }

  Future<int> insertStudent(Map<String, Object?> record) async {
    final db = await database;
    return db.insert('students', {...record, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<int> updateStudent(int id, Map<String, Object?> record) async {
    final db = await database;
    return db.update('students', record, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.delete('attendance', where: 'student_id = ?', whereArgs: [id]);
      return txn.delete('students', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Map<String, Object?>>> getAttendanceForClass({required String className, required String date}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT s.id, s.name, s.father_name, s.roll_no, s.class_name,
             a.status AS attendance_status
      FROM students s
      LEFT JOIN attendance a ON a.student_id = s.id AND a.attendance_date = ?
      WHERE s.class_name = ?
      ORDER BY s.name COLLATE NOCASE
    ''', [date, className]);
  }

  Future<void> saveAttendance({required int studentId, required String date, required String status}) async {
    if (!['present', 'absent', 'leave'].contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported attendance status');
    }
    final db = await database;
    await db.insert('attendance', {
      'student_id': studentId,
      'attendance_date': date,
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, int>> attendanceSummary({required String className, required String date}) async {
    final rows = await getAttendanceForClass(className: className, date: date);
    var present = 0, absent = 0, leave = 0, unmarked = 0;
    for (final row in rows) {
      switch (row['attendance_status']) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'leave':
          leave++;
          break;
        default:
          unmarked++;
      }
    }
    return {'total': rows.length, 'present': present, 'absent': absent, 'leave': leave, 'unmarked': unmarked};
  }

  /// Portable JSON backup. Older v1 backups without attendance remain supported.
  Future<Map<String, Object?>> exportBackupData() async {
    final db = await database;
    final students = await db.query('students', orderBy: 'id ASC');
    final attendance = await db.query('attendance', orderBy: 'attendance_date ASC, student_id ASC');
    return <String, Object?>{
      'app': 'Smart School Teacher',
      'backup_format_version': 1,
      'created_at': DateTime.now().toIso8601String(),
      'data': <String, Object?>{'students': students, 'attendance': attendance},
    };
  }

  Future<int> restoreBackupData(String jsonText) async {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic> || decoded['app'] != 'Smart School Teacher' ||
        decoded['backup_format_version'] != 1 || decoded['data'] is! Map<String, dynamic> ||
        (decoded['data'] as Map<String, dynamic>)['students'] is! List) {
      throw const FormatException('یہ Smart School Teacher کی درست بیک اپ فائل نہیں ہے۔');
    }
    final data = decoded['data'] as Map<String, dynamic>;
    final rawStudents = data['students'] as List;
    final normalizedStudents = <Map<String, Object?>>[];
    final oldIdToNewId = <int, int>{};
    for (final item in rawStudents) {
      if (item is! Map) throw const FormatException('بیک اپ میں طلبہ کا ریکارڈ درست نہیں۔');
      final row = Map<String, Object?>.from(item);
      if (row['name'] is! String || row['class_name'] is! String) {
        throw const FormatException('بیک اپ میں طالب علم کا نام یا جماعت موجود نہیں۔');
      }
      normalizedStudents.add({
        'old_id': row['id'],
        'name': row['name'],
        'father_name': row['father_name'] is String ? row['father_name'] : '',
        'roll_no': row['roll_no'] is String ? row['roll_no'] : '',
        'admission_no': row['admission_no'] is String ? row['admission_no'] : '',
        'phone': row['phone'] is String ? row['phone'] : '',
        'class_name': row['class_name'],
        'created_at': row['created_at'] is String ? row['created_at'] : DateTime.now().toIso8601String(),
      });
    }
    final normalizedAttendance = <Map<String, Object?>>[];
    final rawAttendance = data['attendance'];
    if (rawAttendance != null) {
      if (rawAttendance is! List) throw const FormatException('بیک اپ میں حاضری کا ڈیٹا درست نہیں۔');
      for (final item in rawAttendance) {
        if (item is! Map) throw const FormatException('حاضری کا ریکارڈ درست نہیں۔');
        final row = Map<String, Object?>.from(item);
        if (row['student_id'] is! int || row['attendance_date'] is! String ||
            row['status'] is! String || !['present', 'absent', 'leave'].contains(row['status'])) {
          throw const FormatException('حاضری کی تاریخ یا حیثیت درست نہیں۔');
        }
        normalizedAttendance.add(row);
      }
    }

    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('attendance');
      await txn.delete('students');
      for (final student in normalizedStudents) {
        final oldId = student.remove('old_id');
        final newId = await txn.insert('students', student);
        if (oldId is int) oldIdToNewId[oldId] = newId;
      }
      for (final row in normalizedAttendance) {
        final newId = oldIdToNewId[row['student_id']];
        if (newId == null) continue;
        await txn.insert('attendance', {
          'student_id': newId,
          'attendance_date': row['attendance_date'],
          'status': row['status'],
          'updated_at': row['updated_at'] is String ? row['updated_at'] : DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    return normalizedStudents.length;
  }
}
