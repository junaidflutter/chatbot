import 'package:chat_bot_app/utils/helper_functions.dart';
import 'package:flutter/material.dart';

class DateSelectionWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelection;

  const DateSelectionWidget({
    super.key,
    this.selectedDate,
    required this.onDateSelection,
  });

  @override
  State<DateSelectionWidget> createState() => _DateSelectionWidgetState();
}

class _DateSelectionWidgetState extends State<DateSelectionWidget> {
  DateTime? selectedDate;

  Future<void> selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select date of birth',
    );
    if (pickedDate != null) {
      selectedDate = pickedDate;
      widget.onDateSelection(pickedDate);
      setState(() {});
    }
  }

  @override
  void initState() {
    selectedDate = widget.selectedDate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    return GestureDetector(
      onTap: selectDate,
      child: Container(
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedDate != null
                    ? getFormattedDate(selectedDate!)
                    : 'Date of Birth',
              ),
              const Icon(Icons.date_range_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
