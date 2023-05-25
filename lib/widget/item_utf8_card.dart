import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

class ItemUtf8Card extends StatelessWidget {
  final NSPboardTypeModel model;
  final bool isSelected;

  ItemUtf8Card({required this.model, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 16, 10, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueAccent,width: isSelected ? 5.0 : 0.1,),
      ),
      child: SingleChildScrollView(
        child: Text(
          model.pvalue,
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
// class ItemUtf8Card extends StatefulWidget {
//   final NSPboardTypeModel model;
//
//   ItemUtf8Card({required this.model});
//
//   @override
//   _ItemUtf8CardState createState() => new _ItemUtf8CardState(model: model);
// }
//
// class _ItemUtf8CardState extends State<ItemUtf8Card> {
//   final NSPboardTypeModel model;
//   _ItemUtf8CardState({required this.model});
//
//   bool _isSelected = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _isSelected = !_isSelected;
//         });
//       },
//       onDoubleTap: () {
//         if (_isSelected) {
//           // 隐藏 window
//           print("object");
//         }
//       },
//       child: Container(
//         padding: EdgeInsets.fromLTRB(10, 16, 10, 0),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Colors.blueAccent,width: _isSelected ? 5.0 : 0.1,),
//         ),
//         child: SingleChildScrollView(
//           child: Text(
//             model.pvalue,
//           ),
//         ),
//       ),
//     );
//   }
// }