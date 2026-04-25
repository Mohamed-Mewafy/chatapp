 
import 'package:flutter/material.dart';

class TopToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const TopToastWidget({required this.message, required this.isError, required this.onDismiss});

  @override
  State<TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<TopToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _offsetAnimation = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    
 
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(15),
              color: widget.isError ? Colors.redAccent : Colors.green.shade600,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    Icon(widget.isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.none, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}