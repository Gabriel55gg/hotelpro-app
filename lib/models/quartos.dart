class HospedeInfo {
  final String nome;
  final String cpf;
  final String telefone;

  HospedeInfo({required this.nome, required this.cpf, required this.telefone});
}

class Quarto {
  String id;
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
}

class ClienteHistorico {
  final String nome;
  final String cpf;
  final String telefone;
  final String ultimaEstada;

  ClienteHistorico({required this.nome, required this.cpf, required this.telefone, required this.ultimaEstada});
}

class GerenciadorQuartos {
  final List<Quarto> listaQuartos = [];
  final List<TransacaoFinanceira> historicoCaixa = [
    // Exemplo inicial de custos/gastos para movimentar a aba financeira
    TransacaoFinanceira(descricao: 'Manutenção de Ar-Condicionado', valor: 150.0, data: DateTime.now().subtract(const Duration(days: 2)), tipo: 'Saída'),
    TransacaoFinanceira(descricao: 'Compra de Produtos de Limpeza', valor: 80.0, data: DateTime.now().subtract(const Duration(days: 5)), tipo: 'Saída'),
  ];
  final List<ClienteHistorico> historicoClientes = [];

  void realizarCheckInCompleto({
    required int index,
    required String nome,
    required String cpf,
    required String telefone,
    required String placa,
    required List<HospedeInfo> listaAcompanhantes,
  }) {
    listaQuartos[index].status = 'Ocupado';
    listaQuartos[index].hospedePrincipal = nome;
    listaQuartos[index].cpf = cpf;
    listaQuartos[index].telefone = telefone;
    listaQuartos[index].placaVeiculo = placa.isEmpty ? 'Não possui' : placa;
    listaQuartos[index].dataEntrada = DateTime.now();
    listaQuartos[index].acompanhantes = listaAcompanhantes;

    historicoClientes.removeWhere((c) => c.cpf == cpf);
    historicoClientes.insert(
      0,
      ClienteHistorico(
        nome: nome,
        cpf: cpf,
        telefone: telefone,
        ultimaEstada: '${listaQuartos[index].dataEntrada!.day}/${listaQuartos[index].dataEntrada!.month}/${listaQuartos[index].dataEntrada!.year}',
      ),
    );

    for (var ap in listaAcompanhantes) {
      if (ap.cpf.isNotEmpty) {
        historicoClientes.removeWhere((c) => c.cpf == ap.cpf);
        historicoClientes.insert(
          0,
          ClienteHistorico(
            nome: '${ap.nome} (Acompanhante)',
            cpf: ap.cpf,
            telefone: ap.telefone,
            ultimaEstada: '${listaQuartos[index].dataEntrada!.day}/${listaQuartos[index].dataEntrada!.month}/${listaQuartos[index].dataEntrada!.year}',
          ),
        );
      }
    }
  }

  double realizarCheckOut(int index) {
    double valorTotal = listaQuartos[index].calcularValorTotal();
    String quartoId = listaQuartos[index].id;
    String hospede = listaQuartos[index].hospedePrincipal ?? 'Hóspede';

    historicoCaixa.add(
      TransacaoFinanceira(
        descricao: 'Check-Out Quarto $quartoId ($hospede)',
        valor: valorTotal,
        data: DateTime.now(),
        tipo: 'Entrada',
      ),
    );

    listaQuartos[index].status = 'Disponível';
    listaQuartos[index].hospedePrincipal = null;
    listaQuartos[index].cpf = null;
    listaQuartos[index].telefone = null;
    listaQuartos[index].placaVeiculo = null;
    listaQuartos[index].dataEntrada = null;
    listaQuartos[index].acompanhantes.clear();

    return valorTotal;
  }

  void adicionarQuarto(String numero, String tipo, double diaria) {
    listaQuartos.add(
      Quarto(id: numero, tipo: tipo, valorDiaria: diaria, status: 'Disponível'),
    );
  }

  void editarQuarto(int index, String numero, String tipo, double diaria) {
    listaQuartos[index].id = numero;
    listaQuartos[index].tipo = tipo;
    listaQuartos[index].valorDiaria = diaria;
  }

  void removerQuarto(int index) {
    listaQuartos.removeAt(index);
  }

  void adicionarGasto(String descricao, double valor) {
    historicoCaixa.add(
      TransacaoFinanceira(
        descricao: descricao,
        valor: valor,
        data: DateTime.now(),
        tipo: 'Saída',
      ),
    );
  }

  double getTotalEntradasMesAtual() {
    DateTime agora = DateTime.now();
    return historicoCaixa
        .where((t) => t.tipo == 'Entrada' && t.data.month == agora.month && t.data.year == agora.year)
        .fold(0.0, (soma, t) => soma + t.valor);
  }

  double getTotalSaidasMesAtual() {
    DateTime agora = DateTime.now();
    return historicoCaixa
        .where((t) => t.tipo == 'Saída' && t.data.month == agora.month && t.data.year == agora.year)
        .fold(0.0, (soma, t) => soma + t.valor);
  }

  double getLucroLiquidoMesAtual() {
    return getTotalEntradasMesAtual() - getTotalSaidasMesAtual();
  }
}