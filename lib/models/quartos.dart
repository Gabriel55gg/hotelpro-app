import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HospedeInfo {
  final String nome;
  final String cpf;
  final String telefone;

  HospedeInfo({required this.nome, required this.cpf, required this.telefone});

  Map<String, dynamic> toMap() => {'nome': nome, 'cpf': cpf, 'telefone': telefone};

  factory HospedeInfo.fromMap(Map<String, dynamic> m) => HospedeInfo(
        nome: (m['nome'] ?? '').toString(),
        cpf: (m['cpf'] ?? '').toString(),
        telefone: (m['telefone'] ?? '').toString(),
      );
}

class Quarto {
  int? dbId; // id (bigint) no banco; fica null até o primeiro salvamento
  Future<void>? gravando; // fila de gravação deste quarto
  String id; // número do quarto (como você já usava)
  String tipo;
  double valorDiaria;
  String status;

  String? hospedePrincipal;
  String? cpf;
  String? telefone;
  String? placaVeiculo;
  DateTime? dataEntrada;

  List<HospedeInfo> acompanhantes = [];

  Quarto({
    this.dbId,
    required this.id,
    required this.tipo,
    required this.valorDiaria,
    required this.status,
    this.hospedePrincipal,
    this.cpf,
    this.telefone,
    this.placaVeiculo,
    this.dataEntrada,
  });

