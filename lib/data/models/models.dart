import 'dart:convert';

// 1. USUARIOS
class Usuario {
  final String id;
  final String nome;
  final String email;
  final String? fotoUrl;
  final String unidadeCarga; // 'kg' ou 'lb'
  final int descansoPadrao; // em segundos
  final DateTime criadoEm;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.fotoUrl,
    this.unidadeCarga = 'kg',
    this.descansoPadrao = 60,
    required this.criadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'foto_url': fotoUrl,
      'unidade_carga': unidadeCarga,
      'descanso_padrao': descansoPadrao,
      'criado_em': criadoEm.toIso8601String(),
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] ?? '',
      nome: map['nome'] ?? 'Atleta',
      email: map['email'] ?? '',
      fotoUrl: map['foto_url'],
      unidadeCarga: map['unidade_carga'] ?? 'kg',
      descansoPadrao: map['descanso_padrao'] ?? 60,
      criadoEm: map['criado_em'] != null 
          ? DateTime.parse(map['criado_em']) 
          : DateTime.now(),
    );
  }
}

// 2. EXERCICIOS
class Exercicio {
  final String id;
  final String? exerciseDbId;
  final String nome;
  final String? nomeOriginal;
  final String grupoMuscular; // Peito, Costas, Pernas, Ombros, Bíceps, Tríceps, Abdômen, Corpo inteiro, Mobilidade
  final String? parteCorpoOriginal;
  final String? musculoPrincipalOriginal;
  final String musculosAuxiliares;
  final String equipamento; // Halteres, Barra, Máquina, Peso corporal, etc.
  final String? equipamentoOriginal;
  final String instrucoes;
  final String cuidados;
  final String? gifUrl;
  final String? videoUrl;
  final String? imagemUrl;
  final bool personalizado;
  final String? usuarioId;
  final bool isFavorito;

  Exercicio({
    required this.id,
    this.exerciseDbId,
    required this.nome,
    this.nomeOriginal,
    required this.grupoMuscular,
    this.parteCorpoOriginal,
    this.musculoPrincipalOriginal,
    this.musculosAuxiliares = '',
    required this.equipamento,
    this.equipamentoOriginal,
    required this.instrucoes,
    this.cuidados = '',
    this.gifUrl,
    this.videoUrl,
    this.imagemUrl,
    this.personalizado = false,
    this.usuarioId,
    this.isFavorito = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_db_id': exerciseDbId,
      'nome': nome,
      'nome_original': nomeOriginal,
      'grupo_muscular': grupoMuscular,
      'parte_corpo_original': parteCorpoOriginal,
      'musculo_principal_original': musculoPrincipalOriginal,
      'musculos_auxiliares': musculosAuxiliares,
      'equipamento': equipamento,
      'equipamento_original': equipamentoOriginal,
      'instrucoes': instrucoes,
      'cuidados': cuidados,
      'gif_url': gifUrl,
      'video_url': videoUrl,
      'imagem_url': imagemUrl,
      'personalizado': personalizado ? 1 : 0,
      'usuario_id': usuarioId,
      'is_favorito': isFavorito ? 1 : 0,
    };
  }

  factory Exercicio.fromMap(Map<String, dynamic> map) {
    return Exercicio(
      id: map['id'] ?? '',
      exerciseDbId: map['exercise_db_id'],
      nome: map['nome_traduzido'] ?? map['nome'] ?? '',
      nomeOriginal: map['nome_original'],
      grupoMuscular: map['parte_corpo_traduzida'] ?? map['grupo_muscular'] ?? 'Geral',
      parteCorpoOriginal: map['parte_corpo_original'],
      musculoPrincipalOriginal: map['musculo_principal_original'],
      musculosAuxiliares: map['musculos_secundarios'] ?? map['musculos_auxiliares'] ?? '',
      equipamento: map['equipamento_traduzido'] ?? map['equipamento'] ?? 'Nenhum',
      equipamentoOriginal: map['equipamento_original'],
      instrucoes: map['instrucoes'] ?? '',
      cuidados: map['cuidados'] ?? '',
      gifUrl: map['gif_url'],
      videoUrl: map['video_url'],
      imagemUrl: map['imagem_url'],
      personalizado: map['personalizado'] == 1 || map['personalizado'] == true,
      usuarioId: map['usuario_id'],
      isFavorito: map['is_favorito'] == 1 || map['is_favorito'] == true || map['favorito'] == 1 || map['favorito'] == true,
    );
  }

  Exercicio copyWith({bool? isFavorito}) {
    return Exercicio(
      id: id,
      exerciseDbId: exerciseDbId,
      nome: nome,
      nomeOriginal: nomeOriginal,
      grupoMuscular: grupoMuscular,
      parteCorpoOriginal: parteCorpoOriginal,
      musculoPrincipalOriginal: musculoPrincipalOriginal,
      musculosAuxiliares: musculosAuxiliares,
      equipamento: equipamento,
      equipamentoOriginal: equipamentoOriginal,
      instrucoes: instrucoes,
      cuidados: cuidados,
      gifUrl: gifUrl,
      videoUrl: videoUrl,
      imagemUrl: imagemUrl,
      personalizado: personalizado,
      usuarioId: usuarioId,
      isFavorito: isFavorito ?? this.isFavorito,
    );
  }
}

// 3. TREINOS (Fichas / Divisões)
class Treino {
  final String id;
  final String usuarioId;
  final String nome; // Ex: Treino A - Peito e Tríceps
  final String descricao;
  final List<String> diasSemana; // ['Segunda', 'Quinta']
  final String corHex; // Hex string Ex: '#1E88E5'
  final DateTime criadoEm;
  final List<ExercicioDoTreino> exercicios;

