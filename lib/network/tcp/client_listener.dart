abstract class IClientListener {
  // on directory data received
  void onDirectorySelected(Map data);
  // on server disconnected
  void onServerDisconnected();

  //on share file is received
  void onShareFile(Map data);
}
