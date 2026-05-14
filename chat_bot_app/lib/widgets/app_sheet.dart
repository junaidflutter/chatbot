import 'package:flutter/material.dart';

class AppSheet extends StatelessWidget {
  final String title;
  final List<ActionTileModel> actions;

  const AppSheet({super.key, required this.title, required this.actions});

  static void show(
    BuildContext context, {
    required String title,
    required List<ActionTileModel> actions,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Behtar sizing ke liye
      backgroundColor: Colors.transparent,
      builder: (context) => AppSheet(title: title, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              30,
            ), // Bottom margin for breathing room
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListView.separated(
              shrinkWrap: true, // Sirf utni height lega jitne items hain
              padding: EdgeInsets.zero, // FIX: Default padding khatam kar di
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 0.5,
                indent: 16,
                endIndent: 16,
                color: Colors.grey.shade300,
              ),
              itemBuilder: (context, index) {
                final action = actions[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),

                  title: Text(
                    action.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: action.icon,
                  onTap: () {
                    Navigator.pop(context);
                    action.onPressed();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ActionTileModel {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  ActionTileModel({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}
