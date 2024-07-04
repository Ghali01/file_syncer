import 'package:files_syncer/network/tcp/server.dart';

/// the classes need to implement this interface to listen on [AppServer] events
abstract class IServerListener {
  /// on a new connection comes to the server
  void onNewConnection(ClientConnectionServer connection);
}
