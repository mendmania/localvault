import 'package:flutter/material.dart';

class AsyncActionButton extends StatefulWidget {
  const AsyncActionButton({
    required this.onPressed,
    required this.child,
    this.icon,
    super.key,
  });

  final Future<void> Function()? onPressed;
  final Widget child;
  final Widget? icon;

  @override
  State<AsyncActionButton> createState() => _AsyncActionButtonState();
}

class _AsyncActionButtonState extends State<AsyncActionButton> {
  bool _busy = false;
  bool _done = false;

  Future<void> _run() async {
    if (_busy || widget.onPressed == null) {
      return;
    }
    setState(() {
      _busy = true;
      _done = false;
    });
    try {
      await widget.onPressed!();
      if (!mounted) {
        return;
      }
      setState(() {
        _done = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 180));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _done = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final content = _busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : _done
        ? const Icon(Icons.check_rounded)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              widget.child,
            ],
          );
    return AnimatedScale(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 160),
      scale: _busy ? 0.97 : 1,
      child: FilledButton(
        onPressed: _busy || widget.onPressed == null ? null : _run,
        child: AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          child: content,
        ),
      ),
    );
  }
}
