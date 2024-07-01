import 'package:flutter/material.dart';

class MyBomb extends StatelessWidget {
  final child;
  bool revealed;
  bool flagged;
  final function;
  final functionLongPress;
  final functionDoublePress;

  MyBomb({this.child, required this.revealed, this.function, this.functionLongPress, required this.flagged, required this.functionDoublePress});

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
            color: revealed ? Colors.red[900] : Colors.brown[400],
            borderRadius: BorderRadius.circular(4)
          ),
          
          child: Center(
            child: Text(
                revealed ? child.toString() : ( flagged ? '🚩' : ''),
                style: const TextStyle(
                  fontSize: 16,
                ),
              )
          ),
        ),
      ),
    );
  }
}
