import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class ExerciseLocalDatabase {
  static final ExerciseLocalDatabase instance = ExerciseLocalDatabase._init();
  static Database? _database;

  ExerciseLocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('jtech_fit_local.db');
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

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercicios (
        id TEXT PRIMARY KEY,
        exercise_db_id TEXT,
        nome_original TEXT,
        nome_traduzido TEXT,
        parte_corpo_original TEXT,
        parte_corpo_traduzida TEXT,
        musculo_principal_original TEXT,
        musculo_principal_traduzido TEXT,
        musculos_secundarios TEXT,
        equipamento_original TEXT,
        equipamento_traduzido TEXT,
        instrucoes TEXT,
        cuidados TEXT,
        gif_url TEXT,
        video_url TEXT,
        imagem_url TEXT,
        personalizado INTEGER,
        usuario_id TEXT,
        favorito INTEGER,
        atualizado_em TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE exercicios_do_treino (
        id TEXT PRIMARY KEY,
        treino_id TEXT,
        exercicio_id TEXT,
        ordem INTEGER,
        quantidade_series INTEGER,
        repeticoes TEXT,
        carga_inicial REAL,
        descanso_segundos INTEGER,
        observacoes TEXT
      )
    ''');
  }

  /// Salva ou atualiza uma lista de exercícios no cache local
  Future<void> saveExercisesBatch(List<Map<String, dynamic>> list) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var item in list) {
      batch.insert(
        'exercicios',
        {
          'id': item['id'] ?? item['exercise_db_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'exercise_db_id': item['exercise_db_id'],
          'nome_original': item['nome_original'],
          'nome_traduzido': item['nome_traduzido'] ?? item['nome'],
          'parte_corpo_original': item['parte_corpo_original'],
          'parte_corpo_traduzida': item['parte_corpo_traduzida'] ?? item['grupo_muscular'],
          'musculo_principal_original': item['musculo_principal_original'],
          'musculo_principal_traduzido': item['musculo_principal_traduzido'] ?? item['grupo_muscular'],
          'musculos_secundarios': item['musculos_secundarios'] ?? '',
          'equipamento_original': item['equipamento_original'],
          'equipamento_traduzido': item['equipamento_traduzido'] ?? item['equipamento'],
          'instrucoes': item['instrucoes'] ?? '',
          'cuidados': item['cuidados'] ?? '',
          'gif_url': item['gif_url'],
          'video_url': item['video_url'],
          'imagem_url': item['imagem_url'],
          'personalizado': item['personalizado'] == true ? 1 : 0,
          'usuario_id': item['usuario_id'],
          'favorito': item['favorito'] == true || item['is_favorito'] == true ? 1 : 0,
          'atualizado_em': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Recupera todos os exercícios salvos localmente
  Future<List<Exercicio>> getLocalExercises() async {
    final db = await instance.database;
    final result = await db.query('exercicios', orderBy: 'nome_traduzido ASC');
    return result.map((map) => Exercicio.fromMap(map)).toList();
  }

  /// Alterna estado de favorito no banco local
  Future<void> toggleFavorito(String id, bool isFav) async {
    final db = await instance.database;
    await db.update(
      'exercicios',
      {'favorito': isFav ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
