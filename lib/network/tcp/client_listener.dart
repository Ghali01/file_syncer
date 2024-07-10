abstract class IClientListener {
  // on directory data received
  void onDirectorySelected(Map data);
  // on server disconnected
  void onServerDisconnected();
}
