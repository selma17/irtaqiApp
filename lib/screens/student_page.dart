import 'package:flutter/material.dart';

class StudentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("واجهة الطالب")),
      body: Center(child: Text("أهلا بك، أيها الطالب")),
    );
  }
}
