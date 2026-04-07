import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_087/features/logbook/models/log_model.dart';
import 'package:logbook_app_087/services/access_control_service.dart';
import 'package:mongo_dart/mongo_dart.dart';

void main() {
  test('RBAC Security Check: Private logs should NOT be visible to teammates', () {
    // 1. Setup Data:
    // User A memiliki 2 catatan: 1 berstatus 'Private' dan 1 berstatus 'Public'.
    final userA = 'User A';
    final userB = 'User B'; // Rekan satu tim User A

    final logPrivate = LogModel(
      id: ObjectId().oid,
      title: 'Private Log',
      description: 'Isi private.',
      date: DateTime.now().toString(),
      category: 'Mechanical',
      author: userA,
      teamId: 'Team1',
      isPublic: false,
    );

    final logPublic = LogModel(
      id: ObjectId().oid,
      title: 'Public Log',
      description: 'Isi public.',
      date: DateTime.now().toString(),
      category: 'Software',
      author: userA,
      teamId: 'Team1',
      isPublic: true,
    );

    final allLogs = [logPrivate, logPublic];

    // 2. Action:
    // User B (rekan satu tim User A) melakukan fungsi fetchLogs() / filter lokal yang mensimulasikan
    // logika di LogView: Tampilkan jika author == currentUserId ATAU isPublic == true
    
    final displayLogsForUserB = allLogs.where((log) {
      return log.author == userB || log.isPublic == true;
    }).toList();

    // 3. Assert (Validasi):
    // Pastikan List data yang diterima User B hanya berisi 1 log (hanya yang Public).
    expect(displayLogsForUserB.length, 1, reason: "Hanya satu log yang harusnya terlihat oleh User B");
    
    // Pastikan log yang terlihat adalah log public.
    expect(displayLogsForUserB.first.title, 'Public Log', reason: "Log yang tampil harusnya adalah 'Public Log'");

    // Jika log Private muncul, maka sistem dinyatakan gagal.
    final privateLogsVisible = displayLogsForUserB.where((log) => !log.isPublic && log.author != userB);
    expect(privateLogsVisible.isEmpty, true, reason: "SISTEM VULNERABLE: Log Private User A tidak boleh terlihat oleh User B!");
  });

  test('RBAC Security Check: Users CANNOT edit or delete logs they do not own', () {
    // 1. Setup Role and Ownership
    final roleAnggota = 'Anggota';
    final roleKetua = 'Ketua';
    
    // 2. Action & Assert untuk Anggota
    // Anggota biasa BUKAN pemilik catatan
    bool canAnggotaEditLain = AccessControlService.canPerform(roleAnggota, AccessControlService.actionUpdate, isOwner: false);
    bool canAnggotaDeleteLain = AccessControlService.canPerform(roleAnggota, AccessControlService.actionDelete, isOwner: false);
    
    expect(canAnggotaEditLain, false, reason: "Anggota TIDAK BOLEH mengedit catatan orang lain");
    expect(canAnggotaDeleteLain, false, reason: "Anggota TIDAK BOLEH menghapus catatan orang lain");

    // Anggota biasa ADALAH pemilik catatan
    bool canAnggotaEditSendiri = AccessControlService.canPerform(roleAnggota, AccessControlService.actionUpdate, isOwner: true);
    bool canAnggotaDeleteSendiri = AccessControlService.canPerform(roleAnggota, AccessControlService.actionDelete, isOwner: true);
    
    expect(canAnggotaEditSendiri, true, reason: "Anggota BOLEH mengedit catatannya sendiri");
    expect(canAnggotaDeleteSendiri, true, reason: "Anggota BOLEH menghapus catatannya sendiri");

    // 3. Action & Assert untuk Ketua
    // Ketua BUKAN pemilik catatan
    bool canKetuaEditLain = AccessControlService.canPerform(roleKetua, AccessControlService.actionUpdate, isOwner: false);
    bool canKetuaDeleteLain = AccessControlService.canPerform(roleKetua, AccessControlService.actionDelete, isOwner: false);
    
    expect(canKetuaEditLain, false, reason: "SISTEM VULNERABLE: Ketua BUKAN pemilik, jadi TIDAK BOLEH mengedit catatan orang lain");
    expect(canKetuaDeleteLain, false, reason: "SISTEM VULNERABLE: Ketua BUKAN pemilik, jadi TIDAK BOLEH menghapus catatan orang lain");
    
    // Ketua ADALAH pemilik catatan
    bool canKetuaEditSendiri = AccessControlService.canPerform(roleKetua, AccessControlService.actionUpdate, isOwner: true);
    
    expect(canKetuaEditSendiri, true, reason: "Ketua BOLEH mengedit catatannya sendiri");
  });
}
