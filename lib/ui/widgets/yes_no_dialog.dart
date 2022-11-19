import 'package:flutter/material.dart';

class YesNoDialog extends StatelessWidget {
  final String title;
  final String text;
  const YesNoDialog({
    Key? key,
    required this.title,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 250,
        height: 150,
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24),
            ),
            Expanded(child: Text(text)),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
                const SizedBox(
                  width: 16,
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
