import 'dart:convert';
import 'package:flutter/material.dart';
import 'main.dart';

/// Avisa o app inteiro que os dados mudaram (o MainScreenHolder escuta isso).
final ValueNotifier<int> globalAtualizar = ValueNotifier<int>(0);

/// Instruções que vão junto com cada pergunta, ensinando a IA a pedir ações.
const String kInstrucoesAcoes = '''
VOCÊ PODE EXECUTAR AÇÕES NO APP. Quando o gestor pedir claramente para fazer algo, responda com uma frase curta dizendo o que entendeu e inclua, no FINAL da resposta, um bloco por ação neste formato exato (JSON em uma única linha):
[[ACAO]]{"acao":"registrar_gasto","descricao":"Compra de sabão","valor":150.5}[[/ACAO]]

Ações disponíveis e seus campos:
- registrar_gasto: descricao (texto), valor (número em reais com ponto decimal), categoria (opcional: Limpeza, Alimentação, Manutenção, Contas, Equipe ou Outros)
- criar_quarto: numero, tipo, diaria
- editar_quarto: numero (o atual), novo_numero, tipo, diaria (envie só o que muda)
- remover_quarto: numero (somente quartos livres)
- fazer_checkin: numero (quarto livre), nome, cpf, telefone, placa (omita o que não foi informado)
- fazer_checkout: numero (quarto ocupado)

Regras: o app mostra um botão de confirmação ao gestor, então NUNCA diga que já foi feito; diga que está pronto para confirmar. Se faltar um dado essencial (valor, nome, número do quarto) ou houver dúvida, PERGUNTE antes e não inclua o bloco. Use os números de quarto exatamente como aparecem em detalhes_dos_quartos. Para qualquer pedido fora dessa lista (por exemplo alterar o nome de um hóspede já cadastrado, ou editar/apagar um lançamento do caixa), explique que ainda não consegue fazer isso.
''';

const _acoesValidas = {'registrar_gasto', 'criar_quarto', 'editar_quarto', 'remover_quarto', 'fazer_checkin', 'fazer_checkout'};
const _categoriasValidas = ['Limpeza', 'Alimentação', 'Manutenção', 'Contas', 'Equipe', 'Outros'];

enum EstadoAcao { pendente, feita, cancelada, erro }

class AcaoIA {
  final String tipo;
  final Map<String, dynamic> dados;
  EstadoAcao estado = EstadoAcao.pendente;
  String resultado = '';
  AcaoIA(this.tipo, this.dados);

  IconData get icone {
    switch (tipo) {
      case 'registrar_gasto':
        return Icons.receipt_long_outlined;
      case 'remover_quarto':
        return Icons.delete_outline_rounded;
      case 'fazer_checkin':
        return Icons.login_rounded;
      case 'fazer_checkout':
        return Icons.logout_rounded;
      default:
        return Icons.meeting_room_outlined;
    }
  }

  String get resumo {
    final d = dados;
    switch (tipo) {
      case 'registrar_gasto':
        final cat = _s(d['categoria']);
        return 'Registrar gasto de ${moeda(_d(d['valor']))}: ${_s(d['descricao'])}${cat.isNotEmpty ? ' ($cat)' : ''}';
      case 'criar_quarto':
        return 'Criar o quarto ${_s(d['numero'])} (${_s(d['tipo'])}) com diária de ${moeda(_d(d['diaria']))}';
      case 'editar_quarto':
        final partes = <String>[];
        if (_s(d['novo_numero']).isNotEmpty) partes.add('número → ${_s(d['novo_numero'])}');
        if (_s(d['tipo']).isNotEmpty) partes.add('tipo → ${_s(d['tipo'])}');
        if (_d(d['diaria']) > 0) partes.add('diária → ${moeda(_d(d['diaria']))}');
        return 'Editar o quarto ${_s(d['numero'])}: ${partes.isEmpty ? 'sem alterações' : partes.join(', ')}';
      case 'remover_quarto':
        return 'Remover o quarto ${_s(d['numero'])}';
      case 'fazer_checkin':
        return 'Check-in no quarto ${_s(d['numero'])} para ${_s(d['nome'])}'
            '${_s(d['telefone']).isNotEmpty ? ' · Tel ${_s(d['telefone'])}' : ''}'
            '${_s(d['placa']).isNotEmpty ? ' · Placa ${_s(d['placa'])}' : ''}';
      case 'fazer_checkout':
        return 'Check-out do quarto ${_s(d['numero'])}';
      default:
        return tipo;
    }
  }
}

class RespostaIA {
  final String texto;
  final List<AcaoIA> acoes;
  RespostaIA(this.texto, this.acoes);
}

/// Separa o texto da resposta dos blocos [[ACAO]]...[[/ACAO]].
RespostaIA interpretarResposta(String bruto) {
  final regex = RegExp(r'\[\[ACAO\]\](.*?)\[\[/ACAO\]\]', dotAll: true);
  final acoes = <AcaoIA>[];
  for (final m in regex.allMatches(bruto)) {
    try {
      final j = jsonDecode(m.group(1)!.trim());
      if (j is Map && _acoesValidas.contains(j['acao'])) {
        acoes.add(AcaoIA(j['acao'].toString(), Map<String, dynamic>.from(j)));
      }
    } catch (_) {}
    if (acoes.length >= 5) break;
  }
  var texto = bruto.replaceAll(regex, '').trim();
  if (texto.isEmpty && acoes.isNotEmpty) texto = 'Pronto para executar. Confirme abaixo:';
  return RespostaIA(texto, acoes);
}

