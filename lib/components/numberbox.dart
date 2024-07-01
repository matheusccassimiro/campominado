import 'package:flutter/material.dart';

class MyNumberBox extends StatelessWidget {
  final child;
  bool revealed;
  bool flagged;
  final function;
  final functionLongPress;
  final functionDoublePress;


  MyNumberBox({this.child, required this.revealed, this.function, this.functionLongPress, required this.flagged, required this.functionDoublePress});



  Color? getColor(child) {
    Color? textColor;
    switch (child) {
      case 1:
        textColor = Colors.blue[900];
        break;
      case 2:
        textColor = Colors.green[900];
        break;
      case 3:
        textColor = Color(0xFFFFCC80);
        break;
      case 4:
        textColor = Colors.deepPurple[900];
        break;
      case 5:
        textColor = Colors.red[900];
        break;
      case 6:
        textColor = Colors.redAccent[900];
        break;
      case 7:
        textColor = Colors.green[900];
        break;
      case 8:
        textColor = Colors.black38;
        break;
      case 0:
        textColor = Colors.green;
        break;
      default:
        textColor = Colors.black38;
        break;
    }
    return textColor;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: function,
      onLongPress: functionLongPress,
      onDoubleTap: functionDoublePress,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Container(
          decoration: BoxDecoration(
            color: revealed ? Colors.brown[300] : Colors.brown[400],
            borderRadius: BorderRadius.circular(4)
          ),

          child: Center(
              child: Text(
                flagged ? "🚩" : (revealed ? (child == 0 ? '' : child.toString()) : ''),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: getColor(child),
                ),
              )
          ),
        ),
      ),
    );
  }
}
