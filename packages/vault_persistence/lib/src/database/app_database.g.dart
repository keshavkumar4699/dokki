// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DevicesTable extends Devices with TableInfo<$DevicesTable, DeviceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSelfMeta = const VerificationMeta('isSelf');
  @override
  late final GeneratedColumn<bool> isSelf = GeneratedColumn<bool>(
    'is_self',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_self" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($DevicesTable.$convertercreatedAt);
  static const VerificationMeta _lastSeenHlcMeta = const VerificationMeta(
    'lastSeenHlc',
  );
  @override
  late final GeneratedColumn<String> lastSeenHlc = GeneratedColumn<String>(
    'last_seen_hlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastSyncedAt =
      GeneratedColumn<int>(
        'last_synced_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($DevicesTable.$converterlastSyncedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    isSelf,
    createdAt,
    lastSeenHlc,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('is_self')) {
      context.handle(
        _isSelfMeta,
        isSelf.isAcceptableOrUnknown(data['is_self']!, _isSelfMeta),
      );
    }
    if (data.containsKey('last_seen_hlc')) {
      context.handle(
        _lastSeenHlcMeta,
        lastSeenHlc.isAcceptableOrUnknown(
          data['last_seen_hlc']!,
          _lastSeenHlcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      isSelf: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_self'],
      )!,
      createdAt: $DevicesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      lastSeenHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_seen_hlc'],
      ),
      lastSyncedAt: $DevicesTable.$converterlastSyncedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_synced_at'],
        ),
      ),
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterlastSyncedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterlastSyncedAtn =
      NullAwareTypeConverter.wrap($converterlastSyncedAt);
}

class DeviceData extends DataClass implements Insertable<DeviceData> {
  final String id;
  final String? label;
  final bool isSelf;
  final DateTime createdAt;
  final String? lastSeenHlc;
  final DateTime? lastSyncedAt;
  const DeviceData({
    required this.id,
    this.label,
    required this.isSelf,
    required this.createdAt,
    this.lastSeenHlc,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['is_self'] = Variable<bool>(isSelf);
    {
      map['created_at'] = Variable<int>(
        $DevicesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || lastSeenHlc != null) {
      map['last_seen_hlc'] = Variable<String>(lastSeenHlc);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(
        $DevicesTable.$converterlastSyncedAtn.toSql(lastSyncedAt),
      );
    }
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      isSelf: Value(isSelf),
      createdAt: Value(createdAt),
      lastSeenHlc: lastSeenHlc == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenHlc),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory DeviceData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceData(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String?>(json['label']),
      isSelf: serializer.fromJson<bool>(json['isSelf']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastSeenHlc: serializer.fromJson<String?>(json['lastSeenHlc']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String?>(label),
      'isSelf': serializer.toJson<bool>(isSelf),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastSeenHlc': serializer.toJson<String?>(lastSeenHlc),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  DeviceData copyWith({
    String? id,
    Value<String?> label = const Value.absent(),
    bool? isSelf,
    DateTime? createdAt,
    Value<String?> lastSeenHlc = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => DeviceData(
    id: id ?? this.id,
    label: label.present ? label.value : this.label,
    isSelf: isSelf ?? this.isSelf,
    createdAt: createdAt ?? this.createdAt,
    lastSeenHlc: lastSeenHlc.present ? lastSeenHlc.value : this.lastSeenHlc,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  DeviceData copyWithCompanion(DevicesCompanion data) {
    return DeviceData(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      isSelf: data.isSelf.present ? data.isSelf.value : this.isSelf,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSeenHlc: data.lastSeenHlc.present
          ? data.lastSeenHlc.value
          : this.lastSeenHlc,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceData(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('isSelf: $isSelf, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSeenHlc: $lastSeenHlc, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, label, isSelf, createdAt, lastSeenHlc, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceData &&
          other.id == this.id &&
          other.label == this.label &&
          other.isSelf == this.isSelf &&
          other.createdAt == this.createdAt &&
          other.lastSeenHlc == this.lastSeenHlc &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class DevicesCompanion extends UpdateCompanion<DeviceData> {
  final Value<String> id;
  final Value<String?> label;
  final Value<bool> isSelf;
  final Value<DateTime> createdAt;
  final Value<String?> lastSeenHlc;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.isSelf = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSeenHlc = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    this.label = const Value.absent(),
    this.isSelf = const Value.absent(),
    required DateTime createdAt,
    this.lastSeenHlc = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt);
  static Insertable<DeviceData> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<bool>? isSelf,
    Expression<int>? createdAt,
    Expression<String>? lastSeenHlc,
    Expression<int>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (isSelf != null) 'is_self': isSelf,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSeenHlc != null) 'last_seen_hlc': lastSeenHlc,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith({
    Value<String>? id,
    Value<String?>? label,
    Value<bool>? isSelf,
    Value<DateTime>? createdAt,
    Value<String?>? lastSeenHlc,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      isSelf: isSelf ?? this.isSelf,
      createdAt: createdAt ?? this.createdAt,
      lastSeenHlc: lastSeenHlc ?? this.lastSeenHlc,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (isSelf.present) {
      map['is_self'] = Variable<bool>(isSelf.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $DevicesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (lastSeenHlc.present) {
      map['last_seen_hlc'] = Variable<String>(lastSeenHlc.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(
        $DevicesTable.$converterlastSyncedAtn.toSql(lastSyncedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('isSelf: $isSelf, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSeenHlc: $lastSeenHlc, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<Uint8List> value = GeneratedColumn<Uint8List>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaData extends DataClass implements Insertable<AppMetaData> {
  final String key;
  final Uint8List value;
  const AppMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<Uint8List>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<Uint8List>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<Uint8List>(value),
    };
  }

  AppMetaData copyWith({String? key, Uint8List? value}) =>
      AppMetaData(key: key ?? this.key, value: value ?? this.value);
  AppMetaData copyWithCompanion(AppMetaCompanion data) {
    return AppMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, $driftBlobEquality.hash(value));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaData &&
          other.key == this.key &&
          $driftBlobEquality.equals(other.value, this.value));
}

class AppMetaCompanion extends UpdateCompanion<AppMetaData> {
  final Value<String> key;
  final Value<Uint8List> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required Uint8List value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetaData> custom({
    Expression<String>? key,
    Expression<Uint8List>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<Uint8List>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<Uint8List>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyEpochsTable extends KeyEpochs
    with TableInfo<$KeyEpochsTable, KeyEpochData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyEpochsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _epochMeta = const VerificationMeta('epoch');
  @override
  late final GeneratedColumn<int> epoch = GeneratedColumn<int>(
    'epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($KeyEpochsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> retiredAt =
      GeneratedColumn<int>(
        'retired_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($KeyEpochsTable.$converterretiredAtn);
  static const VerificationMeta _wrapAlgMeta = const VerificationMeta(
    'wrapAlg',
  );
  @override
  late final GeneratedColumn<String> wrapAlg = GeneratedColumn<String>(
    'wrap_alg',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wrappedMkDeviceMeta = const VerificationMeta(
    'wrappedMkDevice',
  );
  @override
  late final GeneratedColumn<Uint8List> wrappedMkDevice =
      GeneratedColumn<Uint8List>(
        'wrapped_mk_device',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _wrappedMkRecoveryMeta = const VerificationMeta(
    'wrappedMkRecovery',
  );
  @override
  late final GeneratedColumn<Uint8List> wrappedMkRecovery =
      GeneratedColumn<Uint8List>(
        'wrapped_mk_recovery',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _kdfParamsJsonMeta = const VerificationMeta(
    'kdfParamsJson',
  );
  @override
  late final GeneratedColumn<String> kdfParamsJson = GeneratedColumn<String>(
    'kdf_params_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keystoreAliasMeta = const VerificationMeta(
    'keystoreAlias',
  );
  @override
  late final GeneratedColumn<String> keystoreAlias = GeneratedColumn<String>(
    'keystore_alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strongboxMeta = const VerificationMeta(
    'strongbox',
  );
  @override
  late final GeneratedColumn<bool> strongbox = GeneratedColumn<bool>(
    'strongbox',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("strongbox" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    epoch,
    createdAt,
    retiredAt,
    wrapAlg,
    wrappedMkDevice,
    wrappedMkRecovery,
    kdfParamsJson,
    keystoreAlias,
    strongbox,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_epochs';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyEpochData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('epoch')) {
      context.handle(
        _epochMeta,
        epoch.isAcceptableOrUnknown(data['epoch']!, _epochMeta),
      );
    }
    if (data.containsKey('wrap_alg')) {
      context.handle(
        _wrapAlgMeta,
        wrapAlg.isAcceptableOrUnknown(data['wrap_alg']!, _wrapAlgMeta),
      );
    } else if (isInserting) {
      context.missing(_wrapAlgMeta);
    }
    if (data.containsKey('wrapped_mk_device')) {
      context.handle(
        _wrappedMkDeviceMeta,
        wrappedMkDevice.isAcceptableOrUnknown(
          data['wrapped_mk_device']!,
          _wrappedMkDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wrappedMkDeviceMeta);
    }
    if (data.containsKey('wrapped_mk_recovery')) {
      context.handle(
        _wrappedMkRecoveryMeta,
        wrappedMkRecovery.isAcceptableOrUnknown(
          data['wrapped_mk_recovery']!,
          _wrappedMkRecoveryMeta,
        ),
      );
    }
    if (data.containsKey('kdf_params_json')) {
      context.handle(
        _kdfParamsJsonMeta,
        kdfParamsJson.isAcceptableOrUnknown(
          data['kdf_params_json']!,
          _kdfParamsJsonMeta,
        ),
      );
    }
    if (data.containsKey('keystore_alias')) {
      context.handle(
        _keystoreAliasMeta,
        keystoreAlias.isAcceptableOrUnknown(
          data['keystore_alias']!,
          _keystoreAliasMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keystoreAliasMeta);
    }
    if (data.containsKey('strongbox')) {
      context.handle(
        _strongboxMeta,
        strongbox.isAcceptableOrUnknown(data['strongbox']!, _strongboxMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {epoch};
  @override
  KeyEpochData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyEpochData(
      epoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}epoch'],
      )!,
      createdAt: $KeyEpochsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      retiredAt: $KeyEpochsTable.$converterretiredAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}retired_at'],
        ),
      ),
      wrapAlg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wrap_alg'],
      )!,
      wrappedMkDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}wrapped_mk_device'],
      )!,
      wrappedMkRecovery: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}wrapped_mk_recovery'],
      ),
      kdfParamsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kdf_params_json'],
      ),
      keystoreAlias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keystore_alias'],
      )!,
      strongbox: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}strongbox'],
      )!,
    );
  }

  @override
  $KeyEpochsTable createAlias(String alias) {
    return $KeyEpochsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterretiredAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterretiredAtn =
      NullAwareTypeConverter.wrap($converterretiredAt);
}

class KeyEpochData extends DataClass implements Insertable<KeyEpochData> {
  final int epoch;
  final DateTime createdAt;
  final DateTime? retiredAt;
  final String wrapAlg;
  final Uint8List wrappedMkDevice;
  final Uint8List? wrappedMkRecovery;
  final String? kdfParamsJson;
  final String keystoreAlias;
  final bool strongbox;
  const KeyEpochData({
    required this.epoch,
    required this.createdAt,
    this.retiredAt,
    required this.wrapAlg,
    required this.wrappedMkDevice,
    this.wrappedMkRecovery,
    this.kdfParamsJson,
    required this.keystoreAlias,
    required this.strongbox,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['epoch'] = Variable<int>(epoch);
    {
      map['created_at'] = Variable<int>(
        $KeyEpochsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || retiredAt != null) {
      map['retired_at'] = Variable<int>(
        $KeyEpochsTable.$converterretiredAtn.toSql(retiredAt),
      );
    }
    map['wrap_alg'] = Variable<String>(wrapAlg);
    map['wrapped_mk_device'] = Variable<Uint8List>(wrappedMkDevice);
    if (!nullToAbsent || wrappedMkRecovery != null) {
      map['wrapped_mk_recovery'] = Variable<Uint8List>(wrappedMkRecovery);
    }
    if (!nullToAbsent || kdfParamsJson != null) {
      map['kdf_params_json'] = Variable<String>(kdfParamsJson);
    }
    map['keystore_alias'] = Variable<String>(keystoreAlias);
    map['strongbox'] = Variable<bool>(strongbox);
    return map;
  }

  KeyEpochsCompanion toCompanion(bool nullToAbsent) {
    return KeyEpochsCompanion(
      epoch: Value(epoch),
      createdAt: Value(createdAt),
      retiredAt: retiredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(retiredAt),
      wrapAlg: Value(wrapAlg),
      wrappedMkDevice: Value(wrappedMkDevice),
      wrappedMkRecovery: wrappedMkRecovery == null && nullToAbsent
          ? const Value.absent()
          : Value(wrappedMkRecovery),
      kdfParamsJson: kdfParamsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(kdfParamsJson),
      keystoreAlias: Value(keystoreAlias),
      strongbox: Value(strongbox),
    );
  }

  factory KeyEpochData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyEpochData(
      epoch: serializer.fromJson<int>(json['epoch']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retiredAt: serializer.fromJson<DateTime?>(json['retiredAt']),
      wrapAlg: serializer.fromJson<String>(json['wrapAlg']),
      wrappedMkDevice: serializer.fromJson<Uint8List>(json['wrappedMkDevice']),
      wrappedMkRecovery: serializer.fromJson<Uint8List?>(
        json['wrappedMkRecovery'],
      ),
      kdfParamsJson: serializer.fromJson<String?>(json['kdfParamsJson']),
      keystoreAlias: serializer.fromJson<String>(json['keystoreAlias']),
      strongbox: serializer.fromJson<bool>(json['strongbox']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'epoch': serializer.toJson<int>(epoch),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retiredAt': serializer.toJson<DateTime?>(retiredAt),
      'wrapAlg': serializer.toJson<String>(wrapAlg),
      'wrappedMkDevice': serializer.toJson<Uint8List>(wrappedMkDevice),
      'wrappedMkRecovery': serializer.toJson<Uint8List?>(wrappedMkRecovery),
      'kdfParamsJson': serializer.toJson<String?>(kdfParamsJson),
      'keystoreAlias': serializer.toJson<String>(keystoreAlias),
      'strongbox': serializer.toJson<bool>(strongbox),
    };
  }

  KeyEpochData copyWith({
    int? epoch,
    DateTime? createdAt,
    Value<DateTime?> retiredAt = const Value.absent(),
    String? wrapAlg,
    Uint8List? wrappedMkDevice,
    Value<Uint8List?> wrappedMkRecovery = const Value.absent(),
    Value<String?> kdfParamsJson = const Value.absent(),
    String? keystoreAlias,
    bool? strongbox,
  }) => KeyEpochData(
    epoch: epoch ?? this.epoch,
    createdAt: createdAt ?? this.createdAt,
    retiredAt: retiredAt.present ? retiredAt.value : this.retiredAt,
    wrapAlg: wrapAlg ?? this.wrapAlg,
    wrappedMkDevice: wrappedMkDevice ?? this.wrappedMkDevice,
    wrappedMkRecovery: wrappedMkRecovery.present
        ? wrappedMkRecovery.value
        : this.wrappedMkRecovery,
    kdfParamsJson: kdfParamsJson.present
        ? kdfParamsJson.value
        : this.kdfParamsJson,
    keystoreAlias: keystoreAlias ?? this.keystoreAlias,
    strongbox: strongbox ?? this.strongbox,
  );
  KeyEpochData copyWithCompanion(KeyEpochsCompanion data) {
    return KeyEpochData(
      epoch: data.epoch.present ? data.epoch.value : this.epoch,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retiredAt: data.retiredAt.present ? data.retiredAt.value : this.retiredAt,
      wrapAlg: data.wrapAlg.present ? data.wrapAlg.value : this.wrapAlg,
      wrappedMkDevice: data.wrappedMkDevice.present
          ? data.wrappedMkDevice.value
          : this.wrappedMkDevice,
      wrappedMkRecovery: data.wrappedMkRecovery.present
          ? data.wrappedMkRecovery.value
          : this.wrappedMkRecovery,
      kdfParamsJson: data.kdfParamsJson.present
          ? data.kdfParamsJson.value
          : this.kdfParamsJson,
      keystoreAlias: data.keystoreAlias.present
          ? data.keystoreAlias.value
          : this.keystoreAlias,
      strongbox: data.strongbox.present ? data.strongbox.value : this.strongbox,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyEpochData(')
          ..write('epoch: $epoch, ')
          ..write('createdAt: $createdAt, ')
          ..write('retiredAt: $retiredAt, ')
          ..write('wrapAlg: $wrapAlg, ')
          ..write('wrappedMkDevice: $wrappedMkDevice, ')
          ..write('wrappedMkRecovery: $wrappedMkRecovery, ')
          ..write('kdfParamsJson: $kdfParamsJson, ')
          ..write('keystoreAlias: $keystoreAlias, ')
          ..write('strongbox: $strongbox')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    epoch,
    createdAt,
    retiredAt,
    wrapAlg,
    $driftBlobEquality.hash(wrappedMkDevice),
    $driftBlobEquality.hash(wrappedMkRecovery),
    kdfParamsJson,
    keystoreAlias,
    strongbox,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyEpochData &&
          other.epoch == this.epoch &&
          other.createdAt == this.createdAt &&
          other.retiredAt == this.retiredAt &&
          other.wrapAlg == this.wrapAlg &&
          $driftBlobEquality.equals(
            other.wrappedMkDevice,
            this.wrappedMkDevice,
          ) &&
          $driftBlobEquality.equals(
            other.wrappedMkRecovery,
            this.wrappedMkRecovery,
          ) &&
          other.kdfParamsJson == this.kdfParamsJson &&
          other.keystoreAlias == this.keystoreAlias &&
          other.strongbox == this.strongbox);
}

class KeyEpochsCompanion extends UpdateCompanion<KeyEpochData> {
  final Value<int> epoch;
  final Value<DateTime> createdAt;
  final Value<DateTime?> retiredAt;
  final Value<String> wrapAlg;
  final Value<Uint8List> wrappedMkDevice;
  final Value<Uint8List?> wrappedMkRecovery;
  final Value<String?> kdfParamsJson;
  final Value<String> keystoreAlias;
  final Value<bool> strongbox;
  const KeyEpochsCompanion({
    this.epoch = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retiredAt = const Value.absent(),
    this.wrapAlg = const Value.absent(),
    this.wrappedMkDevice = const Value.absent(),
    this.wrappedMkRecovery = const Value.absent(),
    this.kdfParamsJson = const Value.absent(),
    this.keystoreAlias = const Value.absent(),
    this.strongbox = const Value.absent(),
  });
  KeyEpochsCompanion.insert({
    this.epoch = const Value.absent(),
    required DateTime createdAt,
    this.retiredAt = const Value.absent(),
    required String wrapAlg,
    required Uint8List wrappedMkDevice,
    this.wrappedMkRecovery = const Value.absent(),
    this.kdfParamsJson = const Value.absent(),
    required String keystoreAlias,
    this.strongbox = const Value.absent(),
  }) : createdAt = Value(createdAt),
       wrapAlg = Value(wrapAlg),
       wrappedMkDevice = Value(wrappedMkDevice),
       keystoreAlias = Value(keystoreAlias);
  static Insertable<KeyEpochData> custom({
    Expression<int>? epoch,
    Expression<int>? createdAt,
    Expression<int>? retiredAt,
    Expression<String>? wrapAlg,
    Expression<Uint8List>? wrappedMkDevice,
    Expression<Uint8List>? wrappedMkRecovery,
    Expression<String>? kdfParamsJson,
    Expression<String>? keystoreAlias,
    Expression<bool>? strongbox,
  }) {
    return RawValuesInsertable({
      if (epoch != null) 'epoch': epoch,
      if (createdAt != null) 'created_at': createdAt,
      if (retiredAt != null) 'retired_at': retiredAt,
      if (wrapAlg != null) 'wrap_alg': wrapAlg,
      if (wrappedMkDevice != null) 'wrapped_mk_device': wrappedMkDevice,
      if (wrappedMkRecovery != null) 'wrapped_mk_recovery': wrappedMkRecovery,
      if (kdfParamsJson != null) 'kdf_params_json': kdfParamsJson,
      if (keystoreAlias != null) 'keystore_alias': keystoreAlias,
      if (strongbox != null) 'strongbox': strongbox,
    });
  }

  KeyEpochsCompanion copyWith({
    Value<int>? epoch,
    Value<DateTime>? createdAt,
    Value<DateTime?>? retiredAt,
    Value<String>? wrapAlg,
    Value<Uint8List>? wrappedMkDevice,
    Value<Uint8List?>? wrappedMkRecovery,
    Value<String?>? kdfParamsJson,
    Value<String>? keystoreAlias,
    Value<bool>? strongbox,
  }) {
    return KeyEpochsCompanion(
      epoch: epoch ?? this.epoch,
      createdAt: createdAt ?? this.createdAt,
      retiredAt: retiredAt ?? this.retiredAt,
      wrapAlg: wrapAlg ?? this.wrapAlg,
      wrappedMkDevice: wrappedMkDevice ?? this.wrappedMkDevice,
      wrappedMkRecovery: wrappedMkRecovery ?? this.wrappedMkRecovery,
      kdfParamsJson: kdfParamsJson ?? this.kdfParamsJson,
      keystoreAlias: keystoreAlias ?? this.keystoreAlias,
      strongbox: strongbox ?? this.strongbox,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (epoch.present) {
      map['epoch'] = Variable<int>(epoch.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $KeyEpochsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (retiredAt.present) {
      map['retired_at'] = Variable<int>(
        $KeyEpochsTable.$converterretiredAtn.toSql(retiredAt.value),
      );
    }
    if (wrapAlg.present) {
      map['wrap_alg'] = Variable<String>(wrapAlg.value);
    }
    if (wrappedMkDevice.present) {
      map['wrapped_mk_device'] = Variable<Uint8List>(wrappedMkDevice.value);
    }
    if (wrappedMkRecovery.present) {
      map['wrapped_mk_recovery'] = Variable<Uint8List>(wrappedMkRecovery.value);
    }
    if (kdfParamsJson.present) {
      map['kdf_params_json'] = Variable<String>(kdfParamsJson.value);
    }
    if (keystoreAlias.present) {
      map['keystore_alias'] = Variable<String>(keystoreAlias.value);
    }
    if (strongbox.present) {
      map['strongbox'] = Variable<bool>(strongbox.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyEpochsCompanion(')
          ..write('epoch: $epoch, ')
          ..write('createdAt: $createdAt, ')
          ..write('retiredAt: $retiredAt, ')
          ..write('wrapAlg: $wrapAlg, ')
          ..write('wrappedMkDevice: $wrappedMkDevice, ')
          ..write('wrappedMkRecovery: $wrappedMkRecovery, ')
          ..write('kdfParamsJson: $kdfParamsJson, ')
          ..write('keystoreAlias: $keystoreAlias, ')
          ..write('strongbox: $strongbox')
          ..write(')'))
        .toString();
  }
}

class $VaultEntriesTable extends VaultEntries
    with TableInfo<$VaultEntriesTable, VaultEntryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    check: () =>
        type.isIn(const ['PHOTO', 'ID', 'SIGNATURE', 'THUMBPRINT', 'DOCUMENT']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleEncMeta = const VerificationMeta(
    'titleEnc',
  );
  @override
  late final GeneratedColumn<Uint8List> titleEnc = GeneratedColumn<Uint8List>(
    'title_enc',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteEncMeta = const VerificationMeta(
    'noteEnc',
  );
  @override
  late final GeneratedColumn<Uint8List> noteEnc = GeneratedColumn<Uint8List>(
    'note_enc',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsEncMeta = const VerificationMeta(
    'tagsEnc',
  );
  @override
  late final GeneratedColumn<Uint8List> tagsEnc = GeneratedColumn<Uint8List>(
    'tags_enc',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($VaultEntriesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($VaultEntriesTable.$converterupdatedAt);
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originDeviceMeta = const VerificationMeta(
    'originDevice',
  );
  @override
  late final GeneratedColumn<String> originDevice = GeneratedColumn<String>(
    'origin_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($VaultEntriesTable.$converterdeletedAtn);
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LOCAL_ONLY'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    titleEnc,
    noteEnc,
    tagsEnc,
    createdAt,
    updatedAt,
    updatedHlc,
    originDevice,
    deletedAt,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultEntryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title_enc')) {
      context.handle(
        _titleEncMeta,
        titleEnc.isAcceptableOrUnknown(data['title_enc']!, _titleEncMeta),
      );
    }
    if (data.containsKey('note_enc')) {
      context.handle(
        _noteEncMeta,
        noteEnc.isAcceptableOrUnknown(data['note_enc']!, _noteEncMeta),
      );
    }
    if (data.containsKey('tags_enc')) {
      context.handle(
        _tagsEncMeta,
        tagsEnc.isAcceptableOrUnknown(data['tags_enc']!, _tagsEncMeta),
      );
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('origin_device')) {
      context.handle(
        _originDeviceMeta,
        originDevice.isAcceptableOrUnknown(
          data['origin_device']!,
          _originDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultEntryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultEntryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      titleEnc: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}title_enc'],
      ),
      noteEnc: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}note_enc'],
      ),
      tagsEnc: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}tags_enc'],
      ),
      createdAt: $VaultEntriesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $VaultEntriesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      originDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device'],
      )!,
      deletedAt: $VaultEntriesTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
    );
  }

  @override
  $VaultEntriesTable createAlias(String alias) {
    return $VaultEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class VaultEntryData extends DataClass implements Insertable<VaultEntryData> {
  final String id;
  final String type;
  final Uint8List? titleEnc;
  final Uint8List? noteEnc;
  final Uint8List? tagsEnc;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedHlc;
  final String originDevice;
  final DateTime? deletedAt;
  final String syncState;
  const VaultEntryData({
    required this.id,
    required this.type,
    this.titleEnc,
    this.noteEnc,
    this.tagsEnc,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedHlc,
    required this.originDevice,
    this.deletedAt,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || titleEnc != null) {
      map['title_enc'] = Variable<Uint8List>(titleEnc);
    }
    if (!nullToAbsent || noteEnc != null) {
      map['note_enc'] = Variable<Uint8List>(noteEnc);
    }
    if (!nullToAbsent || tagsEnc != null) {
      map['tags_enc'] = Variable<Uint8List>(tagsEnc);
    }
    {
      map['created_at'] = Variable<int>(
        $VaultEntriesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $VaultEntriesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['origin_device'] = Variable<String>(originDevice);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $VaultEntriesTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  VaultEntriesCompanion toCompanion(bool nullToAbsent) {
    return VaultEntriesCompanion(
      id: Value(id),
      type: Value(type),
      titleEnc: titleEnc == null && nullToAbsent
          ? const Value.absent()
          : Value(titleEnc),
      noteEnc: noteEnc == null && nullToAbsent
          ? const Value.absent()
          : Value(noteEnc),
      tagsEnc: tagsEnc == null && nullToAbsent
          ? const Value.absent()
          : Value(tagsEnc),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedHlc: Value(updatedHlc),
      originDevice: Value(originDevice),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncState: Value(syncState),
    );
  }

  factory VaultEntryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultEntryData(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      titleEnc: serializer.fromJson<Uint8List?>(json['titleEnc']),
      noteEnc: serializer.fromJson<Uint8List?>(json['noteEnc']),
      tagsEnc: serializer.fromJson<Uint8List?>(json['tagsEnc']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      originDevice: serializer.fromJson<String>(json['originDevice']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'titleEnc': serializer.toJson<Uint8List?>(titleEnc),
      'noteEnc': serializer.toJson<Uint8List?>(noteEnc),
      'tagsEnc': serializer.toJson<Uint8List?>(tagsEnc),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'originDevice': serializer.toJson<String>(originDevice),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  VaultEntryData copyWith({
    String? id,
    String? type,
    Value<Uint8List?> titleEnc = const Value.absent(),
    Value<Uint8List?> noteEnc = const Value.absent(),
    Value<Uint8List?> tagsEnc = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedHlc,
    String? originDevice,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncState,
  }) => VaultEntryData(
    id: id ?? this.id,
    type: type ?? this.type,
    titleEnc: titleEnc.present ? titleEnc.value : this.titleEnc,
    noteEnc: noteEnc.present ? noteEnc.value : this.noteEnc,
    tagsEnc: tagsEnc.present ? tagsEnc.value : this.tagsEnc,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    originDevice: originDevice ?? this.originDevice,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncState: syncState ?? this.syncState,
  );
  VaultEntryData copyWithCompanion(VaultEntriesCompanion data) {
    return VaultEntryData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      titleEnc: data.titleEnc.present ? data.titleEnc.value : this.titleEnc,
      noteEnc: data.noteEnc.present ? data.noteEnc.value : this.noteEnc,
      tagsEnc: data.tagsEnc.present ? data.tagsEnc.value : this.tagsEnc,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      originDevice: data.originDevice.present
          ? data.originDevice.value
          : this.originDevice,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultEntryData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('titleEnc: $titleEnc, ')
          ..write('noteEnc: $noteEnc, ')
          ..write('tagsEnc: $tagsEnc, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('originDevice: $originDevice, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    $driftBlobEquality.hash(titleEnc),
    $driftBlobEquality.hash(noteEnc),
    $driftBlobEquality.hash(tagsEnc),
    createdAt,
    updatedAt,
    updatedHlc,
    originDevice,
    deletedAt,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultEntryData &&
          other.id == this.id &&
          other.type == this.type &&
          $driftBlobEquality.equals(other.titleEnc, this.titleEnc) &&
          $driftBlobEquality.equals(other.noteEnc, this.noteEnc) &&
          $driftBlobEquality.equals(other.tagsEnc, this.tagsEnc) &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedHlc == this.updatedHlc &&
          other.originDevice == this.originDevice &&
          other.deletedAt == this.deletedAt &&
          other.syncState == this.syncState);
}

class VaultEntriesCompanion extends UpdateCompanion<VaultEntryData> {
  final Value<String> id;
  final Value<String> type;
  final Value<Uint8List?> titleEnc;
  final Value<Uint8List?> noteEnc;
  final Value<Uint8List?> tagsEnc;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedHlc;
  final Value<String> originDevice;
  final Value<DateTime?> deletedAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const VaultEntriesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.titleEnc = const Value.absent(),
    this.noteEnc = const Value.absent(),
    this.tagsEnc = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.originDevice = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultEntriesCompanion.insert({
    required String id,
    required String type,
    this.titleEnc = const Value.absent(),
    this.noteEnc = const Value.absent(),
    this.tagsEnc = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedHlc,
    required String originDevice,
    this.deletedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedHlc = Value(updatedHlc),
       originDevice = Value(originDevice);
  static Insertable<VaultEntryData> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<Uint8List>? titleEnc,
    Expression<Uint8List>? noteEnc,
    Expression<Uint8List>? tagsEnc,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? updatedHlc,
    Expression<String>? originDevice,
    Expression<int>? deletedAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (titleEnc != null) 'title_enc': titleEnc,
      if (noteEnc != null) 'note_enc': noteEnc,
      if (tagsEnc != null) 'tags_enc': tagsEnc,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (originDevice != null) 'origin_device': originDevice,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<Uint8List?>? titleEnc,
    Value<Uint8List?>? noteEnc,
    Value<Uint8List?>? tagsEnc,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedHlc,
    Value<String>? originDevice,
    Value<DateTime?>? deletedAt,
    Value<String>? syncState,
    Value<int>? rowid,
  }) {
    return VaultEntriesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      titleEnc: titleEnc ?? this.titleEnc,
      noteEnc: noteEnc ?? this.noteEnc,
      tagsEnc: tagsEnc ?? this.tagsEnc,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      originDevice: originDevice ?? this.originDevice,
      deletedAt: deletedAt ?? this.deletedAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (titleEnc.present) {
      map['title_enc'] = Variable<Uint8List>(titleEnc.value);
    }
    if (noteEnc.present) {
      map['note_enc'] = Variable<Uint8List>(noteEnc.value);
    }
    if (tagsEnc.present) {
      map['tags_enc'] = Variable<Uint8List>(tagsEnc.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $VaultEntriesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $VaultEntriesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (originDevice.present) {
      map['origin_device'] = Variable<String>(originDevice.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $VaultEntriesTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultEntriesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('titleEnc: $titleEnc, ')
          ..write('noteEnc: $noteEnc, ')
          ..write('tagsEnc: $tagsEnc, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('originDevice: $originDevice, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BlobsTable extends Blobs with TableInfo<$BlobsTable, BlobData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storageClassMeta = const VerificationMeta(
    'storageClass',
  );
  @override
  late final GeneratedColumn<String> storageClass = GeneratedColumn<String>(
    'storage_class',
    aliasedName,
    false,
    check: () =>
        storageClass.isIn(const ['ASSET', 'THUMBNAIL', 'EXPORT', 'SYNC_LOG']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relPathMeta = const VerificationMeta(
    'relPath',
  );
  @override
  late final GeneratedColumn<String> relPath = GeneratedColumn<String>(
    'rel_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _envelopeVersionMeta = const VerificationMeta(
    'envelopeVersion',
  );
  @override
  late final GeneratedColumn<int> envelopeVersion = GeneratedColumn<int>(
    'envelope_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _keyEpochMeta = const VerificationMeta(
    'keyEpoch',
  );
  @override
  late final GeneratedColumn<int> keyEpoch = GeneratedColumn<int>(
    'key_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES key_epochs (epoch) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _wrappedDekMeta = const VerificationMeta(
    'wrappedDek',
  );
  @override
  late final GeneratedColumn<Uint8List> wrappedDek = GeneratedColumn<Uint8List>(
    'wrapped_dek',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ciphertextSizeMeta = const VerificationMeta(
    'ciphertextSize',
  );
  @override
  late final GeneratedColumn<int> ciphertextSize = GeneratedColumn<int>(
    'ciphertext_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plaintextSizeMeta = const VerificationMeta(
    'plaintextSize',
  );
  @override
  late final GeneratedColumn<int> plaintextSize = GeneratedColumn<int>(
    'plaintext_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ciphertextSha256Meta = const VerificationMeta(
    'ciphertextSha256',
  );
  @override
  late final GeneratedColumn<Uint8List> ciphertextSha256 =
      GeneratedColumn<Uint8List>(
        'ciphertext_sha256',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _localStateMeta = const VerificationMeta(
    'localState',
  );
  @override
  late final GeneratedColumn<String> localState = GeneratedColumn<String>(
    'local_state',
    aliasedName,
    false,
    check: () =>
        localState.isIn(const ['PRESENT', 'EVICTED', 'REMOTE_ONLY', 'CORRUPT']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BlobsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastVerifiedAt =
      GeneratedColumn<int>(
        'last_verified_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($BlobsTable.$converterlastVerifiedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storageClass,
    relPath,
    envelopeVersion,
    keyEpoch,
    wrappedDek,
    ciphertextSize,
    plaintextSize,
    ciphertextSha256,
    localState,
    createdAt,
    lastVerifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlobData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('storage_class')) {
      context.handle(
        _storageClassMeta,
        storageClass.isAcceptableOrUnknown(
          data['storage_class']!,
          _storageClassMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storageClassMeta);
    }
    if (data.containsKey('rel_path')) {
      context.handle(
        _relPathMeta,
        relPath.isAcceptableOrUnknown(data['rel_path']!, _relPathMeta),
      );
    } else if (isInserting) {
      context.missing(_relPathMeta);
    }
    if (data.containsKey('envelope_version')) {
      context.handle(
        _envelopeVersionMeta,
        envelopeVersion.isAcceptableOrUnknown(
          data['envelope_version']!,
          _envelopeVersionMeta,
        ),
      );
    }
    if (data.containsKey('key_epoch')) {
      context.handle(
        _keyEpochMeta,
        keyEpoch.isAcceptableOrUnknown(data['key_epoch']!, _keyEpochMeta),
      );
    } else if (isInserting) {
      context.missing(_keyEpochMeta);
    }
    if (data.containsKey('wrapped_dek')) {
      context.handle(
        _wrappedDekMeta,
        wrappedDek.isAcceptableOrUnknown(data['wrapped_dek']!, _wrappedDekMeta),
      );
    } else if (isInserting) {
      context.missing(_wrappedDekMeta);
    }
    if (data.containsKey('ciphertext_size')) {
      context.handle(
        _ciphertextSizeMeta,
        ciphertextSize.isAcceptableOrUnknown(
          data['ciphertext_size']!,
          _ciphertextSizeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ciphertextSizeMeta);
    }
    if (data.containsKey('plaintext_size')) {
      context.handle(
        _plaintextSizeMeta,
        plaintextSize.isAcceptableOrUnknown(
          data['plaintext_size']!,
          _plaintextSizeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plaintextSizeMeta);
    }
    if (data.containsKey('ciphertext_sha256')) {
      context.handle(
        _ciphertextSha256Meta,
        ciphertextSha256.isAcceptableOrUnknown(
          data['ciphertext_sha256']!,
          _ciphertextSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ciphertextSha256Meta);
    }
    if (data.containsKey('local_state')) {
      context.handle(
        _localStateMeta,
        localState.isAcceptableOrUnknown(data['local_state']!, _localStateMeta),
      );
    } else if (isInserting) {
      context.missing(_localStateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {relPath},
  ];
  @override
  BlobData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlobData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storageClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_class'],
      )!,
      relPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rel_path'],
      )!,
      envelopeVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}envelope_version'],
      )!,
      keyEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}key_epoch'],
      )!,
      wrappedDek: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}wrapped_dek'],
      )!,
      ciphertextSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ciphertext_size'],
      )!,
      plaintextSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plaintext_size'],
      )!,
      ciphertextSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}ciphertext_sha256'],
      )!,
      localState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_state'],
      )!,
      createdAt: $BlobsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      lastVerifiedAt: $BlobsTable.$converterlastVerifiedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_verified_at'],
        ),
      ),
    );
  }

  @override
  $BlobsTable createAlias(String alias) {
    return $BlobsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterlastVerifiedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterlastVerifiedAtn =
      NullAwareTypeConverter.wrap($converterlastVerifiedAt);
}

class BlobData extends DataClass implements Insertable<BlobData> {
  final String id;
  final String storageClass;
  final String relPath;
  final int envelopeVersion;
  final int keyEpoch;
  final Uint8List wrappedDek;
  final int ciphertextSize;
  final int plaintextSize;
  final Uint8List ciphertextSha256;
  final String localState;
  final DateTime createdAt;
  final DateTime? lastVerifiedAt;
  const BlobData({
    required this.id,
    required this.storageClass,
    required this.relPath,
    required this.envelopeVersion,
    required this.keyEpoch,
    required this.wrappedDek,
    required this.ciphertextSize,
    required this.plaintextSize,
    required this.ciphertextSha256,
    required this.localState,
    required this.createdAt,
    this.lastVerifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['storage_class'] = Variable<String>(storageClass);
    map['rel_path'] = Variable<String>(relPath);
    map['envelope_version'] = Variable<int>(envelopeVersion);
    map['key_epoch'] = Variable<int>(keyEpoch);
    map['wrapped_dek'] = Variable<Uint8List>(wrappedDek);
    map['ciphertext_size'] = Variable<int>(ciphertextSize);
    map['plaintext_size'] = Variable<int>(plaintextSize);
    map['ciphertext_sha256'] = Variable<Uint8List>(ciphertextSha256);
    map['local_state'] = Variable<String>(localState);
    {
      map['created_at'] = Variable<int>(
        $BlobsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || lastVerifiedAt != null) {
      map['last_verified_at'] = Variable<int>(
        $BlobsTable.$converterlastVerifiedAtn.toSql(lastVerifiedAt),
      );
    }
    return map;
  }

  BlobsCompanion toCompanion(bool nullToAbsent) {
    return BlobsCompanion(
      id: Value(id),
      storageClass: Value(storageClass),
      relPath: Value(relPath),
      envelopeVersion: Value(envelopeVersion),
      keyEpoch: Value(keyEpoch),
      wrappedDek: Value(wrappedDek),
      ciphertextSize: Value(ciphertextSize),
      plaintextSize: Value(plaintextSize),
      ciphertextSha256: Value(ciphertextSha256),
      localState: Value(localState),
      createdAt: Value(createdAt),
      lastVerifiedAt: lastVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerifiedAt),
    );
  }

  factory BlobData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlobData(
      id: serializer.fromJson<String>(json['id']),
      storageClass: serializer.fromJson<String>(json['storageClass']),
      relPath: serializer.fromJson<String>(json['relPath']),
      envelopeVersion: serializer.fromJson<int>(json['envelopeVersion']),
      keyEpoch: serializer.fromJson<int>(json['keyEpoch']),
      wrappedDek: serializer.fromJson<Uint8List>(json['wrappedDek']),
      ciphertextSize: serializer.fromJson<int>(json['ciphertextSize']),
      plaintextSize: serializer.fromJson<int>(json['plaintextSize']),
      ciphertextSha256: serializer.fromJson<Uint8List>(
        json['ciphertextSha256'],
      ),
      localState: serializer.fromJson<String>(json['localState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastVerifiedAt: serializer.fromJson<DateTime?>(json['lastVerifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storageClass': serializer.toJson<String>(storageClass),
      'relPath': serializer.toJson<String>(relPath),
      'envelopeVersion': serializer.toJson<int>(envelopeVersion),
      'keyEpoch': serializer.toJson<int>(keyEpoch),
      'wrappedDek': serializer.toJson<Uint8List>(wrappedDek),
      'ciphertextSize': serializer.toJson<int>(ciphertextSize),
      'plaintextSize': serializer.toJson<int>(plaintextSize),
      'ciphertextSha256': serializer.toJson<Uint8List>(ciphertextSha256),
      'localState': serializer.toJson<String>(localState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastVerifiedAt': serializer.toJson<DateTime?>(lastVerifiedAt),
    };
  }

  BlobData copyWith({
    String? id,
    String? storageClass,
    String? relPath,
    int? envelopeVersion,
    int? keyEpoch,
    Uint8List? wrappedDek,
    int? ciphertextSize,
    int? plaintextSize,
    Uint8List? ciphertextSha256,
    String? localState,
    DateTime? createdAt,
    Value<DateTime?> lastVerifiedAt = const Value.absent(),
  }) => BlobData(
    id: id ?? this.id,
    storageClass: storageClass ?? this.storageClass,
    relPath: relPath ?? this.relPath,
    envelopeVersion: envelopeVersion ?? this.envelopeVersion,
    keyEpoch: keyEpoch ?? this.keyEpoch,
    wrappedDek: wrappedDek ?? this.wrappedDek,
    ciphertextSize: ciphertextSize ?? this.ciphertextSize,
    plaintextSize: plaintextSize ?? this.plaintextSize,
    ciphertextSha256: ciphertextSha256 ?? this.ciphertextSha256,
    localState: localState ?? this.localState,
    createdAt: createdAt ?? this.createdAt,
    lastVerifiedAt: lastVerifiedAt.present
        ? lastVerifiedAt.value
        : this.lastVerifiedAt,
  );
  BlobData copyWithCompanion(BlobsCompanion data) {
    return BlobData(
      id: data.id.present ? data.id.value : this.id,
      storageClass: data.storageClass.present
          ? data.storageClass.value
          : this.storageClass,
      relPath: data.relPath.present ? data.relPath.value : this.relPath,
      envelopeVersion: data.envelopeVersion.present
          ? data.envelopeVersion.value
          : this.envelopeVersion,
      keyEpoch: data.keyEpoch.present ? data.keyEpoch.value : this.keyEpoch,
      wrappedDek: data.wrappedDek.present
          ? data.wrappedDek.value
          : this.wrappedDek,
      ciphertextSize: data.ciphertextSize.present
          ? data.ciphertextSize.value
          : this.ciphertextSize,
      plaintextSize: data.plaintextSize.present
          ? data.plaintextSize.value
          : this.plaintextSize,
      ciphertextSha256: data.ciphertextSha256.present
          ? data.ciphertextSha256.value
          : this.ciphertextSha256,
      localState: data.localState.present
          ? data.localState.value
          : this.localState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastVerifiedAt: data.lastVerifiedAt.present
          ? data.lastVerifiedAt.value
          : this.lastVerifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlobData(')
          ..write('id: $id, ')
          ..write('storageClass: $storageClass, ')
          ..write('relPath: $relPath, ')
          ..write('envelopeVersion: $envelopeVersion, ')
          ..write('keyEpoch: $keyEpoch, ')
          ..write('wrappedDek: $wrappedDek, ')
          ..write('ciphertextSize: $ciphertextSize, ')
          ..write('plaintextSize: $plaintextSize, ')
          ..write('ciphertextSha256: $ciphertextSha256, ')
          ..write('localState: $localState, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastVerifiedAt: $lastVerifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storageClass,
    relPath,
    envelopeVersion,
    keyEpoch,
    $driftBlobEquality.hash(wrappedDek),
    ciphertextSize,
    plaintextSize,
    $driftBlobEquality.hash(ciphertextSha256),
    localState,
    createdAt,
    lastVerifiedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlobData &&
          other.id == this.id &&
          other.storageClass == this.storageClass &&
          other.relPath == this.relPath &&
          other.envelopeVersion == this.envelopeVersion &&
          other.keyEpoch == this.keyEpoch &&
          $driftBlobEquality.equals(other.wrappedDek, this.wrappedDek) &&
          other.ciphertextSize == this.ciphertextSize &&
          other.plaintextSize == this.plaintextSize &&
          $driftBlobEquality.equals(
            other.ciphertextSha256,
            this.ciphertextSha256,
          ) &&
          other.localState == this.localState &&
          other.createdAt == this.createdAt &&
          other.lastVerifiedAt == this.lastVerifiedAt);
}

class BlobsCompanion extends UpdateCompanion<BlobData> {
  final Value<String> id;
  final Value<String> storageClass;
  final Value<String> relPath;
  final Value<int> envelopeVersion;
  final Value<int> keyEpoch;
  final Value<Uint8List> wrappedDek;
  final Value<int> ciphertextSize;
  final Value<int> plaintextSize;
  final Value<Uint8List> ciphertextSha256;
  final Value<String> localState;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastVerifiedAt;
  final Value<int> rowid;
  const BlobsCompanion({
    this.id = const Value.absent(),
    this.storageClass = const Value.absent(),
    this.relPath = const Value.absent(),
    this.envelopeVersion = const Value.absent(),
    this.keyEpoch = const Value.absent(),
    this.wrappedDek = const Value.absent(),
    this.ciphertextSize = const Value.absent(),
    this.plaintextSize = const Value.absent(),
    this.ciphertextSha256 = const Value.absent(),
    this.localState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlobsCompanion.insert({
    required String id,
    required String storageClass,
    required String relPath,
    this.envelopeVersion = const Value.absent(),
    required int keyEpoch,
    required Uint8List wrappedDek,
    required int ciphertextSize,
    required int plaintextSize,
    required Uint8List ciphertextSha256,
    required String localState,
    required DateTime createdAt,
    this.lastVerifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storageClass = Value(storageClass),
       relPath = Value(relPath),
       keyEpoch = Value(keyEpoch),
       wrappedDek = Value(wrappedDek),
       ciphertextSize = Value(ciphertextSize),
       plaintextSize = Value(plaintextSize),
       ciphertextSha256 = Value(ciphertextSha256),
       localState = Value(localState),
       createdAt = Value(createdAt);
  static Insertable<BlobData> custom({
    Expression<String>? id,
    Expression<String>? storageClass,
    Expression<String>? relPath,
    Expression<int>? envelopeVersion,
    Expression<int>? keyEpoch,
    Expression<Uint8List>? wrappedDek,
    Expression<int>? ciphertextSize,
    Expression<int>? plaintextSize,
    Expression<Uint8List>? ciphertextSha256,
    Expression<String>? localState,
    Expression<int>? createdAt,
    Expression<int>? lastVerifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storageClass != null) 'storage_class': storageClass,
      if (relPath != null) 'rel_path': relPath,
      if (envelopeVersion != null) 'envelope_version': envelopeVersion,
      if (keyEpoch != null) 'key_epoch': keyEpoch,
      if (wrappedDek != null) 'wrapped_dek': wrappedDek,
      if (ciphertextSize != null) 'ciphertext_size': ciphertextSize,
      if (plaintextSize != null) 'plaintext_size': plaintextSize,
      if (ciphertextSha256 != null) 'ciphertext_sha256': ciphertextSha256,
      if (localState != null) 'local_state': localState,
      if (createdAt != null) 'created_at': createdAt,
      if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BlobsCompanion copyWith({
    Value<String>? id,
    Value<String>? storageClass,
    Value<String>? relPath,
    Value<int>? envelopeVersion,
    Value<int>? keyEpoch,
    Value<Uint8List>? wrappedDek,
    Value<int>? ciphertextSize,
    Value<int>? plaintextSize,
    Value<Uint8List>? ciphertextSha256,
    Value<String>? localState,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastVerifiedAt,
    Value<int>? rowid,
  }) {
    return BlobsCompanion(
      id: id ?? this.id,
      storageClass: storageClass ?? this.storageClass,
      relPath: relPath ?? this.relPath,
      envelopeVersion: envelopeVersion ?? this.envelopeVersion,
      keyEpoch: keyEpoch ?? this.keyEpoch,
      wrappedDek: wrappedDek ?? this.wrappedDek,
      ciphertextSize: ciphertextSize ?? this.ciphertextSize,
      plaintextSize: plaintextSize ?? this.plaintextSize,
      ciphertextSha256: ciphertextSha256 ?? this.ciphertextSha256,
      localState: localState ?? this.localState,
      createdAt: createdAt ?? this.createdAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storageClass.present) {
      map['storage_class'] = Variable<String>(storageClass.value);
    }
    if (relPath.present) {
      map['rel_path'] = Variable<String>(relPath.value);
    }
    if (envelopeVersion.present) {
      map['envelope_version'] = Variable<int>(envelopeVersion.value);
    }
    if (keyEpoch.present) {
      map['key_epoch'] = Variable<int>(keyEpoch.value);
    }
    if (wrappedDek.present) {
      map['wrapped_dek'] = Variable<Uint8List>(wrappedDek.value);
    }
    if (ciphertextSize.present) {
      map['ciphertext_size'] = Variable<int>(ciphertextSize.value);
    }
    if (plaintextSize.present) {
      map['plaintext_size'] = Variable<int>(plaintextSize.value);
    }
    if (ciphertextSha256.present) {
      map['ciphertext_sha256'] = Variable<Uint8List>(ciphertextSha256.value);
    }
    if (localState.present) {
      map['local_state'] = Variable<String>(localState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $BlobsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (lastVerifiedAt.present) {
      map['last_verified_at'] = Variable<int>(
        $BlobsTable.$converterlastVerifiedAtn.toSql(lastVerifiedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlobsCompanion(')
          ..write('id: $id, ')
          ..write('storageClass: $storageClass, ')
          ..write('relPath: $relPath, ')
          ..write('envelopeVersion: $envelopeVersion, ')
          ..write('keyEpoch: $keyEpoch, ')
          ..write('wrappedDek: $wrappedDek, ')
          ..write('ciphertextSize: $ciphertextSize, ')
          ..write('plaintextSize: $plaintextSize, ')
          ..write('ciphertextSha256: $ciphertextSha256, ')
          ..write('localState: $localState, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetsTable extends Assets with TableInfo<$AssetsTable, AssetData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vault_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    check: () => role.isIn(const ['PRIMARY', 'ID_FRONT', 'ID_BACK', 'PAGE']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    check: () => ComparableExpr(ordinal).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentVersionIdMeta = const VerificationMeta(
    'currentVersionId',
  );
  @override
  late final GeneratedColumn<String> currentVersionId = GeneratedColumn<String>(
    'current_version_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AssetsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AssetsTable.$converterupdatedAt);
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originDeviceMeta = const VerificationMeta(
    'originDevice',
  );
  @override
  late final GeneratedColumn<String> originDevice = GeneratedColumn<String>(
    'origin_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($AssetsTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    role,
    ordinal,
    currentVersionId,
    createdAt,
    updatedAt,
    updatedHlc,
    originDevice,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    }
    if (data.containsKey('current_version_id')) {
      context.handle(
        _currentVersionIdMeta,
        currentVersionId.isAcceptableOrUnknown(
          data['current_version_id']!,
          _currentVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('origin_device')) {
      context.handle(
        _originDeviceMeta,
        originDevice.isAcceptableOrUnknown(
          data['origin_device']!,
          _originDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      currentVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_version_id'],
      ),
      createdAt: $AssetsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $AssetsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      originDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device'],
      )!,
      deletedAt: $AssetsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class AssetData extends DataClass implements Insertable<AssetData> {
  final String id;
  final String entryId;
  final String role;
  final int ordinal;
  final String? currentVersionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedHlc;
  final String originDevice;
  final DateTime? deletedAt;
  const AssetData({
    required this.id,
    required this.entryId,
    required this.role,
    required this.ordinal,
    this.currentVersionId,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedHlc,
    required this.originDevice,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['role'] = Variable<String>(role);
    map['ordinal'] = Variable<int>(ordinal);
    if (!nullToAbsent || currentVersionId != null) {
      map['current_version_id'] = Variable<String>(currentVersionId);
    }
    {
      map['created_at'] = Variable<int>(
        $AssetsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $AssetsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['origin_device'] = Variable<String>(originDevice);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $AssetsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      role: Value(role),
      ordinal: Value(ordinal),
      currentVersionId: currentVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentVersionId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedHlc: Value(updatedHlc),
      originDevice: Value(originDevice),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory AssetData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetData(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      role: serializer.fromJson<String>(json['role']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      currentVersionId: serializer.fromJson<String?>(json['currentVersionId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      originDevice: serializer.fromJson<String>(json['originDevice']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'role': serializer.toJson<String>(role),
      'ordinal': serializer.toJson<int>(ordinal),
      'currentVersionId': serializer.toJson<String?>(currentVersionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'originDevice': serializer.toJson<String>(originDevice),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  AssetData copyWith({
    String? id,
    String? entryId,
    String? role,
    int? ordinal,
    Value<String?> currentVersionId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedHlc,
    String? originDevice,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => AssetData(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    role: role ?? this.role,
    ordinal: ordinal ?? this.ordinal,
    currentVersionId: currentVersionId.present
        ? currentVersionId.value
        : this.currentVersionId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    originDevice: originDevice ?? this.originDevice,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  AssetData copyWithCompanion(AssetsCompanion data) {
    return AssetData(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      role: data.role.present ? data.role.value : this.role,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      currentVersionId: data.currentVersionId.present
          ? data.currentVersionId.value
          : this.currentVersionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      originDevice: data.originDevice.present
          ? data.originDevice.value
          : this.originDevice,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetData(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('role: $role, ')
          ..write('ordinal: $ordinal, ')
          ..write('currentVersionId: $currentVersionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('originDevice: $originDevice, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entryId,
    role,
    ordinal,
    currentVersionId,
    createdAt,
    updatedAt,
    updatedHlc,
    originDevice,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetData &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.role == this.role &&
          other.ordinal == this.ordinal &&
          other.currentVersionId == this.currentVersionId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedHlc == this.updatedHlc &&
          other.originDevice == this.originDevice &&
          other.deletedAt == this.deletedAt);
}

class AssetsCompanion extends UpdateCompanion<AssetData> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<String> role;
  final Value<int> ordinal;
  final Value<String?> currentVersionId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedHlc;
  final Value<String> originDevice;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.role = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.currentVersionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.originDevice = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String id,
    required String entryId,
    required String role,
    this.ordinal = const Value.absent(),
    this.currentVersionId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedHlc,
    required String originDevice,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       role = Value(role),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedHlc = Value(updatedHlc),
       originDevice = Value(originDevice);
  static Insertable<AssetData> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? role,
    Expression<int>? ordinal,
    Expression<String>? currentVersionId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? updatedHlc,
    Expression<String>? originDevice,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (role != null) 'role': role,
      if (ordinal != null) 'ordinal': ordinal,
      if (currentVersionId != null) 'current_version_id': currentVersionId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (originDevice != null) 'origin_device': originDevice,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? entryId,
    Value<String>? role,
    Value<int>? ordinal,
    Value<String?>? currentVersionId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedHlc,
    Value<String>? originDevice,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return AssetsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      role: role ?? this.role,
      ordinal: ordinal ?? this.ordinal,
      currentVersionId: currentVersionId ?? this.currentVersionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      originDevice: originDevice ?? this.originDevice,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (currentVersionId.present) {
      map['current_version_id'] = Variable<String>(currentVersionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $AssetsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $AssetsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (originDevice.present) {
      map['origin_device'] = Variable<String>(originDevice.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $AssetsTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('role: $role, ')
          ..write('ordinal: $ordinal, ')
          ..write('currentVersionId: $currentVersionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('originDevice: $originDevice, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetVersionsTable extends AssetVersions
    with TableInfo<$AssetVersionsTable, AssetVersionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES assets (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _parentVersionIdMeta = const VerificationMeta(
    'parentVersionId',
  );
  @override
  late final GeneratedColumn<String> parentVersionId = GeneratedColumn<String>(
    'parent_version_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset_versions (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(const ['ORIGINAL', 'DERIVED']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blobIdMeta = const VerificationMeta('blobId');
  @override
  late final GeneratedColumn<String> blobId = GeneratedColumn<String>(
    'blob_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES blobs (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _recipeJsonMeta = const VerificationMeta(
    'recipeJson',
  );
  @override
  late final GeneratedColumn<String> recipeJson = GeneratedColumn<String>(
    'recipe_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recipeSchemaVersionMeta =
      const VerificationMeta('recipeSchemaVersion');
  @override
  late final GeneratedColumn<int> recipeSchemaVersion = GeneratedColumn<int>(
    'recipe_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _recipeDeterministicMeta =
      const VerificationMeta('recipeDeterministic');
  @override
  late final GeneratedColumn<bool> recipeDeterministic = GeneratedColumn<bool>(
    'recipe_deterministic',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("recipe_deterministic" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plaintextSha256Meta = const VerificationMeta(
    'plaintextSha256',
  );
  @override
  late final GeneratedColumn<Uint8List> plaintextSha256 =
      GeneratedColumn<Uint8List>(
        'plaintext_sha256',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _plaintextSizeMeta = const VerificationMeta(
    'plaintextSize',
  );
  @override
  late final GeneratedColumn<int> plaintextSize = GeneratedColumn<int>(
    'plaintext_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AssetVersionsTable.$convertercreatedAt);
  static const VerificationMeta _createdHlcMeta = const VerificationMeta(
    'createdHlc',
  );
  @override
  late final GeneratedColumn<String> createdHlc = GeneratedColumn<String>(
    'created_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originDeviceMeta = const VerificationMeta(
    'originDevice',
  );
  @override
  late final GeneratedColumn<String> originDevice = GeneratedColumn<String>(
    'origin_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> evictedAt =
      GeneratedColumn<int>(
        'evicted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($AssetVersionsTable.$converterevictedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    parentVersionId,
    kind,
    seq,
    blobId,
    recipeJson,
    recipeSchemaVersion,
    recipeDeterministic,
    width,
    height,
    mime,
    plaintextSha256,
    plaintextSize,
    createdAt,
    createdHlc,
    originDevice,
    evictedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetVersionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('parent_version_id')) {
      context.handle(
        _parentVersionIdMeta,
        parentVersionId.isAcceptableOrUnknown(
          data['parent_version_id']!,
          _parentVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('blob_id')) {
      context.handle(
        _blobIdMeta,
        blobId.isAcceptableOrUnknown(data['blob_id']!, _blobIdMeta),
      );
    }
    if (data.containsKey('recipe_json')) {
      context.handle(
        _recipeJsonMeta,
        recipeJson.isAcceptableOrUnknown(data['recipe_json']!, _recipeJsonMeta),
      );
    }
    if (data.containsKey('recipe_schema_version')) {
      context.handle(
        _recipeSchemaVersionMeta,
        recipeSchemaVersion.isAcceptableOrUnknown(
          data['recipe_schema_version']!,
          _recipeSchemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('recipe_deterministic')) {
      context.handle(
        _recipeDeterministicMeta,
        recipeDeterministic.isAcceptableOrUnknown(
          data['recipe_deterministic']!,
          _recipeDeterministicMeta,
        ),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeMeta);
    }
    if (data.containsKey('plaintext_sha256')) {
      context.handle(
        _plaintextSha256Meta,
        plaintextSha256.isAcceptableOrUnknown(
          data['plaintext_sha256']!,
          _plaintextSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plaintextSha256Meta);
    }
    if (data.containsKey('plaintext_size')) {
      context.handle(
        _plaintextSizeMeta,
        plaintextSize.isAcceptableOrUnknown(
          data['plaintext_size']!,
          _plaintextSizeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plaintextSizeMeta);
    }
    if (data.containsKey('created_hlc')) {
      context.handle(
        _createdHlcMeta,
        createdHlc.isAcceptableOrUnknown(data['created_hlc']!, _createdHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_createdHlcMeta);
    }
    if (data.containsKey('origin_device')) {
      context.handle(
        _originDeviceMeta,
        originDevice.isAcceptableOrUnknown(
          data['origin_device']!,
          _originDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetVersionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetVersionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      parentVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_version_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      blobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blob_id'],
      ),
      recipeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_json'],
      ),
      recipeSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipe_schema_version'],
      )!,
      recipeDeterministic: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}recipe_deterministic'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      )!,
      plaintextSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}plaintext_sha256'],
      )!,
      plaintextSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plaintext_size'],
      )!,
      createdAt: $AssetVersionsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      createdHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_hlc'],
      )!,
      originDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device'],
      )!,
      evictedAt: $AssetVersionsTable.$converterevictedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}evicted_at'],
        ),
      ),
    );
  }

  @override
  $AssetVersionsTable createAlias(String alias) {
    return $AssetVersionsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterevictedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterevictedAtn =
      NullAwareTypeConverter.wrap($converterevictedAt);
}

class AssetVersionData extends DataClass
    implements Insertable<AssetVersionData> {
  final String id;
  final String assetId;
  final String? parentVersionId;
  final String kind;
  final int seq;
  final String? blobId;
  final String? recipeJson;
  final int recipeSchemaVersion;
  final bool recipeDeterministic;
  final int width;
  final int height;
  final String mime;
  final Uint8List plaintextSha256;
  final int plaintextSize;
  final DateTime createdAt;
  final String createdHlc;
  final String originDevice;
  final DateTime? evictedAt;
  const AssetVersionData({
    required this.id,
    required this.assetId,
    this.parentVersionId,
    required this.kind,
    required this.seq,
    this.blobId,
    this.recipeJson,
    required this.recipeSchemaVersion,
    required this.recipeDeterministic,
    required this.width,
    required this.height,
    required this.mime,
    required this.plaintextSha256,
    required this.plaintextSize,
    required this.createdAt,
    required this.createdHlc,
    required this.originDevice,
    this.evictedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['asset_id'] = Variable<String>(assetId);
    if (!nullToAbsent || parentVersionId != null) {
      map['parent_version_id'] = Variable<String>(parentVersionId);
    }
    map['kind'] = Variable<String>(kind);
    map['seq'] = Variable<int>(seq);
    if (!nullToAbsent || blobId != null) {
      map['blob_id'] = Variable<String>(blobId);
    }
    if (!nullToAbsent || recipeJson != null) {
      map['recipe_json'] = Variable<String>(recipeJson);
    }
    map['recipe_schema_version'] = Variable<int>(recipeSchemaVersion);
    map['recipe_deterministic'] = Variable<bool>(recipeDeterministic);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['mime'] = Variable<String>(mime);
    map['plaintext_sha256'] = Variable<Uint8List>(plaintextSha256);
    map['plaintext_size'] = Variable<int>(plaintextSize);
    {
      map['created_at'] = Variable<int>(
        $AssetVersionsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    map['created_hlc'] = Variable<String>(createdHlc);
    map['origin_device'] = Variable<String>(originDevice);
    if (!nullToAbsent || evictedAt != null) {
      map['evicted_at'] = Variable<int>(
        $AssetVersionsTable.$converterevictedAtn.toSql(evictedAt),
      );
    }
    return map;
  }

  AssetVersionsCompanion toCompanion(bool nullToAbsent) {
    return AssetVersionsCompanion(
      id: Value(id),
      assetId: Value(assetId),
      parentVersionId: parentVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentVersionId),
      kind: Value(kind),
      seq: Value(seq),
      blobId: blobId == null && nullToAbsent
          ? const Value.absent()
          : Value(blobId),
      recipeJson: recipeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(recipeJson),
      recipeSchemaVersion: Value(recipeSchemaVersion),
      recipeDeterministic: Value(recipeDeterministic),
      width: Value(width),
      height: Value(height),
      mime: Value(mime),
      plaintextSha256: Value(plaintextSha256),
      plaintextSize: Value(plaintextSize),
      createdAt: Value(createdAt),
      createdHlc: Value(createdHlc),
      originDevice: Value(originDevice),
      evictedAt: evictedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(evictedAt),
    );
  }

  factory AssetVersionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetVersionData(
      id: serializer.fromJson<String>(json['id']),
      assetId: serializer.fromJson<String>(json['assetId']),
      parentVersionId: serializer.fromJson<String?>(json['parentVersionId']),
      kind: serializer.fromJson<String>(json['kind']),
      seq: serializer.fromJson<int>(json['seq']),
      blobId: serializer.fromJson<String?>(json['blobId']),
      recipeJson: serializer.fromJson<String?>(json['recipeJson']),
      recipeSchemaVersion: serializer.fromJson<int>(
        json['recipeSchemaVersion'],
      ),
      recipeDeterministic: serializer.fromJson<bool>(
        json['recipeDeterministic'],
      ),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      mime: serializer.fromJson<String>(json['mime']),
      plaintextSha256: serializer.fromJson<Uint8List>(json['plaintextSha256']),
      plaintextSize: serializer.fromJson<int>(json['plaintextSize']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      createdHlc: serializer.fromJson<String>(json['createdHlc']),
      originDevice: serializer.fromJson<String>(json['originDevice']),
      evictedAt: serializer.fromJson<DateTime?>(json['evictedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'assetId': serializer.toJson<String>(assetId),
      'parentVersionId': serializer.toJson<String?>(parentVersionId),
      'kind': serializer.toJson<String>(kind),
      'seq': serializer.toJson<int>(seq),
      'blobId': serializer.toJson<String?>(blobId),
      'recipeJson': serializer.toJson<String?>(recipeJson),
      'recipeSchemaVersion': serializer.toJson<int>(recipeSchemaVersion),
      'recipeDeterministic': serializer.toJson<bool>(recipeDeterministic),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'mime': serializer.toJson<String>(mime),
      'plaintextSha256': serializer.toJson<Uint8List>(plaintextSha256),
      'plaintextSize': serializer.toJson<int>(plaintextSize),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'createdHlc': serializer.toJson<String>(createdHlc),
      'originDevice': serializer.toJson<String>(originDevice),
      'evictedAt': serializer.toJson<DateTime?>(evictedAt),
    };
  }

  AssetVersionData copyWith({
    String? id,
    String? assetId,
    Value<String?> parentVersionId = const Value.absent(),
    String? kind,
    int? seq,
    Value<String?> blobId = const Value.absent(),
    Value<String?> recipeJson = const Value.absent(),
    int? recipeSchemaVersion,
    bool? recipeDeterministic,
    int? width,
    int? height,
    String? mime,
    Uint8List? plaintextSha256,
    int? plaintextSize,
    DateTime? createdAt,
    String? createdHlc,
    String? originDevice,
    Value<DateTime?> evictedAt = const Value.absent(),
  }) => AssetVersionData(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    parentVersionId: parentVersionId.present
        ? parentVersionId.value
        : this.parentVersionId,
    kind: kind ?? this.kind,
    seq: seq ?? this.seq,
    blobId: blobId.present ? blobId.value : this.blobId,
    recipeJson: recipeJson.present ? recipeJson.value : this.recipeJson,
    recipeSchemaVersion: recipeSchemaVersion ?? this.recipeSchemaVersion,
    recipeDeterministic: recipeDeterministic ?? this.recipeDeterministic,
    width: width ?? this.width,
    height: height ?? this.height,
    mime: mime ?? this.mime,
    plaintextSha256: plaintextSha256 ?? this.plaintextSha256,
    plaintextSize: plaintextSize ?? this.plaintextSize,
    createdAt: createdAt ?? this.createdAt,
    createdHlc: createdHlc ?? this.createdHlc,
    originDevice: originDevice ?? this.originDevice,
    evictedAt: evictedAt.present ? evictedAt.value : this.evictedAt,
  );
  AssetVersionData copyWithCompanion(AssetVersionsCompanion data) {
    return AssetVersionData(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      parentVersionId: data.parentVersionId.present
          ? data.parentVersionId.value
          : this.parentVersionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      seq: data.seq.present ? data.seq.value : this.seq,
      blobId: data.blobId.present ? data.blobId.value : this.blobId,
      recipeJson: data.recipeJson.present
          ? data.recipeJson.value
          : this.recipeJson,
      recipeSchemaVersion: data.recipeSchemaVersion.present
          ? data.recipeSchemaVersion.value
          : this.recipeSchemaVersion,
      recipeDeterministic: data.recipeDeterministic.present
          ? data.recipeDeterministic.value
          : this.recipeDeterministic,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      mime: data.mime.present ? data.mime.value : this.mime,
      plaintextSha256: data.plaintextSha256.present
          ? data.plaintextSha256.value
          : this.plaintextSha256,
      plaintextSize: data.plaintextSize.present
          ? data.plaintextSize.value
          : this.plaintextSize,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdHlc: data.createdHlc.present
          ? data.createdHlc.value
          : this.createdHlc,
      originDevice: data.originDevice.present
          ? data.originDevice.value
          : this.originDevice,
      evictedAt: data.evictedAt.present ? data.evictedAt.value : this.evictedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetVersionData(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('parentVersionId: $parentVersionId, ')
          ..write('kind: $kind, ')
          ..write('seq: $seq, ')
          ..write('blobId: $blobId, ')
          ..write('recipeJson: $recipeJson, ')
          ..write('recipeSchemaVersion: $recipeSchemaVersion, ')
          ..write('recipeDeterministic: $recipeDeterministic, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('mime: $mime, ')
          ..write('plaintextSha256: $plaintextSha256, ')
          ..write('plaintextSize: $plaintextSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdHlc: $createdHlc, ')
          ..write('originDevice: $originDevice, ')
          ..write('evictedAt: $evictedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assetId,
    parentVersionId,
    kind,
    seq,
    blobId,
    recipeJson,
    recipeSchemaVersion,
    recipeDeterministic,
    width,
    height,
    mime,
    $driftBlobEquality.hash(plaintextSha256),
    plaintextSize,
    createdAt,
    createdHlc,
    originDevice,
    evictedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetVersionData &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.parentVersionId == this.parentVersionId &&
          other.kind == this.kind &&
          other.seq == this.seq &&
          other.blobId == this.blobId &&
          other.recipeJson == this.recipeJson &&
          other.recipeSchemaVersion == this.recipeSchemaVersion &&
          other.recipeDeterministic == this.recipeDeterministic &&
          other.width == this.width &&
          other.height == this.height &&
          other.mime == this.mime &&
          $driftBlobEquality.equals(
            other.plaintextSha256,
            this.plaintextSha256,
          ) &&
          other.plaintextSize == this.plaintextSize &&
          other.createdAt == this.createdAt &&
          other.createdHlc == this.createdHlc &&
          other.originDevice == this.originDevice &&
          other.evictedAt == this.evictedAt);
}

class AssetVersionsCompanion extends UpdateCompanion<AssetVersionData> {
  final Value<String> id;
  final Value<String> assetId;
  final Value<String?> parentVersionId;
  final Value<String> kind;
  final Value<int> seq;
  final Value<String?> blobId;
  final Value<String?> recipeJson;
  final Value<int> recipeSchemaVersion;
  final Value<bool> recipeDeterministic;
  final Value<int> width;
  final Value<int> height;
  final Value<String> mime;
  final Value<Uint8List> plaintextSha256;
  final Value<int> plaintextSize;
  final Value<DateTime> createdAt;
  final Value<String> createdHlc;
  final Value<String> originDevice;
  final Value<DateTime?> evictedAt;
  final Value<int> rowid;
  const AssetVersionsCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.parentVersionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.seq = const Value.absent(),
    this.blobId = const Value.absent(),
    this.recipeJson = const Value.absent(),
    this.recipeSchemaVersion = const Value.absent(),
    this.recipeDeterministic = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.mime = const Value.absent(),
    this.plaintextSha256 = const Value.absent(),
    this.plaintextSize = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdHlc = const Value.absent(),
    this.originDevice = const Value.absent(),
    this.evictedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetVersionsCompanion.insert({
    required String id,
    required String assetId,
    this.parentVersionId = const Value.absent(),
    required String kind,
    required int seq,
    this.blobId = const Value.absent(),
    this.recipeJson = const Value.absent(),
    this.recipeSchemaVersion = const Value.absent(),
    this.recipeDeterministic = const Value.absent(),
    required int width,
    required int height,
    required String mime,
    required Uint8List plaintextSha256,
    required int plaintextSize,
    required DateTime createdAt,
    required String createdHlc,
    required String originDevice,
    this.evictedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       assetId = Value(assetId),
       kind = Value(kind),
       seq = Value(seq),
       width = Value(width),
       height = Value(height),
       mime = Value(mime),
       plaintextSha256 = Value(plaintextSha256),
       plaintextSize = Value(plaintextSize),
       createdAt = Value(createdAt),
       createdHlc = Value(createdHlc),
       originDevice = Value(originDevice);
  static Insertable<AssetVersionData> custom({
    Expression<String>? id,
    Expression<String>? assetId,
    Expression<String>? parentVersionId,
    Expression<String>? kind,
    Expression<int>? seq,
    Expression<String>? blobId,
    Expression<String>? recipeJson,
    Expression<int>? recipeSchemaVersion,
    Expression<bool>? recipeDeterministic,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? mime,
    Expression<Uint8List>? plaintextSha256,
    Expression<int>? plaintextSize,
    Expression<int>? createdAt,
    Expression<String>? createdHlc,
    Expression<String>? originDevice,
    Expression<int>? evictedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (parentVersionId != null) 'parent_version_id': parentVersionId,
      if (kind != null) 'kind': kind,
      if (seq != null) 'seq': seq,
      if (blobId != null) 'blob_id': blobId,
      if (recipeJson != null) 'recipe_json': recipeJson,
      if (recipeSchemaVersion != null)
        'recipe_schema_version': recipeSchemaVersion,
      if (recipeDeterministic != null)
        'recipe_deterministic': recipeDeterministic,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (mime != null) 'mime': mime,
      if (plaintextSha256 != null) 'plaintext_sha256': plaintextSha256,
      if (plaintextSize != null) 'plaintext_size': plaintextSize,
      if (createdAt != null) 'created_at': createdAt,
      if (createdHlc != null) 'created_hlc': createdHlc,
      if (originDevice != null) 'origin_device': originDevice,
      if (evictedAt != null) 'evicted_at': evictedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? assetId,
    Value<String?>? parentVersionId,
    Value<String>? kind,
    Value<int>? seq,
    Value<String?>? blobId,
    Value<String?>? recipeJson,
    Value<int>? recipeSchemaVersion,
    Value<bool>? recipeDeterministic,
    Value<int>? width,
    Value<int>? height,
    Value<String>? mime,
    Value<Uint8List>? plaintextSha256,
    Value<int>? plaintextSize,
    Value<DateTime>? createdAt,
    Value<String>? createdHlc,
    Value<String>? originDevice,
    Value<DateTime?>? evictedAt,
    Value<int>? rowid,
  }) {
    return AssetVersionsCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      parentVersionId: parentVersionId ?? this.parentVersionId,
      kind: kind ?? this.kind,
      seq: seq ?? this.seq,
      blobId: blobId ?? this.blobId,
      recipeJson: recipeJson ?? this.recipeJson,
      recipeSchemaVersion: recipeSchemaVersion ?? this.recipeSchemaVersion,
      recipeDeterministic: recipeDeterministic ?? this.recipeDeterministic,
      width: width ?? this.width,
      height: height ?? this.height,
      mime: mime ?? this.mime,
      plaintextSha256: plaintextSha256 ?? this.plaintextSha256,
      plaintextSize: plaintextSize ?? this.plaintextSize,
      createdAt: createdAt ?? this.createdAt,
      createdHlc: createdHlc ?? this.createdHlc,
      originDevice: originDevice ?? this.originDevice,
      evictedAt: evictedAt ?? this.evictedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (parentVersionId.present) {
      map['parent_version_id'] = Variable<String>(parentVersionId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (blobId.present) {
      map['blob_id'] = Variable<String>(blobId.value);
    }
    if (recipeJson.present) {
      map['recipe_json'] = Variable<String>(recipeJson.value);
    }
    if (recipeSchemaVersion.present) {
      map['recipe_schema_version'] = Variable<int>(recipeSchemaVersion.value);
    }
    if (recipeDeterministic.present) {
      map['recipe_deterministic'] = Variable<bool>(recipeDeterministic.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (plaintextSha256.present) {
      map['plaintext_sha256'] = Variable<Uint8List>(plaintextSha256.value);
    }
    if (plaintextSize.present) {
      map['plaintext_size'] = Variable<int>(plaintextSize.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $AssetVersionsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (createdHlc.present) {
      map['created_hlc'] = Variable<String>(createdHlc.value);
    }
    if (originDevice.present) {
      map['origin_device'] = Variable<String>(originDevice.value);
    }
    if (evictedAt.present) {
      map['evicted_at'] = Variable<int>(
        $AssetVersionsTable.$converterevictedAtn.toSql(evictedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetVersionsCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('parentVersionId: $parentVersionId, ')
          ..write('kind: $kind, ')
          ..write('seq: $seq, ')
          ..write('blobId: $blobId, ')
          ..write('recipeJson: $recipeJson, ')
          ..write('recipeSchemaVersion: $recipeSchemaVersion, ')
          ..write('recipeDeterministic: $recipeDeterministic, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('mime: $mime, ')
          ..write('plaintextSha256: $plaintextSha256, ')
          ..write('plaintextSize: $plaintextSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdHlc: $createdHlc, ')
          ..write('originDevice: $originDevice, ')
          ..write('evictedAt: $evictedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VersionPinsTable extends VersionPins
    with TableInfo<$VersionPinsTable, VersionPinData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VersionPinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionIdMeta = const VerificationMeta(
    'versionId',
  );
  @override
  late final GeneratedColumn<String> versionId = GeneratedColumn<String>(
    'version_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset_versions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($VersionPinsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [versionId, reason, refId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'version_pins';
  @override
  VerificationContext validateIntegrity(
    Insertable<VersionPinData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version_id')) {
      context.handle(
        _versionIdMeta,
        versionId.isAcceptableOrUnknown(data['version_id']!, _versionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_versionIdMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {versionId, reason, refId};
  @override
  VersionPinData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VersionPinData(
      versionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_id'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      )!,
      createdAt: $VersionPinsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $VersionPinsTable createAlias(String alias) {
    return $VersionPinsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
}

class VersionPinData extends DataClass implements Insertable<VersionPinData> {
  final String versionId;
  final String reason;
  final String refId;
  final DateTime createdAt;
  const VersionPinData({
    required this.versionId,
    required this.reason,
    required this.refId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version_id'] = Variable<String>(versionId);
    map['reason'] = Variable<String>(reason);
    map['ref_id'] = Variable<String>(refId);
    {
      map['created_at'] = Variable<int>(
        $VersionPinsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  VersionPinsCompanion toCompanion(bool nullToAbsent) {
    return VersionPinsCompanion(
      versionId: Value(versionId),
      reason: Value(reason),
      refId: Value(refId),
      createdAt: Value(createdAt),
    );
  }

  factory VersionPinData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VersionPinData(
      versionId: serializer.fromJson<String>(json['versionId']),
      reason: serializer.fromJson<String>(json['reason']),
      refId: serializer.fromJson<String>(json['refId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'versionId': serializer.toJson<String>(versionId),
      'reason': serializer.toJson<String>(reason),
      'refId': serializer.toJson<String>(refId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VersionPinData copyWith({
    String? versionId,
    String? reason,
    String? refId,
    DateTime? createdAt,
  }) => VersionPinData(
    versionId: versionId ?? this.versionId,
    reason: reason ?? this.reason,
    refId: refId ?? this.refId,
    createdAt: createdAt ?? this.createdAt,
  );
  VersionPinData copyWithCompanion(VersionPinsCompanion data) {
    return VersionPinData(
      versionId: data.versionId.present ? data.versionId.value : this.versionId,
      reason: data.reason.present ? data.reason.value : this.reason,
      refId: data.refId.present ? data.refId.value : this.refId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VersionPinData(')
          ..write('versionId: $versionId, ')
          ..write('reason: $reason, ')
          ..write('refId: $refId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(versionId, reason, refId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VersionPinData &&
          other.versionId == this.versionId &&
          other.reason == this.reason &&
          other.refId == this.refId &&
          other.createdAt == this.createdAt);
}

class VersionPinsCompanion extends UpdateCompanion<VersionPinData> {
  final Value<String> versionId;
  final Value<String> reason;
  final Value<String> refId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VersionPinsCompanion({
    this.versionId = const Value.absent(),
    this.reason = const Value.absent(),
    this.refId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VersionPinsCompanion.insert({
    required String versionId,
    required String reason,
    this.refId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : versionId = Value(versionId),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<VersionPinData> custom({
    Expression<String>? versionId,
    Expression<String>? reason,
    Expression<String>? refId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (versionId != null) 'version_id': versionId,
      if (reason != null) 'reason': reason,
      if (refId != null) 'ref_id': refId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VersionPinsCompanion copyWith({
    Value<String>? versionId,
    Value<String>? reason,
    Value<String>? refId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return VersionPinsCompanion(
      versionId: versionId ?? this.versionId,
      reason: reason ?? this.reason,
      refId: refId ?? this.refId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (versionId.present) {
      map['version_id'] = Variable<String>(versionId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $VersionPinsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VersionPinsCompanion(')
          ..write('versionId: $versionId, ')
          ..write('reason: $reason, ')
          ..write('refId: $refId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ThumbnailsTable extends Thumbnails
    with TableInfo<$ThumbnailsTable, ThumbnailData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThumbnailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionIdMeta = const VerificationMeta(
    'versionId',
  );
  @override
  late final GeneratedColumn<String> versionId = GeneratedColumn<String>(
    'version_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset_versions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sizeClassMeta = const VerificationMeta(
    'sizeClass',
  );
  @override
  late final GeneratedColumn<String> sizeClass = GeneratedColumn<String>(
    'size_class',
    aliasedName,
    false,
    check: () => sizeClass.isIn(const ['S', 'M', 'L']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blobIdMeta = const VerificationMeta('blobId');
  @override
  late final GeneratedColumn<String> blobId = GeneratedColumn<String>(
    'blob_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES blobs (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ThumbnailsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> lastAccessedAt =
      GeneratedColumn<int>(
        'last_accessed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ThumbnailsTable.$converterlastAccessedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    versionId,
    sizeClass,
    blobId,
    width,
    height,
    createdAt,
    lastAccessedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'thumbnails';
  @override
  VerificationContext validateIntegrity(
    Insertable<ThumbnailData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version_id')) {
      context.handle(
        _versionIdMeta,
        versionId.isAcceptableOrUnknown(data['version_id']!, _versionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_versionIdMeta);
    }
    if (data.containsKey('size_class')) {
      context.handle(
        _sizeClassMeta,
        sizeClass.isAcceptableOrUnknown(data['size_class']!, _sizeClassMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeClassMeta);
    }
    if (data.containsKey('blob_id')) {
      context.handle(
        _blobIdMeta,
        blobId.isAcceptableOrUnknown(data['blob_id']!, _blobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_blobIdMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {versionId, sizeClass},
  ];
  @override
  ThumbnailData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThumbnailData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      versionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_id'],
      )!,
      sizeClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}size_class'],
      )!,
      blobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blob_id'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      createdAt: $ThumbnailsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      lastAccessedAt: $ThumbnailsTable.$converterlastAccessedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_accessed_at'],
        )!,
      ),
    );
  }

  @override
  $ThumbnailsTable createAlias(String alias) {
    return $ThumbnailsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterlastAccessedAt =
      const MillisConverter();
}

class ThumbnailData extends DataClass implements Insertable<ThumbnailData> {
  final String id;
  final String versionId;
  final String sizeClass;
  final String blobId;
  final int width;
  final int height;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  const ThumbnailData({
    required this.id,
    required this.versionId,
    required this.sizeClass,
    required this.blobId,
    required this.width,
    required this.height,
    required this.createdAt,
    required this.lastAccessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version_id'] = Variable<String>(versionId);
    map['size_class'] = Variable<String>(sizeClass);
    map['blob_id'] = Variable<String>(blobId);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    {
      map['created_at'] = Variable<int>(
        $ThumbnailsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['last_accessed_at'] = Variable<int>(
        $ThumbnailsTable.$converterlastAccessedAt.toSql(lastAccessedAt),
      );
    }
    return map;
  }

  ThumbnailsCompanion toCompanion(bool nullToAbsent) {
    return ThumbnailsCompanion(
      id: Value(id),
      versionId: Value(versionId),
      sizeClass: Value(sizeClass),
      blobId: Value(blobId),
      width: Value(width),
      height: Value(height),
      createdAt: Value(createdAt),
      lastAccessedAt: Value(lastAccessedAt),
    );
  }

  factory ThumbnailData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThumbnailData(
      id: serializer.fromJson<String>(json['id']),
      versionId: serializer.fromJson<String>(json['versionId']),
      sizeClass: serializer.fromJson<String>(json['sizeClass']),
      blobId: serializer.fromJson<String>(json['blobId']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAccessedAt: serializer.fromJson<DateTime>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'versionId': serializer.toJson<String>(versionId),
      'sizeClass': serializer.toJson<String>(sizeClass),
      'blobId': serializer.toJson<String>(blobId),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAccessedAt': serializer.toJson<DateTime>(lastAccessedAt),
    };
  }

  ThumbnailData copyWith({
    String? id,
    String? versionId,
    String? sizeClass,
    String? blobId,
    int? width,
    int? height,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
  }) => ThumbnailData(
    id: id ?? this.id,
    versionId: versionId ?? this.versionId,
    sizeClass: sizeClass ?? this.sizeClass,
    blobId: blobId ?? this.blobId,
    width: width ?? this.width,
    height: height ?? this.height,
    createdAt: createdAt ?? this.createdAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
  );
  ThumbnailData copyWithCompanion(ThumbnailsCompanion data) {
    return ThumbnailData(
      id: data.id.present ? data.id.value : this.id,
      versionId: data.versionId.present ? data.versionId.value : this.versionId,
      sizeClass: data.sizeClass.present ? data.sizeClass.value : this.sizeClass,
      blobId: data.blobId.present ? data.blobId.value : this.blobId,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThumbnailData(')
          ..write('id: $id, ')
          ..write('versionId: $versionId, ')
          ..write('sizeClass: $sizeClass, ')
          ..write('blobId: $blobId, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    versionId,
    sizeClass,
    blobId,
    width,
    height,
    createdAt,
    lastAccessedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThumbnailData &&
          other.id == this.id &&
          other.versionId == this.versionId &&
          other.sizeClass == this.sizeClass &&
          other.blobId == this.blobId &&
          other.width == this.width &&
          other.height == this.height &&
          other.createdAt == this.createdAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class ThumbnailsCompanion extends UpdateCompanion<ThumbnailData> {
  final Value<String> id;
  final Value<String> versionId;
  final Value<String> sizeClass;
  final Value<String> blobId;
  final Value<int> width;
  final Value<int> height;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastAccessedAt;
  final Value<int> rowid;
  const ThumbnailsCompanion({
    this.id = const Value.absent(),
    this.versionId = const Value.absent(),
    this.sizeClass = const Value.absent(),
    this.blobId = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ThumbnailsCompanion.insert({
    required String id,
    required String versionId,
    required String sizeClass,
    required String blobId,
    required int width,
    required int height,
    required DateTime createdAt,
    required DateTime lastAccessedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       versionId = Value(versionId),
       sizeClass = Value(sizeClass),
       blobId = Value(blobId),
       width = Value(width),
       height = Value(height),
       createdAt = Value(createdAt),
       lastAccessedAt = Value(lastAccessedAt);
  static Insertable<ThumbnailData> custom({
    Expression<String>? id,
    Expression<String>? versionId,
    Expression<String>? sizeClass,
    Expression<String>? blobId,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? createdAt,
    Expression<int>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (versionId != null) 'version_id': versionId,
      if (sizeClass != null) 'size_class': sizeClass,
      if (blobId != null) 'blob_id': blobId,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ThumbnailsCompanion copyWith({
    Value<String>? id,
    Value<String>? versionId,
    Value<String>? sizeClass,
    Value<String>? blobId,
    Value<int>? width,
    Value<int>? height,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastAccessedAt,
    Value<int>? rowid,
  }) {
    return ThumbnailsCompanion(
      id: id ?? this.id,
      versionId: versionId ?? this.versionId,
      sizeClass: sizeClass ?? this.sizeClass,
      blobId: blobId ?? this.blobId,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (versionId.present) {
      map['version_id'] = Variable<String>(versionId.value);
    }
    if (sizeClass.present) {
      map['size_class'] = Variable<String>(sizeClass.value);
    }
    if (blobId.present) {
      map['blob_id'] = Variable<String>(blobId.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $ThumbnailsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<int>(
        $ThumbnailsTable.$converterlastAccessedAt.toSql(lastAccessedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThumbnailsCompanion(')
          ..write('id: $id, ')
          ..write('versionId: $versionId, ')
          ..write('sizeClass: $sizeClass, ')
          ..write('blobId: $blobId, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExportRecordsTable extends ExportRecords
    with TableInfo<$ExportRecordsTable, ExportRecordData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExportRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vault_entries (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _requestJsonMeta = const VerificationMeta(
    'requestJson',
  );
  @override
  late final GeneratedColumn<String> requestJson = GeneratedColumn<String>(
    'request_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestSchemaVersionMeta =
      const VerificationMeta('requestSchemaVersion');
  @override
  late final GeneratedColumn<int> requestSchemaVersion = GeneratedColumn<int>(
    'request_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _layoutMeta = const VerificationMeta('layout');
  @override
  late final GeneratedColumn<String> layout = GeneratedColumn<String>(
    'layout',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paperSizeMeta = const VerificationMeta(
    'paperSize',
  );
  @override
  late final GeneratedColumn<String> paperSize = GeneratedColumn<String>(
    'paper_size',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outWidthMeta = const VerificationMeta(
    'outWidth',
  );
  @override
  late final GeneratedColumn<int> outWidth = GeneratedColumn<int>(
    'out_width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outHeightMeta = const VerificationMeta(
    'outHeight',
  );
  @override
  late final GeneratedColumn<int> outHeight = GeneratedColumn<int>(
    'out_height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dpiMeta = const VerificationMeta('dpi');
  @override
  late final GeneratedColumn<int> dpi = GeneratedColumn<int>(
    'dpi',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<int> quality = GeneratedColumn<int>(
    'quality',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetBytesMeta = const VerificationMeta(
    'targetBytes',
  );
  @override
  late final GeneratedColumn<int> targetBytes = GeneratedColumn<int>(
    'target_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxBytesMeta = const VerificationMeta(
    'maxBytes',
  );
  @override
  late final GeneratedColumn<int> maxBytes = GeneratedColumn<int>(
    'max_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualBytesMeta = const VerificationMeta(
    'actualBytes',
  );
  @override
  late final GeneratedColumn<int> actualBytes = GeneratedColumn<int>(
    'actual_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(const ['SUCCESS', 'FAILED', 'CANCELLED']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failureCodeMeta = const VerificationMeta(
    'failureCode',
  );
  @override
  late final GeneratedColumn<String> failureCode = GeneratedColumn<String>(
    'failure_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warningsJsonMeta = const VerificationMeta(
    'warningsJson',
  );
  @override
  late final GeneratedColumn<String> warningsJson = GeneratedColumn<String>(
    'warnings_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artifactBlobIdMeta = const VerificationMeta(
    'artifactBlobId',
  );
  @override
  late final GeneratedColumn<String> artifactBlobId = GeneratedColumn<String>(
    'artifact_blob_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES blobs (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _retainArtifactMeta = const VerificationMeta(
    'retainArtifact',
  );
  @override
  late final GeneratedColumn<bool> retainArtifact = GeneratedColumn<bool>(
    'retain_artifact',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retain_artifact" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int>
  artifactExpiresAt = GeneratedColumn<int>(
    'artifact_expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($ExportRecordsTable.$converterartifactExpiresAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ExportRecordsTable.$convertercreatedAt);
  static const VerificationMeta _originDeviceMeta = const VerificationMeta(
    'originDevice',
  );
  @override
  late final GeneratedColumn<String> originDevice = GeneratedColumn<String>(
    'origin_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE RESTRICT',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    requestJson,
    requestSchemaVersion,
    format,
    layout,
    paperSize,
    outWidth,
    outHeight,
    dpi,
    quality,
    targetBytes,
    maxBytes,
    actualBytes,
    pageCount,
    status,
    failureCode,
    warningsJson,
    durationMs,
    artifactBlobId,
    retainArtifact,
    artifactExpiresAt,
    createdAt,
    originDevice,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'export_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExportRecordData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('request_json')) {
      context.handle(
        _requestJsonMeta,
        requestJson.isAcceptableOrUnknown(
          data['request_json']!,
          _requestJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestJsonMeta);
    }
    if (data.containsKey('request_schema_version')) {
      context.handle(
        _requestSchemaVersionMeta,
        requestSchemaVersion.isAcceptableOrUnknown(
          data['request_schema_version']!,
          _requestSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestSchemaVersionMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('layout')) {
      context.handle(
        _layoutMeta,
        layout.isAcceptableOrUnknown(data['layout']!, _layoutMeta),
      );
    }
    if (data.containsKey('paper_size')) {
      context.handle(
        _paperSizeMeta,
        paperSize.isAcceptableOrUnknown(data['paper_size']!, _paperSizeMeta),
      );
    }
    if (data.containsKey('out_width')) {
      context.handle(
        _outWidthMeta,
        outWidth.isAcceptableOrUnknown(data['out_width']!, _outWidthMeta),
      );
    }
    if (data.containsKey('out_height')) {
      context.handle(
        _outHeightMeta,
        outHeight.isAcceptableOrUnknown(data['out_height']!, _outHeightMeta),
      );
    }
    if (data.containsKey('dpi')) {
      context.handle(
        _dpiMeta,
        dpi.isAcceptableOrUnknown(data['dpi']!, _dpiMeta),
      );
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    }
    if (data.containsKey('target_bytes')) {
      context.handle(
        _targetBytesMeta,
        targetBytes.isAcceptableOrUnknown(
          data['target_bytes']!,
          _targetBytesMeta,
        ),
      );
    }
    if (data.containsKey('max_bytes')) {
      context.handle(
        _maxBytesMeta,
        maxBytes.isAcceptableOrUnknown(data['max_bytes']!, _maxBytesMeta),
      );
    }
    if (data.containsKey('actual_bytes')) {
      context.handle(
        _actualBytesMeta,
        actualBytes.isAcceptableOrUnknown(
          data['actual_bytes']!,
          _actualBytesMeta,
        ),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('failure_code')) {
      context.handle(
        _failureCodeMeta,
        failureCode.isAcceptableOrUnknown(
          data['failure_code']!,
          _failureCodeMeta,
        ),
      );
    }
    if (data.containsKey('warnings_json')) {
      context.handle(
        _warningsJsonMeta,
        warningsJson.isAcceptableOrUnknown(
          data['warnings_json']!,
          _warningsJsonMeta,
        ),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('artifact_blob_id')) {
      context.handle(
        _artifactBlobIdMeta,
        artifactBlobId.isAcceptableOrUnknown(
          data['artifact_blob_id']!,
          _artifactBlobIdMeta,
        ),
      );
    }
    if (data.containsKey('retain_artifact')) {
      context.handle(
        _retainArtifactMeta,
        retainArtifact.isAcceptableOrUnknown(
          data['retain_artifact']!,
          _retainArtifactMeta,
        ),
      );
    }
    if (data.containsKey('origin_device')) {
      context.handle(
        _originDeviceMeta,
        originDevice.isAcceptableOrUnknown(
          data['origin_device']!,
          _originDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExportRecordData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportRecordData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      requestJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_json'],
      )!,
      requestSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}request_schema_version'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      layout: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout'],
      ),
      paperSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paper_size'],
      ),
      outWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}out_width'],
      ),
      outHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}out_height'],
      ),
      dpi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dpi'],
      ),
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quality'],
      ),
      targetBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_bytes'],
      ),
      maxBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_bytes'],
      ),
      actualBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_bytes'],
      ),
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      failureCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_code'],
      ),
      warningsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warnings_json'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      artifactBlobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artifact_blob_id'],
      ),
      retainArtifact: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retain_artifact'],
      )!,
      artifactExpiresAt: $ExportRecordsTable.$converterartifactExpiresAtn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}artifact_expires_at'],
            ),
          ),
      createdAt: $ExportRecordsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      originDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device'],
      )!,
    );
  }

  @override
  $ExportRecordsTable createAlias(String alias) {
    return $ExportRecordsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterartifactExpiresAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterartifactExpiresAtn =
      NullAwareTypeConverter.wrap($converterartifactExpiresAt);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
}

class ExportRecordData extends DataClass
    implements Insertable<ExportRecordData> {
  final String id;
  final String entryId;
  final String requestJson;
  final int requestSchemaVersion;
  final String format;
  final String? layout;
  final String? paperSize;
  final int? outWidth;
  final int? outHeight;
  final int? dpi;
  final int? quality;
  final int? targetBytes;
  final int? maxBytes;
  final int? actualBytes;
  final int? pageCount;
  final String status;
  final String? failureCode;
  final String? warningsJson;
  final int? durationMs;
  final String? artifactBlobId;
  final bool retainArtifact;
  final DateTime? artifactExpiresAt;
  final DateTime createdAt;
  final String originDevice;
  const ExportRecordData({
    required this.id,
    required this.entryId,
    required this.requestJson,
    required this.requestSchemaVersion,
    required this.format,
    this.layout,
    this.paperSize,
    this.outWidth,
    this.outHeight,
    this.dpi,
    this.quality,
    this.targetBytes,
    this.maxBytes,
    this.actualBytes,
    this.pageCount,
    required this.status,
    this.failureCode,
    this.warningsJson,
    this.durationMs,
    this.artifactBlobId,
    required this.retainArtifact,
    this.artifactExpiresAt,
    required this.createdAt,
    required this.originDevice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['request_json'] = Variable<String>(requestJson);
    map['request_schema_version'] = Variable<int>(requestSchemaVersion);
    map['format'] = Variable<String>(format);
    if (!nullToAbsent || layout != null) {
      map['layout'] = Variable<String>(layout);
    }
    if (!nullToAbsent || paperSize != null) {
      map['paper_size'] = Variable<String>(paperSize);
    }
    if (!nullToAbsent || outWidth != null) {
      map['out_width'] = Variable<int>(outWidth);
    }
    if (!nullToAbsent || outHeight != null) {
      map['out_height'] = Variable<int>(outHeight);
    }
    if (!nullToAbsent || dpi != null) {
      map['dpi'] = Variable<int>(dpi);
    }
    if (!nullToAbsent || quality != null) {
      map['quality'] = Variable<int>(quality);
    }
    if (!nullToAbsent || targetBytes != null) {
      map['target_bytes'] = Variable<int>(targetBytes);
    }
    if (!nullToAbsent || maxBytes != null) {
      map['max_bytes'] = Variable<int>(maxBytes);
    }
    if (!nullToAbsent || actualBytes != null) {
      map['actual_bytes'] = Variable<int>(actualBytes);
    }
    if (!nullToAbsent || pageCount != null) {
      map['page_count'] = Variable<int>(pageCount);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || failureCode != null) {
      map['failure_code'] = Variable<String>(failureCode);
    }
    if (!nullToAbsent || warningsJson != null) {
      map['warnings_json'] = Variable<String>(warningsJson);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || artifactBlobId != null) {
      map['artifact_blob_id'] = Variable<String>(artifactBlobId);
    }
    map['retain_artifact'] = Variable<bool>(retainArtifact);
    if (!nullToAbsent || artifactExpiresAt != null) {
      map['artifact_expires_at'] = Variable<int>(
        $ExportRecordsTable.$converterartifactExpiresAtn.toSql(
          artifactExpiresAt,
        ),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $ExportRecordsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    map['origin_device'] = Variable<String>(originDevice);
    return map;
  }

  ExportRecordsCompanion toCompanion(bool nullToAbsent) {
    return ExportRecordsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      requestJson: Value(requestJson),
      requestSchemaVersion: Value(requestSchemaVersion),
      format: Value(format),
      layout: layout == null && nullToAbsent
          ? const Value.absent()
          : Value(layout),
      paperSize: paperSize == null && nullToAbsent
          ? const Value.absent()
          : Value(paperSize),
      outWidth: outWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(outWidth),
      outHeight: outHeight == null && nullToAbsent
          ? const Value.absent()
          : Value(outHeight),
      dpi: dpi == null && nullToAbsent ? const Value.absent() : Value(dpi),
      quality: quality == null && nullToAbsent
          ? const Value.absent()
          : Value(quality),
      targetBytes: targetBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(targetBytes),
      maxBytes: maxBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(maxBytes),
      actualBytes: actualBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(actualBytes),
      pageCount: pageCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pageCount),
      status: Value(status),
      failureCode: failureCode == null && nullToAbsent
          ? const Value.absent()
          : Value(failureCode),
      warningsJson: warningsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(warningsJson),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      artifactBlobId: artifactBlobId == null && nullToAbsent
          ? const Value.absent()
          : Value(artifactBlobId),
      retainArtifact: Value(retainArtifact),
      artifactExpiresAt: artifactExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(artifactExpiresAt),
      createdAt: Value(createdAt),
      originDevice: Value(originDevice),
    );
  }

  factory ExportRecordData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportRecordData(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      requestJson: serializer.fromJson<String>(json['requestJson']),
      requestSchemaVersion: serializer.fromJson<int>(
        json['requestSchemaVersion'],
      ),
      format: serializer.fromJson<String>(json['format']),
      layout: serializer.fromJson<String?>(json['layout']),
      paperSize: serializer.fromJson<String?>(json['paperSize']),
      outWidth: serializer.fromJson<int?>(json['outWidth']),
      outHeight: serializer.fromJson<int?>(json['outHeight']),
      dpi: serializer.fromJson<int?>(json['dpi']),
      quality: serializer.fromJson<int?>(json['quality']),
      targetBytes: serializer.fromJson<int?>(json['targetBytes']),
      maxBytes: serializer.fromJson<int?>(json['maxBytes']),
      actualBytes: serializer.fromJson<int?>(json['actualBytes']),
      pageCount: serializer.fromJson<int?>(json['pageCount']),
      status: serializer.fromJson<String>(json['status']),
      failureCode: serializer.fromJson<String?>(json['failureCode']),
      warningsJson: serializer.fromJson<String?>(json['warningsJson']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      artifactBlobId: serializer.fromJson<String?>(json['artifactBlobId']),
      retainArtifact: serializer.fromJson<bool>(json['retainArtifact']),
      artifactExpiresAt: serializer.fromJson<DateTime?>(
        json['artifactExpiresAt'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      originDevice: serializer.fromJson<String>(json['originDevice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'requestJson': serializer.toJson<String>(requestJson),
      'requestSchemaVersion': serializer.toJson<int>(requestSchemaVersion),
      'format': serializer.toJson<String>(format),
      'layout': serializer.toJson<String?>(layout),
      'paperSize': serializer.toJson<String?>(paperSize),
      'outWidth': serializer.toJson<int?>(outWidth),
      'outHeight': serializer.toJson<int?>(outHeight),
      'dpi': serializer.toJson<int?>(dpi),
      'quality': serializer.toJson<int?>(quality),
      'targetBytes': serializer.toJson<int?>(targetBytes),
      'maxBytes': serializer.toJson<int?>(maxBytes),
      'actualBytes': serializer.toJson<int?>(actualBytes),
      'pageCount': serializer.toJson<int?>(pageCount),
      'status': serializer.toJson<String>(status),
      'failureCode': serializer.toJson<String?>(failureCode),
      'warningsJson': serializer.toJson<String?>(warningsJson),
      'durationMs': serializer.toJson<int?>(durationMs),
      'artifactBlobId': serializer.toJson<String?>(artifactBlobId),
      'retainArtifact': serializer.toJson<bool>(retainArtifact),
      'artifactExpiresAt': serializer.toJson<DateTime?>(artifactExpiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'originDevice': serializer.toJson<String>(originDevice),
    };
  }

  ExportRecordData copyWith({
    String? id,
    String? entryId,
    String? requestJson,
    int? requestSchemaVersion,
    String? format,
    Value<String?> layout = const Value.absent(),
    Value<String?> paperSize = const Value.absent(),
    Value<int?> outWidth = const Value.absent(),
    Value<int?> outHeight = const Value.absent(),
    Value<int?> dpi = const Value.absent(),
    Value<int?> quality = const Value.absent(),
    Value<int?> targetBytes = const Value.absent(),
    Value<int?> maxBytes = const Value.absent(),
    Value<int?> actualBytes = const Value.absent(),
    Value<int?> pageCount = const Value.absent(),
    String? status,
    Value<String?> failureCode = const Value.absent(),
    Value<String?> warningsJson = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<String?> artifactBlobId = const Value.absent(),
    bool? retainArtifact,
    Value<DateTime?> artifactExpiresAt = const Value.absent(),
    DateTime? createdAt,
    String? originDevice,
  }) => ExportRecordData(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    requestJson: requestJson ?? this.requestJson,
    requestSchemaVersion: requestSchemaVersion ?? this.requestSchemaVersion,
    format: format ?? this.format,
    layout: layout.present ? layout.value : this.layout,
    paperSize: paperSize.present ? paperSize.value : this.paperSize,
    outWidth: outWidth.present ? outWidth.value : this.outWidth,
    outHeight: outHeight.present ? outHeight.value : this.outHeight,
    dpi: dpi.present ? dpi.value : this.dpi,
    quality: quality.present ? quality.value : this.quality,
    targetBytes: targetBytes.present ? targetBytes.value : this.targetBytes,
    maxBytes: maxBytes.present ? maxBytes.value : this.maxBytes,
    actualBytes: actualBytes.present ? actualBytes.value : this.actualBytes,
    pageCount: pageCount.present ? pageCount.value : this.pageCount,
    status: status ?? this.status,
    failureCode: failureCode.present ? failureCode.value : this.failureCode,
    warningsJson: warningsJson.present ? warningsJson.value : this.warningsJson,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    artifactBlobId: artifactBlobId.present
        ? artifactBlobId.value
        : this.artifactBlobId,
    retainArtifact: retainArtifact ?? this.retainArtifact,
    artifactExpiresAt: artifactExpiresAt.present
        ? artifactExpiresAt.value
        : this.artifactExpiresAt,
    createdAt: createdAt ?? this.createdAt,
    originDevice: originDevice ?? this.originDevice,
  );
  ExportRecordData copyWithCompanion(ExportRecordsCompanion data) {
    return ExportRecordData(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      requestJson: data.requestJson.present
          ? data.requestJson.value
          : this.requestJson,
      requestSchemaVersion: data.requestSchemaVersion.present
          ? data.requestSchemaVersion.value
          : this.requestSchemaVersion,
      format: data.format.present ? data.format.value : this.format,
      layout: data.layout.present ? data.layout.value : this.layout,
      paperSize: data.paperSize.present ? data.paperSize.value : this.paperSize,
      outWidth: data.outWidth.present ? data.outWidth.value : this.outWidth,
      outHeight: data.outHeight.present ? data.outHeight.value : this.outHeight,
      dpi: data.dpi.present ? data.dpi.value : this.dpi,
      quality: data.quality.present ? data.quality.value : this.quality,
      targetBytes: data.targetBytes.present
          ? data.targetBytes.value
          : this.targetBytes,
      maxBytes: data.maxBytes.present ? data.maxBytes.value : this.maxBytes,
      actualBytes: data.actualBytes.present
          ? data.actualBytes.value
          : this.actualBytes,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      status: data.status.present ? data.status.value : this.status,
      failureCode: data.failureCode.present
          ? data.failureCode.value
          : this.failureCode,
      warningsJson: data.warningsJson.present
          ? data.warningsJson.value
          : this.warningsJson,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      artifactBlobId: data.artifactBlobId.present
          ? data.artifactBlobId.value
          : this.artifactBlobId,
      retainArtifact: data.retainArtifact.present
          ? data.retainArtifact.value
          : this.retainArtifact,
      artifactExpiresAt: data.artifactExpiresAt.present
          ? data.artifactExpiresAt.value
          : this.artifactExpiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      originDevice: data.originDevice.present
          ? data.originDevice.value
          : this.originDevice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportRecordData(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('requestJson: $requestJson, ')
          ..write('requestSchemaVersion: $requestSchemaVersion, ')
          ..write('format: $format, ')
          ..write('layout: $layout, ')
          ..write('paperSize: $paperSize, ')
          ..write('outWidth: $outWidth, ')
          ..write('outHeight: $outHeight, ')
          ..write('dpi: $dpi, ')
          ..write('quality: $quality, ')
          ..write('targetBytes: $targetBytes, ')
          ..write('maxBytes: $maxBytes, ')
          ..write('actualBytes: $actualBytes, ')
          ..write('pageCount: $pageCount, ')
          ..write('status: $status, ')
          ..write('failureCode: $failureCode, ')
          ..write('warningsJson: $warningsJson, ')
          ..write('durationMs: $durationMs, ')
          ..write('artifactBlobId: $artifactBlobId, ')
          ..write('retainArtifact: $retainArtifact, ')
          ..write('artifactExpiresAt: $artifactExpiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('originDevice: $originDevice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    entryId,
    requestJson,
    requestSchemaVersion,
    format,
    layout,
    paperSize,
    outWidth,
    outHeight,
    dpi,
    quality,
    targetBytes,
    maxBytes,
    actualBytes,
    pageCount,
    status,
    failureCode,
    warningsJson,
    durationMs,
    artifactBlobId,
    retainArtifact,
    artifactExpiresAt,
    createdAt,
    originDevice,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportRecordData &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.requestJson == this.requestJson &&
          other.requestSchemaVersion == this.requestSchemaVersion &&
          other.format == this.format &&
          other.layout == this.layout &&
          other.paperSize == this.paperSize &&
          other.outWidth == this.outWidth &&
          other.outHeight == this.outHeight &&
          other.dpi == this.dpi &&
          other.quality == this.quality &&
          other.targetBytes == this.targetBytes &&
          other.maxBytes == this.maxBytes &&
          other.actualBytes == this.actualBytes &&
          other.pageCount == this.pageCount &&
          other.status == this.status &&
          other.failureCode == this.failureCode &&
          other.warningsJson == this.warningsJson &&
          other.durationMs == this.durationMs &&
          other.artifactBlobId == this.artifactBlobId &&
          other.retainArtifact == this.retainArtifact &&
          other.artifactExpiresAt == this.artifactExpiresAt &&
          other.createdAt == this.createdAt &&
          other.originDevice == this.originDevice);
}

class ExportRecordsCompanion extends UpdateCompanion<ExportRecordData> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<String> requestJson;
  final Value<int> requestSchemaVersion;
  final Value<String> format;
  final Value<String?> layout;
  final Value<String?> paperSize;
  final Value<int?> outWidth;
  final Value<int?> outHeight;
  final Value<int?> dpi;
  final Value<int?> quality;
  final Value<int?> targetBytes;
  final Value<int?> maxBytes;
  final Value<int?> actualBytes;
  final Value<int?> pageCount;
  final Value<String> status;
  final Value<String?> failureCode;
  final Value<String?> warningsJson;
  final Value<int?> durationMs;
  final Value<String?> artifactBlobId;
  final Value<bool> retainArtifact;
  final Value<DateTime?> artifactExpiresAt;
  final Value<DateTime> createdAt;
  final Value<String> originDevice;
  final Value<int> rowid;
  const ExportRecordsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.requestJson = const Value.absent(),
    this.requestSchemaVersion = const Value.absent(),
    this.format = const Value.absent(),
    this.layout = const Value.absent(),
    this.paperSize = const Value.absent(),
    this.outWidth = const Value.absent(),
    this.outHeight = const Value.absent(),
    this.dpi = const Value.absent(),
    this.quality = const Value.absent(),
    this.targetBytes = const Value.absent(),
    this.maxBytes = const Value.absent(),
    this.actualBytes = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.status = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.warningsJson = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.artifactBlobId = const Value.absent(),
    this.retainArtifact = const Value.absent(),
    this.artifactExpiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.originDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExportRecordsCompanion.insert({
    required String id,
    required String entryId,
    required String requestJson,
    required int requestSchemaVersion,
    required String format,
    this.layout = const Value.absent(),
    this.paperSize = const Value.absent(),
    this.outWidth = const Value.absent(),
    this.outHeight = const Value.absent(),
    this.dpi = const Value.absent(),
    this.quality = const Value.absent(),
    this.targetBytes = const Value.absent(),
    this.maxBytes = const Value.absent(),
    this.actualBytes = const Value.absent(),
    this.pageCount = const Value.absent(),
    required String status,
    this.failureCode = const Value.absent(),
    this.warningsJson = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.artifactBlobId = const Value.absent(),
    this.retainArtifact = const Value.absent(),
    this.artifactExpiresAt = const Value.absent(),
    required DateTime createdAt,
    required String originDevice,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       requestJson = Value(requestJson),
       requestSchemaVersion = Value(requestSchemaVersion),
       format = Value(format),
       status = Value(status),
       createdAt = Value(createdAt),
       originDevice = Value(originDevice);
  static Insertable<ExportRecordData> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? requestJson,
    Expression<int>? requestSchemaVersion,
    Expression<String>? format,
    Expression<String>? layout,
    Expression<String>? paperSize,
    Expression<int>? outWidth,
    Expression<int>? outHeight,
    Expression<int>? dpi,
    Expression<int>? quality,
    Expression<int>? targetBytes,
    Expression<int>? maxBytes,
    Expression<int>? actualBytes,
    Expression<int>? pageCount,
    Expression<String>? status,
    Expression<String>? failureCode,
    Expression<String>? warningsJson,
    Expression<int>? durationMs,
    Expression<String>? artifactBlobId,
    Expression<bool>? retainArtifact,
    Expression<int>? artifactExpiresAt,
    Expression<int>? createdAt,
    Expression<String>? originDevice,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (requestJson != null) 'request_json': requestJson,
      if (requestSchemaVersion != null)
        'request_schema_version': requestSchemaVersion,
      if (format != null) 'format': format,
      if (layout != null) 'layout': layout,
      if (paperSize != null) 'paper_size': paperSize,
      if (outWidth != null) 'out_width': outWidth,
      if (outHeight != null) 'out_height': outHeight,
      if (dpi != null) 'dpi': dpi,
      if (quality != null) 'quality': quality,
      if (targetBytes != null) 'target_bytes': targetBytes,
      if (maxBytes != null) 'max_bytes': maxBytes,
      if (actualBytes != null) 'actual_bytes': actualBytes,
      if (pageCount != null) 'page_count': pageCount,
      if (status != null) 'status': status,
      if (failureCode != null) 'failure_code': failureCode,
      if (warningsJson != null) 'warnings_json': warningsJson,
      if (durationMs != null) 'duration_ms': durationMs,
      if (artifactBlobId != null) 'artifact_blob_id': artifactBlobId,
      if (retainArtifact != null) 'retain_artifact': retainArtifact,
      if (artifactExpiresAt != null) 'artifact_expires_at': artifactExpiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (originDevice != null) 'origin_device': originDevice,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExportRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? entryId,
    Value<String>? requestJson,
    Value<int>? requestSchemaVersion,
    Value<String>? format,
    Value<String?>? layout,
    Value<String?>? paperSize,
    Value<int?>? outWidth,
    Value<int?>? outHeight,
    Value<int?>? dpi,
    Value<int?>? quality,
    Value<int?>? targetBytes,
    Value<int?>? maxBytes,
    Value<int?>? actualBytes,
    Value<int?>? pageCount,
    Value<String>? status,
    Value<String?>? failureCode,
    Value<String?>? warningsJson,
    Value<int?>? durationMs,
    Value<String?>? artifactBlobId,
    Value<bool>? retainArtifact,
    Value<DateTime?>? artifactExpiresAt,
    Value<DateTime>? createdAt,
    Value<String>? originDevice,
    Value<int>? rowid,
  }) {
    return ExportRecordsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      requestJson: requestJson ?? this.requestJson,
      requestSchemaVersion: requestSchemaVersion ?? this.requestSchemaVersion,
      format: format ?? this.format,
      layout: layout ?? this.layout,
      paperSize: paperSize ?? this.paperSize,
      outWidth: outWidth ?? this.outWidth,
      outHeight: outHeight ?? this.outHeight,
      dpi: dpi ?? this.dpi,
      quality: quality ?? this.quality,
      targetBytes: targetBytes ?? this.targetBytes,
      maxBytes: maxBytes ?? this.maxBytes,
      actualBytes: actualBytes ?? this.actualBytes,
      pageCount: pageCount ?? this.pageCount,
      status: status ?? this.status,
      failureCode: failureCode ?? this.failureCode,
      warningsJson: warningsJson ?? this.warningsJson,
      durationMs: durationMs ?? this.durationMs,
      artifactBlobId: artifactBlobId ?? this.artifactBlobId,
      retainArtifact: retainArtifact ?? this.retainArtifact,
      artifactExpiresAt: artifactExpiresAt ?? this.artifactExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      originDevice: originDevice ?? this.originDevice,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (requestJson.present) {
      map['request_json'] = Variable<String>(requestJson.value);
    }
    if (requestSchemaVersion.present) {
      map['request_schema_version'] = Variable<int>(requestSchemaVersion.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (layout.present) {
      map['layout'] = Variable<String>(layout.value);
    }
    if (paperSize.present) {
      map['paper_size'] = Variable<String>(paperSize.value);
    }
    if (outWidth.present) {
      map['out_width'] = Variable<int>(outWidth.value);
    }
    if (outHeight.present) {
      map['out_height'] = Variable<int>(outHeight.value);
    }
    if (dpi.present) {
      map['dpi'] = Variable<int>(dpi.value);
    }
    if (quality.present) {
      map['quality'] = Variable<int>(quality.value);
    }
    if (targetBytes.present) {
      map['target_bytes'] = Variable<int>(targetBytes.value);
    }
    if (maxBytes.present) {
      map['max_bytes'] = Variable<int>(maxBytes.value);
    }
    if (actualBytes.present) {
      map['actual_bytes'] = Variable<int>(actualBytes.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (failureCode.present) {
      map['failure_code'] = Variable<String>(failureCode.value);
    }
    if (warningsJson.present) {
      map['warnings_json'] = Variable<String>(warningsJson.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (artifactBlobId.present) {
      map['artifact_blob_id'] = Variable<String>(artifactBlobId.value);
    }
    if (retainArtifact.present) {
      map['retain_artifact'] = Variable<bool>(retainArtifact.value);
    }
    if (artifactExpiresAt.present) {
      map['artifact_expires_at'] = Variable<int>(
        $ExportRecordsTable.$converterartifactExpiresAtn.toSql(
          artifactExpiresAt.value,
        ),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $ExportRecordsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (originDevice.present) {
      map['origin_device'] = Variable<String>(originDevice.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportRecordsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('requestJson: $requestJson, ')
          ..write('requestSchemaVersion: $requestSchemaVersion, ')
          ..write('format: $format, ')
          ..write('layout: $layout, ')
          ..write('paperSize: $paperSize, ')
          ..write('outWidth: $outWidth, ')
          ..write('outHeight: $outHeight, ')
          ..write('dpi: $dpi, ')
          ..write('quality: $quality, ')
          ..write('targetBytes: $targetBytes, ')
          ..write('maxBytes: $maxBytes, ')
          ..write('actualBytes: $actualBytes, ')
          ..write('pageCount: $pageCount, ')
          ..write('status: $status, ')
          ..write('failureCode: $failureCode, ')
          ..write('warningsJson: $warningsJson, ')
          ..write('durationMs: $durationMs, ')
          ..write('artifactBlobId: $artifactBlobId, ')
          ..write('retainArtifact: $retainArtifact, ')
          ..write('artifactExpiresAt: $artifactExpiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('originDevice: $originDevice, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExportRecordSourcesTable extends ExportRecordSources
    with TableInfo<$ExportRecordSourcesTable, ExportRecordSourceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExportRecordSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exportIdMeta = const VerificationMeta(
    'exportId',
  );
  @override
  late final GeneratedColumn<String> exportId = GeneratedColumn<String>(
    'export_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES export_records (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionIdMeta = const VerificationMeta(
    'versionId',
  );
  @override
  late final GeneratedColumn<String> versionId = GeneratedColumn<String>(
    'version_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset_versions (id) ON DELETE RESTRICT',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [exportId, ordinal, versionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'export_record_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExportRecordSourceData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('export_id')) {
      context.handle(
        _exportIdMeta,
        exportId.isAcceptableOrUnknown(data['export_id']!, _exportIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exportIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('version_id')) {
      context.handle(
        _versionIdMeta,
        versionId.isAcceptableOrUnknown(data['version_id']!, _versionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_versionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exportId, ordinal};
  @override
  ExportRecordSourceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportRecordSourceData(
      exportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}export_id'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      versionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_id'],
      )!,
    );
  }

  @override
  $ExportRecordSourcesTable createAlias(String alias) {
    return $ExportRecordSourcesTable(attachedDatabase, alias);
  }
}

class ExportRecordSourceData extends DataClass
    implements Insertable<ExportRecordSourceData> {
  final String exportId;
  final int ordinal;
  final String versionId;
  const ExportRecordSourceData({
    required this.exportId,
    required this.ordinal,
    required this.versionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['export_id'] = Variable<String>(exportId);
    map['ordinal'] = Variable<int>(ordinal);
    map['version_id'] = Variable<String>(versionId);
    return map;
  }

  ExportRecordSourcesCompanion toCompanion(bool nullToAbsent) {
    return ExportRecordSourcesCompanion(
      exportId: Value(exportId),
      ordinal: Value(ordinal),
      versionId: Value(versionId),
    );
  }

  factory ExportRecordSourceData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportRecordSourceData(
      exportId: serializer.fromJson<String>(json['exportId']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      versionId: serializer.fromJson<String>(json['versionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exportId': serializer.toJson<String>(exportId),
      'ordinal': serializer.toJson<int>(ordinal),
      'versionId': serializer.toJson<String>(versionId),
    };
  }

  ExportRecordSourceData copyWith({
    String? exportId,
    int? ordinal,
    String? versionId,
  }) => ExportRecordSourceData(
    exportId: exportId ?? this.exportId,
    ordinal: ordinal ?? this.ordinal,
    versionId: versionId ?? this.versionId,
  );
  ExportRecordSourceData copyWithCompanion(ExportRecordSourcesCompanion data) {
    return ExportRecordSourceData(
      exportId: data.exportId.present ? data.exportId.value : this.exportId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      versionId: data.versionId.present ? data.versionId.value : this.versionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportRecordSourceData(')
          ..write('exportId: $exportId, ')
          ..write('ordinal: $ordinal, ')
          ..write('versionId: $versionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exportId, ordinal, versionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportRecordSourceData &&
          other.exportId == this.exportId &&
          other.ordinal == this.ordinal &&
          other.versionId == this.versionId);
}

class ExportRecordSourcesCompanion
    extends UpdateCompanion<ExportRecordSourceData> {
  final Value<String> exportId;
  final Value<int> ordinal;
  final Value<String> versionId;
  final Value<int> rowid;
  const ExportRecordSourcesCompanion({
    this.exportId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.versionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExportRecordSourcesCompanion.insert({
    required String exportId,
    required int ordinal,
    required String versionId,
    this.rowid = const Value.absent(),
  }) : exportId = Value(exportId),
       ordinal = Value(ordinal),
       versionId = Value(versionId);
  static Insertable<ExportRecordSourceData> custom({
    Expression<String>? exportId,
    Expression<int>? ordinal,
    Expression<String>? versionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exportId != null) 'export_id': exportId,
      if (ordinal != null) 'ordinal': ordinal,
      if (versionId != null) 'version_id': versionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExportRecordSourcesCompanion copyWith({
    Value<String>? exportId,
    Value<int>? ordinal,
    Value<String>? versionId,
    Value<int>? rowid,
  }) {
    return ExportRecordSourcesCompanion(
      exportId: exportId ?? this.exportId,
      ordinal: ordinal ?? this.ordinal,
      versionId: versionId ?? this.versionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exportId.present) {
      map['export_id'] = Variable<String>(exportId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (versionId.present) {
      map['version_id'] = Variable<String>(versionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportRecordSourcesCompanion(')
          ..write('exportId: $exportId, ')
          ..write('ordinal: $ordinal, ')
          ..write('versionId: $versionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
    'op_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetKindMeta = const VerificationMeta(
    'targetKind',
  );
  @override
  late final GeneratedColumn<String> targetKind = GeneratedColumn<String>(
    'target_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    check: () =>
        state.isIn(const ['PENDING', 'INFLIGHT', 'DONE', 'FAILED', 'DEAD']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> nextAttemptAt =
      GeneratedColumn<int>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SyncQueueTable.$converternextAttemptAt);
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastErrorAt =
      GeneratedColumn<int>(
        'last_error_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SyncQueueTable.$converterlastErrorAtn);
  static const VerificationMeta _resumeTokenMeta = const VerificationMeta(
    'resumeToken',
  );
  @override
  late final GeneratedColumn<String> resumeToken = GeneratedColumn<String>(
    'resume_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesDoneMeta = const VerificationMeta(
    'bytesDone',
  );
  @override
  late final GeneratedColumn<int> bytesDone = GeneratedColumn<int>(
    'bytes_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bytesTotalMeta = const VerificationMeta(
    'bytesTotal',
  );
  @override
  late final GeneratedColumn<int> bytesTotal = GeneratedColumn<int>(
    'bytes_total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leaseOwnerMeta = const VerificationMeta(
    'leaseOwner',
  );
  @override
  late final GeneratedColumn<String> leaseOwner = GeneratedColumn<String>(
    'lease_owner',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> leaseExpiresAt =
      GeneratedColumn<int>(
        'lease_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SyncQueueTable.$converterleaseExpiresAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SyncQueueTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    opType,
    targetKind,
    targetId,
    idempotencyKey,
    priority,
    state,
    attempts,
    nextAttemptAt,
    lastErrorCode,
    lastErrorAt,
    resumeToken,
    bytesDone,
    bytesTotal,
    leaseOwner,
    leaseExpiresAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('op_type')) {
      context.handle(
        _opTypeMeta,
        opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('target_kind')) {
      context.handle(
        _targetKindMeta,
        targetKind.isAcceptableOrUnknown(data['target_kind']!, _targetKindMeta),
      );
    } else if (isInserting) {
      context.missing(_targetKindMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('resume_token')) {
      context.handle(
        _resumeTokenMeta,
        resumeToken.isAcceptableOrUnknown(
          data['resume_token']!,
          _resumeTokenMeta,
        ),
      );
    }
    if (data.containsKey('bytes_done')) {
      context.handle(
        _bytesDoneMeta,
        bytesDone.isAcceptableOrUnknown(data['bytes_done']!, _bytesDoneMeta),
      );
    }
    if (data.containsKey('bytes_total')) {
      context.handle(
        _bytesTotalMeta,
        bytesTotal.isAcceptableOrUnknown(data['bytes_total']!, _bytesTotalMeta),
      );
    }
    if (data.containsKey('lease_owner')) {
      context.handle(
        _leaseOwnerMeta,
        leaseOwner.isAcceptableOrUnknown(data['lease_owner']!, _leaseOwnerMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {idempotencyKey},
  ];
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      opType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_type'],
      )!,
      targetKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_kind'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: $SyncQueueTable.$converternextAttemptAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}next_attempt_at'],
        )!,
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      lastErrorAt: $SyncQueueTable.$converterlastErrorAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_error_at'],
        ),
      ),
      resumeToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resume_token'],
      ),
      bytesDone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_done'],
      )!,
      bytesTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_total'],
      ),
      leaseOwner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lease_owner'],
      ),
      leaseExpiresAt: $SyncQueueTable.$converterleaseExpiresAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}lease_expires_at'],
        ),
      ),
      createdAt: $SyncQueueTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converternextAttemptAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterlastErrorAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterlastErrorAtn =
      NullAwareTypeConverter.wrap($converterlastErrorAt);
  static TypeConverter<DateTime, int> $converterleaseExpiresAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterleaseExpiresAtn =
      NullAwareTypeConverter.wrap($converterleaseExpiresAt);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String opType;
  final String targetKind;
  final String targetId;
  final String idempotencyKey;
  final int priority;
  final String state;
  final int attempts;
  final DateTime nextAttemptAt;
  final String? lastErrorCode;
  final DateTime? lastErrorAt;
  final String? resumeToken;
  final int bytesDone;
  final int? bytesTotal;
  final String? leaseOwner;
  final DateTime? leaseExpiresAt;
  final DateTime createdAt;
  const SyncQueueData({
    required this.id,
    required this.opType,
    required this.targetKind,
    required this.targetId,
    required this.idempotencyKey,
    required this.priority,
    required this.state,
    required this.attempts,
    required this.nextAttemptAt,
    this.lastErrorCode,
    this.lastErrorAt,
    this.resumeToken,
    required this.bytesDone,
    this.bytesTotal,
    this.leaseOwner,
    this.leaseExpiresAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['op_type'] = Variable<String>(opType);
    map['target_kind'] = Variable<String>(targetKind);
    map['target_id'] = Variable<String>(targetId);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['priority'] = Variable<int>(priority);
    map['state'] = Variable<String>(state);
    map['attempts'] = Variable<int>(attempts);
    {
      map['next_attempt_at'] = Variable<int>(
        $SyncQueueTable.$converternextAttemptAt.toSql(nextAttemptAt),
      );
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    if (!nullToAbsent || lastErrorAt != null) {
      map['last_error_at'] = Variable<int>(
        $SyncQueueTable.$converterlastErrorAtn.toSql(lastErrorAt),
      );
    }
    if (!nullToAbsent || resumeToken != null) {
      map['resume_token'] = Variable<String>(resumeToken);
    }
    map['bytes_done'] = Variable<int>(bytesDone);
    if (!nullToAbsent || bytesTotal != null) {
      map['bytes_total'] = Variable<int>(bytesTotal);
    }
    if (!nullToAbsent || leaseOwner != null) {
      map['lease_owner'] = Variable<String>(leaseOwner);
    }
    if (!nullToAbsent || leaseExpiresAt != null) {
      map['lease_expires_at'] = Variable<int>(
        $SyncQueueTable.$converterleaseExpiresAtn.toSql(leaseExpiresAt),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $SyncQueueTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      opType: Value(opType),
      targetKind: Value(targetKind),
      targetId: Value(targetId),
      idempotencyKey: Value(idempotencyKey),
      priority: Value(priority),
      state: Value(state),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      lastErrorAt: lastErrorAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorAt),
      resumeToken: resumeToken == null && nullToAbsent
          ? const Value.absent()
          : Value(resumeToken),
      bytesDone: Value(bytesDone),
      bytesTotal: bytesTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(bytesTotal),
      leaseOwner: leaseOwner == null && nullToAbsent
          ? const Value.absent()
          : Value(leaseOwner),
      leaseExpiresAt: leaseExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leaseExpiresAt),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      opType: serializer.fromJson<String>(json['opType']),
      targetKind: serializer.fromJson<String>(json['targetKind']),
      targetId: serializer.fromJson<String>(json['targetId']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      priority: serializer.fromJson<int>(json['priority']),
      state: serializer.fromJson<String>(json['state']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      lastErrorAt: serializer.fromJson<DateTime?>(json['lastErrorAt']),
      resumeToken: serializer.fromJson<String?>(json['resumeToken']),
      bytesDone: serializer.fromJson<int>(json['bytesDone']),
      bytesTotal: serializer.fromJson<int?>(json['bytesTotal']),
      leaseOwner: serializer.fromJson<String?>(json['leaseOwner']),
      leaseExpiresAt: serializer.fromJson<DateTime?>(json['leaseExpiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'opType': serializer.toJson<String>(opType),
      'targetKind': serializer.toJson<String>(targetKind),
      'targetId': serializer.toJson<String>(targetId),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'priority': serializer.toJson<int>(priority),
      'state': serializer.toJson<String>(state),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'lastErrorAt': serializer.toJson<DateTime?>(lastErrorAt),
      'resumeToken': serializer.toJson<String?>(resumeToken),
      'bytesDone': serializer.toJson<int>(bytesDone),
      'bytesTotal': serializer.toJson<int?>(bytesTotal),
      'leaseOwner': serializer.toJson<String?>(leaseOwner),
      'leaseExpiresAt': serializer.toJson<DateTime?>(leaseExpiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? opType,
    String? targetKind,
    String? targetId,
    String? idempotencyKey,
    int? priority,
    String? state,
    int? attempts,
    DateTime? nextAttemptAt,
    Value<String?> lastErrorCode = const Value.absent(),
    Value<DateTime?> lastErrorAt = const Value.absent(),
    Value<String?> resumeToken = const Value.absent(),
    int? bytesDone,
    Value<int?> bytesTotal = const Value.absent(),
    Value<String?> leaseOwner = const Value.absent(),
    Value<DateTime?> leaseExpiresAt = const Value.absent(),
    DateTime? createdAt,
  }) => SyncQueueData(
    id: id ?? this.id,
    opType: opType ?? this.opType,
    targetKind: targetKind ?? this.targetKind,
    targetId: targetId ?? this.targetId,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    priority: priority ?? this.priority,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    lastErrorAt: lastErrorAt.present ? lastErrorAt.value : this.lastErrorAt,
    resumeToken: resumeToken.present ? resumeToken.value : this.resumeToken,
    bytesDone: bytesDone ?? this.bytesDone,
    bytesTotal: bytesTotal.present ? bytesTotal.value : this.bytesTotal,
    leaseOwner: leaseOwner.present ? leaseOwner.value : this.leaseOwner,
    leaseExpiresAt: leaseExpiresAt.present
        ? leaseExpiresAt.value
        : this.leaseExpiresAt,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      opType: data.opType.present ? data.opType.value : this.opType,
      targetKind: data.targetKind.present
          ? data.targetKind.value
          : this.targetKind,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      priority: data.priority.present ? data.priority.value : this.priority,
      state: data.state.present ? data.state.value : this.state,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      lastErrorAt: data.lastErrorAt.present
          ? data.lastErrorAt.value
          : this.lastErrorAt,
      resumeToken: data.resumeToken.present
          ? data.resumeToken.value
          : this.resumeToken,
      bytesDone: data.bytesDone.present ? data.bytesDone.value : this.bytesDone,
      bytesTotal: data.bytesTotal.present
          ? data.bytesTotal.value
          : this.bytesTotal,
      leaseOwner: data.leaseOwner.present
          ? data.leaseOwner.value
          : this.leaseOwner,
      leaseExpiresAt: data.leaseExpiresAt.present
          ? data.leaseExpiresAt.value
          : this.leaseExpiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('opType: $opType, ')
          ..write('targetKind: $targetKind, ')
          ..write('targetId: $targetId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('priority: $priority, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorAt: $lastErrorAt, ')
          ..write('resumeToken: $resumeToken, ')
          ..write('bytesDone: $bytesDone, ')
          ..write('bytesTotal: $bytesTotal, ')
          ..write('leaseOwner: $leaseOwner, ')
          ..write('leaseExpiresAt: $leaseExpiresAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    opType,
    targetKind,
    targetId,
    idempotencyKey,
    priority,
    state,
    attempts,
    nextAttemptAt,
    lastErrorCode,
    lastErrorAt,
    resumeToken,
    bytesDone,
    bytesTotal,
    leaseOwner,
    leaseExpiresAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.opType == this.opType &&
          other.targetKind == this.targetKind &&
          other.targetId == this.targetId &&
          other.idempotencyKey == this.idempotencyKey &&
          other.priority == this.priority &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastErrorCode == this.lastErrorCode &&
          other.lastErrorAt == this.lastErrorAt &&
          other.resumeToken == this.resumeToken &&
          other.bytesDone == this.bytesDone &&
          other.bytesTotal == this.bytesTotal &&
          other.leaseOwner == this.leaseOwner &&
          other.leaseExpiresAt == this.leaseExpiresAt &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> opType;
  final Value<String> targetKind;
  final Value<String> targetId;
  final Value<String> idempotencyKey;
  final Value<int> priority;
  final Value<String> state;
  final Value<int> attempts;
  final Value<DateTime> nextAttemptAt;
  final Value<String?> lastErrorCode;
  final Value<DateTime?> lastErrorAt;
  final Value<String?> resumeToken;
  final Value<int> bytesDone;
  final Value<int?> bytesTotal;
  final Value<String?> leaseOwner;
  final Value<DateTime?> leaseExpiresAt;
  final Value<DateTime> createdAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.opType = const Value.absent(),
    this.targetKind = const Value.absent(),
    this.targetId = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.priority = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorAt = const Value.absent(),
    this.resumeToken = const Value.absent(),
    this.bytesDone = const Value.absent(),
    this.bytesTotal = const Value.absent(),
    this.leaseOwner = const Value.absent(),
    this.leaseExpiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String opType,
    required String targetKind,
    required String targetId,
    required String idempotencyKey,
    this.priority = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    required DateTime nextAttemptAt,
    this.lastErrorCode = const Value.absent(),
    this.lastErrorAt = const Value.absent(),
    this.resumeToken = const Value.absent(),
    this.bytesDone = const Value.absent(),
    this.bytesTotal = const Value.absent(),
    this.leaseOwner = const Value.absent(),
    this.leaseExpiresAt = const Value.absent(),
    required DateTime createdAt,
  }) : opType = Value(opType),
       targetKind = Value(targetKind),
       targetId = Value(targetId),
       idempotencyKey = Value(idempotencyKey),
       nextAttemptAt = Value(nextAttemptAt),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? opType,
    Expression<String>? targetKind,
    Expression<String>? targetId,
    Expression<String>? idempotencyKey,
    Expression<int>? priority,
    Expression<String>? state,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAt,
    Expression<String>? lastErrorCode,
    Expression<int>? lastErrorAt,
    Expression<String>? resumeToken,
    Expression<int>? bytesDone,
    Expression<int>? bytesTotal,
    Expression<String>? leaseOwner,
    Expression<int>? leaseExpiresAt,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (opType != null) 'op_type': opType,
      if (targetKind != null) 'target_kind': targetKind,
      if (targetId != null) 'target_id': targetId,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (priority != null) 'priority': priority,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (lastErrorAt != null) 'last_error_at': lastErrorAt,
      if (resumeToken != null) 'resume_token': resumeToken,
      if (bytesDone != null) 'bytes_done': bytesDone,
      if (bytesTotal != null) 'bytes_total': bytesTotal,
      if (leaseOwner != null) 'lease_owner': leaseOwner,
      if (leaseExpiresAt != null) 'lease_expires_at': leaseExpiresAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? opType,
    Value<String>? targetKind,
    Value<String>? targetId,
    Value<String>? idempotencyKey,
    Value<int>? priority,
    Value<String>? state,
    Value<int>? attempts,
    Value<DateTime>? nextAttemptAt,
    Value<String?>? lastErrorCode,
    Value<DateTime?>? lastErrorAt,
    Value<String?>? resumeToken,
    Value<int>? bytesDone,
    Value<int?>? bytesTotal,
    Value<String?>? leaseOwner,
    Value<DateTime?>? leaseExpiresAt,
    Value<DateTime>? createdAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      opType: opType ?? this.opType,
      targetKind: targetKind ?? this.targetKind,
      targetId: targetId ?? this.targetId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      priority: priority ?? this.priority,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorAt: lastErrorAt ?? this.lastErrorAt,
      resumeToken: resumeToken ?? this.resumeToken,
      bytesDone: bytesDone ?? this.bytesDone,
      bytesTotal: bytesTotal ?? this.bytesTotal,
      leaseOwner: leaseOwner ?? this.leaseOwner,
      leaseExpiresAt: leaseExpiresAt ?? this.leaseExpiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (targetKind.present) {
      map['target_kind'] = Variable<String>(targetKind.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(
        $SyncQueueTable.$converternextAttemptAt.toSql(nextAttemptAt.value),
      );
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (lastErrorAt.present) {
      map['last_error_at'] = Variable<int>(
        $SyncQueueTable.$converterlastErrorAtn.toSql(lastErrorAt.value),
      );
    }
    if (resumeToken.present) {
      map['resume_token'] = Variable<String>(resumeToken.value);
    }
    if (bytesDone.present) {
      map['bytes_done'] = Variable<int>(bytesDone.value);
    }
    if (bytesTotal.present) {
      map['bytes_total'] = Variable<int>(bytesTotal.value);
    }
    if (leaseOwner.present) {
      map['lease_owner'] = Variable<String>(leaseOwner.value);
    }
    if (leaseExpiresAt.present) {
      map['lease_expires_at'] = Variable<int>(
        $SyncQueueTable.$converterleaseExpiresAtn.toSql(leaseExpiresAt.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $SyncQueueTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('opType: $opType, ')
          ..write('targetKind: $targetKind, ')
          ..write('targetId: $targetId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('priority: $priority, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorAt: $lastErrorAt, ')
          ..write('resumeToken: $resumeToken, ')
          ..write('bytesDone: $bytesDone, ')
          ..write('bytesTotal: $bytesTotal, ')
          ..write('leaseOwner: $leaseOwner, ')
          ..write('leaseExpiresAt: $leaseExpiresAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CloudObjectsTable extends CloudObjects
    with TableInfo<$CloudObjectsTable, CloudObjectData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CloudObjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _blobIdMeta = const VerificationMeta('blobId');
  @override
  late final GeneratedColumn<String> blobId = GeneratedColumn<String>(
    'blob_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES blobs (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteNameMeta = const VerificationMeta(
    'remoteName',
  );
  @override
  late final GeneratedColumn<String> remoteName = GeneratedColumn<String>(
    'remote_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteSizeMeta = const VerificationMeta(
    'remoteSize',
  );
  @override
  late final GeneratedColumn<int> remoteSize = GeneratedColumn<int>(
    'remote_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteChecksumMeta = const VerificationMeta(
    'remoteChecksum',
  );
  @override
  late final GeneratedColumn<String> remoteChecksum = GeneratedColumn<String>(
    'remote_checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ciphertextSha256Meta = const VerificationMeta(
    'ciphertextSha256',
  );
  @override
  late final GeneratedColumn<Uint8List> ciphertextSha256 =
      GeneratedColumn<Uint8List>(
        'ciphertext_sha256',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _keyEpochMeta = const VerificationMeta(
    'keyEpoch',
  );
  @override
  late final GeneratedColumn<int> keyEpoch = GeneratedColumn<int>(
    'key_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    check: () => state.isIn(const [
      'LOCAL_ONLY',
      'UPLOADING',
      'UPLOADED',
      'REMOTE_ONLY',
      'MISSING',
      'TAMPERED',
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> uploadedAt =
      GeneratedColumn<int>(
        'uploaded_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CloudObjectsTable.$converteruploadedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> verifiedAt =
      GeneratedColumn<int>(
        'verified_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CloudObjectsTable.$converterverifiedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    blobId,
    remoteId,
    remoteName,
    remoteSize,
    remoteChecksum,
    ciphertextSha256,
    keyEpoch,
    state,
    uploadedAt,
    verifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cloud_objects';
  @override
  VerificationContext validateIntegrity(
    Insertable<CloudObjectData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('blob_id')) {
      context.handle(
        _blobIdMeta,
        blobId.isAcceptableOrUnknown(data['blob_id']!, _blobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_blobIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('remote_name')) {
      context.handle(
        _remoteNameMeta,
        remoteName.isAcceptableOrUnknown(data['remote_name']!, _remoteNameMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteNameMeta);
    }
    if (data.containsKey('remote_size')) {
      context.handle(
        _remoteSizeMeta,
        remoteSize.isAcceptableOrUnknown(data['remote_size']!, _remoteSizeMeta),
      );
    }
    if (data.containsKey('remote_checksum')) {
      context.handle(
        _remoteChecksumMeta,
        remoteChecksum.isAcceptableOrUnknown(
          data['remote_checksum']!,
          _remoteChecksumMeta,
        ),
      );
    }
    if (data.containsKey('ciphertext_sha256')) {
      context.handle(
        _ciphertextSha256Meta,
        ciphertextSha256.isAcceptableOrUnknown(
          data['ciphertext_sha256']!,
          _ciphertextSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ciphertextSha256Meta);
    }
    if (data.containsKey('key_epoch')) {
      context.handle(
        _keyEpochMeta,
        keyEpoch.isAcceptableOrUnknown(data['key_epoch']!, _keyEpochMeta),
      );
    } else if (isInserting) {
      context.missing(_keyEpochMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {blobId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {remoteName},
  ];
  @override
  CloudObjectData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CloudObjectData(
      blobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blob_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      remoteName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_name'],
      )!,
      remoteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_size'],
      ),
      remoteChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_checksum'],
      ),
      ciphertextSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}ciphertext_sha256'],
      )!,
      keyEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}key_epoch'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      uploadedAt: $CloudObjectsTable.$converteruploadedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}uploaded_at'],
        ),
      ),
      verifiedAt: $CloudObjectsTable.$converterverifiedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}verified_at'],
        ),
      ),
    );
  }

  @override
  $CloudObjectsTable createAlias(String alias) {
    return $CloudObjectsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converteruploadedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converteruploadedAtn =
      NullAwareTypeConverter.wrap($converteruploadedAt);
  static TypeConverter<DateTime, int> $converterverifiedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterverifiedAtn =
      NullAwareTypeConverter.wrap($converterverifiedAt);
}

class CloudObjectData extends DataClass implements Insertable<CloudObjectData> {
  final String blobId;
  final String? remoteId;
  final String remoteName;
  final int? remoteSize;
  final String? remoteChecksum;
  final Uint8List ciphertextSha256;
  final int keyEpoch;
  final String state;
  final DateTime? uploadedAt;
  final DateTime? verifiedAt;
  const CloudObjectData({
    required this.blobId,
    this.remoteId,
    required this.remoteName,
    this.remoteSize,
    this.remoteChecksum,
    required this.ciphertextSha256,
    required this.keyEpoch,
    required this.state,
    this.uploadedAt,
    this.verifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['blob_id'] = Variable<String>(blobId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['remote_name'] = Variable<String>(remoteName);
    if (!nullToAbsent || remoteSize != null) {
      map['remote_size'] = Variable<int>(remoteSize);
    }
    if (!nullToAbsent || remoteChecksum != null) {
      map['remote_checksum'] = Variable<String>(remoteChecksum);
    }
    map['ciphertext_sha256'] = Variable<Uint8List>(ciphertextSha256);
    map['key_epoch'] = Variable<int>(keyEpoch);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || uploadedAt != null) {
      map['uploaded_at'] = Variable<int>(
        $CloudObjectsTable.$converteruploadedAtn.toSql(uploadedAt),
      );
    }
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<int>(
        $CloudObjectsTable.$converterverifiedAtn.toSql(verifiedAt),
      );
    }
    return map;
  }

  CloudObjectsCompanion toCompanion(bool nullToAbsent) {
    return CloudObjectsCompanion(
      blobId: Value(blobId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      remoteName: Value(remoteName),
      remoteSize: remoteSize == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteSize),
      remoteChecksum: remoteChecksum == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteChecksum),
      ciphertextSha256: Value(ciphertextSha256),
      keyEpoch: Value(keyEpoch),
      state: Value(state),
      uploadedAt: uploadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadedAt),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
    );
  }

  factory CloudObjectData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CloudObjectData(
      blobId: serializer.fromJson<String>(json['blobId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      remoteName: serializer.fromJson<String>(json['remoteName']),
      remoteSize: serializer.fromJson<int?>(json['remoteSize']),
      remoteChecksum: serializer.fromJson<String?>(json['remoteChecksum']),
      ciphertextSha256: serializer.fromJson<Uint8List>(
        json['ciphertextSha256'],
      ),
      keyEpoch: serializer.fromJson<int>(json['keyEpoch']),
      state: serializer.fromJson<String>(json['state']),
      uploadedAt: serializer.fromJson<DateTime?>(json['uploadedAt']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'blobId': serializer.toJson<String>(blobId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'remoteName': serializer.toJson<String>(remoteName),
      'remoteSize': serializer.toJson<int?>(remoteSize),
      'remoteChecksum': serializer.toJson<String?>(remoteChecksum),
      'ciphertextSha256': serializer.toJson<Uint8List>(ciphertextSha256),
      'keyEpoch': serializer.toJson<int>(keyEpoch),
      'state': serializer.toJson<String>(state),
      'uploadedAt': serializer.toJson<DateTime?>(uploadedAt),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
    };
  }

  CloudObjectData copyWith({
    String? blobId,
    Value<String?> remoteId = const Value.absent(),
    String? remoteName,
    Value<int?> remoteSize = const Value.absent(),
    Value<String?> remoteChecksum = const Value.absent(),
    Uint8List? ciphertextSha256,
    int? keyEpoch,
    String? state,
    Value<DateTime?> uploadedAt = const Value.absent(),
    Value<DateTime?> verifiedAt = const Value.absent(),
  }) => CloudObjectData(
    blobId: blobId ?? this.blobId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    remoteName: remoteName ?? this.remoteName,
    remoteSize: remoteSize.present ? remoteSize.value : this.remoteSize,
    remoteChecksum: remoteChecksum.present
        ? remoteChecksum.value
        : this.remoteChecksum,
    ciphertextSha256: ciphertextSha256 ?? this.ciphertextSha256,
    keyEpoch: keyEpoch ?? this.keyEpoch,
    state: state ?? this.state,
    uploadedAt: uploadedAt.present ? uploadedAt.value : this.uploadedAt,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
  );
  CloudObjectData copyWithCompanion(CloudObjectsCompanion data) {
    return CloudObjectData(
      blobId: data.blobId.present ? data.blobId.value : this.blobId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      remoteName: data.remoteName.present
          ? data.remoteName.value
          : this.remoteName,
      remoteSize: data.remoteSize.present
          ? data.remoteSize.value
          : this.remoteSize,
      remoteChecksum: data.remoteChecksum.present
          ? data.remoteChecksum.value
          : this.remoteChecksum,
      ciphertextSha256: data.ciphertextSha256.present
          ? data.ciphertextSha256.value
          : this.ciphertextSha256,
      keyEpoch: data.keyEpoch.present ? data.keyEpoch.value : this.keyEpoch,
      state: data.state.present ? data.state.value : this.state,
      uploadedAt: data.uploadedAt.present
          ? data.uploadedAt.value
          : this.uploadedAt,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CloudObjectData(')
          ..write('blobId: $blobId, ')
          ..write('remoteId: $remoteId, ')
          ..write('remoteName: $remoteName, ')
          ..write('remoteSize: $remoteSize, ')
          ..write('remoteChecksum: $remoteChecksum, ')
          ..write('ciphertextSha256: $ciphertextSha256, ')
          ..write('keyEpoch: $keyEpoch, ')
          ..write('state: $state, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('verifiedAt: $verifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    blobId,
    remoteId,
    remoteName,
    remoteSize,
    remoteChecksum,
    $driftBlobEquality.hash(ciphertextSha256),
    keyEpoch,
    state,
    uploadedAt,
    verifiedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CloudObjectData &&
          other.blobId == this.blobId &&
          other.remoteId == this.remoteId &&
          other.remoteName == this.remoteName &&
          other.remoteSize == this.remoteSize &&
          other.remoteChecksum == this.remoteChecksum &&
          $driftBlobEquality.equals(
            other.ciphertextSha256,
            this.ciphertextSha256,
          ) &&
          other.keyEpoch == this.keyEpoch &&
          other.state == this.state &&
          other.uploadedAt == this.uploadedAt &&
          other.verifiedAt == this.verifiedAt);
}

class CloudObjectsCompanion extends UpdateCompanion<CloudObjectData> {
  final Value<String> blobId;
  final Value<String?> remoteId;
  final Value<String> remoteName;
  final Value<int?> remoteSize;
  final Value<String?> remoteChecksum;
  final Value<Uint8List> ciphertextSha256;
  final Value<int> keyEpoch;
  final Value<String> state;
  final Value<DateTime?> uploadedAt;
  final Value<DateTime?> verifiedAt;
  final Value<int> rowid;
  const CloudObjectsCompanion({
    this.blobId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.remoteName = const Value.absent(),
    this.remoteSize = const Value.absent(),
    this.remoteChecksum = const Value.absent(),
    this.ciphertextSha256 = const Value.absent(),
    this.keyEpoch = const Value.absent(),
    this.state = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CloudObjectsCompanion.insert({
    required String blobId,
    this.remoteId = const Value.absent(),
    required String remoteName,
    this.remoteSize = const Value.absent(),
    this.remoteChecksum = const Value.absent(),
    required Uint8List ciphertextSha256,
    required int keyEpoch,
    required String state,
    this.uploadedAt = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : blobId = Value(blobId),
       remoteName = Value(remoteName),
       ciphertextSha256 = Value(ciphertextSha256),
       keyEpoch = Value(keyEpoch),
       state = Value(state);
  static Insertable<CloudObjectData> custom({
    Expression<String>? blobId,
    Expression<String>? remoteId,
    Expression<String>? remoteName,
    Expression<int>? remoteSize,
    Expression<String>? remoteChecksum,
    Expression<Uint8List>? ciphertextSha256,
    Expression<int>? keyEpoch,
    Expression<String>? state,
    Expression<int>? uploadedAt,
    Expression<int>? verifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (blobId != null) 'blob_id': blobId,
      if (remoteId != null) 'remote_id': remoteId,
      if (remoteName != null) 'remote_name': remoteName,
      if (remoteSize != null) 'remote_size': remoteSize,
      if (remoteChecksum != null) 'remote_checksum': remoteChecksum,
      if (ciphertextSha256 != null) 'ciphertext_sha256': ciphertextSha256,
      if (keyEpoch != null) 'key_epoch': keyEpoch,
      if (state != null) 'state': state,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CloudObjectsCompanion copyWith({
    Value<String>? blobId,
    Value<String?>? remoteId,
    Value<String>? remoteName,
    Value<int?>? remoteSize,
    Value<String?>? remoteChecksum,
    Value<Uint8List>? ciphertextSha256,
    Value<int>? keyEpoch,
    Value<String>? state,
    Value<DateTime?>? uploadedAt,
    Value<DateTime?>? verifiedAt,
    Value<int>? rowid,
  }) {
    return CloudObjectsCompanion(
      blobId: blobId ?? this.blobId,
      remoteId: remoteId ?? this.remoteId,
      remoteName: remoteName ?? this.remoteName,
      remoteSize: remoteSize ?? this.remoteSize,
      remoteChecksum: remoteChecksum ?? this.remoteChecksum,
      ciphertextSha256: ciphertextSha256 ?? this.ciphertextSha256,
      keyEpoch: keyEpoch ?? this.keyEpoch,
      state: state ?? this.state,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (blobId.present) {
      map['blob_id'] = Variable<String>(blobId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (remoteName.present) {
      map['remote_name'] = Variable<String>(remoteName.value);
    }
    if (remoteSize.present) {
      map['remote_size'] = Variable<int>(remoteSize.value);
    }
    if (remoteChecksum.present) {
      map['remote_checksum'] = Variable<String>(remoteChecksum.value);
    }
    if (ciphertextSha256.present) {
      map['ciphertext_sha256'] = Variable<Uint8List>(ciphertextSha256.value);
    }
    if (keyEpoch.present) {
      map['key_epoch'] = Variable<int>(keyEpoch.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (uploadedAt.present) {
      map['uploaded_at'] = Variable<int>(
        $CloudObjectsTable.$converteruploadedAtn.toSql(uploadedAt.value),
      );
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<int>(
        $CloudObjectsTable.$converterverifiedAtn.toSql(verifiedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CloudObjectsCompanion(')
          ..write('blobId: $blobId, ')
          ..write('remoteId: $remoteId, ')
          ..write('remoteName: $remoteName, ')
          ..write('remoteSize: $remoteSize, ')
          ..write('remoteChecksum: $remoteChecksum, ')
          ..write('ciphertextSha256: $ciphertextSha256, ')
          ..write('keyEpoch: $keyEpoch, ')
          ..write('state: $state, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncLogSegmentsTable extends SyncLogSegments
    with TableInfo<$SyncLogSegmentsTable, SyncLogSegmentData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteNameMeta = const VerificationMeta(
    'remoteName',
  );
  @override
  late final GeneratedColumn<String> remoteName = GeneratedColumn<String>(
    'remote_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blobIdMeta = const VerificationMeta('blobId');
  @override
  late final GeneratedColumn<String> blobId = GeneratedColumn<String>(
    'blob_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES blobs (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _opCountMeta = const VerificationMeta(
    'opCount',
  );
  @override
  late final GeneratedColumn<int> opCount = GeneratedColumn<int>(
    'op_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hlcLowMeta = const VerificationMeta('hlcLow');
  @override
  late final GeneratedColumn<String> hlcLow = GeneratedColumn<String>(
    'hlc_low',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hlcHighMeta = const VerificationMeta(
    'hlcHigh',
  );
  @override
  late final GeneratedColumn<String> hlcHigh = GeneratedColumn<String>(
    'hlc_high',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> sealedAt =
      GeneratedColumn<int>(
        'sealed_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SyncLogSegmentsTable.$convertersealedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> uploadedAt =
      GeneratedColumn<int>(
        'uploaded_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SyncLogSegmentsTable.$converteruploadedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> appliedAt =
      GeneratedColumn<int>(
        'applied_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SyncLogSegmentsTable.$converterappliedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    seq,
    remoteId,
    remoteName,
    blobId,
    opCount,
    hlcLow,
    hlcHigh,
    sealedAt,
    uploadedAt,
    appliedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_log_segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncLogSegmentData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('remote_name')) {
      context.handle(
        _remoteNameMeta,
        remoteName.isAcceptableOrUnknown(data['remote_name']!, _remoteNameMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteNameMeta);
    }
    if (data.containsKey('blob_id')) {
      context.handle(
        _blobIdMeta,
        blobId.isAcceptableOrUnknown(data['blob_id']!, _blobIdMeta),
      );
    }
    if (data.containsKey('op_count')) {
      context.handle(
        _opCountMeta,
        opCount.isAcceptableOrUnknown(data['op_count']!, _opCountMeta),
      );
    }
    if (data.containsKey('hlc_low')) {
      context.handle(
        _hlcLowMeta,
        hlcLow.isAcceptableOrUnknown(data['hlc_low']!, _hlcLowMeta),
      );
    }
    if (data.containsKey('hlc_high')) {
      context.handle(
        _hlcHighMeta,
        hlcHigh.isAcceptableOrUnknown(data['hlc_high']!, _hlcHighMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, seq};
  @override
  SyncLogSegmentData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLogSegmentData(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      remoteName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_name'],
      )!,
      blobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blob_id'],
      ),
      opCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}op_count'],
      )!,
      hlcLow: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc_low'],
      ),
      hlcHigh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc_high'],
      ),
      sealedAt: $SyncLogSegmentsTable.$convertersealedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sealed_at'],
        ),
      ),
      uploadedAt: $SyncLogSegmentsTable.$converteruploadedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}uploaded_at'],
        ),
      ),
      appliedAt: $SyncLogSegmentsTable.$converterappliedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}applied_at'],
        ),
      ),
    );
  }

  @override
  $SyncLogSegmentsTable createAlias(String alias) {
    return $SyncLogSegmentsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertersealedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $convertersealedAtn =
      NullAwareTypeConverter.wrap($convertersealedAt);
  static TypeConverter<DateTime, int> $converteruploadedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converteruploadedAtn =
      NullAwareTypeConverter.wrap($converteruploadedAt);
  static TypeConverter<DateTime, int> $converterappliedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterappliedAtn =
      NullAwareTypeConverter.wrap($converterappliedAt);
}

class SyncLogSegmentData extends DataClass
    implements Insertable<SyncLogSegmentData> {
  final String deviceId;
  final int seq;
  final String? remoteId;
  final String remoteName;
  final String? blobId;
  final int opCount;
  final String? hlcLow;
  final String? hlcHigh;
  final DateTime? sealedAt;
  final DateTime? uploadedAt;
  final DateTime? appliedAt;
  const SyncLogSegmentData({
    required this.deviceId,
    required this.seq,
    this.remoteId,
    required this.remoteName,
    this.blobId,
    required this.opCount,
    this.hlcLow,
    this.hlcHigh,
    this.sealedAt,
    this.uploadedAt,
    this.appliedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['seq'] = Variable<int>(seq);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['remote_name'] = Variable<String>(remoteName);
    if (!nullToAbsent || blobId != null) {
      map['blob_id'] = Variable<String>(blobId);
    }
    map['op_count'] = Variable<int>(opCount);
    if (!nullToAbsent || hlcLow != null) {
      map['hlc_low'] = Variable<String>(hlcLow);
    }
    if (!nullToAbsent || hlcHigh != null) {
      map['hlc_high'] = Variable<String>(hlcHigh);
    }
    if (!nullToAbsent || sealedAt != null) {
      map['sealed_at'] = Variable<int>(
        $SyncLogSegmentsTable.$convertersealedAtn.toSql(sealedAt),
      );
    }
    if (!nullToAbsent || uploadedAt != null) {
      map['uploaded_at'] = Variable<int>(
        $SyncLogSegmentsTable.$converteruploadedAtn.toSql(uploadedAt),
      );
    }
    if (!nullToAbsent || appliedAt != null) {
      map['applied_at'] = Variable<int>(
        $SyncLogSegmentsTable.$converterappliedAtn.toSql(appliedAt),
      );
    }
    return map;
  }

  SyncLogSegmentsCompanion toCompanion(bool nullToAbsent) {
    return SyncLogSegmentsCompanion(
      deviceId: Value(deviceId),
      seq: Value(seq),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      remoteName: Value(remoteName),
      blobId: blobId == null && nullToAbsent
          ? const Value.absent()
          : Value(blobId),
      opCount: Value(opCount),
      hlcLow: hlcLow == null && nullToAbsent
          ? const Value.absent()
          : Value(hlcLow),
      hlcHigh: hlcHigh == null && nullToAbsent
          ? const Value.absent()
          : Value(hlcHigh),
      sealedAt: sealedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sealedAt),
      uploadedAt: uploadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadedAt),
      appliedAt: appliedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedAt),
    );
  }

  factory SyncLogSegmentData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLogSegmentData(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      seq: serializer.fromJson<int>(json['seq']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      remoteName: serializer.fromJson<String>(json['remoteName']),
      blobId: serializer.fromJson<String?>(json['blobId']),
      opCount: serializer.fromJson<int>(json['opCount']),
      hlcLow: serializer.fromJson<String?>(json['hlcLow']),
      hlcHigh: serializer.fromJson<String?>(json['hlcHigh']),
      sealedAt: serializer.fromJson<DateTime?>(json['sealedAt']),
      uploadedAt: serializer.fromJson<DateTime?>(json['uploadedAt']),
      appliedAt: serializer.fromJson<DateTime?>(json['appliedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'seq': serializer.toJson<int>(seq),
      'remoteId': serializer.toJson<String?>(remoteId),
      'remoteName': serializer.toJson<String>(remoteName),
      'blobId': serializer.toJson<String?>(blobId),
      'opCount': serializer.toJson<int>(opCount),
      'hlcLow': serializer.toJson<String?>(hlcLow),
      'hlcHigh': serializer.toJson<String?>(hlcHigh),
      'sealedAt': serializer.toJson<DateTime?>(sealedAt),
      'uploadedAt': serializer.toJson<DateTime?>(uploadedAt),
      'appliedAt': serializer.toJson<DateTime?>(appliedAt),
    };
  }

  SyncLogSegmentData copyWith({
    String? deviceId,
    int? seq,
    Value<String?> remoteId = const Value.absent(),
    String? remoteName,
    Value<String?> blobId = const Value.absent(),
    int? opCount,
    Value<String?> hlcLow = const Value.absent(),
    Value<String?> hlcHigh = const Value.absent(),
    Value<DateTime?> sealedAt = const Value.absent(),
    Value<DateTime?> uploadedAt = const Value.absent(),
    Value<DateTime?> appliedAt = const Value.absent(),
  }) => SyncLogSegmentData(
    deviceId: deviceId ?? this.deviceId,
    seq: seq ?? this.seq,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    remoteName: remoteName ?? this.remoteName,
    blobId: blobId.present ? blobId.value : this.blobId,
    opCount: opCount ?? this.opCount,
    hlcLow: hlcLow.present ? hlcLow.value : this.hlcLow,
    hlcHigh: hlcHigh.present ? hlcHigh.value : this.hlcHigh,
    sealedAt: sealedAt.present ? sealedAt.value : this.sealedAt,
    uploadedAt: uploadedAt.present ? uploadedAt.value : this.uploadedAt,
    appliedAt: appliedAt.present ? appliedAt.value : this.appliedAt,
  );
  SyncLogSegmentData copyWithCompanion(SyncLogSegmentsCompanion data) {
    return SyncLogSegmentData(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      seq: data.seq.present ? data.seq.value : this.seq,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      remoteName: data.remoteName.present
          ? data.remoteName.value
          : this.remoteName,
      blobId: data.blobId.present ? data.blobId.value : this.blobId,
      opCount: data.opCount.present ? data.opCount.value : this.opCount,
      hlcLow: data.hlcLow.present ? data.hlcLow.value : this.hlcLow,
      hlcHigh: data.hlcHigh.present ? data.hlcHigh.value : this.hlcHigh,
      sealedAt: data.sealedAt.present ? data.sealedAt.value : this.sealedAt,
      uploadedAt: data.uploadedAt.present
          ? data.uploadedAt.value
          : this.uploadedAt,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogSegmentData(')
          ..write('deviceId: $deviceId, ')
          ..write('seq: $seq, ')
          ..write('remoteId: $remoteId, ')
          ..write('remoteName: $remoteName, ')
          ..write('blobId: $blobId, ')
          ..write('opCount: $opCount, ')
          ..write('hlcLow: $hlcLow, ')
          ..write('hlcHigh: $hlcHigh, ')
          ..write('sealedAt: $sealedAt, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    seq,
    remoteId,
    remoteName,
    blobId,
    opCount,
    hlcLow,
    hlcHigh,
    sealedAt,
    uploadedAt,
    appliedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLogSegmentData &&
          other.deviceId == this.deviceId &&
          other.seq == this.seq &&
          other.remoteId == this.remoteId &&
          other.remoteName == this.remoteName &&
          other.blobId == this.blobId &&
          other.opCount == this.opCount &&
          other.hlcLow == this.hlcLow &&
          other.hlcHigh == this.hlcHigh &&
          other.sealedAt == this.sealedAt &&
          other.uploadedAt == this.uploadedAt &&
          other.appliedAt == this.appliedAt);
}

class SyncLogSegmentsCompanion extends UpdateCompanion<SyncLogSegmentData> {
  final Value<String> deviceId;
  final Value<int> seq;
  final Value<String?> remoteId;
  final Value<String> remoteName;
  final Value<String?> blobId;
  final Value<int> opCount;
  final Value<String?> hlcLow;
  final Value<String?> hlcHigh;
  final Value<DateTime?> sealedAt;
  final Value<DateTime?> uploadedAt;
  final Value<DateTime?> appliedAt;
  final Value<int> rowid;
  const SyncLogSegmentsCompanion({
    this.deviceId = const Value.absent(),
    this.seq = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.remoteName = const Value.absent(),
    this.blobId = const Value.absent(),
    this.opCount = const Value.absent(),
    this.hlcLow = const Value.absent(),
    this.hlcHigh = const Value.absent(),
    this.sealedAt = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncLogSegmentsCompanion.insert({
    required String deviceId,
    required int seq,
    this.remoteId = const Value.absent(),
    required String remoteName,
    this.blobId = const Value.absent(),
    this.opCount = const Value.absent(),
    this.hlcLow = const Value.absent(),
    this.hlcHigh = const Value.absent(),
    this.sealedAt = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       seq = Value(seq),
       remoteName = Value(remoteName);
  static Insertable<SyncLogSegmentData> custom({
    Expression<String>? deviceId,
    Expression<int>? seq,
    Expression<String>? remoteId,
    Expression<String>? remoteName,
    Expression<String>? blobId,
    Expression<int>? opCount,
    Expression<String>? hlcLow,
    Expression<String>? hlcHigh,
    Expression<int>? sealedAt,
    Expression<int>? uploadedAt,
    Expression<int>? appliedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (seq != null) 'seq': seq,
      if (remoteId != null) 'remote_id': remoteId,
      if (remoteName != null) 'remote_name': remoteName,
      if (blobId != null) 'blob_id': blobId,
      if (opCount != null) 'op_count': opCount,
      if (hlcLow != null) 'hlc_low': hlcLow,
      if (hlcHigh != null) 'hlc_high': hlcHigh,
      if (sealedAt != null) 'sealed_at': sealedAt,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncLogSegmentsCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? seq,
    Value<String?>? remoteId,
    Value<String>? remoteName,
    Value<String?>? blobId,
    Value<int>? opCount,
    Value<String?>? hlcLow,
    Value<String?>? hlcHigh,
    Value<DateTime?>? sealedAt,
    Value<DateTime?>? uploadedAt,
    Value<DateTime?>? appliedAt,
    Value<int>? rowid,
  }) {
    return SyncLogSegmentsCompanion(
      deviceId: deviceId ?? this.deviceId,
      seq: seq ?? this.seq,
      remoteId: remoteId ?? this.remoteId,
      remoteName: remoteName ?? this.remoteName,
      blobId: blobId ?? this.blobId,
      opCount: opCount ?? this.opCount,
      hlcLow: hlcLow ?? this.hlcLow,
      hlcHigh: hlcHigh ?? this.hlcHigh,
      sealedAt: sealedAt ?? this.sealedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      appliedAt: appliedAt ?? this.appliedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (remoteName.present) {
      map['remote_name'] = Variable<String>(remoteName.value);
    }
    if (blobId.present) {
      map['blob_id'] = Variable<String>(blobId.value);
    }
    if (opCount.present) {
      map['op_count'] = Variable<int>(opCount.value);
    }
    if (hlcLow.present) {
      map['hlc_low'] = Variable<String>(hlcLow.value);
    }
    if (hlcHigh.present) {
      map['hlc_high'] = Variable<String>(hlcHigh.value);
    }
    if (sealedAt.present) {
      map['sealed_at'] = Variable<int>(
        $SyncLogSegmentsTable.$convertersealedAtn.toSql(sealedAt.value),
      );
    }
    if (uploadedAt.present) {
      map['uploaded_at'] = Variable<int>(
        $SyncLogSegmentsTable.$converteruploadedAtn.toSql(uploadedAt.value),
      );
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<int>(
        $SyncLogSegmentsTable.$converterappliedAtn.toSql(appliedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogSegmentsCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('seq: $seq, ')
          ..write('remoteId: $remoteId, ')
          ..write('remoteName: $remoteName, ')
          ..write('blobId: $blobId, ')
          ..write('opCount: $opCount, ')
          ..write('hlcLow: $hlcLow, ')
          ..write('hlcHigh: $hlcHigh, ')
          ..write('sealedAt: $sealedAt, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncLogOpsTable extends SyncLogOps
    with TableInfo<$SyncLogOpsTable, SyncLogOpData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogOpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opJsonMeta = const VerificationMeta('opJson');
  @override
  late final GeneratedColumn<String> opJson = GeneratedColumn<String>(
    'op_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, deviceId, opJson, hlc, seq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_log_ops';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncLogOpData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('op_json')) {
      context.handle(
        _opJsonMeta,
        opJson.isAcceptableOrUnknown(data['op_json']!, _opJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_opJsonMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLogOpData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLogOpData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      opJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_json'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
    );
  }

  @override
  $SyncLogOpsTable createAlias(String alias) {
    return $SyncLogOpsTable(attachedDatabase, alias);
  }
}

class SyncLogOpData extends DataClass implements Insertable<SyncLogOpData> {
  final int id;
  final String deviceId;
  final String opJson;
  final String hlc;
  final int seq;
  const SyncLogOpData({
    required this.id,
    required this.deviceId,
    required this.opJson,
    required this.hlc,
    required this.seq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['op_json'] = Variable<String>(opJson);
    map['hlc'] = Variable<String>(hlc);
    map['seq'] = Variable<int>(seq);
    return map;
  }

  SyncLogOpsCompanion toCompanion(bool nullToAbsent) {
    return SyncLogOpsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      opJson: Value(opJson),
      hlc: Value(hlc),
      seq: Value(seq),
    );
  }

  factory SyncLogOpData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLogOpData(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      opJson: serializer.fromJson<String>(json['opJson']),
      hlc: serializer.fromJson<String>(json['hlc']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'opJson': serializer.toJson<String>(opJson),
      'hlc': serializer.toJson<String>(hlc),
      'seq': serializer.toJson<int>(seq),
    };
  }

  SyncLogOpData copyWith({
    int? id,
    String? deviceId,
    String? opJson,
    String? hlc,
    int? seq,
  }) => SyncLogOpData(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    opJson: opJson ?? this.opJson,
    hlc: hlc ?? this.hlc,
    seq: seq ?? this.seq,
  );
  SyncLogOpData copyWithCompanion(SyncLogOpsCompanion data) {
    return SyncLogOpData(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      opJson: data.opJson.present ? data.opJson.value : this.opJson,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogOpData(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('opJson: $opJson, ')
          ..write('hlc: $hlc, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deviceId, opJson, hlc, seq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLogOpData &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.opJson == this.opJson &&
          other.hlc == this.hlc &&
          other.seq == this.seq);
}

class SyncLogOpsCompanion extends UpdateCompanion<SyncLogOpData> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String> opJson;
  final Value<String> hlc;
  final Value<int> seq;
  const SyncLogOpsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.opJson = const Value.absent(),
    this.hlc = const Value.absent(),
    this.seq = const Value.absent(),
  });
  SyncLogOpsCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    required String opJson,
    required String hlc,
    required int seq,
  }) : deviceId = Value(deviceId),
       opJson = Value(opJson),
       hlc = Value(hlc),
       seq = Value(seq);
  static Insertable<SyncLogOpData> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? opJson,
    Expression<String>? hlc,
    Expression<int>? seq,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (opJson != null) 'op_json': opJson,
      if (hlc != null) 'hlc': hlc,
      if (seq != null) 'seq': seq,
    });
  }

  SyncLogOpsCompanion copyWith({
    Value<int>? id,
    Value<String>? deviceId,
    Value<String>? opJson,
    Value<String>? hlc,
    Value<int>? seq,
  }) {
    return SyncLogOpsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      opJson: opJson ?? this.opJson,
      hlc: hlc ?? this.hlc,
      seq: seq ?? this.seq,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (opJson.present) {
      map['op_json'] = Variable<String>(opJson.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogOpsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('opJson: $opJson, ')
          ..write('hlc: $hlc, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorTable extends SyncCursor
    with TableInfo<$SyncCursorTable, SyncCursorData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _lastAppliedSeqMeta = const VerificationMeta(
    'lastAppliedSeq',
  );
  @override
  late final GeneratedColumn<int> lastAppliedSeq = GeneratedColumn<int>(
    'last_applied_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAppliedHlcMeta = const VerificationMeta(
    'lastAppliedHlc',
  );
  @override
  late final GeneratedColumn<String> lastAppliedHlc = GeneratedColumn<String>(
    'last_applied_hlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    lastAppliedSeq,
    lastAppliedHlc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursor';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursorData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('last_applied_seq')) {
      context.handle(
        _lastAppliedSeqMeta,
        lastAppliedSeq.isAcceptableOrUnknown(
          data['last_applied_seq']!,
          _lastAppliedSeqMeta,
        ),
      );
    }
    if (data.containsKey('last_applied_hlc')) {
      context.handle(
        _lastAppliedHlcMeta,
        lastAppliedHlc.isAcceptableOrUnknown(
          data['last_applied_hlc']!,
          _lastAppliedHlcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  SyncCursorData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorData(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      lastAppliedSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_applied_seq'],
      )!,
      lastAppliedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_applied_hlc'],
      ),
    );
  }

  @override
  $SyncCursorTable createAlias(String alias) {
    return $SyncCursorTable(attachedDatabase, alias);
  }
}

class SyncCursorData extends DataClass implements Insertable<SyncCursorData> {
  final String deviceId;
  final int lastAppliedSeq;
  final String? lastAppliedHlc;
  const SyncCursorData({
    required this.deviceId,
    required this.lastAppliedSeq,
    this.lastAppliedHlc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['last_applied_seq'] = Variable<int>(lastAppliedSeq);
    if (!nullToAbsent || lastAppliedHlc != null) {
      map['last_applied_hlc'] = Variable<String>(lastAppliedHlc);
    }
    return map;
  }

  SyncCursorCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorCompanion(
      deviceId: Value(deviceId),
      lastAppliedSeq: Value(lastAppliedSeq),
      lastAppliedHlc: lastAppliedHlc == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAppliedHlc),
    );
  }

  factory SyncCursorData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorData(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      lastAppliedSeq: serializer.fromJson<int>(json['lastAppliedSeq']),
      lastAppliedHlc: serializer.fromJson<String?>(json['lastAppliedHlc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'lastAppliedSeq': serializer.toJson<int>(lastAppliedSeq),
      'lastAppliedHlc': serializer.toJson<String?>(lastAppliedHlc),
    };
  }

  SyncCursorData copyWith({
    String? deviceId,
    int? lastAppliedSeq,
    Value<String?> lastAppliedHlc = const Value.absent(),
  }) => SyncCursorData(
    deviceId: deviceId ?? this.deviceId,
    lastAppliedSeq: lastAppliedSeq ?? this.lastAppliedSeq,
    lastAppliedHlc: lastAppliedHlc.present
        ? lastAppliedHlc.value
        : this.lastAppliedHlc,
  );
  SyncCursorData copyWithCompanion(SyncCursorCompanion data) {
    return SyncCursorData(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      lastAppliedSeq: data.lastAppliedSeq.present
          ? data.lastAppliedSeq.value
          : this.lastAppliedSeq,
      lastAppliedHlc: data.lastAppliedHlc.present
          ? data.lastAppliedHlc.value
          : this.lastAppliedHlc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorData(')
          ..write('deviceId: $deviceId, ')
          ..write('lastAppliedSeq: $lastAppliedSeq, ')
          ..write('lastAppliedHlc: $lastAppliedHlc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, lastAppliedSeq, lastAppliedHlc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorData &&
          other.deviceId == this.deviceId &&
          other.lastAppliedSeq == this.lastAppliedSeq &&
          other.lastAppliedHlc == this.lastAppliedHlc);
}

class SyncCursorCompanion extends UpdateCompanion<SyncCursorData> {
  final Value<String> deviceId;
  final Value<int> lastAppliedSeq;
  final Value<String?> lastAppliedHlc;
  final Value<int> rowid;
  const SyncCursorCompanion({
    this.deviceId = const Value.absent(),
    this.lastAppliedSeq = const Value.absent(),
    this.lastAppliedHlc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorCompanion.insert({
    required String deviceId,
    this.lastAppliedSeq = const Value.absent(),
    this.lastAppliedHlc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId);
  static Insertable<SyncCursorData> custom({
    Expression<String>? deviceId,
    Expression<int>? lastAppliedSeq,
    Expression<String>? lastAppliedHlc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (lastAppliedSeq != null) 'last_applied_seq': lastAppliedSeq,
      if (lastAppliedHlc != null) 'last_applied_hlc': lastAppliedHlc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? lastAppliedSeq,
    Value<String?>? lastAppliedHlc,
    Value<int>? rowid,
  }) {
    return SyncCursorCompanion(
      deviceId: deviceId ?? this.deviceId,
      lastAppliedSeq: lastAppliedSeq ?? this.lastAppliedSeq,
      lastAppliedHlc: lastAppliedHlc ?? this.lastAppliedHlc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (lastAppliedSeq.present) {
      map['last_applied_seq'] = Variable<int>(lastAppliedSeq.value);
    }
    if (lastAppliedHlc.present) {
      map['last_applied_hlc'] = Variable<String>(lastAppliedHlc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('lastAppliedSeq: $lastAppliedSeq, ')
          ..write('lastAppliedHlc: $lastAppliedHlc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConflictsTable extends Conflicts
    with TableInfo<$ConflictsTable, ConflictData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityKindMeta = const VerificationMeta(
    'entityKind',
  );
  @override
  late final GeneratedColumn<String> entityKind = GeneratedColumn<String>(
    'entity_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localStateJsonMeta = const VerificationMeta(
    'localStateJson',
  );
  @override
  late final GeneratedColumn<String> localStateJson = GeneratedColumn<String>(
    'local_state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteStateJsonMeta = const VerificationMeta(
    'remoteStateJson',
  );
  @override
  late final GeneratedColumn<String> remoteStateJson = GeneratedColumn<String>(
    'remote_state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _provisionalWinnerMeta = const VerificationMeta(
    'provisionalWinner',
  );
  @override
  late final GeneratedColumn<String> provisionalWinner =
      GeneratedColumn<String>(
        'provisional_winner',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> detectedAt =
      GeneratedColumn<int>(
        'detected_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ConflictsTable.$converterdetectedAt);
  static const VerificationMeta _detectedHlcMeta = const VerificationMeta(
    'detectedHlc',
  );
  @override
  late final GeneratedColumn<String> detectedHlc = GeneratedColumn<String>(
    'detected_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> resolvedAt =
      GeneratedColumn<int>(
        'resolved_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ConflictsTable.$converterresolvedAtn);
  static const VerificationMeta _resolutionMeta = const VerificationMeta(
    'resolution',
  );
  @override
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
    'resolution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedByDeviceMeta = const VerificationMeta(
    'resolvedByDevice',
  );
  @override
  late final GeneratedColumn<String> resolvedByDevice = GeneratedColumn<String>(
    'resolved_by_device',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityKind,
    entityId,
    localStateJson,
    remoteStateJson,
    provisionalWinner,
    detectedAt,
    detectedHlc,
    resolvedAt,
    resolution,
    resolvedByDevice,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConflictData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_kind')) {
      context.handle(
        _entityKindMeta,
        entityKind.isAcceptableOrUnknown(data['entity_kind']!, _entityKindMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKindMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('local_state_json')) {
      context.handle(
        _localStateJsonMeta,
        localStateJson.isAcceptableOrUnknown(
          data['local_state_json']!,
          _localStateJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localStateJsonMeta);
    }
    if (data.containsKey('remote_state_json')) {
      context.handle(
        _remoteStateJsonMeta,
        remoteStateJson.isAcceptableOrUnknown(
          data['remote_state_json']!,
          _remoteStateJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteStateJsonMeta);
    }
    if (data.containsKey('provisional_winner')) {
      context.handle(
        _provisionalWinnerMeta,
        provisionalWinner.isAcceptableOrUnknown(
          data['provisional_winner']!,
          _provisionalWinnerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_provisionalWinnerMeta);
    }
    if (data.containsKey('detected_hlc')) {
      context.handle(
        _detectedHlcMeta,
        detectedHlc.isAcceptableOrUnknown(
          data['detected_hlc']!,
          _detectedHlcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_detectedHlcMeta);
    }
    if (data.containsKey('resolution')) {
      context.handle(
        _resolutionMeta,
        resolution.isAcceptableOrUnknown(data['resolution']!, _resolutionMeta),
      );
    }
    if (data.containsKey('resolved_by_device')) {
      context.handle(
        _resolvedByDeviceMeta,
        resolvedByDevice.isAcceptableOrUnknown(
          data['resolved_by_device']!,
          _resolvedByDeviceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConflictData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConflictData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_kind'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      localStateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_state_json'],
      )!,
      remoteStateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_state_json'],
      )!,
      provisionalWinner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provisional_winner'],
      )!,
      detectedAt: $ConflictsTable.$converterdetectedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}detected_at'],
        )!,
      ),
      detectedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detected_hlc'],
      )!,
      resolvedAt: $ConflictsTable.$converterresolvedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}resolved_at'],
        ),
      ),
      resolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution'],
      ),
      resolvedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_by_device'],
      ),
    );
  }

  @override
  $ConflictsTable createAlias(String alias) {
    return $ConflictsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdetectedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterresolvedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterresolvedAtn =
      NullAwareTypeConverter.wrap($converterresolvedAt);
}

class ConflictData extends DataClass implements Insertable<ConflictData> {
  final String id;
  final String entityKind;
  final String entityId;
  final String localStateJson;
  final String remoteStateJson;
  final String provisionalWinner;
  final DateTime detectedAt;
  final String detectedHlc;
  final DateTime? resolvedAt;
  final String? resolution;
  final String? resolvedByDevice;
  const ConflictData({
    required this.id,
    required this.entityKind,
    required this.entityId,
    required this.localStateJson,
    required this.remoteStateJson,
    required this.provisionalWinner,
    required this.detectedAt,
    required this.detectedHlc,
    this.resolvedAt,
    this.resolution,
    this.resolvedByDevice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_kind'] = Variable<String>(entityKind);
    map['entity_id'] = Variable<String>(entityId);
    map['local_state_json'] = Variable<String>(localStateJson);
    map['remote_state_json'] = Variable<String>(remoteStateJson);
    map['provisional_winner'] = Variable<String>(provisionalWinner);
    {
      map['detected_at'] = Variable<int>(
        $ConflictsTable.$converterdetectedAt.toSql(detectedAt),
      );
    }
    map['detected_hlc'] = Variable<String>(detectedHlc);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<int>(
        $ConflictsTable.$converterresolvedAtn.toSql(resolvedAt),
      );
    }
    if (!nullToAbsent || resolution != null) {
      map['resolution'] = Variable<String>(resolution);
    }
    if (!nullToAbsent || resolvedByDevice != null) {
      map['resolved_by_device'] = Variable<String>(resolvedByDevice);
    }
    return map;
  }

  ConflictsCompanion toCompanion(bool nullToAbsent) {
    return ConflictsCompanion(
      id: Value(id),
      entityKind: Value(entityKind),
      entityId: Value(entityId),
      localStateJson: Value(localStateJson),
      remoteStateJson: Value(remoteStateJson),
      provisionalWinner: Value(provisionalWinner),
      detectedAt: Value(detectedAt),
      detectedHlc: Value(detectedHlc),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      resolution: resolution == null && nullToAbsent
          ? const Value.absent()
          : Value(resolution),
      resolvedByDevice: resolvedByDevice == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedByDevice),
    );
  }

  factory ConflictData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConflictData(
      id: serializer.fromJson<String>(json['id']),
      entityKind: serializer.fromJson<String>(json['entityKind']),
      entityId: serializer.fromJson<String>(json['entityId']),
      localStateJson: serializer.fromJson<String>(json['localStateJson']),
      remoteStateJson: serializer.fromJson<String>(json['remoteStateJson']),
      provisionalWinner: serializer.fromJson<String>(json['provisionalWinner']),
      detectedAt: serializer.fromJson<DateTime>(json['detectedAt']),
      detectedHlc: serializer.fromJson<String>(json['detectedHlc']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      resolution: serializer.fromJson<String?>(json['resolution']),
      resolvedByDevice: serializer.fromJson<String?>(json['resolvedByDevice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityKind': serializer.toJson<String>(entityKind),
      'entityId': serializer.toJson<String>(entityId),
      'localStateJson': serializer.toJson<String>(localStateJson),
      'remoteStateJson': serializer.toJson<String>(remoteStateJson),
      'provisionalWinner': serializer.toJson<String>(provisionalWinner),
      'detectedAt': serializer.toJson<DateTime>(detectedAt),
      'detectedHlc': serializer.toJson<String>(detectedHlc),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'resolution': serializer.toJson<String?>(resolution),
      'resolvedByDevice': serializer.toJson<String?>(resolvedByDevice),
    };
  }

  ConflictData copyWith({
    String? id,
    String? entityKind,
    String? entityId,
    String? localStateJson,
    String? remoteStateJson,
    String? provisionalWinner,
    DateTime? detectedAt,
    String? detectedHlc,
    Value<DateTime?> resolvedAt = const Value.absent(),
    Value<String?> resolution = const Value.absent(),
    Value<String?> resolvedByDevice = const Value.absent(),
  }) => ConflictData(
    id: id ?? this.id,
    entityKind: entityKind ?? this.entityKind,
    entityId: entityId ?? this.entityId,
    localStateJson: localStateJson ?? this.localStateJson,
    remoteStateJson: remoteStateJson ?? this.remoteStateJson,
    provisionalWinner: provisionalWinner ?? this.provisionalWinner,
    detectedAt: detectedAt ?? this.detectedAt,
    detectedHlc: detectedHlc ?? this.detectedHlc,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    resolution: resolution.present ? resolution.value : this.resolution,
    resolvedByDevice: resolvedByDevice.present
        ? resolvedByDevice.value
        : this.resolvedByDevice,
  );
  ConflictData copyWithCompanion(ConflictsCompanion data) {
    return ConflictData(
      id: data.id.present ? data.id.value : this.id,
      entityKind: data.entityKind.present
          ? data.entityKind.value
          : this.entityKind,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      localStateJson: data.localStateJson.present
          ? data.localStateJson.value
          : this.localStateJson,
      remoteStateJson: data.remoteStateJson.present
          ? data.remoteStateJson.value
          : this.remoteStateJson,
      provisionalWinner: data.provisionalWinner.present
          ? data.provisionalWinner.value
          : this.provisionalWinner,
      detectedAt: data.detectedAt.present
          ? data.detectedAt.value
          : this.detectedAt,
      detectedHlc: data.detectedHlc.present
          ? data.detectedHlc.value
          : this.detectedHlc,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      resolution: data.resolution.present
          ? data.resolution.value
          : this.resolution,
      resolvedByDevice: data.resolvedByDevice.present
          ? data.resolvedByDevice.value
          : this.resolvedByDevice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConflictData(')
          ..write('id: $id, ')
          ..write('entityKind: $entityKind, ')
          ..write('entityId: $entityId, ')
          ..write('localStateJson: $localStateJson, ')
          ..write('remoteStateJson: $remoteStateJson, ')
          ..write('provisionalWinner: $provisionalWinner, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('detectedHlc: $detectedHlc, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('resolution: $resolution, ')
          ..write('resolvedByDevice: $resolvedByDevice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityKind,
    entityId,
    localStateJson,
    remoteStateJson,
    provisionalWinner,
    detectedAt,
    detectedHlc,
    resolvedAt,
    resolution,
    resolvedByDevice,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictData &&
          other.id == this.id &&
          other.entityKind == this.entityKind &&
          other.entityId == this.entityId &&
          other.localStateJson == this.localStateJson &&
          other.remoteStateJson == this.remoteStateJson &&
          other.provisionalWinner == this.provisionalWinner &&
          other.detectedAt == this.detectedAt &&
          other.detectedHlc == this.detectedHlc &&
          other.resolvedAt == this.resolvedAt &&
          other.resolution == this.resolution &&
          other.resolvedByDevice == this.resolvedByDevice);
}

class ConflictsCompanion extends UpdateCompanion<ConflictData> {
  final Value<String> id;
  final Value<String> entityKind;
  final Value<String> entityId;
  final Value<String> localStateJson;
  final Value<String> remoteStateJson;
  final Value<String> provisionalWinner;
  final Value<DateTime> detectedAt;
  final Value<String> detectedHlc;
  final Value<DateTime?> resolvedAt;
  final Value<String?> resolution;
  final Value<String?> resolvedByDevice;
  final Value<int> rowid;
  const ConflictsCompanion({
    this.id = const Value.absent(),
    this.entityKind = const Value.absent(),
    this.entityId = const Value.absent(),
    this.localStateJson = const Value.absent(),
    this.remoteStateJson = const Value.absent(),
    this.provisionalWinner = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.detectedHlc = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.resolution = const Value.absent(),
    this.resolvedByDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConflictsCompanion.insert({
    required String id,
    required String entityKind,
    required String entityId,
    required String localStateJson,
    required String remoteStateJson,
    required String provisionalWinner,
    required DateTime detectedAt,
    required String detectedHlc,
    this.resolvedAt = const Value.absent(),
    this.resolution = const Value.absent(),
    this.resolvedByDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityKind = Value(entityKind),
       entityId = Value(entityId),
       localStateJson = Value(localStateJson),
       remoteStateJson = Value(remoteStateJson),
       provisionalWinner = Value(provisionalWinner),
       detectedAt = Value(detectedAt),
       detectedHlc = Value(detectedHlc);
  static Insertable<ConflictData> custom({
    Expression<String>? id,
    Expression<String>? entityKind,
    Expression<String>? entityId,
    Expression<String>? localStateJson,
    Expression<String>? remoteStateJson,
    Expression<String>? provisionalWinner,
    Expression<int>? detectedAt,
    Expression<String>? detectedHlc,
    Expression<int>? resolvedAt,
    Expression<String>? resolution,
    Expression<String>? resolvedByDevice,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityKind != null) 'entity_kind': entityKind,
      if (entityId != null) 'entity_id': entityId,
      if (localStateJson != null) 'local_state_json': localStateJson,
      if (remoteStateJson != null) 'remote_state_json': remoteStateJson,
      if (provisionalWinner != null) 'provisional_winner': provisionalWinner,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (detectedHlc != null) 'detected_hlc': detectedHlc,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (resolution != null) 'resolution': resolution,
      if (resolvedByDevice != null) 'resolved_by_device': resolvedByDevice,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConflictsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityKind,
    Value<String>? entityId,
    Value<String>? localStateJson,
    Value<String>? remoteStateJson,
    Value<String>? provisionalWinner,
    Value<DateTime>? detectedAt,
    Value<String>? detectedHlc,
    Value<DateTime?>? resolvedAt,
    Value<String?>? resolution,
    Value<String?>? resolvedByDevice,
    Value<int>? rowid,
  }) {
    return ConflictsCompanion(
      id: id ?? this.id,
      entityKind: entityKind ?? this.entityKind,
      entityId: entityId ?? this.entityId,
      localStateJson: localStateJson ?? this.localStateJson,
      remoteStateJson: remoteStateJson ?? this.remoteStateJson,
      provisionalWinner: provisionalWinner ?? this.provisionalWinner,
      detectedAt: detectedAt ?? this.detectedAt,
      detectedHlc: detectedHlc ?? this.detectedHlc,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
      resolvedByDevice: resolvedByDevice ?? this.resolvedByDevice,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityKind.present) {
      map['entity_kind'] = Variable<String>(entityKind.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (localStateJson.present) {
      map['local_state_json'] = Variable<String>(localStateJson.value);
    }
    if (remoteStateJson.present) {
      map['remote_state_json'] = Variable<String>(remoteStateJson.value);
    }
    if (provisionalWinner.present) {
      map['provisional_winner'] = Variable<String>(provisionalWinner.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<int>(
        $ConflictsTable.$converterdetectedAt.toSql(detectedAt.value),
      );
    }
    if (detectedHlc.present) {
      map['detected_hlc'] = Variable<String>(detectedHlc.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<int>(
        $ConflictsTable.$converterresolvedAtn.toSql(resolvedAt.value),
      );
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    if (resolvedByDevice.present) {
      map['resolved_by_device'] = Variable<String>(resolvedByDevice.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictsCompanion(')
          ..write('id: $id, ')
          ..write('entityKind: $entityKind, ')
          ..write('entityId: $entityId, ')
          ..write('localStateJson: $localStateJson, ')
          ..write('remoteStateJson: $remoteStateJson, ')
          ..write('provisionalWinner: $provisionalWinner, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('detectedHlc: $detectedHlc, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('resolution: $resolution, ')
          ..write('resolvedByDevice: $resolvedByDevice, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TombstonesTable extends Tombstones
    with TableInfo<$TombstonesTable, TombstoneData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityKindMeta = const VerificationMeta(
    'entityKind',
  );
  @override
  late final GeneratedColumn<String> entityKind = GeneratedColumn<String>(
    'entity_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedHlcMeta = const VerificationMeta(
    'deletedHlc',
  );
  @override
  late final GeneratedColumn<String> deletedHlc = GeneratedColumn<String>(
    'deleted_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originDeviceMeta = const VerificationMeta(
    'originDevice',
  );
  @override
  late final GeneratedColumn<String> originDevice = GeneratedColumn<String>(
    'origin_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> purgeAfter =
      GeneratedColumn<int>(
        'purge_after',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($TombstonesTable.$converterpurgeAfter);
  @override
  List<GeneratedColumn> get $columns => [
    entityKind,
    entityId,
    deletedHlc,
    originDevice,
    purgeAfter,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<TombstoneData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_kind')) {
      context.handle(
        _entityKindMeta,
        entityKind.isAcceptableOrUnknown(data['entity_kind']!, _entityKindMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKindMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('deleted_hlc')) {
      context.handle(
        _deletedHlcMeta,
        deletedHlc.isAcceptableOrUnknown(data['deleted_hlc']!, _deletedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedHlcMeta);
    }
    if (data.containsKey('origin_device')) {
      context.handle(
        _originDeviceMeta,
        originDevice.isAcceptableOrUnknown(
          data['origin_device']!,
          _originDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityKind, entityId};
  @override
  TombstoneData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TombstoneData(
      entityKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_kind'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      deletedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_hlc'],
      )!,
      originDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device'],
      )!,
      purgeAfter: $TombstonesTable.$converterpurgeAfter.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}purge_after'],
        )!,
      ),
    );
  }

  @override
  $TombstonesTable createAlias(String alias) {
    return $TombstonesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterpurgeAfter =
      const MillisConverter();
}

class TombstoneData extends DataClass implements Insertable<TombstoneData> {
  final String entityKind;
  final String entityId;
  final String deletedHlc;
  final String originDevice;
  final DateTime purgeAfter;
  const TombstoneData({
    required this.entityKind,
    required this.entityId,
    required this.deletedHlc,
    required this.originDevice,
    required this.purgeAfter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_kind'] = Variable<String>(entityKind);
    map['entity_id'] = Variable<String>(entityId);
    map['deleted_hlc'] = Variable<String>(deletedHlc);
    map['origin_device'] = Variable<String>(originDevice);
    {
      map['purge_after'] = Variable<int>(
        $TombstonesTable.$converterpurgeAfter.toSql(purgeAfter),
      );
    }
    return map;
  }

  TombstonesCompanion toCompanion(bool nullToAbsent) {
    return TombstonesCompanion(
      entityKind: Value(entityKind),
      entityId: Value(entityId),
      deletedHlc: Value(deletedHlc),
      originDevice: Value(originDevice),
      purgeAfter: Value(purgeAfter),
    );
  }

  factory TombstoneData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TombstoneData(
      entityKind: serializer.fromJson<String>(json['entityKind']),
      entityId: serializer.fromJson<String>(json['entityId']),
      deletedHlc: serializer.fromJson<String>(json['deletedHlc']),
      originDevice: serializer.fromJson<String>(json['originDevice']),
      purgeAfter: serializer.fromJson<DateTime>(json['purgeAfter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityKind': serializer.toJson<String>(entityKind),
      'entityId': serializer.toJson<String>(entityId),
      'deletedHlc': serializer.toJson<String>(deletedHlc),
      'originDevice': serializer.toJson<String>(originDevice),
      'purgeAfter': serializer.toJson<DateTime>(purgeAfter),
    };
  }

  TombstoneData copyWith({
    String? entityKind,
    String? entityId,
    String? deletedHlc,
    String? originDevice,
    DateTime? purgeAfter,
  }) => TombstoneData(
    entityKind: entityKind ?? this.entityKind,
    entityId: entityId ?? this.entityId,
    deletedHlc: deletedHlc ?? this.deletedHlc,
    originDevice: originDevice ?? this.originDevice,
    purgeAfter: purgeAfter ?? this.purgeAfter,
  );
  TombstoneData copyWithCompanion(TombstonesCompanion data) {
    return TombstoneData(
      entityKind: data.entityKind.present
          ? data.entityKind.value
          : this.entityKind,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      deletedHlc: data.deletedHlc.present
          ? data.deletedHlc.value
          : this.deletedHlc,
      originDevice: data.originDevice.present
          ? data.originDevice.value
          : this.originDevice,
      purgeAfter: data.purgeAfter.present
          ? data.purgeAfter.value
          : this.purgeAfter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TombstoneData(')
          ..write('entityKind: $entityKind, ')
          ..write('entityId: $entityId, ')
          ..write('deletedHlc: $deletedHlc, ')
          ..write('originDevice: $originDevice, ')
          ..write('purgeAfter: $purgeAfter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(entityKind, entityId, deletedHlc, originDevice, purgeAfter);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TombstoneData &&
          other.entityKind == this.entityKind &&
          other.entityId == this.entityId &&
          other.deletedHlc == this.deletedHlc &&
          other.originDevice == this.originDevice &&
          other.purgeAfter == this.purgeAfter);
}

class TombstonesCompanion extends UpdateCompanion<TombstoneData> {
  final Value<String> entityKind;
  final Value<String> entityId;
  final Value<String> deletedHlc;
  final Value<String> originDevice;
  final Value<DateTime> purgeAfter;
  final Value<int> rowid;
  const TombstonesCompanion({
    this.entityKind = const Value.absent(),
    this.entityId = const Value.absent(),
    this.deletedHlc = const Value.absent(),
    this.originDevice = const Value.absent(),
    this.purgeAfter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TombstonesCompanion.insert({
    required String entityKind,
    required String entityId,
    required String deletedHlc,
    required String originDevice,
    required DateTime purgeAfter,
    this.rowid = const Value.absent(),
  }) : entityKind = Value(entityKind),
       entityId = Value(entityId),
       deletedHlc = Value(deletedHlc),
       originDevice = Value(originDevice),
       purgeAfter = Value(purgeAfter);
  static Insertable<TombstoneData> custom({
    Expression<String>? entityKind,
    Expression<String>? entityId,
    Expression<String>? deletedHlc,
    Expression<String>? originDevice,
    Expression<int>? purgeAfter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityKind != null) 'entity_kind': entityKind,
      if (entityId != null) 'entity_id': entityId,
      if (deletedHlc != null) 'deleted_hlc': deletedHlc,
      if (originDevice != null) 'origin_device': originDevice,
      if (purgeAfter != null) 'purge_after': purgeAfter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TombstonesCompanion copyWith({
    Value<String>? entityKind,
    Value<String>? entityId,
    Value<String>? deletedHlc,
    Value<String>? originDevice,
    Value<DateTime>? purgeAfter,
    Value<int>? rowid,
  }) {
    return TombstonesCompanion(
      entityKind: entityKind ?? this.entityKind,
      entityId: entityId ?? this.entityId,
      deletedHlc: deletedHlc ?? this.deletedHlc,
      originDevice: originDevice ?? this.originDevice,
      purgeAfter: purgeAfter ?? this.purgeAfter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityKind.present) {
      map['entity_kind'] = Variable<String>(entityKind.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (deletedHlc.present) {
      map['deleted_hlc'] = Variable<String>(deletedHlc.value);
    }
    if (originDevice.present) {
      map['origin_device'] = Variable<String>(originDevice.value);
    }
    if (purgeAfter.present) {
      map['purge_after'] = Variable<int>(
        $TombstonesTable.$converterpurgeAfter.toSql(purgeAfter.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TombstonesCompanion(')
          ..write('entityKind: $entityKind, ')
          ..write('entityId: $entityId, ')
          ..write('deletedHlc: $deletedHlc, ')
          ..write('originDevice: $originDevice, ')
          ..write('purgeAfter: $purgeAfter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final $KeyEpochsTable keyEpochs = $KeyEpochsTable(this);
  late final $VaultEntriesTable vaultEntries = $VaultEntriesTable(this);
  late final $BlobsTable blobs = $BlobsTable(this);
  late final $AssetsTable assets = $AssetsTable(this);
  late final $AssetVersionsTable assetVersions = $AssetVersionsTable(this);
  late final $VersionPinsTable versionPins = $VersionPinsTable(this);
  late final $ThumbnailsTable thumbnails = $ThumbnailsTable(this);
  late final $ExportRecordsTable exportRecords = $ExportRecordsTable(this);
  late final $ExportRecordSourcesTable exportRecordSources =
      $ExportRecordSourcesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $CloudObjectsTable cloudObjects = $CloudObjectsTable(this);
  late final $SyncLogSegmentsTable syncLogSegments = $SyncLogSegmentsTable(
    this,
  );
  late final $SyncLogOpsTable syncLogOps = $SyncLogOpsTable(this);
  late final $SyncCursorTable syncCursor = $SyncCursorTable(this);
  late final $ConflictsTable conflicts = $ConflictsTable(this);
  late final $TombstonesTable tombstones = $TombstonesTable(this);
  late final DevicesDao devicesDao = DevicesDao(this as AppDatabase);
  late final EntriesDao entriesDao = EntriesDao(this as AppDatabase);
  late final EpochsDao epochsDao = EpochsDao(this as AppDatabase);
  late final ExportsDao exportsDao = ExportsDao(this as AppDatabase);
  late final SyncDao syncDao = SyncDao(this as AppDatabase);
  late final VersionsDao versionsDao = VersionsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    devices,
    appMeta,
    keyEpochs,
    vaultEntries,
    blobs,
    assets,
    assetVersions,
    versionPins,
    thumbnails,
    exportRecords,
    exportRecordSources,
    syncQueue,
    cloudObjects,
    syncLogSegments,
    syncLogOps,
    syncCursor,
    conflicts,
    tombstones,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vault_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('assets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'assets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('asset_versions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'asset_versions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('version_pins', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'asset_versions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('thumbnails', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'blobs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('export_records', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'export_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('export_record_sources', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'devices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sync_cursor', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'devices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('conflicts', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$DevicesTableCreateCompanionBuilder =
    DevicesCompanion Function({
      required String id,
      Value<String?> label,
      Value<bool> isSelf,
      required DateTime createdAt,
      Value<String?> lastSeenHlc,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$DevicesTableUpdateCompanionBuilder =
    DevicesCompanion Function({
      Value<String> id,
      Value<String?> label,
      Value<bool> isSelf,
      Value<DateTime> createdAt,
      Value<String?> lastSeenHlc,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

final class $$DevicesTableReferences
    extends BaseReferences<_$AppDatabase, $DevicesTable, DeviceData> {
  $$DevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VaultEntriesTable, List<VaultEntryData>>
  _vaultEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.vaultEntries,
    aliasName: $_aliasNameGenerator(
      db.devices.id,
      db.vaultEntries.originDevice,
    ),
  );

  $$VaultEntriesTableProcessedTableManager get vaultEntriesRefs {
    final manager = $$VaultEntriesTableTableManager(
      $_db,
      $_db.vaultEntries,
    ).filter((f) => f.originDevice.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_vaultEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AssetsTable, List<AssetData>> _assetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.assets,
    aliasName: $_aliasNameGenerator(db.devices.id, db.assets.originDevice),
  );

  $$AssetsTableProcessedTableManager get assetsRefs {
    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.originDevice.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AssetVersionsTable, List<AssetVersionData>>
  _assetVersionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.assetVersions,
    aliasName: $_aliasNameGenerator(
      db.devices.id,
      db.assetVersions.originDevice,
    ),
  );

  $$AssetVersionsTableProcessedTableManager get assetVersionsRefs {
    final manager = $$AssetVersionsTableTableManager(
      $_db,
      $_db.assetVersions,
    ).filter((f) => f.originDevice.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetVersionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExportRecordsTable, List<ExportRecordData>>
  _exportRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exportRecords,
    aliasName: $_aliasNameGenerator(
      db.devices.id,
      db.exportRecords.originDevice,
    ),
  );

  $$ExportRecordsTableProcessedTableManager get exportRecordsRefs {
    final manager = $$ExportRecordsTableTableManager(
      $_db,
      $_db.exportRecords,
    ).filter((f) => f.originDevice.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_exportRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncLogSegmentsTable, List<SyncLogSegmentData>>
  _syncLogSegmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syncLogSegments,
    aliasName: $_aliasNameGenerator(db.devices.id, db.syncLogSegments.deviceId),
  );

  $$SyncLogSegmentsTableProcessedTableManager get syncLogSegmentsRefs {
    final manager = $$SyncLogSegmentsTableTableManager(
      $_db,
      $_db.syncLogSegments,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _syncLogSegmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncCursorTable, List<SyncCursorData>>
  _syncCursorRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syncCursor,
    aliasName: $_aliasNameGenerator(db.devices.id, db.syncCursor.deviceId),
  );

  $$SyncCursorTableProcessedTableManager get syncCursorRefs {
    final manager = $$SyncCursorTableTableManager(
      $_db,
      $_db.syncCursor,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_syncCursorRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ConflictsTable, List<ConflictData>>
  _conflictsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.conflicts,
    aliasName: $_aliasNameGenerator(
      db.devices.id,
      db.conflicts.resolvedByDevice,
    ),
  );

  $$ConflictsTableProcessedTableManager get conflictsRefs {
    final manager = $$ConflictsTableTableManager($_db, $_db.conflicts).filter(
      (f) => f.resolvedByDevice.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_conflictsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TombstonesTable, List<TombstoneData>>
  _tombstonesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.tombstones,
    aliasName: $_aliasNameGenerator(db.devices.id, db.tombstones.originDevice),
  );

  $$TombstonesTableProcessedTableManager get tombstonesRefs {
    final manager = $$TombstonesTableTableManager(
      $_db,
      $_db.tombstones,
    ).filter((f) => f.originDevice.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tombstonesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSelf => $composableBuilder(
    column: $table.isSelf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get lastSeenHlc => $composableBuilder(
    column: $table.lastSeenHlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastSyncedAt =>
      $composableBuilder(
        column: $table.lastSyncedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> vaultEntriesRefs(
    Expression<bool> Function($$VaultEntriesTableFilterComposer f) f,
  ) {
    final $$VaultEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vaultEntries,
      getReferencedColumn: (t) => t.originDevice,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultEntriesTableFilterComposer(
            $db: $db,
            $table: $db.vaultEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> assetsRefs(
    Expression<bool> Function($$AssetsTableFilterComposer f) f,
  ) {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.originDevice,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> assetVersionsRefs(
    Expression<bool> Function($$AssetVersionsTableFilterComposer f) f,
  ) {
    final $$AssetVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.originDevice,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableFilterComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exportRecordsRefs(
    Expression<bool> Function($$ExportRecordsTableFilterComposer f) f,
  ) {
    final $$ExportRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exportRecords,
      getReferencedColumn: (t) => t.originDevice,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExportRecordsTableFilterComposer(
            $db: $db,
            $table: $db.exportRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncLogSegmentsRefs(
    Expression<bool> Function($$SyncLogSegmentsTableFilterComposer f) f,
  ) {
    final $$SyncLogSegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncLogSegments,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncLogSegmentsTableFilterComposer(
            $db: $db,
            $table: $db.syncLogSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncCursorRefs(
    Expression<bool> Function($$SyncCursorTableFilterComposer f) f,
  ) {
    final $$SyncCursorTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncCursor,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncCursorTableFilterComposer(
            $db: $db,
            $table: $db.syncCursor,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> conflictsRefs(
    Expression<bool> Function($$ConflictsTableFilterComposer f) f,
  ) {
    final $$ConflictsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conflicts,
      getReferencedColumn: (t) => t.resolvedByDevice,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConflictsTableFilterComposer(
            $db: $db,
            $table: $db.conflicts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tombstonesRefs(
    Expression<bool> Function($$TombstonesTableFilterComposer f) f,
  ) {
    final $$TombstonesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tombstones,
      getReferencedColumn: (t) => t.originDevice,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TombstonesTableFilterComposer(
            $db: $db,
            $table: $db.tombstones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSelf => $composableBuilder(
    column: $table.isSelf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSeenHlc => $composableBuilder(
    column: $table.lastSeenHlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get isSelf =>
      $composableBuilder(column: $table.isSelf, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get lastSeenHlc => $composableBuilder(
    column: $table.lastSeenHlc,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastSyncedAt =>
      $composableBuilder(
        column: $table.lastSyncedAt,
        builder: (column) => column,
      );

  Expression<T> vaultEntriesRefs<T extends Object>(
    Expression<T> Function($$VaultEntriesTableAnnotationComposer a) f,
  ) {
    final $$VaultEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vaultEntries,
      getReferencedColumn: (t) => t.originDevice,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.vaultEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> assetsRefs<T extends Object>(
    Expression<T> Function($$AssetsTableAnnotationComposer a) f,
  ) {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.originDevice,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> assetVersionsRefs<T extends Object>(
    Expression<T> Function($$AssetVersionsTableAnnotationComposer a) f,
  ) {
    final $$AssetVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.originDevice,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exportRecordsRefs<T extends Object>(
    Expression<T> Function($$ExportRecordsTableAnnotationComposer a) f,
  ) {
    final $$ExportRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exportRecords,
      getReferencedColumn: (t) => t.originDevice,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExportRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.exportRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncLogSegmentsRefs<T extends Object>(
    Expression<T> Function($$SyncLogSegmentsTableAnnotationComposer a) f,
  ) {
    final $$SyncLogSegmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncLogSegments,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncLogSegmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.syncLogSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncCursorRefs<T extends Object>(
    Expression<T> Function($$SyncCursorTableAnnotationComposer a) f,
  ) {
    final $$SyncCursorTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncCursor,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncCursorTableAnnotationComposer(
            $db: $db,
            $table: $db.syncCursor,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> conflictsRefs<T extends Object>(
    Expression<T> Function($$ConflictsTableAnnotationComposer a) f,
  ) {
    final $$ConflictsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conflicts,
      getReferencedColumn: (t) => t.resolvedByDevice,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConflictsTableAnnotationComposer(
            $db: $db,
            $table: $db.conflicts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tombstonesRefs<T extends Object>(
    Expression<T> Function($$TombstonesTableAnnotationComposer a) f,
  ) {
    final $$TombstonesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tombstones,
      getReferencedColumn: (t) => t.originDevice,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TombstonesTableAnnotationComposer(
            $db: $db,
            $table: $db.tombstones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevicesTable,
          DeviceData,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (DeviceData, $$DevicesTableReferences),
          DeviceData,
          PrefetchHooks Function({
            bool vaultEntriesRefs,
            bool assetsRefs,
            bool assetVersionsRefs,
            bool exportRecordsRefs,
            bool syncLogSegmentsRefs,
            bool syncCursorRefs,
            bool conflictsRefs,
            bool tombstonesRefs,
          })
        > {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<bool> isSelf = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> lastSeenHlc = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion(
                id: id,
                label: label,
                isSelf: isSelf,
                createdAt: createdAt,
                lastSeenHlc: lastSeenHlc,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> label = const Value.absent(),
                Value<bool> isSelf = const Value.absent(),
                required DateTime createdAt,
                Value<String?> lastSeenHlc = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion.insert(
                id: id,
                label: label,
                isSelf: isSelf,
                createdAt: createdAt,
                lastSeenHlc: lastSeenHlc,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DevicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                vaultEntriesRefs = false,
                assetsRefs = false,
                assetVersionsRefs = false,
                exportRecordsRefs = false,
                syncLogSegmentsRefs = false,
                syncCursorRefs = false,
                conflictsRefs = false,
                tombstonesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (vaultEntriesRefs) db.vaultEntries,
                    if (assetsRefs) db.assets,
                    if (assetVersionsRefs) db.assetVersions,
                    if (exportRecordsRefs) db.exportRecords,
                    if (syncLogSegmentsRefs) db.syncLogSegments,
                    if (syncCursorRefs) db.syncCursor,
                    if (conflictsRefs) db.conflicts,
                    if (tombstonesRefs) db.tombstones,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (vaultEntriesRefs)
                        await $_getPrefetchedData<
                          DeviceData,
                          $DevicesTable,
                          VaultEntryData
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._vaultEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).vaultEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.originDevice == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (assetsRefs)
                        await $_getPrefetchedData<
                          DeviceData,
                          $DevicesTable,
                          AssetData
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._assetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).assetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.originDevice == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (assetVersionsRefs)
                        await $_getPrefetchedData<
                          DeviceData,
                          $DevicesTable,
                          AssetVersionData
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._assetVersionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).assetVersionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.originDevice == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exportRecordsRefs)
                        await $_getPrefetchedData<
                          DeviceData,
                          $DevicesTable,
                          ExportRecordData
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._exportRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).exportRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.originDevice == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syncLogSegmentsRefs)
                        await $_getPrefetchedData<
                          DeviceData,
                          $DevicesTable,
                          SyncLogSegmentData
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._syncLogSegmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).syncLogSegmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deviceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syncCursorRefs)
                        await $_getPrefetchedData<
                          DeviceData,
                          $DevicesTable,
                          SyncCursorData
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._syncCursorRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).syncCursorRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deviceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (conflictsRefs)
                        await $_getPrefetchedData<
                          DeviceData,
                          $DevicesTable,
                          ConflictData
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._conflictsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).conflictsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.resolvedByDevice == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tombstonesRefs)
                        await $_getPrefetchedData<
                          DeviceData,
                          $DevicesTable,
                          TombstoneData
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._tombstonesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).tombstonesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.originDevice == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevicesTable,
      DeviceData,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (DeviceData, $$DevicesTableReferences),
      DeviceData,
      PrefetchHooks Function({
        bool vaultEntriesRefs,
        bool assetsRefs,
        bool assetVersionsRefs,
        bool exportRecordsRefs,
        bool syncLogSegmentsRefs,
        bool syncCursorRefs,
        bool conflictsRefs,
        bool tombstonesRefs,
      })
    >;
typedef $$AppMetaTableCreateCompanionBuilder =
    AppMetaCompanion Function({
      required String key,
      required Uint8List value,
      Value<int> rowid,
    });
typedef $$AppMetaTableUpdateCompanionBuilder =
    AppMetaCompanion Function({
      Value<String> key,
      Value<Uint8List> value,
      Value<int> rowid,
    });

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<Uint8List> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          AppMetaData,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaData,
            BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>,
          ),
          AppMetaData,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<Uint8List> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required Uint8List value,
                Value<int> rowid = const Value.absent(),
              }) =>
                  AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      AppMetaData,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
      AppMetaData,
      PrefetchHooks Function()
    >;
typedef $$KeyEpochsTableCreateCompanionBuilder =
    KeyEpochsCompanion Function({
      Value<int> epoch,
      required DateTime createdAt,
      Value<DateTime?> retiredAt,
      required String wrapAlg,
      required Uint8List wrappedMkDevice,
      Value<Uint8List?> wrappedMkRecovery,
      Value<String?> kdfParamsJson,
      required String keystoreAlias,
      Value<bool> strongbox,
    });
typedef $$KeyEpochsTableUpdateCompanionBuilder =
    KeyEpochsCompanion Function({
      Value<int> epoch,
      Value<DateTime> createdAt,
      Value<DateTime?> retiredAt,
      Value<String> wrapAlg,
      Value<Uint8List> wrappedMkDevice,
      Value<Uint8List?> wrappedMkRecovery,
      Value<String?> kdfParamsJson,
      Value<String> keystoreAlias,
      Value<bool> strongbox,
    });

final class $$KeyEpochsTableReferences
    extends BaseReferences<_$AppDatabase, $KeyEpochsTable, KeyEpochData> {
  $$KeyEpochsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BlobsTable, List<BlobData>> _blobsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.blobs,
    aliasName: $_aliasNameGenerator(db.keyEpochs.epoch, db.blobs.keyEpoch),
  );

  $$BlobsTableProcessedTableManager get blobsRefs {
    final manager = $$BlobsTableTableManager(
      $_db,
      $_db.blobs,
    ).filter((f) => f.keyEpoch.epoch.sqlEquals($_itemColumn<int>('epoch')!));

    final cache = $_typedResult.readTableOrNull(_blobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KeyEpochsTableFilterComposer
    extends Composer<_$AppDatabase, $KeyEpochsTable> {
  $$KeyEpochsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get retiredAt =>
      $composableBuilder(
        column: $table.retiredAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get wrapAlg => $composableBuilder(
    column: $table.wrapAlg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get wrappedMkDevice => $composableBuilder(
    column: $table.wrappedMkDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get wrappedMkRecovery => $composableBuilder(
    column: $table.wrappedMkRecovery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kdfParamsJson => $composableBuilder(
    column: $table.kdfParamsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keystoreAlias => $composableBuilder(
    column: $table.keystoreAlias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get strongbox => $composableBuilder(
    column: $table.strongbox,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> blobsRefs(
    Expression<bool> Function($$BlobsTableFilterComposer f) f,
  ) {
    final $$BlobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.epoch,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.keyEpoch,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableFilterComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KeyEpochsTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyEpochsTable> {
  $$KeyEpochsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retiredAt => $composableBuilder(
    column: $table.retiredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wrapAlg => $composableBuilder(
    column: $table.wrapAlg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get wrappedMkDevice => $composableBuilder(
    column: $table.wrappedMkDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get wrappedMkRecovery => $composableBuilder(
    column: $table.wrappedMkRecovery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kdfParamsJson => $composableBuilder(
    column: $table.kdfParamsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keystoreAlias => $composableBuilder(
    column: $table.keystoreAlias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get strongbox => $composableBuilder(
    column: $table.strongbox,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyEpochsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyEpochsTable> {
  $$KeyEpochsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get epoch =>
      $composableBuilder(column: $table.epoch, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get retiredAt =>
      $composableBuilder(column: $table.retiredAt, builder: (column) => column);

  GeneratedColumn<String> get wrapAlg =>
      $composableBuilder(column: $table.wrapAlg, builder: (column) => column);

  GeneratedColumn<Uint8List> get wrappedMkDevice => $composableBuilder(
    column: $table.wrappedMkDevice,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get wrappedMkRecovery => $composableBuilder(
    column: $table.wrappedMkRecovery,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kdfParamsJson => $composableBuilder(
    column: $table.kdfParamsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keystoreAlias => $composableBuilder(
    column: $table.keystoreAlias,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get strongbox =>
      $composableBuilder(column: $table.strongbox, builder: (column) => column);

  Expression<T> blobsRefs<T extends Object>(
    Expression<T> Function($$BlobsTableAnnotationComposer a) f,
  ) {
    final $$BlobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.epoch,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.keyEpoch,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableAnnotationComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KeyEpochsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyEpochsTable,
          KeyEpochData,
          $$KeyEpochsTableFilterComposer,
          $$KeyEpochsTableOrderingComposer,
          $$KeyEpochsTableAnnotationComposer,
          $$KeyEpochsTableCreateCompanionBuilder,
          $$KeyEpochsTableUpdateCompanionBuilder,
          (KeyEpochData, $$KeyEpochsTableReferences),
          KeyEpochData,
          PrefetchHooks Function({bool blobsRefs})
        > {
  $$KeyEpochsTableTableManager(_$AppDatabase db, $KeyEpochsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyEpochsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyEpochsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyEpochsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> epoch = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> retiredAt = const Value.absent(),
                Value<String> wrapAlg = const Value.absent(),
                Value<Uint8List> wrappedMkDevice = const Value.absent(),
                Value<Uint8List?> wrappedMkRecovery = const Value.absent(),
                Value<String?> kdfParamsJson = const Value.absent(),
                Value<String> keystoreAlias = const Value.absent(),
                Value<bool> strongbox = const Value.absent(),
              }) => KeyEpochsCompanion(
                epoch: epoch,
                createdAt: createdAt,
                retiredAt: retiredAt,
                wrapAlg: wrapAlg,
                wrappedMkDevice: wrappedMkDevice,
                wrappedMkRecovery: wrappedMkRecovery,
                kdfParamsJson: kdfParamsJson,
                keystoreAlias: keystoreAlias,
                strongbox: strongbox,
              ),
          createCompanionCallback:
              ({
                Value<int> epoch = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> retiredAt = const Value.absent(),
                required String wrapAlg,
                required Uint8List wrappedMkDevice,
                Value<Uint8List?> wrappedMkRecovery = const Value.absent(),
                Value<String?> kdfParamsJson = const Value.absent(),
                required String keystoreAlias,
                Value<bool> strongbox = const Value.absent(),
              }) => KeyEpochsCompanion.insert(
                epoch: epoch,
                createdAt: createdAt,
                retiredAt: retiredAt,
                wrapAlg: wrapAlg,
                wrappedMkDevice: wrappedMkDevice,
                wrappedMkRecovery: wrappedMkRecovery,
                kdfParamsJson: kdfParamsJson,
                keystoreAlias: keystoreAlias,
                strongbox: strongbox,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$KeyEpochsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({blobsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (blobsRefs) db.blobs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (blobsRefs)
                    await $_getPrefetchedData<
                      KeyEpochData,
                      $KeyEpochsTable,
                      BlobData
                    >(
                      currentTable: table,
                      referencedTable: $$KeyEpochsTableReferences
                          ._blobsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$KeyEpochsTableReferences(db, table, p0).blobsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.keyEpoch == item.epoch,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$KeyEpochsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyEpochsTable,
      KeyEpochData,
      $$KeyEpochsTableFilterComposer,
      $$KeyEpochsTableOrderingComposer,
      $$KeyEpochsTableAnnotationComposer,
      $$KeyEpochsTableCreateCompanionBuilder,
      $$KeyEpochsTableUpdateCompanionBuilder,
      (KeyEpochData, $$KeyEpochsTableReferences),
      KeyEpochData,
      PrefetchHooks Function({bool blobsRefs})
    >;
typedef $$VaultEntriesTableCreateCompanionBuilder =
    VaultEntriesCompanion Function({
      required String id,
      required String type,
      Value<Uint8List?> titleEnc,
      Value<Uint8List?> noteEnc,
      Value<Uint8List?> tagsEnc,
      required DateTime createdAt,
      required DateTime updatedAt,
      required String updatedHlc,
      required String originDevice,
      Value<DateTime?> deletedAt,
      Value<String> syncState,
      Value<int> rowid,
    });
typedef $$VaultEntriesTableUpdateCompanionBuilder =
    VaultEntriesCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<Uint8List?> titleEnc,
      Value<Uint8List?> noteEnc,
      Value<Uint8List?> tagsEnc,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> updatedHlc,
      Value<String> originDevice,
      Value<DateTime?> deletedAt,
      Value<String> syncState,
      Value<int> rowid,
    });

final class $$VaultEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $VaultEntriesTable, VaultEntryData> {
  $$VaultEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DevicesTable _originDeviceTable(_$AppDatabase db) =>
      db.devices.createAlias(
        $_aliasNameGenerator(db.vaultEntries.originDevice, db.devices.id),
      );

  $$DevicesTableProcessedTableManager get originDevice {
    final $_column = $_itemColumn<String>('origin_device')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_originDeviceTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AssetsTable, List<AssetData>> _assetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.assets,
    aliasName: $_aliasNameGenerator(db.vaultEntries.id, db.assets.entryId),
  );

  $$AssetsTableProcessedTableManager get assetsRefs {
    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExportRecordsTable, List<ExportRecordData>>
  _exportRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exportRecords,
    aliasName: $_aliasNameGenerator(
      db.vaultEntries.id,
      db.exportRecords.entryId,
    ),
  );

  $$ExportRecordsTableProcessedTableManager get exportRecordsRefs {
    final manager = $$ExportRecordsTableTableManager(
      $_db,
      $_db.exportRecords,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_exportRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VaultEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $VaultEntriesTable> {
  $$VaultEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get titleEnc => $composableBuilder(
    column: $table.titleEnc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get noteEnc => $composableBuilder(
    column: $table.noteEnc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get tagsEnc => $composableBuilder(
    column: $table.tagsEnc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get updatedHlc => $composableBuilder(
    column: $table.updatedHlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  $$DevicesTableFilterComposer get originDevice {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> assetsRefs(
    Expression<bool> Function($$AssetsTableFilterComposer f) f,
  ) {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exportRecordsRefs(
    Expression<bool> Function($$ExportRecordsTableFilterComposer f) f,
  ) {
    final $$ExportRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exportRecords,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExportRecordsTableFilterComposer(
            $db: $db,
            $table: $db.exportRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VaultEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultEntriesTable> {
  $$VaultEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get titleEnc => $composableBuilder(
    column: $table.titleEnc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get noteEnc => $composableBuilder(
    column: $table.noteEnc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get tagsEnc => $composableBuilder(
    column: $table.tagsEnc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedHlc => $composableBuilder(
    column: $table.updatedHlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  $$DevicesTableOrderingComposer get originDevice {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VaultEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultEntriesTable> {
  $$VaultEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<Uint8List> get titleEnc =>
      $composableBuilder(column: $table.titleEnc, builder: (column) => column);

  GeneratedColumn<Uint8List> get noteEnc =>
      $composableBuilder(column: $table.noteEnc, builder: (column) => column);

  GeneratedColumn<Uint8List> get tagsEnc =>
      $composableBuilder(column: $table.tagsEnc, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedHlc => $composableBuilder(
    column: $table.updatedHlc,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  $$DevicesTableAnnotationComposer get originDevice {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> assetsRefs<T extends Object>(
    Expression<T> Function($$AssetsTableAnnotationComposer a) f,
  ) {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exportRecordsRefs<T extends Object>(
    Expression<T> Function($$ExportRecordsTableAnnotationComposer a) f,
  ) {
    final $$ExportRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exportRecords,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExportRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.exportRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VaultEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultEntriesTable,
          VaultEntryData,
          $$VaultEntriesTableFilterComposer,
          $$VaultEntriesTableOrderingComposer,
          $$VaultEntriesTableAnnotationComposer,
          $$VaultEntriesTableCreateCompanionBuilder,
          $$VaultEntriesTableUpdateCompanionBuilder,
          (VaultEntryData, $$VaultEntriesTableReferences),
          VaultEntryData,
          PrefetchHooks Function({
            bool originDevice,
            bool assetsRefs,
            bool exportRecordsRefs,
          })
        > {
  $$VaultEntriesTableTableManager(_$AppDatabase db, $VaultEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<Uint8List?> titleEnc = const Value.absent(),
                Value<Uint8List?> noteEnc = const Value.absent(),
                Value<Uint8List?> tagsEnc = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> updatedHlc = const Value.absent(),
                Value<String> originDevice = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultEntriesCompanion(
                id: id,
                type: type,
                titleEnc: titleEnc,
                noteEnc: noteEnc,
                tagsEnc: tagsEnc,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedHlc: updatedHlc,
                originDevice: originDevice,
                deletedAt: deletedAt,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                Value<Uint8List?> titleEnc = const Value.absent(),
                Value<Uint8List?> noteEnc = const Value.absent(),
                Value<Uint8List?> tagsEnc = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required String updatedHlc,
                required String originDevice,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultEntriesCompanion.insert(
                id: id,
                type: type,
                titleEnc: titleEnc,
                noteEnc: noteEnc,
                tagsEnc: tagsEnc,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedHlc: updatedHlc,
                originDevice: originDevice,
                deletedAt: deletedAt,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VaultEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                originDevice = false,
                assetsRefs = false,
                exportRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (assetsRefs) db.assets,
                    if (exportRecordsRefs) db.exportRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (originDevice) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.originDevice,
                                    referencedTable:
                                        $$VaultEntriesTableReferences
                                            ._originDeviceTable(db),
                                    referencedColumn:
                                        $$VaultEntriesTableReferences
                                            ._originDeviceTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (assetsRefs)
                        await $_getPrefetchedData<
                          VaultEntryData,
                          $VaultEntriesTable,
                          AssetData
                        >(
                          currentTable: table,
                          referencedTable: $$VaultEntriesTableReferences
                              ._assetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VaultEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).assetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exportRecordsRefs)
                        await $_getPrefetchedData<
                          VaultEntryData,
                          $VaultEntriesTable,
                          ExportRecordData
                        >(
                          currentTable: table,
                          referencedTable: $$VaultEntriesTableReferences
                              ._exportRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VaultEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).exportRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VaultEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultEntriesTable,
      VaultEntryData,
      $$VaultEntriesTableFilterComposer,
      $$VaultEntriesTableOrderingComposer,
      $$VaultEntriesTableAnnotationComposer,
      $$VaultEntriesTableCreateCompanionBuilder,
      $$VaultEntriesTableUpdateCompanionBuilder,
      (VaultEntryData, $$VaultEntriesTableReferences),
      VaultEntryData,
      PrefetchHooks Function({
        bool originDevice,
        bool assetsRefs,
        bool exportRecordsRefs,
      })
    >;
typedef $$BlobsTableCreateCompanionBuilder =
    BlobsCompanion Function({
      required String id,
      required String storageClass,
      required String relPath,
      Value<int> envelopeVersion,
      required int keyEpoch,
      required Uint8List wrappedDek,
      required int ciphertextSize,
      required int plaintextSize,
      required Uint8List ciphertextSha256,
      required String localState,
      required DateTime createdAt,
      Value<DateTime?> lastVerifiedAt,
      Value<int> rowid,
    });
typedef $$BlobsTableUpdateCompanionBuilder =
    BlobsCompanion Function({
      Value<String> id,
      Value<String> storageClass,
      Value<String> relPath,
      Value<int> envelopeVersion,
      Value<int> keyEpoch,
      Value<Uint8List> wrappedDek,
      Value<int> ciphertextSize,
      Value<int> plaintextSize,
      Value<Uint8List> ciphertextSha256,
      Value<String> localState,
      Value<DateTime> createdAt,
      Value<DateTime?> lastVerifiedAt,
      Value<int> rowid,
    });

final class $$BlobsTableReferences
    extends BaseReferences<_$AppDatabase, $BlobsTable, BlobData> {
  $$BlobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KeyEpochsTable _keyEpochTable(_$AppDatabase db) => db.keyEpochs
      .createAlias($_aliasNameGenerator(db.blobs.keyEpoch, db.keyEpochs.epoch));

  $$KeyEpochsTableProcessedTableManager get keyEpoch {
    final $_column = $_itemColumn<int>('key_epoch')!;

    final manager = $$KeyEpochsTableTableManager(
      $_db,
      $_db.keyEpochs,
    ).filter((f) => f.epoch.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_keyEpochTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AssetVersionsTable, List<AssetVersionData>>
  _assetVersionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.assetVersions,
    aliasName: $_aliasNameGenerator(db.blobs.id, db.assetVersions.blobId),
  );

  $$AssetVersionsTableProcessedTableManager get assetVersionsRefs {
    final manager = $$AssetVersionsTableTableManager(
      $_db,
      $_db.assetVersions,
    ).filter((f) => f.blobId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetVersionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ThumbnailsTable, List<ThumbnailData>>
  _thumbnailsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.thumbnails,
    aliasName: $_aliasNameGenerator(db.blobs.id, db.thumbnails.blobId),
  );

  $$ThumbnailsTableProcessedTableManager get thumbnailsRefs {
    final manager = $$ThumbnailsTableTableManager(
      $_db,
      $_db.thumbnails,
    ).filter((f) => f.blobId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_thumbnailsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExportRecordsTable, List<ExportRecordData>>
  _exportRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exportRecords,
    aliasName: $_aliasNameGenerator(
      db.blobs.id,
      db.exportRecords.artifactBlobId,
    ),
  );

  $$ExportRecordsTableProcessedTableManager get exportRecordsRefs {
    final manager = $$ExportRecordsTableTableManager(
      $_db,
      $_db.exportRecords,
    ).filter((f) => f.artifactBlobId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_exportRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CloudObjectsTable, List<CloudObjectData>>
  _cloudObjectsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cloudObjects,
    aliasName: $_aliasNameGenerator(db.blobs.id, db.cloudObjects.blobId),
  );

  $$CloudObjectsTableProcessedTableManager get cloudObjectsRefs {
    final manager = $$CloudObjectsTableTableManager(
      $_db,
      $_db.cloudObjects,
    ).filter((f) => f.blobId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cloudObjectsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncLogSegmentsTable, List<SyncLogSegmentData>>
  _syncLogSegmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syncLogSegments,
    aliasName: $_aliasNameGenerator(db.blobs.id, db.syncLogSegments.blobId),
  );

  $$SyncLogSegmentsTableProcessedTableManager get syncLogSegmentsRefs {
    final manager = $$SyncLogSegmentsTableTableManager(
      $_db,
      $_db.syncLogSegments,
    ).filter((f) => f.blobId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _syncLogSegmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BlobsTableFilterComposer extends Composer<_$AppDatabase, $BlobsTable> {
  $$BlobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageClass => $composableBuilder(
    column: $table.storageClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relPath => $composableBuilder(
    column: $table.relPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get envelopeVersion => $composableBuilder(
    column: $table.envelopeVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get wrappedDek => $composableBuilder(
    column: $table.wrappedDek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ciphertextSize => $composableBuilder(
    column: $table.ciphertextSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plaintextSize => $composableBuilder(
    column: $table.plaintextSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get ciphertextSha256 => $composableBuilder(
    column: $table.ciphertextSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localState => $composableBuilder(
    column: $table.localState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastVerifiedAt =>
      $composableBuilder(
        column: $table.lastVerifiedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$KeyEpochsTableFilterComposer get keyEpoch {
    final $$KeyEpochsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.keyEpoch,
      referencedTable: $db.keyEpochs,
      getReferencedColumn: (t) => t.epoch,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KeyEpochsTableFilterComposer(
            $db: $db,
            $table: $db.keyEpochs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> assetVersionsRefs(
    Expression<bool> Function($$AssetVersionsTableFilterComposer f) f,
  ) {
    final $$AssetVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.blobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableFilterComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> thumbnailsRefs(
    Expression<bool> Function($$ThumbnailsTableFilterComposer f) f,
  ) {
    final $$ThumbnailsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.thumbnails,
      getReferencedColumn: (t) => t.blobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThumbnailsTableFilterComposer(
            $db: $db,
            $table: $db.thumbnails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exportRecordsRefs(
    Expression<bool> Function($$ExportRecordsTableFilterComposer f) f,
  ) {
    final $$ExportRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exportRecords,
      getReferencedColumn: (t) => t.artifactBlobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExportRecordsTableFilterComposer(
            $db: $db,
            $table: $db.exportRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cloudObjectsRefs(
    Expression<bool> Function($$CloudObjectsTableFilterComposer f) f,
  ) {
    final $$CloudObjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cloudObjects,
      getReferencedColumn: (t) => t.blobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CloudObjectsTableFilterComposer(
            $db: $db,
            $table: $db.cloudObjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncLogSegmentsRefs(
    Expression<bool> Function($$SyncLogSegmentsTableFilterComposer f) f,
  ) {
    final $$SyncLogSegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncLogSegments,
      getReferencedColumn: (t) => t.blobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncLogSegmentsTableFilterComposer(
            $db: $db,
            $table: $db.syncLogSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BlobsTableOrderingComposer
    extends Composer<_$AppDatabase, $BlobsTable> {
  $$BlobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageClass => $composableBuilder(
    column: $table.storageClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relPath => $composableBuilder(
    column: $table.relPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get envelopeVersion => $composableBuilder(
    column: $table.envelopeVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get wrappedDek => $composableBuilder(
    column: $table.wrappedDek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ciphertextSize => $composableBuilder(
    column: $table.ciphertextSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plaintextSize => $composableBuilder(
    column: $table.plaintextSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get ciphertextSha256 => $composableBuilder(
    column: $table.ciphertextSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localState => $composableBuilder(
    column: $table.localState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$KeyEpochsTableOrderingComposer get keyEpoch {
    final $$KeyEpochsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.keyEpoch,
      referencedTable: $db.keyEpochs,
      getReferencedColumn: (t) => t.epoch,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KeyEpochsTableOrderingComposer(
            $db: $db,
            $table: $db.keyEpochs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BlobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlobsTable> {
  $$BlobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storageClass => $composableBuilder(
    column: $table.storageClass,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relPath =>
      $composableBuilder(column: $table.relPath, builder: (column) => column);

  GeneratedColumn<int> get envelopeVersion => $composableBuilder(
    column: $table.envelopeVersion,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get wrappedDek => $composableBuilder(
    column: $table.wrappedDek,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ciphertextSize => $composableBuilder(
    column: $table.ciphertextSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plaintextSize => $composableBuilder(
    column: $table.plaintextSize,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get ciphertextSha256 => $composableBuilder(
    column: $table.ciphertextSha256,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localState => $composableBuilder(
    column: $table.localState,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastVerifiedAt =>
      $composableBuilder(
        column: $table.lastVerifiedAt,
        builder: (column) => column,
      );

  $$KeyEpochsTableAnnotationComposer get keyEpoch {
    final $$KeyEpochsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.keyEpoch,
      referencedTable: $db.keyEpochs,
      getReferencedColumn: (t) => t.epoch,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KeyEpochsTableAnnotationComposer(
            $db: $db,
            $table: $db.keyEpochs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> assetVersionsRefs<T extends Object>(
    Expression<T> Function($$AssetVersionsTableAnnotationComposer a) f,
  ) {
    final $$AssetVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.blobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> thumbnailsRefs<T extends Object>(
    Expression<T> Function($$ThumbnailsTableAnnotationComposer a) f,
  ) {
    final $$ThumbnailsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.thumbnails,
      getReferencedColumn: (t) => t.blobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThumbnailsTableAnnotationComposer(
            $db: $db,
            $table: $db.thumbnails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exportRecordsRefs<T extends Object>(
    Expression<T> Function($$ExportRecordsTableAnnotationComposer a) f,
  ) {
    final $$ExportRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exportRecords,
      getReferencedColumn: (t) => t.artifactBlobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExportRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.exportRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cloudObjectsRefs<T extends Object>(
    Expression<T> Function($$CloudObjectsTableAnnotationComposer a) f,
  ) {
    final $$CloudObjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cloudObjects,
      getReferencedColumn: (t) => t.blobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CloudObjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.cloudObjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncLogSegmentsRefs<T extends Object>(
    Expression<T> Function($$SyncLogSegmentsTableAnnotationComposer a) f,
  ) {
    final $$SyncLogSegmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncLogSegments,
      getReferencedColumn: (t) => t.blobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncLogSegmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.syncLogSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BlobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlobsTable,
          BlobData,
          $$BlobsTableFilterComposer,
          $$BlobsTableOrderingComposer,
          $$BlobsTableAnnotationComposer,
          $$BlobsTableCreateCompanionBuilder,
          $$BlobsTableUpdateCompanionBuilder,
          (BlobData, $$BlobsTableReferences),
          BlobData,
          PrefetchHooks Function({
            bool keyEpoch,
            bool assetVersionsRefs,
            bool thumbnailsRefs,
            bool exportRecordsRefs,
            bool cloudObjectsRefs,
            bool syncLogSegmentsRefs,
          })
        > {
  $$BlobsTableTableManager(_$AppDatabase db, $BlobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storageClass = const Value.absent(),
                Value<String> relPath = const Value.absent(),
                Value<int> envelopeVersion = const Value.absent(),
                Value<int> keyEpoch = const Value.absent(),
                Value<Uint8List> wrappedDek = const Value.absent(),
                Value<int> ciphertextSize = const Value.absent(),
                Value<int> plaintextSize = const Value.absent(),
                Value<Uint8List> ciphertextSha256 = const Value.absent(),
                Value<String> localState = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlobsCompanion(
                id: id,
                storageClass: storageClass,
                relPath: relPath,
                envelopeVersion: envelopeVersion,
                keyEpoch: keyEpoch,
                wrappedDek: wrappedDek,
                ciphertextSize: ciphertextSize,
                plaintextSize: plaintextSize,
                ciphertextSha256: ciphertextSha256,
                localState: localState,
                createdAt: createdAt,
                lastVerifiedAt: lastVerifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storageClass,
                required String relPath,
                Value<int> envelopeVersion = const Value.absent(),
                required int keyEpoch,
                required Uint8List wrappedDek,
                required int ciphertextSize,
                required int plaintextSize,
                required Uint8List ciphertextSha256,
                required String localState,
                required DateTime createdAt,
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlobsCompanion.insert(
                id: id,
                storageClass: storageClass,
                relPath: relPath,
                envelopeVersion: envelopeVersion,
                keyEpoch: keyEpoch,
                wrappedDek: wrappedDek,
                ciphertextSize: ciphertextSize,
                plaintextSize: plaintextSize,
                ciphertextSha256: ciphertextSha256,
                localState: localState,
                createdAt: createdAt,
                lastVerifiedAt: lastVerifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BlobsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                keyEpoch = false,
                assetVersionsRefs = false,
                thumbnailsRefs = false,
                exportRecordsRefs = false,
                cloudObjectsRefs = false,
                syncLogSegmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (assetVersionsRefs) db.assetVersions,
                    if (thumbnailsRefs) db.thumbnails,
                    if (exportRecordsRefs) db.exportRecords,
                    if (cloudObjectsRefs) db.cloudObjects,
                    if (syncLogSegmentsRefs) db.syncLogSegments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (keyEpoch) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.keyEpoch,
                                    referencedTable: $$BlobsTableReferences
                                        ._keyEpochTable(db),
                                    referencedColumn: $$BlobsTableReferences
                                        ._keyEpochTable(db)
                                        .epoch,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (assetVersionsRefs)
                        await $_getPrefetchedData<
                          BlobData,
                          $BlobsTable,
                          AssetVersionData
                        >(
                          currentTable: table,
                          referencedTable: $$BlobsTableReferences
                              ._assetVersionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BlobsTableReferences(
                                db,
                                table,
                                p0,
                              ).assetVersionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.blobId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (thumbnailsRefs)
                        await $_getPrefetchedData<
                          BlobData,
                          $BlobsTable,
                          ThumbnailData
                        >(
                          currentTable: table,
                          referencedTable: $$BlobsTableReferences
                              ._thumbnailsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BlobsTableReferences(
                                db,
                                table,
                                p0,
                              ).thumbnailsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.blobId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exportRecordsRefs)
                        await $_getPrefetchedData<
                          BlobData,
                          $BlobsTable,
                          ExportRecordData
                        >(
                          currentTable: table,
                          referencedTable: $$BlobsTableReferences
                              ._exportRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BlobsTableReferences(
                                db,
                                table,
                                p0,
                              ).exportRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.artifactBlobId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cloudObjectsRefs)
                        await $_getPrefetchedData<
                          BlobData,
                          $BlobsTable,
                          CloudObjectData
                        >(
                          currentTable: table,
                          referencedTable: $$BlobsTableReferences
                              ._cloudObjectsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BlobsTableReferences(
                                db,
                                table,
                                p0,
                              ).cloudObjectsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.blobId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syncLogSegmentsRefs)
                        await $_getPrefetchedData<
                          BlobData,
                          $BlobsTable,
                          SyncLogSegmentData
                        >(
                          currentTable: table,
                          referencedTable: $$BlobsTableReferences
                              ._syncLogSegmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BlobsTableReferences(
                                db,
                                table,
                                p0,
                              ).syncLogSegmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.blobId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BlobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlobsTable,
      BlobData,
      $$BlobsTableFilterComposer,
      $$BlobsTableOrderingComposer,
      $$BlobsTableAnnotationComposer,
      $$BlobsTableCreateCompanionBuilder,
      $$BlobsTableUpdateCompanionBuilder,
      (BlobData, $$BlobsTableReferences),
      BlobData,
      PrefetchHooks Function({
        bool keyEpoch,
        bool assetVersionsRefs,
        bool thumbnailsRefs,
        bool exportRecordsRefs,
        bool cloudObjectsRefs,
        bool syncLogSegmentsRefs,
      })
    >;
typedef $$AssetsTableCreateCompanionBuilder =
    AssetsCompanion Function({
      required String id,
      required String entryId,
      required String role,
      Value<int> ordinal,
      Value<String?> currentVersionId,
      required DateTime createdAt,
      required DateTime updatedAt,
      required String updatedHlc,
      required String originDevice,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$AssetsTableUpdateCompanionBuilder =
    AssetsCompanion Function({
      Value<String> id,
      Value<String> entryId,
      Value<String> role,
      Value<int> ordinal,
      Value<String?> currentVersionId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> updatedHlc,
      Value<String> originDevice,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$AssetsTableReferences
    extends BaseReferences<_$AppDatabase, $AssetsTable, AssetData> {
  $$AssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VaultEntriesTable _entryIdTable(_$AppDatabase db) => db.vaultEntries
      .createAlias($_aliasNameGenerator(db.assets.entryId, db.vaultEntries.id));

  $$VaultEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$VaultEntriesTableTableManager(
      $_db,
      $_db.vaultEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DevicesTable _originDeviceTable(_$AppDatabase db) => db.devices
      .createAlias($_aliasNameGenerator(db.assets.originDevice, db.devices.id));

  $$DevicesTableProcessedTableManager get originDevice {
    final $_column = $_itemColumn<String>('origin_device')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_originDeviceTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AssetVersionsTable, List<AssetVersionData>>
  _assetVersionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.assetVersions,
    aliasName: $_aliasNameGenerator(db.assets.id, db.assetVersions.assetId),
  );

  $$AssetVersionsTableProcessedTableManager get assetVersionsRefs {
    final manager = $$AssetVersionsTableTableManager(
      $_db,
      $_db.assetVersions,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetVersionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AssetsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentVersionId => $composableBuilder(
    column: $table.currentVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get updatedHlc => $composableBuilder(
    column: $table.updatedHlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$VaultEntriesTableFilterComposer get entryId {
    final $$VaultEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vaultEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultEntriesTableFilterComposer(
            $db: $db,
            $table: $db.vaultEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DevicesTableFilterComposer get originDevice {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> assetVersionsRefs(
    Expression<bool> Function($$AssetVersionsTableFilterComposer f) f,
  ) {
    final $$AssetVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableFilterComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentVersionId => $composableBuilder(
    column: $table.currentVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedHlc => $composableBuilder(
    column: $table.updatedHlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VaultEntriesTableOrderingComposer get entryId {
    final $$VaultEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vaultEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.vaultEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DevicesTableOrderingComposer get originDevice {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<String> get currentVersionId => $composableBuilder(
    column: $table.currentVersionId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedHlc => $composableBuilder(
    column: $table.updatedHlc,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$VaultEntriesTableAnnotationComposer get entryId {
    final $$VaultEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vaultEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.vaultEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DevicesTableAnnotationComposer get originDevice {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> assetVersionsRefs<T extends Object>(
    Expression<T> Function($$AssetVersionsTableAnnotationComposer a) f,
  ) {
    final $$AssetVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetsTable,
          AssetData,
          $$AssetsTableFilterComposer,
          $$AssetsTableOrderingComposer,
          $$AssetsTableAnnotationComposer,
          $$AssetsTableCreateCompanionBuilder,
          $$AssetsTableUpdateCompanionBuilder,
          (AssetData, $$AssetsTableReferences),
          AssetData,
          PrefetchHooks Function({
            bool entryId,
            bool originDevice,
            bool assetVersionsRefs,
          })
        > {
  $$AssetsTableTableManager(_$AppDatabase db, $AssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<String?> currentVersionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> updatedHlc = const Value.absent(),
                Value<String> originDevice = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion(
                id: id,
                entryId: entryId,
                role: role,
                ordinal: ordinal,
                currentVersionId: currentVersionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedHlc: updatedHlc,
                originDevice: originDevice,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryId,
                required String role,
                Value<int> ordinal = const Value.absent(),
                Value<String?> currentVersionId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required String updatedHlc,
                required String originDevice,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion.insert(
                id: id,
                entryId: entryId,
                role: role,
                ordinal: ordinal,
                currentVersionId: currentVersionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedHlc: updatedHlc,
                originDevice: originDevice,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AssetsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                entryId = false,
                originDevice = false,
                assetVersionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (assetVersionsRefs) db.assetVersions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (entryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.entryId,
                                    referencedTable: $$AssetsTableReferences
                                        ._entryIdTable(db),
                                    referencedColumn: $$AssetsTableReferences
                                        ._entryIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (originDevice) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.originDevice,
                                    referencedTable: $$AssetsTableReferences
                                        ._originDeviceTable(db),
                                    referencedColumn: $$AssetsTableReferences
                                        ._originDeviceTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (assetVersionsRefs)
                        await $_getPrefetchedData<
                          AssetData,
                          $AssetsTable,
                          AssetVersionData
                        >(
                          currentTable: table,
                          referencedTable: $$AssetsTableReferences
                              ._assetVersionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).assetVersionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetsTable,
      AssetData,
      $$AssetsTableFilterComposer,
      $$AssetsTableOrderingComposer,
      $$AssetsTableAnnotationComposer,
      $$AssetsTableCreateCompanionBuilder,
      $$AssetsTableUpdateCompanionBuilder,
      (AssetData, $$AssetsTableReferences),
      AssetData,
      PrefetchHooks Function({
        bool entryId,
        bool originDevice,
        bool assetVersionsRefs,
      })
    >;
typedef $$AssetVersionsTableCreateCompanionBuilder =
    AssetVersionsCompanion Function({
      required String id,
      required String assetId,
      Value<String?> parentVersionId,
      required String kind,
      required int seq,
      Value<String?> blobId,
      Value<String?> recipeJson,
      Value<int> recipeSchemaVersion,
      Value<bool> recipeDeterministic,
      required int width,
      required int height,
      required String mime,
      required Uint8List plaintextSha256,
      required int plaintextSize,
      required DateTime createdAt,
      required String createdHlc,
      required String originDevice,
      Value<DateTime?> evictedAt,
      Value<int> rowid,
    });
typedef $$AssetVersionsTableUpdateCompanionBuilder =
    AssetVersionsCompanion Function({
      Value<String> id,
      Value<String> assetId,
      Value<String?> parentVersionId,
      Value<String> kind,
      Value<int> seq,
      Value<String?> blobId,
      Value<String?> recipeJson,
      Value<int> recipeSchemaVersion,
      Value<bool> recipeDeterministic,
      Value<int> width,
      Value<int> height,
      Value<String> mime,
      Value<Uint8List> plaintextSha256,
      Value<int> plaintextSize,
      Value<DateTime> createdAt,
      Value<String> createdHlc,
      Value<String> originDevice,
      Value<DateTime?> evictedAt,
      Value<int> rowid,
    });

final class $$AssetVersionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $AssetVersionsTable, AssetVersionData> {
  $$AssetVersionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
    $_aliasNameGenerator(db.assetVersions.assetId, db.assets.id),
  );

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<String>('asset_id')!;

    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AssetVersionsTable _parentVersionIdTable(_$AppDatabase db) =>
      db.assetVersions.createAlias(
        $_aliasNameGenerator(
          db.assetVersions.parentVersionId,
          db.assetVersions.id,
        ),
      );

  $$AssetVersionsTableProcessedTableManager? get parentVersionId {
    final $_column = $_itemColumn<String>('parent_version_id');
    if ($_column == null) return null;
    final manager = $$AssetVersionsTableTableManager(
      $_db,
      $_db.assetVersions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentVersionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BlobsTable _blobIdTable(_$AppDatabase db) => db.blobs.createAlias(
    $_aliasNameGenerator(db.assetVersions.blobId, db.blobs.id),
  );

  $$BlobsTableProcessedTableManager? get blobId {
    final $_column = $_itemColumn<String>('blob_id');
    if ($_column == null) return null;
    final manager = $$BlobsTableTableManager(
      $_db,
      $_db.blobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_blobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DevicesTable _originDeviceTable(_$AppDatabase db) =>
      db.devices.createAlias(
        $_aliasNameGenerator(db.assetVersions.originDevice, db.devices.id),
      );

  $$DevicesTableProcessedTableManager get originDevice {
    final $_column = $_itemColumn<String>('origin_device')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_originDeviceTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$VersionPinsTable, List<VersionPinData>>
  _versionPinsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.versionPins,
    aliasName: $_aliasNameGenerator(
      db.assetVersions.id,
      db.versionPins.versionId,
    ),
  );

  $$VersionPinsTableProcessedTableManager get versionPinsRefs {
    final manager = $$VersionPinsTableTableManager(
      $_db,
      $_db.versionPins,
    ).filter((f) => f.versionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_versionPinsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ThumbnailsTable, List<ThumbnailData>>
  _thumbnailsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.thumbnails,
    aliasName: $_aliasNameGenerator(
      db.assetVersions.id,
      db.thumbnails.versionId,
    ),
  );

  $$ThumbnailsTableProcessedTableManager get thumbnailsRefs {
    final manager = $$ThumbnailsTableTableManager(
      $_db,
      $_db.thumbnails,
    ).filter((f) => f.versionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_thumbnailsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ExportRecordSourcesTable,
    List<ExportRecordSourceData>
  >
  _exportRecordSourcesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exportRecordSources,
        aliasName: $_aliasNameGenerator(
          db.assetVersions.id,
          db.exportRecordSources.versionId,
        ),
      );

  $$ExportRecordSourcesTableProcessedTableManager get exportRecordSourcesRefs {
    final manager = $$ExportRecordSourcesTableTableManager(
      $_db,
      $_db.exportRecordSources,
    ).filter((f) => f.versionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exportRecordSourcesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AssetVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetVersionsTable> {
  $$AssetVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeJson => $composableBuilder(
    column: $table.recipeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recipeSchemaVersion => $composableBuilder(
    column: $table.recipeSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get recipeDeterministic => $composableBuilder(
    column: $table.recipeDeterministic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get plaintextSha256 => $composableBuilder(
    column: $table.plaintextSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plaintextSize => $composableBuilder(
    column: $table.plaintextSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get createdHlc => $composableBuilder(
    column: $table.createdHlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get evictedAt =>
      $composableBuilder(
        column: $table.evictedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetVersionsTableFilterComposer get parentVersionId {
    final $$AssetVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentVersionId,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableFilterComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableFilterComposer get blobId {
    final $$BlobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableFilterComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DevicesTableFilterComposer get originDevice {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> versionPinsRefs(
    Expression<bool> Function($$VersionPinsTableFilterComposer f) f,
  ) {
    final $$VersionPinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.versionPins,
      getReferencedColumn: (t) => t.versionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VersionPinsTableFilterComposer(
            $db: $db,
            $table: $db.versionPins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> thumbnailsRefs(
    Expression<bool> Function($$ThumbnailsTableFilterComposer f) f,
  ) {
    final $$ThumbnailsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.thumbnails,
      getReferencedColumn: (t) => t.versionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThumbnailsTableFilterComposer(
            $db: $db,
            $table: $db.thumbnails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exportRecordSourcesRefs(
    Expression<bool> Function($$ExportRecordSourcesTableFilterComposer f) f,
  ) {
    final $$ExportRecordSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exportRecordSources,
      getReferencedColumn: (t) => t.versionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExportRecordSourcesTableFilterComposer(
            $db: $db,
            $table: $db.exportRecordSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetVersionsTable> {
  $$AssetVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeJson => $composableBuilder(
    column: $table.recipeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recipeSchemaVersion => $composableBuilder(
    column: $table.recipeSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get recipeDeterministic => $composableBuilder(
    column: $table.recipeDeterministic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get plaintextSha256 => $composableBuilder(
    column: $table.plaintextSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plaintextSize => $composableBuilder(
    column: $table.plaintextSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdHlc => $composableBuilder(
    column: $table.createdHlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get evictedAt => $composableBuilder(
    column: $table.evictedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableOrderingComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetVersionsTableOrderingComposer get parentVersionId {
    final $$AssetVersionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentVersionId,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableOrderingComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableOrderingComposer get blobId {
    final $$BlobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableOrderingComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DevicesTableOrderingComposer get originDevice {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetVersionsTable> {
  $$AssetVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get recipeJson => $composableBuilder(
    column: $table.recipeJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recipeSchemaVersion => $composableBuilder(
    column: $table.recipeSchemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get recipeDeterministic => $composableBuilder(
    column: $table.recipeDeterministic,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<Uint8List> get plaintextSha256 => $composableBuilder(
    column: $table.plaintextSha256,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plaintextSize => $composableBuilder(
    column: $table.plaintextSize,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdHlc => $composableBuilder(
    column: $table.createdHlc,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get evictedAt =>
      $composableBuilder(column: $table.evictedAt, builder: (column) => column);

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetVersionsTableAnnotationComposer get parentVersionId {
    final $$AssetVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentVersionId,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableAnnotationComposer get blobId {
    final $$BlobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableAnnotationComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DevicesTableAnnotationComposer get originDevice {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> versionPinsRefs<T extends Object>(
    Expression<T> Function($$VersionPinsTableAnnotationComposer a) f,
  ) {
    final $$VersionPinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.versionPins,
      getReferencedColumn: (t) => t.versionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VersionPinsTableAnnotationComposer(
            $db: $db,
            $table: $db.versionPins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> thumbnailsRefs<T extends Object>(
    Expression<T> Function($$ThumbnailsTableAnnotationComposer a) f,
  ) {
    final $$ThumbnailsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.thumbnails,
      getReferencedColumn: (t) => t.versionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThumbnailsTableAnnotationComposer(
            $db: $db,
            $table: $db.thumbnails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exportRecordSourcesRefs<T extends Object>(
    Expression<T> Function($$ExportRecordSourcesTableAnnotationComposer a) f,
  ) {
    final $$ExportRecordSourcesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exportRecordSources,
          getReferencedColumn: (t) => t.versionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExportRecordSourcesTableAnnotationComposer(
                $db: $db,
                $table: $db.exportRecordSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AssetVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetVersionsTable,
          AssetVersionData,
          $$AssetVersionsTableFilterComposer,
          $$AssetVersionsTableOrderingComposer,
          $$AssetVersionsTableAnnotationComposer,
          $$AssetVersionsTableCreateCompanionBuilder,
          $$AssetVersionsTableUpdateCompanionBuilder,
          (AssetVersionData, $$AssetVersionsTableReferences),
          AssetVersionData,
          PrefetchHooks Function({
            bool assetId,
            bool parentVersionId,
            bool blobId,
            bool originDevice,
            bool versionPinsRefs,
            bool thumbnailsRefs,
            bool exportRecordSourcesRefs,
          })
        > {
  $$AssetVersionsTableTableManager(_$AppDatabase db, $AssetVersionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<String?> parentVersionId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String?> blobId = const Value.absent(),
                Value<String?> recipeJson = const Value.absent(),
                Value<int> recipeSchemaVersion = const Value.absent(),
                Value<bool> recipeDeterministic = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<String> mime = const Value.absent(),
                Value<Uint8List> plaintextSha256 = const Value.absent(),
                Value<int> plaintextSize = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> createdHlc = const Value.absent(),
                Value<String> originDevice = const Value.absent(),
                Value<DateTime?> evictedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetVersionsCompanion(
                id: id,
                assetId: assetId,
                parentVersionId: parentVersionId,
                kind: kind,
                seq: seq,
                blobId: blobId,
                recipeJson: recipeJson,
                recipeSchemaVersion: recipeSchemaVersion,
                recipeDeterministic: recipeDeterministic,
                width: width,
                height: height,
                mime: mime,
                plaintextSha256: plaintextSha256,
                plaintextSize: plaintextSize,
                createdAt: createdAt,
                createdHlc: createdHlc,
                originDevice: originDevice,
                evictedAt: evictedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String assetId,
                Value<String?> parentVersionId = const Value.absent(),
                required String kind,
                required int seq,
                Value<String?> blobId = const Value.absent(),
                Value<String?> recipeJson = const Value.absent(),
                Value<int> recipeSchemaVersion = const Value.absent(),
                Value<bool> recipeDeterministic = const Value.absent(),
                required int width,
                required int height,
                required String mime,
                required Uint8List plaintextSha256,
                required int plaintextSize,
                required DateTime createdAt,
                required String createdHlc,
                required String originDevice,
                Value<DateTime?> evictedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetVersionsCompanion.insert(
                id: id,
                assetId: assetId,
                parentVersionId: parentVersionId,
                kind: kind,
                seq: seq,
                blobId: blobId,
                recipeJson: recipeJson,
                recipeSchemaVersion: recipeSchemaVersion,
                recipeDeterministic: recipeDeterministic,
                width: width,
                height: height,
                mime: mime,
                plaintextSha256: plaintextSha256,
                plaintextSize: plaintextSize,
                createdAt: createdAt,
                createdHlc: createdHlc,
                originDevice: originDevice,
                evictedAt: evictedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssetVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                assetId = false,
                parentVersionId = false,
                blobId = false,
                originDevice = false,
                versionPinsRefs = false,
                thumbnailsRefs = false,
                exportRecordSourcesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (versionPinsRefs) db.versionPins,
                    if (thumbnailsRefs) db.thumbnails,
                    if (exportRecordSourcesRefs) db.exportRecordSources,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (assetId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.assetId,
                                    referencedTable:
                                        $$AssetVersionsTableReferences
                                            ._assetIdTable(db),
                                    referencedColumn:
                                        $$AssetVersionsTableReferences
                                            ._assetIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (parentVersionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentVersionId,
                                    referencedTable:
                                        $$AssetVersionsTableReferences
                                            ._parentVersionIdTable(db),
                                    referencedColumn:
                                        $$AssetVersionsTableReferences
                                            ._parentVersionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (blobId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.blobId,
                                    referencedTable:
                                        $$AssetVersionsTableReferences
                                            ._blobIdTable(db),
                                    referencedColumn:
                                        $$AssetVersionsTableReferences
                                            ._blobIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (originDevice) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.originDevice,
                                    referencedTable:
                                        $$AssetVersionsTableReferences
                                            ._originDeviceTable(db),
                                    referencedColumn:
                                        $$AssetVersionsTableReferences
                                            ._originDeviceTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (versionPinsRefs)
                        await $_getPrefetchedData<
                          AssetVersionData,
                          $AssetVersionsTable,
                          VersionPinData
                        >(
                          currentTable: table,
                          referencedTable: $$AssetVersionsTableReferences
                              ._versionPinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetVersionsTableReferences(
                                db,
                                table,
                                p0,
                              ).versionPinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.versionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (thumbnailsRefs)
                        await $_getPrefetchedData<
                          AssetVersionData,
                          $AssetVersionsTable,
                          ThumbnailData
                        >(
                          currentTable: table,
                          referencedTable: $$AssetVersionsTableReferences
                              ._thumbnailsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetVersionsTableReferences(
                                db,
                                table,
                                p0,
                              ).thumbnailsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.versionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exportRecordSourcesRefs)
                        await $_getPrefetchedData<
                          AssetVersionData,
                          $AssetVersionsTable,
                          ExportRecordSourceData
                        >(
                          currentTable: table,
                          referencedTable: $$AssetVersionsTableReferences
                              ._exportRecordSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetVersionsTableReferences(
                                db,
                                table,
                                p0,
                              ).exportRecordSourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.versionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AssetVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetVersionsTable,
      AssetVersionData,
      $$AssetVersionsTableFilterComposer,
      $$AssetVersionsTableOrderingComposer,
      $$AssetVersionsTableAnnotationComposer,
      $$AssetVersionsTableCreateCompanionBuilder,
      $$AssetVersionsTableUpdateCompanionBuilder,
      (AssetVersionData, $$AssetVersionsTableReferences),
      AssetVersionData,
      PrefetchHooks Function({
        bool assetId,
        bool parentVersionId,
        bool blobId,
        bool originDevice,
        bool versionPinsRefs,
        bool thumbnailsRefs,
        bool exportRecordSourcesRefs,
      })
    >;
typedef $$VersionPinsTableCreateCompanionBuilder =
    VersionPinsCompanion Function({
      required String versionId,
      required String reason,
      Value<String> refId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$VersionPinsTableUpdateCompanionBuilder =
    VersionPinsCompanion Function({
      Value<String> versionId,
      Value<String> reason,
      Value<String> refId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$VersionPinsTableReferences
    extends BaseReferences<_$AppDatabase, $VersionPinsTable, VersionPinData> {
  $$VersionPinsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AssetVersionsTable _versionIdTable(_$AppDatabase db) =>
      db.assetVersions.createAlias(
        $_aliasNameGenerator(db.versionPins.versionId, db.assetVersions.id),
      );

  $$AssetVersionsTableProcessedTableManager get versionId {
    final $_column = $_itemColumn<String>('version_id')!;

    final manager = $$AssetVersionsTableTableManager(
      $_db,
      $_db.assetVersions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_versionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VersionPinsTableFilterComposer
    extends Composer<_$AppDatabase, $VersionPinsTable> {
  $$VersionPinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$AssetVersionsTableFilterComposer get versionId {
    final $$AssetVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableFilterComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VersionPinsTableOrderingComposer
    extends Composer<_$AppDatabase, $VersionPinsTable> {
  $$VersionPinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetVersionsTableOrderingComposer get versionId {
    final $$AssetVersionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableOrderingComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VersionPinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VersionPinsTable> {
  $$VersionPinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AssetVersionsTableAnnotationComposer get versionId {
    final $$AssetVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VersionPinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VersionPinsTable,
          VersionPinData,
          $$VersionPinsTableFilterComposer,
          $$VersionPinsTableOrderingComposer,
          $$VersionPinsTableAnnotationComposer,
          $$VersionPinsTableCreateCompanionBuilder,
          $$VersionPinsTableUpdateCompanionBuilder,
          (VersionPinData, $$VersionPinsTableReferences),
          VersionPinData,
          PrefetchHooks Function({bool versionId})
        > {
  $$VersionPinsTableTableManager(_$AppDatabase db, $VersionPinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VersionPinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VersionPinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VersionPinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> versionId = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> refId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VersionPinsCompanion(
                versionId: versionId,
                reason: reason,
                refId: refId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String versionId,
                required String reason,
                Value<String> refId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => VersionPinsCompanion.insert(
                versionId: versionId,
                reason: reason,
                refId: refId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VersionPinsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({versionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (versionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.versionId,
                                referencedTable: $$VersionPinsTableReferences
                                    ._versionIdTable(db),
                                referencedColumn: $$VersionPinsTableReferences
                                    ._versionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VersionPinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VersionPinsTable,
      VersionPinData,
      $$VersionPinsTableFilterComposer,
      $$VersionPinsTableOrderingComposer,
      $$VersionPinsTableAnnotationComposer,
      $$VersionPinsTableCreateCompanionBuilder,
      $$VersionPinsTableUpdateCompanionBuilder,
      (VersionPinData, $$VersionPinsTableReferences),
      VersionPinData,
      PrefetchHooks Function({bool versionId})
    >;
typedef $$ThumbnailsTableCreateCompanionBuilder =
    ThumbnailsCompanion Function({
      required String id,
      required String versionId,
      required String sizeClass,
      required String blobId,
      required int width,
      required int height,
      required DateTime createdAt,
      required DateTime lastAccessedAt,
      Value<int> rowid,
    });
typedef $$ThumbnailsTableUpdateCompanionBuilder =
    ThumbnailsCompanion Function({
      Value<String> id,
      Value<String> versionId,
      Value<String> sizeClass,
      Value<String> blobId,
      Value<int> width,
      Value<int> height,
      Value<DateTime> createdAt,
      Value<DateTime> lastAccessedAt,
      Value<int> rowid,
    });

final class $$ThumbnailsTableReferences
    extends BaseReferences<_$AppDatabase, $ThumbnailsTable, ThumbnailData> {
  $$ThumbnailsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AssetVersionsTable _versionIdTable(_$AppDatabase db) =>
      db.assetVersions.createAlias(
        $_aliasNameGenerator(db.thumbnails.versionId, db.assetVersions.id),
      );

  $$AssetVersionsTableProcessedTableManager get versionId {
    final $_column = $_itemColumn<String>('version_id')!;

    final manager = $$AssetVersionsTableTableManager(
      $_db,
      $_db.assetVersions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_versionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BlobsTable _blobIdTable(_$AppDatabase db) => db.blobs.createAlias(
    $_aliasNameGenerator(db.thumbnails.blobId, db.blobs.id),
  );

  $$BlobsTableProcessedTableManager get blobId {
    final $_column = $_itemColumn<String>('blob_id')!;

    final manager = $$BlobsTableTableManager(
      $_db,
      $_db.blobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_blobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ThumbnailsTableFilterComposer
    extends Composer<_$AppDatabase, $ThumbnailsTable> {
  $$ThumbnailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sizeClass => $composableBuilder(
    column: $table.sizeClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get lastAccessedAt =>
      $composableBuilder(
        column: $table.lastAccessedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$AssetVersionsTableFilterComposer get versionId {
    final $$AssetVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableFilterComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableFilterComposer get blobId {
    final $$BlobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableFilterComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ThumbnailsTableOrderingComposer
    extends Composer<_$AppDatabase, $ThumbnailsTable> {
  $$ThumbnailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sizeClass => $composableBuilder(
    column: $table.sizeClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetVersionsTableOrderingComposer get versionId {
    final $$AssetVersionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableOrderingComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableOrderingComposer get blobId {
    final $$BlobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableOrderingComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ThumbnailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThumbnailsTable> {
  $$ThumbnailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sizeClass =>
      $composableBuilder(column: $table.sizeClass, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get lastAccessedAt =>
      $composableBuilder(
        column: $table.lastAccessedAt,
        builder: (column) => column,
      );

  $$AssetVersionsTableAnnotationComposer get versionId {
    final $$AssetVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableAnnotationComposer get blobId {
    final $$BlobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableAnnotationComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ThumbnailsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ThumbnailsTable,
          ThumbnailData,
          $$ThumbnailsTableFilterComposer,
          $$ThumbnailsTableOrderingComposer,
          $$ThumbnailsTableAnnotationComposer,
          $$ThumbnailsTableCreateCompanionBuilder,
          $$ThumbnailsTableUpdateCompanionBuilder,
          (ThumbnailData, $$ThumbnailsTableReferences),
          ThumbnailData,
          PrefetchHooks Function({bool versionId, bool blobId})
        > {
  $$ThumbnailsTableTableManager(_$AppDatabase db, $ThumbnailsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThumbnailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThumbnailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThumbnailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> versionId = const Value.absent(),
                Value<String> sizeClass = const Value.absent(),
                Value<String> blobId = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastAccessedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ThumbnailsCompanion(
                id: id,
                versionId: versionId,
                sizeClass: sizeClass,
                blobId: blobId,
                width: width,
                height: height,
                createdAt: createdAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String versionId,
                required String sizeClass,
                required String blobId,
                required int width,
                required int height,
                required DateTime createdAt,
                required DateTime lastAccessedAt,
                Value<int> rowid = const Value.absent(),
              }) => ThumbnailsCompanion.insert(
                id: id,
                versionId: versionId,
                sizeClass: sizeClass,
                blobId: blobId,
                width: width,
                height: height,
                createdAt: createdAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ThumbnailsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({versionId = false, blobId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (versionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.versionId,
                                referencedTable: $$ThumbnailsTableReferences
                                    ._versionIdTable(db),
                                referencedColumn: $$ThumbnailsTableReferences
                                    ._versionIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (blobId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.blobId,
                                referencedTable: $$ThumbnailsTableReferences
                                    ._blobIdTable(db),
                                referencedColumn: $$ThumbnailsTableReferences
                                    ._blobIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ThumbnailsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ThumbnailsTable,
      ThumbnailData,
      $$ThumbnailsTableFilterComposer,
      $$ThumbnailsTableOrderingComposer,
      $$ThumbnailsTableAnnotationComposer,
      $$ThumbnailsTableCreateCompanionBuilder,
      $$ThumbnailsTableUpdateCompanionBuilder,
      (ThumbnailData, $$ThumbnailsTableReferences),
      ThumbnailData,
      PrefetchHooks Function({bool versionId, bool blobId})
    >;
typedef $$ExportRecordsTableCreateCompanionBuilder =
    ExportRecordsCompanion Function({
      required String id,
      required String entryId,
      required String requestJson,
      required int requestSchemaVersion,
      required String format,
      Value<String?> layout,
      Value<String?> paperSize,
      Value<int?> outWidth,
      Value<int?> outHeight,
      Value<int?> dpi,
      Value<int?> quality,
      Value<int?> targetBytes,
      Value<int?> maxBytes,
      Value<int?> actualBytes,
      Value<int?> pageCount,
      required String status,
      Value<String?> failureCode,
      Value<String?> warningsJson,
      Value<int?> durationMs,
      Value<String?> artifactBlobId,
      Value<bool> retainArtifact,
      Value<DateTime?> artifactExpiresAt,
      required DateTime createdAt,
      required String originDevice,
      Value<int> rowid,
    });
typedef $$ExportRecordsTableUpdateCompanionBuilder =
    ExportRecordsCompanion Function({
      Value<String> id,
      Value<String> entryId,
      Value<String> requestJson,
      Value<int> requestSchemaVersion,
      Value<String> format,
      Value<String?> layout,
      Value<String?> paperSize,
      Value<int?> outWidth,
      Value<int?> outHeight,
      Value<int?> dpi,
      Value<int?> quality,
      Value<int?> targetBytes,
      Value<int?> maxBytes,
      Value<int?> actualBytes,
      Value<int?> pageCount,
      Value<String> status,
      Value<String?> failureCode,
      Value<String?> warningsJson,
      Value<int?> durationMs,
      Value<String?> artifactBlobId,
      Value<bool> retainArtifact,
      Value<DateTime?> artifactExpiresAt,
      Value<DateTime> createdAt,
      Value<String> originDevice,
      Value<int> rowid,
    });

final class $$ExportRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExportRecordsTable, ExportRecordData> {
  $$ExportRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VaultEntriesTable _entryIdTable(_$AppDatabase db) =>
      db.vaultEntries.createAlias(
        $_aliasNameGenerator(db.exportRecords.entryId, db.vaultEntries.id),
      );

  $$VaultEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$VaultEntriesTableTableManager(
      $_db,
      $_db.vaultEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BlobsTable _artifactBlobIdTable(_$AppDatabase db) =>
      db.blobs.createAlias(
        $_aliasNameGenerator(db.exportRecords.artifactBlobId, db.blobs.id),
      );

  $$BlobsTableProcessedTableManager? get artifactBlobId {
    final $_column = $_itemColumn<String>('artifact_blob_id');
    if ($_column == null) return null;
    final manager = $$BlobsTableTableManager(
      $_db,
      $_db.blobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artifactBlobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DevicesTable _originDeviceTable(_$AppDatabase db) =>
      db.devices.createAlias(
        $_aliasNameGenerator(db.exportRecords.originDevice, db.devices.id),
      );

  $$DevicesTableProcessedTableManager get originDevice {
    final $_column = $_itemColumn<String>('origin_device')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_originDeviceTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ExportRecordSourcesTable,
    List<ExportRecordSourceData>
  >
  _exportRecordSourcesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exportRecordSources,
        aliasName: $_aliasNameGenerator(
          db.exportRecords.id,
          db.exportRecordSources.exportId,
        ),
      );

  $$ExportRecordSourcesTableProcessedTableManager get exportRecordSourcesRefs {
    final manager = $$ExportRecordSourcesTableTableManager(
      $_db,
      $_db.exportRecordSources,
    ).filter((f) => f.exportId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exportRecordSourcesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExportRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ExportRecordsTable> {
  $$ExportRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestJson => $composableBuilder(
    column: $table.requestJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requestSchemaVersion => $composableBuilder(
    column: $table.requestSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paperSize => $composableBuilder(
    column: $table.paperSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outWidth => $composableBuilder(
    column: $table.outWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outHeight => $composableBuilder(
    column: $table.outHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dpi => $composableBuilder(
    column: $table.dpi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetBytes => $composableBuilder(
    column: $table.targetBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxBytes => $composableBuilder(
    column: $table.maxBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualBytes => $composableBuilder(
    column: $table.actualBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retainArtifact => $composableBuilder(
    column: $table.retainArtifact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int>
  get artifactExpiresAt => $composableBuilder(
    column: $table.artifactExpiresAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$VaultEntriesTableFilterComposer get entryId {
    final $$VaultEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vaultEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultEntriesTableFilterComposer(
            $db: $db,
            $table: $db.vaultEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableFilterComposer get artifactBlobId {
    final $$BlobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artifactBlobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableFilterComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DevicesTableFilterComposer get originDevice {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> exportRecordSourcesRefs(
    Expression<bool> Function($$ExportRecordSourcesTableFilterComposer f) f,
  ) {
    final $$ExportRecordSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exportRecordSources,
      getReferencedColumn: (t) => t.exportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExportRecordSourcesTableFilterComposer(
            $db: $db,
            $table: $db.exportRecordSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExportRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExportRecordsTable> {
  $$ExportRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestJson => $composableBuilder(
    column: $table.requestJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requestSchemaVersion => $composableBuilder(
    column: $table.requestSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paperSize => $composableBuilder(
    column: $table.paperSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outWidth => $composableBuilder(
    column: $table.outWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outHeight => $composableBuilder(
    column: $table.outHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dpi => $composableBuilder(
    column: $table.dpi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetBytes => $composableBuilder(
    column: $table.targetBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxBytes => $composableBuilder(
    column: $table.maxBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualBytes => $composableBuilder(
    column: $table.actualBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retainArtifact => $composableBuilder(
    column: $table.retainArtifact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get artifactExpiresAt => $composableBuilder(
    column: $table.artifactExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VaultEntriesTableOrderingComposer get entryId {
    final $$VaultEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vaultEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.vaultEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableOrderingComposer get artifactBlobId {
    final $$BlobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artifactBlobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableOrderingComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DevicesTableOrderingComposer get originDevice {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExportRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExportRecordsTable> {
  $$ExportRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get requestJson => $composableBuilder(
    column: $table.requestJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get requestSchemaVersion => $composableBuilder(
    column: $table.requestSchemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get layout =>
      $composableBuilder(column: $table.layout, builder: (column) => column);

  GeneratedColumn<String> get paperSize =>
      $composableBuilder(column: $table.paperSize, builder: (column) => column);

  GeneratedColumn<int> get outWidth =>
      $composableBuilder(column: $table.outWidth, builder: (column) => column);

  GeneratedColumn<int> get outHeight =>
      $composableBuilder(column: $table.outHeight, builder: (column) => column);

  GeneratedColumn<int> get dpi =>
      $composableBuilder(column: $table.dpi, builder: (column) => column);

  GeneratedColumn<int> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<int> get targetBytes => $composableBuilder(
    column: $table.targetBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxBytes =>
      $composableBuilder(column: $table.maxBytes, builder: (column) => column);

  GeneratedColumn<int> get actualBytes => $composableBuilder(
    column: $table.actualBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get retainArtifact => $composableBuilder(
    column: $table.retainArtifact,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get artifactExpiresAt =>
      $composableBuilder(
        column: $table.artifactExpiresAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$VaultEntriesTableAnnotationComposer get entryId {
    final $$VaultEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vaultEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.vaultEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableAnnotationComposer get artifactBlobId {
    final $$BlobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artifactBlobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableAnnotationComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DevicesTableAnnotationComposer get originDevice {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> exportRecordSourcesRefs<T extends Object>(
    Expression<T> Function($$ExportRecordSourcesTableAnnotationComposer a) f,
  ) {
    final $$ExportRecordSourcesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exportRecordSources,
          getReferencedColumn: (t) => t.exportId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExportRecordSourcesTableAnnotationComposer(
                $db: $db,
                $table: $db.exportRecordSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExportRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExportRecordsTable,
          ExportRecordData,
          $$ExportRecordsTableFilterComposer,
          $$ExportRecordsTableOrderingComposer,
          $$ExportRecordsTableAnnotationComposer,
          $$ExportRecordsTableCreateCompanionBuilder,
          $$ExportRecordsTableUpdateCompanionBuilder,
          (ExportRecordData, $$ExportRecordsTableReferences),
          ExportRecordData,
          PrefetchHooks Function({
            bool entryId,
            bool artifactBlobId,
            bool originDevice,
            bool exportRecordSourcesRefs,
          })
        > {
  $$ExportRecordsTableTableManager(_$AppDatabase db, $ExportRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExportRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExportRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExportRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String> requestJson = const Value.absent(),
                Value<int> requestSchemaVersion = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String?> layout = const Value.absent(),
                Value<String?> paperSize = const Value.absent(),
                Value<int?> outWidth = const Value.absent(),
                Value<int?> outHeight = const Value.absent(),
                Value<int?> dpi = const Value.absent(),
                Value<int?> quality = const Value.absent(),
                Value<int?> targetBytes = const Value.absent(),
                Value<int?> maxBytes = const Value.absent(),
                Value<int?> actualBytes = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                Value<String?> warningsJson = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> artifactBlobId = const Value.absent(),
                Value<bool> retainArtifact = const Value.absent(),
                Value<DateTime?> artifactExpiresAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> originDevice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExportRecordsCompanion(
                id: id,
                entryId: entryId,
                requestJson: requestJson,
                requestSchemaVersion: requestSchemaVersion,
                format: format,
                layout: layout,
                paperSize: paperSize,
                outWidth: outWidth,
                outHeight: outHeight,
                dpi: dpi,
                quality: quality,
                targetBytes: targetBytes,
                maxBytes: maxBytes,
                actualBytes: actualBytes,
                pageCount: pageCount,
                status: status,
                failureCode: failureCode,
                warningsJson: warningsJson,
                durationMs: durationMs,
                artifactBlobId: artifactBlobId,
                retainArtifact: retainArtifact,
                artifactExpiresAt: artifactExpiresAt,
                createdAt: createdAt,
                originDevice: originDevice,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryId,
                required String requestJson,
                required int requestSchemaVersion,
                required String format,
                Value<String?> layout = const Value.absent(),
                Value<String?> paperSize = const Value.absent(),
                Value<int?> outWidth = const Value.absent(),
                Value<int?> outHeight = const Value.absent(),
                Value<int?> dpi = const Value.absent(),
                Value<int?> quality = const Value.absent(),
                Value<int?> targetBytes = const Value.absent(),
                Value<int?> maxBytes = const Value.absent(),
                Value<int?> actualBytes = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                required String status,
                Value<String?> failureCode = const Value.absent(),
                Value<String?> warningsJson = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> artifactBlobId = const Value.absent(),
                Value<bool> retainArtifact = const Value.absent(),
                Value<DateTime?> artifactExpiresAt = const Value.absent(),
                required DateTime createdAt,
                required String originDevice,
                Value<int> rowid = const Value.absent(),
              }) => ExportRecordsCompanion.insert(
                id: id,
                entryId: entryId,
                requestJson: requestJson,
                requestSchemaVersion: requestSchemaVersion,
                format: format,
                layout: layout,
                paperSize: paperSize,
                outWidth: outWidth,
                outHeight: outHeight,
                dpi: dpi,
                quality: quality,
                targetBytes: targetBytes,
                maxBytes: maxBytes,
                actualBytes: actualBytes,
                pageCount: pageCount,
                status: status,
                failureCode: failureCode,
                warningsJson: warningsJson,
                durationMs: durationMs,
                artifactBlobId: artifactBlobId,
                retainArtifact: retainArtifact,
                artifactExpiresAt: artifactExpiresAt,
                createdAt: createdAt,
                originDevice: originDevice,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExportRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                entryId = false,
                artifactBlobId = false,
                originDevice = false,
                exportRecordSourcesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (exportRecordSourcesRefs) db.exportRecordSources,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (entryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.entryId,
                                    referencedTable:
                                        $$ExportRecordsTableReferences
                                            ._entryIdTable(db),
                                    referencedColumn:
                                        $$ExportRecordsTableReferences
                                            ._entryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (artifactBlobId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.artifactBlobId,
                                    referencedTable:
                                        $$ExportRecordsTableReferences
                                            ._artifactBlobIdTable(db),
                                    referencedColumn:
                                        $$ExportRecordsTableReferences
                                            ._artifactBlobIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (originDevice) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.originDevice,
                                    referencedTable:
                                        $$ExportRecordsTableReferences
                                            ._originDeviceTable(db),
                                    referencedColumn:
                                        $$ExportRecordsTableReferences
                                            ._originDeviceTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (exportRecordSourcesRefs)
                        await $_getPrefetchedData<
                          ExportRecordData,
                          $ExportRecordsTable,
                          ExportRecordSourceData
                        >(
                          currentTable: table,
                          referencedTable: $$ExportRecordsTableReferences
                              ._exportRecordSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExportRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).exportRecordSourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exportId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExportRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExportRecordsTable,
      ExportRecordData,
      $$ExportRecordsTableFilterComposer,
      $$ExportRecordsTableOrderingComposer,
      $$ExportRecordsTableAnnotationComposer,
      $$ExportRecordsTableCreateCompanionBuilder,
      $$ExportRecordsTableUpdateCompanionBuilder,
      (ExportRecordData, $$ExportRecordsTableReferences),
      ExportRecordData,
      PrefetchHooks Function({
        bool entryId,
        bool artifactBlobId,
        bool originDevice,
        bool exportRecordSourcesRefs,
      })
    >;
typedef $$ExportRecordSourcesTableCreateCompanionBuilder =
    ExportRecordSourcesCompanion Function({
      required String exportId,
      required int ordinal,
      required String versionId,
      Value<int> rowid,
    });
typedef $$ExportRecordSourcesTableUpdateCompanionBuilder =
    ExportRecordSourcesCompanion Function({
      Value<String> exportId,
      Value<int> ordinal,
      Value<String> versionId,
      Value<int> rowid,
    });

final class $$ExportRecordSourcesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExportRecordSourcesTable,
          ExportRecordSourceData
        > {
  $$ExportRecordSourcesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExportRecordsTable _exportIdTable(_$AppDatabase db) =>
      db.exportRecords.createAlias(
        $_aliasNameGenerator(
          db.exportRecordSources.exportId,
          db.exportRecords.id,
        ),
      );

  $$ExportRecordsTableProcessedTableManager get exportId {
    final $_column = $_itemColumn<String>('export_id')!;

    final manager = $$ExportRecordsTableTableManager(
      $_db,
      $_db.exportRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exportIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AssetVersionsTable _versionIdTable(_$AppDatabase db) =>
      db.assetVersions.createAlias(
        $_aliasNameGenerator(
          db.exportRecordSources.versionId,
          db.assetVersions.id,
        ),
      );

  $$AssetVersionsTableProcessedTableManager get versionId {
    final $_column = $_itemColumn<String>('version_id')!;

    final manager = $$AssetVersionsTableTableManager(
      $_db,
      $_db.assetVersions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_versionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExportRecordSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $ExportRecordSourcesTable> {
  $$ExportRecordSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  $$ExportRecordsTableFilterComposer get exportId {
    final $$ExportRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exportId,
      referencedTable: $db.exportRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExportRecordsTableFilterComposer(
            $db: $db,
            $table: $db.exportRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetVersionsTableFilterComposer get versionId {
    final $$AssetVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableFilterComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExportRecordSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExportRecordSourcesTable> {
  $$ExportRecordSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExportRecordsTableOrderingComposer get exportId {
    final $$ExportRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exportId,
      referencedTable: $db.exportRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExportRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.exportRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetVersionsTableOrderingComposer get versionId {
    final $$AssetVersionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableOrderingComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExportRecordSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExportRecordSourcesTable> {
  $$ExportRecordSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  $$ExportRecordsTableAnnotationComposer get exportId {
    final $$ExportRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exportId,
      referencedTable: $db.exportRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExportRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.exportRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetVersionsTableAnnotationComposer get versionId {
    final $$AssetVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.assetVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.assetVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExportRecordSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExportRecordSourcesTable,
          ExportRecordSourceData,
          $$ExportRecordSourcesTableFilterComposer,
          $$ExportRecordSourcesTableOrderingComposer,
          $$ExportRecordSourcesTableAnnotationComposer,
          $$ExportRecordSourcesTableCreateCompanionBuilder,
          $$ExportRecordSourcesTableUpdateCompanionBuilder,
          (ExportRecordSourceData, $$ExportRecordSourcesTableReferences),
          ExportRecordSourceData,
          PrefetchHooks Function({bool exportId, bool versionId})
        > {
  $$ExportRecordSourcesTableTableManager(
    _$AppDatabase db,
    $ExportRecordSourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExportRecordSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExportRecordSourcesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExportRecordSourcesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> exportId = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<String> versionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExportRecordSourcesCompanion(
                exportId: exportId,
                ordinal: ordinal,
                versionId: versionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exportId,
                required int ordinal,
                required String versionId,
                Value<int> rowid = const Value.absent(),
              }) => ExportRecordSourcesCompanion.insert(
                exportId: exportId,
                ordinal: ordinal,
                versionId: versionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExportRecordSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exportId = false, versionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exportId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exportId,
                                referencedTable:
                                    $$ExportRecordSourcesTableReferences
                                        ._exportIdTable(db),
                                referencedColumn:
                                    $$ExportRecordSourcesTableReferences
                                        ._exportIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (versionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.versionId,
                                referencedTable:
                                    $$ExportRecordSourcesTableReferences
                                        ._versionIdTable(db),
                                referencedColumn:
                                    $$ExportRecordSourcesTableReferences
                                        ._versionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExportRecordSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExportRecordSourcesTable,
      ExportRecordSourceData,
      $$ExportRecordSourcesTableFilterComposer,
      $$ExportRecordSourcesTableOrderingComposer,
      $$ExportRecordSourcesTableAnnotationComposer,
      $$ExportRecordSourcesTableCreateCompanionBuilder,
      $$ExportRecordSourcesTableUpdateCompanionBuilder,
      (ExportRecordSourceData, $$ExportRecordSourcesTableReferences),
      ExportRecordSourceData,
      PrefetchHooks Function({bool exportId, bool versionId})
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String opType,
      required String targetKind,
      required String targetId,
      required String idempotencyKey,
      Value<int> priority,
      Value<String> state,
      Value<int> attempts,
      required DateTime nextAttemptAt,
      Value<String?> lastErrorCode,
      Value<DateTime?> lastErrorAt,
      Value<String?> resumeToken,
      Value<int> bytesDone,
      Value<int?> bytesTotal,
      Value<String?> leaseOwner,
      Value<DateTime?> leaseExpiresAt,
      required DateTime createdAt,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> opType,
      Value<String> targetKind,
      Value<String> targetId,
      Value<String> idempotencyKey,
      Value<int> priority,
      Value<String> state,
      Value<int> attempts,
      Value<DateTime> nextAttemptAt,
      Value<String?> lastErrorCode,
      Value<DateTime?> lastErrorAt,
      Value<String?> resumeToken,
      Value<int> bytesDone,
      Value<int?> bytesTotal,
      Value<String?> leaseOwner,
      Value<DateTime?> leaseExpiresAt,
      Value<DateTime> createdAt,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetKind => $composableBuilder(
    column: $table.targetKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get nextAttemptAt =>
      $composableBuilder(
        column: $table.nextAttemptAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastErrorAt =>
      $composableBuilder(
        column: $table.lastErrorAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get resumeToken => $composableBuilder(
    column: $table.resumeToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesDone => $composableBuilder(
    column: $table.bytesDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesTotal => $composableBuilder(
    column: $table.bytesTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get leaseOwner => $composableBuilder(
    column: $table.leaseOwner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get leaseExpiresAt =>
      $composableBuilder(
        column: $table.leaseExpiresAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetKind => $composableBuilder(
    column: $table.targetKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastErrorAt => $composableBuilder(
    column: $table.lastErrorAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resumeToken => $composableBuilder(
    column: $table.resumeToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesDone => $composableBuilder(
    column: $table.bytesDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesTotal => $composableBuilder(
    column: $table.bytesTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get leaseOwner => $composableBuilder(
    column: $table.leaseOwner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);

  GeneratedColumn<String> get targetKind => $composableBuilder(
    column: $table.targetKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get nextAttemptAt =>
      $composableBuilder(
        column: $table.nextAttemptAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastErrorAt =>
      $composableBuilder(
        column: $table.lastErrorAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get resumeToken => $composableBuilder(
    column: $table.resumeToken,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytesDone =>
      $composableBuilder(column: $table.bytesDone, builder: (column) => column);

  GeneratedColumn<int> get bytesTotal => $composableBuilder(
    column: $table.bytesTotal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get leaseOwner => $composableBuilder(
    column: $table.leaseOwner,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get leaseExpiresAt =>
      $composableBuilder(
        column: $table.leaseExpiresAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> opType = const Value.absent(),
                Value<String> targetKind = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<DateTime?> lastErrorAt = const Value.absent(),
                Value<String?> resumeToken = const Value.absent(),
                Value<int> bytesDone = const Value.absent(),
                Value<int?> bytesTotal = const Value.absent(),
                Value<String?> leaseOwner = const Value.absent(),
                Value<DateTime?> leaseExpiresAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                opType: opType,
                targetKind: targetKind,
                targetId: targetId,
                idempotencyKey: idempotencyKey,
                priority: priority,
                state: state,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastErrorCode: lastErrorCode,
                lastErrorAt: lastErrorAt,
                resumeToken: resumeToken,
                bytesDone: bytesDone,
                bytesTotal: bytesTotal,
                leaseOwner: leaseOwner,
                leaseExpiresAt: leaseExpiresAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String opType,
                required String targetKind,
                required String targetId,
                required String idempotencyKey,
                Value<int> priority = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required DateTime nextAttemptAt,
                Value<String?> lastErrorCode = const Value.absent(),
                Value<DateTime?> lastErrorAt = const Value.absent(),
                Value<String?> resumeToken = const Value.absent(),
                Value<int> bytesDone = const Value.absent(),
                Value<int?> bytesTotal = const Value.absent(),
                Value<String?> leaseOwner = const Value.absent(),
                Value<DateTime?> leaseExpiresAt = const Value.absent(),
                required DateTime createdAt,
              }) => SyncQueueCompanion.insert(
                id: id,
                opType: opType,
                targetKind: targetKind,
                targetId: targetId,
                idempotencyKey: idempotencyKey,
                priority: priority,
                state: state,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastErrorCode: lastErrorCode,
                lastErrorAt: lastErrorAt,
                resumeToken: resumeToken,
                bytesDone: bytesDone,
                bytesTotal: bytesTotal,
                leaseOwner: leaseOwner,
                leaseExpiresAt: leaseExpiresAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$CloudObjectsTableCreateCompanionBuilder =
    CloudObjectsCompanion Function({
      required String blobId,
      Value<String?> remoteId,
      required String remoteName,
      Value<int?> remoteSize,
      Value<String?> remoteChecksum,
      required Uint8List ciphertextSha256,
      required int keyEpoch,
      required String state,
      Value<DateTime?> uploadedAt,
      Value<DateTime?> verifiedAt,
      Value<int> rowid,
    });
typedef $$CloudObjectsTableUpdateCompanionBuilder =
    CloudObjectsCompanion Function({
      Value<String> blobId,
      Value<String?> remoteId,
      Value<String> remoteName,
      Value<int?> remoteSize,
      Value<String?> remoteChecksum,
      Value<Uint8List> ciphertextSha256,
      Value<int> keyEpoch,
      Value<String> state,
      Value<DateTime?> uploadedAt,
      Value<DateTime?> verifiedAt,
      Value<int> rowid,
    });

final class $$CloudObjectsTableReferences
    extends BaseReferences<_$AppDatabase, $CloudObjectsTable, CloudObjectData> {
  $$CloudObjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BlobsTable _blobIdTable(_$AppDatabase db) => db.blobs.createAlias(
    $_aliasNameGenerator(db.cloudObjects.blobId, db.blobs.id),
  );

  $$BlobsTableProcessedTableManager get blobId {
    final $_column = $_itemColumn<String>('blob_id')!;

    final manager = $$BlobsTableTableManager(
      $_db,
      $_db.blobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_blobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CloudObjectsTableFilterComposer
    extends Composer<_$AppDatabase, $CloudObjectsTable> {
  $$CloudObjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteName => $composableBuilder(
    column: $table.remoteName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteSize => $composableBuilder(
    column: $table.remoteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteChecksum => $composableBuilder(
    column: $table.remoteChecksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get ciphertextSha256 => $composableBuilder(
    column: $table.ciphertextSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get keyEpoch => $composableBuilder(
    column: $table.keyEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get uploadedAt =>
      $composableBuilder(
        column: $table.uploadedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get verifiedAt =>
      $composableBuilder(
        column: $table.verifiedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$BlobsTableFilterComposer get blobId {
    final $$BlobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableFilterComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CloudObjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $CloudObjectsTable> {
  $$CloudObjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteName => $composableBuilder(
    column: $table.remoteName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteSize => $composableBuilder(
    column: $table.remoteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteChecksum => $composableBuilder(
    column: $table.remoteChecksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get ciphertextSha256 => $composableBuilder(
    column: $table.ciphertextSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get keyEpoch => $composableBuilder(
    column: $table.keyEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uploadedAt => $composableBuilder(
    column: $table.uploadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BlobsTableOrderingComposer get blobId {
    final $$BlobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableOrderingComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CloudObjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CloudObjectsTable> {
  $$CloudObjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get remoteName => $composableBuilder(
    column: $table.remoteName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteSize => $composableBuilder(
    column: $table.remoteSize,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteChecksum => $composableBuilder(
    column: $table.remoteChecksum,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get ciphertextSha256 => $composableBuilder(
    column: $table.ciphertextSha256,
    builder: (column) => column,
  );

  GeneratedColumn<int> get keyEpoch =>
      $composableBuilder(column: $table.keyEpoch, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get uploadedAt =>
      $composableBuilder(
        column: $table.uploadedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, int> get verifiedAt =>
      $composableBuilder(
        column: $table.verifiedAt,
        builder: (column) => column,
      );

  $$BlobsTableAnnotationComposer get blobId {
    final $$BlobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableAnnotationComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CloudObjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CloudObjectsTable,
          CloudObjectData,
          $$CloudObjectsTableFilterComposer,
          $$CloudObjectsTableOrderingComposer,
          $$CloudObjectsTableAnnotationComposer,
          $$CloudObjectsTableCreateCompanionBuilder,
          $$CloudObjectsTableUpdateCompanionBuilder,
          (CloudObjectData, $$CloudObjectsTableReferences),
          CloudObjectData,
          PrefetchHooks Function({bool blobId})
        > {
  $$CloudObjectsTableTableManager(_$AppDatabase db, $CloudObjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CloudObjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CloudObjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CloudObjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> blobId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> remoteName = const Value.absent(),
                Value<int?> remoteSize = const Value.absent(),
                Value<String?> remoteChecksum = const Value.absent(),
                Value<Uint8List> ciphertextSha256 = const Value.absent(),
                Value<int> keyEpoch = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<DateTime?> uploadedAt = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CloudObjectsCompanion(
                blobId: blobId,
                remoteId: remoteId,
                remoteName: remoteName,
                remoteSize: remoteSize,
                remoteChecksum: remoteChecksum,
                ciphertextSha256: ciphertextSha256,
                keyEpoch: keyEpoch,
                state: state,
                uploadedAt: uploadedAt,
                verifiedAt: verifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String blobId,
                Value<String?> remoteId = const Value.absent(),
                required String remoteName,
                Value<int?> remoteSize = const Value.absent(),
                Value<String?> remoteChecksum = const Value.absent(),
                required Uint8List ciphertextSha256,
                required int keyEpoch,
                required String state,
                Value<DateTime?> uploadedAt = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CloudObjectsCompanion.insert(
                blobId: blobId,
                remoteId: remoteId,
                remoteName: remoteName,
                remoteSize: remoteSize,
                remoteChecksum: remoteChecksum,
                ciphertextSha256: ciphertextSha256,
                keyEpoch: keyEpoch,
                state: state,
                uploadedAt: uploadedAt,
                verifiedAt: verifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CloudObjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({blobId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (blobId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.blobId,
                                referencedTable: $$CloudObjectsTableReferences
                                    ._blobIdTable(db),
                                referencedColumn: $$CloudObjectsTableReferences
                                    ._blobIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CloudObjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CloudObjectsTable,
      CloudObjectData,
      $$CloudObjectsTableFilterComposer,
      $$CloudObjectsTableOrderingComposer,
      $$CloudObjectsTableAnnotationComposer,
      $$CloudObjectsTableCreateCompanionBuilder,
      $$CloudObjectsTableUpdateCompanionBuilder,
      (CloudObjectData, $$CloudObjectsTableReferences),
      CloudObjectData,
      PrefetchHooks Function({bool blobId})
    >;
typedef $$SyncLogSegmentsTableCreateCompanionBuilder =
    SyncLogSegmentsCompanion Function({
      required String deviceId,
      required int seq,
      Value<String?> remoteId,
      required String remoteName,
      Value<String?> blobId,
      Value<int> opCount,
      Value<String?> hlcLow,
      Value<String?> hlcHigh,
      Value<DateTime?> sealedAt,
      Value<DateTime?> uploadedAt,
      Value<DateTime?> appliedAt,
      Value<int> rowid,
    });
typedef $$SyncLogSegmentsTableUpdateCompanionBuilder =
    SyncLogSegmentsCompanion Function({
      Value<String> deviceId,
      Value<int> seq,
      Value<String?> remoteId,
      Value<String> remoteName,
      Value<String?> blobId,
      Value<int> opCount,
      Value<String?> hlcLow,
      Value<String?> hlcHigh,
      Value<DateTime?> sealedAt,
      Value<DateTime?> uploadedAt,
      Value<DateTime?> appliedAt,
      Value<int> rowid,
    });

final class $$SyncLogSegmentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SyncLogSegmentsTable,
          SyncLogSegmentData
        > {
  $$SyncLogSegmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DevicesTable _deviceIdTable(_$AppDatabase db) =>
      db.devices.createAlias(
        $_aliasNameGenerator(db.syncLogSegments.deviceId, db.devices.id),
      );

  $$DevicesTableProcessedTableManager get deviceId {
    final $_column = $_itemColumn<String>('device_id')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BlobsTable _blobIdTable(_$AppDatabase db) => db.blobs.createAlias(
    $_aliasNameGenerator(db.syncLogSegments.blobId, db.blobs.id),
  );

  $$BlobsTableProcessedTableManager? get blobId {
    final $_column = $_itemColumn<String>('blob_id');
    if ($_column == null) return null;
    final manager = $$BlobsTableTableManager(
      $_db,
      $_db.blobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_blobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncLogSegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncLogSegmentsTable> {
  $$SyncLogSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteName => $composableBuilder(
    column: $table.remoteName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get opCount => $composableBuilder(
    column: $table.opCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlcLow => $composableBuilder(
    column: $table.hlcLow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlcHigh => $composableBuilder(
    column: $table.hlcHigh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get sealedAt =>
      $composableBuilder(
        column: $table.sealedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get uploadedAt =>
      $composableBuilder(
        column: $table.uploadedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get appliedAt =>
      $composableBuilder(
        column: $table.appliedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableFilterComposer get blobId {
    final $$BlobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableFilterComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncLogSegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncLogSegmentsTable> {
  $$SyncLogSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteName => $composableBuilder(
    column: $table.remoteName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get opCount => $composableBuilder(
    column: $table.opCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlcLow => $composableBuilder(
    column: $table.hlcLow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlcHigh => $composableBuilder(
    column: $table.hlcHigh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sealedAt => $composableBuilder(
    column: $table.sealedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uploadedAt => $composableBuilder(
    column: $table.uploadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableOrderingComposer get blobId {
    final $$BlobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableOrderingComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncLogSegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncLogSegmentsTable> {
  $$SyncLogSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get remoteName => $composableBuilder(
    column: $table.remoteName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get opCount =>
      $composableBuilder(column: $table.opCount, builder: (column) => column);

  GeneratedColumn<String> get hlcLow =>
      $composableBuilder(column: $table.hlcLow, builder: (column) => column);

  GeneratedColumn<String> get hlcHigh =>
      $composableBuilder(column: $table.hlcHigh, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get sealedAt =>
      $composableBuilder(column: $table.sealedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get uploadedAt =>
      $composableBuilder(
        column: $table.uploadedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, int> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableAnnotationComposer get blobId {
    final $$BlobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableAnnotationComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncLogSegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncLogSegmentsTable,
          SyncLogSegmentData,
          $$SyncLogSegmentsTableFilterComposer,
          $$SyncLogSegmentsTableOrderingComposer,
          $$SyncLogSegmentsTableAnnotationComposer,
          $$SyncLogSegmentsTableCreateCompanionBuilder,
          $$SyncLogSegmentsTableUpdateCompanionBuilder,
          (SyncLogSegmentData, $$SyncLogSegmentsTableReferences),
          SyncLogSegmentData,
          PrefetchHooks Function({bool deviceId, bool blobId})
        > {
  $$SyncLogSegmentsTableTableManager(
    _$AppDatabase db,
    $SyncLogSegmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLogSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLogSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLogSegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> remoteName = const Value.absent(),
                Value<String?> blobId = const Value.absent(),
                Value<int> opCount = const Value.absent(),
                Value<String?> hlcLow = const Value.absent(),
                Value<String?> hlcHigh = const Value.absent(),
                Value<DateTime?> sealedAt = const Value.absent(),
                Value<DateTime?> uploadedAt = const Value.absent(),
                Value<DateTime?> appliedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncLogSegmentsCompanion(
                deviceId: deviceId,
                seq: seq,
                remoteId: remoteId,
                remoteName: remoteName,
                blobId: blobId,
                opCount: opCount,
                hlcLow: hlcLow,
                hlcHigh: hlcHigh,
                sealedAt: sealedAt,
                uploadedAt: uploadedAt,
                appliedAt: appliedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int seq,
                Value<String?> remoteId = const Value.absent(),
                required String remoteName,
                Value<String?> blobId = const Value.absent(),
                Value<int> opCount = const Value.absent(),
                Value<String?> hlcLow = const Value.absent(),
                Value<String?> hlcHigh = const Value.absent(),
                Value<DateTime?> sealedAt = const Value.absent(),
                Value<DateTime?> uploadedAt = const Value.absent(),
                Value<DateTime?> appliedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncLogSegmentsCompanion.insert(
                deviceId: deviceId,
                seq: seq,
                remoteId: remoteId,
                remoteName: remoteName,
                blobId: blobId,
                opCount: opCount,
                hlcLow: hlcLow,
                hlcHigh: hlcHigh,
                sealedAt: sealedAt,
                uploadedAt: uploadedAt,
                appliedAt: appliedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyncLogSegmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deviceId = false, blobId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deviceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deviceId,
                                referencedTable:
                                    $$SyncLogSegmentsTableReferences
                                        ._deviceIdTable(db),
                                referencedColumn:
                                    $$SyncLogSegmentsTableReferences
                                        ._deviceIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (blobId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.blobId,
                                referencedTable:
                                    $$SyncLogSegmentsTableReferences
                                        ._blobIdTable(db),
                                referencedColumn:
                                    $$SyncLogSegmentsTableReferences
                                        ._blobIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncLogSegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncLogSegmentsTable,
      SyncLogSegmentData,
      $$SyncLogSegmentsTableFilterComposer,
      $$SyncLogSegmentsTableOrderingComposer,
      $$SyncLogSegmentsTableAnnotationComposer,
      $$SyncLogSegmentsTableCreateCompanionBuilder,
      $$SyncLogSegmentsTableUpdateCompanionBuilder,
      (SyncLogSegmentData, $$SyncLogSegmentsTableReferences),
      SyncLogSegmentData,
      PrefetchHooks Function({bool deviceId, bool blobId})
    >;
typedef $$SyncLogOpsTableCreateCompanionBuilder =
    SyncLogOpsCompanion Function({
      Value<int> id,
      required String deviceId,
      required String opJson,
      required String hlc,
      required int seq,
    });
typedef $$SyncLogOpsTableUpdateCompanionBuilder =
    SyncLogOpsCompanion Function({
      Value<int> id,
      Value<String> deviceId,
      Value<String> opJson,
      Value<String> hlc,
      Value<int> seq,
    });

class $$SyncLogOpsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncLogOpsTable> {
  $$SyncLogOpsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opJson => $composableBuilder(
    column: $table.opJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncLogOpsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncLogOpsTable> {
  $$SyncLogOpsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opJson => $composableBuilder(
    column: $table.opJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncLogOpsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncLogOpsTable> {
  $$SyncLogOpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get opJson =>
      $composableBuilder(column: $table.opJson, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$SyncLogOpsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncLogOpsTable,
          SyncLogOpData,
          $$SyncLogOpsTableFilterComposer,
          $$SyncLogOpsTableOrderingComposer,
          $$SyncLogOpsTableAnnotationComposer,
          $$SyncLogOpsTableCreateCompanionBuilder,
          $$SyncLogOpsTableUpdateCompanionBuilder,
          (
            SyncLogOpData,
            BaseReferences<_$AppDatabase, $SyncLogOpsTable, SyncLogOpData>,
          ),
          SyncLogOpData,
          PrefetchHooks Function()
        > {
  $$SyncLogOpsTableTableManager(_$AppDatabase db, $SyncLogOpsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLogOpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLogOpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLogOpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> opJson = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<int> seq = const Value.absent(),
              }) => SyncLogOpsCompanion(
                id: id,
                deviceId: deviceId,
                opJson: opJson,
                hlc: hlc,
                seq: seq,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deviceId,
                required String opJson,
                required String hlc,
                required int seq,
              }) => SyncLogOpsCompanion.insert(
                id: id,
                deviceId: deviceId,
                opJson: opJson,
                hlc: hlc,
                seq: seq,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncLogOpsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncLogOpsTable,
      SyncLogOpData,
      $$SyncLogOpsTableFilterComposer,
      $$SyncLogOpsTableOrderingComposer,
      $$SyncLogOpsTableAnnotationComposer,
      $$SyncLogOpsTableCreateCompanionBuilder,
      $$SyncLogOpsTableUpdateCompanionBuilder,
      (
        SyncLogOpData,
        BaseReferences<_$AppDatabase, $SyncLogOpsTable, SyncLogOpData>,
      ),
      SyncLogOpData,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorTableCreateCompanionBuilder =
    SyncCursorCompanion Function({
      required String deviceId,
      Value<int> lastAppliedSeq,
      Value<String?> lastAppliedHlc,
      Value<int> rowid,
    });
typedef $$SyncCursorTableUpdateCompanionBuilder =
    SyncCursorCompanion Function({
      Value<String> deviceId,
      Value<int> lastAppliedSeq,
      Value<String?> lastAppliedHlc,
      Value<int> rowid,
    });

final class $$SyncCursorTableReferences
    extends BaseReferences<_$AppDatabase, $SyncCursorTable, SyncCursorData> {
  $$SyncCursorTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DevicesTable _deviceIdTable(_$AppDatabase db) => db.devices
      .createAlias($_aliasNameGenerator(db.syncCursor.deviceId, db.devices.id));

  $$DevicesTableProcessedTableManager get deviceId {
    final $_column = $_itemColumn<String>('device_id')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncCursorTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorTable> {
  $$SyncCursorTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get lastAppliedSeq => $composableBuilder(
    column: $table.lastAppliedSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastAppliedHlc => $composableBuilder(
    column: $table.lastAppliedHlc,
    builder: (column) => ColumnFilters(column),
  );

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncCursorTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorTable> {
  $$SyncCursorTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get lastAppliedSeq => $composableBuilder(
    column: $table.lastAppliedSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAppliedHlc => $composableBuilder(
    column: $table.lastAppliedHlc,
    builder: (column) => ColumnOrderings(column),
  );

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncCursorTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorTable> {
  $$SyncCursorTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get lastAppliedSeq => $composableBuilder(
    column: $table.lastAppliedSeq,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastAppliedHlc => $composableBuilder(
    column: $table.lastAppliedHlc,
    builder: (column) => column,
  );

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncCursorTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorTable,
          SyncCursorData,
          $$SyncCursorTableFilterComposer,
          $$SyncCursorTableOrderingComposer,
          $$SyncCursorTableAnnotationComposer,
          $$SyncCursorTableCreateCompanionBuilder,
          $$SyncCursorTableUpdateCompanionBuilder,
          (SyncCursorData, $$SyncCursorTableReferences),
          SyncCursorData,
          PrefetchHooks Function({bool deviceId})
        > {
  $$SyncCursorTableTableManager(_$AppDatabase db, $SyncCursorTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> lastAppliedSeq = const Value.absent(),
                Value<String?> lastAppliedHlc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorCompanion(
                deviceId: deviceId,
                lastAppliedSeq: lastAppliedSeq,
                lastAppliedHlc: lastAppliedHlc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                Value<int> lastAppliedSeq = const Value.absent(),
                Value<String?> lastAppliedHlc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorCompanion.insert(
                deviceId: deviceId,
                lastAppliedSeq: lastAppliedSeq,
                lastAppliedHlc: lastAppliedHlc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyncCursorTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deviceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deviceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deviceId,
                                referencedTable: $$SyncCursorTableReferences
                                    ._deviceIdTable(db),
                                referencedColumn: $$SyncCursorTableReferences
                                    ._deviceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncCursorTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorTable,
      SyncCursorData,
      $$SyncCursorTableFilterComposer,
      $$SyncCursorTableOrderingComposer,
      $$SyncCursorTableAnnotationComposer,
      $$SyncCursorTableCreateCompanionBuilder,
      $$SyncCursorTableUpdateCompanionBuilder,
      (SyncCursorData, $$SyncCursorTableReferences),
      SyncCursorData,
      PrefetchHooks Function({bool deviceId})
    >;
typedef $$ConflictsTableCreateCompanionBuilder =
    ConflictsCompanion Function({
      required String id,
      required String entityKind,
      required String entityId,
      required String localStateJson,
      required String remoteStateJson,
      required String provisionalWinner,
      required DateTime detectedAt,
      required String detectedHlc,
      Value<DateTime?> resolvedAt,
      Value<String?> resolution,
      Value<String?> resolvedByDevice,
      Value<int> rowid,
    });
typedef $$ConflictsTableUpdateCompanionBuilder =
    ConflictsCompanion Function({
      Value<String> id,
      Value<String> entityKind,
      Value<String> entityId,
      Value<String> localStateJson,
      Value<String> remoteStateJson,
      Value<String> provisionalWinner,
      Value<DateTime> detectedAt,
      Value<String> detectedHlc,
      Value<DateTime?> resolvedAt,
      Value<String?> resolution,
      Value<String?> resolvedByDevice,
      Value<int> rowid,
    });

final class $$ConflictsTableReferences
    extends BaseReferences<_$AppDatabase, $ConflictsTable, ConflictData> {
  $$ConflictsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DevicesTable _resolvedByDeviceTable(_$AppDatabase db) =>
      db.devices.createAlias(
        $_aliasNameGenerator(db.conflicts.resolvedByDevice, db.devices.id),
      );

  $$DevicesTableProcessedTableManager? get resolvedByDevice {
    final $_column = $_itemColumn<String>('resolved_by_device');
    if ($_column == null) return null;
    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_resolvedByDeviceTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ConflictsTableFilterComposer
    extends Composer<_$AppDatabase, $ConflictsTable> {
  $$ConflictsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localStateJson => $composableBuilder(
    column: $table.localStateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteStateJson => $composableBuilder(
    column: $table.remoteStateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provisionalWinner => $composableBuilder(
    column: $table.provisionalWinner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get detectedAt =>
      $composableBuilder(
        column: $table.detectedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get detectedHlc => $composableBuilder(
    column: $table.detectedHlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get resolvedAt =>
      $composableBuilder(
        column: $table.resolvedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnFilters(column),
  );

  $$DevicesTableFilterComposer get resolvedByDevice {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resolvedByDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConflictsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConflictsTable> {
  $$ConflictsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localStateJson => $composableBuilder(
    column: $table.localStateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteStateJson => $composableBuilder(
    column: $table.remoteStateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provisionalWinner => $composableBuilder(
    column: $table.provisionalWinner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detectedHlc => $composableBuilder(
    column: $table.detectedHlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnOrderings(column),
  );

  $$DevicesTableOrderingComposer get resolvedByDevice {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resolvedByDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConflictsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConflictsTable> {
  $$ConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get localStateJson => $composableBuilder(
    column: $table.localStateJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteStateJson => $composableBuilder(
    column: $table.remoteStateJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provisionalWinner => $composableBuilder(
    column: $table.provisionalWinner,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get detectedAt =>
      $composableBuilder(
        column: $table.detectedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get detectedHlc => $composableBuilder(
    column: $table.detectedHlc,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get resolvedAt =>
      $composableBuilder(
        column: $table.resolvedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => column,
  );

  $$DevicesTableAnnotationComposer get resolvedByDevice {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resolvedByDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConflictsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConflictsTable,
          ConflictData,
          $$ConflictsTableFilterComposer,
          $$ConflictsTableOrderingComposer,
          $$ConflictsTableAnnotationComposer,
          $$ConflictsTableCreateCompanionBuilder,
          $$ConflictsTableUpdateCompanionBuilder,
          (ConflictData, $$ConflictsTableReferences),
          ConflictData,
          PrefetchHooks Function({bool resolvedByDevice})
        > {
  $$ConflictsTableTableManager(_$AppDatabase db, $ConflictsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityKind = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> localStateJson = const Value.absent(),
                Value<String> remoteStateJson = const Value.absent(),
                Value<String> provisionalWinner = const Value.absent(),
                Value<DateTime> detectedAt = const Value.absent(),
                Value<String> detectedHlc = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String?> resolution = const Value.absent(),
                Value<String?> resolvedByDevice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictsCompanion(
                id: id,
                entityKind: entityKind,
                entityId: entityId,
                localStateJson: localStateJson,
                remoteStateJson: remoteStateJson,
                provisionalWinner: provisionalWinner,
                detectedAt: detectedAt,
                detectedHlc: detectedHlc,
                resolvedAt: resolvedAt,
                resolution: resolution,
                resolvedByDevice: resolvedByDevice,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityKind,
                required String entityId,
                required String localStateJson,
                required String remoteStateJson,
                required String provisionalWinner,
                required DateTime detectedAt,
                required String detectedHlc,
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String?> resolution = const Value.absent(),
                Value<String?> resolvedByDevice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictsCompanion.insert(
                id: id,
                entityKind: entityKind,
                entityId: entityId,
                localStateJson: localStateJson,
                remoteStateJson: remoteStateJson,
                provisionalWinner: provisionalWinner,
                detectedAt: detectedAt,
                detectedHlc: detectedHlc,
                resolvedAt: resolvedAt,
                resolution: resolution,
                resolvedByDevice: resolvedByDevice,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConflictsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({resolvedByDevice = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (resolvedByDevice) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.resolvedByDevice,
                                referencedTable: $$ConflictsTableReferences
                                    ._resolvedByDeviceTable(db),
                                referencedColumn: $$ConflictsTableReferences
                                    ._resolvedByDeviceTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ConflictsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConflictsTable,
      ConflictData,
      $$ConflictsTableFilterComposer,
      $$ConflictsTableOrderingComposer,
      $$ConflictsTableAnnotationComposer,
      $$ConflictsTableCreateCompanionBuilder,
      $$ConflictsTableUpdateCompanionBuilder,
      (ConflictData, $$ConflictsTableReferences),
      ConflictData,
      PrefetchHooks Function({bool resolvedByDevice})
    >;
typedef $$TombstonesTableCreateCompanionBuilder =
    TombstonesCompanion Function({
      required String entityKind,
      required String entityId,
      required String deletedHlc,
      required String originDevice,
      required DateTime purgeAfter,
      Value<int> rowid,
    });
typedef $$TombstonesTableUpdateCompanionBuilder =
    TombstonesCompanion Function({
      Value<String> entityKind,
      Value<String> entityId,
      Value<String> deletedHlc,
      Value<String> originDevice,
      Value<DateTime> purgeAfter,
      Value<int> rowid,
    });

final class $$TombstonesTableReferences
    extends BaseReferences<_$AppDatabase, $TombstonesTable, TombstoneData> {
  $$TombstonesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DevicesTable _originDeviceTable(_$AppDatabase db) =>
      db.devices.createAlias(
        $_aliasNameGenerator(db.tombstones.originDevice, db.devices.id),
      );

  $$DevicesTableProcessedTableManager get originDevice {
    final $_column = $_itemColumn<String>('origin_device')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_originDeviceTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TombstonesTableFilterComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedHlc => $composableBuilder(
    column: $table.deletedHlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get purgeAfter =>
      $composableBuilder(
        column: $table.purgeAfter,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$DevicesTableFilterComposer get originDevice {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TombstonesTableOrderingComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedHlc => $composableBuilder(
    column: $table.deletedHlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeAfter => $composableBuilder(
    column: $table.purgeAfter,
    builder: (column) => ColumnOrderings(column),
  );

  $$DevicesTableOrderingComposer get originDevice {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TombstonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get deletedHlc => $composableBuilder(
    column: $table.deletedHlc,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get purgeAfter =>
      $composableBuilder(
        column: $table.purgeAfter,
        builder: (column) => column,
      );

  $$DevicesTableAnnotationComposer get originDevice {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originDevice,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TombstonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TombstonesTable,
          TombstoneData,
          $$TombstonesTableFilterComposer,
          $$TombstonesTableOrderingComposer,
          $$TombstonesTableAnnotationComposer,
          $$TombstonesTableCreateCompanionBuilder,
          $$TombstonesTableUpdateCompanionBuilder,
          (TombstoneData, $$TombstonesTableReferences),
          TombstoneData,
          PrefetchHooks Function({bool originDevice})
        > {
  $$TombstonesTableTableManager(_$AppDatabase db, $TombstonesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TombstonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityKind = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> deletedHlc = const Value.absent(),
                Value<String> originDevice = const Value.absent(),
                Value<DateTime> purgeAfter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion(
                entityKind: entityKind,
                entityId: entityId,
                deletedHlc: deletedHlc,
                originDevice: originDevice,
                purgeAfter: purgeAfter,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityKind,
                required String entityId,
                required String deletedHlc,
                required String originDevice,
                required DateTime purgeAfter,
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion.insert(
                entityKind: entityKind,
                entityId: entityId,
                deletedHlc: deletedHlc,
                originDevice: originDevice,
                purgeAfter: purgeAfter,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TombstonesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({originDevice = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (originDevice) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.originDevice,
                                referencedTable: $$TombstonesTableReferences
                                    ._originDeviceTable(db),
                                referencedColumn: $$TombstonesTableReferences
                                    ._originDeviceTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TombstonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TombstonesTable,
      TombstoneData,
      $$TombstonesTableFilterComposer,
      $$TombstonesTableOrderingComposer,
      $$TombstonesTableAnnotationComposer,
      $$TombstonesTableCreateCompanionBuilder,
      $$TombstonesTableUpdateCompanionBuilder,
      (TombstoneData, $$TombstonesTableReferences),
      TombstoneData,
      PrefetchHooks Function({bool originDevice})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
  $$KeyEpochsTableTableManager get keyEpochs =>
      $$KeyEpochsTableTableManager(_db, _db.keyEpochs);
  $$VaultEntriesTableTableManager get vaultEntries =>
      $$VaultEntriesTableTableManager(_db, _db.vaultEntries);
  $$BlobsTableTableManager get blobs =>
      $$BlobsTableTableManager(_db, _db.blobs);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$AssetVersionsTableTableManager get assetVersions =>
      $$AssetVersionsTableTableManager(_db, _db.assetVersions);
  $$VersionPinsTableTableManager get versionPins =>
      $$VersionPinsTableTableManager(_db, _db.versionPins);
  $$ThumbnailsTableTableManager get thumbnails =>
      $$ThumbnailsTableTableManager(_db, _db.thumbnails);
  $$ExportRecordsTableTableManager get exportRecords =>
      $$ExportRecordsTableTableManager(_db, _db.exportRecords);
  $$ExportRecordSourcesTableTableManager get exportRecordSources =>
      $$ExportRecordSourcesTableTableManager(_db, _db.exportRecordSources);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$CloudObjectsTableTableManager get cloudObjects =>
      $$CloudObjectsTableTableManager(_db, _db.cloudObjects);
  $$SyncLogSegmentsTableTableManager get syncLogSegments =>
      $$SyncLogSegmentsTableTableManager(_db, _db.syncLogSegments);
  $$SyncLogOpsTableTableManager get syncLogOps =>
      $$SyncLogOpsTableTableManager(_db, _db.syncLogOps);
  $$SyncCursorTableTableManager get syncCursor =>
      $$SyncCursorTableTableManager(_db, _db.syncCursor);
  $$ConflictsTableTableManager get conflicts =>
      $$ConflictsTableTableManager(_db, _db.conflicts);
  $$TombstonesTableTableManager get tombstones =>
      $$TombstonesTableTableManager(_db, _db.tombstones);
}
