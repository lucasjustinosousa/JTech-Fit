import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/models.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('jtech_fit_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabela Usuarios
    await db.execute('''
      CREATE TABLE usuarios (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        email TEXT NOT NULL,
        foto_url TEXT,
        unidade_carga TEXT DEFAULT 'kg',
        descanso_padrao INTEGER DEFAULT 60,
        criado_em TEXT NOT NULL
      )
    ''');

    // 2. Tabela Exercicios
    await db.execute('''
      CREATE TABLE exercicios (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        grupo_muscular TEXT NOT NULL,
        musculos_auxiliares TEXT,
        equipamento TEXT NOT NULL,
        instrucoes TEXT NOT NULL,
        cuidados TEXT,
        video_url TEXT,
        imagem_url TEXT,
        personalizado INTEGER DEFAULT 0,
        usuario_id TEXT,
        is_favorito INTEGER DEFAULT 0
      )
    ''');

    // 3. Tabela Treinos
    await db.execute('''
      CREATE TABLE treinos (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        descricao TEXT,
        dias_semana TEXT NOT NULL,
        cor_hex TEXT DEFAULT '#1E88E5',
        criado_em TEXT NOT NULL
      )
    ''');

    // 4. Tabela Exercicios do Treino
    await db.execute('''
      CREATE TABLE exercicios_do_treino (
        id TEXT PRIMARY KEY,
        treino_id TEXT NOT NULL,
        exercicio_id TEXT NOT NULL,
        ordem INTEGER NOT NULL,
        quantidade_series INTEGER DEFAULT 4,
        repeticoes TEXT DEFAULT '10-12',
        carga_inicial REAL DEFAULT 0.0,
        descanso_segundos INTEGER DEFAULT 60,
        observacoes TEXT
      )
    ''');

    // 5. Tabela Sessoes de Treino
    await db.execute('''
      CREATE TABLE sessoes_de_treino (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        treino_id TEXT NOT NULL,
        nome_treino TEXT NOT NULL,
        inicio TEXT NOT NULL,
        fim TEXT,
        observacoes TEXT,
        concluido INTEGER DEFAULT 0
      )
    ''');

    // 6. Tabela Series Realizadas
    await db.execute('''
      CREATE TABLE series_realizadas (
        id TEXT PRIMARY KEY,
        sessao_id TEXT NOT NULL,
        exercicio_id TEXT NOT NULL,
        numero_serie INTEGER NOT NULL,
        carga REAL NOT NULL,
        repeticoes INTEGER NOT NULL,
        concluida INTEGER DEFAULT 0
      )
    ''');

    // Popular biblioteca inicial de exercícios padrão em PT-BR
    await _seedExerciseLibrary(db);
  }

  Future<void> _seedExerciseLibrary(Database db) async {
    final seedExercises = [
      // Peito
      Exercicio(
        id: 'ex_peito_1',
        nome: 'Supino Reto com Barra',
        grupoMuscular: 'Peito',
        musculosAuxiliares: 'Tríceps, Deltoide Anterior',
        equipamento: 'Barra e Banco Reto',
        instrucoes: 'Deite-se no banco, segure a barra um pouco além da largura dos ombros. Desça a barra até a linha do tórax e empurre firmemente até a extensão completa dos braços.',
        cuidados: 'Mantenha os escápulas aduzidas e os pés firmes no chão. Evite rebater a barra no peito.',
        videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-man-doing-bench-presses-with-a-barbell-40742-large.mp4',
        imagemUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=600&q=80',
      ),
      Exercicio(
        id: 'ex_peito_2',
        nome: 'Supino Inclinado com Halteres',
        grupoMuscular: 'Peito',
        musculosAuxiliares: 'Tríceps, Deltoide Anterior',
        equipamento: 'Halteres e Banco Inclinado',
        instrucoes: 'Ajuste o banco em um ângulo de 30º a 45º. Segure um halter em cada mão, eleve acima do peito superior e desça de forma controlada.',
        cuidados: 'Não incline demais o banco para não sobrecarregar excessivamente os ombros.',
      ),
      Exercicio(
        id: 'ex_peito_3',
        nome: 'Crucifixo no Crossover (Polia Alta)',
        grupoMuscular: 'Peito',
        musculosAuxiliares: 'Deltoide Anterior',
        equipamento: 'Polia / Crossover',
        instrucoes: 'Puxe os cabos da polia alta à frente do corpo unindo as mãos na altura da cintura com cotovelos levemente flexionados.',
        cuidados: 'Controle a fase concêntrica e excêntrica sem dar trancos.',
      ),

      // Costas
      Exercicio(
        id: 'ex_costas_1',
        nome: 'Puxada Frontal na Polia',
        grupoMuscular: 'Costas',
        musculosAuxiliares: 'Bíceps, Antebraço',
        equipamento: 'Polia Alta',
        instrucoes: 'Segure a barra aberta com pegada pronada. Puxe a barra em direção ao peito superior estufando o tórax.',
        cuidados: 'Evite inclinar o tronco excessivamente para trás.',
      ),
      Exercicio(
        id: 'ex_costas_2',
        nome: 'Remada Curvada com Barra',
        grupoMuscular: 'Costas',
        musculosAuxiliares: 'Bíceps, Erretores da Espinha',
        equipamento: 'Barra',
        instrucoes: 'Incline o tronco a aproximadamente 45º com joelhos levemente flexionados. Puxe a barra em direção ao umbigo.',
        cuidados: 'Mantenha a curvatura natural da coluna durante toda a execução.',
      ),
      Exercicio(
        id: 'ex_costas_3',
        nome: 'Remada Unilateral com Halter (Serrote)',
        grupoMuscular: 'Costas',
        musculosAuxiliares: 'Bíceps',
        equipamento: 'Halter e Banco',
        instrucoes: 'Apoie um joelho e uma mão no banco. Puxe o halter na direção do quadril mantendo o cotovelo próximo ao corpo.',
        cuidados: 'Evite rotacionar o quadril ou o tronco no final da puxada.',
      ),

      // Pernas
      Exercicio(
        id: 'ex_pernas_1',
        nome: 'Agachamento Livre com Barra',
        grupoMuscular: 'Pernas',
        musculosAuxiliares: 'Glúteos, Erretores da Espinha',
        equipamento: 'Barra e RACK',
        instrucoes: 'Posicione a barra sobre o trapézio. Flexione joelhos e quadril descendo como se fosse sentar em uma cadeira até 90º.',
        cuidados: 'Mantenha os joelhos alinhados com as pontas dos pés.',
      ),
      Exercicio(
        id: 'ex_pernas_2',
        nome: 'Leg Press 45º',
        grupoMuscular: 'Pernas',
        musculosAuxiliares: 'Quadríceps, Glúteos',
        equipamento: 'Máquina Leg Press',
        instrucoes: 'Apoie os pés na plataforma na largura dos ombros. Destrave a plataforma e desça até formar um ângulo de 90º nos joelhos.',
        cuidados: 'Nunca bloqueie ou hiperestenda totalmente os joelhos no topo.',
      ),
      Exercicio(
        id: 'ex_pernas_3',
        nome: 'Cadeira Extensora',
        grupoMuscular: 'Pernas',
        musculosAuxiliares: 'Quadríceps',
        equipamento: 'Máquina Extensora',
        instrucoes: 'Ajuste o apoio nos tornozelos. Estenda os joelhos até a contração máxima do quadríceps e retorne devagar.',
        cuidados: 'Evite usar impulso exagerado para subir a carga.',
      ),

      // Ombros
      Exercicio(
        id: 'ex_ombros_1',
        nome: 'Desenvolvimento com Halteres',
        grupoMuscular: 'Ombros',
        musculosAuxiliares: 'Tríceps',
        equipamento: 'Halteres e Banco',
        instrucoes: 'Sentado no banco, eleve os halteres a partir da linha das orelhas até a extensão acima da cabeça.',
        cuidados: 'Não empurre a cabeça à frente e mantenha a lombar apoiada.',
      ),
      Exercicio(
        id: 'ex_ombros_2',
        nome: 'Elevação Lateral com Halteres',
        grupoMuscular: 'Ombros',
        musculosAuxiliares: 'Trapezius',
        equipamento: 'Halteres',
        instrucoes: 'Em pé, eleve os halteres lateralmente até a altura dos ombros mantendo cotovelos levemente flexionados.',
        cuidados: 'Não jogue o corpo para trás ao subir a carga.',
      ),

      // Bíceps
      Exercicio(
        id: 'ex_biceps_1',
        nome: 'Rosca Direta com Barra W',
        grupoMuscular: 'Bíceps',
        musculosAuxiliares: 'Antebraço',
        equipamento: 'Barra W',
        instrucoes: 'Segure a barra com pegada supinada. Flexione os cotovelos trazendo a barra até a altura dos ombros.',
        cuidados: 'Mantenha os cotovelos fixos ao lado do tronco.',
      ),
      Exercicio(
        id: 'ex_biceps_2',
        nome: 'Rosca Martelo com Halteres',
        grupoMuscular: 'Bíceps',
        musculosAuxiliares: 'Braquiorradial',
        equipamento: 'Halteres',
        instrucoes: 'Com pegada neutra (palmas voltadas para dentro), eleve os halteres alternadamente ou simultaneamente.',
        cuidados: 'Evite oscilar os ombros para dar balanço.',
      ),

      // Tríceps
      Exercicio(
        id: 'ex_triceps_1',
        nome: 'Tríceps Pulley na Corda',
        grupoMuscular: 'Tríceps',
        musculosAuxiliares: 'Antebraço',
        equipamento: 'Polia Alta e Corda',
        instrucoes: 'Empurre a corda para baixo afastando as pontas no final do movimento para máxima contração.',
        cuidados: 'Mantenha os cotovelos travados na lateral do corpo.',
      ),
      Exercicio(
        id: 'ex_triceps_2',
        nome: 'Tríceps Testa com Barra W',
        grupoMuscular: 'Tríceps',
        musculosAuxiliares: 'Ancôneo',
        equipamento: 'Barra W e Banco Reto',
        instrucoes: 'Deitado no banco, flexione os cotovelos trazendo a barra em direção à testa e estenda novamente.',
        cuidados: 'Não abra excessivamente os cotovelos para fora.',
      ),

      // Abdômen
      Exercicio(
        id: 'ex_abdomen_1',
        nome: 'Abdominal Infra no Solo / Elevação de Pernas',
        grupoMuscular: 'Abdômen',
        musculosAuxiliares: 'Flexores do Quadril',
        equipamento: 'Colchonete',
        instrucoes: 'Deitado de costas, eleve as pernas estendidas ou flexionadas até um ângulo de 90º e retorne sem tocar os pés no chão.',
        cuidados: 'Mantenha a região lombar colada no chão.',
      ),
      Exercicio(
        id: 'ex_abdomen_2',
        nome: 'Prancha Ventral Isométrica',
        grupoMuscular: 'Abdômen',
        musculosAuxiliares: 'Lombar, Core',
        equipamento: 'Colchonete',
        instrucoes: 'Apoie antebraços e pontas dos pés no chão. Mantenha o corpo alinhado isometricamente.',
        cuidados: 'Não deixe o quadril selar ou subir demais.',
      ),

      // Corpo Inteiro & Mobilidade
      Exercicio(
        id: 'ex_corpo_1',
        nome: 'Burpee Completo',
        grupoMuscular: 'Corpo inteiro',
        musculosAuxiliares: 'Peito, Pernas, Core',
        equipamento: 'Peso corporal',
        instrucoes: 'Realize um agachamento, apoie as mãos no chão, jogue os pés para trás em flexão, retorne e salte.',
        cuidados: 'Mantenha ritmo constante e amortecimento no pouso.',
      ),
      Exercicio(
        id: 'ex_mob_1',
        nome: 'Mobilidade de Ombro com Bastão',
        grupoMuscular: 'Mobilidade e aquecimento',
        musculosAuxiliares: 'Manguito Rotador',
        equipamento: 'Bastão / Elastico',
        instrucoes: 'Segure o bastão com pegada larga e passe por cima da cabeça até as costas de forma fluida.',
        cuidados: 'Realize sem forçar a articulação.',
      ),
    ];

    for (var ex in seedExercises) {
      await db.insert('exercicios', ex.toMap());
    }
  }

  // Métodos CRUD para Exercícios
  Future<List<Exercicio>> getExercicios() async {
    final db = await instance.database;
    final result = await db.query('exercicios', orderBy: 'nome ASC');
    return result.map((json) => Exercicio.fromMap(json)).toList();
  }

  Future<void> saveExercicio(Exercicio ex) async {
    final db = await instance.database;
    await db.insert('exercicios', ex.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> toggleFavorito(String exercicioId, bool currentFav) async {
    final db = await instance.database;
    await db.update(
      'exercicios',
      {'is_favorito': currentFav ? 0 : 1},
      where: 'id = ?',
      whereArgs: [exercicioId],
    );
  }

  // Métodos CRUD para Treinos
  Future<List<Treino>> getTreinos(String usuarioId) async {
    final db = await instance.database;
    final result = await db.query('treinos', orderBy: 'criado_em DESC');
    
    List<Treino> treinos = [];
    for (var row in result) {
      final treinoId = row['id'] as String;
      final exerciciosRows = await db.query(
        'exercicios_do_treino',
        where: 'treino_id = ?',
        whereArgs: [treinoId],
        orderBy: 'ordem ASC',
      );

      List<ExercicioDoTreino> exList = [];
      for (var exRow in exerciciosRows) {
        final exId = exRow['exercicio_id'] as String;
        final exInfoResult = await db.query('exercicios', where: 'id = ?', whereArgs: [exId]);
        Exercicio? exInfo = exInfoResult.isNotEmpty ? Exercicio.fromMap(exInfoResult.first) : null;
        exList.add(ExercicioDoTreino.fromMap(exRow, exercicioInfo: exInfo));
      }

      treinos.add(Treino.fromMap(row, exercicios: exList));
    }

    return treinos;
  }

  Future<void> saveTreino(Treino treino) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('treinos', treino.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      
      // Deletar anteriores para atualizar a lista
      await txn.delete('exercicios_do_treino', where: 'treino_id = ?', whereArgs: [treino.id]);
      
      for (var ex in treino.exercicios) {
        await txn.insert('exercicios_do_treino', ex.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> deleteTreino(String treinoId) async {
    final db = await instance.database;
    await db.delete('treinos', where: 'id = ?', whereArgs: [treinoId]);
    await db.delete('exercicios_do_treino', where: 'treino_id = ?', whereArgs: [treinoId]);
  }

  // Métodos para Sessão de Treino e Séries Realizadas
  Future<void> salvarSessaoRealizada(SessaoTreino sessao, List<SerieRealizada> series) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('sessoes_de_treino', sessao.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (var serie in series) {
        await txn.insert('series_realizadas', serie.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<SessaoTreino>> getHistoricoSessoes() async {
    final db = await instance.database;
    final result = await db.query('sessoes_de_treino', orderBy: 'inicio DESC');
    return result.map((json) => SessaoTreino.fromMap(json)).toList();
  }

  Future<List<SerieRealizada>> getSeriesPorSessao(String sessaoId) async {
    final db = await instance.database;
    final result = await db.query('series_realizadas', where: 'sessao_id = ?', whereArgs: [sessaoId]);
    return result.map((json) => SerieRealizada.fromMap(json)).toList();
  }
}
