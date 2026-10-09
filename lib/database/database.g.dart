// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MataKuliahTableTable extends MataKuliahTable
    with TableInfo<$MataKuliahTableTable, MataKuliahData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MataKuliahTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _namaMeta = const VerificationMeta('nama');
  @override
  late final GeneratedColumn<String> nama = GeneratedColumn<String>(
    'nama',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dosenMeta = const VerificationMeta('dosen');
  @override
  late final GeneratedColumn<String> dosen = GeneratedColumn<String>(
    'dosen',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sksMeta = const VerificationMeta('sks');
  @override
  late final GeneratedColumn<int> sks = GeneratedColumn<int>(
    'sks',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nama, dosen, sks];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mata_kuliah';
  @override
  VerificationContext validateIntegrity(
    Insertable<MataKuliahData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nama')) {
      context.handle(
        _namaMeta,
        nama.isAcceptableOrUnknown(data['nama']!, _namaMeta),
      );
    } else if (isInserting) {
      context.missing(_namaMeta);
    }
    if (data.containsKey('dosen')) {
      context.handle(
        _dosenMeta,
        dosen.isAcceptableOrUnknown(data['dosen']!, _dosenMeta),
      );
    }
    if (data.containsKey('sks')) {
      context.handle(
        _sksMeta,
        sks.isAcceptableOrUnknown(data['sks']!, _sksMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MataKuliahData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MataKuliahData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nama: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama'],
      )!,
      dosen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dosen'],
      ),
      sks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sks'],
      ),
    );
  }

  @override
  $MataKuliahTableTable createAlias(String alias) {
    return $MataKuliahTableTable(attachedDatabase, alias);
  }
}

