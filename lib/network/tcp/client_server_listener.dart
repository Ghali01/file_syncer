abstract class IClientServerListener {
  //on the other device is disconnected
  void onDisconnected();
  //on download progress received from the client
  void onProgressChanged(Map data);
  //when the data of the transfer (the list of files will be transferred received)
  void onReceiveTransferData(List files);
  //on the client complete a transfer task
  void onTaskCompleted(int port);
}
