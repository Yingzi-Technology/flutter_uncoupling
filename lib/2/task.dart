import 'package:flutter/material.dart';

class Sub2 extends StatefulWidget {
  @override
  _Sub2State createState() => _Sub2State();
}

class _Sub2State extends State<Sub2> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: GestureDetector(
        onTap: (){
///@@[demo.task]@begin
          print('---我---');
          print('---是---');
          print('---要---');
          print('---替--');
          print('---换--');
          print('---的--');
          print('---内--');
          print('---容--'); 
///@@[demo.task]@end                                
        },        
        child: Text('click'),
      ),
    );
  }
}