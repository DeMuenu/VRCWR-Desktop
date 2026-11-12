import "dart:convert";
import "dart:io";
import "package:cryptography/cryptography.dart";
import "package:yaml/yaml.dart";

Future<String> _sha256Hex(File file) async {
  final bytes = await file.readAsBytes();
  final hash = await Sha256().hash(bytes);
  return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, "0")).join();
}

Future<File?> _findExecutable(Directory bundleDir) async {
  for (final name in ["vrcwr.exe", "VRCWR.exe"]) {
    final f = File("${bundleDir.path}/$name");
    if (await f.exists()) return f;
  }
  return null;
}

Future<File?> _findHelper(Directory bundleDir) async {
  final candidates = [
    File("${bundleDir.path}/desktop_updater_install_helper.exe"),
    File("${bundleDir.path}/data/desktop_updater_install_helper.exe"),
    File("${bundleDir.path}/bin/desktop_updater_install_helper.exe"),
  ];
  for (final candidate in candidates) {
    if (await candidate.exists()) return candidate;
  }
  await for (final entity in bundleDir.list(recursive: true)) {
    if (entity is File &&
        entity.uri.pathSegments.last.toLowerCase() ==
            "desktop_updater_install_helper.exe") {
      return entity;
    }
  }
  return null;
}

Future<String> _resolvePackageId(List<String> args) async {
  if (args.length >= 2 && args[1].trim().isNotEmpty) {
    return args[1].trim().toLowerCase();
  }
  final pubspecFile = File("pubspec.yaml");
  final pubspec = loadYaml(await pubspecFile.readAsString()) as YamlMap;
  return (pubspec["name"] as String).toLowerCase();
}

Future<void> _signBinariesAndCopyCert({
  required Directory bundleDir,
  required File executable,
  required File helper,
}) async {
  final pfxFile = File("tool/demuenu_codesign.pfx");
  final cerFile = File("tool/demuenu_codesign.cer");

  if (!await pfxFile.exists() || !await cerFile.exists()) {
    stderr.writeln(
      "Missing tool/demuenu_codesign.pfx or tool/demuenu_codesign.cer. Run Step 1 first.",
    );
    exit(1);
  }

  // Copy the public .cer file into the Windows release folder so the app can install it
  await cerFile.copy("${bundleDir.path}/demuenu_codesign.cer");

  final psScript = '''
\$ErrorActionPreference = "Stop"
\$pwd = ConvertTo-SecureString -String "vrcwr-signing-key" -Force -AsPlainText
\$cert = Get-PfxCertificate -FilePath "${pfxFile.absolute.path}" -Password \$pwd
Set-AuthenticodeSignature -FilePath "${executable.absolute.path}" -Certificate \$cert | Out-Null
Set-AuthenticodeSignature -FilePath "${helper.absolute.path}" -Certificate \$cert | Out-Null
''';

  final result = await Process.run("powershell", [
    "-NoProfile",
    "-NonInteractive",
    "-Command",
    psScript,
  ]);

  if (result.exitCode != 0) {
    stderr.writeln("Failed to Authenticode-sign Windows binaries:\n${result.stderr}");
    exit(1);
  }
}

Future<void> main(List<String> args) async {
  final bundlePath = args.isNotEmpty
      ? args.first
      : "build/windows/x64/runner/Release";
  final bundleDir = Directory(bundlePath);
  if (!await bundleDir.exists()) {
    stderr.writeln("Bundle directory not found: ${bundleDir.path}");
    exit(1);
  }

  final executable = await _findExecutable(bundleDir);
  if (executable == null) {
    stderr.writeln("Executable (vrcwr.exe) not found in: ${bundleDir.path}");
    exit(1);
  }

  final helper = await _findHelper(bundleDir);
  if (helper == null) {
    stderr.writeln(
      "Helper binary (desktop_updater_install_helper.exe) not found inside: ${bundleDir.path}",
    );
    exit(1);
  }

  // 1. Sign BOTH .exe files first (before computing SHA-256!)
  await _signBinariesAndCopyCert(
    bundleDir: bundleDir,
    executable: executable,
    helper: helper,
  );

  final keysFile = File("desktop_updater.keys.json");
  final keysJson =
      jsonDecode(await keysFile.readAsString()) as Map<String, dynamic>;
  final publicKeys =
      (keysJson["publicKeys"] as Map<String, dynamic>).entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

  final packageId = await _resolvePackageId(args);
  final lowerId = "com.demuenu.$packageId";

  // 2. Compute SHA-256 hashes of the NOW-SIGNED .exe files
  final policyMap = <String, Object?>{
    "allowedApplicationSigner": <String, Object?>{
      "kind": "sha256",
      "value": await _sha256Hex(executable),
    },
    "allowedHelperSigner": <String, Object?>{
      "kind": "sha256",
      "value": await _sha256Hex(helper),
    },
    "allowedInstallRoots": <Object?>[],
    "allowedStrategies": <Object?>[
      <String, Object?>{
        "provider": "platformDirectory",
        "strategy": "directoryReplace",
      },
    ],
    "allowedTargetClasses": <Object?>["sameUserWritable"],
    "applicationPackageId": packageId,
    "helperServiceId": "$lowerId.helper",
    "minimumHelperProtocolVersion": 1,
    "policyId": "$lowerId.portable",
    "policyVersion": 1,
    "releaseRootPublicKeys": [
      for (final entry in publicKeys)
        <String, Object?>{
          "algorithm": "ed25519",
          "keyId": entry.key,
          "publicKeyBase64": entry.value as String,
        },
    ],
  };

  final canonicalPolicy = jsonEncode(policyMap);

  final targetDirs = <String>{
    bundleDir.path,
    helper.parent.path,
  };

  const fileNames = <String>[
    "desktop_updater_install_helper.policy.json",
    "desktop_updater_helper_policy.json",
    "desktop-updater-helper.policy.json",
  ];

  for (final dir in targetDirs) {
    for (final name in fileNames) {
      final policyFile = File("$dir/$name");
      await policyFile.writeAsString(canonicalPolicy, flush: true);
    }
  }

  final identityFile = File("${bundleDir.path}/.desktop_updater_install_identity.json");
  await identityFile.writeAsString(
    jsonEncode(<String, Object?>{"packageId": packageId, "schemaVersion": 1}),
    flush: true,
  );

  stdout.writeln(
    "Signed Windows binaries and wrote canonical helper policy (packageId: $packageId)",
  );
}