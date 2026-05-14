import 'dart:io';

import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:chat_bot_app/utils/app_snackbar.dart';
import 'package:chat_bot_app/widgets/app_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void hideKeyBoard() {
  FocusManager.instance.primaryFocus?.unfocus();
}

String getFormattedDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

// Future<bool> sendFcmTokenToServer(String token) async {
//   try {
//     final authApiProvider = AuthRepository();
//     await authApiProvider.sendFcmToken(token);
//     return true;
//   } catch (e) {
//     debugPrint(handleDioError(e, defaultMessage: "Failed To Send FCM Token"));
//     return false;
//   }
// }

String handleDioError(
  Object e, {
  String defaultMessage = "Something went wrong",
}) {
  if (e is DioException) {
    if (e.response?.data is Map &&
        (e.response?.data as Map).containsKey("message")) {
      return e.response?.data["message"] ?? defaultMessage;
    }

    return e.message ?? defaultMessage;
  }

  return e.toString();
}

Future<bool> isInternetAvailable() async {
  try {
    final result = await InternetAddress.lookup('www.google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    AppSnackbar.showErrorMessage('Check Your Internet Connection');
    return false;
  }
}

// Future<String> getTimeZone() async {
//   try {
//     final tzInfo = await FlutterTimezone.getLocalTimezone();
//     debugPrint("✅ Device Timezone: ${tzInfo.identifier}");
//     return tzInfo.identifier; // return only the IANA timezone
//   } catch (e) {
//     debugPrint("⚠️ Failed to get timezone. Error: $e");
//     return DateTime.now().timeZoneName; // fallback
//   }
// }

Future<bool?> showExitDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.exit_to_app_rounded,
                    size: 60,
                    color: ColorName.primaryColor,
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Are you sure you want to close the app?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    onTap: () {
                      Navigator.of(context).pop(true); // Exit confirmed
                      exit(0); // Closes the app
                    },
                    text: 'Yes, Exit',
                    backgroundColor: ColorName.primaryColor,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(false); // Continue app
                    },
                    child: const Text(
                      'Keep & Continue',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: ColorName.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

String generateSessionId() {
  final uuid = Uuid();
  return uuid.v4();
}

const kDayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const kIndexToWeekday = [7, 1, 2, 3, 4, 5, 6];

String formatTimeOfDay(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$h:$m $period';
}

String formatTo24Hour(DateTime time) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return "${twoDigits(time.hour)}:${twoDigits(time.minute)}";
}

String formatDate(DateTime d) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month]} ${d.day}, ${d.year}';
}

String dayName(DateTime d) {
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[d.weekday - 1];
}

String formatTaskDate(String rawDate) {
  try {
    final dt = DateTime.parse(rawDate);
    return DateFormat('EEEE dd MMM').format(dt);
  } catch (e) {
    return rawDate;
  }
}
