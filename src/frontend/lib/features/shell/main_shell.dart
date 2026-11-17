import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/features/chat/chat_controller.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _chatBranchIndex = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncChatViewing(widget.navigationShell.currentIndex);
    });
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prev = oldWidget.navigationShell.currentIndex;
    final next = widget.navigationShell.currentIndex;
    if (prev != next) {
      _syncChatViewing(next);
    }
  }

  void _syncChatViewing(int index) {
    ref
        .read(chatControllerProvider.notifier)
        .setViewingChat(index == _chatBranchIndex);
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep hub connected app-wide for unread badges.
    final chat = ref.watch(chatControllerProvider);
    final hasUnread = chat.hasUnread;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: OnlyShroomsTheme.forest,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        toolbarHeight: kToolbarHeight,
        title: Semantics(
          button: true,
          label: 'Strona główna',
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => context.go('/'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('OnlyShrooms'),
            ),
          ),
        ),
      ),
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: OnlyShroomsTheme.forest,
          indicatorColor: OnlyShroomsTheme.moss,
          overlayColor: const WidgetStatePropertyAll(Color(0x22FFFFFF)),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected
                  ? OnlyShroomsTheme.cream
                  : OnlyShroomsTheme.cream.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected
                  ? OnlyShroomsTheme.cream
                  : OnlyShroomsTheme.cream.withValues(alpha: 0.75),
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.forest_outlined),
              selectedIcon: Icon(Icons.forest),
              label: 'Grzybobrania',
            ),
            const NavigationDestination(
              icon: Icon(Icons.task_alt_outlined),
              selectedIcon: Icon(Icons.task_alt),
              label: 'Zadania',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: hasUnread,
                smallSize: 10,
                backgroundColor: OnlyShroomsTheme.inactiveFilterBackground,
                child: const Icon(Icons.chat_bubble_outline),
              ),
              selectedIcon: Badge(
                isLabelVisible: hasUnread,
                smallSize: 10,
                backgroundColor: OnlyShroomsTheme.inactiveFilterBackground,
                child: const Icon(Icons.chat_bubble),
              ),
              label: 'Chat',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
