import 'package:files_syncer/logic/controllers/scan.dart';
import 'package:files_syncer/logic/repositories/tcp_clients.dart';
import 'package:files_syncer/network/tcp/scanner.dart';
import 'package:get_it/get_it.dart';
import 'package:network_info_plus/network_info_plus.dart';

final sl = GetIt.instance;

void init() async {
  //scan
  _scan();
}

void _scan() {
  sl.registerSingleton(NetworkInfo());
  sl.registerSingleton(NetworkScanner(sl()));

  sl.registerSingleton(TcpClientsRepository(sl()));
  sl.registerFactory(
    () => ScanCubit(sl()),
  );
}
