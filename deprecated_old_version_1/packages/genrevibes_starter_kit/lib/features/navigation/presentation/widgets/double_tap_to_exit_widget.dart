import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/double_tap_config.dart';

/// A customizable wrapper widget that implements double tap to exit functionality
/// with a configurable exit dialog on first back tap.
class DoubleTapToExitWidget extends StatefulWidget {
  /// The child widget to wrap
  final Widget child;

  /// Configuration for customizing the exit dialog and behavior
  final DoubleTapExitConfig config;

  const DoubleTapToExitWidget({
    super.key,
    required this.child,
    this.config = const DoubleTapExitConfig(),
  });

  @override
  State<DoubleTapToExitWidget> createState() => _DoubleTapToExitWidgetState();
}

class _DoubleTapToExitWidgetState extends State<DoubleTapToExitWidget> {
  DateTime? _lastPressedAt;

  Future<bool?> _showExitDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: widget.config.dialogShape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
        backgroundColor: widget.config.dialogBackgroundColor,
        title: Text(
          widget.config.dialogTitle,
          style: widget.config.titleTextStyle ??
              TextStyle(
                color: widget.config.titleColor ?? Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
        content: Text(
          widget.config.dialogContent,
          style: widget.config.contentTextStyle ??
              TextStyle(
                color: widget.config.contentColor ?? Colors.white,
                fontSize: 16,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Stay in app
            style: TextButton.styleFrom(
              foregroundColor: widget.config.cancelButtonTextColor ?? Colors.white,
              backgroundColor: widget.config.cancelButtonColor,
            ),
            child: Text(
              widget.config.cancelButtonText,
              style: widget.config.cancelButtonTextStyle ??
                  TextStyle(
                    color: widget.config.cancelButtonTextColor ?? Colors.white,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Close dialog first
              SystemChannels.platform
                  .invokeMethod('SystemNavigator.pop'); // Exit app
            },
            style: TextButton.styleFrom(
              foregroundColor: widget.config.confirmButtonTextColor ?? Colors.white,
              backgroundColor: widget.config.confirmButtonColor,
            ),
            child: Text(
              widget.config.confirmButtonText,
              style: widget.config.confirmButtonTextStyle ??
                  TextStyle(
                    color: widget.config.confirmButtonTextColor ?? Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents app from closing automatically
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final now = DateTime.now();
        final doubleTapThreshold = widget.config.doubleTapDuration;

        final bool isFirstTap = _lastPressedAt == null ||
            now.difference(_lastPressedAt!) > doubleTapThreshold;

        if (isFirstTap) {
          setState(() {
            _lastPressedAt = now;
          });
          
          try {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.config.snackBarMessage ?? 'Tap back again to exit',
                  style: widget.config.snackBarTextStyle ??
                      TextStyle(
                        color: widget.config.snackBarTextColor ?? Colors.white,
                      ),
                ),
                backgroundColor: widget.config.snackBarBackgroundColor,
                duration: widget.config.snackBarDuration,
              ),
            );
          } catch (e) {
            // Log quietly if ScaffoldMessenger is not available
            debugPrint('DoubleTapToExit: Snackbar failed: $e');
          }
          return;
        }

        // It's a second tap (double tap)
        setState(() {
          _lastPressedAt = null; // Reset
        });
        
        try {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        } catch (_) {}

        final bool? exitApp = await _showExitDialog(context);
        if (exitApp == true) {
          await SystemNavigator.pop();
        }
      },
      child: widget.child,
    );
  }
}
