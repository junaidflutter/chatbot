import 'package:chat_bot_app/bloc/bottom_bar/bottom_bar_cubit.dart';
import 'package:chat_bot_app/screens/chat_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BottomBarCubit(),
      child: const _BottomShell(),
    );
  }
}

class _BottomShell extends StatelessWidget {
  const _BottomShell();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomBarCubit, BottomBarState>(
      builder: (context, state) {
        final pages = const [
          ChatTabs.chat,
          ChatTabs.streamingChat,
          ChatTabs.voiceChat,
          ChatTabs.settings,
        ];

        return Scaffold(
          backgroundColor: Colors.white,
          extendBody: true,
          body: pages[state.currentTab.index],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: state.currentTab.index,
            onTap: (index) =>
                context.read<BottomBarCubit>().changeTab(AppTab.values[index]),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF6D5EF7),
            unselectedItemColor: Colors.grey.shade600,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.graphic_eq_rounded),
                label: 'Streaming',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mic_none_rounded),
                label: 'Voice',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
