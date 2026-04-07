import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
  // Mengambil roles dari .env di root 
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota', 'Ketua'];

  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  // Matrix perizinan yang tetap fleksibel
  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead, actionUpdate, actionDelete], 
    'Anggota': [actionCreate, actionRead], 
  };

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    // ATURAN TASK 5: Hanya pemilik (Owner) yang boleh Update atau Delete
    // Mengabaikan Role 'Ketua' untuk aksi ini
    if (action == actionUpdate || action == actionDelete) {
      return isOwner; // Mutlak hanya pemilik catatan yang bisa edit/hapus
    }
  
    final permissions = _rolePermissions[role] ?? [];
    return permissions.contains(action);
  }

}