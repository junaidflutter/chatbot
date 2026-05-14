import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:chat_bot_app/utils/app_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StackedBaseLayout extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBackPress;
  final String? title;
  final bool isLoggedInUser;
  const StackedBaseLayout({
    super.key,
    required this.child,
    this.onBackPress,
    this.title,
    this.isLoggedInUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: isLoggedInUser
            ? Colors.grey
            : ColorName.primaryColor.shade700,
        body: Stack(
          children: [
            if (!isLoggedInUser)
              Positioned(
                top: 65,
                left: 20,
                right: 20,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            Positioned(
              top: isLoggedInUser ? 70 : 90,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (canPop)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                        child: InkWell(
                          onTap:
                              onBackPress ?? () => Navigator.maybePop(context),
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: const Icon(Icons.arrow_back, size: 30),
                          ),
                        ),
                      ),
                    if (!canPop) 50.sizeBoxHeight,
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 10,
                        ),
                        child: Text(
                          title!,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
