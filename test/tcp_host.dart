import 'dart:convert';
import 'dart:io';

void main() async {
  Socket socket = await Socket.connect('127.0.0.1', 48510);
  socket.listen((event) {
    print(event);
    print(utf8.decode(event));
  });
  socket.add([1]);
  await Future.delayed(const Duration(seconds: 2));
  socket.add([2, ...utf8.encode('test')]);
}
