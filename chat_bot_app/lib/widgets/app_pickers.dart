import 'dart:io';

import 'package:chat_bot_app/widgets/permission_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPickers {
  AppPickers._();

  static Future<XFile?> pickImage(BuildContext context) async {
    final ImageSource? imageSource =
        await showOptionSelectionSheet<ImageSource>(
          context: context,
          options: {
            for (final value in ImageSource.values)
              value.name[0].toUpperCase() + value.name.substring(1): value,
          },
        );

    if (imageSource == null) return null;

    if (imageSource == ImageSource.camera) {
      if (Platform.isIOS) {
        if (context.mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PermissionScreen()),
          );

          if (result == null || result != true) {
            return null; // Return null if permission wasn't granted
          }
        } else if (Platform.isAndroid) {
          // For Android, request permission directly
          final PermissionStatus status = await Permission.camera.request();
          if (!status.isGranted) {
            return null; // Return null if permission wasn't granted
          }
        }
      } else if (ImageSource.gallery == imageSource) {}
      if (Platform.isIOS) {
        bool hasPermission = await checkPhotoLibraryPermission();
        if (hasPermission) {
        } else {
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PermissionScreen()),
            );
          }
        }
      } else if (Platform.isAndroid) {
        // For Android, request permission directly
        final PermissionStatus status = await Permission.photos.request();
        if (!status.isGranted) {
          return null; // Return null if permission wasn't granted
        }
      }
    }

    final ImagePicker picker = ImagePicker();
    return picker.pickImage(source: imageSource);
  }

  static Future<T?> showOptionSelectionSheet<T>({
    required BuildContext context,
    String? title,
    required Map<String, T> options,
  }) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(title ?? 'Choose an Option'),
        actions: options.keys
            .map(
              (key) => CupertinoActionSheetAction(
                child: Text(key),
                onPressed: () {
                  Navigator.pop(context, options[key]);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  static Future<bool> checkPhotoLibraryPermission() async {
    // Check current permission status
    var status = await Permission.photos.status;

    if (status.isGranted) {
      return true; // Permission is granted
    } else if (status.isDenied) {
      // Permission is denied; request it
      var result = await Permission.photos.request();
      if (result.isGranted) {
        return true; // Permission granted after requesting
      } else {
        return false; // Permission denied after requesting
      }
    } else if (status.isPermanentlyDenied) {
      // Open app settings to enable permission
      await openAppSettings();
      return false; // Permission permanently denied
    } else if (status.isLimited) {
      return true; // Limited access is considered as granted
    }

    return false; // Default case
  }

  static Future<XFile?> pickMedia(
    BuildContext context, {
    required bool isVideo,
  }) async {
    if (isVideo) {
      if (Platform.isIOS) {
        // For iOS, navigate to the custom PermissionScreen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PermissionScreen()),
        );

        if (result == null || result != true) {
          return null; // Return null if permission wasn't granted
        }
      } else if (Platform.isAndroid) {
        // For Android, request permission directly
        final PermissionStatus status = await Permission.camera.request();
        if (!status.isGranted) {
          return null; // Return null if permission wasn't granted
        }
      }
    }

    final ImagePicker picker = ImagePicker();
    if (isVideo) {
      return await picker.pickVideo(source: ImageSource.gallery);
    } else {
      return await picker.pickImage(source: ImageSource.gallery);
    }
  }
}
