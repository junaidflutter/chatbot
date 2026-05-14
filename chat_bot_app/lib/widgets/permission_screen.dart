import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:chat_bot_app/utils/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions(); // Check permissions for camera, microphone, and gallery/photos
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;
    final photosStatus = await Permission.photos.status;

    if (cameraStatus.isGranted &&
        microphoneStatus.isGranted &&
        photosStatus.isGranted) {
      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        _isPermissionGranted = true;
      });

      // Automatically navigate back if permissions are granted
      if (mounted) {
        AppNavigator.pop(context, true);
      }
    } else {
      setState(() {
        _isPermissionGranted = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    // Request camera, microphone, and gallery/photo permissions
    final cameraResult = await Permission.camera.request();
    final microphoneResult = await Permission.microphone.request();
    final photosResult = await Permission.photos.request();

    // Check if all permissions are granted
    if (cameraResult.isGranted &&
        microphoneResult.isGranted &&
        photosResult.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        AppNavigator.pop(context, true); // Navigate back or continue
      }
    } else if (cameraResult.isPermanentlyDenied ||
        microphoneResult.isPermanentlyDenied ||
        photosResult.isPermanentlyDenied) {
      // Open settings if any permission is permanently denied
      _openSettings();
    } else {
      // Update state if permissions are denied but not permanently
      setState(() {
        _isPermissionGranted = false;
      });
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();

    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        // backgroundColor:
        // context.isDarkMode ? Colors.grey.shade600 : Colors.white,
      ),
      backgroundColor: Colors.grey.shade700,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              // color: context.isDarkMode ? Colors.grey.shade600 : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isPermissionGranted
                    ? const Text(
                        'Permission Granted! You can now access the camera, microphone, and gallery/photo library.',
                        style: TextStyle(fontSize: 18, color: Colors.black),
                        textAlign: TextAlign.center,
                      )
                    : Text(
                        'Allow Beanstalk to access your camera, microphone, and gallery/photo library. This lets you share photos, videos, and record audio.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          // color: context.onSurfaceColor,
                        ),
                      ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: ColorName.primaryColor,
                  ),
                  onPressed: () {
                    if (_isPermissionGranted) {
                      AppNavigator.pop(context, true);
                    } else {
                      _requestPermissions(); // Request permissions
                    }
                  },
                  child: Text(
                    'Continue',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