class MataKuliahData extends DataClass implements Insertable<MataKuliahData> {
  final int id;
  final String nama;
  final String? dosen;
  final int? sks;
  const MataKuliahData({
    required this.id,
    required this.nama,
    this.dosen,
    this.sks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nama'] = Variable<String>(nama);
    if (!nullToAbsent || dosen != null) {
      map['dosen'] = Variable<String>(dosen);
    }
    if (!nullToAbsent || sks != null) {
      map['sks'] = Variable<int>(sks);
    }
    return map;
  }

  MataKuliahTableCompanion toCompanion(bool nullToAbsent) {
    return MataKuliahTableCompanion(
      id: Value(id),
      nama: Value(nama),
      dosen: dosen == null && nullToAbsent
          ? const Value.absent()
          : Value(dosen),
      sks: sks == null && nullToAbsent ? const Value.absent() : Value(sks),
    );
  }

  factory MataKuliahData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MataKuliahData(
      id: serializer.fromJson<int>(json['id']),
      nama: serializer.fromJson<String>(json['nama']),
      dosen: serializer.fromJson<String?>(json['dosen']),
      sks: serializer.fromJson<int?>(json['sks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nama': serializer.toJson<String>(nama),
      'dosen': serializer.toJson<String?>(dosen),
      'sks': serializer.toJson<int?>(sks),
    };
  }

  MataKuliahData copyWith({
    int? id,
    String? nama,
    Value<String?> dosen = const Value.absent(),
    Value<int?> sks = const Value.absent(),
  }) => MataKuliahData(
    id: id ?? this.id,
    nama: nama ?? this.nama,
    dosen: dosen.present ? dosen.value : this.dosen,
    sks: sks.present ? sks.value : this.sks,
  );
  MataKuliahData copyWithCompanion(MataKuliahTableCompanion data) {
    return MataKuliahData(
      id: data.id.present ? data.id.value : this.id,
      nama: data.nama.present ? data.nama.value : this.nama,
      dosen: data.dosen.present ? data.dosen.value : this.dosen,
      sks: data.sks.present ? data.sks.value : this.sks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MataKuliahData(')
          ..write('id: $id, ')
          ..write('nama: $nama, ')
          ..write('dosen: $dosen, ')
          ..write('sks: $sks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nama, dosen, sks);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MataKuliahData &&
          other.id == this.id &&
          other.nama == this.nama &&
          other.dosen == this.dosen &&
          other.sks == this.sks);
}

class MataKuliahTableCompanion extends UpdateCompanion<MataKuliahData> {
  final Value<int> id;
  final Value<String> nama;
  final Value<String?> dosen;
  final Value<int?> sks;
  const MataKuliahTableCompanion({
    this.id = const Value.absent(),
    this.nama = const Value.absent(),
    this.dosen = const Value.absent(),
    this.sks = const Value.absent(),
  });
  MataKuliahTableCompanion.insert({
    this.id = const Value.absent(),
    required String nama,
    this.dosen = const Value.absent(),
    this.sks = const Value.absent(),
  }) : nama = Value(nama);
  static Insertable<MataKuliahData> custom({
    Expression<int>? id,
    Expression<String>? nama,
    Expression<String>? dosen,
    Expression<int>? sks,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nama != null) 'nama': nama,
      if (dosen != null) 'dosen': dosen,
      if (sks != null) 'sks': sks,
    });
  }

  MataKuliahTableCompanion copyWith({
    Value<int>? id,
    Value<String>? nama,
    Value<String?>? dosen,
    Value<int?>? sks,
  }) {
    return MataKuliahTableCompanion(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      dosen: dosen ?? this.dosen,
      sks: sks ?? this.sks,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nama.present) {
      map['nama'] = Variable<String>(nama.value);
    }
    if (dosen.present) {
      map['dosen'] = Variable<String>(dosen.value);
    }
    if (sks.present) {
      map['sks'] = Variable<int>(sks.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MataKuliahTableCompanion(')
          ..write('id: $id, ')
          ..write('nama: $nama, ')
          ..write('dosen: $dosen, ')
          ..write('sks: $sks')
          ..write(')'))
        .toString();
  }
}

class $JadwalKuliahTableTable extends JadwalKuliahTable
    with TableInfo<$JadwalKuliahTableTable, JadwalKuliahData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JadwalKuliahTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _mataKuliahIdMeta = const VerificationMeta(
    'mataKuliahId',
  );
  @override
  late final GeneratedColumn<int> mataKuliahId = GeneratedColumn<int>(
    'mata_kuliah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES mata_kuliah (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _hariMeta = const VerificationMeta('hari');
  @override
  late final GeneratedColumn<int> hari = GeneratedColumn<int>(
    'hari',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jamMulaiMeta = const VerificationMeta(
    'jamMulai',
  );
  @override
  late final GeneratedColumn<int> jamMulai = GeneratedColumn<int>(
    'jam_mulai',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jamSelesaiMeta = const VerificationMeta(
    'jamSelesai',
  );
  @override
  late final GeneratedColumn<int> jamSelesai = GeneratedColumn<int>(
    'jam_selesai',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruanganMeta = const VerificationMeta(
    'ruangan',
  );
  @override
  late final GeneratedColumn<String> ruangan = GeneratedColumn<String>(
    'ruangan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pengingatAktifMeta = const VerificationMeta(
    'pengingatAktif',
  );
  @override
  late final GeneratedColumn<bool> pengingatAktif = GeneratedColumn<bool>(
    'pengingat_aktif',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pengingat_aktif" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _menitSebelumMeta = const VerificationMeta(
    'menitSebelum',
  );
  @override
  late final GeneratedColumn<int> menitSebelum = GeneratedColumn<int>(
    'menit_sebelum',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(15),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mataKuliahId,
    hari,
    jamMulai,
    jamSelesai,
    ruangan,
    pengingatAktif,
    menitSebelum,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jadwal_kuliah';
  @override
  VerificationContext validateIntegrity(
    Insertable<JadwalKuliahData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('mata_kuliah_id')) {
      context.handle(
        _mataKuliahIdMeta,
        mataKuliahId.isAcceptableOrUnknown(
          data['mata_kuliah_id']!,
          _mataKuliahIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mataKuliahIdMeta);
    }
    if (data.containsKey('hari')) {
      context.handle(
        _hariMeta,
        hari.isAcceptableOrUnknown(data['hari']!, _hariMeta),
      );
    } else if (isInserting) {
      context.missing(_hariMeta);
    }
    if (data.containsKey('jam_mulai')) {
      context.handle(
        _jamMulaiMeta,
        jamMulai.isAcceptableOrUnknown(data['jam_mulai']!, _jamMulaiMeta),
      );
    } else if (isInserting) {
      context.missing(_jamMulaiMeta);
    }
    if (data.containsKey('jam_selesai')) {
      context.handle(
        _jamSelesaiMeta,
        jamSelesai.isAcceptableOrUnknown(data['jam_selesai']!, _jamSelesaiMeta),
      );
    } else if (isInserting) {
      context.missing(_jamSelesaiMeta);
    }
    if (data.containsKey('ruangan')) {
      context.handle(
        _ruanganMeta,
        ruangan.isAcceptableOrUnknown(data['ruangan']!, _ruanganMeta),
      );
    }
    if (data.containsKey('pengingat_aktif')) {
      context.handle(
        _pengingatAktifMeta,
        pengingatAktif.isAcceptableOrUnknown(
          data['pengingat_aktif']!,
          _pengingatAktifMeta,
        ),
      );
    }
    if (data.containsKey('menit_sebelum')) {
      context.handle(
        _menitSebelumMeta,
        menitSebelum.isAcceptableOrUnknown(
          data['menit_sebelum']!,
          _menitSebelumMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JadwalKuliahData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JadwalKuliahData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mataKuliahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mata_kuliah_id'],
      )!,
      hari: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hari'],
      )!,
      jamMulai: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jam_mulai'],
      )!,
      jamSelesai: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jam_selesai'],
      )!,
      ruangan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruangan'],
      ),
      pengingatAktif: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pengingat_aktif'],
      )!,
      menitSebelum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}menit_sebelum'],
      )!,
    );
  }

  @override
  $JadwalKuliahTableTable createAlias(String alias) {
    return $JadwalKuliahTableTable(attachedDatabase, alias);
  }
}

class JadwalKuliahData extends DataClass
    implements Insertable<JadwalKuliahData> {
  final int id;
  final int mataKuliahId;
  final int hari;
  final int jamMulai;
  final int jamSelesai;
  final String? ruangan;
  final bool pengingatAktif;
  final int menitSebelum;
  const JadwalKuliahData({
    required this.id,
    required this.mataKuliahId,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    this.ruangan,
    required this.pengingatAktif,
    required this.menitSebelum,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['mata_kuliah_id'] = Variable<int>(mataKuliahId);
    map['hari'] = Variable<int>(hari);
    map['jam_mulai'] = Variable<int>(jamMulai);
    map['jam_selesai'] = Variable<int>(jamSelesai);
    if (!nullToAbsent || ruangan != null) {
      map['ruangan'] = Variable<String>(ruangan);
    }
    map['pengingat_aktif'] = Variable<bool>(pengingatAktif);
    map['menit_sebelum'] = Variable<int>(menitSebelum);
    return map;
  }

  JadwalKuliahTableCompanion toCompanion(bool nullToAbsent) {
    return JadwalKuliahTableCompanion(
      id: Value(id),
      mataKuliahId: Value(mataKuliahId),
      hari: Value(hari),
      jamMulai: Value(jamMulai),
      jamSelesai: Value(jamSelesai),
      ruangan: ruangan == null && nullToAbsent
          ? const Value.absent()
          : Value(ruangan),
      pengingatAktif: Value(pengingatAktif),
      menitSebelum: Value(menitSebelum),
    );
  }

  factory JadwalKuliahData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JadwalKuliahData(
      id: serializer.fromJson<int>(json['id']),
      mataKuliahId: serializer.fromJson<int>(json['mataKuliahId']),
      hari: serializer.fromJson<int>(json['hari']),
      jamMulai: serializer.fromJson<int>(json['jamMulai']),
      jamSelesai: serializer.fromJson<int>(json['jamSelesai']),
      ruangan: serializer.fromJson<String?>(json['ruangan']),
      pengingatAktif: serializer.fromJson<bool>(json['pengingatAktif']),
      menitSebelum: serializer.fromJson<int>(json['menitSebelum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mataKuliahId': serializer.toJson<int>(mataKuliahId),
      'hari': serializer.toJson<int>(hari),
      'jamMulai': serializer.toJson<int>(jamMulai),
      'jamSelesai': serializer.toJson<int>(jamSelesai),
      'ruangan': serializer.toJson<String?>(ruangan),
      'pengingatAktif': serializer.toJson<bool>(pengingatAktif),
      'menitSebelum': serializer.toJson<int>(menitSebelum),
    };
  }

  JadwalKuliahData copyWith({
    int? id,
    int? mataKuliahId,
    int? hari,
    int? jamMulai,
    int? jamSelesai,
    Value<String?> ruangan = const Value.absent(),
    bool? pengingatAktif,
    int? menitSebelum,
  }) => JadwalKuliahData(
    id: id ?? this.id,
    mataKuliahId: mataKuliahId ?? this.mataKuliahId,
    hari: hari ?? this.hari,
    jamMulai: jamMulai ?? this.jamMulai,
    jamSelesai: jamSelesai ?? this.jamSelesai,
    ruangan: ruangan.present ? ruangan.value : this.ruangan,
    pengingatAktif: pengingatAktif ?? this.pengingatAktif,
    menitSebelum: menitSebelum ?? this.menitSebelum,
  );
  JadwalKuliahData copyWithCompanion(JadwalKuliahTableCompanion data) {
    return JadwalKuliahData(
      id: data.id.present ? data.id.value : this.id,
      mataKuliahId: data.mataKuliahId.present
          ? data.mataKuliahId.value
          : this.mataKuliahId,
      hari: data.hari.present ? data.hari.value : this.hari,
      jamMulai: data.jamMulai.present ? data.jamMulai.value : this.jamMulai,
      jamSelesai: data.jamSelesai.present
          ? data.jamSelesai.value
          : this.jamSelesai,
      ruangan: data.ruangan.present ? data.ruangan.value : this.ruangan,
      pengingatAktif: data.pengingatAktif.present
          ? data.pengingatAktif.value
          : this.pengingatAktif,
      menitSebelum: data.menitSebelum.present
          ? data.menitSebelum.value
          : this.menitSebelum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JadwalKuliahData(')
          ..write('id: $id, ')
          ..write('mataKuliahId: $mataKuliahId, ')
          ..write('hari: $hari, ')
          ..write('jamMulai: $jamMulai, ')
          ..write('jamSelesai: $jamSelesai, ')
          ..write('ruangan: $ruangan, ')
          ..write('pengingatAktif: $pengingatAktif, ')
          ..write('menitSebelum: $menitSebelum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mataKuliahId,
    hari,
    jamMulai,
    jamSelesai,
    ruangan,
    pengingatAktif,
    menitSebelum,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JadwalKuliahData &&
          other.id == this.id &&
          other.mataKuliahId == this.mataKuliahId &&
          other.hari == this.hari &&
          other.jamMulai == this.jamMulai &&
          other.jamSelesai == this.jamSelesai &&
          other.ruangan == this.ruangan &&
          other.pengingatAktif == this.pengingatAktif &&
          other.menitSebelum == this.menitSebelum);
}

class JadwalKuliahTableCompanion extends UpdateCompanion<JadwalKuliahData> {
  final Value<int> id;
  final Value<int> mataKuliahId;
  final Value<int> hari;
  final Value<int> jamMulai;
  final Value<int> jamSelesai;
  final Value<String?> ruangan;
  final Value<bool> pengingatAktif;
  final Value<int> menitSebelum;
  const JadwalKuliahTableCompanion({
    this.id = const Value.absent(),
    this.mataKuliahId = const Value.absent(),
    this.hari = const Value.absent(),
    this.jamMulai = const Value.absent(),
    this.jamSelesai = const Value.absent(),
    this.ruangan = const Value.absent(),
    this.pengingatAktif = const Value.absent(),
    this.menitSebelum = const Value.absent(),
  });
  JadwalKuliahTableCompanion.insert({
    this.id = const Value.absent(),
    required int mataKuliahId,
    required int hari,
    required int jamMulai,
    required int jamSelesai,
    this.ruangan = const Value.absent(),
    this.pengingatAktif = const Value.absent(),
    this.menitSebelum = const Value.absent(),
  }) : mataKuliahId = Value(mataKuliahId),
       hari = Value(hari),
       jamMulai = Value(jamMulai),
       jamSelesai = Value(jamSelesai);
  static Insertable<JadwalKuliahData> custom({
    Expression<int>? id,
    Expression<int>? mataKuliahId,
    Expression<int>? hari,
    Expression<int>? jamMulai,
    Expression<int>? jamSelesai,
    Expression<String>? ruangan,
    Expression<bool>? pengingatAktif,
    Expression<int>? menitSebelum,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mataKuliahId != null) 'mata_kuliah_id': mataKuliahId,
      if (hari != null) 'hari': hari,
      if (jamMulai != null) 'jam_mulai': jamMulai,
      if (jamSelesai != null) 'jam_selesai': jamSelesai,
      if (ruangan != null) 'ruangan': ruangan,
      if (pengingatAktif != null) 'pengingat_aktif': pengingatAktif,
      if (menitSebelum != null) 'menit_sebelum': menitSebelum,
    });
  }

  JadwalKuliahTableCompanion copyWith({
    Value<int>? id,
    Value<int>? mataKuliahId,
    Value<int>? hari,
    Value<int>? jamMulai,
    Value<int>? jamSelesai,
    Value<String?>? ruangan,
    Value<bool>? pengingatAktif,
    Value<int>? menitSebelum,
  }) {
    return JadwalKuliahTableCompanion(
      id: id ?? this.id,
      mataKuliahId: mataKuliahId ?? this.mataKuliahId,
      hari: hari ?? this.hari,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      ruangan: ruangan ?? this.ruangan,
      pengingatAktif: pengingatAktif ?? this.pengingatAktif,
      menitSebelum: menitSebelum ?? this.menitSebelum,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mataKuliahId.present) {
      map['mata_kuliah_id'] = Variable<int>(mataKuliahId.value);
    }
    if (hari.present) {
      map['hari'] = Variable<int>(hari.value);
    }
    if (jamMulai.present) {
      map['jam_mulai'] = Variable<int>(jamMulai.value);
    }
    if (jamSelesai.present) {
      map['jam_selesai'] = Variable<int>(jamSelesai.value);
    }
    if (ruangan.present) {
      map['ruangan'] = Variable<String>(ruangan.value);
    }
    if (pengingatAktif.present) {
      map['pengingat_aktif'] = Variable<bool>(pengingatAktif.value);
    }
    if (menitSebelum.present) {
      map['menit_sebelum'] = Variable<int>(menitSebelum.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JadwalKuliahTableCompanion(')
          ..write('id: $id, ')
          ..write('mataKuliahId: $mataKuliahId, ')
          ..write('hari: $hari, ')
          ..write('jamMulai: $jamMulai, ')
          ..write('jamSelesai: $jamSelesai, ')
          ..write('ruangan: $ruangan, ')
          ..write('pengingatAktif: $pengingatAktif, ')
          ..write('menitSebelum: $menitSebelum')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MataKuliahTableTable mataKuliahTable = $MataKuliahTableTable(
    this,
  );
  late final $JadwalKuliahTableTable jadwalKuliahTable =
      $JadwalKuliahTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    mataKuliahTable,
    jadwalKuliahTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'mata_kuliah',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('jadwal_kuliah', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$MataKuliahTableTableCreateCompanionBuilder =
    MataKuliahTableCompanion Function({
      Value<int> id,
      required String nama,
      Value<String?> dosen,
      Value<int?> sks,
    });
typedef $$MataKuliahTableTableUpdateCompanionBuilder =
    MataKuliahTableCompanion Function({
      Value<int> id,
      Value<String> nama,
      Value<String?> dosen,
      Value<int?> sks,
    });

final class $$MataKuliahTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $MataKuliahTableTable, MataKuliahData> {
  $$MataKuliahTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$JadwalKuliahTableTable, List<JadwalKuliahData>>
  _jadwalKuliahTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.jadwalKuliahTable,
        aliasName: 'mata_kuliah__id__jadwal_kuliah__mata_kuliah_id',
      );

  $$JadwalKuliahTableTableProcessedTableManager get jadwalKuliahTableRefs {
    final manager = $$JadwalKuliahTableTableTableManager(
      $_db,
      $_db.jadwalKuliahTable,
    ).filter((f) => f.mataKuliahId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _jadwalKuliahTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MataKuliahTableTableFilterComposer
    extends Composer<_$AppDatabase, $MataKuliahTableTable> {
  $$MataKuliahTableTableFilterComposer({
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

  ColumnFilters<String> get nama => $composableBuilder(
    column: $table.nama,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dosen => $composableBuilder(
    column: $table.dosen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sks => $composableBuilder(
    column: $table.sks,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> jadwalKuliahTableRefs(
    Expression<bool> Function($$JadwalKuliahTableTableFilterComposer f) f,
  ) {
    final $$JadwalKuliahTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jadwalKuliahTable,
      getReferencedColumn: (t) => t.mataKuliahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JadwalKuliahTableTableFilterComposer(
            $db: $db,
            $table: $db.jadwalKuliahTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MataKuliahTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MataKuliahTableTable> {
  $$MataKuliahTableTableOrderingComposer({
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

  ColumnOrderings<String> get nama => $composableBuilder(
    column: $table.nama,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dosen => $composableBuilder(
    column: $table.dosen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sks => $composableBuilder(
    column: $table.sks,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MataKuliahTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MataKuliahTableTable> {
  $$MataKuliahTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nama =>
      $composableBuilder(column: $table.nama, builder: (column) => column);

  GeneratedColumn<String> get dosen =>
      $composableBuilder(column: $table.dosen, builder: (column) => column);

  GeneratedColumn<int> get sks =>
      $composableBuilder(column: $table.sks, builder: (column) => column);

  Expression<T> jadwalKuliahTableRefs<T extends Object>(
    Expression<T> Function($$JadwalKuliahTableTableAnnotationComposer a) f,
  ) {
    final $$JadwalKuliahTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.jadwalKuliahTable,
          getReferencedColumn: (t) => t.mataKuliahId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$JadwalKuliahTableTableAnnotationComposer(
                $db: $db,
                $table: $db.jadwalKuliahTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MataKuliahTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MataKuliahTableTable,
          MataKuliahData,
          $$MataKuliahTableTableFilterComposer,
          $$MataKuliahTableTableOrderingComposer,
          $$MataKuliahTableTableAnnotationComposer,
          $$MataKuliahTableTableCreateCompanionBuilder,
          $$MataKuliahTableTableUpdateCompanionBuilder,
          (MataKuliahData, $$MataKuliahTableTableReferences),
          MataKuliahData,
          PrefetchHooks Function({bool jadwalKuliahTableRefs})
        > {
  $$MataKuliahTableTableTableManager(
    _$AppDatabase db,
    $MataKuliahTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MataKuliahTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MataKuliahTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MataKuliahTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nama = const Value.absent(),
                Value<String?> dosen = const Value.absent(),
                Value<int?> sks = const Value.absent(),
              }) => MataKuliahTableCompanion(
                id: id,
                nama: nama,
                dosen: dosen,
                sks: sks,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nama,
                Value<String?> dosen = const Value.absent(),
                Value<int?> sks = const Value.absent(),
              }) => MataKuliahTableCompanion.insert(
                id: id,
                nama: nama,
                dosen: dosen,
                sks: sks,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MataKuliahTableTable, MataKuliahData>(table),
                  $$MataKuliahTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({jadwalKuliahTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (jadwalKuliahTableRefs) db.jadwalKuliahTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (jadwalKuliahTableRefs)
                    await $_getPrefetchedData<
                      MataKuliahData,
                      $MataKuliahTableTable,
                      JadwalKuliahData
                    >(
                      currentTable: table,
                      referencedTable: $$MataKuliahTableTableReferences
                          ._jadwalKuliahTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MataKuliahTableTableReferences(
                            db,
                            table,
                            p0,
                          ).jadwalKuliahTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.mataKuliahId == item.id,
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

typedef $$MataKuliahTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MataKuliahTableTable,
      MataKuliahData,
      $$MataKuliahTableTableFilterComposer,
      $$MataKuliahTableTableOrderingComposer,
      $$MataKuliahTableTableAnnotationComposer,
      $$MataKuliahTableTableCreateCompanionBuilder,
      $$MataKuliahTableTableUpdateCompanionBuilder,
      (MataKuliahData, $$MataKuliahTableTableReferences),
      MataKuliahData,
      PrefetchHooks Function({bool jadwalKuliahTableRefs})
    >;
typedef $$JadwalKuliahTableTableCreateCompanionBuilder =
    JadwalKuliahTableCompanion Function({
      Value<int> id,
      required int mataKuliahId,
      required int hari,
      required int jamMulai,
      required int jamSelesai,
      Value<String?> ruangan,
      Value<bool> pengingatAktif,
      Value<int> menitSebelum,
    });
typedef $$JadwalKuliahTableTableUpdateCompanionBuilder =
    JadwalKuliahTableCompanion Function({
      Value<int> id,
      Value<int> mataKuliahId,
      Value<int> hari,
      Value<int> jamMulai,
      Value<int> jamSelesai,
      Value<String?> ruangan,
      Value<bool> pengingatAktif,
      Value<int> menitSebelum,
    });

final class $$JadwalKuliahTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $JadwalKuliahTableTable,
          JadwalKuliahData
        > {
  $$JadwalKuliahTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MataKuliahTableTable _mataKuliahIdTable(_$AppDatabase db) => db
      .mataKuliahTable
      .createAlias('jadwal_kuliah__mata_kuliah_id__mata_kuliah__id');

  $$MataKuliahTableTableProcessedTableManager get mataKuliahId {
    final $_column = $_itemColumn<int>('mata_kuliah_id')!;

    final manager = $$MataKuliahTableTableTableManager(
      $_db,
      $_db.mataKuliahTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mataKuliahIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JadwalKuliahTableTableFilterComposer
    extends Composer<_$AppDatabase, $JadwalKuliahTableTable> {
  $$JadwalKuliahTableTableFilterComposer({
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

  ColumnFilters<int> get hari => $composableBuilder(
    column: $table.hari,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jamMulai => $composableBuilder(
    column: $table.jamMulai,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jamSelesai => $composableBuilder(
    column: $table.jamSelesai,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruangan => $composableBuilder(
    column: $table.ruangan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pengingatAktif => $composableBuilder(
    column: $table.pengingatAktif,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get menitSebelum => $composableBuilder(
    column: $table.menitSebelum,
    builder: (column) => ColumnFilters(column),
  );

  $$MataKuliahTableTableFilterComposer get mataKuliahId {
    final $$MataKuliahTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mataKuliahId,
      referencedTable: $db.mataKuliahTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MataKuliahTableTableFilterComposer(
            $db: $db,
            $table: $db.mataKuliahTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JadwalKuliahTableTableOrderingComposer
    extends Composer<_$AppDatabase, $JadwalKuliahTableTable> {
  $$JadwalKuliahTableTableOrderingComposer({
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

  ColumnOrderings<int> get hari => $composableBuilder(
    column: $table.hari,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jamMulai => $composableBuilder(
    column: $table.jamMulai,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jamSelesai => $composableBuilder(
    column: $table.jamSelesai,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruangan => $composableBuilder(
    column: $table.ruangan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pengingatAktif => $composableBuilder(
    column: $table.pengingatAktif,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get menitSebelum => $composableBuilder(
    column: $table.menitSebelum,
    builder: (column) => ColumnOrderings(column),
  );

  $$MataKuliahTableTableOrderingComposer get mataKuliahId {
    final $$MataKuliahTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mataKuliahId,
      referencedTable: $db.mataKuliahTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MataKuliahTableTableOrderingComposer(
            $db: $db,
            $table: $db.mataKuliahTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JadwalKuliahTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $JadwalKuliahTableTable> {
  $$JadwalKuliahTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get hari =>
      $composableBuilder(column: $table.hari, builder: (column) => column);

  GeneratedColumn<int> get jamMulai =>
      $composableBuilder(column: $table.jamMulai, builder: (column) => column);

  GeneratedColumn<int> get jamSelesai => $composableBuilder(
    column: $table.jamSelesai,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruangan =>
      $composableBuilder(column: $table.ruangan, builder: (column) => column);

  GeneratedColumn<bool> get pengingatAktif => $composableBuilder(
    column: $table.pengingatAktif,
    builder: (column) => column,
  );

  GeneratedColumn<int> get menitSebelum => $composableBuilder(
    column: $table.menitSebelum,
    builder: (column) => column,
  );

  $$MataKuliahTableTableAnnotationComposer get mataKuliahId {
    final $$MataKuliahTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mataKuliahId,
      referencedTable: $db.mataKuliahTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MataKuliahTableTableAnnotationComposer(
            $db: $db,
            $table: $db.mataKuliahTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JadwalKuliahTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JadwalKuliahTableTable,
          JadwalKuliahData,
          $$JadwalKuliahTableTableFilterComposer,
          $$JadwalKuliahTableTableOrderingComposer,
          $$JadwalKuliahTableTableAnnotationComposer,
          $$JadwalKuliahTableTableCreateCompanionBuilder,
          $$JadwalKuliahTableTableUpdateCompanionBuilder,
          (JadwalKuliahData, $$JadwalKuliahTableTableReferences),
          JadwalKuliahData,
          PrefetchHooks Function({bool mataKuliahId})
        > {
  $$JadwalKuliahTableTableTableManager(
    _$AppDatabase db,
    $JadwalKuliahTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JadwalKuliahTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JadwalKuliahTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JadwalKuliahTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> mataKuliahId = const Value.absent(),
                Value<int> hari = const Value.absent(),
                Value<int> jamMulai = const Value.absent(),
                Value<int> jamSelesai = const Value.absent(),
                Value<String?> ruangan = const Value.absent(),
                Value<bool> pengingatAktif = const Value.absent(),
                Value<int> menitSebelum = const Value.absent(),
              }) => JadwalKuliahTableCompanion(
                id: id,
                mataKuliahId: mataKuliahId,
                hari: hari,
                jamMulai: jamMulai,
                jamSelesai: jamSelesai,
                ruangan: ruangan,
                pengingatAktif: pengingatAktif,
                menitSebelum: menitSebelum,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int mataKuliahId,
                required int hari,
                required int jamMulai,
                required int jamSelesai,
                Value<String?> ruangan = const Value.absent(),
                Value<bool> pengingatAktif = const Value.absent(),
                Value<int> menitSebelum = const Value.absent(),
              }) => JadwalKuliahTableCompanion.insert(
                id: id,
                mataKuliahId: mataKuliahId,
                hari: hari,
                jamMulai: jamMulai,
                jamSelesai: jamSelesai,
                ruangan: ruangan,
                pengingatAktif: pengingatAktif,
                menitSebelum: menitSebelum,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JadwalKuliahTableTable, JadwalKuliahData>(table),
                  $$JadwalKuliahTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mataKuliahId = false}) {
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
                    if (mataKuliahId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.mataKuliahId,
                        referencedTable: $$JadwalKuliahTableTableReferences
                            ._mataKuliahIdTable(db),
                        referencedColumn: $$JadwalKuliahTableTableReferences
                            ._mataKuliahIdTable(db)
                            .id,
                      ) as T;
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

typedef $$JadwalKuliahTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JadwalKuliahTableTable,
      JadwalKuliahData,
      $$JadwalKuliahTableTableFilterComposer,
      $$JadwalKuliahTableTableOrderingComposer,
      $$JadwalKuliahTableTableAnnotationComposer,
      $$JadwalKuliahTableTableCreateCompanionBuilder,
      $$JadwalKuliahTableTableUpdateCompanionBuilder,
      (JadwalKuliahData, $$JadwalKuliahTableTableReferences),
      JadwalKuliahData,
      PrefetchHooks Function({bool mataKuliahId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MataKuliahTableTableTableManager get mataKuliahTable =>
      $$MataKuliahTableTableTableManager(_db, _db.mataKuliahTable);
  $$JadwalKuliahTableTableTableManager get jadwalKuliahTable =>
      $$JadwalKuliahTableTableTableManager(_db, _db.jadwalKuliahTable);
}
