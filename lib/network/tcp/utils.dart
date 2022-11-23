import 'dart:io';
import 'dart:typed_data';

class OPCodes {
  static const int Identification = 1;
  static const int HandShake = 2;
  static const int RejectHandShake = 3;
  static const int DirectorySelected = 4;
  static const int TransferData = 5;
  static const int ProgressChange = 6;
}
