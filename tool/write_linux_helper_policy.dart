import "dart:convert";
import "dart:io";
import "package:cryptography/cryptography.dart";

Future<String> _sha256Hex(File file) async {
  final bytes = await file.readAsBytes();
  final hash = await Sha256().hash(bytes);
  return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, "0")).join();
}

Future<void> main(List<String> args) async {
  final bundlePath = args.isNotEmpty
      ? args.first
      : "build/linux/x64/release/bundle";
  final bundleDir = Directory(bundlePath);
  if (!await bundleDir.exists()) {
    stderr.writeln("Bundle directory not found: ${bundleDir.path}");
    exit(1);
  }

  final executable = File("${bundleDir.path}/VRCWR");
  final helper = File("${bundleDir.path}/lib/desktop-updater-helper");
  if (!await executable.exists()) {
    stderr.writeln("Executable not found: ${executable.path}");
    exit(1);
  }
  if (!await helper.exists()) {
    stderr.writeln("Helper binary not found: ${helper.path}");
    exit(1);
  }

  final keysFile = File("desktop_updater.keys.json");
  final keysJson =
      jsonDecode(await keysFile.readAsString()) as Map<String, dynamic>;
  final publicKeys =
      (keysJson["publicKeys"] as Map<String, dynamic>).entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

  const packageId = "com.demuenu.vrcwr";

  // Keys must remain in strict alphabetical order for canonical_json check:
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
    "helperServiceId": "$packageId.helper",
    "minimumHelperProtocolVersion": 1,
    "policyId": "$packageId.portable",
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
  final policyFile = File(
    "${helper.parent.path}/desktop-updater-helper.policy.json",
  );
  await policyFile.writeAsString(canonicalPolicy, flush: true);

  await Process.run("chmod", ["755", helper.parent.path]);
  await Process.run("chmod", ["755", helper.path]);
  await Process.run("chmod", ["600", policyFile.path]);

  stdout.writeln("Wrote canonical Linux helper policy: ${policyFile.path}");
}