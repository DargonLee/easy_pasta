import 'package:flutter/material.dart';
import 'package:easy_pasta/db/constanst_helper.dart';

class Counter extends StatefulWidget {
  final ValueChanged<int>? onChanged;

  const Counter({Key? key, this.onChanged}) : super(key: key);

  @override
  _CounterState createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 50;

  void _getMaxItemStore() async{
    _count = await SharedPreferenceHelper.getMaxItemStoreKey();
    setState(() {
    });
  }

  @override
  void initState() {
    _getMaxItemStore();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            if (_count == 10) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('最小不低于 10'),
                  action: SnackBarAction(
                    label: 'Ok',
                    onPressed: () {},
                  ),
                ),
              );
              return;
            }
            setState(() {
              _count--;
            });
            widget.onChanged != null ? widget.onChanged!(_count) : null;
            SharedPreferenceHelper.setMaxItemStoreKey(_count);
            SharedPreferenceHelper.getMaxItemStoreKey();
          },
          icon: const Icon(Icons.remove),
        ),
        Text(
          "$_count",
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _count++;
            });
            widget.onChanged != null ? widget.onChanged!(_count) : null;
            SharedPreferenceHelper.setMaxItemStoreKey(_count);
          },
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