// -----------------------------------------------------------------------------
String _s(dynamic v) => v == null ? '' : v.toString().trim();
double _d(dynamic v) => v is num ? v.toDouble() : lerValor(_s(v));
int _indiceQuarto(String numero) => globalGerenciador.listaQuartos.indexWhere((q) => '${q.id}'.trim() == numero.trim());

String _fmtCpf(String s) {
  final d = s.replaceAll(RegExp(r'\D'), '');
  if (d.length != 11) return s;
  return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
}

String _fmtTel(String s) {
  final d = s.replaceAll(RegExp(r'\D'), '');
  if (d.length == 11) return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
  if (d.length == 10) return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
  return s;
}

/// Executa a ação. Devolve a mensagem de sucesso ou lança Exception com o motivo.
String executarAcao(AcaoIA a) {
  final g = globalGerenciador;
  final d = a.dados;

  switch (a.tipo) {
    case 'registrar_gasto':
      final desc = _s(d['descricao']);
      final valor = _d(d['valor']);
      if (desc.isEmpty) throw Exception('Faltou a descrição do gasto.');
      if (valor <= 0) throw Exception('O valor do gasto precisa ser maior que zero.');
      final cat = _s(d['categoria']);
      g.adicionarGasto(_categoriasValidas.contains(cat) ? '$cat · $desc' : desc, valor);
      globalAtualizar.value++;
      return 'gasto de ${moeda(valor)} registrado.';

    case 'criar_quarto':
      final numero = _s(d['numero']);
      final tipo = _s(d['tipo']);
      final diaria = _d(d['diaria']);
      if (numero.isEmpty || tipo.isEmpty || diaria <= 0) throw Exception('Faltaram dados do quarto (número, tipo ou diária).');
      if (_indiceQuarto(numero) >= 0) throw Exception('Já existe um quarto $numero.');
      g.adicionarQuarto(numero, tipo, diaria);
      globalAtualizar.value++;
      return 'quarto $numero criado.';

    case 'editar_quarto':
      final idx = _indiceQuarto(_s(d['numero']));
      if (idx < 0) throw Exception('Não achei o quarto ${_s(d['numero'])}.');
      final q = g.listaQuartos[idx];
      final novoNumero = _s(d['novo_numero']).isEmpty ? '${q.id}' : _s(d['novo_numero']);
      if (novoNumero != '${q.id}' && _indiceQuarto(novoNumero) >= 0) throw Exception('Já existe um quarto $novoNumero.');
      final tipo = _s(d['tipo']).isEmpty ? '${q.tipo}' : _s(d['tipo']);
      final diaria = _d(d['diaria']) > 0 ? _d(d['diaria']) : (q.valorDiaria as num).toDouble();
      g.editarQuarto(idx, novoNumero, tipo, diaria);
      globalAtualizar.value++;
      return 'quarto $novoNumero atualizado.';

    case 'remover_quarto':
      final idx = _indiceQuarto(_s(d['numero']));
      if (idx < 0) throw Exception('Não achei o quarto ${_s(d['numero'])}.');
      if (g.listaQuartos[idx].status == 'Ocupado') throw Exception('O quarto ${_s(d['numero'])} está ocupado. Faça o check-out antes.');
      g.removerQuarto(idx);
      globalAtualizar.value++;
      return 'quarto ${_s(d['numero'])} removido.';

    case 'fazer_checkin':
      final idx = _indiceQuarto(_s(d['numero']));
      if (idx < 0) throw Exception('Não achei o quarto ${_s(d['numero'])}.');
      if (g.listaQuartos[idx].status == 'Ocupado') throw Exception('O quarto ${_s(d['numero'])} já está ocupado.');
      final nome = _s(d['nome']);
      if (nome.isEmpty) throw Exception('Faltou o nome do hóspede.');
      g.realizarCheckInCompleto(
        index: idx,
        nome: nome,
        cpf: _fmtCpf(_s(d['cpf'])),
        telefone: _fmtTel(_s(d['telefone'])),
        placa: _s(d['placa']),
        listaAcompanhantes: [],
      );
      globalAtualizar.value++;
      return 'check-in de $nome no quarto ${_s(d['numero'])} realizado.';

    case 'fazer_checkout':
      final idx = _indiceQuarto(_s(d['numero']));
      if (idx < 0) throw Exception('Não achei o quarto ${_s(d['numero'])}.');
      if (g.listaQuartos[idx].status != 'Ocupado') throw Exception('O quarto ${_s(d['numero'])} não está ocupado.');
      g.realizarCheckOut(idx);
      globalAtualizar.value++;
      return 'check-out do quarto ${_s(d['numero'])} realizado.';
  }
  throw Exception('Ação desconhecida.');
}