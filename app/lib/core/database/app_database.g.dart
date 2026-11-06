// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueEntry> {
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
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($SyncQueueTable.$converterstatus);
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUuid,
    entity,
    action,
    payload,
    createdAt,
    retryCount,
    status,
    lastError,
    nextAttemptAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      status: $SyncQueueTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }

  static TypeConverter<SyncStatus, String> $converterstatus =
      const SyncStatusConverter();
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final int id;
  final String clientUuid;
  final String entity;
  final String action;

  /// JSON object.
  final String payload;
  final DateTime createdAt;
  final int retryCount;
  final SyncStatus status;
  final String? lastError;
  final DateTime? nextAttemptAt;
  const SyncQueueEntry({
    required this.id,
    required this.clientUuid,
    required this.entity,
    required this.action,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    required this.status,
    this.lastError,
    this.nextAttemptAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_uuid'] = Variable<String>(clientUuid);
    map['entity'] = Variable<String>(entity);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    {
      map['status'] = Variable<String>(
        $SyncQueueTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      clientUuid: Value(clientUuid),
      entity: Value(entity),
      action: Value(action),
      payload: Value(payload),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
    );
  }

  factory SyncQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      id: serializer.fromJson<int>(json['id']),
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      entity: serializer.fromJson<String>(json['entity']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      status: serializer.fromJson<SyncStatus>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientUuid': serializer.toJson<String>(clientUuid),
      'entity': serializer.toJson<String>(entity),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'status': serializer.toJson<SyncStatus>(status),
      'lastError': serializer.toJson<String?>(lastError),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
    };
  }

  SyncQueueEntry copyWith({
    int? id,
    String? clientUuid,
    String? entity,
    String? action,
    String? payload,
    DateTime? createdAt,
    int? retryCount,
    SyncStatus? status,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
  }) => SyncQueueEntry(
    id: id ?? this.id,
    clientUuid: clientUuid ?? this.clientUuid,
    entity: entity ?? this.entity,
    action: action ?? this.action,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    status: status ?? this.status,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
  );
  SyncQueueEntry copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      entity: data.entity.present ? data.entity.value : this.entity,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('entity: $entity, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUuid,
    entity,
    action,
    payload,
    createdAt,
    retryCount,
    status,
    lastError,
    nextAttemptAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.id == this.id &&
          other.clientUuid == this.clientUuid &&
          other.entity == this.entity &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.status == this.status &&
          other.lastError == this.lastError &&
          other.nextAttemptAt == this.nextAttemptAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<int> id;
  final Value<String> clientUuid;
  final Value<String> entity;
  final Value<String> action;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<SyncStatus> status;
  final Value<String?> lastError;
  final Value<DateTime?> nextAttemptAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.entity = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String clientUuid,
    required String entity,
    required String action,
    required String payload,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    required SyncStatus status,
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
  }) : clientUuid = Value(clientUuid),
       entity = Value(entity),
       action = Value(action),
       payload = Value(payload),
       createdAt = Value(createdAt),
       status = Value(status);
  static Insertable<SyncQueueEntry> custom({
    Expression<int>? id,
    Expression<String>? clientUuid,
    Expression<String>? entity,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<DateTime>? nextAttemptAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (entity != null) 'entity': entity,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? clientUuid,
    Value<String>? entity,
    Value<String>? action,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<SyncStatus>? status,
    Value<String?>? lastError,
    Value<DateTime?>? nextAttemptAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      clientUuid: clientUuid ?? this.clientUuid,
      entity: entity ?? this.entity,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $SyncQueueTable.$converterstatus.toSql(status.value),
      );
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('entity: $entity, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt')
          ..write(')'))
        .toString();
  }
}

