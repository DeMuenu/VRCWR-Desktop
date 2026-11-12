import "dart:io";

import "package:desktop_updater/desktop_updater.dart";
import "package:path_provider/path_provider.dart";

import "json_file_update_recovery_store.dart";

const trustedReleasePublicKeys = <String, String>{
  "release-c83fe439d90fd7a0c2d34a53":
      "KTUsVXg3y79clnaphb94kMlcgi7sQmGRWz1d83PR3JQ="
};

String expectedPackageIdForCurrentPlatform() {
  if (Platform.isMacOS) return "com.demuenu.vrcwr";
  if (Platform.isWindows) return "vrcwr";
  if (Platform.isLinux) return "com.demuenu.vrcwr";
  throw UnsupportedError("desktop_updater requires a desktop platform.");
}

Future<void> _ensureWindowsCodeSigningCertTrusted() async {
  if (!Platform.isWindows) return;

  final exeDir = File(Platform.resolvedExecutable).parent;
  final cerFile = File("${exeDir.path}${Platform.pathSeparator}demuenu_codesign.cer");
  if (!await cerFile.exists()) return;

  // Check if already installed in CurrentUser\TrustedPublisher and CurrentUser\Root
  const checkAndInstallScript = r'''
$cerPath = $args[0]
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
foreach ($storeName in @("Root", "TrustedPublisher")) {
  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($storeName, "CurrentUser")
  $store.Open("ReadWrite")
  $exists = $store.Certificates.Find("FindByThumbprint", $cert.Thumbprint, $false).Count -gt 0
  if (-not $exists) {
    $store.Add($cert)
  }
  $store.Close()
}
''';

  await Process.run("powershell", [
    "-NoProfile",
    "-NonInteractive",
    "-WindowStyle",
    "Hidden",
    "-Command",
    checkAndInstallScript,
    cerFile.path,
  ]);
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
  await _ensureWindowsCodeSigningCertTrusted();
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