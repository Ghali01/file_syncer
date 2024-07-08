import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:network_info_plus/network_info_plus.dart';

typedef ipAddress = List<List<int>>;

class NetworkScanner {
  final NetworkInfo networkInfo;

  NetworkScanner(this.networkInfo);

  Future<String> get subnetMask async => (await networkInfo.getWifiSubmask())!;
  Future<String> get deviceIp async => (await networkInfo.getWifiIP())!;

  /// convert [int] to 8-integer list as binary
  List<int> _intToBin(int num) {
    List<int> res = [];
    while (num > 0) {
      res.add(num % 2);
      num = num ~/ 2;
    }
    res = [...res, ...List.generate(8 - res.length, (_) => 0)];
    return res;
  }

  /// convert a string address to binary
  ipAddress _addressToBin(String address) {
    final ipAddress res = [];
    for (final dig in address.split('.')) {
      res.add(_intToBin(int.parse(dig)));
    }
    return res;
  }

  /// multiple subnet and ip to get the network ip
  ipAddress _multiple(ipAddress address1, ipAddress address2) {
    ipAddress res = [];
    for (var i = 0; i < 4; i++) {
      final List<int> dig = [];
      for (var j = 0; j < 8; j++) {
        dig.add(address1[i][j] * address2[i][j]);
      }
      res.add(dig);
    }
    return res;
  }

  /// convert a byte(8-integer lit) to [int]
  int _binToInt(List<int> binary) {
    int res = 0;

    for (var i = 0; i < 8; i++) {
      res += (binary[i] * pow(2, i)).toInt();
    }

    return res;
  }

  /// convert a binary address to string
  String addressToString(ipAddress address) {
    return address
        .map(
          (e) => _binToInt(e),
        )
        .join('.');
  }

  /// returns the network ip address as [String]
  Future<String> getNetworkIP() async {
    return addressToString(await _getNetworkIPBin());
  }

  /// compare between tow binary addresses
  bool _compare(ipAddress address1, ipAddress address2) {
    return addressToString(address1) == addressToString(address2);
  }

  /// get the last device ip
  Future<ipAddress> _getLastIPBin() async {
    final networkIp = await _getNetworkIPBin();

    final subnetBin = _addressToBin(await subnetMask);
    final ipAddress address = [];
    for (var i = 0; i < 4; i++) {
      final List<int> dig = [];
      for (var j = 0; j < 8; j++) {
        if (subnetBin[i][j] == 1) {
          dig.add(networkIp[i][j]);
        } else {
          dig.add(1);
        }
      }
      address.add(dig);
    }
    // ignore broadcast address
    address[3] = _intToBin(_binToInt(address[3]) - 1);
    return address;
  }

  Future<String> getLastIP() async => addressToString(await _getLastIPBin());

  Future<List<String>> getIpsList() async {
    final List<String> addresses = [];
    ipAddress address = await _getNetworkIPBin();
    ipAddress lastIp = await _getLastIPBin();
    for (var i = 3; i >= 0; i--) {
      if (_compare(address, lastIp)) {
        break;
      }
      while (_binToInt(address[i]) < 254) {
        address[i] = _intToBin(_binToInt(address[i]) + 1);
        addresses.add(addressToString(address));
        if (_compare(address, lastIp)) {
          break;
        }
      }
    }
    return addresses;
  }

  /// returns the network ip address as binary
  Future<ipAddress> _getNetworkIPBin() async {
    final deviceIpBin = _addressToBin(await deviceIp);
    final subnetBin = _addressToBin(await subnetMask);
    final addressBin = _multiple(deviceIpBin, subnetBin);
    return addressBin;
  }

  Future<Stream<String>> scan(int port,
      {Duration timeout = const Duration(seconds: 7)}) async {
    final out = StreamController<String>();
    final addresses = await getIpsList();
    final List<Future<Socket>> futures = [];

    for (final address in addresses) {
      final future = Socket.connect(address, port, timeout: timeout);
      futures.add(future);
      future.then((s) {
        out.sink.add(s.address.address);
        s.destroy();
      }).onError(
        (error, stackTrace) {},
      );
    }

    Future.wait<Socket>(futures)
        .then<void>((sockets) => out.close())
        .catchError((dynamic e) => out.close());

    return out.stream;
  }
}
