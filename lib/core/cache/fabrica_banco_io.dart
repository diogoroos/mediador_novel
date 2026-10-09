import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

DatabaseFactory fabricaBanco() => databaseFactoryIo;

Future<String> caminhoBanco() async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/novel.db';
}