class $LocalDeviceTable extends LocalDevice
    with TableInfo<$LocalDeviceTable, LocalDeviceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDeviceTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deviceCodeMeta = const VerificationMeta(
    'deviceCode',
  );
  @override
  late final GeneratedColumn<String> deviceCode = GeneratedColumn<String>(
    'device_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pairedAtMeta = const VerificationMeta(
    'pairedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pairedAt = GeneratedColumn<DateTime>(
    'paired_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    deviceCode,
    storeId,
    name,
    pairedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_device';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDeviceRow> instance, {
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
    if (data.containsKey('device_code')) {
      context.handle(
        _deviceCodeMeta,
        deviceCode.isAcceptableOrUnknown(data['device_code']!, _deviceCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceCodeMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('paired_at')) {
      context.handle(
        _pairedAtMeta,
        pairedAt.isAcceptableOrUnknown(data['paired_at']!, _pairedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_pairedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  LocalDeviceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDeviceRow(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deviceCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_code'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      pairedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paired_at'],
      )!,
    );
  }

  @override
  $LocalDeviceTable createAlias(String alias) {
    return $LocalDeviceTable(attachedDatabase, alias);
  }
}

class LocalDeviceRow extends DataClass implements Insertable<LocalDeviceRow> {
  final String deviceId;
  final String deviceCode;
  final String storeId;
  final String name;
  final DateTime pairedAt;
  const LocalDeviceRow({
    required this.deviceId,
    required this.deviceCode,
    required this.storeId,
    required this.name,
    required this.pairedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['device_code'] = Variable<String>(deviceCode);
    map['store_id'] = Variable<String>(storeId);
    map['name'] = Variable<String>(name);
    map['paired_at'] = Variable<DateTime>(pairedAt);
    return map;
  }

  LocalDeviceCompanion toCompanion(bool nullToAbsent) {
    return LocalDeviceCompanion(
      deviceId: Value(deviceId),
      deviceCode: Value(deviceCode),
      storeId: Value(storeId),
      name: Value(name),
      pairedAt: Value(pairedAt),
    );
  }

  factory LocalDeviceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDeviceRow(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceCode: serializer.fromJson<String>(json['deviceCode']),
      storeId: serializer.fromJson<String>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      pairedAt: serializer.fromJson<DateTime>(json['pairedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceCode': serializer.toJson<String>(deviceCode),
      'storeId': serializer.toJson<String>(storeId),
      'name': serializer.toJson<String>(name),
      'pairedAt': serializer.toJson<DateTime>(pairedAt),
    };
  }

  LocalDeviceRow copyWith({
    String? deviceId,
    String? deviceCode,
    String? storeId,
    String? name,
    DateTime? pairedAt,
  }) => LocalDeviceRow(
    deviceId: deviceId ?? this.deviceId,
    deviceCode: deviceCode ?? this.deviceCode,
    storeId: storeId ?? this.storeId,
    name: name ?? this.name,
    pairedAt: pairedAt ?? this.pairedAt,
  );
  LocalDeviceRow copyWithCompanion(LocalDeviceCompanion data) {
    return LocalDeviceRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceCode: data.deviceCode.present
          ? data.deviceCode.value
          : this.deviceCode,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      pairedAt: data.pairedAt.present ? data.pairedAt.value : this.pairedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDeviceRow(')
          ..write('deviceId: $deviceId, ')
          ..write('deviceCode: $deviceCode, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('pairedAt: $pairedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(deviceId, deviceCode, storeId, name, pairedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDeviceRow &&
          other.deviceId == this.deviceId &&
          other.deviceCode == this.deviceCode &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.pairedAt == this.pairedAt);
}

class LocalDeviceCompanion extends UpdateCompanion<LocalDeviceRow> {
  final Value<String> deviceId;
  final Value<String> deviceCode;
  final Value<String> storeId;
  final Value<String> name;
  final Value<DateTime> pairedAt;
  final Value<int> rowid;
  const LocalDeviceCompanion({
    this.deviceId = const Value.absent(),
    this.deviceCode = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDeviceCompanion.insert({
    required String deviceId,
    required String deviceCode,
    required String storeId,
    required String name,
    required DateTime pairedAt,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       deviceCode = Value(deviceCode),
       storeId = Value(storeId),
       name = Value(name),
       pairedAt = Value(pairedAt);
  static Insertable<LocalDeviceRow> custom({
    Expression<String>? deviceId,
    Expression<String>? deviceCode,
    Expression<String>? storeId,
    Expression<String>? name,
    Expression<DateTime>? pairedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (deviceCode != null) 'device_code': deviceCode,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (pairedAt != null) 'paired_at': pairedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDeviceCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? deviceCode,
    Value<String>? storeId,
    Value<String>? name,
    Value<DateTime>? pairedAt,
    Value<int>? rowid,
  }) {
    return LocalDeviceCompanion(
      deviceId: deviceId ?? this.deviceId,
      deviceCode: deviceCode ?? this.deviceCode,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      pairedAt: pairedAt ?? this.pairedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceCode.present) {
      map['device_code'] = Variable<String>(deviceCode.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (pairedAt.present) {
      map['paired_at'] = Variable<DateTime>(pairedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDeviceCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('deviceCode: $deviceCode, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStoresTable extends LocalStores
    with TableInfo<$LocalStoresTable, LocalStoreRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fnbModeMeta = const VerificationMeta(
    'fnbMode',
  );
  @override
  late final GeneratedColumn<bool> fnbMode = GeneratedColumn<bool>(
    'fnb_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fnb_mode" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    address,
    phone,
    timezone,
    fnbMode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStoreRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('fnb_mode')) {
      context.handle(
        _fnbModeMeta,
        fnbMode.isAcceptableOrUnknown(data['fnb_mode']!, _fnbModeMeta),
      );
    } else if (isInserting) {
      context.missing(_fnbModeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStoreRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStoreRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      fnbMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fnb_mode'],
      )!,
    );
  }

  @override
  $LocalStoresTable createAlias(String alias) {
    return $LocalStoresTable(attachedDatabase, alias);
  }
}

class LocalStoreRow extends DataClass implements Insertable<LocalStoreRow> {
  final String id;
  final String code;
  final String name;
  final String? address;
  final String? phone;
  final String timezone;
  final bool fnbMode;
  const LocalStoreRow({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    this.phone,
    required this.timezone,
    required this.fnbMode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['timezone'] = Variable<String>(timezone);
    map['fnb_mode'] = Variable<bool>(fnbMode);
    return map;
  }

  LocalStoresCompanion toCompanion(bool nullToAbsent) {
    return LocalStoresCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      timezone: Value(timezone),
      fnbMode: Value(fnbMode),
    );
  }

  factory LocalStoreRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStoreRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      phone: serializer.fromJson<String?>(json['phone']),
      timezone: serializer.fromJson<String>(json['timezone']),
      fnbMode: serializer.fromJson<bool>(json['fnbMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String?>(address),
      'phone': serializer.toJson<String?>(phone),
      'timezone': serializer.toJson<String>(timezone),
      'fnbMode': serializer.toJson<bool>(fnbMode),
    };
  }

  LocalStoreRow copyWith({
    String? id,
    String? code,
    String? name,
    Value<String?> address = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    String? timezone,
    bool? fnbMode,
  }) => LocalStoreRow(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    address: address.present ? address.value : this.address,
    phone: phone.present ? phone.value : this.phone,
    timezone: timezone ?? this.timezone,
    fnbMode: fnbMode ?? this.fnbMode,
  );
  LocalStoreRow copyWithCompanion(LocalStoresCompanion data) {
    return LocalStoreRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      phone: data.phone.present ? data.phone.value : this.phone,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      fnbMode: data.fnbMode.present ? data.fnbMode.value : this.fnbMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStoreRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('timezone: $timezone, ')
          ..write('fnbMode: $fnbMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, code, name, address, phone, timezone, fnbMode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStoreRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.address == this.address &&
          other.phone == this.phone &&
          other.timezone == this.timezone &&
          other.fnbMode == this.fnbMode);
}

class LocalStoresCompanion extends UpdateCompanion<LocalStoreRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String?> address;
  final Value<String?> phone;
  final Value<String> timezone;
  final Value<bool> fnbMode;
  final Value<int> rowid;
  const LocalStoresCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.timezone = const Value.absent(),
    this.fnbMode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStoresCompanion.insert({
    required String id,
    required String code,
    required String name,
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    required String timezone,
    required bool fnbMode,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       name = Value(name),
       timezone = Value(timezone),
       fnbMode = Value(fnbMode);
  static Insertable<LocalStoreRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? phone,
    Expression<String>? timezone,
    Expression<bool>? fnbMode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (timezone != null) 'timezone': timezone,
      if (fnbMode != null) 'fnb_mode': fnbMode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStoresCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String?>? address,
    Value<String?>? phone,
    Value<String>? timezone,
    Value<bool>? fnbMode,
    Value<int>? rowid,
  }) {
    return LocalStoresCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      timezone: timezone ?? this.timezone,
      fnbMode: fnbMode ?? this.fnbMode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (fnbMode.present) {
      map['fnb_mode'] = Variable<bool>(fnbMode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStoresCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('timezone: $timezone, ')
          ..write('fnbMode: $fnbMode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStoreSettingsTable extends LocalStoreSettings
    with TableInfo<$LocalStoreSettingsTable, LocalStoreSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStoreSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxEnabledMeta = const VerificationMeta(
    'taxEnabled',
  );
  @override
  late final GeneratedColumn<bool> taxEnabled = GeneratedColumn<bool>(
    'tax_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tax_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _taxNameMeta = const VerificationMeta(
    'taxName',
  );
  @override
  late final GeneratedColumn<String> taxName = GeneratedColumn<String>(
    'tax_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxRateBpsMeta = const VerificationMeta(
    'taxRateBps',
  );
  @override
  late final GeneratedColumn<int> taxRateBps = GeneratedColumn<int>(
    'tax_rate_bps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxInclusiveMeta = const VerificationMeta(
    'taxInclusive',
  );
  @override
  late final GeneratedColumn<bool> taxInclusive = GeneratedColumn<bool>(
    'tax_inclusive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tax_inclusive" IN (0, 1))',
    ),
  );
  static const VerificationMeta _serviceChargeEnabledMeta =
      const VerificationMeta('serviceChargeEnabled');
  @override
  late final GeneratedColumn<bool> serviceChargeEnabled = GeneratedColumn<bool>(
    'service_charge_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("service_charge_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _serviceChargeBpsMeta = const VerificationMeta(
    'serviceChargeBps',
  );
  @override
  late final GeneratedColumn<int> serviceChargeBps = GeneratedColumn<int>(
    'service_charge_bps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceChargeTaxableMeta =
      const VerificationMeta('serviceChargeTaxable');
  @override
  late final GeneratedColumn<bool> serviceChargeTaxable = GeneratedColumn<bool>(
    'service_charge_taxable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("service_charge_taxable" IN (0, 1))',
    ),
  );
  static const VerificationMeta _roundingModeMeta = const VerificationMeta(
    'roundingMode',
  );
  @override
  late final GeneratedColumn<String> roundingMode = GeneratedColumn<String>(
    'rounding_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundingUnitMeta = const VerificationMeta(
    'roundingUnit',
  );
  @override
  late final GeneratedColumn<int> roundingUnit = GeneratedColumn<int>(
    'rounding_unit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountApprovalBpsMeta =
      const VerificationMeta('discountApprovalBps');
  @override
  late final GeneratedColumn<int> discountApprovalBps = GeneratedColumn<int>(
    'discount_approval_bps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kasbonEnabledMeta = const VerificationMeta(
    'kasbonEnabled',
  );
  @override
  late final GeneratedColumn<bool> kasbonEnabled = GeneratedColumn<bool>(
    'kasbon_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("kasbon_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _receiptHeaderMeta = const VerificationMeta(
    'receiptHeader',
  );
  @override
  late final GeneratedColumn<String> receiptHeader = GeneratedColumn<String>(
    'receipt_header',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptFooterMeta = const VerificationMeta(
    'receiptFooter',
  );
  @override
  late final GeneratedColumn<String> receiptFooter = GeneratedColumn<String>(
    'receipt_footer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptPaperMmMeta = const VerificationMeta(
    'receiptPaperMm',
  );
  @override
  late final GeneratedColumn<int> receiptPaperMm = GeneratedColumn<int>(
    'receipt_paper_mm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    storeId,
    taxEnabled,
    taxName,
    taxRateBps,
    taxInclusive,
    serviceChargeEnabled,
    serviceChargeBps,
    serviceChargeTaxable,
    roundingMode,
    roundingUnit,
    discountApprovalBps,
    kasbonEnabled,
    receiptHeader,
    receiptFooter,
    receiptPaperMm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_store_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStoreSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('tax_enabled')) {
      context.handle(
        _taxEnabledMeta,
        taxEnabled.isAcceptableOrUnknown(data['tax_enabled']!, _taxEnabledMeta),
      );
    } else if (isInserting) {
      context.missing(_taxEnabledMeta);
    }
    if (data.containsKey('tax_name')) {
      context.handle(
        _taxNameMeta,
        taxName.isAcceptableOrUnknown(data['tax_name']!, _taxNameMeta),
      );
    } else if (isInserting) {
      context.missing(_taxNameMeta);
    }
    if (data.containsKey('tax_rate_bps')) {
      context.handle(
        _taxRateBpsMeta,
        taxRateBps.isAcceptableOrUnknown(
          data['tax_rate_bps']!,
          _taxRateBpsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxRateBpsMeta);
    }
    if (data.containsKey('tax_inclusive')) {
      context.handle(
        _taxInclusiveMeta,
        taxInclusive.isAcceptableOrUnknown(
          data['tax_inclusive']!,
          _taxInclusiveMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxInclusiveMeta);
    }
    if (data.containsKey('service_charge_enabled')) {
      context.handle(
        _serviceChargeEnabledMeta,
        serviceChargeEnabled.isAcceptableOrUnknown(
          data['service_charge_enabled']!,
          _serviceChargeEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serviceChargeEnabledMeta);
    }
    if (data.containsKey('service_charge_bps')) {
      context.handle(
        _serviceChargeBpsMeta,
        serviceChargeBps.isAcceptableOrUnknown(
          data['service_charge_bps']!,
          _serviceChargeBpsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serviceChargeBpsMeta);
    }
    if (data.containsKey('service_charge_taxable')) {
      context.handle(
        _serviceChargeTaxableMeta,
        serviceChargeTaxable.isAcceptableOrUnknown(
          data['service_charge_taxable']!,
          _serviceChargeTaxableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serviceChargeTaxableMeta);
    }
    if (data.containsKey('rounding_mode')) {
      context.handle(
        _roundingModeMeta,
        roundingMode.isAcceptableOrUnknown(
          data['rounding_mode']!,
          _roundingModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_roundingModeMeta);
    }
    if (data.containsKey('rounding_unit')) {
      context.handle(
        _roundingUnitMeta,
        roundingUnit.isAcceptableOrUnknown(
          data['rounding_unit']!,
          _roundingUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_roundingUnitMeta);
    }
    if (data.containsKey('discount_approval_bps')) {
      context.handle(
        _discountApprovalBpsMeta,
        discountApprovalBps.isAcceptableOrUnknown(
          data['discount_approval_bps']!,
          _discountApprovalBpsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountApprovalBpsMeta);
    }
    if (data.containsKey('kasbon_enabled')) {
      context.handle(
        _kasbonEnabledMeta,
        kasbonEnabled.isAcceptableOrUnknown(
          data['kasbon_enabled']!,
          _kasbonEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kasbonEnabledMeta);
    }
    if (data.containsKey('receipt_header')) {
      context.handle(
        _receiptHeaderMeta,
        receiptHeader.isAcceptableOrUnknown(
          data['receipt_header']!,
          _receiptHeaderMeta,
        ),
      );
    }
    if (data.containsKey('receipt_footer')) {
      context.handle(
        _receiptFooterMeta,
        receiptFooter.isAcceptableOrUnknown(
          data['receipt_footer']!,
          _receiptFooterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receiptFooterMeta);
    }
    if (data.containsKey('receipt_paper_mm')) {
      context.handle(
        _receiptPaperMmMeta,
        receiptPaperMm.isAcceptableOrUnknown(
          data['receipt_paper_mm']!,
          _receiptPaperMmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receiptPaperMmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {storeId};
  @override
  LocalStoreSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStoreSettingsRow(
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      taxEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tax_enabled'],
      )!,
      taxName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_name'],
      )!,
      taxRateBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_rate_bps'],
      )!,
      taxInclusive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tax_inclusive'],
      )!,
      serviceChargeEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}service_charge_enabled'],
      )!,
      serviceChargeBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_charge_bps'],
      )!,
      serviceChargeTaxable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}service_charge_taxable'],
      )!,
      roundingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rounding_mode'],
      )!,
      roundingUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rounding_unit'],
      )!,
      discountApprovalBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_approval_bps'],
      )!,
      kasbonEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}kasbon_enabled'],
      )!,
      receiptHeader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_header'],
      ),
      receiptFooter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_footer'],
      )!,
      receiptPaperMm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_paper_mm'],
      )!,
    );
  }

  @override
  $LocalStoreSettingsTable createAlias(String alias) {
    return $LocalStoreSettingsTable(attachedDatabase, alias);
  }
}

class LocalStoreSettingsRow extends DataClass
    implements Insertable<LocalStoreSettingsRow> {
  final String storeId;
  final bool taxEnabled;
  final String taxName;
  final int taxRateBps;
  final bool taxInclusive;
  final bool serviceChargeEnabled;
  final int serviceChargeBps;
  final bool serviceChargeTaxable;
  final String roundingMode;
  final int roundingUnit;
  final int discountApprovalBps;
  final bool kasbonEnabled;
  final String? receiptHeader;
  final String receiptFooter;
  final int receiptPaperMm;
  const LocalStoreSettingsRow({
    required this.storeId,
    required this.taxEnabled,
    required this.taxName,
    required this.taxRateBps,
    required this.taxInclusive,
    required this.serviceChargeEnabled,
    required this.serviceChargeBps,
    required this.serviceChargeTaxable,
    required this.roundingMode,
    required this.roundingUnit,
    required this.discountApprovalBps,
    required this.kasbonEnabled,
    this.receiptHeader,
    required this.receiptFooter,
    required this.receiptPaperMm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['store_id'] = Variable<String>(storeId);
    map['tax_enabled'] = Variable<bool>(taxEnabled);
    map['tax_name'] = Variable<String>(taxName);
    map['tax_rate_bps'] = Variable<int>(taxRateBps);
    map['tax_inclusive'] = Variable<bool>(taxInclusive);
    map['service_charge_enabled'] = Variable<bool>(serviceChargeEnabled);
    map['service_charge_bps'] = Variable<int>(serviceChargeBps);
    map['service_charge_taxable'] = Variable<bool>(serviceChargeTaxable);
    map['rounding_mode'] = Variable<String>(roundingMode);
    map['rounding_unit'] = Variable<int>(roundingUnit);
    map['discount_approval_bps'] = Variable<int>(discountApprovalBps);
    map['kasbon_enabled'] = Variable<bool>(kasbonEnabled);
    if (!nullToAbsent || receiptHeader != null) {
      map['receipt_header'] = Variable<String>(receiptHeader);
    }
    map['receipt_footer'] = Variable<String>(receiptFooter);
    map['receipt_paper_mm'] = Variable<int>(receiptPaperMm);
    return map;
  }

  LocalStoreSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalStoreSettingsCompanion(
      storeId: Value(storeId),
      taxEnabled: Value(taxEnabled),
      taxName: Value(taxName),
      taxRateBps: Value(taxRateBps),
      taxInclusive: Value(taxInclusive),
      serviceChargeEnabled: Value(serviceChargeEnabled),
      serviceChargeBps: Value(serviceChargeBps),
      serviceChargeTaxable: Value(serviceChargeTaxable),
      roundingMode: Value(roundingMode),
      roundingUnit: Value(roundingUnit),
      discountApprovalBps: Value(discountApprovalBps),
      kasbonEnabled: Value(kasbonEnabled),
      receiptHeader: receiptHeader == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptHeader),
      receiptFooter: Value(receiptFooter),
      receiptPaperMm: Value(receiptPaperMm),
    );
  }

  factory LocalStoreSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStoreSettingsRow(
      storeId: serializer.fromJson<String>(json['storeId']),
      taxEnabled: serializer.fromJson<bool>(json['taxEnabled']),
      taxName: serializer.fromJson<String>(json['taxName']),
      taxRateBps: serializer.fromJson<int>(json['taxRateBps']),
      taxInclusive: serializer.fromJson<bool>(json['taxInclusive']),
      serviceChargeEnabled: serializer.fromJson<bool>(
        json['serviceChargeEnabled'],
      ),
      serviceChargeBps: serializer.fromJson<int>(json['serviceChargeBps']),
      serviceChargeTaxable: serializer.fromJson<bool>(
        json['serviceChargeTaxable'],
      ),
      roundingMode: serializer.fromJson<String>(json['roundingMode']),
      roundingUnit: serializer.fromJson<int>(json['roundingUnit']),
      discountApprovalBps: serializer.fromJson<int>(
        json['discountApprovalBps'],
      ),
      kasbonEnabled: serializer.fromJson<bool>(json['kasbonEnabled']),
      receiptHeader: serializer.fromJson<String?>(json['receiptHeader']),
      receiptFooter: serializer.fromJson<String>(json['receiptFooter']),
      receiptPaperMm: serializer.fromJson<int>(json['receiptPaperMm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'storeId': serializer.toJson<String>(storeId),
      'taxEnabled': serializer.toJson<bool>(taxEnabled),
      'taxName': serializer.toJson<String>(taxName),
      'taxRateBps': serializer.toJson<int>(taxRateBps),
      'taxInclusive': serializer.toJson<bool>(taxInclusive),
      'serviceChargeEnabled': serializer.toJson<bool>(serviceChargeEnabled),
      'serviceChargeBps': serializer.toJson<int>(serviceChargeBps),
      'serviceChargeTaxable': serializer.toJson<bool>(serviceChargeTaxable),
      'roundingMode': serializer.toJson<String>(roundingMode),
      'roundingUnit': serializer.toJson<int>(roundingUnit),
      'discountApprovalBps': serializer.toJson<int>(discountApprovalBps),
      'kasbonEnabled': serializer.toJson<bool>(kasbonEnabled),
      'receiptHeader': serializer.toJson<String?>(receiptHeader),
      'receiptFooter': serializer.toJson<String>(receiptFooter),
      'receiptPaperMm': serializer.toJson<int>(receiptPaperMm),
    };
  }

  LocalStoreSettingsRow copyWith({
    String? storeId,
    bool? taxEnabled,
    String? taxName,
    int? taxRateBps,
    bool? taxInclusive,
    bool? serviceChargeEnabled,
    int? serviceChargeBps,
    bool? serviceChargeTaxable,
    String? roundingMode,
    int? roundingUnit,
    int? discountApprovalBps,
    bool? kasbonEnabled,
    Value<String?> receiptHeader = const Value.absent(),
    String? receiptFooter,
    int? receiptPaperMm,
  }) => LocalStoreSettingsRow(
    storeId: storeId ?? this.storeId,
    taxEnabled: taxEnabled ?? this.taxEnabled,
    taxName: taxName ?? this.taxName,
    taxRateBps: taxRateBps ?? this.taxRateBps,
    taxInclusive: taxInclusive ?? this.taxInclusive,
    serviceChargeEnabled: serviceChargeEnabled ?? this.serviceChargeEnabled,
    serviceChargeBps: serviceChargeBps ?? this.serviceChargeBps,
    serviceChargeTaxable: serviceChargeTaxable ?? this.serviceChargeTaxable,
    roundingMode: roundingMode ?? this.roundingMode,
    roundingUnit: roundingUnit ?? this.roundingUnit,
    discountApprovalBps: discountApprovalBps ?? this.discountApprovalBps,
    kasbonEnabled: kasbonEnabled ?? this.kasbonEnabled,
    receiptHeader: receiptHeader.present
        ? receiptHeader.value
        : this.receiptHeader,
    receiptFooter: receiptFooter ?? this.receiptFooter,
    receiptPaperMm: receiptPaperMm ?? this.receiptPaperMm,
  );
  LocalStoreSettingsRow copyWithCompanion(LocalStoreSettingsCompanion data) {
    return LocalStoreSettingsRow(
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      taxEnabled: data.taxEnabled.present
          ? data.taxEnabled.value
          : this.taxEnabled,
      taxName: data.taxName.present ? data.taxName.value : this.taxName,
      taxRateBps: data.taxRateBps.present
          ? data.taxRateBps.value
          : this.taxRateBps,
      taxInclusive: data.taxInclusive.present
          ? data.taxInclusive.value
          : this.taxInclusive,
      serviceChargeEnabled: data.serviceChargeEnabled.present
          ? data.serviceChargeEnabled.value
          : this.serviceChargeEnabled,
      serviceChargeBps: data.serviceChargeBps.present
          ? data.serviceChargeBps.value
          : this.serviceChargeBps,
      serviceChargeTaxable: data.serviceChargeTaxable.present
          ? data.serviceChargeTaxable.value
          : this.serviceChargeTaxable,
      roundingMode: data.roundingMode.present
          ? data.roundingMode.value
          : this.roundingMode,
      roundingUnit: data.roundingUnit.present
          ? data.roundingUnit.value
          : this.roundingUnit,
      discountApprovalBps: data.discountApprovalBps.present
          ? data.discountApprovalBps.value
          : this.discountApprovalBps,
      kasbonEnabled: data.kasbonEnabled.present
          ? data.kasbonEnabled.value
          : this.kasbonEnabled,
      receiptHeader: data.receiptHeader.present
          ? data.receiptHeader.value
          : this.receiptHeader,
      receiptFooter: data.receiptFooter.present
          ? data.receiptFooter.value
          : this.receiptFooter,
      receiptPaperMm: data.receiptPaperMm.present
          ? data.receiptPaperMm.value
          : this.receiptPaperMm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStoreSettingsRow(')
          ..write('storeId: $storeId, ')
          ..write('taxEnabled: $taxEnabled, ')
          ..write('taxName: $taxName, ')
          ..write('taxRateBps: $taxRateBps, ')
          ..write('taxInclusive: $taxInclusive, ')
          ..write('serviceChargeEnabled: $serviceChargeEnabled, ')
          ..write('serviceChargeBps: $serviceChargeBps, ')
          ..write('serviceChargeTaxable: $serviceChargeTaxable, ')
          ..write('roundingMode: $roundingMode, ')
          ..write('roundingUnit: $roundingUnit, ')
          ..write('discountApprovalBps: $discountApprovalBps, ')
          ..write('kasbonEnabled: $kasbonEnabled, ')
          ..write('receiptHeader: $receiptHeader, ')
          ..write('receiptFooter: $receiptFooter, ')
          ..write('receiptPaperMm: $receiptPaperMm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    storeId,
    taxEnabled,
    taxName,
    taxRateBps,
    taxInclusive,
    serviceChargeEnabled,
    serviceChargeBps,
    serviceChargeTaxable,
    roundingMode,
    roundingUnit,
    discountApprovalBps,
    kasbonEnabled,
    receiptHeader,
    receiptFooter,
    receiptPaperMm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStoreSettingsRow &&
          other.storeId == this.storeId &&
          other.taxEnabled == this.taxEnabled &&
          other.taxName == this.taxName &&
          other.taxRateBps == this.taxRateBps &&
          other.taxInclusive == this.taxInclusive &&
          other.serviceChargeEnabled == this.serviceChargeEnabled &&
          other.serviceChargeBps == this.serviceChargeBps &&
          other.serviceChargeTaxable == this.serviceChargeTaxable &&
          other.roundingMode == this.roundingMode &&
          other.roundingUnit == this.roundingUnit &&
          other.discountApprovalBps == this.discountApprovalBps &&
          other.kasbonEnabled == this.kasbonEnabled &&
          other.receiptHeader == this.receiptHeader &&
          other.receiptFooter == this.receiptFooter &&
          other.receiptPaperMm == this.receiptPaperMm);
}

class LocalStoreSettingsCompanion
    extends UpdateCompanion<LocalStoreSettingsRow> {
  final Value<String> storeId;
  final Value<bool> taxEnabled;
  final Value<String> taxName;
  final Value<int> taxRateBps;
  final Value<bool> taxInclusive;
  final Value<bool> serviceChargeEnabled;
  final Value<int> serviceChargeBps;
  final Value<bool> serviceChargeTaxable;
  final Value<String> roundingMode;
  final Value<int> roundingUnit;
  final Value<int> discountApprovalBps;
  final Value<bool> kasbonEnabled;
  final Value<String?> receiptHeader;
  final Value<String> receiptFooter;
  final Value<int> receiptPaperMm;
  final Value<int> rowid;
  const LocalStoreSettingsCompanion({
    this.storeId = const Value.absent(),
    this.taxEnabled = const Value.absent(),
    this.taxName = const Value.absent(),
    this.taxRateBps = const Value.absent(),
    this.taxInclusive = const Value.absent(),
    this.serviceChargeEnabled = const Value.absent(),
    this.serviceChargeBps = const Value.absent(),
    this.serviceChargeTaxable = const Value.absent(),
    this.roundingMode = const Value.absent(),
    this.roundingUnit = const Value.absent(),
    this.discountApprovalBps = const Value.absent(),
    this.kasbonEnabled = const Value.absent(),
    this.receiptHeader = const Value.absent(),
    this.receiptFooter = const Value.absent(),
    this.receiptPaperMm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStoreSettingsCompanion.insert({
    required String storeId,
    required bool taxEnabled,
    required String taxName,
    required int taxRateBps,
    required bool taxInclusive,
    required bool serviceChargeEnabled,
    required int serviceChargeBps,
    required bool serviceChargeTaxable,
    required String roundingMode,
    required int roundingUnit,
    required int discountApprovalBps,
    required bool kasbonEnabled,
    this.receiptHeader = const Value.absent(),
    required String receiptFooter,
    required int receiptPaperMm,
    this.rowid = const Value.absent(),
  }) : storeId = Value(storeId),
       taxEnabled = Value(taxEnabled),
       taxName = Value(taxName),
       taxRateBps = Value(taxRateBps),
       taxInclusive = Value(taxInclusive),
       serviceChargeEnabled = Value(serviceChargeEnabled),
       serviceChargeBps = Value(serviceChargeBps),
       serviceChargeTaxable = Value(serviceChargeTaxable),
       roundingMode = Value(roundingMode),
       roundingUnit = Value(roundingUnit),
       discountApprovalBps = Value(discountApprovalBps),
       kasbonEnabled = Value(kasbonEnabled),
       receiptFooter = Value(receiptFooter),
       receiptPaperMm = Value(receiptPaperMm);
  static Insertable<LocalStoreSettingsRow> custom({
    Expression<String>? storeId,
    Expression<bool>? taxEnabled,
    Expression<String>? taxName,
    Expression<int>? taxRateBps,
    Expression<bool>? taxInclusive,
    Expression<bool>? serviceChargeEnabled,
    Expression<int>? serviceChargeBps,
    Expression<bool>? serviceChargeTaxable,
    Expression<String>? roundingMode,
    Expression<int>? roundingUnit,
    Expression<int>? discountApprovalBps,
    Expression<bool>? kasbonEnabled,
    Expression<String>? receiptHeader,
    Expression<String>? receiptFooter,
    Expression<int>? receiptPaperMm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (storeId != null) 'store_id': storeId,
      if (taxEnabled != null) 'tax_enabled': taxEnabled,
      if (taxName != null) 'tax_name': taxName,
      if (taxRateBps != null) 'tax_rate_bps': taxRateBps,
      if (taxInclusive != null) 'tax_inclusive': taxInclusive,
      if (serviceChargeEnabled != null)
        'service_charge_enabled': serviceChargeEnabled,
      if (serviceChargeBps != null) 'service_charge_bps': serviceChargeBps,
      if (serviceChargeTaxable != null)
        'service_charge_taxable': serviceChargeTaxable,
      if (roundingMode != null) 'rounding_mode': roundingMode,
      if (roundingUnit != null) 'rounding_unit': roundingUnit,
      if (discountApprovalBps != null)
        'discount_approval_bps': discountApprovalBps,
      if (kasbonEnabled != null) 'kasbon_enabled': kasbonEnabled,
      if (receiptHeader != null) 'receipt_header': receiptHeader,
      if (receiptFooter != null) 'receipt_footer': receiptFooter,
      if (receiptPaperMm != null) 'receipt_paper_mm': receiptPaperMm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStoreSettingsCompanion copyWith({
    Value<String>? storeId,
    Value<bool>? taxEnabled,
    Value<String>? taxName,
    Value<int>? taxRateBps,
    Value<bool>? taxInclusive,
    Value<bool>? serviceChargeEnabled,
    Value<int>? serviceChargeBps,
    Value<bool>? serviceChargeTaxable,
    Value<String>? roundingMode,
    Value<int>? roundingUnit,
    Value<int>? discountApprovalBps,
    Value<bool>? kasbonEnabled,
    Value<String?>? receiptHeader,
    Value<String>? receiptFooter,
    Value<int>? receiptPaperMm,
    Value<int>? rowid,
  }) {
    return LocalStoreSettingsCompanion(
      storeId: storeId ?? this.storeId,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      taxName: taxName ?? this.taxName,
      taxRateBps: taxRateBps ?? this.taxRateBps,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      serviceChargeEnabled: serviceChargeEnabled ?? this.serviceChargeEnabled,
      serviceChargeBps: serviceChargeBps ?? this.serviceChargeBps,
      serviceChargeTaxable: serviceChargeTaxable ?? this.serviceChargeTaxable,
      roundingMode: roundingMode ?? this.roundingMode,
      roundingUnit: roundingUnit ?? this.roundingUnit,
      discountApprovalBps: discountApprovalBps ?? this.discountApprovalBps,
      kasbonEnabled: kasbonEnabled ?? this.kasbonEnabled,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      receiptPaperMm: receiptPaperMm ?? this.receiptPaperMm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (taxEnabled.present) {
      map['tax_enabled'] = Variable<bool>(taxEnabled.value);
    }
    if (taxName.present) {
      map['tax_name'] = Variable<String>(taxName.value);
    }
    if (taxRateBps.present) {
      map['tax_rate_bps'] = Variable<int>(taxRateBps.value);
    }
    if (taxInclusive.present) {
      map['tax_inclusive'] = Variable<bool>(taxInclusive.value);
    }
    if (serviceChargeEnabled.present) {
      map['service_charge_enabled'] = Variable<bool>(
        serviceChargeEnabled.value,
      );
    }
    if (serviceChargeBps.present) {
      map['service_charge_bps'] = Variable<int>(serviceChargeBps.value);
    }
    if (serviceChargeTaxable.present) {
      map['service_charge_taxable'] = Variable<bool>(
        serviceChargeTaxable.value,
      );
    }
    if (roundingMode.present) {
      map['rounding_mode'] = Variable<String>(roundingMode.value);
    }
    if (roundingUnit.present) {
      map['rounding_unit'] = Variable<int>(roundingUnit.value);
    }
    if (discountApprovalBps.present) {
      map['discount_approval_bps'] = Variable<int>(discountApprovalBps.value);
    }
    if (kasbonEnabled.present) {
      map['kasbon_enabled'] = Variable<bool>(kasbonEnabled.value);
    }
    if (receiptHeader.present) {
      map['receipt_header'] = Variable<String>(receiptHeader.value);
    }
    if (receiptFooter.present) {
      map['receipt_footer'] = Variable<String>(receiptFooter.value);
    }
    if (receiptPaperMm.present) {
      map['receipt_paper_mm'] = Variable<int>(receiptPaperMm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStoreSettingsCompanion(')
          ..write('storeId: $storeId, ')
          ..write('taxEnabled: $taxEnabled, ')
          ..write('taxName: $taxName, ')
          ..write('taxRateBps: $taxRateBps, ')
          ..write('taxInclusive: $taxInclusive, ')
          ..write('serviceChargeEnabled: $serviceChargeEnabled, ')
          ..write('serviceChargeBps: $serviceChargeBps, ')
          ..write('serviceChargeTaxable: $serviceChargeTaxable, ')
          ..write('roundingMode: $roundingMode, ')
          ..write('roundingUnit: $roundingUnit, ')
          ..write('discountApprovalBps: $discountApprovalBps, ')
          ..write('kasbonEnabled: $kasbonEnabled, ')
          ..write('receiptHeader: $receiptHeader, ')
          ..write('receiptFooter: $receiptFooter, ')
          ..write('receiptPaperMm: $receiptPaperMm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStaffTable extends LocalStaff
    with TableInfo<$LocalStaffTable, LocalStaffRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStaffTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleCodeMeta = const VerificationMeta(
    'roleCode',
  );
  @override
  late final GeneratedColumn<String> roleCode = GeneratedColumn<String>(
    'role_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionsMeta = const VerificationMeta(
    'permissions',
  );
  @override
  late final GeneratedColumn<String> permissions = GeneratedColumn<String>(
    'permissions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    employeeId,
    fullName,
    roleCode,
    permissions,
    pinHash,
    isActive,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_staff';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStaffRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('role_code')) {
      context.handle(
        _roleCodeMeta,
        roleCode.isAcceptableOrUnknown(data['role_code']!, _roleCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_roleCodeMeta);
    }
    if (data.containsKey('permissions')) {
      context.handle(
        _permissionsMeta,
        permissions.isAcceptableOrUnknown(
          data['permissions']!,
          _permissionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_permissionsMeta);
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {employeeId};
  @override
  LocalStaffRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStaffRow(
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      roleCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_code'],
      )!,
      permissions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permissions'],
      )!,
      pinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_hash'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalStaffTable createAlias(String alias) {
    return $LocalStaffTable(attachedDatabase, alias);
  }
}

class LocalStaffRow extends DataClass implements Insertable<LocalStaffRow> {
  final String employeeId;
  final String fullName;
  final String roleCode;

  /// JSON array of permission codes.
  final String permissions;
  final String? pinHash;
  final bool isActive;
  final DateTime syncedAt;
  const LocalStaffRow({
    required this.employeeId,
    required this.fullName,
    required this.roleCode,
    required this.permissions,
    this.pinHash,
    required this.isActive,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['employee_id'] = Variable<String>(employeeId);
    map['full_name'] = Variable<String>(fullName);
    map['role_code'] = Variable<String>(roleCode);
    map['permissions'] = Variable<String>(permissions);
    if (!nullToAbsent || pinHash != null) {
      map['pin_hash'] = Variable<String>(pinHash);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalStaffCompanion toCompanion(bool nullToAbsent) {
    return LocalStaffCompanion(
      employeeId: Value(employeeId),
      fullName: Value(fullName),
      roleCode: Value(roleCode),
      permissions: Value(permissions),
      pinHash: pinHash == null && nullToAbsent
          ? const Value.absent()
          : Value(pinHash),
      isActive: Value(isActive),
      syncedAt: Value(syncedAt),
    );
  }

  factory LocalStaffRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStaffRow(
      employeeId: serializer.fromJson<String>(json['employeeId']),
      fullName: serializer.fromJson<String>(json['fullName']),
      roleCode: serializer.fromJson<String>(json['roleCode']),
      permissions: serializer.fromJson<String>(json['permissions']),
      pinHash: serializer.fromJson<String?>(json['pinHash']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'employeeId': serializer.toJson<String>(employeeId),
      'fullName': serializer.toJson<String>(fullName),
      'roleCode': serializer.toJson<String>(roleCode),
      'permissions': serializer.toJson<String>(permissions),
      'pinHash': serializer.toJson<String?>(pinHash),
      'isActive': serializer.toJson<bool>(isActive),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  LocalStaffRow copyWith({
    String? employeeId,
    String? fullName,
    String? roleCode,
    String? permissions,
    Value<String?> pinHash = const Value.absent(),
    bool? isActive,
    DateTime? syncedAt,
  }) => LocalStaffRow(
    employeeId: employeeId ?? this.employeeId,
    fullName: fullName ?? this.fullName,
    roleCode: roleCode ?? this.roleCode,
    permissions: permissions ?? this.permissions,
    pinHash: pinHash.present ? pinHash.value : this.pinHash,
    isActive: isActive ?? this.isActive,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  LocalStaffRow copyWithCompanion(LocalStaffCompanion data) {
    return LocalStaffRow(
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      roleCode: data.roleCode.present ? data.roleCode.value : this.roleCode,
      permissions: data.permissions.present
          ? data.permissions.value
          : this.permissions,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStaffRow(')
          ..write('employeeId: $employeeId, ')
          ..write('fullName: $fullName, ')
          ..write('roleCode: $roleCode, ')
          ..write('permissions: $permissions, ')
          ..write('pinHash: $pinHash, ')
          ..write('isActive: $isActive, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    employeeId,
    fullName,
    roleCode,
    permissions,
    pinHash,
    isActive,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStaffRow &&
          other.employeeId == this.employeeId &&
          other.fullName == this.fullName &&
          other.roleCode == this.roleCode &&
          other.permissions == this.permissions &&
          other.pinHash == this.pinHash &&
          other.isActive == this.isActive &&
          other.syncedAt == this.syncedAt);
}

class LocalStaffCompanion extends UpdateCompanion<LocalStaffRow> {
  final Value<String> employeeId;
  final Value<String> fullName;
  final Value<String> roleCode;
  final Value<String> permissions;
  final Value<String?> pinHash;
  final Value<bool> isActive;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalStaffCompanion({
    this.employeeId = const Value.absent(),
    this.fullName = const Value.absent(),
    this.roleCode = const Value.absent(),
    this.permissions = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStaffCompanion.insert({
    required String employeeId,
    required String fullName,
    required String roleCode,
    required String permissions,
    this.pinHash = const Value.absent(),
    required bool isActive,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : employeeId = Value(employeeId),
       fullName = Value(fullName),
       roleCode = Value(roleCode),
       permissions = Value(permissions),
       isActive = Value(isActive),
       syncedAt = Value(syncedAt);
  static Insertable<LocalStaffRow> custom({
    Expression<String>? employeeId,
    Expression<String>? fullName,
    Expression<String>? roleCode,
    Expression<String>? permissions,
    Expression<String>? pinHash,
    Expression<bool>? isActive,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (employeeId != null) 'employee_id': employeeId,
      if (fullName != null) 'full_name': fullName,
      if (roleCode != null) 'role_code': roleCode,
      if (permissions != null) 'permissions': permissions,
      if (pinHash != null) 'pin_hash': pinHash,
      if (isActive != null) 'is_active': isActive,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStaffCompanion copyWith({
    Value<String>? employeeId,
    Value<String>? fullName,
    Value<String>? roleCode,
    Value<String>? permissions,
    Value<String?>? pinHash,
    Value<bool>? isActive,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalStaffCompanion(
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      roleCode: roleCode ?? this.roleCode,
      permissions: permissions ?? this.permissions,
      pinHash: pinHash ?? this.pinHash,
      isActive: isActive ?? this.isActive,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (roleCode.present) {
      map['role_code'] = Variable<String>(roleCode.value);
    }
    if (permissions.present) {
      map['permissions'] = Variable<String>(permissions.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStaffCompanion(')
          ..write('employeeId: $employeeId, ')
          ..write('fullName: $fullName, ')
          ..write('roleCode: $roleCode, ')
          ..write('permissions: $permissions, ')
          ..write('pinHash: $pinHash, ')
          ..write('isActive: $isActive, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PinAttemptsTable extends PinAttempts
    with TableInfo<$PinAttemptsTable, PinAttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PinAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failedAttemptsMeta = const VerificationMeta(
    'failedAttempts',
  );
  @override
  late final GeneratedColumn<int> failedAttempts = GeneratedColumn<int>(
    'failed_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lockedUntilMeta = const VerificationMeta(
    'lockedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> lockedUntil = GeneratedColumn<DateTime>(
    'locked_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    employeeId,
    failedAttempts,
    lockedUntil,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pin_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PinAttemptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('failed_attempts')) {
      context.handle(
        _failedAttemptsMeta,
        failedAttempts.isAcceptableOrUnknown(
          data['failed_attempts']!,
          _failedAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('locked_until')) {
      context.handle(
        _lockedUntilMeta,
        lockedUntil.isAcceptableOrUnknown(
          data['locked_until']!,
          _lockedUntilMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {employeeId};
  @override
  PinAttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PinAttemptRow(
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      )!,
      failedAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_attempts'],
      )!,
      lockedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_until'],
      ),
    );
  }

  @override
  $PinAttemptsTable createAlias(String alias) {
    return $PinAttemptsTable(attachedDatabase, alias);
  }
}

class PinAttemptRow extends DataClass implements Insertable<PinAttemptRow> {
  final String employeeId;
  final int failedAttempts;
  final DateTime? lockedUntil;
  const PinAttemptRow({
    required this.employeeId,
    required this.failedAttempts,
    this.lockedUntil,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['employee_id'] = Variable<String>(employeeId);
    map['failed_attempts'] = Variable<int>(failedAttempts);
    if (!nullToAbsent || lockedUntil != null) {
      map['locked_until'] = Variable<DateTime>(lockedUntil);
    }
    return map;
  }

  PinAttemptsCompanion toCompanion(bool nullToAbsent) {
    return PinAttemptsCompanion(
      employeeId: Value(employeeId),
      failedAttempts: Value(failedAttempts),
      lockedUntil: lockedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedUntil),
    );
  }

  factory PinAttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PinAttemptRow(
      employeeId: serializer.fromJson<String>(json['employeeId']),
      failedAttempts: serializer.fromJson<int>(json['failedAttempts']),
      lockedUntil: serializer.fromJson<DateTime?>(json['lockedUntil']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'employeeId': serializer.toJson<String>(employeeId),
      'failedAttempts': serializer.toJson<int>(failedAttempts),
      'lockedUntil': serializer.toJson<DateTime?>(lockedUntil),
    };
  }

  PinAttemptRow copyWith({
    String? employeeId,
    int? failedAttempts,
    Value<DateTime?> lockedUntil = const Value.absent(),
  }) => PinAttemptRow(
    employeeId: employeeId ?? this.employeeId,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntil: lockedUntil.present ? lockedUntil.value : this.lockedUntil,
  );
  PinAttemptRow copyWithCompanion(PinAttemptsCompanion data) {
    return PinAttemptRow(
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      failedAttempts: data.failedAttempts.present
          ? data.failedAttempts.value
          : this.failedAttempts,
      lockedUntil: data.lockedUntil.present
          ? data.lockedUntil.value
          : this.lockedUntil,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PinAttemptRow(')
          ..write('employeeId: $employeeId, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('lockedUntil: $lockedUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(employeeId, failedAttempts, lockedUntil);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PinAttemptRow &&
          other.employeeId == this.employeeId &&
          other.failedAttempts == this.failedAttempts &&
          other.lockedUntil == this.lockedUntil);
}

class PinAttemptsCompanion extends UpdateCompanion<PinAttemptRow> {
  final Value<String> employeeId;
  final Value<int> failedAttempts;
  final Value<DateTime?> lockedUntil;
  final Value<int> rowid;
  const PinAttemptsCompanion({
    this.employeeId = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PinAttemptsCompanion.insert({
    required String employeeId,
    this.failedAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : employeeId = Value(employeeId);
  static Insertable<PinAttemptRow> custom({
    Expression<String>? employeeId,
    Expression<int>? failedAttempts,
    Expression<DateTime>? lockedUntil,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (employeeId != null) 'employee_id': employeeId,
      if (failedAttempts != null) 'failed_attempts': failedAttempts,
      if (lockedUntil != null) 'locked_until': lockedUntil,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PinAttemptsCompanion copyWith({
    Value<String>? employeeId,
    Value<int>? failedAttempts,
    Value<DateTime?>? lockedUntil,
    Value<int>? rowid,
  }) {
    return PinAttemptsCompanion(
      employeeId: employeeId ?? this.employeeId,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (failedAttempts.present) {
      map['failed_attempts'] = Variable<int>(failedAttempts.value);
    }
    if (lockedUntil.present) {
      map['locked_until'] = Variable<DateTime>(lockedUntil.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PinAttemptsCompanion(')
          ..write('employeeId: $employeeId, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  SyncCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorRow(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursorRow extends DataClass implements Insertable<SyncCursorRow> {
  final String name;
  final String value;
  const SyncCursorRow({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(name: Value(name), value: Value(value));
  }

  factory SyncCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorRow(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncCursorRow copyWith({String? name, String? value}) =>
      SyncCursorRow(name: name ?? this.name, value: value ?? this.value);
  SyncCursorRow copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursorRow(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorRow(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorRow &&
          other.name == this.name &&
          other.value == this.value);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursorRow> {
  final Value<String> name;
  final Value<String> value;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String name,
    required String value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<SyncCursorRow> custom({
    Expression<String>? name,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? name,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kitchenStationMeta = const VerificationMeta(
    'kitchenStation',
  );
  @override
  late final GeneratedColumn<String> kitchenStation = GeneratedColumn<String>(
    'kitchen_station',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    name,
    sortOrder,
    color,
    icon,
    kitchenStation,
    isActive,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('kitchen_station')) {
      context.handle(
        _kitchenStationMeta,
        kitchenStation.isAcceptableOrUnknown(
          data['kitchen_station']!,
          _kitchenStationMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      kitchenStation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kitchen_station'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String? parentId;
  final String name;
  final int sortOrder;
  final String? color;
  final String? icon;
  final String? kitchenStation;
  final bool isActive;
  final DateTime updatedAt;
  const CategoryRow({
    required this.id,
    this.parentId,
    required this.name,
    required this.sortOrder,
    this.color,
    this.icon,
    this.kitchenStation,
    required this.isActive,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || kitchenStation != null) {
      map['kitchen_station'] = Variable<String>(kitchenStation);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      sortOrder: Value(sortOrder),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      kitchenStation: kitchenStation == null && nullToAbsent
          ? const Value.absent()
          : Value(kitchenStation),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      kitchenStation: serializer.fromJson<String?>(json['kitchenStation']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
      'kitchenStation': serializer.toJson<String?>(kitchenStation),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CategoryRow copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? name,
    int? sortOrder,
    Value<String?> color = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<String?> kitchenStation = const Value.absent(),
    bool? isActive,
    DateTime? updatedAt,
  }) => CategoryRow(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    color: color.present ? color.value : this.color,
    icon: icon.present ? icon.value : this.icon,
    kitchenStation: kitchenStation.present
        ? kitchenStation.value
        : this.kitchenStation,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      kitchenStation: data.kitchenStation.present
          ? data.kitchenStation.value
          : this.kitchenStation,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('kitchenStation: $kitchenStation, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    name,
    sortOrder,
    color,
    icon,
    kitchenStation,
    isActive,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.kitchenStation == this.kitchenStation &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<String?> kitchenStation;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.kitchenStation = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String name,
    required int sortOrder,
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.kitchenStation = const Value.absent(),
    required bool isActive,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sortOrder = Value(sortOrder),
       isActive = Value(isActive),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<String>? kitchenStation,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (kitchenStation != null) 'kitchen_station': kitchenStation,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<String?>? color,
    Value<String?>? icon,
    Value<String?>? kitchenStation,
    Value<bool>? isActive,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      kitchenStation: kitchenStation ?? this.kitchenStation,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (kitchenStation.present) {
      map['kitchen_station'] = Variable<String>(kitchenStation.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('kitchenStation: $kitchenStation, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitsTable extends Units with TableInfo<$UnitsTable, UnitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allowDecimalMeta = const VerificationMeta(
    'allowDecimal',
  );
  @override
  late final GeneratedColumn<bool> allowDecimal = GeneratedColumn<bool>(
    'allow_decimal',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_decimal" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    allowDecimal,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'units';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('allow_decimal')) {
      context.handle(
        _allowDecimalMeta,
        allowDecimal.isAcceptableOrUnknown(
          data['allow_decimal']!,
          _allowDecimalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allowDecimalMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      allowDecimal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_decimal'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UnitsTable createAlias(String alias) {
    return $UnitsTable(attachedDatabase, alias);
  }
}

class UnitRow extends DataClass implements Insertable<UnitRow> {
  final String id;
  final String code;
  final String name;
  final bool allowDecimal;
  final DateTime updatedAt;
  const UnitRow({
    required this.id,
    required this.code,
    required this.name,
    required this.allowDecimal,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['allow_decimal'] = Variable<bool>(allowDecimal);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UnitsCompanion toCompanion(bool nullToAbsent) {
    return UnitsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      allowDecimal: Value(allowDecimal),
      updatedAt: Value(updatedAt),
    );
  }

  factory UnitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnitRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      allowDecimal: serializer.fromJson<bool>(json['allowDecimal']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'allowDecimal': serializer.toJson<bool>(allowDecimal),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UnitRow copyWith({
    String? id,
    String? code,
    String? name,
    bool? allowDecimal,
    DateTime? updatedAt,
  }) => UnitRow(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    allowDecimal: allowDecimal ?? this.allowDecimal,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UnitRow copyWithCompanion(UnitsCompanion data) {
    return UnitRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      allowDecimal: data.allowDecimal.present
          ? data.allowDecimal.value
          : this.allowDecimal,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnitRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('allowDecimal: $allowDecimal, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, allowDecimal, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnitRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.allowDecimal == this.allowDecimal &&
          other.updatedAt == this.updatedAt);
}

class UnitsCompanion extends UpdateCompanion<UnitRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<bool> allowDecimal;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UnitsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.allowDecimal = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitsCompanion.insert({
    required String id,
    required String code,
    required String name,
    required bool allowDecimal,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       name = Value(name),
       allowDecimal = Value(allowDecimal),
       updatedAt = Value(updatedAt);
  static Insertable<UnitRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<bool>? allowDecimal,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (allowDecimal != null) 'allow_decimal': allowDecimal,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitsCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<bool>? allowDecimal,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UnitsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      allowDecimal: allowDecimal ?? this.allowDecimal,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (allowDecimal.present) {
      map['allow_decimal'] = Variable<bool>(allowDecimal.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('allowDecimal: $allowDecimal, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
    'unit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productTypeMeta = const VerificationMeta(
    'productType',
  );
  @override
  late final GeneratedColumn<String> productType = GeneratedColumn<String>(
    'product_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackStockMeta = const VerificationMeta(
    'trackStock',
  );
  @override
  late final GeneratedColumn<bool> trackStock = GeneratedColumn<bool>(
    'track_stock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("track_stock" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isTaxableMeta = const VerificationMeta(
    'isTaxable',
  );
  @override
  late final GeneratedColumn<bool> isTaxable = GeneratedColumn<bool>(
    'is_taxable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_taxable" IN (0, 1))',
    ),
  );
  static const VerificationMeta _kitchenStationMeta = const VerificationMeta(
    'kitchenStation',
  );
  @override
  late final GeneratedColumn<String> kitchenStation = GeneratedColumn<String>(
    'kitchen_station',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    unitId,
    name,
    description,
    productType,
    trackStock,
    isTaxable,
    kitchenStation,
    imagePath,
    isActive,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('unit_id')) {
      context.handle(
        _unitIdMeta,
        unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_unitIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('product_type')) {
      context.handle(
        _productTypeMeta,
        productType.isAcceptableOrUnknown(
          data['product_type']!,
          _productTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productTypeMeta);
    }
    if (data.containsKey('track_stock')) {
      context.handle(
        _trackStockMeta,
        trackStock.isAcceptableOrUnknown(data['track_stock']!, _trackStockMeta),
      );
    } else if (isInserting) {
      context.missing(_trackStockMeta);
    }
    if (data.containsKey('is_taxable')) {
      context.handle(
        _isTaxableMeta,
        isTaxable.isAcceptableOrUnknown(data['is_taxable']!, _isTaxableMeta),
      );
    } else if (isInserting) {
      context.missing(_isTaxableMeta);
    }
    if (data.containsKey('kitchen_station')) {
      context.handle(
        _kitchenStationMeta,
        kitchenStation.isAcceptableOrUnknown(
          data['kitchen_station']!,
          _kitchenStationMeta,
        ),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      unitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      productType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_type'],
      )!,
      trackStock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}track_stock'],
      )!,
      isTaxable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_taxable'],
      )!,
      kitchenStation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kitchen_station'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final String id;
  final String? categoryId;
  final String unitId;
  final String name;
  final String? description;
  final String productType;
  final bool trackStock;
  final bool isTaxable;
  final String? kitchenStation;
  final String? imagePath;
  final bool isActive;
  final DateTime updatedAt;
  const ProductRow({
    required this.id,
    this.categoryId,
    required this.unitId,
    required this.name,
    this.description,
    required this.productType,
    required this.trackStock,
    required this.isTaxable,
    this.kitchenStation,
    this.imagePath,
    required this.isActive,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['unit_id'] = Variable<String>(unitId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['product_type'] = Variable<String>(productType);
    map['track_stock'] = Variable<bool>(trackStock);
    map['is_taxable'] = Variable<bool>(isTaxable);
    if (!nullToAbsent || kitchenStation != null) {
      map['kitchen_station'] = Variable<String>(kitchenStation);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      unitId: Value(unitId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      productType: Value(productType),
      trackStock: Value(trackStock),
      isTaxable: Value(isTaxable),
      kitchenStation: kitchenStation == null && nullToAbsent
          ? const Value.absent()
          : Value(kitchenStation),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      unitId: serializer.fromJson<String>(json['unitId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      productType: serializer.fromJson<String>(json['productType']),
      trackStock: serializer.fromJson<bool>(json['trackStock']),
      isTaxable: serializer.fromJson<bool>(json['isTaxable']),
      kitchenStation: serializer.fromJson<String?>(json['kitchenStation']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String?>(categoryId),
      'unitId': serializer.toJson<String>(unitId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'productType': serializer.toJson<String>(productType),
      'trackStock': serializer.toJson<bool>(trackStock),
      'isTaxable': serializer.toJson<bool>(isTaxable),
      'kitchenStation': serializer.toJson<String?>(kitchenStation),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductRow copyWith({
    String? id,
    Value<String?> categoryId = const Value.absent(),
    String? unitId,
    String? name,
    Value<String?> description = const Value.absent(),
    String? productType,
    bool? trackStock,
    bool? isTaxable,
    Value<String?> kitchenStation = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    bool? isActive,
    DateTime? updatedAt,
  }) => ProductRow(
    id: id ?? this.id,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    unitId: unitId ?? this.unitId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    productType: productType ?? this.productType,
    trackStock: trackStock ?? this.trackStock,
    isTaxable: isTaxable ?? this.isTaxable,
    kitchenStation: kitchenStation.present
        ? kitchenStation.value
        : this.kitchenStation,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      productType: data.productType.present
          ? data.productType.value
          : this.productType,
      trackStock: data.trackStock.present
          ? data.trackStock.value
          : this.trackStock,
      isTaxable: data.isTaxable.present ? data.isTaxable.value : this.isTaxable,
      kitchenStation: data.kitchenStation.present
          ? data.kitchenStation.value
          : this.kitchenStation,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('unitId: $unitId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('productType: $productType, ')
          ..write('trackStock: $trackStock, ')
          ..write('isTaxable: $isTaxable, ')
          ..write('kitchenStation: $kitchenStation, ')
          ..write('imagePath: $imagePath, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    unitId,
    name,
    description,
    productType,
    trackStock,
    isTaxable,
    kitchenStation,
    imagePath,
    isActive,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.unitId == this.unitId &&
          other.name == this.name &&
          other.description == this.description &&
          other.productType == this.productType &&
          other.trackStock == this.trackStock &&
          other.isTaxable == this.isTaxable &&
          other.kitchenStation == this.kitchenStation &&
          other.imagePath == this.imagePath &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<String> id;
  final Value<String?> categoryId;
  final Value<String> unitId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> productType;
  final Value<bool> trackStock;
  final Value<bool> isTaxable;
  final Value<String?> kitchenStation;
  final Value<String?> imagePath;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.productType = const Value.absent(),
    this.trackStock = const Value.absent(),
    this.isTaxable = const Value.absent(),
    this.kitchenStation = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    this.categoryId = const Value.absent(),
    required String unitId,
    required String name,
    this.description = const Value.absent(),
    required String productType,
    required bool trackStock,
    required bool isTaxable,
    this.kitchenStation = const Value.absent(),
    this.imagePath = const Value.absent(),
    required bool isActive,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       unitId = Value(unitId),
       name = Value(name),
       productType = Value(productType),
       trackStock = Value(trackStock),
       isTaxable = Value(isTaxable),
       isActive = Value(isActive),
       updatedAt = Value(updatedAt);
  static Insertable<ProductRow> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? unitId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? productType,
    Expression<bool>? trackStock,
    Expression<bool>? isTaxable,
    Expression<String>? kitchenStation,
    Expression<String>? imagePath,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (unitId != null) 'unit_id': unitId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (productType != null) 'product_type': productType,
      if (trackStock != null) 'track_stock': trackStock,
      if (isTaxable != null) 'is_taxable': isTaxable,
      if (kitchenStation != null) 'kitchen_station': kitchenStation,
      if (imagePath != null) 'image_path': imagePath,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String?>? categoryId,
    Value<String>? unitId,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? productType,
    Value<bool>? trackStock,
    Value<bool>? isTaxable,
    Value<String?>? kitchenStation,
    Value<String?>? imagePath,
    Value<bool>? isActive,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      name: name ?? this.name,
      description: description ?? this.description,
      productType: productType ?? this.productType,
      trackStock: trackStock ?? this.trackStock,
      isTaxable: isTaxable ?? this.isTaxable,
      kitchenStation: kitchenStation ?? this.kitchenStation,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (productType.present) {
      map['product_type'] = Variable<String>(productType.value);
    }
    if (trackStock.present) {
      map['track_stock'] = Variable<bool>(trackStock.value);
    }
    if (isTaxable.present) {
      map['is_taxable'] = Variable<bool>(isTaxable.value);
    }
    if (kitchenStation.present) {
      map['kitchen_station'] = Variable<String>(kitchenStation.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('unitId: $unitId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('productType: $productType, ')
          ..write('trackStock: $trackStock, ')
          ..write('isTaxable: $isTaxable, ')
          ..write('kitchenStation: $kitchenStation, ')
          ..write('imagePath: $imagePath, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductVariantsTable extends ProductVariants
    with TableInfo<$ProductVariantsTable, VariantRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductVariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<int> cost = GeneratedColumn<int>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    name,
    sku,
    barcode,
    price,
    cost,
    sortOrder,
    isActive,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_variants';
  @override
  VerificationContext validateIntegrity(
    Insertable<VariantRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    } else if (isInserting) {
      context.missing(_costMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VariantRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VariantRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductVariantsTable createAlias(String alias) {
    return $ProductVariantsTable(attachedDatabase, alias);
  }
}

class VariantRow extends DataClass implements Insertable<VariantRow> {
  final String id;
  final String productId;
  final String name;
  final String sku;
  final String? barcode;
  final int price;
  final int cost;
  final int sortOrder;
  final bool isActive;
  final DateTime updatedAt;
  const VariantRow({
    required this.id,
    required this.productId,
    required this.name,
    required this.sku,
    this.barcode,
    required this.price,
    required this.cost,
    required this.sortOrder,
    required this.isActive,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['name'] = Variable<String>(name);
    map['sku'] = Variable<String>(sku);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['price'] = Variable<int>(price);
    map['cost'] = Variable<int>(cost);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductVariantsCompanion toCompanion(bool nullToAbsent) {
    return ProductVariantsCompanion(
      id: Value(id),
      productId: Value(productId),
      name: Value(name),
      sku: Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      price: Value(price),
      cost: Value(cost),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory VariantRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VariantRow(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      name: serializer.fromJson<String>(json['name']),
      sku: serializer.fromJson<String>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      price: serializer.fromJson<int>(json['price']),
      cost: serializer.fromJson<int>(json['cost']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'name': serializer.toJson<String>(name),
      'sku': serializer.toJson<String>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'price': serializer.toJson<int>(price),
      'cost': serializer.toJson<int>(cost),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VariantRow copyWith({
    String? id,
    String? productId,
    String? name,
    String? sku,
    Value<String?> barcode = const Value.absent(),
    int? price,
    int? cost,
    int? sortOrder,
    bool? isActive,
    DateTime? updatedAt,
  }) => VariantRow(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    name: name ?? this.name,
    sku: sku ?? this.sku,
    barcode: barcode.present ? barcode.value : this.barcode,
    price: price ?? this.price,
    cost: cost ?? this.cost,
    sortOrder: sortOrder ?? this.sortOrder,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VariantRow copyWithCompanion(ProductVariantsCompanion data) {
    return VariantRow(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      name: data.name.present ? data.name.value : this.name,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      price: data.price.present ? data.price.value : this.price,
      cost: data.cost.present ? data.cost.value : this.cost,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VariantRow(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('price: $price, ')
          ..write('cost: $cost, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    name,
    sku,
    barcode,
    price,
    cost,
    sortOrder,
    isActive,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VariantRow &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.name == this.name &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.price == this.price &&
          other.cost == this.cost &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class ProductVariantsCompanion extends UpdateCompanion<VariantRow> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> name;
  final Value<String> sku;
  final Value<String?> barcode;
  final Value<int> price;
  final Value<int> cost;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductVariantsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.name = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.price = const Value.absent(),
    this.cost = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductVariantsCompanion.insert({
    required String id,
    required String productId,
    required String name,
    required String sku,
    this.barcode = const Value.absent(),
    required int price,
    required int cost,
    required int sortOrder,
    required bool isActive,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       name = Value(name),
       sku = Value(sku),
       price = Value(price),
       cost = Value(cost),
       sortOrder = Value(sortOrder),
       isActive = Value(isActive),
       updatedAt = Value(updatedAt);
  static Insertable<VariantRow> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? name,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<int>? price,
    Expression<int>? cost,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (price != null) 'price': price,
      if (cost != null) 'cost': cost,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductVariantsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? name,
    Value<String>? sku,
    Value<String?>? barcode,
    Value<int>? price,
    Value<int>? cost,
    Value<int>? sortOrder,
    Value<bool>? isActive,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductVariantsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (cost.present) {
      map['cost'] = Variable<int>(cost.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductVariantsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('price: $price, ')
          ..write('cost: $cost, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoreVariantSettingsTable extends StoreVariantSettings
    with TableInfo<$StoreVariantSettingsTable, StoreVariantSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoreVariantSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceOverrideMeta = const VerificationMeta(
    'priceOverride',
  );
  @override
  late final GeneratedColumn<int> priceOverride = GeneratedColumn<int>(
    'price_override',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reorderPointMilliMeta = const VerificationMeta(
    'reorderPointMilli',
  );
  @override
  late final GeneratedColumn<int> reorderPointMilli = GeneratedColumn<int>(
    'reorder_point_milli',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reorderQtyMilliMeta = const VerificationMeta(
    'reorderQtyMilli',
  );
  @override
  late final GeneratedColumn<int> reorderQtyMilli = GeneratedColumn<int>(
    'reorder_qty_milli',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAvailableMeta = const VerificationMeta(
    'isAvailable',
  );
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
    'is_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    variantId,
    priceOverride,
    reorderPointMilli,
    reorderQtyMilli,
    isAvailable,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'store_variant_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoreVariantSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('price_override')) {
      context.handle(
        _priceOverrideMeta,
        priceOverride.isAcceptableOrUnknown(
          data['price_override']!,
          _priceOverrideMeta,
        ),
      );
    }
    if (data.containsKey('reorder_point_milli')) {
      context.handle(
        _reorderPointMilliMeta,
        reorderPointMilli.isAcceptableOrUnknown(
          data['reorder_point_milli']!,
          _reorderPointMilliMeta,
        ),
      );
    }
    if (data.containsKey('reorder_qty_milli')) {
      context.handle(
        _reorderQtyMilliMeta,
        reorderQtyMilli.isAcceptableOrUnknown(
          data['reorder_qty_milli']!,
          _reorderQtyMilliMeta,
        ),
      );
    }
    if (data.containsKey('is_available')) {
      context.handle(
        _isAvailableMeta,
        isAvailable.isAcceptableOrUnknown(
          data['is_available']!,
          _isAvailableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isAvailableMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {variantId};
  @override
  StoreVariantSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreVariantSettingRow(
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      priceOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_override'],
      ),
      reorderPointMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reorder_point_milli'],
      ),
      reorderQtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reorder_qty_milli'],
      ),
      isAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StoreVariantSettingsTable createAlias(String alias) {
    return $StoreVariantSettingsTable(attachedDatabase, alias);
  }
}

class StoreVariantSettingRow extends DataClass
    implements Insertable<StoreVariantSettingRow> {
  final String variantId;
  final int? priceOverride;
  final int? reorderPointMilli;
  final int? reorderQtyMilli;
  final bool isAvailable;
  final DateTime updatedAt;
  const StoreVariantSettingRow({
    required this.variantId,
    this.priceOverride,
    this.reorderPointMilli,
    this.reorderQtyMilli,
    required this.isAvailable,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['variant_id'] = Variable<String>(variantId);
    if (!nullToAbsent || priceOverride != null) {
      map['price_override'] = Variable<int>(priceOverride);
    }
    if (!nullToAbsent || reorderPointMilli != null) {
      map['reorder_point_milli'] = Variable<int>(reorderPointMilli);
    }
    if (!nullToAbsent || reorderQtyMilli != null) {
      map['reorder_qty_milli'] = Variable<int>(reorderQtyMilli);
    }
    map['is_available'] = Variable<bool>(isAvailable);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StoreVariantSettingsCompanion toCompanion(bool nullToAbsent) {
    return StoreVariantSettingsCompanion(
      variantId: Value(variantId),
      priceOverride: priceOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(priceOverride),
      reorderPointMilli: reorderPointMilli == null && nullToAbsent
          ? const Value.absent()
          : Value(reorderPointMilli),
      reorderQtyMilli: reorderQtyMilli == null && nullToAbsent
          ? const Value.absent()
          : Value(reorderQtyMilli),
      isAvailable: Value(isAvailable),
      updatedAt: Value(updatedAt),
    );
  }

  factory StoreVariantSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreVariantSettingRow(
      variantId: serializer.fromJson<String>(json['variantId']),
      priceOverride: serializer.fromJson<int?>(json['priceOverride']),
      reorderPointMilli: serializer.fromJson<int?>(json['reorderPointMilli']),
      reorderQtyMilli: serializer.fromJson<int?>(json['reorderQtyMilli']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'variantId': serializer.toJson<String>(variantId),
      'priceOverride': serializer.toJson<int?>(priceOverride),
      'reorderPointMilli': serializer.toJson<int?>(reorderPointMilli),
      'reorderQtyMilli': serializer.toJson<int?>(reorderQtyMilli),
      'isAvailable': serializer.toJson<bool>(isAvailable),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StoreVariantSettingRow copyWith({
    String? variantId,
    Value<int?> priceOverride = const Value.absent(),
    Value<int?> reorderPointMilli = const Value.absent(),
    Value<int?> reorderQtyMilli = const Value.absent(),
    bool? isAvailable,
    DateTime? updatedAt,
  }) => StoreVariantSettingRow(
    variantId: variantId ?? this.variantId,
    priceOverride: priceOverride.present
        ? priceOverride.value
        : this.priceOverride,
    reorderPointMilli: reorderPointMilli.present
        ? reorderPointMilli.value
        : this.reorderPointMilli,
    reorderQtyMilli: reorderQtyMilli.present
        ? reorderQtyMilli.value
        : this.reorderQtyMilli,
    isAvailable: isAvailable ?? this.isAvailable,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StoreVariantSettingRow copyWithCompanion(StoreVariantSettingsCompanion data) {
    return StoreVariantSettingRow(
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      priceOverride: data.priceOverride.present
          ? data.priceOverride.value
          : this.priceOverride,
      reorderPointMilli: data.reorderPointMilli.present
          ? data.reorderPointMilli.value
          : this.reorderPointMilli,
      reorderQtyMilli: data.reorderQtyMilli.present
          ? data.reorderQtyMilli.value
          : this.reorderQtyMilli,
      isAvailable: data.isAvailable.present
          ? data.isAvailable.value
          : this.isAvailable,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreVariantSettingRow(')
          ..write('variantId: $variantId, ')
          ..write('priceOverride: $priceOverride, ')
          ..write('reorderPointMilli: $reorderPointMilli, ')
          ..write('reorderQtyMilli: $reorderQtyMilli, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    variantId,
    priceOverride,
    reorderPointMilli,
    reorderQtyMilli,
    isAvailable,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreVariantSettingRow &&
          other.variantId == this.variantId &&
          other.priceOverride == this.priceOverride &&
          other.reorderPointMilli == this.reorderPointMilli &&
          other.reorderQtyMilli == this.reorderQtyMilli &&
          other.isAvailable == this.isAvailable &&
          other.updatedAt == this.updatedAt);
}

class StoreVariantSettingsCompanion
    extends UpdateCompanion<StoreVariantSettingRow> {
  final Value<String> variantId;
  final Value<int?> priceOverride;
  final Value<int?> reorderPointMilli;
  final Value<int?> reorderQtyMilli;
  final Value<bool> isAvailable;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StoreVariantSettingsCompanion({
    this.variantId = const Value.absent(),
    this.priceOverride = const Value.absent(),
    this.reorderPointMilli = const Value.absent(),
    this.reorderQtyMilli = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoreVariantSettingsCompanion.insert({
    required String variantId,
    this.priceOverride = const Value.absent(),
    this.reorderPointMilli = const Value.absent(),
    this.reorderQtyMilli = const Value.absent(),
    required bool isAvailable,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : variantId = Value(variantId),
       isAvailable = Value(isAvailable),
       updatedAt = Value(updatedAt);
  static Insertable<StoreVariantSettingRow> custom({
    Expression<String>? variantId,
    Expression<int>? priceOverride,
    Expression<int>? reorderPointMilli,
    Expression<int>? reorderQtyMilli,
    Expression<bool>? isAvailable,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (variantId != null) 'variant_id': variantId,
      if (priceOverride != null) 'price_override': priceOverride,
      if (reorderPointMilli != null) 'reorder_point_milli': reorderPointMilli,
      if (reorderQtyMilli != null) 'reorder_qty_milli': reorderQtyMilli,
      if (isAvailable != null) 'is_available': isAvailable,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoreVariantSettingsCompanion copyWith({
    Value<String>? variantId,
    Value<int?>? priceOverride,
    Value<int?>? reorderPointMilli,
    Value<int?>? reorderQtyMilli,
    Value<bool>? isAvailable,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StoreVariantSettingsCompanion(
      variantId: variantId ?? this.variantId,
      priceOverride: priceOverride ?? this.priceOverride,
      reorderPointMilli: reorderPointMilli ?? this.reorderPointMilli,
      reorderQtyMilli: reorderQtyMilli ?? this.reorderQtyMilli,
      isAvailable: isAvailable ?? this.isAvailable,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (priceOverride.present) {
      map['price_override'] = Variable<int>(priceOverride.value);
    }
    if (reorderPointMilli.present) {
      map['reorder_point_milli'] = Variable<int>(reorderPointMilli.value);
    }
    if (reorderQtyMilli.present) {
      map['reorder_qty_milli'] = Variable<int>(reorderQtyMilli.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoreVariantSettingsCompanion(')
          ..write('variantId: $variantId, ')
          ..write('priceOverride: $priceOverride, ')
          ..write('reorderPointMilli: $reorderPointMilli, ')
          ..write('reorderQtyMilli: $reorderQtyMilli, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModifierGroupsTable extends ModifierGroups
    with TableInfo<$ModifierGroupsTable, ModifierGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModifierGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minSelectMeta = const VerificationMeta(
    'minSelect',
  );
  @override
  late final GeneratedColumn<int> minSelect = GeneratedColumn<int>(
    'min_select',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxSelectMeta = const VerificationMeta(
    'maxSelect',
  );
  @override
  late final GeneratedColumn<int> maxSelect = GeneratedColumn<int>(
    'max_select',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    minSelect,
    maxSelect,
    sortOrder,
    isActive,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'modifier_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModifierGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('min_select')) {
      context.handle(
        _minSelectMeta,
        minSelect.isAcceptableOrUnknown(data['min_select']!, _minSelectMeta),
      );
    } else if (isInserting) {
      context.missing(_minSelectMeta);
    }
    if (data.containsKey('max_select')) {
      context.handle(
        _maxSelectMeta,
        maxSelect.isAcceptableOrUnknown(data['max_select']!, _maxSelectMeta),
      );
    } else if (isInserting) {
      context.missing(_maxSelectMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModifierGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModifierGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      minSelect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_select'],
      )!,
      maxSelect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_select'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ModifierGroupsTable createAlias(String alias) {
    return $ModifierGroupsTable(attachedDatabase, alias);
  }
}

class ModifierGroupRow extends DataClass
    implements Insertable<ModifierGroupRow> {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final int sortOrder;
  final bool isActive;
  final DateTime updatedAt;
  const ModifierGroupRow({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.sortOrder,
    required this.isActive,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['min_select'] = Variable<int>(minSelect);
    map['max_select'] = Variable<int>(maxSelect);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ModifierGroupsCompanion toCompanion(bool nullToAbsent) {
    return ModifierGroupsCompanion(
      id: Value(id),
      name: Value(name),
      minSelect: Value(minSelect),
      maxSelect: Value(maxSelect),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory ModifierGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModifierGroupRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      minSelect: serializer.fromJson<int>(json['minSelect']),
      maxSelect: serializer.fromJson<int>(json['maxSelect']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'minSelect': serializer.toJson<int>(minSelect),
      'maxSelect': serializer.toJson<int>(maxSelect),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ModifierGroupRow copyWith({
    String? id,
    String? name,
    int? minSelect,
    int? maxSelect,
    int? sortOrder,
    bool? isActive,
    DateTime? updatedAt,
  }) => ModifierGroupRow(
    id: id ?? this.id,
    name: name ?? this.name,
    minSelect: minSelect ?? this.minSelect,
    maxSelect: maxSelect ?? this.maxSelect,
    sortOrder: sortOrder ?? this.sortOrder,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ModifierGroupRow copyWithCompanion(ModifierGroupsCompanion data) {
    return ModifierGroupRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      minSelect: data.minSelect.present ? data.minSelect.value : this.minSelect,
      maxSelect: data.maxSelect.present ? data.maxSelect.value : this.maxSelect,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModifierGroupRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('minSelect: $minSelect, ')
          ..write('maxSelect: $maxSelect, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    minSelect,
    maxSelect,
    sortOrder,
    isActive,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModifierGroupRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.minSelect == this.minSelect &&
          other.maxSelect == this.maxSelect &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class ModifierGroupsCompanion extends UpdateCompanion<ModifierGroupRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> minSelect;
  final Value<int> maxSelect;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ModifierGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.minSelect = const Value.absent(),
    this.maxSelect = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModifierGroupsCompanion.insert({
    required String id,
    required String name,
    required int minSelect,
    required int maxSelect,
    required int sortOrder,
    required bool isActive,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       minSelect = Value(minSelect),
       maxSelect = Value(maxSelect),
       sortOrder = Value(sortOrder),
       isActive = Value(isActive),
       updatedAt = Value(updatedAt);
  static Insertable<ModifierGroupRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? minSelect,
    Expression<int>? maxSelect,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (minSelect != null) 'min_select': minSelect,
      if (maxSelect != null) 'max_select': maxSelect,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModifierGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? minSelect,
    Value<int>? maxSelect,
    Value<int>? sortOrder,
    Value<bool>? isActive,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ModifierGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      minSelect: minSelect ?? this.minSelect,
      maxSelect: maxSelect ?? this.maxSelect,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (minSelect.present) {
      map['min_select'] = Variable<int>(minSelect.value);
    }
    if (maxSelect.present) {
      map['max_select'] = Variable<int>(maxSelect.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModifierGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('minSelect: $minSelect, ')
          ..write('maxSelect: $maxSelect, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModifiersTable extends Modifiers
    with TableInfo<$ModifiersTable, ModifierRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModifiersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceDeltaMeta = const VerificationMeta(
    'priceDelta',
  );
  @override
  late final GeneratedColumn<int> priceDelta = GeneratedColumn<int>(
    'price_delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    name,
    priceDelta,
    sortOrder,
    isActive,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'modifiers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModifierRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price_delta')) {
      context.handle(
        _priceDeltaMeta,
        priceDelta.isAcceptableOrUnknown(data['price_delta']!, _priceDeltaMeta),
      );
    } else if (isInserting) {
      context.missing(_priceDeltaMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModifierRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModifierRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      priceDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_delta'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ModifiersTable createAlias(String alias) {
    return $ModifiersTable(attachedDatabase, alias);
  }
}

class ModifierRow extends DataClass implements Insertable<ModifierRow> {
  final String id;
  final String groupId;
  final String name;
  final int priceDelta;
  final int sortOrder;
  final bool isActive;
  final DateTime updatedAt;
  const ModifierRow({
    required this.id,
    required this.groupId,
    required this.name,
    required this.priceDelta,
    required this.sortOrder,
    required this.isActive,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['name'] = Variable<String>(name);
    map['price_delta'] = Variable<int>(priceDelta);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ModifiersCompanion toCompanion(bool nullToAbsent) {
    return ModifiersCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      priceDelta: Value(priceDelta),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory ModifierRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModifierRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      priceDelta: serializer.fromJson<int>(json['priceDelta']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'name': serializer.toJson<String>(name),
      'priceDelta': serializer.toJson<int>(priceDelta),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ModifierRow copyWith({
    String? id,
    String? groupId,
    String? name,
    int? priceDelta,
    int? sortOrder,
    bool? isActive,
    DateTime? updatedAt,
  }) => ModifierRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    priceDelta: priceDelta ?? this.priceDelta,
    sortOrder: sortOrder ?? this.sortOrder,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ModifierRow copyWithCompanion(ModifiersCompanion data) {
    return ModifierRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      priceDelta: data.priceDelta.present
          ? data.priceDelta.value
          : this.priceDelta,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModifierRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('priceDelta: $priceDelta, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    name,
    priceDelta,
    sortOrder,
    isActive,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModifierRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.priceDelta == this.priceDelta &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class ModifiersCompanion extends UpdateCompanion<ModifierRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> name;
  final Value<int> priceDelta;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ModifiersCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.priceDelta = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModifiersCompanion.insert({
    required String id,
    required String groupId,
    required String name,
    required int priceDelta,
    required int sortOrder,
    required bool isActive,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       name = Value(name),
       priceDelta = Value(priceDelta),
       sortOrder = Value(sortOrder),
       isActive = Value(isActive),
       updatedAt = Value(updatedAt);
  static Insertable<ModifierRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? name,
    Expression<int>? priceDelta,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (priceDelta != null) 'price_delta': priceDelta,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModifiersCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? name,
    Value<int>? priceDelta,
    Value<int>? sortOrder,
    Value<bool>? isActive,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ModifiersCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      priceDelta: priceDelta ?? this.priceDelta,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (priceDelta.present) {
      map['price_delta'] = Variable<int>(priceDelta.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModifiersCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('priceDelta: $priceDelta, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductModifierGroupsTable extends ProductModifierGroups
    with TableInfo<$ProductModifierGroupsTable, ProductModifierGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductModifierGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    groupId,
    sortOrder,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_modifier_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductModifierGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId, groupId};
  @override
  ProductModifierGroupRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductModifierGroupRow(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductModifierGroupsTable createAlias(String alias) {
    return $ProductModifierGroupsTable(attachedDatabase, alias);
  }
}

class ProductModifierGroupRow extends DataClass
    implements Insertable<ProductModifierGroupRow> {
  final String productId;
  final String groupId;
  final int sortOrder;
  final DateTime updatedAt;
  const ProductModifierGroupRow({
    required this.productId,
    required this.groupId,
    required this.sortOrder,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['group_id'] = Variable<String>(groupId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductModifierGroupsCompanion toCompanion(bool nullToAbsent) {
    return ProductModifierGroupsCompanion(
      productId: Value(productId),
      groupId: Value(groupId),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductModifierGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductModifierGroupRow(
      productId: serializer.fromJson<String>(json['productId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'groupId': serializer.toJson<String>(groupId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductModifierGroupRow copyWith({
    String? productId,
    String? groupId,
    int? sortOrder,
    DateTime? updatedAt,
  }) => ProductModifierGroupRow(
    productId: productId ?? this.productId,
    groupId: groupId ?? this.groupId,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProductModifierGroupRow copyWithCompanion(
    ProductModifierGroupsCompanion data,
  ) {
    return ProductModifierGroupRow(
      productId: data.productId.present ? data.productId.value : this.productId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductModifierGroupRow(')
          ..write('productId: $productId, ')
          ..write('groupId: $groupId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, groupId, sortOrder, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductModifierGroupRow &&
          other.productId == this.productId &&
          other.groupId == this.groupId &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt);
}

class ProductModifierGroupsCompanion
    extends UpdateCompanion<ProductModifierGroupRow> {
  final Value<String> productId;
  final Value<String> groupId;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductModifierGroupsCompanion({
    this.productId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductModifierGroupsCompanion.insert({
    required String productId,
    required String groupId,
    required int sortOrder,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       groupId = Value(groupId),
       sortOrder = Value(sortOrder),
       updatedAt = Value(updatedAt);
  static Insertable<ProductModifierGroupRow> custom({
    Expression<String>? productId,
    Expression<String>? groupId,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (groupId != null) 'group_id': groupId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductModifierGroupsCompanion copyWith({
    Value<String>? productId,
    Value<String>? groupId,
    Value<int>? sortOrder,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductModifierGroupsCompanion(
      productId: productId ?? this.productId,
      groupId: groupId ?? this.groupId,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductModifierGroupsCompanion(')
          ..write('productId: $productId, ')
          ..write('groupId: $groupId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoreFavoritesTable extends StoreFavorites
    with TableInfo<$StoreFavoritesTable, StoreFavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoreFavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [productId, sortOrder, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'store_favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoreFavoriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId};
  @override
  StoreFavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreFavoriteRow(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StoreFavoritesTable createAlias(String alias) {
    return $StoreFavoritesTable(attachedDatabase, alias);
  }
}

class StoreFavoriteRow extends DataClass
    implements Insertable<StoreFavoriteRow> {
  final String productId;
  final int sortOrder;
  final DateTime updatedAt;
  const StoreFavoriteRow({
    required this.productId,
    required this.sortOrder,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StoreFavoritesCompanion toCompanion(bool nullToAbsent) {
    return StoreFavoritesCompanion(
      productId: Value(productId),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
    );
  }

  factory StoreFavoriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreFavoriteRow(
      productId: serializer.fromJson<String>(json['productId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StoreFavoriteRow copyWith({
    String? productId,
    int? sortOrder,
    DateTime? updatedAt,
  }) => StoreFavoriteRow(
    productId: productId ?? this.productId,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StoreFavoriteRow copyWithCompanion(StoreFavoritesCompanion data) {
    return StoreFavoriteRow(
      productId: data.productId.present ? data.productId.value : this.productId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreFavoriteRow(')
          ..write('productId: $productId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, sortOrder, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreFavoriteRow &&
          other.productId == this.productId &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt);
}

class StoreFavoritesCompanion extends UpdateCompanion<StoreFavoriteRow> {
  final Value<String> productId;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StoreFavoritesCompanion({
    this.productId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoreFavoritesCompanion.insert({
    required String productId,
    required int sortOrder,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       sortOrder = Value(sortOrder),
       updatedAt = Value(updatedAt);
  static Insertable<StoreFavoriteRow> custom({
    Expression<String>? productId,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoreFavoritesCompanion copyWith({
    Value<String>? productId,
    Value<int>? sortOrder,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StoreFavoritesCompanion(
      productId: productId ?? this.productId,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoreFavoritesCompanion(')
          ..write('productId: $productId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockLevelsTable extends StockLevels
    with TableInfo<$StockLevelsTable, StockLevelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockLevelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMilliMeta = const VerificationMeta(
    'quantityMilli',
  );
  @override
  late final GeneratedColumn<int> quantityMilli = GeneratedColumn<int>(
    'quantity_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [variantId, quantityMilli, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_levels';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockLevelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('quantity_milli')) {
      context.handle(
        _quantityMilliMeta,
        quantityMilli.isAcceptableOrUnknown(
          data['quantity_milli']!,
          _quantityMilliMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityMilliMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {variantId};
  @override
  StockLevelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockLevelRow(
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      quantityMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_milli'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StockLevelsTable createAlias(String alias) {
    return $StockLevelsTable(attachedDatabase, alias);
  }
}

class StockLevelRow extends DataClass implements Insertable<StockLevelRow> {
  final String variantId;
  final int quantityMilli;
  final DateTime updatedAt;
  const StockLevelRow({
    required this.variantId,
    required this.quantityMilli,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['variant_id'] = Variable<String>(variantId);
    map['quantity_milli'] = Variable<int>(quantityMilli);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StockLevelsCompanion toCompanion(bool nullToAbsent) {
    return StockLevelsCompanion(
      variantId: Value(variantId),
      quantityMilli: Value(quantityMilli),
      updatedAt: Value(updatedAt),
    );
  }

  factory StockLevelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockLevelRow(
      variantId: serializer.fromJson<String>(json['variantId']),
      quantityMilli: serializer.fromJson<int>(json['quantityMilli']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'variantId': serializer.toJson<String>(variantId),
      'quantityMilli': serializer.toJson<int>(quantityMilli),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StockLevelRow copyWith({
    String? variantId,
    int? quantityMilli,
    DateTime? updatedAt,
  }) => StockLevelRow(
    variantId: variantId ?? this.variantId,
    quantityMilli: quantityMilli ?? this.quantityMilli,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StockLevelRow copyWithCompanion(StockLevelsCompanion data) {
    return StockLevelRow(
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      quantityMilli: data.quantityMilli.present
          ? data.quantityMilli.value
          : this.quantityMilli,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockLevelRow(')
          ..write('variantId: $variantId, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(variantId, quantityMilli, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockLevelRow &&
          other.variantId == this.variantId &&
          other.quantityMilli == this.quantityMilli &&
          other.updatedAt == this.updatedAt);
}

class StockLevelsCompanion extends UpdateCompanion<StockLevelRow> {
  final Value<String> variantId;
  final Value<int> quantityMilli;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StockLevelsCompanion({
    this.variantId = const Value.absent(),
    this.quantityMilli = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockLevelsCompanion.insert({
    required String variantId,
    required int quantityMilli,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : variantId = Value(variantId),
       quantityMilli = Value(quantityMilli),
       updatedAt = Value(updatedAt);
  static Insertable<StockLevelRow> custom({
    Expression<String>? variantId,
    Expression<int>? quantityMilli,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (variantId != null) 'variant_id': variantId,
      if (quantityMilli != null) 'quantity_milli': quantityMilli,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockLevelsCompanion copyWith({
    Value<String>? variantId,
    Value<int>? quantityMilli,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StockLevelsCompanion(
      variantId: variantId ?? this.variantId,
      quantityMilli: quantityMilli ?? this.quantityMilli,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (quantityMilli.present) {
      map['quantity_milli'] = Variable<int>(quantityMilli.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockLevelsCompanion(')
          ..write('variantId: $variantId, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MirrorRecordsTable extends MirrorRecords
    with TableInfo<$MirrorRecordsTable, MirrorRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MirrorRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceTableMeta = const VerificationMeta(
    'sourceTable',
  );
  @override
  late final GeneratedColumn<String> sourceTable = GeneratedColumn<String>(
    'source_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pkMeta = const VerificationMeta('pk');
  @override
  late final GeneratedColumn<String> pk = GeneratedColumn<String>(
    'pk',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sourceTable, pk, data, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mirror_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MirrorRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_table')) {
      context.handle(
        _sourceTableMeta,
        sourceTable.isAcceptableOrUnknown(
          data['source_table']!,
          _sourceTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceTableMeta);
    }
    if (data.containsKey('pk')) {
      context.handle(_pkMeta, pk.isAcceptableOrUnknown(data['pk']!, _pkMeta));
    } else if (isInserting) {
      context.missing(_pkMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceTable, pk};
  @override
  MirrorRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MirrorRecordRow(
      sourceTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_table'],
      )!,
      pk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pk'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MirrorRecordsTable createAlias(String alias) {
    return $MirrorRecordsTable(attachedDatabase, alias);
  }
}

class MirrorRecordRow extends DataClass implements Insertable<MirrorRecordRow> {
  final String sourceTable;
  final String pk;

  /// The server row as JSON.
  final String data;
  final DateTime updatedAt;
  const MirrorRecordRow({
    required this.sourceTable,
    required this.pk,
    required this.data,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_table'] = Variable<String>(sourceTable);
    map['pk'] = Variable<String>(pk);
    map['data'] = Variable<String>(data);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MirrorRecordsCompanion toCompanion(bool nullToAbsent) {
    return MirrorRecordsCompanion(
      sourceTable: Value(sourceTable),
      pk: Value(pk),
      data: Value(data),
      updatedAt: Value(updatedAt),
    );
  }

  factory MirrorRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MirrorRecordRow(
      sourceTable: serializer.fromJson<String>(json['sourceTable']),
      pk: serializer.fromJson<String>(json['pk']),
      data: serializer.fromJson<String>(json['data']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceTable': serializer.toJson<String>(sourceTable),
      'pk': serializer.toJson<String>(pk),
      'data': serializer.toJson<String>(data),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MirrorRecordRow copyWith({
    String? sourceTable,
    String? pk,
    String? data,
    DateTime? updatedAt,
  }) => MirrorRecordRow(
    sourceTable: sourceTable ?? this.sourceTable,
    pk: pk ?? this.pk,
    data: data ?? this.data,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MirrorRecordRow copyWithCompanion(MirrorRecordsCompanion data) {
    return MirrorRecordRow(
      sourceTable: data.sourceTable.present
          ? data.sourceTable.value
          : this.sourceTable,
      pk: data.pk.present ? data.pk.value : this.pk,
      data: data.data.present ? data.data.value : this.data,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MirrorRecordRow(')
          ..write('sourceTable: $sourceTable, ')
          ..write('pk: $pk, ')
          ..write('data: $data, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceTable, pk, data, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MirrorRecordRow &&
          other.sourceTable == this.sourceTable &&
          other.pk == this.pk &&
          other.data == this.data &&
          other.updatedAt == this.updatedAt);
}

class MirrorRecordsCompanion extends UpdateCompanion<MirrorRecordRow> {
  final Value<String> sourceTable;
  final Value<String> pk;
  final Value<String> data;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MirrorRecordsCompanion({
    this.sourceTable = const Value.absent(),
    this.pk = const Value.absent(),
    this.data = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MirrorRecordsCompanion.insert({
    required String sourceTable,
    required String pk,
    required String data,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : sourceTable = Value(sourceTable),
       pk = Value(pk),
       data = Value(data),
       updatedAt = Value(updatedAt);
  static Insertable<MirrorRecordRow> custom({
    Expression<String>? sourceTable,
    Expression<String>? pk,
    Expression<String>? data,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceTable != null) 'source_table': sourceTable,
      if (pk != null) 'pk': pk,
      if (data != null) 'data': data,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MirrorRecordsCompanion copyWith({
    Value<String>? sourceTable,
    Value<String>? pk,
    Value<String>? data,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MirrorRecordsCompanion(
      sourceTable: sourceTable ?? this.sourceTable,
      pk: pk ?? this.pk,
      data: data ?? this.data,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceTable.present) {
      map['source_table'] = Variable<String>(sourceTable.value);
    }
    if (pk.present) {
      map['pk'] = Variable<String>(pk.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MirrorRecordsCompanion(')
          ..write('sourceTable: $sourceTable, ')
          ..write('pk: $pk, ')
          ..write('data: $data, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCustomersTable extends LocalCustomers
    with TableInfo<$LocalCustomersTable, CustomerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pointsBalanceMeta = const VerificationMeta(
    'pointsBalance',
  );
  @override
  late final GeneratedColumn<int> pointsBalance = GeneratedColumn<int>(
    'points_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _kasbonLimitMeta = const VerificationMeta(
    'kasbonLimit',
  );
  @override
  late final GeneratedColumn<int> kasbonLimit = GeneratedColumn<int>(
    'kasbon_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    phone,
    pointsBalance,
    kasbonLimit,
    isActive,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('points_balance')) {
      context.handle(
        _pointsBalanceMeta,
        pointsBalance.isAcceptableOrUnknown(
          data['points_balance']!,
          _pointsBalanceMeta,
        ),
      );
    }
    if (data.containsKey('kasbon_limit')) {
      context.handle(
        _kasbonLimitMeta,
        kasbonLimit.isAcceptableOrUnknown(
          data['kasbon_limit']!,
          _kasbonLimitMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      pointsBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points_balance'],
      )!,
      kasbonLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kasbon_limit'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalCustomersTable createAlias(String alias) {
    return $LocalCustomersTable(attachedDatabase, alias);
  }
}

class CustomerRow extends DataClass implements Insertable<CustomerRow> {
  final String id;
  final String? code;
  final String name;
  final String? phone;
  final int pointsBalance;
  final int? kasbonLimit;
  final bool isActive;
  final DateTime updatedAt;
  const CustomerRow({
    required this.id,
    this.code,
    required this.name,
    this.phone,
    required this.pointsBalance,
    this.kasbonLimit,
    required this.isActive,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['points_balance'] = Variable<int>(pointsBalance);
    if (!nullToAbsent || kasbonLimit != null) {
      map['kasbon_limit'] = Variable<int>(kasbonLimit);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalCustomersCompanion toCompanion(bool nullToAbsent) {
    return LocalCustomersCompanion(
      id: Value(id),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      pointsBalance: Value(pointsBalance),
      kasbonLimit: kasbonLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(kasbonLimit),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String?>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      pointsBalance: serializer.fromJson<int>(json['pointsBalance']),
      kasbonLimit: serializer.fromJson<int?>(json['kasbonLimit']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String?>(code),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'pointsBalance': serializer.toJson<int>(pointsBalance),
      'kasbonLimit': serializer.toJson<int?>(kasbonLimit),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CustomerRow copyWith({
    String? id,
    Value<String?> code = const Value.absent(),
    String? name,
    Value<String?> phone = const Value.absent(),
    int? pointsBalance,
    Value<int?> kasbonLimit = const Value.absent(),
    bool? isActive,
    DateTime? updatedAt,
  }) => CustomerRow(
    id: id ?? this.id,
    code: code.present ? code.value : this.code,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    pointsBalance: pointsBalance ?? this.pointsBalance,
    kasbonLimit: kasbonLimit.present ? kasbonLimit.value : this.kasbonLimit,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomerRow copyWithCompanion(LocalCustomersCompanion data) {
    return CustomerRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      pointsBalance: data.pointsBalance.present
          ? data.pointsBalance.value
          : this.pointsBalance,
      kasbonLimit: data.kasbonLimit.present
          ? data.kasbonLimit.value
          : this.kasbonLimit,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('pointsBalance: $pointsBalance, ')
          ..write('kasbonLimit: $kasbonLimit, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    name,
    phone,
    pointsBalance,
    kasbonLimit,
    isActive,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.pointsBalance == this.pointsBalance &&
          other.kasbonLimit == this.kasbonLimit &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class LocalCustomersCompanion extends UpdateCompanion<CustomerRow> {
  final Value<String> id;
  final Value<String?> code;
  final Value<String> name;
  final Value<String?> phone;
  final Value<int> pointsBalance;
  final Value<int?> kasbonLimit;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalCustomersCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.pointsBalance = const Value.absent(),
    this.kasbonLimit = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCustomersCompanion.insert({
    required String id,
    this.code = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.pointsBalance = const Value.absent(),
    this.kasbonLimit = const Value.absent(),
    required bool isActive,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       isActive = Value(isActive),
       updatedAt = Value(updatedAt);
  static Insertable<CustomerRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<int>? pointsBalance,
    Expression<int>? kasbonLimit,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (pointsBalance != null) 'points_balance': pointsBalance,
      if (kasbonLimit != null) 'kasbon_limit': kasbonLimit,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCustomersCompanion copyWith({
    Value<String>? id,
    Value<String?>? code,
    Value<String>? name,
    Value<String?>? phone,
    Value<int>? pointsBalance,
    Value<int?>? kasbonLimit,
    Value<bool>? isActive,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalCustomersCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      kasbonLimit: kasbonLimit ?? this.kasbonLimit,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (pointsBalance.present) {
      map['points_balance'] = Variable<int>(pointsBalance.value);
    }
    if (kasbonLimit.present) {
      map['kasbon_limit'] = Variable<int>(kasbonLimit.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCustomersCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('pointsBalance: $pointsBalance, ')
          ..write('kasbonLimit: $kasbonLimit, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalShiftsTable extends LocalShifts
    with TableInfo<$LocalShiftsTable, ShiftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShiftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedByMeta = const VerificationMeta(
    'openedBy',
  );
  @override
  late final GeneratedColumn<String> openedBy = GeneratedColumn<String>(
    'opened_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedByNameMeta = const VerificationMeta(
    'openedByName',
  );
  @override
  late final GeneratedColumn<String> openedByName = GeneratedColumn<String>(
    'opened_by_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingCashMeta = const VerificationMeta(
    'openingCash',
  );
  @override
  late final GeneratedColumn<int> openingCash = GeneratedColumn<int>(
    'opening_cash',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedByMeta = const VerificationMeta(
    'closedBy',
  );
  @override
  late final GeneratedColumn<String> closedBy = GeneratedColumn<String>(
    'closed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedByNameMeta = const VerificationMeta(
    'closedByName',
  );
  @override
  late final GeneratedColumn<String> closedByName = GeneratedColumn<String>(
    'closed_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countedCashMeta = const VerificationMeta(
    'countedCash',
  );
  @override
  late final GeneratedColumn<int> countedCash = GeneratedColumn<int>(
    'counted_cash',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedCashMeta = const VerificationMeta(
    'expectedCash',
  );
  @override
  late final GeneratedColumn<int> expectedCash = GeneratedColumn<int>(
    'expected_cash',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closeNoteMeta = const VerificationMeta(
    'closeNote',
  );
  @override
  late final GeneratedColumn<String> closeNote = GeneratedColumn<String>(
    'close_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    openedBy,
    openedByName,
    openedAt,
    openingCash,
    status,
    closedAt,
    closedBy,
    closedByName,
    countedCash,
    expectedCash,
    closeNote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shifts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShiftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('opened_by')) {
      context.handle(
        _openedByMeta,
        openedBy.isAcceptableOrUnknown(data['opened_by']!, _openedByMeta),
      );
    } else if (isInserting) {
      context.missing(_openedByMeta);
    }
    if (data.containsKey('opened_by_name')) {
      context.handle(
        _openedByNameMeta,
        openedByName.isAcceptableOrUnknown(
          data['opened_by_name']!,
          _openedByNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openedByNameMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('opening_cash')) {
      context.handle(
        _openingCashMeta,
        openingCash.isAcceptableOrUnknown(
          data['opening_cash']!,
          _openingCashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingCashMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('closed_by')) {
      context.handle(
        _closedByMeta,
        closedBy.isAcceptableOrUnknown(data['closed_by']!, _closedByMeta),
      );
    }
    if (data.containsKey('closed_by_name')) {
      context.handle(
        _closedByNameMeta,
        closedByName.isAcceptableOrUnknown(
          data['closed_by_name']!,
          _closedByNameMeta,
        ),
      );
    }
    if (data.containsKey('counted_cash')) {
      context.handle(
        _countedCashMeta,
        countedCash.isAcceptableOrUnknown(
          data['counted_cash']!,
          _countedCashMeta,
        ),
      );
    }
    if (data.containsKey('expected_cash')) {
      context.handle(
        _expectedCashMeta,
        expectedCash.isAcceptableOrUnknown(
          data['expected_cash']!,
          _expectedCashMeta,
        ),
      );
    }
    if (data.containsKey('close_note')) {
      context.handle(
        _closeNoteMeta,
        closeNote.isAcceptableOrUnknown(data['close_note']!, _closeNoteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      openedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opened_by'],
      )!,
      openedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opened_by_name'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
      openingCash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_cash'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      closedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closed_by'],
      ),
      closedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closed_by_name'],
      ),
      countedCash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counted_cash'],
      ),
      expectedCash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_cash'],
      ),
      closeNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}close_note'],
      ),
    );
  }

  @override
  $LocalShiftsTable createAlias(String alias) {
    return $LocalShiftsTable(attachedDatabase, alias);
  }
}

class ShiftRow extends DataClass implements Insertable<ShiftRow> {
  final String id;
  final String storeId;
  final String openedBy;
  final String openedByName;
  final DateTime openedAt;
  final int openingCash;

  /// `open` or `closed`.
  final String status;
  final DateTime? closedAt;
  final String? closedBy;
  final String? closedByName;
  final int? countedCash;

  /// What this terminal computed when closing (sent as client_expected_cash).
  final int? expectedCash;
  final String? closeNote;
  const ShiftRow({
    required this.id,
    required this.storeId,
    required this.openedBy,
    required this.openedByName,
    required this.openedAt,
    required this.openingCash,
    required this.status,
    this.closedAt,
    this.closedBy,
    this.closedByName,
    this.countedCash,
    this.expectedCash,
    this.closeNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['opened_by'] = Variable<String>(openedBy);
    map['opened_by_name'] = Variable<String>(openedByName);
    map['opened_at'] = Variable<DateTime>(openedAt);
    map['opening_cash'] = Variable<int>(openingCash);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    if (!nullToAbsent || closedBy != null) {
      map['closed_by'] = Variable<String>(closedBy);
    }
    if (!nullToAbsent || closedByName != null) {
      map['closed_by_name'] = Variable<String>(closedByName);
    }
    if (!nullToAbsent || countedCash != null) {
      map['counted_cash'] = Variable<int>(countedCash);
    }
    if (!nullToAbsent || expectedCash != null) {
      map['expected_cash'] = Variable<int>(expectedCash);
    }
    if (!nullToAbsent || closeNote != null) {
      map['close_note'] = Variable<String>(closeNote);
    }
    return map;
  }

  LocalShiftsCompanion toCompanion(bool nullToAbsent) {
    return LocalShiftsCompanion(
      id: Value(id),
      storeId: Value(storeId),
      openedBy: Value(openedBy),
      openedByName: Value(openedByName),
      openedAt: Value(openedAt),
      openingCash: Value(openingCash),
      status: Value(status),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      closedBy: closedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(closedBy),
      closedByName: closedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(closedByName),
      countedCash: countedCash == null && nullToAbsent
          ? const Value.absent()
          : Value(countedCash),
      expectedCash: expectedCash == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedCash),
      closeNote: closeNote == null && nullToAbsent
          ? const Value.absent()
          : Value(closeNote),
    );
  }

  factory ShiftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftRow(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      openedBy: serializer.fromJson<String>(json['openedBy']),
      openedByName: serializer.fromJson<String>(json['openedByName']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      openingCash: serializer.fromJson<int>(json['openingCash']),
      status: serializer.fromJson<String>(json['status']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      closedBy: serializer.fromJson<String?>(json['closedBy']),
      closedByName: serializer.fromJson<String?>(json['closedByName']),
      countedCash: serializer.fromJson<int?>(json['countedCash']),
      expectedCash: serializer.fromJson<int?>(json['expectedCash']),
      closeNote: serializer.fromJson<String?>(json['closeNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'openedBy': serializer.toJson<String>(openedBy),
      'openedByName': serializer.toJson<String>(openedByName),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'openingCash': serializer.toJson<int>(openingCash),
      'status': serializer.toJson<String>(status),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'closedBy': serializer.toJson<String?>(closedBy),
      'closedByName': serializer.toJson<String?>(closedByName),
      'countedCash': serializer.toJson<int?>(countedCash),
      'expectedCash': serializer.toJson<int?>(expectedCash),
      'closeNote': serializer.toJson<String?>(closeNote),
    };
  }

  ShiftRow copyWith({
    String? id,
    String? storeId,
    String? openedBy,
    String? openedByName,
    DateTime? openedAt,
    int? openingCash,
    String? status,
    Value<DateTime?> closedAt = const Value.absent(),
    Value<String?> closedBy = const Value.absent(),
    Value<String?> closedByName = const Value.absent(),
    Value<int?> countedCash = const Value.absent(),
    Value<int?> expectedCash = const Value.absent(),
    Value<String?> closeNote = const Value.absent(),
  }) => ShiftRow(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    openedBy: openedBy ?? this.openedBy,
    openedByName: openedByName ?? this.openedByName,
    openedAt: openedAt ?? this.openedAt,
    openingCash: openingCash ?? this.openingCash,
    status: status ?? this.status,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    closedBy: closedBy.present ? closedBy.value : this.closedBy,
    closedByName: closedByName.present ? closedByName.value : this.closedByName,
    countedCash: countedCash.present ? countedCash.value : this.countedCash,
    expectedCash: expectedCash.present ? expectedCash.value : this.expectedCash,
    closeNote: closeNote.present ? closeNote.value : this.closeNote,
  );
  ShiftRow copyWithCompanion(LocalShiftsCompanion data) {
    return ShiftRow(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      openedBy: data.openedBy.present ? data.openedBy.value : this.openedBy,
      openedByName: data.openedByName.present
          ? data.openedByName.value
          : this.openedByName,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      openingCash: data.openingCash.present
          ? data.openingCash.value
          : this.openingCash,
      status: data.status.present ? data.status.value : this.status,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      closedBy: data.closedBy.present ? data.closedBy.value : this.closedBy,
      closedByName: data.closedByName.present
          ? data.closedByName.value
          : this.closedByName,
      countedCash: data.countedCash.present
          ? data.countedCash.value
          : this.countedCash,
      expectedCash: data.expectedCash.present
          ? data.expectedCash.value
          : this.expectedCash,
      closeNote: data.closeNote.present ? data.closeNote.value : this.closeNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftRow(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('openedBy: $openedBy, ')
          ..write('openedByName: $openedByName, ')
          ..write('openedAt: $openedAt, ')
          ..write('openingCash: $openingCash, ')
          ..write('status: $status, ')
          ..write('closedAt: $closedAt, ')
          ..write('closedBy: $closedBy, ')
          ..write('closedByName: $closedByName, ')
          ..write('countedCash: $countedCash, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('closeNote: $closeNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    openedBy,
    openedByName,
    openedAt,
    openingCash,
    status,
    closedAt,
    closedBy,
    closedByName,
    countedCash,
    expectedCash,
    closeNote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftRow &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.openedBy == this.openedBy &&
          other.openedByName == this.openedByName &&
          other.openedAt == this.openedAt &&
          other.openingCash == this.openingCash &&
          other.status == this.status &&
          other.closedAt == this.closedAt &&
          other.closedBy == this.closedBy &&
          other.closedByName == this.closedByName &&
          other.countedCash == this.countedCash &&
          other.expectedCash == this.expectedCash &&
          other.closeNote == this.closeNote);
}

class LocalShiftsCompanion extends UpdateCompanion<ShiftRow> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> openedBy;
  final Value<String> openedByName;
  final Value<DateTime> openedAt;
  final Value<int> openingCash;
  final Value<String> status;
  final Value<DateTime?> closedAt;
  final Value<String?> closedBy;
  final Value<String?> closedByName;
  final Value<int?> countedCash;
  final Value<int?> expectedCash;
  final Value<String?> closeNote;
  final Value<int> rowid;
  const LocalShiftsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.openedBy = const Value.absent(),
    this.openedByName = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.openingCash = const Value.absent(),
    this.status = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.closedBy = const Value.absent(),
    this.closedByName = const Value.absent(),
    this.countedCash = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.closeNote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShiftsCompanion.insert({
    required String id,
    required String storeId,
    required String openedBy,
    required String openedByName,
    required DateTime openedAt,
    required int openingCash,
    required String status,
    this.closedAt = const Value.absent(),
    this.closedBy = const Value.absent(),
    this.closedByName = const Value.absent(),
    this.countedCash = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.closeNote = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       openedBy = Value(openedBy),
       openedByName = Value(openedByName),
       openedAt = Value(openedAt),
       openingCash = Value(openingCash),
       status = Value(status);
  static Insertable<ShiftRow> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? openedBy,
    Expression<String>? openedByName,
    Expression<DateTime>? openedAt,
    Expression<int>? openingCash,
    Expression<String>? status,
    Expression<DateTime>? closedAt,
    Expression<String>? closedBy,
    Expression<String>? closedByName,
    Expression<int>? countedCash,
    Expression<int>? expectedCash,
    Expression<String>? closeNote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (openedBy != null) 'opened_by': openedBy,
      if (openedByName != null) 'opened_by_name': openedByName,
      if (openedAt != null) 'opened_at': openedAt,
      if (openingCash != null) 'opening_cash': openingCash,
      if (status != null) 'status': status,
      if (closedAt != null) 'closed_at': closedAt,
      if (closedBy != null) 'closed_by': closedBy,
      if (closedByName != null) 'closed_by_name': closedByName,
      if (countedCash != null) 'counted_cash': countedCash,
      if (expectedCash != null) 'expected_cash': expectedCash,
      if (closeNote != null) 'close_note': closeNote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShiftsCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String>? openedBy,
    Value<String>? openedByName,
    Value<DateTime>? openedAt,
    Value<int>? openingCash,
    Value<String>? status,
    Value<DateTime?>? closedAt,
    Value<String?>? closedBy,
    Value<String?>? closedByName,
    Value<int?>? countedCash,
    Value<int?>? expectedCash,
    Value<String?>? closeNote,
    Value<int>? rowid,
  }) {
    return LocalShiftsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      openedBy: openedBy ?? this.openedBy,
      openedByName: openedByName ?? this.openedByName,
      openedAt: openedAt ?? this.openedAt,
      openingCash: openingCash ?? this.openingCash,
      status: status ?? this.status,
      closedAt: closedAt ?? this.closedAt,
      closedBy: closedBy ?? this.closedBy,
      closedByName: closedByName ?? this.closedByName,
      countedCash: countedCash ?? this.countedCash,
      expectedCash: expectedCash ?? this.expectedCash,
      closeNote: closeNote ?? this.closeNote,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (openedBy.present) {
      map['opened_by'] = Variable<String>(openedBy.value);
    }
    if (openedByName.present) {
      map['opened_by_name'] = Variable<String>(openedByName.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (openingCash.present) {
      map['opening_cash'] = Variable<int>(openingCash.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (closedBy.present) {
      map['closed_by'] = Variable<String>(closedBy.value);
    }
    if (closedByName.present) {
      map['closed_by_name'] = Variable<String>(closedByName.value);
    }
    if (countedCash.present) {
      map['counted_cash'] = Variable<int>(countedCash.value);
    }
    if (expectedCash.present) {
      map['expected_cash'] = Variable<int>(expectedCash.value);
    }
    if (closeNote.present) {
      map['close_note'] = Variable<String>(closeNote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShiftsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('openedBy: $openedBy, ')
          ..write('openedByName: $openedByName, ')
          ..write('openedAt: $openedAt, ')
          ..write('openingCash: $openingCash, ')
          ..write('status: $status, ')
          ..write('closedAt: $closedAt, ')
          ..write('closedBy: $closedBy, ')
          ..write('closedByName: $closedByName, ')
          ..write('countedCash: $countedCash, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('closeNote: $closeNote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalOrdersTable extends LocalOrders
    with TableInfo<$LocalOrdersTable, LocalOrderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderNumberMeta = const VerificationMeta(
    'orderNumber',
  );
  @override
  late final GeneratedColumn<String> orderNumber = GeneratedColumn<String>(
    'order_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cartJsonMeta = const VerificationMeta(
    'cartJson',
  );
  @override
  late final GeneratedColumn<String> cartJson = GeneratedColumn<String>(
    'cart_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grandTotalMeta = const VerificationMeta(
    'grandTotal',
  );
  @override
  late final GeneratedColumn<int> grandTotal = GeneratedColumn<int>(
    'grand_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashierNameMeta = const VerificationMeta(
    'cashierName',
  );
  @override
  late final GeneratedColumn<String> cashierName = GeneratedColumn<String>(
    'cashier_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _printedAtMeta = const VerificationMeta(
    'printedAt',
  );
  @override
  late final GeneratedColumn<DateTime> printedAt = GeneratedColumn<DateTime>(
    'printed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidedAtMeta = const VerificationMeta(
    'voidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> voidedAt = GeneratedColumn<DateTime>(
    'voided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidReasonMeta = const VerificationMeta(
    'voidReason',
  );
  @override
  late final GeneratedColumn<String> voidReason = GeneratedColumn<String>(
    'void_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidedByNameMeta = const VerificationMeta(
    'voidedByName',
  );
  @override
  late final GeneratedColumn<String> voidedByName = GeneratedColumn<String>(
    'voided_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidedShiftIdMeta = const VerificationMeta(
    'voidedShiftId',
  );
  @override
  late final GeneratedColumn<String> voidedShiftId = GeneratedColumn<String>(
    'voided_shift_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderNumber,
    status,
    version,
    cartJson,
    payloadJson,
    grandTotal,
    itemCount,
    customerName,
    cashierName,
    shiftId,
    createdAt,
    updatedAt,
    completedAt,
    printedAt,
    voidedAt,
    voidReason,
    voidedByName,
    voidedShiftId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOrderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_number')) {
      context.handle(
        _orderNumberMeta,
        orderNumber.isAcceptableOrUnknown(
          data['order_number']!,
          _orderNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderNumberMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('cart_json')) {
      context.handle(
        _cartJsonMeta,
        cartJson.isAcceptableOrUnknown(data['cart_json']!, _cartJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_cartJsonMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('grand_total')) {
      context.handle(
        _grandTotalMeta,
        grandTotal.isAcceptableOrUnknown(data['grand_total']!, _grandTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_grandTotalMeta);
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCountMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('cashier_name')) {
      context.handle(
        _cashierNameMeta,
        cashierName.isAcceptableOrUnknown(
          data['cashier_name']!,
          _cashierNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashierNameMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('printed_at')) {
      context.handle(
        _printedAtMeta,
        printedAt.isAcceptableOrUnknown(data['printed_at']!, _printedAtMeta),
      );
    }
    if (data.containsKey('voided_at')) {
      context.handle(
        _voidedAtMeta,
        voidedAt.isAcceptableOrUnknown(data['voided_at']!, _voidedAtMeta),
      );
    }
    if (data.containsKey('void_reason')) {
      context.handle(
        _voidReasonMeta,
        voidReason.isAcceptableOrUnknown(data['void_reason']!, _voidReasonMeta),
      );
    }
    if (data.containsKey('voided_by_name')) {
      context.handle(
        _voidedByNameMeta,
        voidedByName.isAcceptableOrUnknown(
          data['voided_by_name']!,
          _voidedByNameMeta,
        ),
      );
    }
    if (data.containsKey('voided_shift_id')) {
      context.handle(
        _voidedShiftIdMeta,
        voidedShiftId.isAcceptableOrUnknown(
          data['voided_shift_id']!,
          _voidedShiftIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalOrderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOrderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      orderNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_number'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      cartJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cart_json'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      grandTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grand_total'],
      )!,
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      cashierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_name'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      printedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}printed_at'],
      ),
      voidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}voided_at'],
      ),
      voidReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_reason'],
      ),
      voidedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voided_by_name'],
      ),
      voidedShiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voided_shift_id'],
      ),
    );
  }

  @override
  $LocalOrdersTable createAlias(String alias) {
    return $LocalOrdersTable(attachedDatabase, alias);
  }
}

class LocalOrderRow extends DataClass implements Insertable<LocalOrderRow> {
  final String id;
  final String orderNumber;

  /// `held`, `completed`, `cancelled` or `voided`.
  final String status;

  /// Version of the last snapshot queued for the server.
  final int version;

  /// The cart (to resume a held bill).
  final String cartJson;

  /// The last `order.upsert` payload (receipts are built from it).
  final String payloadJson;
  final int grandTotal;
  final int itemCount;
  final String? customerName;
  final String cashierName;
  final String? shiftId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? printedAt;
  final DateTime? voidedAt;
  final String? voidReason;
  final String? voidedByName;

  /// The shift whose drawer gave the money back.
  final String? voidedShiftId;
  const LocalOrderRow({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.version,
    required this.cartJson,
    required this.payloadJson,
    required this.grandTotal,
    required this.itemCount,
    this.customerName,
    required this.cashierName,
    this.shiftId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.printedAt,
    this.voidedAt,
    this.voidReason,
    this.voidedByName,
    this.voidedShiftId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_number'] = Variable<String>(orderNumber);
    map['status'] = Variable<String>(status);
    map['version'] = Variable<int>(version);
    map['cart_json'] = Variable<String>(cartJson);
    map['payload_json'] = Variable<String>(payloadJson);
    map['grand_total'] = Variable<int>(grandTotal);
    map['item_count'] = Variable<int>(itemCount);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    map['cashier_name'] = Variable<String>(cashierName);
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<String>(shiftId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || printedAt != null) {
      map['printed_at'] = Variable<DateTime>(printedAt);
    }
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<DateTime>(voidedAt);
    }
    if (!nullToAbsent || voidReason != null) {
      map['void_reason'] = Variable<String>(voidReason);
    }
    if (!nullToAbsent || voidedByName != null) {
      map['voided_by_name'] = Variable<String>(voidedByName);
    }
    if (!nullToAbsent || voidedShiftId != null) {
      map['voided_shift_id'] = Variable<String>(voidedShiftId);
    }
    return map;
  }

  LocalOrdersCompanion toCompanion(bool nullToAbsent) {
    return LocalOrdersCompanion(
      id: Value(id),
      orderNumber: Value(orderNumber),
      status: Value(status),
      version: Value(version),
      cartJson: Value(cartJson),
      payloadJson: Value(payloadJson),
      grandTotal: Value(grandTotal),
      itemCount: Value(itemCount),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      cashierName: Value(cashierName),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      printedAt: printedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(printedAt),
      voidedAt: voidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedAt),
      voidReason: voidReason == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReason),
      voidedByName: voidedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedByName),
      voidedShiftId: voidedShiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedShiftId),
    );
  }

  factory LocalOrderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOrderRow(
      id: serializer.fromJson<String>(json['id']),
      orderNumber: serializer.fromJson<String>(json['orderNumber']),
      status: serializer.fromJson<String>(json['status']),
      version: serializer.fromJson<int>(json['version']),
      cartJson: serializer.fromJson<String>(json['cartJson']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      grandTotal: serializer.fromJson<int>(json['grandTotal']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      cashierName: serializer.fromJson<String>(json['cashierName']),
      shiftId: serializer.fromJson<String?>(json['shiftId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      printedAt: serializer.fromJson<DateTime?>(json['printedAt']),
      voidedAt: serializer.fromJson<DateTime?>(json['voidedAt']),
      voidReason: serializer.fromJson<String?>(json['voidReason']),
      voidedByName: serializer.fromJson<String?>(json['voidedByName']),
      voidedShiftId: serializer.fromJson<String?>(json['voidedShiftId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderNumber': serializer.toJson<String>(orderNumber),
      'status': serializer.toJson<String>(status),
      'version': serializer.toJson<int>(version),
      'cartJson': serializer.toJson<String>(cartJson),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'grandTotal': serializer.toJson<int>(grandTotal),
      'itemCount': serializer.toJson<int>(itemCount),
      'customerName': serializer.toJson<String?>(customerName),
      'cashierName': serializer.toJson<String>(cashierName),
      'shiftId': serializer.toJson<String?>(shiftId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'printedAt': serializer.toJson<DateTime?>(printedAt),
      'voidedAt': serializer.toJson<DateTime?>(voidedAt),
      'voidReason': serializer.toJson<String?>(voidReason),
      'voidedByName': serializer.toJson<String?>(voidedByName),
      'voidedShiftId': serializer.toJson<String?>(voidedShiftId),
    };
  }

  LocalOrderRow copyWith({
    String? id,
    String? orderNumber,
    String? status,
    int? version,
    String? cartJson,
    String? payloadJson,
    int? grandTotal,
    int? itemCount,
    Value<String?> customerName = const Value.absent(),
    String? cashierName,
    Value<String?> shiftId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> printedAt = const Value.absent(),
    Value<DateTime?> voidedAt = const Value.absent(),
    Value<String?> voidReason = const Value.absent(),
    Value<String?> voidedByName = const Value.absent(),
    Value<String?> voidedShiftId = const Value.absent(),
  }) => LocalOrderRow(
    id: id ?? this.id,
    orderNumber: orderNumber ?? this.orderNumber,
    status: status ?? this.status,
    version: version ?? this.version,
    cartJson: cartJson ?? this.cartJson,
    payloadJson: payloadJson ?? this.payloadJson,
    grandTotal: grandTotal ?? this.grandTotal,
    itemCount: itemCount ?? this.itemCount,
    customerName: customerName.present ? customerName.value : this.customerName,
    cashierName: cashierName ?? this.cashierName,
    shiftId: shiftId.present ? shiftId.value : this.shiftId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    printedAt: printedAt.present ? printedAt.value : this.printedAt,
    voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
    voidReason: voidReason.present ? voidReason.value : this.voidReason,
    voidedByName: voidedByName.present ? voidedByName.value : this.voidedByName,
    voidedShiftId: voidedShiftId.present
        ? voidedShiftId.value
        : this.voidedShiftId,
  );
  LocalOrderRow copyWithCompanion(LocalOrdersCompanion data) {
    return LocalOrderRow(
      id: data.id.present ? data.id.value : this.id,
      orderNumber: data.orderNumber.present
          ? data.orderNumber.value
          : this.orderNumber,
      status: data.status.present ? data.status.value : this.status,
      version: data.version.present ? data.version.value : this.version,
      cartJson: data.cartJson.present ? data.cartJson.value : this.cartJson,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      grandTotal: data.grandTotal.present
          ? data.grandTotal.value
          : this.grandTotal,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      cashierName: data.cashierName.present
          ? data.cashierName.value
          : this.cashierName,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      printedAt: data.printedAt.present ? data.printedAt.value : this.printedAt,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
      voidReason: data.voidReason.present
          ? data.voidReason.value
          : this.voidReason,
      voidedByName: data.voidedByName.present
          ? data.voidedByName.value
          : this.voidedByName,
      voidedShiftId: data.voidedShiftId.present
          ? data.voidedShiftId.value
          : this.voidedShiftId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrderRow(')
          ..write('id: $id, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('status: $status, ')
          ..write('version: $version, ')
          ..write('cartJson: $cartJson, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('itemCount: $itemCount, ')
          ..write('customerName: $customerName, ')
          ..write('cashierName: $cashierName, ')
          ..write('shiftId: $shiftId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('printedAt: $printedAt, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidedByName: $voidedByName, ')
          ..write('voidedShiftId: $voidedShiftId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderNumber,
    status,
    version,
    cartJson,
    payloadJson,
    grandTotal,
    itemCount,
    customerName,
    cashierName,
    shiftId,
    createdAt,
    updatedAt,
    completedAt,
    printedAt,
    voidedAt,
    voidReason,
    voidedByName,
    voidedShiftId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOrderRow &&
          other.id == this.id &&
          other.orderNumber == this.orderNumber &&
          other.status == this.status &&
          other.version == this.version &&
          other.cartJson == this.cartJson &&
          other.payloadJson == this.payloadJson &&
          other.grandTotal == this.grandTotal &&
          other.itemCount == this.itemCount &&
          other.customerName == this.customerName &&
          other.cashierName == this.cashierName &&
          other.shiftId == this.shiftId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt &&
          other.printedAt == this.printedAt &&
          other.voidedAt == this.voidedAt &&
          other.voidReason == this.voidReason &&
          other.voidedByName == this.voidedByName &&
          other.voidedShiftId == this.voidedShiftId);
}

class LocalOrdersCompanion extends UpdateCompanion<LocalOrderRow> {
  final Value<String> id;
  final Value<String> orderNumber;
  final Value<String> status;
  final Value<int> version;
  final Value<String> cartJson;
  final Value<String> payloadJson;
  final Value<int> grandTotal;
  final Value<int> itemCount;
  final Value<String?> customerName;
  final Value<String> cashierName;
  final Value<String?> shiftId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> printedAt;
  final Value<DateTime?> voidedAt;
  final Value<String?> voidReason;
  final Value<String?> voidedByName;
  final Value<String?> voidedShiftId;
  final Value<int> rowid;
  const LocalOrdersCompanion({
    this.id = const Value.absent(),
    this.orderNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.version = const Value.absent(),
    this.cartJson = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.customerName = const Value.absent(),
    this.cashierName = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.printedAt = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidedByName = const Value.absent(),
    this.voidedShiftId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOrdersCompanion.insert({
    required String id,
    required String orderNumber,
    required String status,
    required int version,
    required String cartJson,
    required String payloadJson,
    required int grandTotal,
    required int itemCount,
    this.customerName = const Value.absent(),
    required String cashierName,
    this.shiftId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.completedAt = const Value.absent(),
    this.printedAt = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidedByName = const Value.absent(),
    this.voidedShiftId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderNumber = Value(orderNumber),
       status = Value(status),
       version = Value(version),
       cartJson = Value(cartJson),
       payloadJson = Value(payloadJson),
       grandTotal = Value(grandTotal),
       itemCount = Value(itemCount),
       cashierName = Value(cashierName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalOrderRow> custom({
    Expression<String>? id,
    Expression<String>? orderNumber,
    Expression<String>? status,
    Expression<int>? version,
    Expression<String>? cartJson,
    Expression<String>? payloadJson,
    Expression<int>? grandTotal,
    Expression<int>? itemCount,
    Expression<String>? customerName,
    Expression<String>? cashierName,
    Expression<String>? shiftId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? printedAt,
    Expression<DateTime>? voidedAt,
    Expression<String>? voidReason,
    Expression<String>? voidedByName,
    Expression<String>? voidedShiftId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderNumber != null) 'order_number': orderNumber,
      if (status != null) 'status': status,
      if (version != null) 'version': version,
      if (cartJson != null) 'cart_json': cartJson,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (grandTotal != null) 'grand_total': grandTotal,
      if (itemCount != null) 'item_count': itemCount,
      if (customerName != null) 'customer_name': customerName,
      if (cashierName != null) 'cashier_name': cashierName,
      if (shiftId != null) 'shift_id': shiftId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (printedAt != null) 'printed_at': printedAt,
      if (voidedAt != null) 'voided_at': voidedAt,
      if (voidReason != null) 'void_reason': voidReason,
      if (voidedByName != null) 'voided_by_name': voidedByName,
      if (voidedShiftId != null) 'voided_shift_id': voidedShiftId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? orderNumber,
    Value<String>? status,
    Value<int>? version,
    Value<String>? cartJson,
    Value<String>? payloadJson,
    Value<int>? grandTotal,
    Value<int>? itemCount,
    Value<String?>? customerName,
    Value<String>? cashierName,
    Value<String?>? shiftId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? printedAt,
    Value<DateTime?>? voidedAt,
    Value<String?>? voidReason,
    Value<String?>? voidedByName,
    Value<String?>? voidedShiftId,
    Value<int>? rowid,
  }) {
    return LocalOrdersCompanion(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      version: version ?? this.version,
      cartJson: cartJson ?? this.cartJson,
      payloadJson: payloadJson ?? this.payloadJson,
      grandTotal: grandTotal ?? this.grandTotal,
      itemCount: itemCount ?? this.itemCount,
      customerName: customerName ?? this.customerName,
      cashierName: cashierName ?? this.cashierName,
      shiftId: shiftId ?? this.shiftId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      printedAt: printedAt ?? this.printedAt,
      voidedAt: voidedAt ?? this.voidedAt,
      voidReason: voidReason ?? this.voidReason,
      voidedByName: voidedByName ?? this.voidedByName,
      voidedShiftId: voidedShiftId ?? this.voidedShiftId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderNumber.present) {
      map['order_number'] = Variable<String>(orderNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (cartJson.present) {
      map['cart_json'] = Variable<String>(cartJson.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (grandTotal.present) {
      map['grand_total'] = Variable<int>(grandTotal.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (cashierName.present) {
      map['cashier_name'] = Variable<String>(cashierName.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (printedAt.present) {
      map['printed_at'] = Variable<DateTime>(printedAt.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<DateTime>(voidedAt.value);
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    if (voidedByName.present) {
      map['voided_by_name'] = Variable<String>(voidedByName.value);
    }
    if (voidedShiftId.present) {
      map['voided_shift_id'] = Variable<String>(voidedShiftId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrdersCompanion(')
          ..write('id: $id, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('status: $status, ')
          ..write('version: $version, ')
          ..write('cartJson: $cartJson, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('itemCount: $itemCount, ')
          ..write('customerName: $customerName, ')
          ..write('cashierName: $cashierName, ')
          ..write('shiftId: $shiftId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('printedAt: $printedAt, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidedByName: $voidedByName, ')
          ..write('voidedShiftId: $voidedShiftId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCountersTable extends LocalCounters
    with TableInfo<$LocalCountersTable, CounterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_counters';
  @override
  VerificationContext validateIntegrity(
    Insertable<CounterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  CounterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CounterRow(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalCountersTable createAlias(String alias) {
    return $LocalCountersTable(attachedDatabase, alias);
  }
}

class CounterRow extends DataClass implements Insertable<CounterRow> {
  final String name;
  final int value;
  const CounterRow({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<int>(value);
    return map;
  }

  LocalCountersCompanion toCompanion(bool nullToAbsent) {
    return LocalCountersCompanion(name: Value(name), value: Value(value));
  }

  factory CounterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CounterRow(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<int>(value),
    };
  }

  CounterRow copyWith({String? name, int? value}) =>
      CounterRow(name: name ?? this.name, value: value ?? this.value);
  CounterRow copyWithCompanion(LocalCountersCompanion data) {
    return CounterRow(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CounterRow(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CounterRow &&
          other.name == this.name &&
          other.value == this.value);
}

class LocalCountersCompanion extends UpdateCompanion<CounterRow> {
  final Value<String> name;
  final Value<int> value;
  final Value<int> rowid;
  const LocalCountersCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCountersCompanion.insert({
    required String name,
    required int value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<CounterRow> custom({
    Expression<String>? name,
    Expression<int>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCountersCompanion copyWith({
    Value<String>? name,
    Value<int>? value,
    Value<int>? rowid,
  }) {
    return LocalCountersCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCountersCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCashMovementsTable extends LocalCashMovements
    with TableInfo<$LocalCashMovementsTable, CashMovementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCashMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movementTypeMeta = const VerificationMeta(
    'movementType',
  );
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
    'movement_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _employeeNameMeta = const VerificationMeta(
    'employeeName',
  );
  @override
  late final GeneratedColumn<String> employeeName = GeneratedColumn<String>(
    'employee_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shiftId,
    movementType,
    amount,
    reason,
    employeeName,
    occurredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_cash_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashMovementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('movement_type')) {
      context.handle(
        _movementTypeMeta,
        movementType.isAcceptableOrUnknown(
          data['movement_type']!,
          _movementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('employee_name')) {
      context.handle(
        _employeeNameMeta,
        employeeName.isAcceptableOrUnknown(
          data['employee_name']!,
          _employeeNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_employeeNameMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashMovementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashMovementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      movementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      employeeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_name'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
    );
  }

  @override
  $LocalCashMovementsTable createAlias(String alias) {
    return $LocalCashMovementsTable(attachedDatabase, alias);
  }
}

class CashMovementRow extends DataClass implements Insertable<CashMovementRow> {
  final String id;
  final String shiftId;

  /// `in` or `out`.
  final String movementType;
  final int amount;
  final String reason;
  final String employeeName;
  final DateTime occurredAt;
  const CashMovementRow({
    required this.id,
    required this.shiftId,
    required this.movementType,
    required this.amount,
    required this.reason,
    required this.employeeName,
    required this.occurredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shift_id'] = Variable<String>(shiftId);
    map['movement_type'] = Variable<String>(movementType);
    map['amount'] = Variable<int>(amount);
    map['reason'] = Variable<String>(reason);
    map['employee_name'] = Variable<String>(employeeName);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    return map;
  }

  LocalCashMovementsCompanion toCompanion(bool nullToAbsent) {
    return LocalCashMovementsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      movementType: Value(movementType),
      amount: Value(amount),
      reason: Value(reason),
      employeeName: Value(employeeName),
      occurredAt: Value(occurredAt),
    );
  }

  factory CashMovementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashMovementRow(
      id: serializer.fromJson<String>(json['id']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      movementType: serializer.fromJson<String>(json['movementType']),
      amount: serializer.fromJson<int>(json['amount']),
      reason: serializer.fromJson<String>(json['reason']),
      employeeName: serializer.fromJson<String>(json['employeeName']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shiftId': serializer.toJson<String>(shiftId),
      'movementType': serializer.toJson<String>(movementType),
      'amount': serializer.toJson<int>(amount),
      'reason': serializer.toJson<String>(reason),
      'employeeName': serializer.toJson<String>(employeeName),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
    };
  }

  CashMovementRow copyWith({
    String? id,
    String? shiftId,
    String? movementType,
    int? amount,
    String? reason,
    String? employeeName,
    DateTime? occurredAt,
  }) => CashMovementRow(
    id: id ?? this.id,
    shiftId: shiftId ?? this.shiftId,
    movementType: movementType ?? this.movementType,
    amount: amount ?? this.amount,
    reason: reason ?? this.reason,
    employeeName: employeeName ?? this.employeeName,
    occurredAt: occurredAt ?? this.occurredAt,
  );
  CashMovementRow copyWithCompanion(LocalCashMovementsCompanion data) {
    return CashMovementRow(
      id: data.id.present ? data.id.value : this.id,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      amount: data.amount.present ? data.amount.value : this.amount,
      reason: data.reason.present ? data.reason.value : this.reason,
      employeeName: data.employeeName.present
          ? data.employeeName.value
          : this.employeeName,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashMovementRow(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('movementType: $movementType, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('employeeName: $employeeName, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shiftId,
    movementType,
    amount,
    reason,
    employeeName,
    occurredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashMovementRow &&
          other.id == this.id &&
          other.shiftId == this.shiftId &&
          other.movementType == this.movementType &&
          other.amount == this.amount &&
          other.reason == this.reason &&
          other.employeeName == this.employeeName &&
          other.occurredAt == this.occurredAt);
}

class LocalCashMovementsCompanion extends UpdateCompanion<CashMovementRow> {
  final Value<String> id;
  final Value<String> shiftId;
  final Value<String> movementType;
  final Value<int> amount;
  final Value<String> reason;
  final Value<String> employeeName;
  final Value<DateTime> occurredAt;
  final Value<int> rowid;
  const LocalCashMovementsCompanion({
    this.id = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.movementType = const Value.absent(),
    this.amount = const Value.absent(),
    this.reason = const Value.absent(),
    this.employeeName = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCashMovementsCompanion.insert({
    required String id,
    required String shiftId,
    required String movementType,
    required int amount,
    required String reason,
    required String employeeName,
    required DateTime occurredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shiftId = Value(shiftId),
       movementType = Value(movementType),
       amount = Value(amount),
       reason = Value(reason),
       employeeName = Value(employeeName),
       occurredAt = Value(occurredAt);
  static Insertable<CashMovementRow> custom({
    Expression<String>? id,
    Expression<String>? shiftId,
    Expression<String>? movementType,
    Expression<int>? amount,
    Expression<String>? reason,
    Expression<String>? employeeName,
    Expression<DateTime>? occurredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shiftId != null) 'shift_id': shiftId,
      if (movementType != null) 'movement_type': movementType,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
      if (employeeName != null) 'employee_name': employeeName,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCashMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? shiftId,
    Value<String>? movementType,
    Value<int>? amount,
    Value<String>? reason,
    Value<String>? employeeName,
    Value<DateTime>? occurredAt,
    Value<int>? rowid,
  }) {
    return LocalCashMovementsCompanion(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      movementType: movementType ?? this.movementType,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      employeeName: employeeName ?? this.employeeName,
      occurredAt: occurredAt ?? this.occurredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (employeeName.present) {
      map['employee_name'] = Variable<String>(employeeName.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCashMovementsCompanion(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('movementType: $movementType, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('employeeName: $employeeName, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalRefundsTable extends LocalRefunds
    with TableInfo<$LocalRefundsTable, RefundRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRefundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refundNumberMeta = const VerificationMeta(
    'refundNumber',
  );
  @override
  late final GeneratedColumn<String> refundNumber = GeneratedColumn<String>(
    'refund_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodTypeMeta = const VerificationMeta(
    'methodType',
  );
  @override
  late final GeneratedColumn<String> methodType = GeneratedColumn<String>(
    'method_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restockMeta = const VerificationMeta(
    'restock',
  );
  @override
  late final GeneratedColumn<bool> restock = GeneratedColumn<bool>(
    'restock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("restock" IN (0, 1))',
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
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employeeNameMeta = const VerificationMeta(
    'employeeName',
  );
  @override
  late final GeneratedColumn<String> employeeName = GeneratedColumn<String>(
    'employee_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _approvedByNameMeta = const VerificationMeta(
    'approvedByName',
  );
  @override
  late final GeneratedColumn<String> approvedByName = GeneratedColumn<String>(
    'approved_by_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refundedAtMeta = const VerificationMeta(
    'refundedAt',
  );
  @override
  late final GeneratedColumn<DateTime> refundedAt = GeneratedColumn<DateTime>(
    'refunded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    shiftId,
    refundNumber,
    amount,
    methodType,
    restock,
    reason,
    itemsJson,
    employeeName,
    approvedByName,
    refundedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_refunds';
  @override
  VerificationContext validateIntegrity(
    Insertable<RefundRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    }
    if (data.containsKey('refund_number')) {
      context.handle(
        _refundNumberMeta,
        refundNumber.isAcceptableOrUnknown(
          data['refund_number']!,
          _refundNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refundNumberMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('method_type')) {
      context.handle(
        _methodTypeMeta,
        methodType.isAcceptableOrUnknown(data['method_type']!, _methodTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_methodTypeMeta);
    }
    if (data.containsKey('restock')) {
      context.handle(
        _restockMeta,
        restock.isAcceptableOrUnknown(data['restock']!, _restockMeta),
      );
    } else if (isInserting) {
      context.missing(_restockMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_itemsJsonMeta);
    }
    if (data.containsKey('employee_name')) {
      context.handle(
        _employeeNameMeta,
        employeeName.isAcceptableOrUnknown(
          data['employee_name']!,
          _employeeNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_employeeNameMeta);
    }
    if (data.containsKey('approved_by_name')) {
      context.handle(
        _approvedByNameMeta,
        approvedByName.isAcceptableOrUnknown(
          data['approved_by_name']!,
          _approvedByNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_approvedByNameMeta);
    }
    if (data.containsKey('refunded_at')) {
      context.handle(
        _refundedAtMeta,
        refundedAt.isAcceptableOrUnknown(data['refunded_at']!, _refundedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_refundedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RefundRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RefundRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      ),
      refundNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refund_number'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      methodType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method_type'],
      )!,
      restock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}restock'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      employeeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_name'],
      )!,
      approvedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by_name'],
      )!,
      refundedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}refunded_at'],
      )!,
    );
  }

  @override
  $LocalRefundsTable createAlias(String alias) {
    return $LocalRefundsTable(attachedDatabase, alias);
  }
}

class RefundRow extends DataClass implements Insertable<RefundRow> {
  final String id;
  final String orderId;

  /// The open shift when refunding (required for cash).
  final String? shiftId;
  final String refundNumber;
  final int amount;

  /// `cash`, `qris`, `card`, `transfer` or `ewallet`.
  final String methodType;
  final bool restock;
  final String reason;

  /// The refund items as sent: `[{id, order_item_id, quantity, amount}]`.
  final String itemsJson;
  final String employeeName;
  final String approvedByName;
  final DateTime refundedAt;
  const RefundRow({
    required this.id,
    required this.orderId,
    this.shiftId,
    required this.refundNumber,
    required this.amount,
    required this.methodType,
    required this.restock,
    required this.reason,
    required this.itemsJson,
    required this.employeeName,
    required this.approvedByName,
    required this.refundedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<String>(shiftId);
    }
    map['refund_number'] = Variable<String>(refundNumber);
    map['amount'] = Variable<int>(amount);
    map['method_type'] = Variable<String>(methodType);
    map['restock'] = Variable<bool>(restock);
    map['reason'] = Variable<String>(reason);
    map['items_json'] = Variable<String>(itemsJson);
    map['employee_name'] = Variable<String>(employeeName);
    map['approved_by_name'] = Variable<String>(approvedByName);
    map['refunded_at'] = Variable<DateTime>(refundedAt);
    return map;
  }

  LocalRefundsCompanion toCompanion(bool nullToAbsent) {
    return LocalRefundsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      refundNumber: Value(refundNumber),
      amount: Value(amount),
      methodType: Value(methodType),
      restock: Value(restock),
      reason: Value(reason),
      itemsJson: Value(itemsJson),
      employeeName: Value(employeeName),
      approvedByName: Value(approvedByName),
      refundedAt: Value(refundedAt),
    );
  }

  factory RefundRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RefundRow(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      shiftId: serializer.fromJson<String?>(json['shiftId']),
      refundNumber: serializer.fromJson<String>(json['refundNumber']),
      amount: serializer.fromJson<int>(json['amount']),
      methodType: serializer.fromJson<String>(json['methodType']),
      restock: serializer.fromJson<bool>(json['restock']),
      reason: serializer.fromJson<String>(json['reason']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      employeeName: serializer.fromJson<String>(json['employeeName']),
      approvedByName: serializer.fromJson<String>(json['approvedByName']),
      refundedAt: serializer.fromJson<DateTime>(json['refundedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'shiftId': serializer.toJson<String?>(shiftId),
      'refundNumber': serializer.toJson<String>(refundNumber),
      'amount': serializer.toJson<int>(amount),
      'methodType': serializer.toJson<String>(methodType),
      'restock': serializer.toJson<bool>(restock),
      'reason': serializer.toJson<String>(reason),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'employeeName': serializer.toJson<String>(employeeName),
      'approvedByName': serializer.toJson<String>(approvedByName),
      'refundedAt': serializer.toJson<DateTime>(refundedAt),
    };
  }

  RefundRow copyWith({
    String? id,
    String? orderId,
    Value<String?> shiftId = const Value.absent(),
    String? refundNumber,
    int? amount,
    String? methodType,
    bool? restock,
    String? reason,
    String? itemsJson,
    String? employeeName,
    String? approvedByName,
    DateTime? refundedAt,
  }) => RefundRow(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    shiftId: shiftId.present ? shiftId.value : this.shiftId,
    refundNumber: refundNumber ?? this.refundNumber,
    amount: amount ?? this.amount,
    methodType: methodType ?? this.methodType,
    restock: restock ?? this.restock,
    reason: reason ?? this.reason,
    itemsJson: itemsJson ?? this.itemsJson,
    employeeName: employeeName ?? this.employeeName,
    approvedByName: approvedByName ?? this.approvedByName,
    refundedAt: refundedAt ?? this.refundedAt,
  );
  RefundRow copyWithCompanion(LocalRefundsCompanion data) {
    return RefundRow(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      refundNumber: data.refundNumber.present
          ? data.refundNumber.value
          : this.refundNumber,
      amount: data.amount.present ? data.amount.value : this.amount,
      methodType: data.methodType.present
          ? data.methodType.value
          : this.methodType,
      restock: data.restock.present ? data.restock.value : this.restock,
      reason: data.reason.present ? data.reason.value : this.reason,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      employeeName: data.employeeName.present
          ? data.employeeName.value
          : this.employeeName,
      approvedByName: data.approvedByName.present
          ? data.approvedByName.value
          : this.approvedByName,
      refundedAt: data.refundedAt.present
          ? data.refundedAt.value
          : this.refundedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RefundRow(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('shiftId: $shiftId, ')
          ..write('refundNumber: $refundNumber, ')
          ..write('amount: $amount, ')
          ..write('methodType: $methodType, ')
          ..write('restock: $restock, ')
          ..write('reason: $reason, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('employeeName: $employeeName, ')
          ..write('approvedByName: $approvedByName, ')
          ..write('refundedAt: $refundedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderId,
    shiftId,
    refundNumber,
    amount,
    methodType,
    restock,
    reason,
    itemsJson,
    employeeName,
    approvedByName,
    refundedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RefundRow &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.shiftId == this.shiftId &&
          other.refundNumber == this.refundNumber &&
          other.amount == this.amount &&
          other.methodType == this.methodType &&
          other.restock == this.restock &&
          other.reason == this.reason &&
          other.itemsJson == this.itemsJson &&
          other.employeeName == this.employeeName &&
          other.approvedByName == this.approvedByName &&
          other.refundedAt == this.refundedAt);
}

class LocalRefundsCompanion extends UpdateCompanion<RefundRow> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String?> shiftId;
  final Value<String> refundNumber;
  final Value<int> amount;
  final Value<String> methodType;
  final Value<bool> restock;
  final Value<String> reason;
  final Value<String> itemsJson;
  final Value<String> employeeName;
  final Value<String> approvedByName;
  final Value<DateTime> refundedAt;
  final Value<int> rowid;
  const LocalRefundsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.refundNumber = const Value.absent(),
    this.amount = const Value.absent(),
    this.methodType = const Value.absent(),
    this.restock = const Value.absent(),
    this.reason = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.employeeName = const Value.absent(),
    this.approvedByName = const Value.absent(),
    this.refundedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRefundsCompanion.insert({
    required String id,
    required String orderId,
    this.shiftId = const Value.absent(),
    required String refundNumber,
    required int amount,
    required String methodType,
    required bool restock,
    required String reason,
    required String itemsJson,
    required String employeeName,
    required String approvedByName,
    required DateTime refundedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderId = Value(orderId),
       refundNumber = Value(refundNumber),
       amount = Value(amount),
       methodType = Value(methodType),
       restock = Value(restock),
       reason = Value(reason),
       itemsJson = Value(itemsJson),
       employeeName = Value(employeeName),
       approvedByName = Value(approvedByName),
       refundedAt = Value(refundedAt);
  static Insertable<RefundRow> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? shiftId,
    Expression<String>? refundNumber,
    Expression<int>? amount,
    Expression<String>? methodType,
    Expression<bool>? restock,
    Expression<String>? reason,
    Expression<String>? itemsJson,
    Expression<String>? employeeName,
    Expression<String>? approvedByName,
    Expression<DateTime>? refundedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (shiftId != null) 'shift_id': shiftId,
      if (refundNumber != null) 'refund_number': refundNumber,
      if (amount != null) 'amount': amount,
      if (methodType != null) 'method_type': methodType,
      if (restock != null) 'restock': restock,
      if (reason != null) 'reason': reason,
      if (itemsJson != null) 'items_json': itemsJson,
      if (employeeName != null) 'employee_name': employeeName,
      if (approvedByName != null) 'approved_by_name': approvedByName,
      if (refundedAt != null) 'refunded_at': refundedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRefundsCompanion copyWith({
    Value<String>? id,
    Value<String>? orderId,
    Value<String?>? shiftId,
    Value<String>? refundNumber,
    Value<int>? amount,
    Value<String>? methodType,
    Value<bool>? restock,
    Value<String>? reason,
    Value<String>? itemsJson,
    Value<String>? employeeName,
    Value<String>? approvedByName,
    Value<DateTime>? refundedAt,
    Value<int>? rowid,
  }) {
    return LocalRefundsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      shiftId: shiftId ?? this.shiftId,
      refundNumber: refundNumber ?? this.refundNumber,
      amount: amount ?? this.amount,
      methodType: methodType ?? this.methodType,
      restock: restock ?? this.restock,
      reason: reason ?? this.reason,
      itemsJson: itemsJson ?? this.itemsJson,
      employeeName: employeeName ?? this.employeeName,
      approvedByName: approvedByName ?? this.approvedByName,
      refundedAt: refundedAt ?? this.refundedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (refundNumber.present) {
      map['refund_number'] = Variable<String>(refundNumber.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (methodType.present) {
      map['method_type'] = Variable<String>(methodType.value);
    }
    if (restock.present) {
      map['restock'] = Variable<bool>(restock.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (employeeName.present) {
      map['employee_name'] = Variable<String>(employeeName.value);
    }
    if (approvedByName.present) {
      map['approved_by_name'] = Variable<String>(approvedByName.value);
    }
    if (refundedAt.present) {
      map['refunded_at'] = Variable<DateTime>(refundedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalRefundsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('shiftId: $shiftId, ')
          ..write('refundNumber: $refundNumber, ')
          ..write('amount: $amount, ')
          ..write('methodType: $methodType, ')
          ..write('restock: $restock, ')
          ..write('reason: $reason, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('employeeName: $employeeName, ')
          ..write('approvedByName: $approvedByName, ')
          ..write('refundedAt: $refundedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPrintersTable extends LocalPrinters
    with TableInfo<$LocalPrintersTable, PrinterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPrintersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _connectionMeta = const VerificationMeta(
    'connection',
  );
  @override
  late final GeneratedColumn<String> connection = GeneratedColumn<String>(
    'connection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paperMmMeta = const VerificationMeta(
    'paperMm',
  );
  @override
  late final GeneratedColumn<int> paperMm = GeneratedColumn<int>(
    'paper_mm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opensCashDrawerMeta = const VerificationMeta(
    'opensCashDrawer',
  );
  @override
  late final GeneratedColumn<bool> opensCashDrawer = GeneratedColumn<bool>(
    'opens_cash_drawer',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("opens_cash_drawer" IN (0, 1))',
    ),
  );
  static const VerificationMeta _autoPrintMeta = const VerificationMeta(
    'autoPrint',
  );
  @override
  late final GeneratedColumn<bool> autoPrint = GeneratedColumn<bool>(
    'auto_print',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_print" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    connection,
    address,
    paperMm,
    opensCashDrawer,
    autoPrint,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_printers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrinterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('connection')) {
      context.handle(
        _connectionMeta,
        connection.isAcceptableOrUnknown(data['connection']!, _connectionMeta),
      );
    } else if (isInserting) {
      context.missing(_connectionMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('paper_mm')) {
      context.handle(
        _paperMmMeta,
        paperMm.isAcceptableOrUnknown(data['paper_mm']!, _paperMmMeta),
      );
    } else if (isInserting) {
      context.missing(_paperMmMeta);
    }
    if (data.containsKey('opens_cash_drawer')) {
      context.handle(
        _opensCashDrawerMeta,
        opensCashDrawer.isAcceptableOrUnknown(
          data['opens_cash_drawer']!,
          _opensCashDrawerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_opensCashDrawerMeta);
    }
    if (data.containsKey('auto_print')) {
      context.handle(
        _autoPrintMeta,
        autoPrint.isAcceptableOrUnknown(data['auto_print']!, _autoPrintMeta),
      );
    } else if (isInserting) {
      context.missing(_autoPrintMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrinterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrinterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      connection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      paperMm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paper_mm'],
      )!,
      opensCashDrawer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}opens_cash_drawer'],
      )!,
      autoPrint: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_print'],
      )!,
    );
  }

  @override
  $LocalPrintersTable createAlias(String alias) {
    return $LocalPrintersTable(attachedDatabase, alias);
  }
}

class PrinterRow extends DataClass implements Insertable<PrinterRow> {
  final String id;
  final String name;

  /// `bluetooth`, `ble`, `usb` or `network` (as in public.printers).
  final String connection;

  /// MAC or BLE id, USB id or Windows printer name, or host:port.
  final String address;
  final int paperMm;
  final bool opensCashDrawer;

  /// Print every finished sale without asking.
  final bool autoPrint;
  const PrinterRow({
    required this.id,
    required this.name,
    required this.connection,
    required this.address,
    required this.paperMm,
    required this.opensCashDrawer,
    required this.autoPrint,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['connection'] = Variable<String>(connection);
    map['address'] = Variable<String>(address);
    map['paper_mm'] = Variable<int>(paperMm);
    map['opens_cash_drawer'] = Variable<bool>(opensCashDrawer);
    map['auto_print'] = Variable<bool>(autoPrint);
    return map;
  }

  LocalPrintersCompanion toCompanion(bool nullToAbsent) {
    return LocalPrintersCompanion(
      id: Value(id),
      name: Value(name),
      connection: Value(connection),
      address: Value(address),
      paperMm: Value(paperMm),
      opensCashDrawer: Value(opensCashDrawer),
      autoPrint: Value(autoPrint),
    );
  }

  factory PrinterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrinterRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      connection: serializer.fromJson<String>(json['connection']),
      address: serializer.fromJson<String>(json['address']),
      paperMm: serializer.fromJson<int>(json['paperMm']),
      opensCashDrawer: serializer.fromJson<bool>(json['opensCashDrawer']),
      autoPrint: serializer.fromJson<bool>(json['autoPrint']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'connection': serializer.toJson<String>(connection),
      'address': serializer.toJson<String>(address),
      'paperMm': serializer.toJson<int>(paperMm),
      'opensCashDrawer': serializer.toJson<bool>(opensCashDrawer),
      'autoPrint': serializer.toJson<bool>(autoPrint),
    };
  }

  PrinterRow copyWith({
    String? id,
    String? name,
    String? connection,
    String? address,
    int? paperMm,
    bool? opensCashDrawer,
    bool? autoPrint,
  }) => PrinterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    connection: connection ?? this.connection,
    address: address ?? this.address,
    paperMm: paperMm ?? this.paperMm,
    opensCashDrawer: opensCashDrawer ?? this.opensCashDrawer,
    autoPrint: autoPrint ?? this.autoPrint,
  );
  PrinterRow copyWithCompanion(LocalPrintersCompanion data) {
    return PrinterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      connection: data.connection.present
          ? data.connection.value
          : this.connection,
      address: data.address.present ? data.address.value : this.address,
      paperMm: data.paperMm.present ? data.paperMm.value : this.paperMm,
      opensCashDrawer: data.opensCashDrawer.present
          ? data.opensCashDrawer.value
          : this.opensCashDrawer,
      autoPrint: data.autoPrint.present ? data.autoPrint.value : this.autoPrint,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrinterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('connection: $connection, ')
          ..write('address: $address, ')
          ..write('paperMm: $paperMm, ')
          ..write('opensCashDrawer: $opensCashDrawer, ')
          ..write('autoPrint: $autoPrint')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    connection,
    address,
    paperMm,
    opensCashDrawer,
    autoPrint,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrinterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.connection == this.connection &&
          other.address == this.address &&
          other.paperMm == this.paperMm &&
          other.opensCashDrawer == this.opensCashDrawer &&
          other.autoPrint == this.autoPrint);
}

class LocalPrintersCompanion extends UpdateCompanion<PrinterRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> connection;
  final Value<String> address;
  final Value<int> paperMm;
  final Value<bool> opensCashDrawer;
  final Value<bool> autoPrint;
  final Value<int> rowid;
  const LocalPrintersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.connection = const Value.absent(),
    this.address = const Value.absent(),
    this.paperMm = const Value.absent(),
    this.opensCashDrawer = const Value.absent(),
    this.autoPrint = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPrintersCompanion.insert({
    required String id,
    required String name,
    required String connection,
    required String address,
    required int paperMm,
    required bool opensCashDrawer,
    required bool autoPrint,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       connection = Value(connection),
       address = Value(address),
       paperMm = Value(paperMm),
       opensCashDrawer = Value(opensCashDrawer),
       autoPrint = Value(autoPrint);
  static Insertable<PrinterRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? connection,
    Expression<String>? address,
    Expression<int>? paperMm,
    Expression<bool>? opensCashDrawer,
    Expression<bool>? autoPrint,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (connection != null) 'connection': connection,
      if (address != null) 'address': address,
      if (paperMm != null) 'paper_mm': paperMm,
      if (opensCashDrawer != null) 'opens_cash_drawer': opensCashDrawer,
      if (autoPrint != null) 'auto_print': autoPrint,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPrintersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? connection,
    Value<String>? address,
    Value<int>? paperMm,
    Value<bool>? opensCashDrawer,
    Value<bool>? autoPrint,
    Value<int>? rowid,
  }) {
    return LocalPrintersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      connection: connection ?? this.connection,
      address: address ?? this.address,
      paperMm: paperMm ?? this.paperMm,
      opensCashDrawer: opensCashDrawer ?? this.opensCashDrawer,
      autoPrint: autoPrint ?? this.autoPrint,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (connection.present) {
      map['connection'] = Variable<String>(connection.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (paperMm.present) {
      map['paper_mm'] = Variable<int>(paperMm.value);
    }
    if (opensCashDrawer.present) {
      map['opens_cash_drawer'] = Variable<bool>(opensCashDrawer.value);
    }
    if (autoPrint.present) {
      map['auto_print'] = Variable<bool>(autoPrint.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPrintersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('connection: $connection, ')
          ..write('address: $address, ')
          ..write('paperMm: $paperMm, ')
          ..write('opensCashDrawer: $opensCashDrawer, ')
          ..write('autoPrint: $autoPrint, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalReceivablesTable extends LocalReceivables
    with TableInfo<$LocalReceivablesTable, ReceivableRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalReceivablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivableIdMeta = const VerificationMeta(
    'receivableId',
  );
  @override
  late final GeneratedColumn<String> receivableId = GeneratedColumn<String>(
    'receivable_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAmountMeta = const VerificationMeta(
    'paidAmount',
  );
  @override
  late final GeneratedColumn<int> paidAmount = GeneratedColumn<int>(
    'paid_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    orderId,
    receivableId,
    customerId,
    amount,
    paidAmount,
    dueDate,
    status,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_receivables';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceivableRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('receivable_id')) {
      context.handle(
        _receivableIdMeta,
        receivableId.isAcceptableOrUnknown(
          data['receivable_id']!,
          _receivableIdMeta,
        ),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('paid_amount')) {
      context.handle(
        _paidAmountMeta,
        paidAmount.isAcceptableOrUnknown(data['paid_amount']!, _paidAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAmountMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {orderId};
  @override
  ReceivableRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceivableRow(
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      receivableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receivable_id'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      paidAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_amount'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalReceivablesTable createAlias(String alias) {
    return $LocalReceivablesTable(attachedDatabase, alias);
  }
}

class ReceivableRow extends DataClass implements Insertable<ReceivableRow> {
  final String orderId;

  /// The server's receivable id, once pulled.
  final String? receivableId;
  final String customerId;
  final int amount;
  final int paidAmount;

  /// Store-local due date (midnight UTC of that day).
  final DateTime dueDate;

  /// `open`, `partial`, `paid` or `void`.
  final String status;
  final DateTime updatedAt;
  const ReceivableRow({
    required this.orderId,
    this.receivableId,
    required this.customerId,
    required this.amount,
    required this.paidAmount,
    required this.dueDate,
    required this.status,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['order_id'] = Variable<String>(orderId);
    if (!nullToAbsent || receivableId != null) {
      map['receivable_id'] = Variable<String>(receivableId);
    }
    map['customer_id'] = Variable<String>(customerId);
    map['amount'] = Variable<int>(amount);
    map['paid_amount'] = Variable<int>(paidAmount);
    map['due_date'] = Variable<DateTime>(dueDate);
    map['status'] = Variable<String>(status);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalReceivablesCompanion toCompanion(bool nullToAbsent) {
    return LocalReceivablesCompanion(
      orderId: Value(orderId),
      receivableId: receivableId == null && nullToAbsent
          ? const Value.absent()
          : Value(receivableId),
      customerId: Value(customerId),
      amount: Value(amount),
      paidAmount: Value(paidAmount),
      dueDate: Value(dueDate),
      status: Value(status),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReceivableRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceivableRow(
      orderId: serializer.fromJson<String>(json['orderId']),
      receivableId: serializer.fromJson<String?>(json['receivableId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      amount: serializer.fromJson<int>(json['amount']),
      paidAmount: serializer.fromJson<int>(json['paidAmount']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'orderId': serializer.toJson<String>(orderId),
      'receivableId': serializer.toJson<String?>(receivableId),
      'customerId': serializer.toJson<String>(customerId),
      'amount': serializer.toJson<int>(amount),
      'paidAmount': serializer.toJson<int>(paidAmount),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'status': serializer.toJson<String>(status),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReceivableRow copyWith({
    String? orderId,
    Value<String?> receivableId = const Value.absent(),
    String? customerId,
    int? amount,
    int? paidAmount,
    DateTime? dueDate,
    String? status,
    DateTime? updatedAt,
  }) => ReceivableRow(
    orderId: orderId ?? this.orderId,
    receivableId: receivableId.present ? receivableId.value : this.receivableId,
    customerId: customerId ?? this.customerId,
    amount: amount ?? this.amount,
    paidAmount: paidAmount ?? this.paidAmount,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReceivableRow copyWithCompanion(LocalReceivablesCompanion data) {
    return ReceivableRow(
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      receivableId: data.receivableId.present
          ? data.receivableId.value
          : this.receivableId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      amount: data.amount.present ? data.amount.value : this.amount,
      paidAmount: data.paidAmount.present
          ? data.paidAmount.value
          : this.paidAmount,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceivableRow(')
          ..write('orderId: $orderId, ')
          ..write('receivableId: $receivableId, ')
          ..write('customerId: $customerId, ')
          ..write('amount: $amount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    orderId,
    receivableId,
    customerId,
    amount,
    paidAmount,
    dueDate,
    status,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceivableRow &&
          other.orderId == this.orderId &&
          other.receivableId == this.receivableId &&
          other.customerId == this.customerId &&
          other.amount == this.amount &&
          other.paidAmount == this.paidAmount &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.updatedAt == this.updatedAt);
}

class LocalReceivablesCompanion extends UpdateCompanion<ReceivableRow> {
  final Value<String> orderId;
  final Value<String?> receivableId;
  final Value<String> customerId;
  final Value<int> amount;
  final Value<int> paidAmount;
  final Value<DateTime> dueDate;
  final Value<String> status;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalReceivablesCompanion({
    this.orderId = const Value.absent(),
    this.receivableId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.amount = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalReceivablesCompanion.insert({
    required String orderId,
    this.receivableId = const Value.absent(),
    required String customerId,
    required int amount,
    required int paidAmount,
    required DateTime dueDate,
    required String status,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : orderId = Value(orderId),
       customerId = Value(customerId),
       amount = Value(amount),
       paidAmount = Value(paidAmount),
       dueDate = Value(dueDate),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<ReceivableRow> custom({
    Expression<String>? orderId,
    Expression<String>? receivableId,
    Expression<String>? customerId,
    Expression<int>? amount,
    Expression<int>? paidAmount,
    Expression<DateTime>? dueDate,
    Expression<String>? status,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (orderId != null) 'order_id': orderId,
      if (receivableId != null) 'receivable_id': receivableId,
      if (customerId != null) 'customer_id': customerId,
      if (amount != null) 'amount': amount,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalReceivablesCompanion copyWith({
    Value<String>? orderId,
    Value<String?>? receivableId,
    Value<String>? customerId,
    Value<int>? amount,
    Value<int>? paidAmount,
    Value<DateTime>? dueDate,
    Value<String>? status,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalReceivablesCompanion(
      orderId: orderId ?? this.orderId,
      receivableId: receivableId ?? this.receivableId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (receivableId.present) {
      map['receivable_id'] = Variable<String>(receivableId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<int>(paidAmount.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalReceivablesCompanion(')
          ..write('orderId: $orderId, ')
          ..write('receivableId: $receivableId, ')
          ..write('customerId: $customerId, ')
          ..write('amount: $amount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalReceivablePaymentsTable extends LocalReceivablePayments
    with TableInfo<$LocalReceivablePaymentsTable, ReceivablePaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalReceivablePaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodTypeMeta = const VerificationMeta(
    'methodType',
  );
  @override
  late final GeneratedColumn<String> methodType = GeneratedColumn<String>(
    'method_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _employeeNameMeta = const VerificationMeta(
    'employeeName',
  );
  @override
  late final GeneratedColumn<String> employeeName = GeneratedColumn<String>(
    'employee_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
    'paid_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    customerId,
    shiftId,
    amount,
    methodType,
    reference,
    employeeName,
    paidAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_receivable_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceivablePaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('method_type')) {
      context.handle(
        _methodTypeMeta,
        methodType.isAcceptableOrUnknown(data['method_type']!, _methodTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_methodTypeMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('employee_name')) {
      context.handle(
        _employeeNameMeta,
        employeeName.isAcceptableOrUnknown(
          data['employee_name']!,
          _employeeNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_employeeNameMeta);
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceivablePaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceivablePaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      methodType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method_type'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      employeeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_name'],
      )!,
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at'],
      )!,
    );
  }

  @override
  $LocalReceivablePaymentsTable createAlias(String alias) {
    return $LocalReceivablePaymentsTable(attachedDatabase, alias);
  }
}

class ReceivablePaymentRow extends DataClass
    implements Insertable<ReceivablePaymentRow> {
  final String id;
  final String orderId;
  final String customerId;

  /// The open shift (required for cash).
  final String? shiftId;
  final int amount;

  /// `cash`, `qris`, `card`, `transfer` or `ewallet`.
  final String methodType;
  final String? reference;
  final String employeeName;
  final DateTime paidAt;
  const ReceivablePaymentRow({
    required this.id,
    required this.orderId,
    required this.customerId,
    this.shiftId,
    required this.amount,
    required this.methodType,
    this.reference,
    required this.employeeName,
    required this.paidAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['customer_id'] = Variable<String>(customerId);
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<String>(shiftId);
    }
    map['amount'] = Variable<int>(amount);
    map['method_type'] = Variable<String>(methodType);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    map['employee_name'] = Variable<String>(employeeName);
    map['paid_at'] = Variable<DateTime>(paidAt);
    return map;
  }

  LocalReceivablePaymentsCompanion toCompanion(bool nullToAbsent) {
    return LocalReceivablePaymentsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      customerId: Value(customerId),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      amount: Value(amount),
      methodType: Value(methodType),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      employeeName: Value(employeeName),
      paidAt: Value(paidAt),
    );
  }

  factory ReceivablePaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceivablePaymentRow(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      shiftId: serializer.fromJson<String?>(json['shiftId']),
      amount: serializer.fromJson<int>(json['amount']),
      methodType: serializer.fromJson<String>(json['methodType']),
      reference: serializer.fromJson<String?>(json['reference']),
      employeeName: serializer.fromJson<String>(json['employeeName']),
      paidAt: serializer.fromJson<DateTime>(json['paidAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'customerId': serializer.toJson<String>(customerId),
      'shiftId': serializer.toJson<String?>(shiftId),
      'amount': serializer.toJson<int>(amount),
      'methodType': serializer.toJson<String>(methodType),
      'reference': serializer.toJson<String?>(reference),
      'employeeName': serializer.toJson<String>(employeeName),
      'paidAt': serializer.toJson<DateTime>(paidAt),
    };
  }

  ReceivablePaymentRow copyWith({
    String? id,
    String? orderId,
    String? customerId,
    Value<String?> shiftId = const Value.absent(),
    int? amount,
    String? methodType,
    Value<String?> reference = const Value.absent(),
    String? employeeName,
    DateTime? paidAt,
  }) => ReceivablePaymentRow(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    customerId: customerId ?? this.customerId,
    shiftId: shiftId.present ? shiftId.value : this.shiftId,
    amount: amount ?? this.amount,
    methodType: methodType ?? this.methodType,
    reference: reference.present ? reference.value : this.reference,
    employeeName: employeeName ?? this.employeeName,
    paidAt: paidAt ?? this.paidAt,
  );
  ReceivablePaymentRow copyWithCompanion(
    LocalReceivablePaymentsCompanion data,
  ) {
    return ReceivablePaymentRow(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      amount: data.amount.present ? data.amount.value : this.amount,
      methodType: data.methodType.present
          ? data.methodType.value
          : this.methodType,
      reference: data.reference.present ? data.reference.value : this.reference,
      employeeName: data.employeeName.present
          ? data.employeeName.value
          : this.employeeName,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceivablePaymentRow(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('customerId: $customerId, ')
          ..write('shiftId: $shiftId, ')
          ..write('amount: $amount, ')
          ..write('methodType: $methodType, ')
          ..write('reference: $reference, ')
          ..write('employeeName: $employeeName, ')
          ..write('paidAt: $paidAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderId,
    customerId,
    shiftId,
    amount,
    methodType,
    reference,
    employeeName,
    paidAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceivablePaymentRow &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.customerId == this.customerId &&
          other.shiftId == this.shiftId &&
          other.amount == this.amount &&
          other.methodType == this.methodType &&
          other.reference == this.reference &&
          other.employeeName == this.employeeName &&
          other.paidAt == this.paidAt);
}

class LocalReceivablePaymentsCompanion
    extends UpdateCompanion<ReceivablePaymentRow> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> customerId;
  final Value<String?> shiftId;
  final Value<int> amount;
  final Value<String> methodType;
  final Value<String?> reference;
  final Value<String> employeeName;
  final Value<DateTime> paidAt;
  final Value<int> rowid;
  const LocalReceivablePaymentsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.amount = const Value.absent(),
    this.methodType = const Value.absent(),
    this.reference = const Value.absent(),
    this.employeeName = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalReceivablePaymentsCompanion.insert({
    required String id,
    required String orderId,
    required String customerId,
    this.shiftId = const Value.absent(),
    required int amount,
    required String methodType,
    this.reference = const Value.absent(),
    required String employeeName,
    required DateTime paidAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderId = Value(orderId),
       customerId = Value(customerId),
       amount = Value(amount),
       methodType = Value(methodType),
       employeeName = Value(employeeName),
       paidAt = Value(paidAt);
  static Insertable<ReceivablePaymentRow> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? customerId,
    Expression<String>? shiftId,
    Expression<int>? amount,
    Expression<String>? methodType,
    Expression<String>? reference,
    Expression<String>? employeeName,
    Expression<DateTime>? paidAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (customerId != null) 'customer_id': customerId,
      if (shiftId != null) 'shift_id': shiftId,
      if (amount != null) 'amount': amount,
      if (methodType != null) 'method_type': methodType,
      if (reference != null) 'reference': reference,
      if (employeeName != null) 'employee_name': employeeName,
      if (paidAt != null) 'paid_at': paidAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalReceivablePaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? orderId,
    Value<String>? customerId,
    Value<String?>? shiftId,
    Value<int>? amount,
    Value<String>? methodType,
    Value<String?>? reference,
    Value<String>? employeeName,
    Value<DateTime>? paidAt,
    Value<int>? rowid,
  }) {
    return LocalReceivablePaymentsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      shiftId: shiftId ?? this.shiftId,
      amount: amount ?? this.amount,
      methodType: methodType ?? this.methodType,
      reference: reference ?? this.reference,
      employeeName: employeeName ?? this.employeeName,
      paidAt: paidAt ?? this.paidAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (methodType.present) {
      map['method_type'] = Variable<String>(methodType.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (employeeName.present) {
      map['employee_name'] = Variable<String>(employeeName.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalReceivablePaymentsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('customerId: $customerId, ')
          ..write('shiftId: $shiftId, ')
          ..write('amount: $amount, ')
          ..write('methodType: $methodType, ')
          ..write('reference: $reference, ')
          ..write('employeeName: $employeeName, ')
          ..write('paidAt: $paidAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $LocalDeviceTable localDevice = $LocalDeviceTable(this);
  late final $LocalStoresTable localStores = $LocalStoresTable(this);
  late final $LocalStoreSettingsTable localStoreSettings =
      $LocalStoreSettingsTable(this);
  late final $LocalStaffTable localStaff = $LocalStaffTable(this);
  late final $PinAttemptsTable pinAttempts = $PinAttemptsTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $UnitsTable units = $UnitsTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $ProductVariantsTable productVariants = $ProductVariantsTable(
    this,
  );
  late final $StoreVariantSettingsTable storeVariantSettings =
      $StoreVariantSettingsTable(this);
  late final $ModifierGroupsTable modifierGroups = $ModifierGroupsTable(this);
  late final $ModifiersTable modifiers = $ModifiersTable(this);
  late final $ProductModifierGroupsTable productModifierGroups =
      $ProductModifierGroupsTable(this);
  late final $StoreFavoritesTable storeFavorites = $StoreFavoritesTable(this);
  late final $StockLevelsTable stockLevels = $StockLevelsTable(this);
  late final $MirrorRecordsTable mirrorRecords = $MirrorRecordsTable(this);
  late final $LocalCustomersTable localCustomers = $LocalCustomersTable(this);
  late final $LocalShiftsTable localShifts = $LocalShiftsTable(this);
  late final $LocalOrdersTable localOrders = $LocalOrdersTable(this);
  late final $LocalCountersTable localCounters = $LocalCountersTable(this);
  late final $LocalCashMovementsTable localCashMovements =
      $LocalCashMovementsTable(this);
  late final $LocalRefundsTable localRefunds = $LocalRefundsTable(this);
  late final $LocalPrintersTable localPrinters = $LocalPrintersTable(this);
  late final $LocalReceivablesTable localReceivables = $LocalReceivablesTable(
    this,
  );
  late final $LocalReceivablePaymentsTable localReceivablePayments =
      $LocalReceivablePaymentsTable(this);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    syncQueue,
    localDevice,
    localStores,
    localStoreSettings,
    localStaff,
    pinAttempts,
    syncCursors,
    categories,
    units,
    products,
    productVariants,
    storeVariantSettings,
    modifierGroups,
    modifiers,
    productModifierGroups,
    storeFavorites,
    stockLevels,
    mirrorRecords,
    localCustomers,
    localShifts,
    localOrders,
    localCounters,
    localCashMovements,
    localRefunds,
    localPrinters,
    localReceivables,
    localReceivablePayments,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String clientUuid,
  required String entity,
  required String action,
  required String payload,
  required DateTime createdAt,
  Value<int> retryCount,
  required SyncStatus status,
  Value<String?> lastError,
  Value<DateTime?> nextAttemptAt,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> clientUuid,
  Value<String> entity,
  Value<String> action,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<int> retryCount,
  Value<SyncStatus> status,
  Value<String?> lastError,
  Value<DateTime?> nextAttemptAt,
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

  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
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

  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
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

  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueEntry,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueEntry,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>,
          ),
          SyncQueueEntry,
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
                Value<String> clientUuid = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<SyncStatus> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                clientUuid: clientUuid,
                entity: entity,
                action: action,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                status: status,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientUuid,
                required String entity,
                required String action,
                required String payload,
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                required SyncStatus status,
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                clientUuid: clientUuid,
                entity: entity,
                action: action,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                status: status,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueTable, SyncQueueEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncQueueTable,
                    SyncQueueEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueEntry,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueEntry,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>,
      ),
      SyncQueueEntry,
      PrefetchHooks Function()
    >;
typedef $$LocalDeviceTableCreateCompanionBuilder =
    LocalDeviceCompanion Function({
      required String deviceId,
      required String deviceCode,
      required String storeId,
      required String name,
      required DateTime pairedAt,
      Value<int> rowid,
    });
typedef $$LocalDeviceTableUpdateCompanionBuilder =
    LocalDeviceCompanion Function({
      Value<String> deviceId,
      Value<String> deviceCode,
      Value<String> storeId,
      Value<String> name,
      Value<DateTime> pairedAt,
      Value<int> rowid,
    });

class $$LocalDeviceTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDeviceTable> {
  $$LocalDeviceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceCode => $composableBuilder(
    column: $table.deviceCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDeviceTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDeviceTable> {
  $$LocalDeviceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceCode => $composableBuilder(
    column: $table.deviceCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDeviceTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDeviceTable> {
  $$LocalDeviceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceCode => $composableBuilder(
    column: $table.deviceCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get pairedAt =>
      $composableBuilder(column: $table.pairedAt, builder: (column) => column);
}

class $$LocalDeviceTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDeviceTable,
          LocalDeviceRow,
          $$LocalDeviceTableFilterComposer,
          $$LocalDeviceTableOrderingComposer,
          $$LocalDeviceTableAnnotationComposer,
          $$LocalDeviceTableCreateCompanionBuilder,
          $$LocalDeviceTableUpdateCompanionBuilder,
          (
            LocalDeviceRow,
            BaseReferences<_$AppDatabase, $LocalDeviceTable, LocalDeviceRow>,
          ),
          LocalDeviceRow,
          PrefetchHooks Function()
        > {
  $$LocalDeviceTableTableManager(_$AppDatabase db, $LocalDeviceTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDeviceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDeviceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDeviceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String> deviceCode = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> pairedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDeviceCompanion(
                deviceId: deviceId,
                deviceCode: deviceCode,
                storeId: storeId,
                name: name,
                pairedAt: pairedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required String deviceCode,
                required String storeId,
                required String name,
                required DateTime pairedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalDeviceCompanion.insert(
                deviceId: deviceId,
                deviceCode: deviceCode,
                storeId: storeId,
                name: name,
                pairedAt: pairedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalDeviceTable, LocalDeviceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalDeviceTable,
                    LocalDeviceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDeviceTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDeviceTable,
      LocalDeviceRow,
      $$LocalDeviceTableFilterComposer,
      $$LocalDeviceTableOrderingComposer,
      $$LocalDeviceTableAnnotationComposer,
      $$LocalDeviceTableCreateCompanionBuilder,
      $$LocalDeviceTableUpdateCompanionBuilder,
      (
        LocalDeviceRow,
        BaseReferences<_$AppDatabase, $LocalDeviceTable, LocalDeviceRow>,
      ),
      LocalDeviceRow,
      PrefetchHooks Function()
    >;
typedef $$LocalStoresTableCreateCompanionBuilder =
    LocalStoresCompanion Function({
      required String id,
      required String code,
      required String name,
      Value<String?> address,
      Value<String?> phone,
      required String timezone,
      required bool fnbMode,
      Value<int> rowid,
    });
typedef $$LocalStoresTableUpdateCompanionBuilder =
    LocalStoresCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> name,
      Value<String?> address,
      Value<String?> phone,
      Value<String> timezone,
      Value<bool> fnbMode,
      Value<int> rowid,
    });

class $$LocalStoresTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStoresTable> {
  $$LocalStoresTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fnbMode => $composableBuilder(
    column: $table.fnbMode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStoresTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStoresTable> {
  $$LocalStoresTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fnbMode => $composableBuilder(
    column: $table.fnbMode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStoresTable> {
  $$LocalStoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<bool> get fnbMode =>
      $composableBuilder(column: $table.fnbMode, builder: (column) => column);
}

class $$LocalStoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStoresTable,
          LocalStoreRow,
          $$LocalStoresTableFilterComposer,
          $$LocalStoresTableOrderingComposer,
          $$LocalStoresTableAnnotationComposer,
          $$LocalStoresTableCreateCompanionBuilder,
          $$LocalStoresTableUpdateCompanionBuilder,
          (
            LocalStoreRow,
            BaseReferences<_$AppDatabase, $LocalStoresTable, LocalStoreRow>,
          ),
          LocalStoreRow,
          PrefetchHooks Function()
        > {
  $$LocalStoresTableTableManager(_$AppDatabase db, $LocalStoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalStoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<bool> fnbMode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStoresCompanion(
                id: id,
                code: code,
                name: name,
                address: address,
                phone: phone,
                timezone: timezone,
                fnbMode: fnbMode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String name,
                Value<String?> address = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                required String timezone,
                required bool fnbMode,
                Value<int> rowid = const Value.absent(),
              }) => LocalStoresCompanion.insert(
                id: id,
                code: code,
                name: name,
                address: address,
                phone: phone,
                timezone: timezone,
                fnbMode: fnbMode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalStoresTable, LocalStoreRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalStoresTable,
                    LocalStoreRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStoresTable,
      LocalStoreRow,
      $$LocalStoresTableFilterComposer,
      $$LocalStoresTableOrderingComposer,
      $$LocalStoresTableAnnotationComposer,
      $$LocalStoresTableCreateCompanionBuilder,
      $$LocalStoresTableUpdateCompanionBuilder,
      (
        LocalStoreRow,
        BaseReferences<_$AppDatabase, $LocalStoresTable, LocalStoreRow>,
      ),
      LocalStoreRow,
      PrefetchHooks Function()
    >;
typedef $$LocalStoreSettingsTableCreateCompanionBuilder =
    LocalStoreSettingsCompanion Function({
      required String storeId,
      required bool taxEnabled,
      required String taxName,
      required int taxRateBps,
      required bool taxInclusive,
      required bool serviceChargeEnabled,
      required int serviceChargeBps,
      required bool serviceChargeTaxable,
      required String roundingMode,
      required int roundingUnit,
      required int discountApprovalBps,
      required bool kasbonEnabled,
      Value<String?> receiptHeader,
      required String receiptFooter,
      required int receiptPaperMm,
      Value<int> rowid,
    });
typedef $$LocalStoreSettingsTableUpdateCompanionBuilder =
    LocalStoreSettingsCompanion Function({
      Value<String> storeId,
      Value<bool> taxEnabled,
      Value<String> taxName,
      Value<int> taxRateBps,
      Value<bool> taxInclusive,
      Value<bool> serviceChargeEnabled,
      Value<int> serviceChargeBps,
      Value<bool> serviceChargeTaxable,
      Value<String> roundingMode,
      Value<int> roundingUnit,
      Value<int> discountApprovalBps,
      Value<bool> kasbonEnabled,
      Value<String?> receiptHeader,
      Value<String> receiptFooter,
      Value<int> receiptPaperMm,
      Value<int> rowid,
    });

class $$LocalStoreSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStoreSettingsTable> {
  $$LocalStoreSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get taxEnabled => $composableBuilder(
    column: $table.taxEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxName => $composableBuilder(
    column: $table.taxName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxRateBps => $composableBuilder(
    column: $table.taxRateBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get taxInclusive => $composableBuilder(
    column: $table.taxInclusive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get serviceChargeEnabled => $composableBuilder(
    column: $table.serviceChargeEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceChargeBps => $composableBuilder(
    column: $table.serviceChargeBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get serviceChargeTaxable => $composableBuilder(
    column: $table.serviceChargeTaxable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roundingMode => $composableBuilder(
    column: $table.roundingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundingUnit => $composableBuilder(
    column: $table.roundingUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountApprovalBps => $composableBuilder(
    column: $table.discountApprovalBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get kasbonEnabled => $composableBuilder(
    column: $table.kasbonEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptHeader => $composableBuilder(
    column: $table.receiptHeader,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptFooter => $composableBuilder(
    column: $table.receiptFooter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receiptPaperMm => $composableBuilder(
    column: $table.receiptPaperMm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStoreSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStoreSettingsTable> {
  $$LocalStoreSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get taxEnabled => $composableBuilder(
    column: $table.taxEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxName => $composableBuilder(
    column: $table.taxName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxRateBps => $composableBuilder(
    column: $table.taxRateBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get taxInclusive => $composableBuilder(
    column: $table.taxInclusive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get serviceChargeEnabled => $composableBuilder(
    column: $table.serviceChargeEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceChargeBps => $composableBuilder(
    column: $table.serviceChargeBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get serviceChargeTaxable => $composableBuilder(
    column: $table.serviceChargeTaxable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roundingMode => $composableBuilder(
    column: $table.roundingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundingUnit => $composableBuilder(
    column: $table.roundingUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountApprovalBps => $composableBuilder(
    column: $table.discountApprovalBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get kasbonEnabled => $composableBuilder(
    column: $table.kasbonEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptHeader => $composableBuilder(
    column: $table.receiptHeader,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptFooter => $composableBuilder(
    column: $table.receiptFooter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receiptPaperMm => $composableBuilder(
    column: $table.receiptPaperMm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStoreSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStoreSettingsTable> {
  $$LocalStoreSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<bool> get taxEnabled => $composableBuilder(
    column: $table.taxEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxName =>
      $composableBuilder(column: $table.taxName, builder: (column) => column);

  GeneratedColumn<int> get taxRateBps => $composableBuilder(
    column: $table.taxRateBps,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get taxInclusive => $composableBuilder(
    column: $table.taxInclusive,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get serviceChargeEnabled => $composableBuilder(
    column: $table.serviceChargeEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serviceChargeBps => $composableBuilder(
    column: $table.serviceChargeBps,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get serviceChargeTaxable => $composableBuilder(
    column: $table.serviceChargeTaxable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roundingMode => $composableBuilder(
    column: $table.roundingMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get roundingUnit => $composableBuilder(
    column: $table.roundingUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountApprovalBps => $composableBuilder(
    column: $table.discountApprovalBps,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get kasbonEnabled => $composableBuilder(
    column: $table.kasbonEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptHeader => $composableBuilder(
    column: $table.receiptHeader,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptFooter => $composableBuilder(
    column: $table.receiptFooter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receiptPaperMm => $composableBuilder(
    column: $table.receiptPaperMm,
    builder: (column) => column,
  );
}

class $$LocalStoreSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStoreSettingsTable,
          LocalStoreSettingsRow,
          $$LocalStoreSettingsTableFilterComposer,
          $$LocalStoreSettingsTableOrderingComposer,
          $$LocalStoreSettingsTableAnnotationComposer,
          $$LocalStoreSettingsTableCreateCompanionBuilder,
          $$LocalStoreSettingsTableUpdateCompanionBuilder,
          (
            LocalStoreSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $LocalStoreSettingsTable,
              LocalStoreSettingsRow
            >,
          ),
          LocalStoreSettingsRow,
          PrefetchHooks Function()
        > {
  $$LocalStoreSettingsTableTableManager(
    _$AppDatabase db,
    $LocalStoreSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStoreSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStoreSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalStoreSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> storeId = const Value.absent(),
                Value<bool> taxEnabled = const Value.absent(),
                Value<String> taxName = const Value.absent(),
                Value<int> taxRateBps = const Value.absent(),
                Value<bool> taxInclusive = const Value.absent(),
                Value<bool> serviceChargeEnabled = const Value.absent(),
                Value<int> serviceChargeBps = const Value.absent(),
                Value<bool> serviceChargeTaxable = const Value.absent(),
                Value<String> roundingMode = const Value.absent(),
                Value<int> roundingUnit = const Value.absent(),
                Value<int> discountApprovalBps = const Value.absent(),
                Value<bool> kasbonEnabled = const Value.absent(),
                Value<String?> receiptHeader = const Value.absent(),
                Value<String> receiptFooter = const Value.absent(),
                Value<int> receiptPaperMm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStoreSettingsCompanion(
                storeId: storeId,
                taxEnabled: taxEnabled,
                taxName: taxName,
                taxRateBps: taxRateBps,
                taxInclusive: taxInclusive,
                serviceChargeEnabled: serviceChargeEnabled,
                serviceChargeBps: serviceChargeBps,
                serviceChargeTaxable: serviceChargeTaxable,
                roundingMode: roundingMode,
                roundingUnit: roundingUnit,
                discountApprovalBps: discountApprovalBps,
                kasbonEnabled: kasbonEnabled,
                receiptHeader: receiptHeader,
                receiptFooter: receiptFooter,
                receiptPaperMm: receiptPaperMm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String storeId,
                required bool taxEnabled,
                required String taxName,
                required int taxRateBps,
                required bool taxInclusive,
                required bool serviceChargeEnabled,
                required int serviceChargeBps,
                required bool serviceChargeTaxable,
                required String roundingMode,
                required int roundingUnit,
                required int discountApprovalBps,
                required bool kasbonEnabled,
                Value<String?> receiptHeader = const Value.absent(),
                required String receiptFooter,
                required int receiptPaperMm,
                Value<int> rowid = const Value.absent(),
              }) => LocalStoreSettingsCompanion.insert(
                storeId: storeId,
                taxEnabled: taxEnabled,
                taxName: taxName,
                taxRateBps: taxRateBps,
                taxInclusive: taxInclusive,
                serviceChargeEnabled: serviceChargeEnabled,
                serviceChargeBps: serviceChargeBps,
                serviceChargeTaxable: serviceChargeTaxable,
                roundingMode: roundingMode,
                roundingUnit: roundingUnit,
                discountApprovalBps: discountApprovalBps,
                kasbonEnabled: kasbonEnabled,
                receiptHeader: receiptHeader,
                receiptFooter: receiptFooter,
                receiptPaperMm: receiptPaperMm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalStoreSettingsTable, LocalStoreSettingsRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalStoreSettingsTable,
                    LocalStoreSettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStoreSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStoreSettingsTable,
      LocalStoreSettingsRow,
      $$LocalStoreSettingsTableFilterComposer,
      $$LocalStoreSettingsTableOrderingComposer,
      $$LocalStoreSettingsTableAnnotationComposer,
      $$LocalStoreSettingsTableCreateCompanionBuilder,
      $$LocalStoreSettingsTableUpdateCompanionBuilder,
      (
        LocalStoreSettingsRow,
        BaseReferences<
          _$AppDatabase,
          $LocalStoreSettingsTable,
          LocalStoreSettingsRow
        >,
      ),
      LocalStoreSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$LocalStaffTableCreateCompanionBuilder = LocalStaffCompanion Function({
  required String employeeId,
  required String fullName,
  required String roleCode,
  required String permissions,
  Value<String?> pinHash,
  required bool isActive,
  required DateTime syncedAt,
  Value<int> rowid,
});
typedef $$LocalStaffTableUpdateCompanionBuilder = LocalStaffCompanion Function({
  Value<String> employeeId,
  Value<String> fullName,
  Value<String> roleCode,
  Value<String> permissions,
  Value<String?> pinHash,
  Value<bool> isActive,
  Value<DateTime> syncedAt,
  Value<int> rowid,
});

class $$LocalStaffTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStaffTable> {
  $$LocalStaffTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleCode => $composableBuilder(
    column: $table.roleCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStaffTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStaffTable> {
  $$LocalStaffTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleCode => $composableBuilder(
    column: $table.roleCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStaffTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStaffTable> {
  $$LocalStaffTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get roleCode =>
      $composableBuilder(column: $table.roleCode, builder: (column) => column);

  GeneratedColumn<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalStaffTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStaffTable,
          LocalStaffRow,
          $$LocalStaffTableFilterComposer,
          $$LocalStaffTableOrderingComposer,
          $$LocalStaffTableAnnotationComposer,
          $$LocalStaffTableCreateCompanionBuilder,
          $$LocalStaffTableUpdateCompanionBuilder,
          (
            LocalStaffRow,
            BaseReferences<_$AppDatabase, $LocalStaffTable, LocalStaffRow>,
          ),
          LocalStaffRow,
          PrefetchHooks Function()
        > {
  $$LocalStaffTableTableManager(_$AppDatabase db, $LocalStaffTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStaffTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStaffTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalStaffTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> employeeId = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> roleCode = const Value.absent(),
                Value<String> permissions = const Value.absent(),
                Value<String?> pinHash = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStaffCompanion(
                employeeId: employeeId,
                fullName: fullName,
                roleCode: roleCode,
                permissions: permissions,
                pinHash: pinHash,
                isActive: isActive,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String employeeId,
                required String fullName,
                required String roleCode,
                required String permissions,
                Value<String?> pinHash = const Value.absent(),
                required bool isActive,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalStaffCompanion.insert(
                employeeId: employeeId,
                fullName: fullName,
                roleCode: roleCode,
                permissions: permissions,
                pinHash: pinHash,
                isActive: isActive,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalStaffTable, LocalStaffRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalStaffTable,
                    LocalStaffRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStaffTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStaffTable,
      LocalStaffRow,
      $$LocalStaffTableFilterComposer,
      $$LocalStaffTableOrderingComposer,
      $$LocalStaffTableAnnotationComposer,
      $$LocalStaffTableCreateCompanionBuilder,
      $$LocalStaffTableUpdateCompanionBuilder,
      (
        LocalStaffRow,
        BaseReferences<_$AppDatabase, $LocalStaffTable, LocalStaffRow>,
      ),
      LocalStaffRow,
      PrefetchHooks Function()
    >;
typedef $$PinAttemptsTableCreateCompanionBuilder =
    PinAttemptsCompanion Function({
      required String employeeId,
      Value<int> failedAttempts,
      Value<DateTime?> lockedUntil,
      Value<int> rowid,
    });
typedef $$PinAttemptsTableUpdateCompanionBuilder =
    PinAttemptsCompanion Function({
      Value<String> employeeId,
      Value<int> failedAttempts,
      Value<DateTime?> lockedUntil,
      Value<int> rowid,
    });

class $$PinAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $PinAttemptsTable> {
  $$PinAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PinAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $PinAttemptsTable> {
  $$PinAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PinAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PinAttemptsTable> {
  $$PinAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => column,
  );
}

class $$PinAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PinAttemptsTable,
          PinAttemptRow,
          $$PinAttemptsTableFilterComposer,
          $$PinAttemptsTableOrderingComposer,
          $$PinAttemptsTableAnnotationComposer,
          $$PinAttemptsTableCreateCompanionBuilder,
          $$PinAttemptsTableUpdateCompanionBuilder,
          (
            PinAttemptRow,
            BaseReferences<_$AppDatabase, $PinAttemptsTable, PinAttemptRow>,
          ),
          PinAttemptRow,
          PrefetchHooks Function()
        > {
  $$PinAttemptsTableTableManager(_$AppDatabase db, $PinAttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PinAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PinAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PinAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> employeeId = const Value.absent(),
                Value<int> failedAttempts = const Value.absent(),
                Value<DateTime?> lockedUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PinAttemptsCompanion(
                employeeId: employeeId,
                failedAttempts: failedAttempts,
                lockedUntil: lockedUntil,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String employeeId,
                Value<int> failedAttempts = const Value.absent(),
                Value<DateTime?> lockedUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PinAttemptsCompanion.insert(
                employeeId: employeeId,
                failedAttempts: failedAttempts,
                lockedUntil: lockedUntil,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PinAttemptsTable, PinAttemptRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PinAttemptsTable,
                    PinAttemptRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PinAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PinAttemptsTable,
      PinAttemptRow,
      $$PinAttemptsTableFilterComposer,
      $$PinAttemptsTableOrderingComposer,
      $$PinAttemptsTableAnnotationComposer,
      $$PinAttemptsTableCreateCompanionBuilder,
      $$PinAttemptsTableUpdateCompanionBuilder,
      (
        PinAttemptRow,
        BaseReferences<_$AppDatabase, $PinAttemptsTable, PinAttemptRow>,
      ),
      PinAttemptRow,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String name,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> name,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursorRow,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursorRow,
            BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursorRow>,
          ),
          SyncCursorRow,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncCursorsCompanion(name: name, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                name: name,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCursorsTable, SyncCursorRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncCursorsTable,
                    SyncCursorRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursorRow,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursorRow,
        BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursorRow>,
      ),
      SyncCursorRow,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  Value<String?> parentId,
  required String name,
  required int sortOrder,
  Value<String?> color,
  Value<String?> icon,
  Value<String?> kitchenStation,
  required bool isActive,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String?> parentId,
  Value<String> name,
  Value<int> sortOrder,
  Value<String?> color,
  Value<String?> icon,
  Value<String?> kitchenStation,
  Value<bool> isActive,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kitchenStation => $composableBuilder(
    column: $table.kitchenStation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kitchenStation => $composableBuilder(
    column: $table.kitchenStation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get kitchenStation => $composableBuilder(
    column: $table.kitchenStation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> kitchenStation = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                parentId: parentId,
                name: name,
                sortOrder: sortOrder,
                color: color,
                icon: icon,
                kitchenStation: kitchenStation,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                required String name,
                required int sortOrder,
                Value<String?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> kitchenStation = const Value.absent(),
                required bool isActive,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                parentId: parentId,
                name: name,
                sortOrder: sortOrder,
                color: color,
                icon: icon,
                kitchenStation: kitchenStation,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$UnitsTableCreateCompanionBuilder = UnitsCompanion Function({
  required String id,
  required String code,
  required String name,
  required bool allowDecimal,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$UnitsTableUpdateCompanionBuilder = UnitsCompanion Function({
  Value<String> id,
  Value<String> code,
  Value<String> name,
  Value<bool> allowDecimal,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UnitsTableFilterComposer extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowDecimal => $composableBuilder(
    column: $table.allowDecimal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnitsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowDecimal => $composableBuilder(
    column: $table.allowDecimal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get allowDecimal => $composableBuilder(
    column: $table.allowDecimal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UnitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnitsTable,
          UnitRow,
          $$UnitsTableFilterComposer,
          $$UnitsTableOrderingComposer,
          $$UnitsTableAnnotationComposer,
          $$UnitsTableCreateCompanionBuilder,
          $$UnitsTableUpdateCompanionBuilder,
          (UnitRow, BaseReferences<_$AppDatabase, $UnitsTable, UnitRow>),
          UnitRow,
          PrefetchHooks Function()
        > {
  $$UnitsTableTableManager(_$AppDatabase db, $UnitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> allowDecimal = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnitsCompanion(
                id: id,
                code: code,
                name: name,
                allowDecimal: allowDecimal,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String name,
                required bool allowDecimal,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UnitsCompanion.insert(
                id: id,
                code: code,
                name: name,
                allowDecimal: allowDecimal,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UnitsTable, UnitRow>(table),
                  BaseReferences<_$AppDatabase, $UnitsTable, UnitRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnitsTable,
      UnitRow,
      $$UnitsTableFilterComposer,
      $$UnitsTableOrderingComposer,
      $$UnitsTableAnnotationComposer,
      $$UnitsTableCreateCompanionBuilder,
      $$UnitsTableUpdateCompanionBuilder,
      (UnitRow, BaseReferences<_$AppDatabase, $UnitsTable, UnitRow>),
      UnitRow,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  Value<String?> categoryId,
  required String unitId,
  required String name,
  Value<String?> description,
  required String productType,
  required bool trackStock,
  required bool isTaxable,
  Value<String?> kitchenStation,
  Value<String?> imagePath,
  required bool isActive,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String?> categoryId,
  Value<String> unitId,
  Value<String> name,
  Value<String?> description,
  Value<String> productType,
  Value<bool> trackStock,
  Value<bool> isTaxable,
  Value<String?> kitchenStation,
  Value<String?> imagePath,
  Value<bool> isActive,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
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

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productType => $composableBuilder(
    column: $table.productType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trackStock => $composableBuilder(
    column: $table.trackStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTaxable => $composableBuilder(
    column: $table.isTaxable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kitchenStation => $composableBuilder(
    column: $table.kitchenStation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
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

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productType => $composableBuilder(
    column: $table.productType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trackStock => $composableBuilder(
    column: $table.trackStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTaxable => $composableBuilder(
    column: $table.isTaxable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kitchenStation => $composableBuilder(
    column: $table.kitchenStation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productType => $composableBuilder(
    column: $table.productType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get trackStock => $composableBuilder(
    column: $table.trackStock,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTaxable =>
      $composableBuilder(column: $table.isTaxable, builder: (column) => column);

  GeneratedColumn<String> get kitchenStation => $composableBuilder(
    column: $table.kitchenStation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          ProductRow,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (
            ProductRow,
            BaseReferences<_$AppDatabase, $ProductsTable, ProductRow>,
          ),
          ProductRow,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> unitId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> productType = const Value.absent(),
                Value<bool> trackStock = const Value.absent(),
                Value<bool> isTaxable = const Value.absent(),
                Value<String?> kitchenStation = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                categoryId: categoryId,
                unitId: unitId,
                name: name,
                description: description,
                productType: productType,
                trackStock: trackStock,
                isTaxable: isTaxable,
                kitchenStation: kitchenStation,
                imagePath: imagePath,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> categoryId = const Value.absent(),
                required String unitId,
                required String name,
                Value<String?> description = const Value.absent(),
                required String productType,
                required bool trackStock,
                required bool isTaxable,
                Value<String?> kitchenStation = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                required bool isActive,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                categoryId: categoryId,
                unitId: unitId,
                name: name,
                description: description,
                productType: productType,
                trackStock: trackStock,
                isTaxable: isTaxable,
                kitchenStation: kitchenStation,
                imagePath: imagePath,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductsTable, ProductRow>(table),
                  BaseReferences<_$AppDatabase, $ProductsTable, ProductRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      ProductRow,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (ProductRow, BaseReferences<_$AppDatabase, $ProductsTable, ProductRow>),
      ProductRow,
      PrefetchHooks Function()
    >;
typedef $$ProductVariantsTableCreateCompanionBuilder =
    ProductVariantsCompanion Function({
      required String id,
      required String productId,
      required String name,
      required String sku,
      Value<String?> barcode,
      required int price,
      required int cost,
      required int sortOrder,
      required bool isActive,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProductVariantsTableUpdateCompanionBuilder =
    ProductVariantsCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> name,
      Value<String> sku,
      Value<String?> barcode,
      Value<int> price,
      Value<int> cost,
      Value<int> sortOrder,
      Value<bool> isActive,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProductVariantsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductVariantsTable> {
  $$ProductVariantsTableFilterComposer({
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

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductVariantsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductVariantsTable> {
  $$ProductVariantsTableOrderingComposer({
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

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductVariantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductVariantsTable> {
  $$ProductVariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductVariantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductVariantsTable,
          VariantRow,
          $$ProductVariantsTableFilterComposer,
          $$ProductVariantsTableOrderingComposer,
          $$ProductVariantsTableAnnotationComposer,
          $$ProductVariantsTableCreateCompanionBuilder,
          $$ProductVariantsTableUpdateCompanionBuilder,
          (
            VariantRow,
            BaseReferences<_$AppDatabase, $ProductVariantsTable, VariantRow>,
          ),
          VariantRow,
          PrefetchHooks Function()
        > {
  $$ProductVariantsTableTableManager(
    _$AppDatabase db,
    $ProductVariantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductVariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductVariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductVariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<int> price = const Value.absent(),
                Value<int> cost = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductVariantsCompanion(
                id: id,
                productId: productId,
                name: name,
                sku: sku,
                barcode: barcode,
                price: price,
                cost: cost,
                sortOrder: sortOrder,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String name,
                required String sku,
                Value<String?> barcode = const Value.absent(),
                required int price,
                required int cost,
                required int sortOrder,
                required bool isActive,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductVariantsCompanion.insert(
                id: id,
                productId: productId,
                name: name,
                sku: sku,
                barcode: barcode,
                price: price,
                cost: cost,
                sortOrder: sortOrder,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductVariantsTable, VariantRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProductVariantsTable,
                    VariantRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductVariantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductVariantsTable,
      VariantRow,
      $$ProductVariantsTableFilterComposer,
      $$ProductVariantsTableOrderingComposer,
      $$ProductVariantsTableAnnotationComposer,
      $$ProductVariantsTableCreateCompanionBuilder,
      $$ProductVariantsTableUpdateCompanionBuilder,
      (
        VariantRow,
        BaseReferences<_$AppDatabase, $ProductVariantsTable, VariantRow>,
      ),
      VariantRow,
      PrefetchHooks Function()
    >;
typedef $$StoreVariantSettingsTableCreateCompanionBuilder =
    StoreVariantSettingsCompanion Function({
      required String variantId,
      Value<int?> priceOverride,
      Value<int?> reorderPointMilli,
      Value<int?> reorderQtyMilli,
      required bool isAvailable,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StoreVariantSettingsTableUpdateCompanionBuilder =
    StoreVariantSettingsCompanion Function({
      Value<String> variantId,
      Value<int?> priceOverride,
      Value<int?> reorderPointMilli,
      Value<int?> reorderQtyMilli,
      Value<bool> isAvailable,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StoreVariantSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $StoreVariantSettingsTable> {
  $$StoreVariantSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceOverride => $composableBuilder(
    column: $table.priceOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reorderPointMilli => $composableBuilder(
    column: $table.reorderPointMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reorderQtyMilli => $composableBuilder(
    column: $table.reorderQtyMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoreVariantSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $StoreVariantSettingsTable> {
  $$StoreVariantSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceOverride => $composableBuilder(
    column: $table.priceOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reorderPointMilli => $composableBuilder(
    column: $table.reorderPointMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reorderQtyMilli => $composableBuilder(
    column: $table.reorderQtyMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoreVariantSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoreVariantSettingsTable> {
  $$StoreVariantSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<int> get priceOverride => $composableBuilder(
    column: $table.priceOverride,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reorderPointMilli => $composableBuilder(
    column: $table.reorderPointMilli,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reorderQtyMilli => $composableBuilder(
    column: $table.reorderQtyMilli,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StoreVariantSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoreVariantSettingsTable,
          StoreVariantSettingRow,
          $$StoreVariantSettingsTableFilterComposer,
          $$StoreVariantSettingsTableOrderingComposer,
          $$StoreVariantSettingsTableAnnotationComposer,
          $$StoreVariantSettingsTableCreateCompanionBuilder,
          $$StoreVariantSettingsTableUpdateCompanionBuilder,
          (
            StoreVariantSettingRow,
            BaseReferences<
              _$AppDatabase,
              $StoreVariantSettingsTable,
              StoreVariantSettingRow
            >,
          ),
          StoreVariantSettingRow,
          PrefetchHooks Function()
        > {
  $$StoreVariantSettingsTableTableManager(
    _$AppDatabase db,
    $StoreVariantSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoreVariantSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoreVariantSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StoreVariantSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> variantId = const Value.absent(),
                Value<int?> priceOverride = const Value.absent(),
                Value<int?> reorderPointMilli = const Value.absent(),
                Value<int?> reorderQtyMilli = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoreVariantSettingsCompanion(
                variantId: variantId,
                priceOverride: priceOverride,
                reorderPointMilli: reorderPointMilli,
                reorderQtyMilli: reorderQtyMilli,
                isAvailable: isAvailable,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String variantId,
                Value<int?> priceOverride = const Value.absent(),
                Value<int?> reorderPointMilli = const Value.absent(),
                Value<int?> reorderQtyMilli = const Value.absent(),
                required bool isAvailable,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StoreVariantSettingsCompanion.insert(
                variantId: variantId,
                priceOverride: priceOverride,
                reorderPointMilli: reorderPointMilli,
                reorderQtyMilli: reorderQtyMilli,
                isAvailable: isAvailable,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $StoreVariantSettingsTable,
                    StoreVariantSettingRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StoreVariantSettingsTable,
                    StoreVariantSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoreVariantSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoreVariantSettingsTable,
      StoreVariantSettingRow,
      $$StoreVariantSettingsTableFilterComposer,
      $$StoreVariantSettingsTableOrderingComposer,
      $$StoreVariantSettingsTableAnnotationComposer,
      $$StoreVariantSettingsTableCreateCompanionBuilder,
      $$StoreVariantSettingsTableUpdateCompanionBuilder,
      (
        StoreVariantSettingRow,
        BaseReferences<
          _$AppDatabase,
          $StoreVariantSettingsTable,
          StoreVariantSettingRow
        >,
      ),
      StoreVariantSettingRow,
      PrefetchHooks Function()
    >;
typedef $$ModifierGroupsTableCreateCompanionBuilder =
    ModifierGroupsCompanion Function({
      required String id,
      required String name,
      required int minSelect,
      required int maxSelect,
      required int sortOrder,
      required bool isActive,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ModifierGroupsTableUpdateCompanionBuilder =
    ModifierGroupsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> minSelect,
      Value<int> maxSelect,
      Value<int> sortOrder,
      Value<bool> isActive,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ModifierGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ModifierGroupsTable> {
  $$ModifierGroupsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minSelect => $composableBuilder(
    column: $table.minSelect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxSelect => $composableBuilder(
    column: $table.maxSelect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ModifierGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ModifierGroupsTable> {
  $$ModifierGroupsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minSelect => $composableBuilder(
    column: $table.minSelect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxSelect => $composableBuilder(
    column: $table.maxSelect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModifierGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModifierGroupsTable> {
  $$ModifierGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get minSelect =>
      $composableBuilder(column: $table.minSelect, builder: (column) => column);

  GeneratedColumn<int> get maxSelect =>
      $composableBuilder(column: $table.maxSelect, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ModifierGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModifierGroupsTable,
          ModifierGroupRow,
          $$ModifierGroupsTableFilterComposer,
          $$ModifierGroupsTableOrderingComposer,
          $$ModifierGroupsTableAnnotationComposer,
          $$ModifierGroupsTableCreateCompanionBuilder,
          $$ModifierGroupsTableUpdateCompanionBuilder,
          (
            ModifierGroupRow,
            BaseReferences<
              _$AppDatabase,
              $ModifierGroupsTable,
              ModifierGroupRow
            >,
          ),
          ModifierGroupRow,
          PrefetchHooks Function()
        > {
  $$ModifierGroupsTableTableManager(
    _$AppDatabase db,
    $ModifierGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModifierGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModifierGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModifierGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> minSelect = const Value.absent(),
                Value<int> maxSelect = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModifierGroupsCompanion(
                id: id,
                name: name,
                minSelect: minSelect,
                maxSelect: maxSelect,
                sortOrder: sortOrder,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int minSelect,
                required int maxSelect,
                required int sortOrder,
                required bool isActive,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ModifierGroupsCompanion.insert(
                id: id,
                name: name,
                minSelect: minSelect,
                maxSelect: maxSelect,
                sortOrder: sortOrder,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ModifierGroupsTable, ModifierGroupRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ModifierGroupsTable,
                    ModifierGroupRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ModifierGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModifierGroupsTable,
      ModifierGroupRow,
      $$ModifierGroupsTableFilterComposer,
      $$ModifierGroupsTableOrderingComposer,
      $$ModifierGroupsTableAnnotationComposer,
      $$ModifierGroupsTableCreateCompanionBuilder,
      $$ModifierGroupsTableUpdateCompanionBuilder,
      (
        ModifierGroupRow,
        BaseReferences<_$AppDatabase, $ModifierGroupsTable, ModifierGroupRow>,
      ),
      ModifierGroupRow,
      PrefetchHooks Function()
    >;
typedef $$ModifiersTableCreateCompanionBuilder = ModifiersCompanion Function({
  required String id,
  required String groupId,
  required String name,
  required int priceDelta,
  required int sortOrder,
  required bool isActive,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ModifiersTableUpdateCompanionBuilder = ModifiersCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> name,
  Value<int> priceDelta,
  Value<int> sortOrder,
  Value<bool> isActive,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ModifiersTableFilterComposer
    extends Composer<_$AppDatabase, $ModifiersTable> {
  $$ModifiersTableFilterComposer({
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

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceDelta => $composableBuilder(
    column: $table.priceDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ModifiersTableOrderingComposer
    extends Composer<_$AppDatabase, $ModifiersTable> {
  $$ModifiersTableOrderingComposer({
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

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceDelta => $composableBuilder(
    column: $table.priceDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModifiersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModifiersTable> {
  $$ModifiersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get priceDelta => $composableBuilder(
    column: $table.priceDelta,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ModifiersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModifiersTable,
          ModifierRow,
          $$ModifiersTableFilterComposer,
          $$ModifiersTableOrderingComposer,
          $$ModifiersTableAnnotationComposer,
          $$ModifiersTableCreateCompanionBuilder,
          $$ModifiersTableUpdateCompanionBuilder,
          (
            ModifierRow,
            BaseReferences<_$AppDatabase, $ModifiersTable, ModifierRow>,
          ),
          ModifierRow,
          PrefetchHooks Function()
        > {
  $$ModifiersTableTableManager(_$AppDatabase db, $ModifiersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModifiersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModifiersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModifiersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> priceDelta = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModifiersCompanion(
                id: id,
                groupId: groupId,
                name: name,
                priceDelta: priceDelta,
                sortOrder: sortOrder,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String name,
                required int priceDelta,
                required int sortOrder,
                required bool isActive,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ModifiersCompanion.insert(
                id: id,
                groupId: groupId,
                name: name,
                priceDelta: priceDelta,
                sortOrder: sortOrder,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ModifiersTable, ModifierRow>(table),
                  BaseReferences<_$AppDatabase, $ModifiersTable, ModifierRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ModifiersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModifiersTable,
      ModifierRow,
      $$ModifiersTableFilterComposer,
      $$ModifiersTableOrderingComposer,
      $$ModifiersTableAnnotationComposer,
      $$ModifiersTableCreateCompanionBuilder,
      $$ModifiersTableUpdateCompanionBuilder,
      (
        ModifierRow,
        BaseReferences<_$AppDatabase, $ModifiersTable, ModifierRow>,
      ),
      ModifierRow,
      PrefetchHooks Function()
    >;
typedef $$ProductModifierGroupsTableCreateCompanionBuilder =
    ProductModifierGroupsCompanion Function({
      required String productId,
      required String groupId,
      required int sortOrder,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProductModifierGroupsTableUpdateCompanionBuilder =
    ProductModifierGroupsCompanion Function({
      Value<String> productId,
      Value<String> groupId,
      Value<int> sortOrder,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProductModifierGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductModifierGroupsTable> {
  $$ProductModifierGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductModifierGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductModifierGroupsTable> {
  $$ProductModifierGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductModifierGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductModifierGroupsTable> {
  $$ProductModifierGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductModifierGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductModifierGroupsTable,
          ProductModifierGroupRow,
          $$ProductModifierGroupsTableFilterComposer,
          $$ProductModifierGroupsTableOrderingComposer,
          $$ProductModifierGroupsTableAnnotationComposer,
          $$ProductModifierGroupsTableCreateCompanionBuilder,
          $$ProductModifierGroupsTableUpdateCompanionBuilder,
          (
            ProductModifierGroupRow,
            BaseReferences<
              _$AppDatabase,
              $ProductModifierGroupsTable,
              ProductModifierGroupRow
            >,
          ),
          ProductModifierGroupRow,
          PrefetchHooks Function()
        > {
  $$ProductModifierGroupsTableTableManager(
    _$AppDatabase db,
    $ProductModifierGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductModifierGroupsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProductModifierGroupsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProductModifierGroupsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductModifierGroupsCompanion(
                productId: productId,
                groupId: groupId,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                required String groupId,
                required int sortOrder,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductModifierGroupsCompanion.insert(
                productId: productId,
                groupId: groupId,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ProductModifierGroupsTable,
                    ProductModifierGroupRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProductModifierGroupsTable,
                    ProductModifierGroupRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductModifierGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductModifierGroupsTable,
      ProductModifierGroupRow,
      $$ProductModifierGroupsTableFilterComposer,
      $$ProductModifierGroupsTableOrderingComposer,
      $$ProductModifierGroupsTableAnnotationComposer,
      $$ProductModifierGroupsTableCreateCompanionBuilder,
      $$ProductModifierGroupsTableUpdateCompanionBuilder,
      (
        ProductModifierGroupRow,
        BaseReferences<
          _$AppDatabase,
          $ProductModifierGroupsTable,
          ProductModifierGroupRow
        >,
      ),
      ProductModifierGroupRow,
      PrefetchHooks Function()
    >;
typedef $$StoreFavoritesTableCreateCompanionBuilder =
    StoreFavoritesCompanion Function({
      required String productId,
      required int sortOrder,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StoreFavoritesTableUpdateCompanionBuilder =
    StoreFavoritesCompanion Function({
      Value<String> productId,
      Value<int> sortOrder,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StoreFavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $StoreFavoritesTable> {
  $$StoreFavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoreFavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoreFavoritesTable> {
  $$StoreFavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoreFavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoreFavoritesTable> {
  $$StoreFavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StoreFavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoreFavoritesTable,
          StoreFavoriteRow,
          $$StoreFavoritesTableFilterComposer,
          $$StoreFavoritesTableOrderingComposer,
          $$StoreFavoritesTableAnnotationComposer,
          $$StoreFavoritesTableCreateCompanionBuilder,
          $$StoreFavoritesTableUpdateCompanionBuilder,
          (
            StoreFavoriteRow,
            BaseReferences<
              _$AppDatabase,
              $StoreFavoritesTable,
              StoreFavoriteRow
            >,
          ),
          StoreFavoriteRow,
          PrefetchHooks Function()
        > {
  $$StoreFavoritesTableTableManager(
    _$AppDatabase db,
    $StoreFavoritesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoreFavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoreFavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoreFavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoreFavoritesCompanion(
                productId: productId,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                required int sortOrder,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StoreFavoritesCompanion.insert(
                productId: productId,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoreFavoritesTable, StoreFavoriteRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StoreFavoritesTable,
                    StoreFavoriteRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoreFavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoreFavoritesTable,
      StoreFavoriteRow,
      $$StoreFavoritesTableFilterComposer,
      $$StoreFavoritesTableOrderingComposer,
      $$StoreFavoritesTableAnnotationComposer,
      $$StoreFavoritesTableCreateCompanionBuilder,
      $$StoreFavoritesTableUpdateCompanionBuilder,
      (
        StoreFavoriteRow,
        BaseReferences<_$AppDatabase, $StoreFavoritesTable, StoreFavoriteRow>,
      ),
      StoreFavoriteRow,
      PrefetchHooks Function()
    >;
typedef $$StockLevelsTableCreateCompanionBuilder =
    StockLevelsCompanion Function({
      required String variantId,
      required int quantityMilli,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StockLevelsTableUpdateCompanionBuilder =
    StockLevelsCompanion Function({
      Value<String> variantId,
      Value<int> quantityMilli,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StockLevelsTableFilterComposer
    extends Composer<_$AppDatabase, $StockLevelsTable> {
  $$StockLevelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockLevelsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockLevelsTable> {
  $$StockLevelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockLevelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockLevelsTable> {
  $$StockLevelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StockLevelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockLevelsTable,
          StockLevelRow,
          $$StockLevelsTableFilterComposer,
          $$StockLevelsTableOrderingComposer,
          $$StockLevelsTableAnnotationComposer,
          $$StockLevelsTableCreateCompanionBuilder,
          $$StockLevelsTableUpdateCompanionBuilder,
          (
            StockLevelRow,
            BaseReferences<_$AppDatabase, $StockLevelsTable, StockLevelRow>,
          ),
          StockLevelRow,
          PrefetchHooks Function()
        > {
  $$StockLevelsTableTableManager(_$AppDatabase db, $StockLevelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockLevelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockLevelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockLevelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> variantId = const Value.absent(),
                Value<int> quantityMilli = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockLevelsCompanion(
                variantId: variantId,
                quantityMilli: quantityMilli,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String variantId,
                required int quantityMilli,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StockLevelsCompanion.insert(
                variantId: variantId,
                quantityMilli: quantityMilli,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StockLevelsTable, StockLevelRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StockLevelsTable,
                    StockLevelRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockLevelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockLevelsTable,
      StockLevelRow,
      $$StockLevelsTableFilterComposer,
      $$StockLevelsTableOrderingComposer,
      $$StockLevelsTableAnnotationComposer,
      $$StockLevelsTableCreateCompanionBuilder,
      $$StockLevelsTableUpdateCompanionBuilder,
      (
        StockLevelRow,
        BaseReferences<_$AppDatabase, $StockLevelsTable, StockLevelRow>,
      ),
      StockLevelRow,
      PrefetchHooks Function()
    >;
typedef $$MirrorRecordsTableCreateCompanionBuilder =
    MirrorRecordsCompanion Function({
      required String sourceTable,
      required String pk,
      required String data,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MirrorRecordsTableUpdateCompanionBuilder =
    MirrorRecordsCompanion Function({
      Value<String> sourceTable,
      Value<String> pk,
      Value<String> data,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MirrorRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $MirrorRecordsTable> {
  $$MirrorRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceTable => $composableBuilder(
    column: $table.sourceTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pk => $composableBuilder(
    column: $table.pk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MirrorRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $MirrorRecordsTable> {
  $$MirrorRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceTable => $composableBuilder(
    column: $table.sourceTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pk => $composableBuilder(
    column: $table.pk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MirrorRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MirrorRecordsTable> {
  $$MirrorRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceTable => $composableBuilder(
    column: $table.sourceTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pk =>
      $composableBuilder(column: $table.pk, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MirrorRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MirrorRecordsTable,
          MirrorRecordRow,
          $$MirrorRecordsTableFilterComposer,
          $$MirrorRecordsTableOrderingComposer,
          $$MirrorRecordsTableAnnotationComposer,
          $$MirrorRecordsTableCreateCompanionBuilder,
          $$MirrorRecordsTableUpdateCompanionBuilder,
          (
            MirrorRecordRow,
            BaseReferences<_$AppDatabase, $MirrorRecordsTable, MirrorRecordRow>,
          ),
          MirrorRecordRow,
          PrefetchHooks Function()
        > {
  $$MirrorRecordsTableTableManager(_$AppDatabase db, $MirrorRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MirrorRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MirrorRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MirrorRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sourceTable = const Value.absent(),
                Value<String> pk = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MirrorRecordsCompanion(
                sourceTable: sourceTable,
                pk: pk,
                data: data,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceTable,
                required String pk,
                required String data,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MirrorRecordsCompanion.insert(
                sourceTable: sourceTable,
                pk: pk,
                data: data,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MirrorRecordsTable, MirrorRecordRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MirrorRecordsTable,
                    MirrorRecordRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MirrorRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MirrorRecordsTable,
      MirrorRecordRow,
      $$MirrorRecordsTableFilterComposer,
      $$MirrorRecordsTableOrderingComposer,
      $$MirrorRecordsTableAnnotationComposer,
      $$MirrorRecordsTableCreateCompanionBuilder,
      $$MirrorRecordsTableUpdateCompanionBuilder,
      (
        MirrorRecordRow,
        BaseReferences<_$AppDatabase, $MirrorRecordsTable, MirrorRecordRow>,
      ),
      MirrorRecordRow,
      PrefetchHooks Function()
    >;
typedef $$LocalCustomersTableCreateCompanionBuilder =
    LocalCustomersCompanion Function({
      required String id,
      Value<String?> code,
      required String name,
      Value<String?> phone,
      Value<int> pointsBalance,
      Value<int?> kasbonLimit,
      required bool isActive,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalCustomersTableUpdateCompanionBuilder =
    LocalCustomersCompanion Function({
      Value<String> id,
      Value<String?> code,
      Value<String> name,
      Value<String?> phone,
      Value<int> pointsBalance,
      Value<int?> kasbonLimit,
      Value<bool> isActive,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalCustomersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointsBalance => $composableBuilder(
    column: $table.pointsBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kasbonLimit => $composableBuilder(
    column: $table.kasbonLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointsBalance => $composableBuilder(
    column: $table.pointsBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kasbonLimit => $composableBuilder(
    column: $table.kasbonLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<int> get pointsBalance => $composableBuilder(
    column: $table.pointsBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get kasbonLimit => $composableBuilder(
    column: $table.kasbonLimit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalCustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCustomersTable,
          CustomerRow,
          $$LocalCustomersTableFilterComposer,
          $$LocalCustomersTableOrderingComposer,
          $$LocalCustomersTableAnnotationComposer,
          $$LocalCustomersTableCreateCompanionBuilder,
          $$LocalCustomersTableUpdateCompanionBuilder,
          (
            CustomerRow,
            BaseReferences<_$AppDatabase, $LocalCustomersTable, CustomerRow>,
          ),
          CustomerRow,
          PrefetchHooks Function()
        > {
  $$LocalCustomersTableTableManager(
    _$AppDatabase db,
    $LocalCustomersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<int> pointsBalance = const Value.absent(),
                Value<int?> kasbonLimit = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCustomersCompanion(
                id: id,
                code: code,
                name: name,
                phone: phone,
                pointsBalance: pointsBalance,
                kasbonLimit: kasbonLimit,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> code = const Value.absent(),
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<int> pointsBalance = const Value.absent(),
                Value<int?> kasbonLimit = const Value.absent(),
                required bool isActive,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalCustomersCompanion.insert(
                id: id,
                code: code,
                name: name,
                phone: phone,
                pointsBalance: pointsBalance,
                kasbonLimit: kasbonLimit,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalCustomersTable, CustomerRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalCustomersTable,
                    CustomerRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCustomersTable,
      CustomerRow,
      $$LocalCustomersTableFilterComposer,
      $$LocalCustomersTableOrderingComposer,
      $$LocalCustomersTableAnnotationComposer,
      $$LocalCustomersTableCreateCompanionBuilder,
      $$LocalCustomersTableUpdateCompanionBuilder,
      (
        CustomerRow,
        BaseReferences<_$AppDatabase, $LocalCustomersTable, CustomerRow>,
      ),
      CustomerRow,
      PrefetchHooks Function()
    >;
typedef $$LocalShiftsTableCreateCompanionBuilder =
    LocalShiftsCompanion Function({
      required String id,
      required String storeId,
      required String openedBy,
      required String openedByName,
      required DateTime openedAt,
      required int openingCash,
      required String status,
      Value<DateTime?> closedAt,
      Value<String?> closedBy,
      Value<String?> closedByName,
      Value<int?> countedCash,
      Value<int?> expectedCash,
      Value<String?> closeNote,
      Value<int> rowid,
    });
typedef $$LocalShiftsTableUpdateCompanionBuilder =
    LocalShiftsCompanion Function({
      Value<String> id,
      Value<String> storeId,
      Value<String> openedBy,
      Value<String> openedByName,
      Value<DateTime> openedAt,
      Value<int> openingCash,
      Value<String> status,
      Value<DateTime?> closedAt,
      Value<String?> closedBy,
      Value<String?> closedByName,
      Value<int?> countedCash,
      Value<int?> expectedCash,
      Value<String?> closeNote,
      Value<int> rowid,
    });

class $$LocalShiftsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalShiftsTable> {
  $$LocalShiftsTableFilterComposer({
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

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openedBy => $composableBuilder(
    column: $table.openedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openedByName => $composableBuilder(
    column: $table.openedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingCash => $composableBuilder(
    column: $table.openingCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closedBy => $composableBuilder(
    column: $table.closedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closedByName => $composableBuilder(
    column: $table.closedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get countedCash => $composableBuilder(
    column: $table.countedCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closeNote => $composableBuilder(
    column: $table.closeNote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalShiftsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalShiftsTable> {
  $$LocalShiftsTableOrderingComposer({
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

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openedBy => $composableBuilder(
    column: $table.openedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openedByName => $composableBuilder(
    column: $table.openedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingCash => $composableBuilder(
    column: $table.openingCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closedBy => $composableBuilder(
    column: $table.closedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closedByName => $composableBuilder(
    column: $table.closedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get countedCash => $composableBuilder(
    column: $table.countedCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closeNote => $composableBuilder(
    column: $table.closeNote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalShiftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalShiftsTable> {
  $$LocalShiftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get openedBy =>
      $composableBuilder(column: $table.openedBy, builder: (column) => column);

  GeneratedColumn<String> get openedByName => $composableBuilder(
    column: $table.openedByName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<int> get openingCash => $composableBuilder(
    column: $table.openingCash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<String> get closedBy =>
      $composableBuilder(column: $table.closedBy, builder: (column) => column);

  GeneratedColumn<String> get closedByName => $composableBuilder(
    column: $table.closedByName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get countedCash => $composableBuilder(
    column: $table.countedCash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get closeNote =>
      $composableBuilder(column: $table.closeNote, builder: (column) => column);
}

class $$LocalShiftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalShiftsTable,
          ShiftRow,
          $$LocalShiftsTableFilterComposer,
          $$LocalShiftsTableOrderingComposer,
          $$LocalShiftsTableAnnotationComposer,
          $$LocalShiftsTableCreateCompanionBuilder,
          $$LocalShiftsTableUpdateCompanionBuilder,
          (
            ShiftRow,
            BaseReferences<_$AppDatabase, $LocalShiftsTable, ShiftRow>,
          ),
          ShiftRow,
          PrefetchHooks Function()
        > {
  $$LocalShiftsTableTableManager(_$AppDatabase db, $LocalShiftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalShiftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalShiftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalShiftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> openedBy = const Value.absent(),
                Value<String> openedByName = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<int> openingCash = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<String?> closedBy = const Value.absent(),
                Value<String?> closedByName = const Value.absent(),
                Value<int?> countedCash = const Value.absent(),
                Value<int?> expectedCash = const Value.absent(),
                Value<String?> closeNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShiftsCompanion(
                id: id,
                storeId: storeId,
                openedBy: openedBy,
                openedByName: openedByName,
                openedAt: openedAt,
                openingCash: openingCash,
                status: status,
                closedAt: closedAt,
                closedBy: closedBy,
                closedByName: closedByName,
                countedCash: countedCash,
                expectedCash: expectedCash,
                closeNote: closeNote,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storeId,
                required String openedBy,
                required String openedByName,
                required DateTime openedAt,
                required int openingCash,
                required String status,
                Value<DateTime?> closedAt = const Value.absent(),
                Value<String?> closedBy = const Value.absent(),
                Value<String?> closedByName = const Value.absent(),
                Value<int?> countedCash = const Value.absent(),
                Value<int?> expectedCash = const Value.absent(),
                Value<String?> closeNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShiftsCompanion.insert(
                id: id,
                storeId: storeId,
                openedBy: openedBy,
                openedByName: openedByName,
                openedAt: openedAt,
                openingCash: openingCash,
                status: status,
                closedAt: closedAt,
                closedBy: closedBy,
                closedByName: closedByName,
                countedCash: countedCash,
                expectedCash: expectedCash,
                closeNote: closeNote,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalShiftsTable, ShiftRow>(table),
                  BaseReferences<_$AppDatabase, $LocalShiftsTable, ShiftRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalShiftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalShiftsTable,
      ShiftRow,
      $$LocalShiftsTableFilterComposer,
      $$LocalShiftsTableOrderingComposer,
      $$LocalShiftsTableAnnotationComposer,
      $$LocalShiftsTableCreateCompanionBuilder,
      $$LocalShiftsTableUpdateCompanionBuilder,
      (ShiftRow, BaseReferences<_$AppDatabase, $LocalShiftsTable, ShiftRow>),
      ShiftRow,
      PrefetchHooks Function()
    >;
typedef $$LocalOrdersTableCreateCompanionBuilder =
    LocalOrdersCompanion Function({
      required String id,
      required String orderNumber,
      required String status,
      required int version,
      required String cartJson,
      required String payloadJson,
      required int grandTotal,
      required int itemCount,
      Value<String?> customerName,
      required String cashierName,
      Value<String?> shiftId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> printedAt,
      Value<DateTime?> voidedAt,
      Value<String?> voidReason,
      Value<String?> voidedByName,
      Value<String?> voidedShiftId,
      Value<int> rowid,
    });
typedef $$LocalOrdersTableUpdateCompanionBuilder =
    LocalOrdersCompanion Function({
      Value<String> id,
      Value<String> orderNumber,
      Value<String> status,
      Value<int> version,
      Value<String> cartJson,
      Value<String> payloadJson,
      Value<int> grandTotal,
      Value<int> itemCount,
      Value<String?> customerName,
      Value<String> cashierName,
      Value<String?> shiftId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> printedAt,
      Value<DateTime?> voidedAt,
      Value<String?> voidReason,
      Value<String?> voidedByName,
      Value<String?> voidedShiftId,
      Value<int> rowid,
    });

class $$LocalOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableFilterComposer({
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

  ColumnFilters<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cartJson => $composableBuilder(
    column: $table.cartJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get printedAt => $composableBuilder(
    column: $table.printedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidedByName => $composableBuilder(
    column: $table.voidedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidedShiftId => $composableBuilder(
    column: $table.voidedShiftId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableOrderingComposer({
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

  ColumnOrderings<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cartJson => $composableBuilder(
    column: $table.cartJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get printedAt => $composableBuilder(
    column: $table.printedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidedByName => $composableBuilder(
    column: $table.voidedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidedShiftId => $composableBuilder(
    column: $table.voidedShiftId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get cartJson =>
      $composableBuilder(column: $table.cartJson, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get printedAt =>
      $composableBuilder(column: $table.printedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);

  GeneratedColumn<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voidedByName => $composableBuilder(
    column: $table.voidedByName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voidedShiftId => $composableBuilder(
    column: $table.voidedShiftId,
    builder: (column) => column,
  );
}

class $$LocalOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalOrdersTable,
          LocalOrderRow,
          $$LocalOrdersTableFilterComposer,
          $$LocalOrdersTableOrderingComposer,
          $$LocalOrdersTableAnnotationComposer,
          $$LocalOrdersTableCreateCompanionBuilder,
          $$LocalOrdersTableUpdateCompanionBuilder,
          (
            LocalOrderRow,
            BaseReferences<_$AppDatabase, $LocalOrdersTable, LocalOrderRow>,
          ),
          LocalOrderRow,
          PrefetchHooks Function()
        > {
  $$LocalOrdersTableTableManager(_$AppDatabase db, $LocalOrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderNumber = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> cartJson = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> grandTotal = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String> cashierName = const Value.absent(),
                Value<String?> shiftId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> printedAt = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<String?> voidedByName = const Value.absent(),
                Value<String?> voidedShiftId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdersCompanion(
                id: id,
                orderNumber: orderNumber,
                status: status,
                version: version,
                cartJson: cartJson,
                payloadJson: payloadJson,
                grandTotal: grandTotal,
                itemCount: itemCount,
                customerName: customerName,
                cashierName: cashierName,
                shiftId: shiftId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                printedAt: printedAt,
                voidedAt: voidedAt,
                voidReason: voidReason,
                voidedByName: voidedByName,
                voidedShiftId: voidedShiftId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderNumber,
                required String status,
                required int version,
                required String cartJson,
                required String payloadJson,
                required int grandTotal,
                required int itemCount,
                Value<String?> customerName = const Value.absent(),
                required String cashierName,
                Value<String?> shiftId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> printedAt = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<String?> voidedByName = const Value.absent(),
                Value<String?> voidedShiftId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdersCompanion.insert(
                id: id,
                orderNumber: orderNumber,
                status: status,
                version: version,
                cartJson: cartJson,
                payloadJson: payloadJson,
                grandTotal: grandTotal,
                itemCount: itemCount,
                customerName: customerName,
                cashierName: cashierName,
                shiftId: shiftId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                printedAt: printedAt,
                voidedAt: voidedAt,
                voidReason: voidReason,
                voidedByName: voidedByName,
                voidedShiftId: voidedShiftId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalOrdersTable, LocalOrderRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalOrdersTable,
                    LocalOrderRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalOrdersTable,
      LocalOrderRow,
      $$LocalOrdersTableFilterComposer,
      $$LocalOrdersTableOrderingComposer,
      $$LocalOrdersTableAnnotationComposer,
      $$LocalOrdersTableCreateCompanionBuilder,
      $$LocalOrdersTableUpdateCompanionBuilder,
      (
        LocalOrderRow,
        BaseReferences<_$AppDatabase, $LocalOrdersTable, LocalOrderRow>,
      ),
      LocalOrderRow,
      PrefetchHooks Function()
    >;
typedef $$LocalCountersTableCreateCompanionBuilder =
    LocalCountersCompanion Function({
      required String name,
      required int value,
      Value<int> rowid,
    });
typedef $$LocalCountersTableUpdateCompanionBuilder =
    LocalCountersCompanion Function({
      Value<String> name,
      Value<int> value,
      Value<int> rowid,
    });

class $$LocalCountersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCountersTable> {
  $$LocalCountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCountersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCountersTable> {
  $$LocalCountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCountersTable> {
  $$LocalCountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalCountersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCountersTable,
          CounterRow,
          $$LocalCountersTableFilterComposer,
          $$LocalCountersTableOrderingComposer,
          $$LocalCountersTableAnnotationComposer,
          $$LocalCountersTableCreateCompanionBuilder,
          $$LocalCountersTableUpdateCompanionBuilder,
          (
            CounterRow,
            BaseReferences<_$AppDatabase, $LocalCountersTable, CounterRow>,
          ),
          CounterRow,
          PrefetchHooks Function()
        > {
  $$LocalCountersTableTableManager(_$AppDatabase db, $LocalCountersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCountersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<int> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalCountersCompanion(name: name, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                required int value,
                Value<int> rowid = const Value.absent(),
              }) => LocalCountersCompanion.insert(
                name: name,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalCountersTable, CounterRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalCountersTable,
                    CounterRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCountersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCountersTable,
      CounterRow,
      $$LocalCountersTableFilterComposer,
      $$LocalCountersTableOrderingComposer,
      $$LocalCountersTableAnnotationComposer,
      $$LocalCountersTableCreateCompanionBuilder,
      $$LocalCountersTableUpdateCompanionBuilder,
      (
        CounterRow,
        BaseReferences<_$AppDatabase, $LocalCountersTable, CounterRow>,
      ),
      CounterRow,
      PrefetchHooks Function()
    >;
typedef $$LocalCashMovementsTableCreateCompanionBuilder =
    LocalCashMovementsCompanion Function({
      required String id,
      required String shiftId,
      required String movementType,
      required int amount,
      required String reason,
      required String employeeName,
      required DateTime occurredAt,
      Value<int> rowid,
    });
typedef $$LocalCashMovementsTableUpdateCompanionBuilder =
    LocalCashMovementsCompanion Function({
      Value<String> id,
      Value<String> shiftId,
      Value<String> movementType,
      Value<int> amount,
      Value<String> reason,
      Value<String> employeeName,
      Value<DateTime> occurredAt,
      Value<int> rowid,
    });

class $$LocalCashMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCashMovementsTable> {
  $$LocalCashMovementsTableFilterComposer({
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

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCashMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCashMovementsTable> {
  $$LocalCashMovementsTableOrderingComposer({
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

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCashMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCashMovementsTable> {
  $$LocalCashMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );
}

class $$LocalCashMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCashMovementsTable,
          CashMovementRow,
          $$LocalCashMovementsTableFilterComposer,
          $$LocalCashMovementsTableOrderingComposer,
          $$LocalCashMovementsTableAnnotationComposer,
          $$LocalCashMovementsTableCreateCompanionBuilder,
          $$LocalCashMovementsTableUpdateCompanionBuilder,
          (
            CashMovementRow,
            BaseReferences<
              _$AppDatabase,
              $LocalCashMovementsTable,
              CashMovementRow
            >,
          ),
          CashMovementRow,
          PrefetchHooks Function()
        > {
  $$LocalCashMovementsTableTableManager(
    _$AppDatabase db,
    $LocalCashMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCashMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCashMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCashMovementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<String> movementType = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> employeeName = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCashMovementsCompanion(
                id: id,
                shiftId: shiftId,
                movementType: movementType,
                amount: amount,
                reason: reason,
                employeeName: employeeName,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shiftId,
                required String movementType,
                required int amount,
                required String reason,
                required String employeeName,
                required DateTime occurredAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalCashMovementsCompanion.insert(
                id: id,
                shiftId: shiftId,
                movementType: movementType,
                amount: amount,
                reason: reason,
                employeeName: employeeName,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalCashMovementsTable, CashMovementRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalCashMovementsTable,
                    CashMovementRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCashMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCashMovementsTable,
      CashMovementRow,
      $$LocalCashMovementsTableFilterComposer,
      $$LocalCashMovementsTableOrderingComposer,
      $$LocalCashMovementsTableAnnotationComposer,
      $$LocalCashMovementsTableCreateCompanionBuilder,
      $$LocalCashMovementsTableUpdateCompanionBuilder,
      (
        CashMovementRow,
        BaseReferences<
          _$AppDatabase,
          $LocalCashMovementsTable,
          CashMovementRow
        >,
      ),
      CashMovementRow,
      PrefetchHooks Function()
    >;
typedef $$LocalRefundsTableCreateCompanionBuilder =
    LocalRefundsCompanion Function({
      required String id,
      required String orderId,
      Value<String?> shiftId,
      required String refundNumber,
      required int amount,
      required String methodType,
      required bool restock,
      required String reason,
      required String itemsJson,
      required String employeeName,
      required String approvedByName,
      required DateTime refundedAt,
      Value<int> rowid,
    });
typedef $$LocalRefundsTableUpdateCompanionBuilder =
    LocalRefundsCompanion Function({
      Value<String> id,
      Value<String> orderId,
      Value<String?> shiftId,
      Value<String> refundNumber,
      Value<int> amount,
      Value<String> methodType,
      Value<bool> restock,
      Value<String> reason,
      Value<String> itemsJson,
      Value<String> employeeName,
      Value<String> approvedByName,
      Value<DateTime> refundedAt,
      Value<int> rowid,
    });

class $$LocalRefundsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalRefundsTable> {
  $$LocalRefundsTableFilterComposer({
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

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refundNumber => $composableBuilder(
    column: $table.refundNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get methodType => $composableBuilder(
    column: $table.methodType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get restock => $composableBuilder(
    column: $table.restock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedByName => $composableBuilder(
    column: $table.approvedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get refundedAt => $composableBuilder(
    column: $table.refundedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalRefundsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalRefundsTable> {
  $$LocalRefundsTableOrderingComposer({
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

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refundNumber => $composableBuilder(
    column: $table.refundNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methodType => $composableBuilder(
    column: $table.methodType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get restock => $composableBuilder(
    column: $table.restock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedByName => $composableBuilder(
    column: $table.approvedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get refundedAt => $composableBuilder(
    column: $table.refundedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalRefundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalRefundsTable> {
  $$LocalRefundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<String> get refundNumber => $composableBuilder(
    column: $table.refundNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get methodType => $composableBuilder(
    column: $table.methodType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get restock =>
      $composableBuilder(column: $table.restock, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvedByName => $composableBuilder(
    column: $table.approvedByName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get refundedAt => $composableBuilder(
    column: $table.refundedAt,
    builder: (column) => column,
  );
}

class $$LocalRefundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalRefundsTable,
          RefundRow,
          $$LocalRefundsTableFilterComposer,
          $$LocalRefundsTableOrderingComposer,
          $$LocalRefundsTableAnnotationComposer,
          $$LocalRefundsTableCreateCompanionBuilder,
          $$LocalRefundsTableUpdateCompanionBuilder,
          (
            RefundRow,
            BaseReferences<_$AppDatabase, $LocalRefundsTable, RefundRow>,
          ),
          RefundRow,
          PrefetchHooks Function()
        > {
  $$LocalRefundsTableTableManager(_$AppDatabase db, $LocalRefundsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRefundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalRefundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalRefundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String?> shiftId = const Value.absent(),
                Value<String> refundNumber = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> methodType = const Value.absent(),
                Value<bool> restock = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<String> employeeName = const Value.absent(),
                Value<String> approvedByName = const Value.absent(),
                Value<DateTime> refundedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRefundsCompanion(
                id: id,
                orderId: orderId,
                shiftId: shiftId,
                refundNumber: refundNumber,
                amount: amount,
                methodType: methodType,
                restock: restock,
                reason: reason,
                itemsJson: itemsJson,
                employeeName: employeeName,
                approvedByName: approvedByName,
                refundedAt: refundedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderId,
                Value<String?> shiftId = const Value.absent(),
                required String refundNumber,
                required int amount,
                required String methodType,
                required bool restock,
                required String reason,
                required String itemsJson,
                required String employeeName,
                required String approvedByName,
                required DateTime refundedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalRefundsCompanion.insert(
                id: id,
                orderId: orderId,
                shiftId: shiftId,
                refundNumber: refundNumber,
                amount: amount,
                methodType: methodType,
                restock: restock,
                reason: reason,
                itemsJson: itemsJson,
                employeeName: employeeName,
                approvedByName: approvedByName,
                refundedAt: refundedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalRefundsTable, RefundRow>(table),
                  BaseReferences<_$AppDatabase, $LocalRefundsTable, RefundRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalRefundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalRefundsTable,
      RefundRow,
      $$LocalRefundsTableFilterComposer,
      $$LocalRefundsTableOrderingComposer,
      $$LocalRefundsTableAnnotationComposer,
      $$LocalRefundsTableCreateCompanionBuilder,
      $$LocalRefundsTableUpdateCompanionBuilder,
      (RefundRow, BaseReferences<_$AppDatabase, $LocalRefundsTable, RefundRow>),
      RefundRow,
      PrefetchHooks Function()
    >;
typedef $$LocalPrintersTableCreateCompanionBuilder =
    LocalPrintersCompanion Function({
      required String id,
      required String name,
      required String connection,
      required String address,
      required int paperMm,
      required bool opensCashDrawer,
      required bool autoPrint,
      Value<int> rowid,
    });
typedef $$LocalPrintersTableUpdateCompanionBuilder =
    LocalPrintersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> connection,
      Value<String> address,
      Value<int> paperMm,
      Value<bool> opensCashDrawer,
      Value<bool> autoPrint,
      Value<int> rowid,
    });

class $$LocalPrintersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPrintersTable> {
  $$LocalPrintersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get connection => $composableBuilder(
    column: $table.connection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paperMm => $composableBuilder(
    column: $table.paperMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get opensCashDrawer => $composableBuilder(
    column: $table.opensCashDrawer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoPrint => $composableBuilder(
    column: $table.autoPrint,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPrintersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPrintersTable> {
  $$LocalPrintersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get connection => $composableBuilder(
    column: $table.connection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paperMm => $composableBuilder(
    column: $table.paperMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get opensCashDrawer => $composableBuilder(
    column: $table.opensCashDrawer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoPrint => $composableBuilder(
    column: $table.autoPrint,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPrintersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPrintersTable> {
  $$LocalPrintersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get connection => $composableBuilder(
    column: $table.connection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get paperMm =>
      $composableBuilder(column: $table.paperMm, builder: (column) => column);

  GeneratedColumn<bool> get opensCashDrawer => $composableBuilder(
    column: $table.opensCashDrawer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoPrint =>
      $composableBuilder(column: $table.autoPrint, builder: (column) => column);
}

class $$LocalPrintersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPrintersTable,
          PrinterRow,
          $$LocalPrintersTableFilterComposer,
          $$LocalPrintersTableOrderingComposer,
          $$LocalPrintersTableAnnotationComposer,
          $$LocalPrintersTableCreateCompanionBuilder,
          $$LocalPrintersTableUpdateCompanionBuilder,
          (
            PrinterRow,
            BaseReferences<_$AppDatabase, $LocalPrintersTable, PrinterRow>,
          ),
          PrinterRow,
          PrefetchHooks Function()
        > {
  $$LocalPrintersTableTableManager(_$AppDatabase db, $LocalPrintersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPrintersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPrintersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPrintersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> connection = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<int> paperMm = const Value.absent(),
                Value<bool> opensCashDrawer = const Value.absent(),
                Value<bool> autoPrint = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPrintersCompanion(
                id: id,
                name: name,
                connection: connection,
                address: address,
                paperMm: paperMm,
                opensCashDrawer: opensCashDrawer,
                autoPrint: autoPrint,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String connection,
                required String address,
                required int paperMm,
                required bool opensCashDrawer,
                required bool autoPrint,
                Value<int> rowid = const Value.absent(),
              }) => LocalPrintersCompanion.insert(
                id: id,
                name: name,
                connection: connection,
                address: address,
                paperMm: paperMm,
                opensCashDrawer: opensCashDrawer,
                autoPrint: autoPrint,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalPrintersTable, PrinterRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalPrintersTable,
                    PrinterRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPrintersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPrintersTable,
      PrinterRow,
      $$LocalPrintersTableFilterComposer,
      $$LocalPrintersTableOrderingComposer,
      $$LocalPrintersTableAnnotationComposer,
      $$LocalPrintersTableCreateCompanionBuilder,
      $$LocalPrintersTableUpdateCompanionBuilder,
      (
        PrinterRow,
        BaseReferences<_$AppDatabase, $LocalPrintersTable, PrinterRow>,
      ),
      PrinterRow,
      PrefetchHooks Function()
    >;
typedef $$LocalReceivablesTableCreateCompanionBuilder =
    LocalReceivablesCompanion Function({
      required String orderId,
      Value<String?> receivableId,
      required String customerId,
      required int amount,
      required int paidAmount,
      required DateTime dueDate,
      required String status,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalReceivablesTableUpdateCompanionBuilder =
    LocalReceivablesCompanion Function({
      Value<String> orderId,
      Value<String?> receivableId,
      Value<String> customerId,
      Value<int> amount,
      Value<int> paidAmount,
      Value<DateTime> dueDate,
      Value<String> status,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalReceivablesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalReceivablesTable> {
  $$LocalReceivablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receivableId => $composableBuilder(
    column: $table.receivableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalReceivablesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalReceivablesTable> {
  $$LocalReceivablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receivableId => $composableBuilder(
    column: $table.receivableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalReceivablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalReceivablesTable> {
  $$LocalReceivablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get receivableId => $composableBuilder(
    column: $table.receivableId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalReceivablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalReceivablesTable,
          ReceivableRow,
          $$LocalReceivablesTableFilterComposer,
          $$LocalReceivablesTableOrderingComposer,
          $$LocalReceivablesTableAnnotationComposer,
          $$LocalReceivablesTableCreateCompanionBuilder,
          $$LocalReceivablesTableUpdateCompanionBuilder,
          (
            ReceivableRow,
            BaseReferences<
              _$AppDatabase,
              $LocalReceivablesTable,
              ReceivableRow
            >,
          ),
          ReceivableRow,
          PrefetchHooks Function()
        > {
  $$LocalReceivablesTableTableManager(
    _$AppDatabase db,
    $LocalReceivablesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalReceivablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalReceivablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalReceivablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> orderId = const Value.absent(),
                Value<String?> receivableId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> paidAmount = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalReceivablesCompanion(
                orderId: orderId,
                receivableId: receivableId,
                customerId: customerId,
                amount: amount,
                paidAmount: paidAmount,
                dueDate: dueDate,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String orderId,
                Value<String?> receivableId = const Value.absent(),
                required String customerId,
                required int amount,
                required int paidAmount,
                required DateTime dueDate,
                required String status,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalReceivablesCompanion.insert(
                orderId: orderId,
                receivableId: receivableId,
                customerId: customerId,
                amount: amount,
                paidAmount: paidAmount,
                dueDate: dueDate,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalReceivablesTable, ReceivableRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalReceivablesTable,
                    ReceivableRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalReceivablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalReceivablesTable,
      ReceivableRow,
      $$LocalReceivablesTableFilterComposer,
      $$LocalReceivablesTableOrderingComposer,
      $$LocalReceivablesTableAnnotationComposer,
      $$LocalReceivablesTableCreateCompanionBuilder,
      $$LocalReceivablesTableUpdateCompanionBuilder,
      (
        ReceivableRow,
        BaseReferences<_$AppDatabase, $LocalReceivablesTable, ReceivableRow>,
      ),
      ReceivableRow,
      PrefetchHooks Function()
    >;
typedef $$LocalReceivablePaymentsTableCreateCompanionBuilder =
    LocalReceivablePaymentsCompanion Function({
      required String id,
      required String orderId,
      required String customerId,
      Value<String?> shiftId,
      required int amount,
      required String methodType,
      Value<String?> reference,
      required String employeeName,
      required DateTime paidAt,
      Value<int> rowid,
    });
typedef $$LocalReceivablePaymentsTableUpdateCompanionBuilder =
    LocalReceivablePaymentsCompanion Function({
      Value<String> id,
      Value<String> orderId,
      Value<String> customerId,
      Value<String?> shiftId,
      Value<int> amount,
      Value<String> methodType,
      Value<String?> reference,
      Value<String> employeeName,
      Value<DateTime> paidAt,
      Value<int> rowid,
    });

class $$LocalReceivablePaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalReceivablePaymentsTable> {
  $$LocalReceivablePaymentsTableFilterComposer({
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

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get methodType => $composableBuilder(
    column: $table.methodType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalReceivablePaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalReceivablePaymentsTable> {
  $$LocalReceivablePaymentsTableOrderingComposer({
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

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methodType => $composableBuilder(
    column: $table.methodType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalReceivablePaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalReceivablePaymentsTable> {
  $$LocalReceivablePaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get methodType => $composableBuilder(
    column: $table.methodType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);
}

class $$LocalReceivablePaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalReceivablePaymentsTable,
          ReceivablePaymentRow,
          $$LocalReceivablePaymentsTableFilterComposer,
          $$LocalReceivablePaymentsTableOrderingComposer,
          $$LocalReceivablePaymentsTableAnnotationComposer,
          $$LocalReceivablePaymentsTableCreateCompanionBuilder,
          $$LocalReceivablePaymentsTableUpdateCompanionBuilder,
          (
            ReceivablePaymentRow,
            BaseReferences<
              _$AppDatabase,
              $LocalReceivablePaymentsTable,
              ReceivablePaymentRow
            >,
          ),
          ReceivablePaymentRow,
          PrefetchHooks Function()
        > {
  $$LocalReceivablePaymentsTableTableManager(
    _$AppDatabase db,
    $LocalReceivablePaymentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalReceivablePaymentsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalReceivablePaymentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalReceivablePaymentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String?> shiftId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> methodType = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String> employeeName = const Value.absent(),
                Value<DateTime> paidAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalReceivablePaymentsCompanion(
                id: id,
                orderId: orderId,
                customerId: customerId,
                shiftId: shiftId,
                amount: amount,
                methodType: methodType,
                reference: reference,
                employeeName: employeeName,
                paidAt: paidAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderId,
                required String customerId,
                Value<String?> shiftId = const Value.absent(),
                required int amount,
                required String methodType,
                Value<String?> reference = const Value.absent(),
                required String employeeName,
                required DateTime paidAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalReceivablePaymentsCompanion.insert(
                id: id,
                orderId: orderId,
                customerId: customerId,
                shiftId: shiftId,
                amount: amount,
                methodType: methodType,
                reference: reference,
                employeeName: employeeName,
                paidAt: paidAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalReceivablePaymentsTable,
                    ReceivablePaymentRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalReceivablePaymentsTable,
                    ReceivablePaymentRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalReceivablePaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalReceivablePaymentsTable,
      ReceivablePaymentRow,
      $$LocalReceivablePaymentsTableFilterComposer,
      $$LocalReceivablePaymentsTableOrderingComposer,
      $$LocalReceivablePaymentsTableAnnotationComposer,
      $$LocalReceivablePaymentsTableCreateCompanionBuilder,
      $$LocalReceivablePaymentsTableUpdateCompanionBuilder,
      (
        ReceivablePaymentRow,
        BaseReferences<
          _$AppDatabase,
          $LocalReceivablePaymentsTable,
          ReceivablePaymentRow
        >,
      ),
      ReceivablePaymentRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$LocalDeviceTableTableManager get localDevice =>
      $$LocalDeviceTableTableManager(_db, _db.localDevice);
  $$LocalStoresTableTableManager get localStores =>
      $$LocalStoresTableTableManager(_db, _db.localStores);
  $$LocalStoreSettingsTableTableManager get localStoreSettings =>
      $$LocalStoreSettingsTableTableManager(_db, _db.localStoreSettings);
  $$LocalStaffTableTableManager get localStaff =>
      $$LocalStaffTableTableManager(_db, _db.localStaff);
  $$PinAttemptsTableTableManager get pinAttempts =>
      $$PinAttemptsTableTableManager(_db, _db.pinAttempts);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db, _db.units);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$ProductVariantsTableTableManager get productVariants =>
      $$ProductVariantsTableTableManager(_db, _db.productVariants);
  $$StoreVariantSettingsTableTableManager get storeVariantSettings =>
      $$StoreVariantSettingsTableTableManager(_db, _db.storeVariantSettings);
  $$ModifierGroupsTableTableManager get modifierGroups =>
      $$ModifierGroupsTableTableManager(_db, _db.modifierGroups);
  $$ModifiersTableTableManager get modifiers =>
      $$ModifiersTableTableManager(_db, _db.modifiers);
  $$ProductModifierGroupsTableTableManager get productModifierGroups =>
      $$ProductModifierGroupsTableTableManager(_db, _db.productModifierGroups);
  $$StoreFavoritesTableTableManager get storeFavorites =>
      $$StoreFavoritesTableTableManager(_db, _db.storeFavorites);
  $$StockLevelsTableTableManager get stockLevels =>
      $$StockLevelsTableTableManager(_db, _db.stockLevels);
  $$MirrorRecordsTableTableManager get mirrorRecords =>
      $$MirrorRecordsTableTableManager(_db, _db.mirrorRecords);
  $$LocalCustomersTableTableManager get localCustomers =>
      $$LocalCustomersTableTableManager(_db, _db.localCustomers);
  $$LocalShiftsTableTableManager get localShifts =>
      $$LocalShiftsTableTableManager(_db, _db.localShifts);
  $$LocalOrdersTableTableManager get localOrders =>
      $$LocalOrdersTableTableManager(_db, _db.localOrders);
  $$LocalCountersTableTableManager get localCounters =>
      $$LocalCountersTableTableManager(_db, _db.localCounters);
  $$LocalCashMovementsTableTableManager get localCashMovements =>
      $$LocalCashMovementsTableTableManager(_db, _db.localCashMovements);
  $$LocalRefundsTableTableManager get localRefunds =>
      $$LocalRefundsTableTableManager(_db, _db.localRefunds);
  $$LocalPrintersTableTableManager get localPrinters =>
      $$LocalPrintersTableTableManager(_db, _db.localPrinters);
  $$LocalReceivablesTableTableManager get localReceivables =>
      $$LocalReceivablesTableTableManager(_db, _db.localReceivables);
  $$LocalReceivablePaymentsTableTableManager get localReceivablePayments =>
      $$LocalReceivablePaymentsTableTableManager(
        _db,
        _db.localReceivablePayments,
      );
}
