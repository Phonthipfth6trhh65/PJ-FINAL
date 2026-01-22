import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

class DumbbellExercisePage extends StatefulWidget {
  const DumbbellExercisePage({super.key});

  @override
  State<DumbbellExercisePage> createState() => _DumbbellExercisePageState();
}

class _DumbbellExercisePageState extends State<DumbbellExercisePage> {
  late InAppLocalhostServer _localhostServer;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();

    // ✅ เปิด localhost server
    _localhostServer = InAppLocalhostServer(
      documentRoot: 'assets/site',
      port: 8080,
    );

    _localhostServer.start();
  }

  // ✅ ขอ permission กล้อง
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _permissionGranted = status.isGranted;
    });

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาอนุญาตให้เข้าถึงกล้องเพื่อใช้งานฟีเจอร์นี้'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _localhostServer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ท่ายกดัมเบลแบบยืน')),
      body: !_permissionGranted
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังขอสิทธิ์เข้าถึงกล้อง...'),
                ],
              ),
            )
          : InAppWebView(
              // ✅ โหลดผ่าน http://localhost (iOS อนุญาตกล้อง)
              initialUrlRequest: URLRequest(
                url: WebUri('http://localhost:8080/index.html'),
              ),

              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                allowsInlineMediaPlayback: true,
                mediaPlaybackRequiresUserGesture: false,
              ),

              // ✅ อนุญาต camera ให้ JS
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },

              // ✅ สำหรับ Android - จัดการ permission request
              androidOnPermissionRequest:
                  (controller, origin, resources) async {
                    return PermissionRequestResponse(
                      resources: resources,
                      action: PermissionRequestResponseAction.GRANT,
                    );
                  },

              onConsoleMessage: (controller, message) {
                debugPrint('WEB: ${message.message}');
              },

              onLoadError: (controller, url, code, message) {
                debugPrint('Error loading $url: $message');
              },
            ),
    );
  }
}
