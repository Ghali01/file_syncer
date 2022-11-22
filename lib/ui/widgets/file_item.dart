import 'package:files_syncer/logic/models/file_model.dart';
import 'package:files_syncer/utils/colors.dart';
import 'package:flutter/material.dart';

class FileItem extends StatelessWidget {
  final FileModel data;
  const FileItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 100,
        child: Stack(
          children: [
            LayoutBuilder(
                builder: (_, box) => Container(
                      height: box.maxHeight,
                      width: data.progress * box.maxWidth / 100,
                      decoration: BoxDecoration(
                        color: AppColors.keppel.withOpacity(.4),
                      ),
                    )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    data.path,
                    style: const TextStyle(fontSize: 21),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${data.progress}%'),
                      Text(data.size.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
