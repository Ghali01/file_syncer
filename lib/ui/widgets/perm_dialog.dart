import 'package:flutter/material.dart';

class PermissionDialog extends StatelessWidget {
  final String title;
  final String text;
  const PermissionDialog({
    Key? key,
    required this.title,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 350,
        height: 250,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              Expanded(child: Text(text)),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Ok'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
