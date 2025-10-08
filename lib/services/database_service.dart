import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../app_config.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'controle_gastos.db';
  static const int _databaseVersion = 1;

  // Tabelas
  static const String _transacoesTable = 'transacoes';
  static const String _categoriasTable = 'categorias';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Criar tabela de transações
    await db.execute('''
      CREATE TABLE $_transacoesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor REAL NOT NULL,
        categoria TEXT NOT NULL,
        tipo TEXT NOT NULL,
        data TEXT NOT NULL,
        observacao TEXT,
        metodo TEXT NOT NULL,
        eParcelaFutura INTEGER NOT NULL DEFAULT 0,
        parcelas INTEGER NOT NULL DEFAULT 1,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Criar tabela de categorias
    await db.execute('''
      CREATE TABLE $_categoriasTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL
      )
    ''');

    // Inserir categorias padrão
    await _inserirCategoriasPadrao(db);
  }

  static Future<void> _inserirCategoriasPadrao(Database db) async {
    List<String> categoriasEntradaPadrao = versaoPessoal 
        ? ['Salário', 'IC', 'Ajuda', 'Cofrinho', 'Outro']
        : ['Salário', 'Renda Extra', 'Presente'];
    
    List<String> categoriasSaidaPadrao = versaoPessoal 
        ? ['Aluguel', 'Mercado', 'Farmácia', 'Transporte', 'Compras', 'Gás',
           'Lazer', 'Investido', 'Cofrinho', 'Aposta', 'Tarifa', 'Conta', 'Outro']
        : ['Moradia', 'Alimentação', 'Transporte', 'Saúde', 
           'Lazer', 'Contas', 'Outros'];

    // Inserir categorias de entrada
    for (String categoria in categoriasEntradaPadrao) {
      await db.insert(_categoriasTable, {
        'nome': categoria,
        'tipo': 'Entrada',
      });
    }

    // Inserir categorias de saída
    for (String categoria in categoriasSaidaPadrao) {
      await db.insert(_categoriasTable, {
        'nome': categoria,
        'tipo': 'Saida',
      });
    }

    // Adicionar categoria especial para faturas
    await db.insert(_categoriasTable, {
      'nome': 'Fatura',
      'tipo': 'Saida',
    });
  }

  // CRUD para Transações
  static Future<int> inserirTransacao(Map<String, dynamic> transacao) async {
    final db = await database;
    return await db.insert(_transacoesTable, transacao);
  }

  static Future<List<Map<String, dynamic>>> obterTransacoes() async {
    final db = await database;
    return await db.query(_transacoesTable, orderBy: 'timestamp DESC');
  }

  static Future<int> atualizarTransacao(int id, Map<String, dynamic> transacao) async {
    final db = await database;
    return await db.update(
      _transacoesTable,
      transacao,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> excluirTransacao(int id) async {
    final db = await database;
    return await db.delete(
      _transacoesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> limparTodasTransacoes() async {
    final db = await database;
    await db.delete(_transacoesTable);
  }

  // CRUD para Categorias
  static Future<List<Map<String, dynamic>>> obterCategorias(String tipo) async {
    final db = await database;
    return await db.query(
      _categoriasTable,
      where: 'tipo = ?',
      whereArgs: [tipo],
      orderBy: 'nome ASC',
    );
  }

  static Future<int> inserirCategoria(String nome, String tipo) async {
    final db = await database;
    return await db.insert(_categoriasTable, {
      'nome': nome,
      'tipo': tipo,
    });
  }

  static Future<int> excluirCategoria(int id) async {
    final db = await database;
    return await db.delete(
      _categoriasTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> atualizarCategoria(int id, String novoNome) async {
    final db = await database;
    return await db.update(
      _categoriasTable,
      {'nome': novoNome},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método para atualizar categorias em transações quando uma categoria é renomeada
  static Future<void> atualizarCategoriaEmTransacoes(String nomeAntigo, String novoNome) async {
    final db = await database;
    await db.update(
      _transacoesTable,
      {'categoria': novoNome},
      where: 'categoria = ?',
      whereArgs: [nomeAntigo],
    );
  }

  // Fechar banco de dados
  static Future<void> fecharDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}