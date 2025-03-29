// ModernSvgLoader.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ModernSvgLoader extends StatefulWidget {
  final String? message;
  final String? svgAssetPath;
  final Color? backgroundColor;
  
  const ModernSvgLoader({
    Key? key,
    this.message = "Chargement en cours...",
    this.svgAssetPath = 'assets/education_loader.svg',
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  _ModernSvgLoaderState createState() => _ModernSvgLoaderState();
}

class _ModernSvgLoaderState extends State<ModernSvgLoader> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: Colors.blue[400],
      end: Colors.teal[400],
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        _colorAnimation.value ?? Colors.blue,
                        BlendMode.srcIn,
                      ),
                      child: SvgPicture.asset(
                        widget.svgAssetPath!,
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              widget.message!,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}