  factory Quarto.fromMap(Map<String, dynamic> m) {
    final q = Quarto(
      dbId: (m['id'] as num).toInt(),
      id: (m['numero'] ?? '').toString(),
      tipo: (m['tipo'] ?? '').toString(),
      valorDiaria: () {
        final v = double.tryParse('${m['valor_diaria']}') ?? 0;
        if (v > 0) return v;
        return double.tryParse('${m['preco_diaria']}') ?? 0;
      }(),
      status: (m['status'] ?? 'Disponível').toString(),
      hospedePrincipal: m['hospede_principal'] as String?,
      cpf: m['cpf'] as String?,
      telefone: m['telefone'] as String?,
      placaVeiculo: m['placa_veiculo'] as String?,
      dataEntrada: m['data_entrada'] == null
          ? null
          : DateTime.tryParse(m['data_entrada'].toString())?.toLocal(),
    );
    final ac = m['acompanhantes'];
    if (ac is List) {
      q.acompanhantes = ac
          .map((e) => HospedeInfo.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return q;
  }

  Map<String, dynamic> toMap(String empresaId) => {
        'empresa_id': empresaId,
        'numero': id,
        'tipo': tipo,
        'valor_diaria': valorDiaria,
        'preco_diaria': valorDiaria, // coluna antiga, mantida em dia
        'status': status,
        'hospede_principal': hospedePrincipal,
        'cpf': cpf,
        'telefone': telefone,
        'placa_veiculo': placaVeiculo,
        'data_entrada': dataEntrada?.toUtc().toIso8601String(),
        'acompanhantes': acompanhantes.map((a) => a.toMap()).toList(),
      };

  String get entradaFormatada {
    if (dataEntrada == null) return '';
    String dia = dataEntrada!.day.toString().padLeft(2, '0');
    String mes = dataEntrada!.month.toString().padLeft(2, '0');
    String ano = dataEntrada!.year.toString();
    String hora = dataEntrada!.hour.toString().padLeft(2, '0');
    String minuto = dataEntrada!.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano $hora:$minuto';
  }

  double calcularValorDiarias() {
    if (dataEntrada == null) return valorDiaria;
    final diferenca = DateTime.now().difference(dataEntrada!);
    int horas = diferenca.inHours;
    if (horas <= 0) return valorDiaria;

    int diarias = (horas / 24).ceil();
    if (diarias < 1) diarias = 1;
    return diarias * valorDiaria;
  }

  double calcularValorTotal() {
    return calcularValorDiarias();
  }
}

class TransacaoFinanceira {
  final String descricao;
  final double valor;
  final DateTime data;
  final String tipo; // 'Entrada' ou 'Saída'

  TransacaoFinanceira({
    required this.descricao,
    required this.valor,
    required this.data,
    required this.tipo,
  });

  factory TransacaoFinanceira.fromMap(Map<String, dynamic> m) =>
      TransacaoFinanceira(
        descricao: (m['descricao'] ?? '').toString(),
        valor: double.tryParse(m['valor'].toString()) ?? 0,
        data: DateTime.parse(m['data'].toString()).toLocal(),
        tipo: (m['tipo'] ?? 'Saída').toString(),
      );

  Map<String, dynamic> toMap(String empresaId) => {
        'empresa_id': empresaId,
        'descricao': descricao,
        'valor': valor,
        'tipo': tipo,
        'data': data.toUtc().toIso8601String(),
      };
}

class ClienteHistorico {
  final String nome;
  final String cpf;
  final String telefone;
  final String ultimaEstada;

  ClienteHistorico({
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.ultimaEstada,
  });

  factory ClienteHistorico.fromMap(Map<String, dynamic> m) => ClienteHistorico(
        nome: (m['nome'] ?? '').toString(),
        cpf: (m['cpf'] ?? '').toString(),
        telefone: (m['telefone'] ?? '').toString(),
        ultimaEstada: (m['ultima_estada'] ?? '').toString(),
      );

  Map<String, dynamic> toMap(String empresaId) => {
        'empresa_id': empresaId,
        'nome': nome,
        'cpf': cpf,
        'telefone': telefone,
        'ultima_estada': ultimaEstada,
        'atualizado_em': DateTime.now().toUtc().toIso8601String(),
      };
}

class GerenciadorQuartos {
  /// Id da pousada logada. Enquanto for null, tudo funciona só em memória.
  String? empresaId;

  /// Último erro ao falar com o Supabase (útil para mostrar na tela).
  String? ultimoErro;

  final List<Quarto> listaQuartos = [];
  final List<TransacaoFinanceira> historicoCaixa = [];
  final List<ClienteHistorico> historicoClientes = [];

  SupabaseClient get _db => Supabase.instance.client;

  // ───────────────────── CARREGAR / LIMPAR ─────────────────────

  /// Chame logo depois do login, passando o id da pousada.
  Future<void> iniciar(String idDaPousada) async {
    empresaId = idDaPousada;
    ultimoErro = null;
    try {
      final q = await _db.from('quartos').select().eq('empresa_id', idDaPousada);
      listaQuartos
        ..clear()
        ..addAll((q as List)
            .map((m) => Quarto.fromMap(Map<String, dynamic>.from(m as Map))));
      listaQuartos.sort((a, b) {
        final na = int.tryParse(a.id);
        final nb = int.tryParse(b.id);
        if (na != null && nb != null) return na.compareTo(nb);
        return a.id.compareTo(b.id);
      });

      final c = await _db
          .from('caixa_transacoes')
          .select()
          .eq('empresa_id', idDaPousada)
          .order('data', ascending: true);
      historicoCaixa
        ..clear()
        ..addAll((c as List).map((m) =>
            TransacaoFinanceira.fromMap(Map<String, dynamic>.from(m as Map))));

      final h = await _db
          .from('clientes_historico')
          .select()
          .eq('empresa_id', idDaPousada)
          .order('atualizado_em', ascending: false);
      historicoClientes
        ..clear()
        ..addAll((h as List).map((m) =>
            ClienteHistorico.fromMap(Map<String, dynamic>.from(m as Map))));
    } catch (e) {
      ultimoErro = e.toString();
      debugPrint('Erro ao carregar dados da pousada: $e');
    }
  }

  /// Chame ao sair da conta.
  void limpar() {
    empresaId = null;
    listaQuartos.clear();
    historicoCaixa.clear();
    historicoClientes.clear();
  }

  // Salva em segundo plano. A tela atualiza na hora (memória) e o banco
  // recebe em seguida, então o resto do app não precisa mudar.
  Future<void> _salvar(Future<dynamic> Function() operacao) async {
    if (empresaId == null) return;
    try {
      await operacao();
    } catch (e) {
      ultimoErro = e.toString();
      debugPrint('Erro ao salvar no Supabase: $e');
    }
  }

  // Grava o quarto em fila: o primeiro salvamento faz INSERT e guarda o id
  // devolvido pelo banco; os seguintes fazem UPDATE. Assim, editar logo após
  // criar não gera quarto duplicado.
  Future<void> _salvarQuarto(Quarto q) {
    if (empresaId == null) return Future.value();
    final anterior = q.gravando ?? Future.value();
    final f = anterior.then((_) async {
      try {
        final map = q.toMap(empresaId!);
        if (q.dbId == null) {
          final r = await _db.from('quartos').insert(map).select('id').single();
          q.dbId = (r['id'] as num).toInt();
        } else {
          await _db.from('quartos').update(map).eq('id', q.dbId!);
        }
      } catch (e) {
        ultimoErro = e.toString();
        debugPrint('Erro ao salvar quarto: $e');
      }
    });
    q.gravando = f;
    return f;
  }

  void _salvarTransacao(TransacaoFinanceira t) {
    _salvar(() => _db.from('caixa_transacoes').insert(t.toMap(empresaId!)));
  }

  void _salvarClientes(List<ClienteHistorico> clientes) {
    if (clientes.isEmpty) return;
    _salvar(() => _db
        .from('clientes_historico')
        .upsert(clientes.map((c) => c.toMap(empresaId!)).toList(),
            onConflict: 'empresa_id,cpf'));
  }

  // ───────────────────── CHECK-IN / CHECK-OUT ─────────────────────

  void realizarCheckInCompleto({
    required int index,
    required String nome,
    required String cpf,
    required String telefone,
    required String placa,
    required List<HospedeInfo> listaAcompanhantes,
  }) {
    final q = listaQuartos[index];
    q.status = 'Ocupado';
    q.hospedePrincipal = nome;
    q.cpf = cpf;
    q.telefone = telefone;
    q.placaVeiculo = placa.isEmpty ? 'Não possui' : placa;
    q.dataEntrada = DateTime.now();
    q.acompanhantes = listaAcompanhantes;

    final estada =
        '${q.dataEntrada!.day}/${q.dataEntrada!.month}/${q.dataEntrada!.year}';
    final novos = <ClienteHistorico>[];

    historicoClientes.removeWhere((c) => c.cpf == cpf);
    final principal = ClienteHistorico(
      nome: nome,
      cpf: cpf,
      telefone: telefone,
      ultimaEstada: estada,
    );
    historicoClientes.insert(0, principal);
    if (cpf.isNotEmpty) novos.add(principal);

    for (var ap in listaAcompanhantes) {
      if (ap.cpf.isNotEmpty) {
        historicoClientes.removeWhere((c) => c.cpf == ap.cpf);
        final c = ClienteHistorico(
          nome: '${ap.nome} (Acompanhante)',
          cpf: ap.cpf,
          telefone: ap.telefone,
          ultimaEstada: estada,
        );
        historicoClientes.insert(0, c);
        novos.add(c);
      }
    }

    _salvarQuarto(q);
    _salvarClientes(novos);
  }

  double realizarCheckOut(int index) {
    final q = listaQuartos[index];
    double valorTotal = q.calcularValorTotal();
    String quartoId = q.id;
    String hospede = q.hospedePrincipal ?? 'Hóspede';

    final transacao = TransacaoFinanceira(
      descricao: 'Check-Out Quarto $quartoId ($hospede)',
      valor: valorTotal,
      data: DateTime.now(),
      tipo: 'Entrada',
    );
    historicoCaixa.add(transacao);

    q.status = 'Disponível';
    q.hospedePrincipal = null;
    q.cpf = null;
    q.telefone = null;
    q.placaVeiculo = null;
    q.dataEntrada = null;
    q.acompanhantes = [];

    _salvarTransacao(transacao);
    _salvarQuarto(q);

    return valorTotal;
  }

  // ───────────────────── CRUD DE QUARTOS ─────────────────────

  void adicionarQuarto(String numero, String tipo, double diaria) {
    final q = Quarto(
      id: numero,
      tipo: tipo,
      valorDiaria: diaria,
      status: 'Disponível',
    );
    listaQuartos.add(q);
    _salvarQuarto(q);
  }

  void editarQuarto(int index, String numero, String tipo, double diaria) {
    final q = listaQuartos[index];
    q.id = numero;
    q.tipo = tipo;
    q.valorDiaria = diaria;
    _salvarQuarto(q);
  }

  void removerQuarto(int index) {
    final q = listaQuartos.removeAt(index);
    if (empresaId == null) return;
    (q.gravando ?? Future.value()).then((_) async {
      if (q.dbId == null) return;
      await _salvar(() => _db.from('quartos').delete().eq('id', q.dbId!));
    });
  }

  // ───────────────────── FINANCEIRO ─────────────────────

  void adicionarGasto(String descricao, double valor) {
    final t = TransacaoFinanceira(
      descricao: descricao,
      valor: valor,
      data: DateTime.now(),
      tipo: 'Saída',
    );
    historicoCaixa.add(t);
    _salvarTransacao(t);
  }

  double getTotalEntradasMesAtual() {
    DateTime agora = DateTime.now();
    return historicoCaixa
        .where((t) =>
            t.tipo == 'Entrada' &&
            t.data.month == agora.month &&
            t.data.year == agora.year)
        .fold(0.0, (soma, t) => soma + t.valor);
  }

  double getTotalSaidasMesAtual() {
    DateTime agora = DateTime.now();
    return historicoCaixa
        .where((t) =>
            t.tipo == 'Saída' &&
            t.data.month == agora.month &&
            t.data.year == agora.year)
        .fold(0.0, (soma, t) => soma + t.valor);
  }

  double getLucroLiquidoMesAtual() {
    return getTotalEntradasMesAtual() - getTotalSaidasMesAtual();
  }
}
