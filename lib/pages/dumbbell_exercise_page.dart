import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class DumbbellExercisePage extends StatefulWidget {
  const DumbbellExercisePage({super.key});

  @override
  State<DumbbellExercisePage> createState() => _DumbbellExercisePageState();
}

class _DumbbellExercisePageState extends State<DumbbellExercisePage> {
  late InAppLocalhostServer _server;

  @override
  void initState() {
    super.initState();
    // Serving assets/site on port 8080
    _server = InAppLocalhostServer(documentRoot: 'assets/site', port: 8080);
    _server.start();
  }

  @override
  void dispose() {
    _server.close();
    super.dispose();
  }

  Future<void> _saveToFirebase(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้ กรุณาล็อกอินใหม่')),
      );
      return;
    }

    try {
      // Data structure to save
      // 1. ชื่อผู้ใช้ (User Name) - Normally stored in user profile, but we can just rely on uid.
      // 2. วันที่ (Date) - from data
      // 3. เวลา (Time) - from data
      // 4. ข้างซ้าย (Left)
      // 5. ข้างขวา (Right)
      // 6. จำนวนรอบ (Rounds)
      // 7. รวมครั้ง (Total)
      // 8. ระยะเวลา (Duration)

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('exercise_history')
          .add({
            'exercise': 'dumbbell_standing', // ระบุประเภทท่า
            'date': data['date'],
            'left': data['left'],
            'right': data['right'],
            'rounds': data['rounds'],
            'total': data['total'],
            'duration_seconds': data['durationSec'],
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving to Firebase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ท่ายกดัมเบล'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri('http://localhost:8080/index.html'),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          allowsInlineMediaPlayback: true,
          mediaPlaybackRequiresUserGesture: false,
        ),
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: 'saveExerciseData',
            callback: (args) {
              // args[0] คือข้อมูลที่ส่งมาจาก JS
              if (args.isNotEmpty) {
                final data = args[0] as Map<String, dynamic>;
                _saveToFirebase(data);
                return 'Saved';
              }
              return 'No Data';
            },
          );
        },
        onPermissionRequest: (controller, request) async {
          return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT,
          );
        },
        onConsoleMessage: (controller, message) {
          debugPrint('WEB ▶ ${message.message}');
        },
      ),
    );
  }
}
