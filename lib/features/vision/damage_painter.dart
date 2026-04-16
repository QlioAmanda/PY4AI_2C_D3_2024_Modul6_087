import 'package:flutter/material.dart';

class DamagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 1. Draw Target Box/Corner Brackets (Cyan/Blue Accent)
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double boxSize = 250.0;
    const double lineLength = 20.0;

    // Top Left
    canvas.drawLine(Offset(centerX - boxSize / 2, centerY - boxSize / 2),
        Offset(centerX - boxSize / 2 + lineLength, centerY - boxSize / 2), paint);
    canvas.drawLine(Offset(centerX - boxSize / 2, centerY - boxSize / 2),
        Offset(centerX - boxSize / 2, centerY - boxSize / 2 + lineLength), paint);

    // Top Right
    canvas.drawLine(Offset(centerX + boxSize / 2, centerY - boxSize / 2),
        Offset(centerX + boxSize / 2 - lineLength, centerY - boxSize / 2), paint);
    canvas.drawLine(Offset(centerX + boxSize / 2, centerY - boxSize / 2),
        Offset(centerX + boxSize / 2, centerY - boxSize / 2 + lineLength), paint);

    // Bottom Left
    canvas.drawLine(Offset(centerX - boxSize / 2, centerY + boxSize / 2),
        Offset(centerX - boxSize / 2 + lineLength, centerY + boxSize / 2), paint);
    canvas.drawLine(Offset(centerX - boxSize / 2, centerY + boxSize / 2),
        Offset(centerX - boxSize / 2, centerY + boxSize / 2 - lineLength), paint);

    // Bottom Right
    canvas.drawLine(Offset(centerX + boxSize / 2, centerY + boxSize / 2),
        Offset(centerX + boxSize / 2 - lineLength, centerY + boxSize / 2), paint);
    canvas.drawLine(Offset(centerX + boxSize / 2, centerY + boxSize / 2),
        Offset(centerX + boxSize / 2, centerY + boxSize / 2 - lineLength), paint);

    // Center Crosshair (+)
    final crosshairPaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    const double crossSize = 8.0;
    
    // Vertical line
    canvas.drawLine(Offset(centerX, centerY - crossSize), 
        Offset(centerX, centerY + crossSize), crosshairPaint);
    // Horizontal line
    canvas.drawLine(Offset(centerX - crossSize, centerY), 
        Offset(centerX + crossSize, centerY), crosshairPaint);

    // 2. TextPainter for "Searching for Road Damage..."
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    );

    const textSpan = TextSpan(
      text: 'Searching for Road Damage...',
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    // Calculate background rect for text (positioned below the target box)
    const paddingHorizontal = 12.0;
    const paddingVertical = 6.0;
    final textX = centerX - (textPainter.width / 2);
    final textY = centerY + (boxSize / 2) + 20.0; // Posisikan tepat di bawah kotak 250x250

    final bgRect = Rect.fromLTWH(
      textX - paddingHorizontal,
      textY - paddingVertical,
      textPainter.width + (paddingHorizontal * 2),
      textPainter.height + (paddingVertical * 2),
    );

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7) // Semi-transparent black 
      ..style = PaintingStyle.fill;

    // Draw background with rounded corners for high contrast
    canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(8.0)), bgPaint);

    // Draw text on top of the background
    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
