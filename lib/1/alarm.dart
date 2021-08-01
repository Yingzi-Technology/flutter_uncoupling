import 'package:flutter/widgets.dart';

class Sub11 extends StatefulWidget {
  @override
  _Sub11State createState() => _Sub11State();
}

class _Sub11State extends State<Sub11> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('data'),
    );
  }
}

Map alarm = {
///@@[demo.alarm]@begin
  "key1" : "我是要解耦的内容",      
///@@[demo.alarm]@end               
};

