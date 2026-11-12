import "dart:convert";
import "dart:io";
import "package:cryptography/cryptography.dart";
import "package:yaml/yaml.dart";

Future<String> _sha256Hex(File file) async {
  final bytes = await file.readAsBytes();
  final hash = await Sha256().hash(bytes);
  return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, "0")).join();
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
    return args[1].trim();
  }
  final pubspecFile = File("pubspec.yaml");
  final pubspec = loadYaml(await pubspecFile.readAsString()) as YamlMap;
  return pubspec["name"] as String;
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

  final executable = File("${bundleDir.path}/VRCWR.exe");
  if (!await executable.exists()) {
    stderr.writeln("Executable not found: ${executable.path}");
    exit(1);
  }

  final helper = await _findHelper(bundleDir);
  if (helper == null) {
    stderr.writeln(
      "Helper binary (desktop_updater_install_helper.exe) not found inside: ${bundleDir.path}",
    );
    exit(1);
  }

  final keysFile = File("desktop_updater.keys.json");
  final keysJson =
      jsonDecode(await keysFile.readAsString()) as Map<String, dynamic>;
  final publicKeys =
      (keysJson["publicKeys"] as Map<String, dynamic>).entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

  final packageId = await _resolvePackageId(args);

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

  final targetDirs = <String>{
    bundleDir.path,
    helper.parent.path,
  };

  const fileNames = <String>[
    "desktop_updater_helper_policy.json",
    "desktop_updater_install_helper.policy.json",
    "desktop-updater-helper.policy.json",
  ];

  for (final dir in targetDirs) {
    for (final name in fileNames) {
      final policyFile = File("$dir/$name");
      await policyFile.writeAsString(canonicalPolicy, flush: true);
    }
  }

  stdout.writeln(
    "Wrote canonical Windows helper policy (packageId: $packageId) in ${targetDirs.join(', ')}",
  );
}