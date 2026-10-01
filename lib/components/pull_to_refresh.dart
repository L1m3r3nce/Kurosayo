import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

/// Pull-to-refresh with a mascot badge indicator (white circular badge with
/// the app icon, bilibili-skin style): scales in while pulling, spins while
/// refreshing.
class PullToRefresh extends StatefulWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.triggerDistance = 80,
  });

  final RefreshCallback onRefresh;

  final Widget child;

  final double triggerDistance;

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh>
    with SingleTickerProviderStateMixin {
  double _pull = 0;

  bool _refreshing = false;

  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) {
      return false;
    }
    if (n is ScrollUpdateNotification) {
      // Bouncing physics: dragging past the top moves pixels below
      // minScrollExtent instead of emitting OverscrollNotification.
      if (_refreshing || n.dragDetails == null) {
        return false;
      }
      if (n.metrics.pixels > n.metrics.minScrollExtent) {
        return false;
      }
      setState(() {
        _pull = (-n.metrics.pixels / widget.triggerDistance).clamp(0.0, 1.3);
      });
    } else if (n is OverscrollNotification) {
      // Clamping physics fallback: accumulate the overscroll delta.
      if (_refreshing || n.dragDetails == null) {
        return false;
      }
      if (n.metrics.pixels > n.metrics.minScrollExtent + 0.5) {
        return false;
      }
      setState(() {
        _pull = (_pull + n.overscroll / widget.triggerDistance).clamp(0.0, 1.3);
      });
    } else if (n is UserScrollNotification) {
      // Finger released (drag direction back to idle): evaluate the trigger.
      if (n.direction == ScrollDirection.idle && !_refreshing && _pull > 0) {
        if (_pull >= 1.0) {
          _refresh();
        } else {
          setState(() => _pull = 0);
        }
      }
    } else if (n is ScrollEndNotification) {
      if (_pull > 0 && !_refreshing) {
        if (_pull >= 1.0) {
          _refresh();
        } else {
          setState(() => _pull = 0);
        }
      }
    }
    return false;
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _pull = 0;
    });
    _spin.repeat();
    try {
      await widget.onRefresh();
    } finally {
      _spin.stop();
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) {
          setState(() => _refreshing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var show = _refreshing || _pull > 0;
    var t = _refreshing ? 1.0 : _pull.clamp(0.0, 1.0);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedOpacity(
                  opacity: show ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: Transform.scale(
                    scale: 0.5 + 0.5 * t,
                    child: RotationTransition(turns: _spin, child: badge()),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget badge() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: const ClipOval(
        child: Image(
          image: AssetImage('assets/app_icon.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
