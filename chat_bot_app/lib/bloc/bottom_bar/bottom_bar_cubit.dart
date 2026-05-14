import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AppTab { chat, streamingChat, voiceChat, settings }

class BottomBarState extends Equatable {
  final AppTab currentTab;

  const BottomBarState({required this.currentTab});

  BottomBarState copyWith({AppTab? currentTab}) {
    return BottomBarState(currentTab: currentTab ?? this.currentTab);
  }

  @override
  List<Object?> get props => [currentTab];
}

class BottomBarCubit extends Cubit<BottomBarState> {
  BottomBarCubit() : super(const BottomBarState(currentTab: AppTab.chat));

  void changeTab(AppTab tab) {
    emit(state.copyWith(currentTab: tab));
  }
}
