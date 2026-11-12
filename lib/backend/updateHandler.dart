import "dart:io";

import "package:desktop_updater/desktop_updater.dart";
import "package:path_provider/path_provider.dart";

import "json_file_update_recovery_store.dart";

// Replace this entire map with the exact "Public key map" printed by keygen.
const trustedReleasePublicKeys = <String, String>{
  "release-c83fe439d90fd7a0c2d34a53": "KTUsVXg3y79clnaphb94kMlcgi7sQmGRWz1d83PR3JQ="
};


String expectedPackageIdForCurrentPlatform() {
  if (Platform.isMacOS) return "com.demuenu.vrcwr";
  if (Platform.isWindows) return "vrcwr";
  if (Platform.isLinux) return "com.demuenu.vrcwr";
  throw UnsupportedError("desktop_updater requires a desktop platform.");
}

Future<JsonFileUpdateRecoveryStore> createUpdateRecoveryStore() async {
  final appSupportDirectory = await getApplicationSupportDirectory();
  final separator = Platform.pathSeparator;
  return JsonFileUpdateRecoveryStore(
    File(
      "${appSupportDirectory.path}${separator}desktop_updater"
      "${separator}pending-install-stable.json",
    ),
  );
}

Future<DesktopUpdaterController> createDesktopUpdaterController() async {
  final recoveryStore = await createUpdateRecoveryStore();

  return DesktopUpdaterController(
    appArchiveUrl: Uri.parse(
      "https://vrcwr.lunar-appupdater.download/app-archive.json",
    ),
    expectedPackageId: expectedPackageIdForCurrentPlatform(),
    trustedReleasePublicKeys: trustedReleasePublicKeys,
    recoveryStore: recoveryStore,
  );
}