  Treino({
    required this.id,
    required this.usuarioId,
    required this.nome,
    this.descricao = '',
    required this.diasSemana,
    this.corHex = '#1E88E5',
    required this.criadoEm,
    this.exercicios = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nome': nome,
      'descricao': descricao,
      'dias_semana': jsonEncode(diasSemana),
      'cor_hex': corHex,
      'criado_em': criadoEm.toIso8601String(),
    };
  }

  factory Treino.fromMap(Map<String, dynamic> map, {List<ExercicioDoTreino>? exercicios}) {
    List<String> dias = [];
    if (map['dias_semana'] != null) {
      try {
        if (map['dias_semana'] is List) {
          dias = List<String>.from(map['dias_semana']);
        } else {
          dias = List<String>.from(jsonDecode(map['dias_semana']));
        }
      } catch (_) {}
    }

    return Treino(
      id: map['id'] ?? '',
      usuarioId: map['usuario_id'] ?? '',
      nome: map['nome'] ?? 'Treino',
      descricao: map['descricao'] ?? '',
      diasSemana: dias,
      corHex: map['cor_hex'] ?? '#1E88E5',
      criadoEm: map['criado_em'] != null ? DateTime.parse(map['criado_em']) : DateTime.now(),
      exercicios: exercicios ?? [],
    );
  }
}

// 4. EXERCICIOS DO TREINO
class ExercicioDoTreino {
  final String id;
  final String treinoId;
  final String exercicioId;
  final int ordem;
  final int? quantidadeSeries;
  final String? repeticoes;
  final double? cargaInicial;
  final int? descansoSegundos;
  final String? observacoes;
  final Exercicio? exercicioInfo;

  ExercicioDoTreino({
    required this.id,
    required this.treinoId,
    required this.exercicioId,
    required this.ordem,
    this.quantidadeSeries,
    this.repeticoes,
    this.cargaInicial,
    this.descansoSegundos,
    this.observacoes,
    this.exercicioInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'treino_id': treinoId,
      'exercicio_id': exercicioId,
      'ordem': ordem,
      'quantidade_series': quantidadeSeries,
      'repeticoes': repeticoes,
      'carga_inicial': cargaInicial,
      'descanso_segundos': descansoSegundos,
      'observacoes': observacoes,
    };
  }

  factory ExercicioDoTreino.fromMap(Map<String, dynamic> map, {Exercicio? exercicioInfo}) {
    return ExercicioDoTreino(
      id: map['id'] ?? '',
      treinoId: map['treino_id'] ?? '',
      exercicioId: map['exercicio_id'] ?? '',
      ordem: map['ordem'] ?? 0,
      quantidadeSeries: map['quantidade_series'],
      repeticoes: map['repeticoes'],
      cargaInicial: map['carga_inicial'] != null ? (map['carga_inicial'] as num).toDouble() : null,
      descansoSegundos: map['descanso_segundos'],
      observacoes: map['observacoes'],
      exercicioInfo: exercicioInfo,
    );
  }
}

// 5. SESSOES DE TREINO
class SessaoTreino {
  final String id;
  final String usuarioId;
  final String treinoId;
  final String nomeTreino;
  final DateTime inicio;
  final DateTime? fim;
  final String observacoes;
  final bool concluido;

  SessaoTreino({
    required this.id,
    required this.usuarioId,
    required this.treinoId,
    required this.nomeTreino,
    required this.inicio,
    this.fim,
    this.observacoes = '',
    this.concluido = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'treino_id': treinoId,
      'nome_treino': nomeTreino,
      'inicio': inicio.toIso8601String(),
      'fim': fim?.toIso8601String(),
      'observacoes': observacoes,
      'concluido': concluido ? 1 : 0,
    };
  }

  factory SessaoTreino.fromMap(Map<String, dynamic> map) {
    return SessaoTreino(
      id: map['id'] ?? '',
      usuarioId: map['usuario_id'] ?? '',
      treinoId: map['treino_id'] ?? '',
      nomeTreino: map['nome_treino'] ?? 'Treino Realizado',
      inicio: map['inicio'] != null ? DateTime.parse(map['inicio']) : DateTime.now(),
      fim: map['fim'] != null ? DateTime.parse(map['fim']) : null,
      observacoes: map['observacoes'] ?? '',
      concluido: map['concluido'] == 1 || map['concluido'] == true,
    );
  }
}

// 6. SERIES REALIZADAS
class SerieRealizada {
  final String id;
  final String sessaoId;
  final String exercicioId;
  final int numeroSerie;
  final double carga;
  final int repeticoes;
  final bool concluida;

  SerieRealizada({
    required this.id,
    required this.sessaoId,
    required this.exercicioId,
    required this.numeroSerie,
    required this.carga,
    required this.repeticoes,
    this.concluida = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessao_id': sessaoId,
      'exercicio_id': exercicioId,
      'numero_serie': numeroSerie,
      'carga': carga,
      'repeticoes': repeticoes,
      'concluida': concluida ? 1 : 0,
    };
  }

  factory SerieRealizada.fromMap(Map<String, dynamic> map) {
    return SerieRealizada(
      id: map['id'] ?? '',
      sessaoId: map['sessao_id'] ?? '',
      exercicioId: map['exercicio_id'] ?? '',
      numeroSerie: map['numero_serie'] ?? 1,
      carga: (map['carga'] ?? 0.0).toDouble(),
      repeticoes: map['repeticoes'] ?? 0,
      concluida: map['concluida'] == 1 || map['concluida'] == true,
    );
  }
}
