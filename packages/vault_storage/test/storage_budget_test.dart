/// `StorageBudgetImpl` (§7.6): accounting by class, the pressure floor,
/// and the honest "no measurement = no refusal" behaviour.
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_storage/vault_storage.dart';

void main() {
  late Directory root;
  late BlobPaths paths;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('dokki_budget_');
    paths = BlobPaths(root.path);
  });

  tearDown(() => root.delete(recursive: true));

  Future<void> put(StorageClass cls, String id, int bytes) async {
    final path = paths.absolute(BlobPaths.relPathFor(cls, id));
    await File(path).parent.create(recursive: true);
    await File(path).writeAsBytes(List.filled(bytes, 7));
  }

  test('accounts bytes per storage class', () async {
    await put(StorageClass.asset, 'aa0001', 1000);
    await put(StorageClass.asset, 'aa0002', 500);
    await put(StorageClass.thumbnail, 'bb0001', 200);
    await put(StorageClass.exportArtifact, 'cc0001', 300);
    await put(StorageClass.syncLog, 'dd0001', 100);
    final budget = StorageBudgetImpl(paths: paths, freeSpace: () async => null);
    final report = (await budget.check()).okOrNull!;
    expect(report.assetBytes, 1500);
    expect(report.thumbnailBytes, 200);
    expect(report.exportBytes, 300);
    expect(report.logBytes, 100);
    expect(report.totalBytes, 2100);
    expect(report.underPressure, isFalse, reason: 'null free = no refusal');
  });

  test('under the floor is pressure; above it is not', () async {
    final tight = StorageBudgetImpl(
      paths: paths,
      freeSpace: () async => 10,
      floorBytes: 300,
    );
    final tightReport = (await tight.check()).okOrNull!;
    expect(tightReport.underPressure, isTrue);

    final roomy = StorageBudgetImpl(
      paths: paths,
      freeSpace: () async => 1 << 40,
    );
    expect((await roomy.check()).okOrNull!.underPressure, isFalse);
  });

  test('part files are ignored (in-flight writes are not yet real)', () async {
    await put(StorageClass.asset, 'aa0001', 1000);
    final part = File(
      '${paths.absolute(BlobPaths.relPathFor(StorageClass.asset, 'aa0002'))}.part',
    );
    await part.parent.create(recursive: true);
    await part.writeAsBytes(List.filled(999, 1));
    final budget = StorageBudgetImpl(paths: paths, freeSpace: () async => null);
    expect((await budget.check()).okOrNull!.assetBytes, 1000);
  });
}
