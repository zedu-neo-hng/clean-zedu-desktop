import 'dart:async';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class NotificationBellButton extends ConsumerStatefulWidget {
  const NotificationBellButton({
    super.key,
    this.debounceDuration = const Duration(milliseconds: 180),
    this.autofocus = false,
  });

  final Duration debounceDuration;
  final bool autofocus;

  @override
  ConsumerState<NotificationBellButton> createState() =>
      _NotificationBellButtonState();
}

class _NotificationBellButtonState
    extends ConsumerState<NotificationBellButton> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  Timer? _showTimer;
  Timer? _hideTimer;
  bool _isHovered = false;

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onBellEnter() {
    _isHovered = true;
    _hideTimer?.cancel();
    _hideTimer = null;

    if (!_overlayController.isShowing) {
      _showTimer?.cancel();
      _showTimer = Timer(widget.debounceDuration, () {
        if (mounted && _isHovered && !_overlayController.isShowing) {
          setState(() {
            _overlayController.show();
          });
        }
      });
    }
  }

  void _onBellExit() {
    _isHovered = false;
    _showTimer?.cancel();
    _showTimer = null;

    if (_overlayController.isShowing) {
      _startHideTimer();
    }
  }

  void _onPopoverEnter() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _onPopoverExit() {
    if (_overlayController.isShowing) {
      _startHideTimer();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.debounceDuration, () {
      if (mounted && _overlayController.isShowing) {
        setState(() {
          _overlayController.hide();
        });
      }
    });
  }

  void _hidePopover() {
    _showTimer?.cancel();
    _showTimer = null;
    _hideTimer?.cancel();
    _hideTimer = null;
    if (mounted && _overlayController.isShowing) {
      setState(() {
        _overlayController.hide();
      });
    }
  }

  void _togglePopover() {
    _showTimer?.cancel();
    _showTimer = null;
    _hideTimer?.cancel();
    _hideTimer = null;
    setState(() {
      if (_overlayController.isShowing) {
        _overlayController.hide();
      } else {
        _overlayController.show();
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_overlayController.isShowing) {
          _hidePopover();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _togglePopover();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final isOpen = _overlayController.isShowing;

    return Semantics(
      container: true,
      button: true,
      label: 'Notifications',
      hint: 'View recent notifications preview',
      expanded: isOpen,
      child: SizedBox(
        width: 40,
        height: 46,
        child: Focus(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onKeyEvent: _handleKeyEvent,
          child: MouseRegion(
            onEnter: (_) => _onBellEnter(),
            onExit: (_) => _onBellExit(),
            child: OverlayPortal(
              controller: _overlayController,
              overlayChildBuilder: (context) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    targetAnchor: Alignment.topRight,
                    followerAnchor: Alignment.bottomLeft,
                    offset: const Offset(12, 0),
                    child: MouseRegion(
                      onEnter: (_) => _onPopoverEnter(),
                      onExit: (_) => _onPopoverExit(),
                      child: NotificationPreviewPopover(
                        onClose: _hidePopover,
                        onViewAll: () {
                          _hidePopover();
                          ref
                              .read(userProfileNotifierProvider.notifier)
                              .selectSection(UserProfileSection.notifications);
                          context.go(AppRouter.profile);
                        },
                      ),
                    ),
                  ),
                );
              },
              child: CompositedTransformTarget(
                link: _layerLink,
                child: InkWell(
                  onTap: _togglePopover,
                  borderRadius: BorderRadius.circular(7),
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isOpen
                                ? colors.primary.withValues(alpha: 0.95)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            Icons.notifications_none_outlined,
                            color: colors.onPrimary,
                            size: 18,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
