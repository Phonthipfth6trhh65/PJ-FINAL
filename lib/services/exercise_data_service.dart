import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExerciseDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// บันทึกข้อมูลการออกกำลังกายลง Firestore
  Future<Map<String, dynamic>> saveExerciseData({
    required String date,
    required String exerciseType,
    required int left,
    required int right,
    required int rounds,
    required int total,
    required int durationSec,
    required String timestamp,
  }) async {
    try {
      // ตรวจสอบว่าผู้ใช้เข้าสู่ระบบหรือไม่
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'กรุณาเข้าสู่ระบบก่อนบันทึกข้อมูล'};
      }

      // สร้างข้อมูลที่จะบันทึก
      final exerciseData = {
        'userId': user.uid,
        'userEmail': user.email,
        'date': date,
        'exerciseType': exerciseType,
        'left': left,
        'right': right,
        'rounds': rounds,
        'total': total,
        'durationSec': durationSec,
        'timestamp': timestamp,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // บันทึกลง Firestore
      final docRef = await _firestore
          .collection('exercise_records')
          .add(exerciseData);

      print('✅ บันทึกข้อมูลการออกกำลังกายสำเร็จ: ${docRef.id}');

      return {
        'success': true,
        'documentId': docRef.id,
        'message': 'บันทึกข้อมูลเรียบร้อยแล้ว',
      };
    } catch (e) {
      print('❌ Error saving exercise data: $e');
      return {'success': false, 'error': 'เกิดข้อผิดพลาด: ${e.toString()}'};
    }
  }

  /// ดึงข้อมูลการออกกำลังกายของผู้ใช้
  Future<List<Map<String, dynamic>>> getUserExerciseRecords() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ ผู้ใช้ยังไม่ได้เข้าสู่ระบบ');
        return [];
      }

      final querySnapshot = await _firestore
          .collection('exercise_records')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting exercise records: $e');
      return [];
    }
  }

  /// ดึงข้อมูลการออกกำลังกายตามช่วงวันที่
  Future<List<Map<String, dynamic>>> getExerciseRecordsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ ผู้ใช้ยังไม่ได้เข้าสู่ระบบ');
        return [];
      }

      final querySnapshot = await _firestore
          .collection('exercise_records')
          .where('userId', isEqualTo: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting exercise records by date range: $e');
      return [];
    }
  }

  /// ลบข้อมูลการออกกำลังกาย
  Future<bool> deleteExerciseRecord(String documentId) async {
    try {
      await _firestore.collection('exercise_records').doc(documentId).delete();
      print('✅ ลบข้อมูลการออกกำลังกายสำเร็จ: $documentId');
      return true;
    } catch (e) {
      print('❌ Error deleting exercise record: $e');
      return false;
    }
  }
}
