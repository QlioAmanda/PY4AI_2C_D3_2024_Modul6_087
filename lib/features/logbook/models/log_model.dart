// Nama : Qlio Amanda Febriany | Nim : 241511087 | Kelas : 2C
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id; // Ubah ke String agar Hive bisa menyimpannya

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String date;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String author; 

  @HiveField(6, defaultValue: 'no_team')
  final String teamId;

  @HiveField(7, defaultValue: false)
  final bool isPublic;

  LogModel({
    this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.category,
    required this.author,
    required this.teamId,
    this.isPublic = false,
  });

  // Konversi dari Cloud (BSON) ke Aplikasi
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: (map['_id'] as ObjectId?)?.oid,
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Pekerjaan',
      author: map['author'] ?? 'Unknown',
      teamId: map['teamId'] ?? 'no_team',
      isPublic: map['isPublic'] ?? false,
    );
  }

  // Konversi dari Aplikasi ke Cloud (BSON)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': ObjectId.fromHexString(id!),
      'title': title,
      'date': date,
      'description': description,
      'category': category,
      'author': author,
      'teamId': teamId,
      'isPublic': isPublic,
    };
  }
}