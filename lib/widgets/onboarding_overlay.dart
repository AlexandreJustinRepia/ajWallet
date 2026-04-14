import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';


class OnboardingStep {
  final GlobalKey? targetKey;
  final String title;
  final String description;
  final VoidCallback? onStepEnter;

  OnboardingStep({
    this.targetKey,
    required this.title,
    required this.description,
    this.onStepEnter,
  });
}

class OnboardingOverlay extends StatefulWidget {
  final List<OnboardingStep> steps;
  final VoidCallback onFinish;
  final Widget child;
  final bool visible;

  const OnboardingOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
    required this.child,
    this.visible = true,
  });

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> with TickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late AnimationController _rectController;
  late Animation<double> _rectCurve;
  RectTween? _rectTween;
  Rect? _targetRect;
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    
    _rectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _rectCurve = CurvedAnimation(parent: _rectController, curve: Curves.easeInOutCubic);

    _ticker = createTicker((_) => _updateTargetRect());

    if (widget.visible) {
      _animController.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerStepEnter();
        _ticker.start();
      });
    }
  }

  @override
  void didUpdateWidget(OnboardingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _animController.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerStepEnter();
        _ticker.start();
      });
    } else if (!widget.visible && oldWidget.visible) {
      _ticker.stop();
    }
  }

  void _triggerStepEnter() {
    widget.steps[_currentStepIndex].onStepEnter?.call();
    _updateTargetRect(isStepTransition: true);
  }

  void _updateTargetRect({bool isStepTransition = false}) {
    if (!widget.visible) return;
    
    final currentStep = widget.steps[_currentStepIndex];
    Rect? newRect;
    
    if (currentStep.targetKey != null) {
      final RenderBox? box = currentStep.targetKey!.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? overlayBox = context.findRenderObject() as RenderBox?;
      
      if (box != null && overlayBox != null) {
        // Convert global coordinates to local overlay coordinates
        final globalPosition = box.localToGlobal(Offset.zero);
        final localPosition = overlayBox.globalToLocal(globalPosition);
        newRect = Rect.fromLTWH(
          localPosition.dx,
          localPosition.dy,
          box.size.width,
          box.size.height,
        );
      }
    }

    if (newRect != _targetRect || isStepTransition) {
      setState(() {
        if (isStepTransition) {
          _rectTween = RectTween(
            begin: _rectTween?.evaluate(_rectCurve) ?? newRect,
            end: newRect,
          );
          _rectController.forward(from: 0.0);
        } else {
          if (_rectTween != null) {
            _rectTween!.end = newRect;
          } else {
            _rectTween = RectTween(begin: newRect, end: newRect);
          }
        }
        _targetRect = newRect;
      });
    }
  }

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _triggerStepEnter();
    } else {
      _finish();
    }
  }

  void _finish() {
    _animController.reverse().then((_) => widget.onFinish());
  }

  @override
  void dispose() {
    _ticker.dispose();
    _animController.dispose();
    _rectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            widget.child,
            FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                children: [
                  // Dark Overlay with Spotlight
                  GestureDetector(
                    onTap: _nextStep,
                    child: AnimatedBuilder(
                      animation: _rectController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size.infinite,
                          painter: _SpotlightPainter(
                            targetRect:
                                _rectTween?.evaluate(_rectCurve) ?? _targetRect,
                          ),
                        );
                      },
                    ),
                  ),
                  // Step Content
                  _buildStepContent(constraints),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepContent(BoxConstraints constraints) {
    final step = widget.steps[_currentStepIndex];
    final theme = Theme.of(context);
    final availableHeight = constraints.maxHeight;
    final padding = MediaQuery.of(context).padding;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Use actual available height from constraints
    final double baseTop = (_targetRect?.bottom ?? 100) + 20;
    final double baseBottom = (availableHeight - (_targetRect?.top ?? 300)) + 20;

    final double boxMinHeight = 220.0;
    final double safePadding = 24.0;
    // Add extra space for the navbar area if detected via media query padding
    final double effectiveBottomPadding = (padding.bottom > 0) ? padding.bottom + 8 : safePadding;

    // Calculate available space with safe padding
    double spaceBelow =
        (availableHeight - baseTop - effectiveBottomPadding - bottomInset)
            .clamp(0.0, availableHeight);
    double spaceAbove =
        (availableHeight - baseBottom - safePadding).clamp(0.0, availableHeight);

    double? top;
    double? bottom;
    double maxHeight;

    if (spaceBelow >= boxMinHeight) {
      // Preference: Below spotlight
      top = baseTop;
      maxHeight = spaceBelow;
    } else if (spaceAbove >= boxMinHeight) {
      // Alternate: Above spotlight
      bottom = baseBottom;
      maxHeight = spaceAbove;
    } else {
      // Emergency Fallback: If target is too large or centered,
      // place modal at bottom and let it overlap the spotlight
      bottom = effectiveBottomPadding;
      top = null;
      maxHeight =
          (availableHeight * 0.4).clamp(boxMinHeight, availableHeight - 48);
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      top: top,
      bottom: bottom,
      left: 24,
      right: 24,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentStepIndex == widget.steps.length - 1
                            ? 'Get Started'
                            : 'Next',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;

  _SpotlightPainter({this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha:0.7);
    
    if (targetRect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect spotlightRect = RRect.fromRectAndRadius(
      targetRect!.inflate(8), 
      const Radius.circular(16)
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(fullRect),
        Path()..addRRect(spotlightRect),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) => oldDelegate.targetRect != targetRect;
}
