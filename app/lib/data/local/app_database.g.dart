// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UnidadesTable extends Unidades with TableInfo<$UnidadesTable, Unidade> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnidadesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataImportacaoMeta = const VerificationMeta(
    'dataImportacao',
  );
  @override
  late final GeneratedColumn<DateTime> dataImportacao =
      GeneratedColumn<DateTime>(
        'data_importacao',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _arquivoOrigemMeta = const VerificationMeta(
    'arquivoOrigem',
  );
  @override
  late final GeneratedColumn<String> arquivoOrigem = GeneratedColumn<String>(
    'arquivo_origem',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nome,
    dataImportacao,
    arquivoOrigem,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unidades';
  @override
  VerificationContext validateIntegrity(
    Insertable<Unidade> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('data_importacao')) {
      context.handle(
        _dataImportacaoMeta,
        dataImportacao.isAcceptableOrUnknown(
          data['data_importacao']!,
          _dataImportacaoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataImportacaoMeta);
    }
    if (data.containsKey('arquivo_origem')) {
      context.handle(
        _arquivoOrigemMeta,
        arquivoOrigem.isAcceptableOrUnknown(
          data['arquivo_origem']!,
          _arquivoOrigemMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_arquivoOrigemMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Unidade map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Unidade(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      dataImportacao: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_importacao'],
      )!,
      arquivoOrigem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arquivo_origem'],
      )!,
    );
  }

  @override
  $UnidadesTable createAlias(String alias) {
    return $UnidadesTable(attachedDatabase, alias);
  }
}

class Unidade extends DataClass implements Insertable<Unidade> {
  final String id;
  final String nome;
  final DateTime dataImportacao;
  final String arquivoOrigem;
  const Unidade({
    required this.id,
    required this.nome,
    required this.dataImportacao,
    required this.arquivoOrigem,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nome'] = Variable<String>(nome);
    map['data_importacao'] = Variable<DateTime>(dataImportacao);
    map['arquivo_origem'] = Variable<String>(arquivoOrigem);
    return map;
  }

  UnidadesCompanion toCompanion(bool nullToAbsent) {
    return UnidadesCompanion(
      id: Value(id),
      nome: Value(nome),
      dataImportacao: Value(dataImportacao),
      arquivoOrigem: Value(arquivoOrigem),
    );
  }

  factory Unidade.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Unidade(
      id: serializer.fromJson<String>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      dataImportacao: serializer.fromJson<DateTime>(json['dataImportacao']),
      arquivoOrigem: serializer.fromJson<String>(json['arquivoOrigem']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nome': serializer.toJson<String>(nome),
      'dataImportacao': serializer.toJson<DateTime>(dataImportacao),
      'arquivoOrigem': serializer.toJson<String>(arquivoOrigem),
    };
  }

  Unidade copyWith({
    String? id,
    String? nome,
    DateTime? dataImportacao,
    String? arquivoOrigem,
  }) => Unidade(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    dataImportacao: dataImportacao ?? this.dataImportacao,
    arquivoOrigem: arquivoOrigem ?? this.arquivoOrigem,
  );
  Unidade copyWithCompanion(UnidadesCompanion data) {
    return Unidade(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      dataImportacao: data.dataImportacao.present
          ? data.dataImportacao.value
          : this.dataImportacao,
      arquivoOrigem: data.arquivoOrigem.present
          ? data.arquivoOrigem.value
          : this.arquivoOrigem,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Unidade(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('dataImportacao: $dataImportacao, ')
          ..write('arquivoOrigem: $arquivoOrigem')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, dataImportacao, arquivoOrigem);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Unidade &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.dataImportacao == this.dataImportacao &&
          other.arquivoOrigem == this.arquivoOrigem);
}

class UnidadesCompanion extends UpdateCompanion<Unidade> {
  final Value<String> id;
  final Value<String> nome;
  final Value<DateTime> dataImportacao;
  final Value<String> arquivoOrigem;
  final Value<int> rowid;
  const UnidadesCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.dataImportacao = const Value.absent(),
    this.arquivoOrigem = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnidadesCompanion.insert({
    required String id,
    required String nome,
    required DateTime dataImportacao,
    required String arquivoOrigem,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nome = Value(nome),
       dataImportacao = Value(dataImportacao),
       arquivoOrigem = Value(arquivoOrigem);
  static Insertable<Unidade> custom({
    Expression<String>? id,
    Expression<String>? nome,
    Expression<DateTime>? dataImportacao,
    Expression<String>? arquivoOrigem,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (dataImportacao != null) 'data_importacao': dataImportacao,
      if (arquivoOrigem != null) 'arquivo_origem': arquivoOrigem,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnidadesCompanion copyWith({
    Value<String>? id,
    Value<String>? nome,
    Value<DateTime>? dataImportacao,
    Value<String>? arquivoOrigem,
    Value<int>? rowid,
  }) {
    return UnidadesCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataImportacao: dataImportacao ?? this.dataImportacao,
      arquivoOrigem: arquivoOrigem ?? this.arquivoOrigem,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (dataImportacao.present) {
      map['data_importacao'] = Variable<DateTime>(dataImportacao.value);
    }
    if (arquivoOrigem.present) {
      map['arquivo_origem'] = Variable<String>(arquivoOrigem.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnidadesCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('dataImportacao: $dataImportacao, ')
          ..write('arquivoOrigem: $arquivoOrigem, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocaisTable extends Locais with TableInfo<$LocaisTable, Local> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocaisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unidadeIdMeta = const VerificationMeta(
    'unidadeId',
  );
  @override
  late final GeneratedColumn<String> unidadeId = GeneratedColumn<String>(
    'unidade_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paiIdMeta = const VerificationMeta('paiId');
  @override
  late final GeneratedColumn<String> paiId = GeneratedColumn<String>(
    'pai_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caminhoCompletoMeta = const VerificationMeta(
    'caminhoCompleto',
  );
  @override
  late final GeneratedColumn<String> caminhoCompleto = GeneratedColumn<String>(
    'caminho_completo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    unidadeId,
    nome,
    tipo,
    paiId,
    caminhoCompleto,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'locais';
  @override
  VerificationContext validateIntegrity(
    Insertable<Local> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('unidade_id')) {
      context.handle(
        _unidadeIdMeta,
        unidadeId.isAcceptableOrUnknown(data['unidade_id']!, _unidadeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_unidadeIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('pai_id')) {
      context.handle(
        _paiIdMeta,
        paiId.isAcceptableOrUnknown(data['pai_id']!, _paiIdMeta),
      );
    }
    if (data.containsKey('caminho_completo')) {
      context.handle(
        _caminhoCompletoMeta,
        caminhoCompleto.isAcceptableOrUnknown(
          data['caminho_completo']!,
          _caminhoCompletoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caminhoCompletoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Local map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Local(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      unidadeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unidade_id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      paiId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pai_id'],
      ),
      caminhoCompleto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caminho_completo'],
      )!,
    );
  }

  @override
  $LocaisTable createAlias(String alias) {
    return $LocaisTable(attachedDatabase, alias);
  }
}

class Local extends DataClass implements Insertable<Local> {
  final String id;
  final String unidadeId;
  final String nome;
  final String tipo;
  final String? paiId;
  final String caminhoCompleto;
  const Local({
    required this.id,
    required this.unidadeId,
    required this.nome,
    required this.tipo,
    this.paiId,
    required this.caminhoCompleto,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['unidade_id'] = Variable<String>(unidadeId);
    map['nome'] = Variable<String>(nome);
    map['tipo'] = Variable<String>(tipo);
    if (!nullToAbsent || paiId != null) {
      map['pai_id'] = Variable<String>(paiId);
    }
    map['caminho_completo'] = Variable<String>(caminhoCompleto);
    return map;
  }

  LocaisCompanion toCompanion(bool nullToAbsent) {
    return LocaisCompanion(
      id: Value(id),
      unidadeId: Value(unidadeId),
      nome: Value(nome),
      tipo: Value(tipo),
      paiId: paiId == null && nullToAbsent
          ? const Value.absent()
          : Value(paiId),
      caminhoCompleto: Value(caminhoCompleto),
    );
  }

  factory Local.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Local(
      id: serializer.fromJson<String>(json['id']),
      unidadeId: serializer.fromJson<String>(json['unidadeId']),
      nome: serializer.fromJson<String>(json['nome']),
      tipo: serializer.fromJson<String>(json['tipo']),
      paiId: serializer.fromJson<String?>(json['paiId']),
      caminhoCompleto: serializer.fromJson<String>(json['caminhoCompleto']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'unidadeId': serializer.toJson<String>(unidadeId),
      'nome': serializer.toJson<String>(nome),
      'tipo': serializer.toJson<String>(tipo),
      'paiId': serializer.toJson<String?>(paiId),
      'caminhoCompleto': serializer.toJson<String>(caminhoCompleto),
    };
  }

  Local copyWith({
    String? id,
    String? unidadeId,
    String? nome,
    String? tipo,
    Value<String?> paiId = const Value.absent(),
    String? caminhoCompleto,
  }) => Local(
    id: id ?? this.id,
    unidadeId: unidadeId ?? this.unidadeId,
    nome: nome ?? this.nome,
    tipo: tipo ?? this.tipo,
    paiId: paiId.present ? paiId.value : this.paiId,
    caminhoCompleto: caminhoCompleto ?? this.caminhoCompleto,
  );
  Local copyWithCompanion(LocaisCompanion data) {
    return Local(
      id: data.id.present ? data.id.value : this.id,
      unidadeId: data.unidadeId.present ? data.unidadeId.value : this.unidadeId,
      nome: data.nome.present ? data.nome.value : this.nome,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      paiId: data.paiId.present ? data.paiId.value : this.paiId,
      caminhoCompleto: data.caminhoCompleto.present
          ? data.caminhoCompleto.value
          : this.caminhoCompleto,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Local(')
          ..write('id: $id, ')
          ..write('unidadeId: $unidadeId, ')
          ..write('nome: $nome, ')
          ..write('tipo: $tipo, ')
          ..write('paiId: $paiId, ')
          ..write('caminhoCompleto: $caminhoCompleto')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, unidadeId, nome, tipo, paiId, caminhoCompleto);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Local &&
          other.id == this.id &&
          other.unidadeId == this.unidadeId &&
          other.nome == this.nome &&
          other.tipo == this.tipo &&
          other.paiId == this.paiId &&
          other.caminhoCompleto == this.caminhoCompleto);
}

class LocaisCompanion extends UpdateCompanion<Local> {
  final Value<String> id;
  final Value<String> unidadeId;
  final Value<String> nome;
  final Value<String> tipo;
  final Value<String?> paiId;
  final Value<String> caminhoCompleto;
  final Value<int> rowid;
  const LocaisCompanion({
    this.id = const Value.absent(),
    this.unidadeId = const Value.absent(),
    this.nome = const Value.absent(),
    this.tipo = const Value.absent(),
    this.paiId = const Value.absent(),
    this.caminhoCompleto = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocaisCompanion.insert({
    required String id,
    required String unidadeId,
    required String nome,
    required String tipo,
    this.paiId = const Value.absent(),
    required String caminhoCompleto,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       unidadeId = Value(unidadeId),
       nome = Value(nome),
       tipo = Value(tipo),
       caminhoCompleto = Value(caminhoCompleto);
  static Insertable<Local> custom({
    Expression<String>? id,
    Expression<String>? unidadeId,
    Expression<String>? nome,
    Expression<String>? tipo,
    Expression<String>? paiId,
    Expression<String>? caminhoCompleto,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (unidadeId != null) 'unidade_id': unidadeId,
      if (nome != null) 'nome': nome,
      if (tipo != null) 'tipo': tipo,
      if (paiId != null) 'pai_id': paiId,
      if (caminhoCompleto != null) 'caminho_completo': caminhoCompleto,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocaisCompanion copyWith({
    Value<String>? id,
    Value<String>? unidadeId,
    Value<String>? nome,
    Value<String>? tipo,
    Value<String?>? paiId,
    Value<String>? caminhoCompleto,
    Value<int>? rowid,
  }) {
    return LocaisCompanion(
      id: id ?? this.id,
      unidadeId: unidadeId ?? this.unidadeId,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      paiId: paiId ?? this.paiId,
      caminhoCompleto: caminhoCompleto ?? this.caminhoCompleto,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (unidadeId.present) {
      map['unidade_id'] = Variable<String>(unidadeId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (paiId.present) {
      map['pai_id'] = Variable<String>(paiId.value);
    }
    if (caminhoCompleto.present) {
      map['caminho_completo'] = Variable<String>(caminhoCompleto.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocaisCompanion(')
          ..write('id: $id, ')
          ..write('unidadeId: $unidadeId, ')
          ..write('nome: $nome, ')
          ..write('tipo: $tipo, ')
          ..write('paiId: $paiId, ')
          ..write('caminhoCompleto: $caminhoCompleto, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BensTable extends Bens with TableInfo<$BensTable, Bem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tombamentoMeta = const VerificationMeta(
    'tombamento',
  );
  @override
  late final GeneratedColumn<String> tombamento = GeneratedColumn<String>(
    'tombamento',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unidadeIdMeta = const VerificationMeta(
    'unidadeId',
  );
  @override
  late final GeneratedColumn<String> unidadeId = GeneratedColumn<String>(
    'unidade_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descricaoMeta = const VerificationMeta(
    'descricao',
  );
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
    'descricao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localEsperadoIdMeta = const VerificationMeta(
    'localEsperadoId',
  );
  @override
  late final GeneratedColumn<String> localEsperadoId = GeneratedColumn<String>(
    'local_esperado_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responsavelMeta = const VerificationMeta(
    'responsavel',
  );
  @override
  late final GeneratedColumn<String> responsavel = GeneratedColumn<String>(
    'responsavel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numeroSerieMeta = const VerificationMeta(
    'numeroSerie',
  );
  @override
  late final GeneratedColumn<String> numeroSerie = GeneratedColumn<String>(
    'numero_serie',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fabricanteMeta = const VerificationMeta(
    'fabricante',
  );
  @override
  late final GeneratedColumn<String> fabricante = GeneratedColumn<String>(
    'fabricante',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeloMeta = const VerificationMeta('modelo');
  @override
  late final GeneratedColumn<String> modelo = GeneratedColumn<String>(
    'modelo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extrasMeta = const VerificationMeta('extras');
  @override
  late final GeneratedColumn<String> extras = GeneratedColumn<String>(
    'extras',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tombamento,
    unidadeId,
    descricao,
    categoria,
    localEsperadoId,
    responsavel,
    numeroSerie,
    fabricante,
    modelo,
    extras,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bens';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tombamento')) {
      context.handle(
        _tombamentoMeta,
        tombamento.isAcceptableOrUnknown(data['tombamento']!, _tombamentoMeta),
      );
    } else if (isInserting) {
      context.missing(_tombamentoMeta);
    }
    if (data.containsKey('unidade_id')) {
      context.handle(
        _unidadeIdMeta,
        unidadeId.isAcceptableOrUnknown(data['unidade_id']!, _unidadeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_unidadeIdMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(
        _descricaoMeta,
        descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta),
      );
    } else if (isInserting) {
      context.missing(_descricaoMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    }
    if (data.containsKey('local_esperado_id')) {
      context.handle(
        _localEsperadoIdMeta,
        localEsperadoId.isAcceptableOrUnknown(
          data['local_esperado_id']!,
          _localEsperadoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localEsperadoIdMeta);
    }
    if (data.containsKey('responsavel')) {
      context.handle(
        _responsavelMeta,
        responsavel.isAcceptableOrUnknown(
          data['responsavel']!,
          _responsavelMeta,
        ),
      );
    }
    if (data.containsKey('numero_serie')) {
      context.handle(
        _numeroSerieMeta,
        numeroSerie.isAcceptableOrUnknown(
          data['numero_serie']!,
          _numeroSerieMeta,
        ),
      );
    }
    if (data.containsKey('fabricante')) {
      context.handle(
        _fabricanteMeta,
        fabricante.isAcceptableOrUnknown(data['fabricante']!, _fabricanteMeta),
      );
    }
    if (data.containsKey('modelo')) {
      context.handle(
        _modeloMeta,
        modelo.isAcceptableOrUnknown(data['modelo']!, _modeloMeta),
      );
    }
    if (data.containsKey('extras')) {
      context.handle(
        _extrasMeta,
        extras.isAcceptableOrUnknown(data['extras']!, _extrasMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tombamento};
  @override
  Bem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bem(
      tombamento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tombamento'],
      )!,
      unidadeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unidade_id'],
      )!,
      descricao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descricao'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      ),
      localEsperadoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_esperado_id'],
      )!,
      responsavel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}responsavel'],
      ),
      numeroSerie: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero_serie'],
      ),
      fabricante: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fabricante'],
      ),
      modelo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modelo'],
      ),
      extras: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extras'],
      ),
    );
  }

  @override
  $BensTable createAlias(String alias) {
    return $BensTable(attachedDatabase, alias);
  }
}

class Bem extends DataClass implements Insertable<Bem> {
  final String tombamento;
  final String unidadeId;
  final String descricao;
  final String? categoria;
  final String localEsperadoId;
  final String? responsavel;
  final String? numeroSerie;
  final String? fabricante;
  final String? modelo;
  final String? extras;
  const Bem({
    required this.tombamento,
    required this.unidadeId,
    required this.descricao,
    this.categoria,
    required this.localEsperadoId,
    this.responsavel,
    this.numeroSerie,
    this.fabricante,
    this.modelo,
    this.extras,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tombamento'] = Variable<String>(tombamento);
    map['unidade_id'] = Variable<String>(unidadeId);
    map['descricao'] = Variable<String>(descricao);
    if (!nullToAbsent || categoria != null) {
      map['categoria'] = Variable<String>(categoria);
    }
    map['local_esperado_id'] = Variable<String>(localEsperadoId);
    if (!nullToAbsent || responsavel != null) {
      map['responsavel'] = Variable<String>(responsavel);
    }
    if (!nullToAbsent || numeroSerie != null) {
      map['numero_serie'] = Variable<String>(numeroSerie);
    }
    if (!nullToAbsent || fabricante != null) {
      map['fabricante'] = Variable<String>(fabricante);
    }
    if (!nullToAbsent || modelo != null) {
      map['modelo'] = Variable<String>(modelo);
    }
    if (!nullToAbsent || extras != null) {
      map['extras'] = Variable<String>(extras);
    }
    return map;
  }

  BensCompanion toCompanion(bool nullToAbsent) {
    return BensCompanion(
      tombamento: Value(tombamento),
      unidadeId: Value(unidadeId),
      descricao: Value(descricao),
      categoria: categoria == null && nullToAbsent
          ? const Value.absent()
          : Value(categoria),
      localEsperadoId: Value(localEsperadoId),
      responsavel: responsavel == null && nullToAbsent
          ? const Value.absent()
          : Value(responsavel),
      numeroSerie: numeroSerie == null && nullToAbsent
          ? const Value.absent()
          : Value(numeroSerie),
      fabricante: fabricante == null && nullToAbsent
          ? const Value.absent()
          : Value(fabricante),
      modelo: modelo == null && nullToAbsent
          ? const Value.absent()
          : Value(modelo),
      extras: extras == null && nullToAbsent
          ? const Value.absent()
          : Value(extras),
    );
  }

  factory Bem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bem(
      tombamento: serializer.fromJson<String>(json['tombamento']),
      unidadeId: serializer.fromJson<String>(json['unidadeId']),
      descricao: serializer.fromJson<String>(json['descricao']),
      categoria: serializer.fromJson<String?>(json['categoria']),
      localEsperadoId: serializer.fromJson<String>(json['localEsperadoId']),
      responsavel: serializer.fromJson<String?>(json['responsavel']),
      numeroSerie: serializer.fromJson<String?>(json['numeroSerie']),
      fabricante: serializer.fromJson<String?>(json['fabricante']),
      modelo: serializer.fromJson<String?>(json['modelo']),
      extras: serializer.fromJson<String?>(json['extras']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tombamento': serializer.toJson<String>(tombamento),
      'unidadeId': serializer.toJson<String>(unidadeId),
      'descricao': serializer.toJson<String>(descricao),
      'categoria': serializer.toJson<String?>(categoria),
      'localEsperadoId': serializer.toJson<String>(localEsperadoId),
      'responsavel': serializer.toJson<String?>(responsavel),
      'numeroSerie': serializer.toJson<String?>(numeroSerie),
      'fabricante': serializer.toJson<String?>(fabricante),
      'modelo': serializer.toJson<String?>(modelo),
      'extras': serializer.toJson<String?>(extras),
    };
  }

  Bem copyWith({
    String? tombamento,
    String? unidadeId,
    String? descricao,
    Value<String?> categoria = const Value.absent(),
    String? localEsperadoId,
    Value<String?> responsavel = const Value.absent(),
    Value<String?> numeroSerie = const Value.absent(),
    Value<String?> fabricante = const Value.absent(),
    Value<String?> modelo = const Value.absent(),
    Value<String?> extras = const Value.absent(),
  }) => Bem(
    tombamento: tombamento ?? this.tombamento,
    unidadeId: unidadeId ?? this.unidadeId,
    descricao: descricao ?? this.descricao,
    categoria: categoria.present ? categoria.value : this.categoria,
    localEsperadoId: localEsperadoId ?? this.localEsperadoId,
    responsavel: responsavel.present ? responsavel.value : this.responsavel,
    numeroSerie: numeroSerie.present ? numeroSerie.value : this.numeroSerie,
    fabricante: fabricante.present ? fabricante.value : this.fabricante,
    modelo: modelo.present ? modelo.value : this.modelo,
    extras: extras.present ? extras.value : this.extras,
  );
  Bem copyWithCompanion(BensCompanion data) {
    return Bem(
      tombamento: data.tombamento.present
          ? data.tombamento.value
          : this.tombamento,
      unidadeId: data.unidadeId.present ? data.unidadeId.value : this.unidadeId,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      localEsperadoId: data.localEsperadoId.present
          ? data.localEsperadoId.value
          : this.localEsperadoId,
      responsavel: data.responsavel.present
          ? data.responsavel.value
          : this.responsavel,
      numeroSerie: data.numeroSerie.present
          ? data.numeroSerie.value
          : this.numeroSerie,
      fabricante: data.fabricante.present
          ? data.fabricante.value
          : this.fabricante,
      modelo: data.modelo.present ? data.modelo.value : this.modelo,
      extras: data.extras.present ? data.extras.value : this.extras,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bem(')
          ..write('tombamento: $tombamento, ')
          ..write('unidadeId: $unidadeId, ')
          ..write('descricao: $descricao, ')
          ..write('categoria: $categoria, ')
          ..write('localEsperadoId: $localEsperadoId, ')
          ..write('responsavel: $responsavel, ')
          ..write('numeroSerie: $numeroSerie, ')
          ..write('fabricante: $fabricante, ')
          ..write('modelo: $modelo, ')
          ..write('extras: $extras')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tombamento,
    unidadeId,
    descricao,
    categoria,
    localEsperadoId,
    responsavel,
    numeroSerie,
    fabricante,
    modelo,
    extras,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bem &&
          other.tombamento == this.tombamento &&
          other.unidadeId == this.unidadeId &&
          other.descricao == this.descricao &&
          other.categoria == this.categoria &&
          other.localEsperadoId == this.localEsperadoId &&
          other.responsavel == this.responsavel &&
          other.numeroSerie == this.numeroSerie &&
          other.fabricante == this.fabricante &&
          other.modelo == this.modelo &&
          other.extras == this.extras);
}

class BensCompanion extends UpdateCompanion<Bem> {
  final Value<String> tombamento;
  final Value<String> unidadeId;
  final Value<String> descricao;
  final Value<String?> categoria;
  final Value<String> localEsperadoId;
  final Value<String?> responsavel;
  final Value<String?> numeroSerie;
  final Value<String?> fabricante;
  final Value<String?> modelo;
  final Value<String?> extras;
  final Value<int> rowid;
  const BensCompanion({
    this.tombamento = const Value.absent(),
    this.unidadeId = const Value.absent(),
    this.descricao = const Value.absent(),
    this.categoria = const Value.absent(),
    this.localEsperadoId = const Value.absent(),
    this.responsavel = const Value.absent(),
    this.numeroSerie = const Value.absent(),
    this.fabricante = const Value.absent(),
    this.modelo = const Value.absent(),
    this.extras = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BensCompanion.insert({
    required String tombamento,
    required String unidadeId,
    required String descricao,
    this.categoria = const Value.absent(),
    required String localEsperadoId,
    this.responsavel = const Value.absent(),
    this.numeroSerie = const Value.absent(),
    this.fabricante = const Value.absent(),
    this.modelo = const Value.absent(),
    this.extras = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tombamento = Value(tombamento),
       unidadeId = Value(unidadeId),
       descricao = Value(descricao),
       localEsperadoId = Value(localEsperadoId);
  static Insertable<Bem> custom({
    Expression<String>? tombamento,
    Expression<String>? unidadeId,
    Expression<String>? descricao,
    Expression<String>? categoria,
    Expression<String>? localEsperadoId,
    Expression<String>? responsavel,
    Expression<String>? numeroSerie,
    Expression<String>? fabricante,
    Expression<String>? modelo,
    Expression<String>? extras,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tombamento != null) 'tombamento': tombamento,
      if (unidadeId != null) 'unidade_id': unidadeId,
      if (descricao != null) 'descricao': descricao,
      if (categoria != null) 'categoria': categoria,
      if (localEsperadoId != null) 'local_esperado_id': localEsperadoId,
      if (responsavel != null) 'responsavel': responsavel,
      if (numeroSerie != null) 'numero_serie': numeroSerie,
      if (fabricante != null) 'fabricante': fabricante,
      if (modelo != null) 'modelo': modelo,
      if (extras != null) 'extras': extras,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BensCompanion copyWith({
    Value<String>? tombamento,
    Value<String>? unidadeId,
    Value<String>? descricao,
    Value<String?>? categoria,
    Value<String>? localEsperadoId,
    Value<String?>? responsavel,
    Value<String?>? numeroSerie,
    Value<String?>? fabricante,
    Value<String?>? modelo,
    Value<String?>? extras,
    Value<int>? rowid,
  }) {
    return BensCompanion(
      tombamento: tombamento ?? this.tombamento,
      unidadeId: unidadeId ?? this.unidadeId,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      localEsperadoId: localEsperadoId ?? this.localEsperadoId,
      responsavel: responsavel ?? this.responsavel,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      fabricante: fabricante ?? this.fabricante,
      modelo: modelo ?? this.modelo,
      extras: extras ?? this.extras,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tombamento.present) {
      map['tombamento'] = Variable<String>(tombamento.value);
    }
    if (unidadeId.present) {
      map['unidade_id'] = Variable<String>(unidadeId.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (localEsperadoId.present) {
      map['local_esperado_id'] = Variable<String>(localEsperadoId.value);
    }
    if (responsavel.present) {
      map['responsavel'] = Variable<String>(responsavel.value);
    }
    if (numeroSerie.present) {
      map['numero_serie'] = Variable<String>(numeroSerie.value);
    }
    if (fabricante.present) {
      map['fabricante'] = Variable<String>(fabricante.value);
    }
    if (modelo.present) {
      map['modelo'] = Variable<String>(modelo.value);
    }
    if (extras.present) {
      map['extras'] = Variable<String>(extras.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BensCompanion(')
          ..write('tombamento: $tombamento, ')
          ..write('unidadeId: $unidadeId, ')
          ..write('descricao: $descricao, ')
          ..write('categoria: $categoria, ')
          ..write('localEsperadoId: $localEsperadoId, ')
          ..write('responsavel: $responsavel, ')
          ..write('numeroSerie: $numeroSerie, ')
          ..write('fabricante: $fabricante, ')
          ..write('modelo: $modelo, ')
          ..write('extras: $extras, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConferenciaSalasTable extends ConferenciaSalas
    with TableInfo<$ConferenciaSalasTable, ConferenciaSala> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConferenciaSalasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('nao_iniciada'),
  );
  static const VerificationMeta _inicioMeta = const VerificationMeta('inicio');
  @override
  late final GeneratedColumn<DateTime> inicio = GeneratedColumn<DateTime>(
    'inicio',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fimMeta = const VerificationMeta('fim');
  @override
  late final GeneratedColumn<DateTime> fim = GeneratedColumn<DateTime>(
    'fim',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conferenteMeta = const VerificationMeta(
    'conferente',
  );
  @override
  late final GeneratedColumn<String> conferente = GeneratedColumn<String>(
    'conferente',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    status,
    inicio,
    fim,
    conferente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conferencia_salas';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConferenciaSala> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('inicio')) {
      context.handle(
        _inicioMeta,
        inicio.isAcceptableOrUnknown(data['inicio']!, _inicioMeta),
      );
    }
    if (data.containsKey('fim')) {
      context.handle(
        _fimMeta,
        fim.isAcceptableOrUnknown(data['fim']!, _fimMeta),
      );
    }
    if (data.containsKey('conferente')) {
      context.handle(
        _conferenteMeta,
        conferente.isAcceptableOrUnknown(data['conferente']!, _conferenteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  ConferenciaSala map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConferenciaSala(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      inicio: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}inicio'],
      ),
      fim: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fim'],
      ),
      conferente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conferente'],
      ),
    );
  }

  @override
  $ConferenciaSalasTable createAlias(String alias) {
    return $ConferenciaSalasTable(attachedDatabase, alias);
  }
}

class ConferenciaSala extends DataClass implements Insertable<ConferenciaSala> {
  final String localId;
  final String status;
  final DateTime? inicio;
  final DateTime? fim;
  final String? conferente;
  const ConferenciaSala({
    required this.localId,
    required this.status,
    this.inicio,
    this.fim,
    this.conferente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || inicio != null) {
      map['inicio'] = Variable<DateTime>(inicio);
    }
    if (!nullToAbsent || fim != null) {
      map['fim'] = Variable<DateTime>(fim);
    }
    if (!nullToAbsent || conferente != null) {
      map['conferente'] = Variable<String>(conferente);
    }
    return map;
  }

  ConferenciaSalasCompanion toCompanion(bool nullToAbsent) {
    return ConferenciaSalasCompanion(
      localId: Value(localId),
      status: Value(status),
      inicio: inicio == null && nullToAbsent
          ? const Value.absent()
          : Value(inicio),
      fim: fim == null && nullToAbsent ? const Value.absent() : Value(fim),
      conferente: conferente == null && nullToAbsent
          ? const Value.absent()
          : Value(conferente),
    );
  }

  factory ConferenciaSala.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConferenciaSala(
      localId: serializer.fromJson<String>(json['localId']),
      status: serializer.fromJson<String>(json['status']),
      inicio: serializer.fromJson<DateTime?>(json['inicio']),
      fim: serializer.fromJson<DateTime?>(json['fim']),
      conferente: serializer.fromJson<String?>(json['conferente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'status': serializer.toJson<String>(status),
      'inicio': serializer.toJson<DateTime?>(inicio),
      'fim': serializer.toJson<DateTime?>(fim),
      'conferente': serializer.toJson<String?>(conferente),
    };
  }

  ConferenciaSala copyWith({
    String? localId,
    String? status,
    Value<DateTime?> inicio = const Value.absent(),
    Value<DateTime?> fim = const Value.absent(),
    Value<String?> conferente = const Value.absent(),
  }) => ConferenciaSala(
    localId: localId ?? this.localId,
    status: status ?? this.status,
    inicio: inicio.present ? inicio.value : this.inicio,
    fim: fim.present ? fim.value : this.fim,
    conferente: conferente.present ? conferente.value : this.conferente,
  );
  ConferenciaSala copyWithCompanion(ConferenciaSalasCompanion data) {
    return ConferenciaSala(
      localId: data.localId.present ? data.localId.value : this.localId,
      status: data.status.present ? data.status.value : this.status,
      inicio: data.inicio.present ? data.inicio.value : this.inicio,
      fim: data.fim.present ? data.fim.value : this.fim,
      conferente: data.conferente.present
          ? data.conferente.value
          : this.conferente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConferenciaSala(')
          ..write('localId: $localId, ')
          ..write('status: $status, ')
          ..write('inicio: $inicio, ')
          ..write('fim: $fim, ')
          ..write('conferente: $conferente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, status, inicio, fim, conferente);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConferenciaSala &&
          other.localId == this.localId &&
          other.status == this.status &&
          other.inicio == this.inicio &&
          other.fim == this.fim &&
          other.conferente == this.conferente);
}

class ConferenciaSalasCompanion extends UpdateCompanion<ConferenciaSala> {
  final Value<String> localId;
  final Value<String> status;
  final Value<DateTime?> inicio;
  final Value<DateTime?> fim;
  final Value<String?> conferente;
  final Value<int> rowid;
  const ConferenciaSalasCompanion({
    this.localId = const Value.absent(),
    this.status = const Value.absent(),
    this.inicio = const Value.absent(),
    this.fim = const Value.absent(),
    this.conferente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConferenciaSalasCompanion.insert({
    required String localId,
    this.status = const Value.absent(),
    this.inicio = const Value.absent(),
    this.fim = const Value.absent(),
    this.conferente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId);
  static Insertable<ConferenciaSala> custom({
    Expression<String>? localId,
    Expression<String>? status,
    Expression<DateTime>? inicio,
    Expression<DateTime>? fim,
    Expression<String>? conferente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (status != null) 'status': status,
      if (inicio != null) 'inicio': inicio,
      if (fim != null) 'fim': fim,
      if (conferente != null) 'conferente': conferente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConferenciaSalasCompanion copyWith({
    Value<String>? localId,
    Value<String>? status,
    Value<DateTime?>? inicio,
    Value<DateTime?>? fim,
    Value<String?>? conferente,
    Value<int>? rowid,
  }) {
    return ConferenciaSalasCompanion(
      localId: localId ?? this.localId,
      status: status ?? this.status,
      inicio: inicio ?? this.inicio,
      fim: fim ?? this.fim,
      conferente: conferente ?? this.conferente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (inicio.present) {
      map['inicio'] = Variable<DateTime>(inicio.value);
    }
    if (fim.present) {
      map['fim'] = Variable<DateTime>(fim.value);
    }
    if (conferente.present) {
      map['conferente'] = Variable<String>(conferente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConferenciaSalasCompanion(')
          ..write('localId: $localId, ')
          ..write('status: $status, ')
          ..write('inicio: $inicio, ')
          ..write('fim: $fim, ')
          ..write('conferente: $conferente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventosTable extends Eventos with TableInfo<$EventosTable, Evento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unidadeIdMeta = const VerificationMeta(
    'unidadeId',
  );
  @override
  late final GeneratedColumn<String> unidadeId = GeneratedColumn<String>(
    'unidade_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unidade_demo'),
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
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _autorMeta = const VerificationMeta('autor');
  @override
  late final GeneratedColumn<String> autor = GeneratedColumn<String>(
    'autor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_device'),
  );
  static const VerificationMeta _tombamentoMeta = const VerificationMeta(
    'tombamento',
  );
  @override
  late final GeneratedColumn<String> tombamento = GeneratedColumn<String>(
    'tombamento',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aparelhoIdMeta = const VerificationMeta(
    'aparelhoId',
  );
  @override
  late final GeneratedColumn<String> aparelhoId = GeneratedColumn<String>(
    'aparelho_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conferenteMeta = const VerificationMeta(
    'conferente',
  );
  @override
  late final GeneratedColumn<String> conferente = GeneratedColumn<String>(
    'conferente',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _hashFotoMeta = const VerificationMeta(
    'hashFoto',
  );
  @override
  late final GeneratedColumn<String> hashFoto = GeneratedColumn<String>(
    'hash_foto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashAnteriorMeta = const VerificationMeta(
    'hashAnterior',
  );
  @override
  late final GeneratedColumn<String> hashAnterior = GeneratedColumn<String>(
    'hash_anterior',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conhecidosMeta = const VerificationMeta(
    'conhecidos',
  );
  @override
  late final GeneratedColumn<String> conhecidos = GeneratedColumn<String>(
    'conhecidos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assinaturaMeta = const VerificationMeta(
    'assinatura',
  );
  @override
  late final GeneratedColumn<String> assinatura = GeneratedColumn<String>(
    'assinatura',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    unidadeId,
    seq,
    tipo,
    autor,
    tombamento,
    localId,
    aparelhoId,
    conferente,
    timestamp,
    payload,
    hashFoto,
    hashAnterior,
    conhecidos,
    hash,
    assinatura,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eventos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Evento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('unidade_id')) {
      context.handle(
        _unidadeIdMeta,
        unidadeId.isAcceptableOrUnknown(data['unidade_id']!, _unidadeIdMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('autor')) {
      context.handle(
        _autorMeta,
        autor.isAcceptableOrUnknown(data['autor']!, _autorMeta),
      );
    }
    if (data.containsKey('tombamento')) {
      context.handle(
        _tombamentoMeta,
        tombamento.isAcceptableOrUnknown(data['tombamento']!, _tombamentoMeta),
      );
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('aparelho_id')) {
      context.handle(
        _aparelhoIdMeta,
        aparelhoId.isAcceptableOrUnknown(data['aparelho_id']!, _aparelhoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_aparelhoIdMeta);
    }
    if (data.containsKey('conferente')) {
      context.handle(
        _conferenteMeta,
        conferente.isAcceptableOrUnknown(data['conferente']!, _conferenteMeta),
      );
    } else if (isInserting) {
      context.missing(_conferenteMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('hash_foto')) {
      context.handle(
        _hashFotoMeta,
        hashFoto.isAcceptableOrUnknown(data['hash_foto']!, _hashFotoMeta),
      );
    }
    if (data.containsKey('hash_anterior')) {
      context.handle(
        _hashAnteriorMeta,
        hashAnterior.isAcceptableOrUnknown(
          data['hash_anterior']!,
          _hashAnteriorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hashAnteriorMeta);
    }
    if (data.containsKey('conhecidos')) {
      context.handle(
        _conhecidosMeta,
        conhecidos.isAcceptableOrUnknown(data['conhecidos']!, _conhecidosMeta),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('assinatura')) {
      context.handle(
        _assinaturaMeta,
        assinatura.isAcceptableOrUnknown(data['assinatura']!, _assinaturaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Evento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Evento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      unidadeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unidade_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      autor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}autor'],
      )!,
      tombamento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tombamento'],
      ),
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      aparelhoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aparelho_id'],
      )!,
      conferente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conferente'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      hashFoto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_foto'],
      ),
      hashAnterior: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_anterior'],
      )!,
      conhecidos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conhecidos'],
      )!,
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      assinatura: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assinatura'],
      )!,
    );
  }

  @override
  $EventosTable createAlias(String alias) {
    return $EventosTable(attachedDatabase, alias);
  }
}

class Evento extends DataClass implements Insertable<Evento> {
  final String id;
  final String unidadeId;
  final int seq;
  final String tipo;
  final String autor;
  final String? tombamento;
  final String localId;
  final String aparelhoId;
  final String conferente;
  final DateTime timestamp;
  final String payload;
  final String? hashFoto;
  final String hashAnterior;
  final String conhecidos;
  final String hash;
  final String assinatura;
  const Evento({
    required this.id,
    required this.unidadeId,
    required this.seq,
    required this.tipo,
    required this.autor,
    this.tombamento,
    required this.localId,
    required this.aparelhoId,
    required this.conferente,
    required this.timestamp,
    required this.payload,
    this.hashFoto,
    required this.hashAnterior,
    required this.conhecidos,
    required this.hash,
    required this.assinatura,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['unidade_id'] = Variable<String>(unidadeId);
    map['seq'] = Variable<int>(seq);
    map['tipo'] = Variable<String>(tipo);
    map['autor'] = Variable<String>(autor);
    if (!nullToAbsent || tombamento != null) {
      map['tombamento'] = Variable<String>(tombamento);
    }
    map['local_id'] = Variable<String>(localId);
    map['aparelho_id'] = Variable<String>(aparelhoId);
    map['conferente'] = Variable<String>(conferente);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || hashFoto != null) {
      map['hash_foto'] = Variable<String>(hashFoto);
    }
    map['hash_anterior'] = Variable<String>(hashAnterior);
    map['conhecidos'] = Variable<String>(conhecidos);
    map['hash'] = Variable<String>(hash);
    map['assinatura'] = Variable<String>(assinatura);
    return map;
  }

  EventosCompanion toCompanion(bool nullToAbsent) {
    return EventosCompanion(
      id: Value(id),
      unidadeId: Value(unidadeId),
      seq: Value(seq),
      tipo: Value(tipo),
      autor: Value(autor),
      tombamento: tombamento == null && nullToAbsent
          ? const Value.absent()
          : Value(tombamento),
      localId: Value(localId),
      aparelhoId: Value(aparelhoId),
      conferente: Value(conferente),
      timestamp: Value(timestamp),
      payload: Value(payload),
      hashFoto: hashFoto == null && nullToAbsent
          ? const Value.absent()
          : Value(hashFoto),
      hashAnterior: Value(hashAnterior),
      conhecidos: Value(conhecidos),
      hash: Value(hash),
      assinatura: Value(assinatura),
    );
  }

  factory Evento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Evento(
      id: serializer.fromJson<String>(json['id']),
      unidadeId: serializer.fromJson<String>(json['unidadeId']),
      seq: serializer.fromJson<int>(json['seq']),
      tipo: serializer.fromJson<String>(json['tipo']),
      autor: serializer.fromJson<String>(json['autor']),
      tombamento: serializer.fromJson<String?>(json['tombamento']),
      localId: serializer.fromJson<String>(json['localId']),
      aparelhoId: serializer.fromJson<String>(json['aparelhoId']),
      conferente: serializer.fromJson<String>(json['conferente']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      payload: serializer.fromJson<String>(json['payload']),
      hashFoto: serializer.fromJson<String?>(json['hashFoto']),
      hashAnterior: serializer.fromJson<String>(json['hashAnterior']),
      conhecidos: serializer.fromJson<String>(json['conhecidos']),
      hash: serializer.fromJson<String>(json['hash']),
      assinatura: serializer.fromJson<String>(json['assinatura']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'unidadeId': serializer.toJson<String>(unidadeId),
      'seq': serializer.toJson<int>(seq),
      'tipo': serializer.toJson<String>(tipo),
      'autor': serializer.toJson<String>(autor),
      'tombamento': serializer.toJson<String?>(tombamento),
      'localId': serializer.toJson<String>(localId),
      'aparelhoId': serializer.toJson<String>(aparelhoId),
      'conferente': serializer.toJson<String>(conferente),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'payload': serializer.toJson<String>(payload),
      'hashFoto': serializer.toJson<String?>(hashFoto),
      'hashAnterior': serializer.toJson<String>(hashAnterior),
      'conhecidos': serializer.toJson<String>(conhecidos),
      'hash': serializer.toJson<String>(hash),
      'assinatura': serializer.toJson<String>(assinatura),
    };
  }

  Evento copyWith({
    String? id,
    String? unidadeId,
    int? seq,
    String? tipo,
    String? autor,
    Value<String?> tombamento = const Value.absent(),
    String? localId,
    String? aparelhoId,
    String? conferente,
    DateTime? timestamp,
    String? payload,
    Value<String?> hashFoto = const Value.absent(),
    String? hashAnterior,
    String? conhecidos,
    String? hash,
    String? assinatura,
  }) => Evento(
    id: id ?? this.id,
    unidadeId: unidadeId ?? this.unidadeId,
    seq: seq ?? this.seq,
    tipo: tipo ?? this.tipo,
    autor: autor ?? this.autor,
    tombamento: tombamento.present ? tombamento.value : this.tombamento,
    localId: localId ?? this.localId,
    aparelhoId: aparelhoId ?? this.aparelhoId,
    conferente: conferente ?? this.conferente,
    timestamp: timestamp ?? this.timestamp,
    payload: payload ?? this.payload,
    hashFoto: hashFoto.present ? hashFoto.value : this.hashFoto,
    hashAnterior: hashAnterior ?? this.hashAnterior,
    conhecidos: conhecidos ?? this.conhecidos,
    hash: hash ?? this.hash,
    assinatura: assinatura ?? this.assinatura,
  );
  Evento copyWithCompanion(EventosCompanion data) {
    return Evento(
      id: data.id.present ? data.id.value : this.id,
      unidadeId: data.unidadeId.present ? data.unidadeId.value : this.unidadeId,
      seq: data.seq.present ? data.seq.value : this.seq,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      autor: data.autor.present ? data.autor.value : this.autor,
      tombamento: data.tombamento.present
          ? data.tombamento.value
          : this.tombamento,
      localId: data.localId.present ? data.localId.value : this.localId,
      aparelhoId: data.aparelhoId.present
          ? data.aparelhoId.value
          : this.aparelhoId,
      conferente: data.conferente.present
          ? data.conferente.value
          : this.conferente,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      payload: data.payload.present ? data.payload.value : this.payload,
      hashFoto: data.hashFoto.present ? data.hashFoto.value : this.hashFoto,
      hashAnterior: data.hashAnterior.present
          ? data.hashAnterior.value
          : this.hashAnterior,
      conhecidos: data.conhecidos.present
          ? data.conhecidos.value
          : this.conhecidos,
      hash: data.hash.present ? data.hash.value : this.hash,
      assinatura: data.assinatura.present
          ? data.assinatura.value
          : this.assinatura,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Evento(')
          ..write('id: $id, ')
          ..write('unidadeId: $unidadeId, ')
          ..write('seq: $seq, ')
          ..write('tipo: $tipo, ')
          ..write('autor: $autor, ')
          ..write('tombamento: $tombamento, ')
          ..write('localId: $localId, ')
          ..write('aparelhoId: $aparelhoId, ')
          ..write('conferente: $conferente, ')
          ..write('timestamp: $timestamp, ')
          ..write('payload: $payload, ')
          ..write('hashFoto: $hashFoto, ')
          ..write('hashAnterior: $hashAnterior, ')
          ..write('conhecidos: $conhecidos, ')
          ..write('hash: $hash, ')
          ..write('assinatura: $assinatura')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    unidadeId,
    seq,
    tipo,
    autor,
    tombamento,
    localId,
    aparelhoId,
    conferente,
    timestamp,
    payload,
    hashFoto,
    hashAnterior,
    conhecidos,
    hash,
    assinatura,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Evento &&
          other.id == this.id &&
          other.unidadeId == this.unidadeId &&
          other.seq == this.seq &&
          other.tipo == this.tipo &&
          other.autor == this.autor &&
          other.tombamento == this.tombamento &&
          other.localId == this.localId &&
          other.aparelhoId == this.aparelhoId &&
          other.conferente == this.conferente &&
          other.timestamp == this.timestamp &&
          other.payload == this.payload &&
          other.hashFoto == this.hashFoto &&
          other.hashAnterior == this.hashAnterior &&
          other.conhecidos == this.conhecidos &&
          other.hash == this.hash &&
          other.assinatura == this.assinatura);
}

class EventosCompanion extends UpdateCompanion<Evento> {
  final Value<String> id;
  final Value<String> unidadeId;
  final Value<int> seq;
  final Value<String> tipo;
  final Value<String> autor;
  final Value<String?> tombamento;
  final Value<String> localId;
  final Value<String> aparelhoId;
  final Value<String> conferente;
  final Value<DateTime> timestamp;
  final Value<String> payload;
  final Value<String?> hashFoto;
  final Value<String> hashAnterior;
  final Value<String> conhecidos;
  final Value<String> hash;
  final Value<String> assinatura;
  final Value<int> rowid;
  const EventosCompanion({
    this.id = const Value.absent(),
    this.unidadeId = const Value.absent(),
    this.seq = const Value.absent(),
    this.tipo = const Value.absent(),
    this.autor = const Value.absent(),
    this.tombamento = const Value.absent(),
    this.localId = const Value.absent(),
    this.aparelhoId = const Value.absent(),
    this.conferente = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.payload = const Value.absent(),
    this.hashFoto = const Value.absent(),
    this.hashAnterior = const Value.absent(),
    this.conhecidos = const Value.absent(),
    this.hash = const Value.absent(),
    this.assinatura = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventosCompanion.insert({
    required String id,
    this.unidadeId = const Value.absent(),
    required int seq,
    required String tipo,
    this.autor = const Value.absent(),
    this.tombamento = const Value.absent(),
    required String localId,
    required String aparelhoId,
    required String conferente,
    required DateTime timestamp,
    this.payload = const Value.absent(),
    this.hashFoto = const Value.absent(),
    required String hashAnterior,
    this.conhecidos = const Value.absent(),
    required String hash,
    this.assinatura = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seq = Value(seq),
       tipo = Value(tipo),
       localId = Value(localId),
       aparelhoId = Value(aparelhoId),
       conferente = Value(conferente),
       timestamp = Value(timestamp),
       hashAnterior = Value(hashAnterior),
       hash = Value(hash);
  static Insertable<Evento> custom({
    Expression<String>? id,
    Expression<String>? unidadeId,
    Expression<int>? seq,
    Expression<String>? tipo,
    Expression<String>? autor,
    Expression<String>? tombamento,
    Expression<String>? localId,
    Expression<String>? aparelhoId,
    Expression<String>? conferente,
    Expression<DateTime>? timestamp,
    Expression<String>? payload,
    Expression<String>? hashFoto,
    Expression<String>? hashAnterior,
    Expression<String>? conhecidos,
    Expression<String>? hash,
    Expression<String>? assinatura,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (unidadeId != null) 'unidade_id': unidadeId,
      if (seq != null) 'seq': seq,
      if (tipo != null) 'tipo': tipo,
      if (autor != null) 'autor': autor,
      if (tombamento != null) 'tombamento': tombamento,
      if (localId != null) 'local_id': localId,
      if (aparelhoId != null) 'aparelho_id': aparelhoId,
      if (conferente != null) 'conferente': conferente,
      if (timestamp != null) 'timestamp': timestamp,
      if (payload != null) 'payload': payload,
      if (hashFoto != null) 'hash_foto': hashFoto,
      if (hashAnterior != null) 'hash_anterior': hashAnterior,
      if (conhecidos != null) 'conhecidos': conhecidos,
      if (hash != null) 'hash': hash,
      if (assinatura != null) 'assinatura': assinatura,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventosCompanion copyWith({
    Value<String>? id,
    Value<String>? unidadeId,
    Value<int>? seq,
    Value<String>? tipo,
    Value<String>? autor,
    Value<String?>? tombamento,
    Value<String>? localId,
    Value<String>? aparelhoId,
    Value<String>? conferente,
    Value<DateTime>? timestamp,
    Value<String>? payload,
    Value<String?>? hashFoto,
    Value<String>? hashAnterior,
    Value<String>? conhecidos,
    Value<String>? hash,
    Value<String>? assinatura,
    Value<int>? rowid,
  }) {
    return EventosCompanion(
      id: id ?? this.id,
      unidadeId: unidadeId ?? this.unidadeId,
      seq: seq ?? this.seq,
      tipo: tipo ?? this.tipo,
      autor: autor ?? this.autor,
      tombamento: tombamento ?? this.tombamento,
      localId: localId ?? this.localId,
      aparelhoId: aparelhoId ?? this.aparelhoId,
      conferente: conferente ?? this.conferente,
      timestamp: timestamp ?? this.timestamp,
      payload: payload ?? this.payload,
      hashFoto: hashFoto ?? this.hashFoto,
      hashAnterior: hashAnterior ?? this.hashAnterior,
      conhecidos: conhecidos ?? this.conhecidos,
      hash: hash ?? this.hash,
      assinatura: assinatura ?? this.assinatura,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (unidadeId.present) {
      map['unidade_id'] = Variable<String>(unidadeId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (autor.present) {
      map['autor'] = Variable<String>(autor.value);
    }
    if (tombamento.present) {
      map['tombamento'] = Variable<String>(tombamento.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (aparelhoId.present) {
      map['aparelho_id'] = Variable<String>(aparelhoId.value);
    }
    if (conferente.present) {
      map['conferente'] = Variable<String>(conferente.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (hashFoto.present) {
      map['hash_foto'] = Variable<String>(hashFoto.value);
    }
    if (hashAnterior.present) {
      map['hash_anterior'] = Variable<String>(hashAnterior.value);
    }
    if (conhecidos.present) {
      map['conhecidos'] = Variable<String>(conhecidos.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (assinatura.present) {
      map['assinatura'] = Variable<String>(assinatura.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventosCompanion(')
          ..write('id: $id, ')
          ..write('unidadeId: $unidadeId, ')
          ..write('seq: $seq, ')
          ..write('tipo: $tipo, ')
          ..write('autor: $autor, ')
          ..write('tombamento: $tombamento, ')
          ..write('localId: $localId, ')
          ..write('aparelhoId: $aparelhoId, ')
          ..write('conferente: $conferente, ')
          ..write('timestamp: $timestamp, ')
          ..write('payload: $payload, ')
          ..write('hashFoto: $hashFoto, ')
          ..write('hashAnterior: $hashAnterior, ')
          ..write('conhecidos: $conhecidos, ')
          ..write('hash: $hash, ')
          ..write('assinatura: $assinatura, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventosQuarentenaTable extends EventosQuarentena
    with TableInfo<$EventosQuarentenaTable, EventosQuarentenaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventosQuarentenaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventoJsonMeta = const VerificationMeta(
    'eventoJson',
  );
  @override
  late final GeneratedColumn<String> eventoJson = GeneratedColumn<String>(
    'evento_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _motivoMeta = const VerificationMeta('motivo');
  @override
  late final GeneratedColumn<String> motivo = GeneratedColumn<String>(
    'motivo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, eventoJson, motivo, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eventos_quarentena';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventosQuarentenaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('evento_json')) {
      context.handle(
        _eventoJsonMeta,
        eventoJson.isAcceptableOrUnknown(data['evento_json']!, _eventoJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_eventoJsonMeta);
    }
    if (data.containsKey('motivo')) {
      context.handle(
        _motivoMeta,
        motivo.isAcceptableOrUnknown(data['motivo']!, _motivoMeta),
      );
    } else if (isInserting) {
      context.missing(_motivoMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventosQuarentenaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventosQuarentenaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evento_json'],
      )!,
      motivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivo'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $EventosQuarentenaTable createAlias(String alias) {
    return $EventosQuarentenaTable(attachedDatabase, alias);
  }
}

class EventosQuarentenaData extends DataClass
    implements Insertable<EventosQuarentenaData> {
  final String id;
  final String eventoJson;
  final String motivo;
  final DateTime timestamp;
  const EventosQuarentenaData({
    required this.id,
    required this.eventoJson,
    required this.motivo,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['evento_json'] = Variable<String>(eventoJson);
    map['motivo'] = Variable<String>(motivo);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  EventosQuarentenaCompanion toCompanion(bool nullToAbsent) {
    return EventosQuarentenaCompanion(
      id: Value(id),
      eventoJson: Value(eventoJson),
      motivo: Value(motivo),
      timestamp: Value(timestamp),
    );
  }

  factory EventosQuarentenaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventosQuarentenaData(
      id: serializer.fromJson<String>(json['id']),
      eventoJson: serializer.fromJson<String>(json['eventoJson']),
      motivo: serializer.fromJson<String>(json['motivo']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventoJson': serializer.toJson<String>(eventoJson),
      'motivo': serializer.toJson<String>(motivo),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  EventosQuarentenaData copyWith({
    String? id,
    String? eventoJson,
    String? motivo,
    DateTime? timestamp,
  }) => EventosQuarentenaData(
    id: id ?? this.id,
    eventoJson: eventoJson ?? this.eventoJson,
    motivo: motivo ?? this.motivo,
    timestamp: timestamp ?? this.timestamp,
  );
  EventosQuarentenaData copyWithCompanion(EventosQuarentenaCompanion data) {
    return EventosQuarentenaData(
      id: data.id.present ? data.id.value : this.id,
      eventoJson: data.eventoJson.present
          ? data.eventoJson.value
          : this.eventoJson,
      motivo: data.motivo.present ? data.motivo.value : this.motivo,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventosQuarentenaData(')
          ..write('id: $id, ')
          ..write('eventoJson: $eventoJson, ')
          ..write('motivo: $motivo, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventoJson, motivo, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventosQuarentenaData &&
          other.id == this.id &&
          other.eventoJson == this.eventoJson &&
          other.motivo == this.motivo &&
          other.timestamp == this.timestamp);
}

class EventosQuarentenaCompanion
    extends UpdateCompanion<EventosQuarentenaData> {
  final Value<String> id;
  final Value<String> eventoJson;
  final Value<String> motivo;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const EventosQuarentenaCompanion({
    this.id = const Value.absent(),
    this.eventoJson = const Value.absent(),
    this.motivo = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventosQuarentenaCompanion.insert({
    required String id,
    required String eventoJson,
    required String motivo,
    required DateTime timestamp,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventoJson = Value(eventoJson),
       motivo = Value(motivo),
       timestamp = Value(timestamp);
  static Insertable<EventosQuarentenaData> custom({
    Expression<String>? id,
    Expression<String>? eventoJson,
    Expression<String>? motivo,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventoJson != null) 'evento_json': eventoJson,
      if (motivo != null) 'motivo': motivo,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventosQuarentenaCompanion copyWith({
    Value<String>? id,
    Value<String>? eventoJson,
    Value<String>? motivo,
    Value<DateTime>? timestamp,
    Value<int>? rowid,
  }) {
    return EventosQuarentenaCompanion(
      id: id ?? this.id,
      eventoJson: eventoJson ?? this.eventoJson,
      motivo: motivo ?? this.motivo,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventoJson.present) {
      map['evento_json'] = Variable<String>(eventoJson.value);
    }
    if (motivo.present) {
      map['motivo'] = Variable<String>(motivo.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventosQuarentenaCompanion(')
          ..write('id: $id, ')
          ..write('eventoJson: $eventoJson, ')
          ..write('motivo: $motivo, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UnidadesTable unidades = $UnidadesTable(this);
  late final $LocaisTable locais = $LocaisTable(this);
  late final $BensTable bens = $BensTable(this);
  late final $ConferenciaSalasTable conferenciaSalas = $ConferenciaSalasTable(
    this,
  );
  late final $EventosTable eventos = $EventosTable(this);
  late final $EventosQuarentenaTable eventosQuarentena =
      $EventosQuarentenaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    unidades,
    locais,
    bens,
    conferenciaSalas,
    eventos,
    eventosQuarentena,
  ];
}

typedef $$UnidadesTableCreateCompanionBuilder = UnidadesCompanion Function({
  required String id,
  required String nome,
  required DateTime dataImportacao,
  required String arquivoOrigem,
  Value<int> rowid,
});
typedef $$UnidadesTableUpdateCompanionBuilder = UnidadesCompanion Function({
  Value<String> id,
  Value<String> nome,
  Value<DateTime> dataImportacao,
  Value<String> arquivoOrigem,
  Value<int> rowid,
});

class $$UnidadesTableFilterComposer
    extends Composer<_$AppDatabase, $UnidadesTable> {
  $$UnidadesTableFilterComposer({
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

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataImportacao => $composableBuilder(
    column: $table.dataImportacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arquivoOrigem => $composableBuilder(
    column: $table.arquivoOrigem,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnidadesTableOrderingComposer
    extends Composer<_$AppDatabase, $UnidadesTable> {
  $$UnidadesTableOrderingComposer({
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

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataImportacao => $composableBuilder(
    column: $table.dataImportacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arquivoOrigem => $composableBuilder(
    column: $table.arquivoOrigem,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnidadesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnidadesTable> {
  $$UnidadesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<DateTime> get dataImportacao => $composableBuilder(
    column: $table.dataImportacao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get arquivoOrigem => $composableBuilder(
    column: $table.arquivoOrigem,
    builder: (column) => column,
  );
}

class $$UnidadesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnidadesTable,
          Unidade,
          $$UnidadesTableFilterComposer,
          $$UnidadesTableOrderingComposer,
          $$UnidadesTableAnnotationComposer,
          $$UnidadesTableCreateCompanionBuilder,
          $$UnidadesTableUpdateCompanionBuilder,
          (Unidade, BaseReferences<_$AppDatabase, $UnidadesTable, Unidade>),
          Unidade,
          PrefetchHooks Function()
        > {
  $$UnidadesTableTableManager(_$AppDatabase db, $UnidadesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnidadesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnidadesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnidadesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<DateTime> dataImportacao = const Value.absent(),
                Value<String> arquivoOrigem = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnidadesCompanion(
                id: id,
                nome: nome,
                dataImportacao: dataImportacao,
                arquivoOrigem: arquivoOrigem,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nome,
                required DateTime dataImportacao,
                required String arquivoOrigem,
                Value<int> rowid = const Value.absent(),
              }) => UnidadesCompanion.insert(
                id: id,
                nome: nome,
                dataImportacao: dataImportacao,
                arquivoOrigem: arquivoOrigem,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UnidadesTable, Unidade>(table),
                  BaseReferences<_$AppDatabase, $UnidadesTable, Unidade>(
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

typedef $$UnidadesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnidadesTable,
      Unidade,
      $$UnidadesTableFilterComposer,
      $$UnidadesTableOrderingComposer,
      $$UnidadesTableAnnotationComposer,
      $$UnidadesTableCreateCompanionBuilder,
      $$UnidadesTableUpdateCompanionBuilder,
      (Unidade, BaseReferences<_$AppDatabase, $UnidadesTable, Unidade>),
      Unidade,
      PrefetchHooks Function()
    >;
typedef $$LocaisTableCreateCompanionBuilder = LocaisCompanion Function({
  required String id,
  required String unidadeId,
  required String nome,
  required String tipo,
  Value<String?> paiId,
  required String caminhoCompleto,
  Value<int> rowid,
});
typedef $$LocaisTableUpdateCompanionBuilder = LocaisCompanion Function({
  Value<String> id,
  Value<String> unidadeId,
  Value<String> nome,
  Value<String> tipo,
  Value<String?> paiId,
  Value<String> caminhoCompleto,
  Value<int> rowid,
});

class $$LocaisTableFilterComposer
    extends Composer<_$AppDatabase, $LocaisTable> {
  $$LocaisTableFilterComposer({
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

  ColumnFilters<String> get unidadeId => $composableBuilder(
    column: $table.unidadeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paiId => $composableBuilder(
    column: $table.paiId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caminhoCompleto => $composableBuilder(
    column: $table.caminhoCompleto,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocaisTableOrderingComposer
    extends Composer<_$AppDatabase, $LocaisTable> {
  $$LocaisTableOrderingComposer({
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

  ColumnOrderings<String> get unidadeId => $composableBuilder(
    column: $table.unidadeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paiId => $composableBuilder(
    column: $table.paiId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caminhoCompleto => $composableBuilder(
    column: $table.caminhoCompleto,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocaisTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocaisTable> {
  $$LocaisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get unidadeId =>
      $composableBuilder(column: $table.unidadeId, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get paiId =>
      $composableBuilder(column: $table.paiId, builder: (column) => column);

  GeneratedColumn<String> get caminhoCompleto => $composableBuilder(
    column: $table.caminhoCompleto,
    builder: (column) => column,
  );
}

class $$LocaisTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocaisTable,
          Local,
          $$LocaisTableFilterComposer,
          $$LocaisTableOrderingComposer,
          $$LocaisTableAnnotationComposer,
          $$LocaisTableCreateCompanionBuilder,
          $$LocaisTableUpdateCompanionBuilder,
          (Local, BaseReferences<_$AppDatabase, $LocaisTable, Local>),
          Local,
          PrefetchHooks Function()
        > {
  $$LocaisTableTableManager(_$AppDatabase db, $LocaisTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocaisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocaisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocaisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> unidadeId = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String?> paiId = const Value.absent(),
                Value<String> caminhoCompleto = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocaisCompanion(
                id: id,
                unidadeId: unidadeId,
                nome: nome,
                tipo: tipo,
                paiId: paiId,
                caminhoCompleto: caminhoCompleto,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String unidadeId,
                required String nome,
                required String tipo,
                Value<String?> paiId = const Value.absent(),
                required String caminhoCompleto,
                Value<int> rowid = const Value.absent(),
              }) => LocaisCompanion.insert(
                id: id,
                unidadeId: unidadeId,
                nome: nome,
                tipo: tipo,
                paiId: paiId,
                caminhoCompleto: caminhoCompleto,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocaisTable, Local>(table),
                  BaseReferences<_$AppDatabase, $LocaisTable, Local>(
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

typedef $$LocaisTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocaisTable,
      Local,
      $$LocaisTableFilterComposer,
      $$LocaisTableOrderingComposer,
      $$LocaisTableAnnotationComposer,
      $$LocaisTableCreateCompanionBuilder,
      $$LocaisTableUpdateCompanionBuilder,
      (Local, BaseReferences<_$AppDatabase, $LocaisTable, Local>),
      Local,
      PrefetchHooks Function()
    >;
typedef $$BensTableCreateCompanionBuilder = BensCompanion Function({
  required String tombamento,
  required String unidadeId,
  required String descricao,
  Value<String?> categoria,
  required String localEsperadoId,
  Value<String?> responsavel,
  Value<String?> numeroSerie,
  Value<String?> fabricante,
  Value<String?> modelo,
  Value<String?> extras,
  Value<int> rowid,
});
typedef $$BensTableUpdateCompanionBuilder = BensCompanion Function({
  Value<String> tombamento,
  Value<String> unidadeId,
  Value<String> descricao,
  Value<String?> categoria,
  Value<String> localEsperadoId,
  Value<String?> responsavel,
  Value<String?> numeroSerie,
  Value<String?> fabricante,
  Value<String?> modelo,
  Value<String?> extras,
  Value<int> rowid,
});

class $$BensTableFilterComposer extends Composer<_$AppDatabase, $BensTable> {
  $$BensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tombamento => $composableBuilder(
    column: $table.tombamento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unidadeId => $composableBuilder(
    column: $table.unidadeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localEsperadoId => $composableBuilder(
    column: $table.localEsperadoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responsavel => $composableBuilder(
    column: $table.responsavel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numeroSerie => $composableBuilder(
    column: $table.numeroSerie,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fabricante => $composableBuilder(
    column: $table.fabricante,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelo => $composableBuilder(
    column: $table.modelo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extras => $composableBuilder(
    column: $table.extras,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BensTableOrderingComposer extends Composer<_$AppDatabase, $BensTable> {
  $$BensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tombamento => $composableBuilder(
    column: $table.tombamento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unidadeId => $composableBuilder(
    column: $table.unidadeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localEsperadoId => $composableBuilder(
    column: $table.localEsperadoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responsavel => $composableBuilder(
    column: $table.responsavel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numeroSerie => $composableBuilder(
    column: $table.numeroSerie,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fabricante => $composableBuilder(
    column: $table.fabricante,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelo => $composableBuilder(
    column: $table.modelo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extras => $composableBuilder(
    column: $table.extras,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BensTableAnnotationComposer
    extends Composer<_$AppDatabase, $BensTable> {
  $$BensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tombamento => $composableBuilder(
    column: $table.tombamento,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unidadeId =>
      $composableBuilder(column: $table.unidadeId, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<String> get localEsperadoId => $composableBuilder(
    column: $table.localEsperadoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responsavel => $composableBuilder(
    column: $table.responsavel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get numeroSerie => $composableBuilder(
    column: $table.numeroSerie,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fabricante => $composableBuilder(
    column: $table.fabricante,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelo =>
      $composableBuilder(column: $table.modelo, builder: (column) => column);

  GeneratedColumn<String> get extras =>
      $composableBuilder(column: $table.extras, builder: (column) => column);
}

class $$BensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BensTable,
          Bem,
          $$BensTableFilterComposer,
          $$BensTableOrderingComposer,
          $$BensTableAnnotationComposer,
          $$BensTableCreateCompanionBuilder,
          $$BensTableUpdateCompanionBuilder,
          (Bem, BaseReferences<_$AppDatabase, $BensTable, Bem>),
          Bem,
          PrefetchHooks Function()
        > {
  $$BensTableTableManager(_$AppDatabase db, $BensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tombamento = const Value.absent(),
                Value<String> unidadeId = const Value.absent(),
                Value<String> descricao = const Value.absent(),
                Value<String?> categoria = const Value.absent(),
                Value<String> localEsperadoId = const Value.absent(),
                Value<String?> responsavel = const Value.absent(),
                Value<String?> numeroSerie = const Value.absent(),
                Value<String?> fabricante = const Value.absent(),
                Value<String?> modelo = const Value.absent(),
                Value<String?> extras = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BensCompanion(
                tombamento: tombamento,
                unidadeId: unidadeId,
                descricao: descricao,
                categoria: categoria,
                localEsperadoId: localEsperadoId,
                responsavel: responsavel,
                numeroSerie: numeroSerie,
                fabricante: fabricante,
                modelo: modelo,
                extras: extras,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tombamento,
                required String unidadeId,
                required String descricao,
                Value<String?> categoria = const Value.absent(),
                required String localEsperadoId,
                Value<String?> responsavel = const Value.absent(),
                Value<String?> numeroSerie = const Value.absent(),
                Value<String?> fabricante = const Value.absent(),
                Value<String?> modelo = const Value.absent(),
                Value<String?> extras = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BensCompanion.insert(
                tombamento: tombamento,
                unidadeId: unidadeId,
                descricao: descricao,
                categoria: categoria,
                localEsperadoId: localEsperadoId,
                responsavel: responsavel,
                numeroSerie: numeroSerie,
                fabricante: fabricante,
                modelo: modelo,
                extras: extras,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BensTable, Bem>(table),
                  BaseReferences<_$AppDatabase, $BensTable, Bem>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BensTable,
      Bem,
      $$BensTableFilterComposer,
      $$BensTableOrderingComposer,
      $$BensTableAnnotationComposer,
      $$BensTableCreateCompanionBuilder,
      $$BensTableUpdateCompanionBuilder,
      (Bem, BaseReferences<_$AppDatabase, $BensTable, Bem>),
      Bem,
      PrefetchHooks Function()
    >;
typedef $$ConferenciaSalasTableCreateCompanionBuilder =
    ConferenciaSalasCompanion Function({
      required String localId,
      Value<String> status,
      Value<DateTime?> inicio,
      Value<DateTime?> fim,
      Value<String?> conferente,
      Value<int> rowid,
    });
typedef $$ConferenciaSalasTableUpdateCompanionBuilder =
    ConferenciaSalasCompanion Function({
      Value<String> localId,
      Value<String> status,
      Value<DateTime?> inicio,
      Value<DateTime?> fim,
      Value<String?> conferente,
      Value<int> rowid,
    });

class $$ConferenciaSalasTableFilterComposer
    extends Composer<_$AppDatabase, $ConferenciaSalasTable> {
  $$ConferenciaSalasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get inicio => $composableBuilder(
    column: $table.inicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fim => $composableBuilder(
    column: $table.fim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conferente => $composableBuilder(
    column: $table.conferente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConferenciaSalasTableOrderingComposer
    extends Composer<_$AppDatabase, $ConferenciaSalasTable> {
  $$ConferenciaSalasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get inicio => $composableBuilder(
    column: $table.inicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fim => $composableBuilder(
    column: $table.fim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conferente => $composableBuilder(
    column: $table.conferente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConferenciaSalasTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConferenciaSalasTable> {
  $$ConferenciaSalasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get inicio =>
      $composableBuilder(column: $table.inicio, builder: (column) => column);

  GeneratedColumn<DateTime> get fim =>
      $composableBuilder(column: $table.fim, builder: (column) => column);

  GeneratedColumn<String> get conferente => $composableBuilder(
    column: $table.conferente,
    builder: (column) => column,
  );
}

class $$ConferenciaSalasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConferenciaSalasTable,
          ConferenciaSala,
          $$ConferenciaSalasTableFilterComposer,
          $$ConferenciaSalasTableOrderingComposer,
          $$ConferenciaSalasTableAnnotationComposer,
          $$ConferenciaSalasTableCreateCompanionBuilder,
          $$ConferenciaSalasTableUpdateCompanionBuilder,
          (
            ConferenciaSala,
            BaseReferences<
              _$AppDatabase,
              $ConferenciaSalasTable,
              ConferenciaSala
            >,
          ),
          ConferenciaSala,
          PrefetchHooks Function()
        > {
  $$ConferenciaSalasTableTableManager(
    _$AppDatabase db,
    $ConferenciaSalasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConferenciaSalasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConferenciaSalasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConferenciaSalasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> inicio = const Value.absent(),
                Value<DateTime?> fim = const Value.absent(),
                Value<String?> conferente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConferenciaSalasCompanion(
                localId: localId,
                status: status,
                inicio: inicio,
                fim: fim,
                conferente: conferente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String> status = const Value.absent(),
                Value<DateTime?> inicio = const Value.absent(),
                Value<DateTime?> fim = const Value.absent(),
                Value<String?> conferente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConferenciaSalasCompanion.insert(
                localId: localId,
                status: status,
                inicio: inicio,
                fim: fim,
                conferente: conferente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConferenciaSalasTable, ConferenciaSala>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ConferenciaSalasTable,
                    ConferenciaSala
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConferenciaSalasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConferenciaSalasTable,
      ConferenciaSala,
      $$ConferenciaSalasTableFilterComposer,
      $$ConferenciaSalasTableOrderingComposer,
      $$ConferenciaSalasTableAnnotationComposer,
      $$ConferenciaSalasTableCreateCompanionBuilder,
      $$ConferenciaSalasTableUpdateCompanionBuilder,
      (
        ConferenciaSala,
        BaseReferences<_$AppDatabase, $ConferenciaSalasTable, ConferenciaSala>,
      ),
      ConferenciaSala,
      PrefetchHooks Function()
    >;
typedef $$EventosTableCreateCompanionBuilder = EventosCompanion Function({
  required String id,
  Value<String> unidadeId,
  required int seq,
  required String tipo,
  Value<String> autor,
  Value<String?> tombamento,
  required String localId,
  required String aparelhoId,
  required String conferente,
  required DateTime timestamp,
  Value<String> payload,
  Value<String?> hashFoto,
  required String hashAnterior,
  Value<String> conhecidos,
  required String hash,
  Value<String> assinatura,
  Value<int> rowid,
});
typedef $$EventosTableUpdateCompanionBuilder = EventosCompanion Function({
  Value<String> id,
  Value<String> unidadeId,
  Value<int> seq,
  Value<String> tipo,
  Value<String> autor,
  Value<String?> tombamento,
  Value<String> localId,
  Value<String> aparelhoId,
  Value<String> conferente,
  Value<DateTime> timestamp,
  Value<String> payload,
  Value<String?> hashFoto,
  Value<String> hashAnterior,
  Value<String> conhecidos,
  Value<String> hash,
  Value<String> assinatura,
  Value<int> rowid,
});

class $$EventosTableFilterComposer
    extends Composer<_$AppDatabase, $EventosTable> {
  $$EventosTableFilterComposer({
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

  ColumnFilters<String> get unidadeId => $composableBuilder(
    column: $table.unidadeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get autor => $composableBuilder(
    column: $table.autor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tombamento => $composableBuilder(
    column: $table.tombamento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aparelhoId => $composableBuilder(
    column: $table.aparelhoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conferente => $composableBuilder(
    column: $table.conferente,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashFoto => $composableBuilder(
    column: $table.hashFoto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashAnterior => $composableBuilder(
    column: $table.hashAnterior,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conhecidos => $composableBuilder(
    column: $table.conhecidos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assinatura => $composableBuilder(
    column: $table.assinatura,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventosTableOrderingComposer
    extends Composer<_$AppDatabase, $EventosTable> {
  $$EventosTableOrderingComposer({
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

  ColumnOrderings<String> get unidadeId => $composableBuilder(
    column: $table.unidadeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get autor => $composableBuilder(
    column: $table.autor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tombamento => $composableBuilder(
    column: $table.tombamento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aparelhoId => $composableBuilder(
    column: $table.aparelhoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conferente => $composableBuilder(
    column: $table.conferente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashFoto => $composableBuilder(
    column: $table.hashFoto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashAnterior => $composableBuilder(
    column: $table.hashAnterior,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conhecidos => $composableBuilder(
    column: $table.conhecidos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assinatura => $composableBuilder(
    column: $table.assinatura,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventosTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventosTable> {
  $$EventosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get unidadeId =>
      $composableBuilder(column: $table.unidadeId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get autor =>
      $composableBuilder(column: $table.autor, builder: (column) => column);

  GeneratedColumn<String> get tombamento => $composableBuilder(
    column: $table.tombamento,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get aparelhoId => $composableBuilder(
    column: $table.aparelhoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conferente => $composableBuilder(
    column: $table.conferente,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get hashFoto =>
      $composableBuilder(column: $table.hashFoto, builder: (column) => column);

  GeneratedColumn<String> get hashAnterior => $composableBuilder(
    column: $table.hashAnterior,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conhecidos => $composableBuilder(
    column: $table.conhecidos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get assinatura => $composableBuilder(
    column: $table.assinatura,
    builder: (column) => column,
  );
}

class $$EventosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventosTable,
          Evento,
          $$EventosTableFilterComposer,
          $$EventosTableOrderingComposer,
          $$EventosTableAnnotationComposer,
          $$EventosTableCreateCompanionBuilder,
          $$EventosTableUpdateCompanionBuilder,
          (Evento, BaseReferences<_$AppDatabase, $EventosTable, Evento>),
          Evento,
          PrefetchHooks Function()
        > {
  $$EventosTableTableManager(_$AppDatabase db, $EventosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> unidadeId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> autor = const Value.absent(),
                Value<String?> tombamento = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String> aparelhoId = const Value.absent(),
                Value<String> conferente = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> hashFoto = const Value.absent(),
                Value<String> hashAnterior = const Value.absent(),
                Value<String> conhecidos = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> assinatura = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventosCompanion(
                id: id,
                unidadeId: unidadeId,
                seq: seq,
                tipo: tipo,
                autor: autor,
                tombamento: tombamento,
                localId: localId,
                aparelhoId: aparelhoId,
                conferente: conferente,
                timestamp: timestamp,
                payload: payload,
                hashFoto: hashFoto,
                hashAnterior: hashAnterior,
                conhecidos: conhecidos,
                hash: hash,
                assinatura: assinatura,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> unidadeId = const Value.absent(),
                required int seq,
                required String tipo,
                Value<String> autor = const Value.absent(),
                Value<String?> tombamento = const Value.absent(),
                required String localId,
                required String aparelhoId,
                required String conferente,
                required DateTime timestamp,
                Value<String> payload = const Value.absent(),
                Value<String?> hashFoto = const Value.absent(),
                required String hashAnterior,
                Value<String> conhecidos = const Value.absent(),
                required String hash,
                Value<String> assinatura = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventosCompanion.insert(
                id: id,
                unidadeId: unidadeId,
                seq: seq,
                tipo: tipo,
                autor: autor,
                tombamento: tombamento,
                localId: localId,
                aparelhoId: aparelhoId,
                conferente: conferente,
                timestamp: timestamp,
                payload: payload,
                hashFoto: hashFoto,
                hashAnterior: hashAnterior,
                conhecidos: conhecidos,
                hash: hash,
                assinatura: assinatura,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventosTable, Evento>(table),
                  BaseReferences<_$AppDatabase, $EventosTable, Evento>(
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

typedef $$EventosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventosTable,
      Evento,
      $$EventosTableFilterComposer,
      $$EventosTableOrderingComposer,
      $$EventosTableAnnotationComposer,
      $$EventosTableCreateCompanionBuilder,
      $$EventosTableUpdateCompanionBuilder,
      (Evento, BaseReferences<_$AppDatabase, $EventosTable, Evento>),
      Evento,
      PrefetchHooks Function()
    >;
typedef $$EventosQuarentenaTableCreateCompanionBuilder =
    EventosQuarentenaCompanion Function({
      required String id,
      required String eventoJson,
      required String motivo,
      required DateTime timestamp,
      Value<int> rowid,
    });
typedef $$EventosQuarentenaTableUpdateCompanionBuilder =
    EventosQuarentenaCompanion Function({
      Value<String> id,
      Value<String> eventoJson,
      Value<String> motivo,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });

class $$EventosQuarentenaTableFilterComposer
    extends Composer<_$AppDatabase, $EventosQuarentenaTable> {
  $$EventosQuarentenaTableFilterComposer({
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

  ColumnFilters<String> get eventoJson => $composableBuilder(
    column: $table.eventoJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventosQuarentenaTableOrderingComposer
    extends Composer<_$AppDatabase, $EventosQuarentenaTable> {
  $$EventosQuarentenaTableOrderingComposer({
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

  ColumnOrderings<String> get eventoJson => $composableBuilder(
    column: $table.eventoJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventosQuarentenaTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventosQuarentenaTable> {
  $$EventosQuarentenaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventoJson => $composableBuilder(
    column: $table.eventoJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motivo =>
      $composableBuilder(column: $table.motivo, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$EventosQuarentenaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventosQuarentenaTable,
          EventosQuarentenaData,
          $$EventosQuarentenaTableFilterComposer,
          $$EventosQuarentenaTableOrderingComposer,
          $$EventosQuarentenaTableAnnotationComposer,
          $$EventosQuarentenaTableCreateCompanionBuilder,
          $$EventosQuarentenaTableUpdateCompanionBuilder,
          (
            EventosQuarentenaData,
            BaseReferences<
              _$AppDatabase,
              $EventosQuarentenaTable,
              EventosQuarentenaData
            >,
          ),
          EventosQuarentenaData,
          PrefetchHooks Function()
        > {
  $$EventosQuarentenaTableTableManager(
    _$AppDatabase db,
    $EventosQuarentenaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventosQuarentenaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventosQuarentenaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventosQuarentenaTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventoJson = const Value.absent(),
                Value<String> motivo = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventosQuarentenaCompanion(
                id: id,
                eventoJson: eventoJson,
                motivo: motivo,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventoJson,
                required String motivo,
                required DateTime timestamp,
                Value<int> rowid = const Value.absent(),
              }) => EventosQuarentenaCompanion.insert(
                id: id,
                eventoJson: eventoJson,
                motivo: motivo,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventosQuarentenaTable, EventosQuarentenaData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $EventosQuarentenaTable,
                    EventosQuarentenaData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventosQuarentenaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventosQuarentenaTable,
      EventosQuarentenaData,
      $$EventosQuarentenaTableFilterComposer,
      $$EventosQuarentenaTableOrderingComposer,
      $$EventosQuarentenaTableAnnotationComposer,
      $$EventosQuarentenaTableCreateCompanionBuilder,
      $$EventosQuarentenaTableUpdateCompanionBuilder,
      (
        EventosQuarentenaData,
        BaseReferences<
          _$AppDatabase,
          $EventosQuarentenaTable,
          EventosQuarentenaData
        >,
      ),
      EventosQuarentenaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UnidadesTableTableManager get unidades =>
      $$UnidadesTableTableManager(_db, _db.unidades);
  $$LocaisTableTableManager get locais =>
      $$LocaisTableTableManager(_db, _db.locais);
  $$BensTableTableManager get bens => $$BensTableTableManager(_db, _db.bens);
  $$ConferenciaSalasTableTableManager get conferenciaSalas =>
      $$ConferenciaSalasTableTableManager(_db, _db.conferenciaSalas);
  $$EventosTableTableManager get eventos =>
      $$EventosTableTableManager(_db, _db.eventos);
  $$EventosQuarentenaTableTableManager get eventosQuarentena =>
      $$EventosQuarentenaTableTableManager(_db, _db.eventosQuarentena);
}
