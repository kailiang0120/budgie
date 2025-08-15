import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

// 使用全局路由观察者（迁移到核心路由模块）
import 'package:budgie/core/router/route_observers.dart';

/// 具有高级动画效果的浮动操作按钮
class AnimatedFloatButton extends StatefulWidget {
  /// 按钮点击回调
  final VoidCallback onPressed;

  /// 按钮颜色
  final Color backgroundColor;

  /// 按钮图标
  final Widget child;

  /// 按钮形状
  final ShapeBorder? shape;

  /// 是否启用触觉反馈
  final bool enableFeedback;

  /// 动画持续时间
  final Duration duration;

  /// 淡入淡出曲线
  final Curve curve;

  /// 按钮高度
  final double? elevation;

  /// 当页面变化时是否自动响应
  final bool reactToRouteChange;

  const AnimatedFloatButton({
    super.key,
    required this.onPressed,
    required this.backgroundColor,
    required this.child,
    this.shape = const CircleBorder(),
    this.enableFeedback = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.elevation,
    this.reactToRouteChange = true,
  });

  @override
  State<AnimatedFloatButton> createState() => _AnimatedFloatButtonState();
}

class _AnimatedFloatButtonState extends State<AnimatedFloatButton>
    with SingleTickerProviderStateMixin, RouteAware {
  // 使用全局路由观察者
  final RouteObserver<PageRoute> _routeObserver = fabRouteObserver;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // 启动动画
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.reactToRouteChange) {
      // 注册路由监听
      final ModalRoute<dynamic>? route = ModalRoute.of(context);
      if (route is PageRoute) {
        _routeObserver.subscribe(this, route);
      }
    }
  }

  @override
  void dispose() {
    if (widget.reactToRouteChange) {
      _routeObserver.unsubscribe(this);
    }
    _controller.dispose();
    super.dispose();
  }

  // 当页面即将被覆盖时，执行淡出动画
  @override
  void didPushNext() {
    if (widget.reactToRouteChange) {
      _controller.reverse();
    }
  }

  // 当页面重新显示时，执行淡入动画
  @override
  void didPopNext() {
    if (widget.reactToRouteChange) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        backgroundColor: widget.backgroundColor,
        shape: widget.shape,
        enableFeedback: widget.enableFeedback,
        elevation: widget.elevation ?? AppConstants.elevationStandard,
        child: widget.child,
      ),
    );
  }
}
