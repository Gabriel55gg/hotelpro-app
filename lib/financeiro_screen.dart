import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'assistente_sheet.dart';

// =============================================================================
//  FINANCEIRO (nova versão)
//  - Seletor de mês + comparação com o mês anterior
//  - Cartão principal com lucro animado, margem e barra de receita x gasto
//  - Gráfico dos últimos 6 meses (toque numa barra para trocar de mês)
//  - Gastos por categoria (toque para filtrar a lista)
//  - Cartão da Aurora com insight automático
//  - Movimentações agrupadas por dia, com busca, filtros e detalhe
//  - Novo gasto com categoria e valores rápidos
//  - Botão de olho para ocultar os valores
// =============================================================================

const _mesesNome = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
const _mesesAbrev = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

const _catsGasto = <(String, String)>[
  ('🧹', 'Limpeza'),
  ('🍽️', 'Alimentação'),
  ('🔧', 'Manutenção'),
  ('💡', 'Contas'),
  ('👷', 'Equipe'),
  ('📦', 'Outros'),
];

const _palavras = <String, List<String>>{
  'Limpeza': ['limp', 'sabao', 'sabão', 'detergente', 'lavanderia', 'toalha', 'lencol', 'lençol', 'cloro'],
  'Alimentação': ['café', 'cafe', 'almoço', 'almoco', 'comida', 'mercado', 'padaria', 'aliment', 'bebida', 'jantar'],
  'Manutenção': ['manut', 'conserto', 'reparo', 'pintura', 'encanador', 'eletric', 'obra', 'ar condicionado'],
  'Contas': ['luz', 'energia', 'água', 'agua', 'internet', 'telefone', 'aluguel', 'imposto', 'taxa', 'gás', 'gas', 'conta'],
  'Equipe': ['salário', 'salario', 'funcion', 'diarista', 'camareira', 'pagamento', 'equipe', 'comiss'],
};

String _emojiCat(String nome) {
  for (final c in _catsGasto) {
    if (c.$2 == nome) return c.$1;
  }
  return nome == 'Hospedagem' ? '🛏️' : '📦';
}

class _Mov {
  final bool entrada;
  final String desc;
  final String cat;
  final DateTime data;
  final double valor;
  _Mov(this.entrada, this.desc, this.cat, this.data, this.valor);
}

List<_Mov> _carregarMovs() {
  final lista = globalGerenciador.historicoCaixa.map((t) {
    final entrada = t.tipo == 'Entrada';
    var desc = t.descricao.toString();
    var cat = entrada ? 'Hospedagem' : 'Outros';
    if (!entrada) {
      var achou = false;
      for (final c in _catsGasto) {
        if (desc == c.$2) {
          cat = c.$2;
          achou = true;
          break;
        }
        if (desc.startsWith('${c.$2} · ')) {
          cat = c.$2;
          desc = desc.substring(c.$2.length + 3);
          achou = true;
          break;
        }
      }
      if (!achou) {
        final low = desc.toLowerCase();
        for (final e in _palavras.entries) {
          if (e.value.any(low.contains)) {
            cat = e.key;
            break;
          }
        }
      }
    }
    return _Mov(entrada, desc, cat, t.data, t.valor.toDouble());
  }).toList();
  lista.sort((a, b) => b.data.compareTo(a.data));
  return lista;
}

DateTime _addMes(DateTime m, int d) => DateTime(m.year, m.month + d);
bool _mesmoMes(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
double _soma(List<_Mov> l, DateTime m, bool entrada) =>
    l.where((e) => e.entrada == entrada && _mesmoMes(e.data, m)).fold(0.0, (a, e) => a + e.valor);

String _hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _rotuloDia(DateTime d) {
  final h = DateTime.now();
  final hoje = DateTime(h.year, h.month, h.day);
  final dia = DateTime(d.year, d.month, d.day);
  final diff = hoje.difference(dia).inDays;
  if (diff == 0) return 'HOJE';
  if (diff == 1) return 'ONTEM';
  return dataBr(d);
}

class _Aparece extends StatelessWidget {
  final int ordem;
  final Widget child;
  const _Aparece({required this.ordem, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + ordem * 90),
      curve: Curves.easeOutCubic,
      builder: (_, v, ch) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: ch)),
      child: child,
    );
  }
}

class FinanceiroScreenTab extends StatefulWidget {
  const FinanceiroScreenTab({super.key});

  @override
  State<FinanceiroScreenTab> createState() => _FinanceiroScreenTabState();
}

class _FinanceiroScreenTabState extends State<FinanceiroScreenTab> {
  late DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  int _filtro = 0; // 0 tudo, 1 entradas, 2 gastos
  String _busca = '';
  String? _catFiltro;
  bool _oculto = false;

  String _v(double v) => _oculto ? 'R\$ ••••' : moeda(v);

  bool get _ehMesAtual => !_mes.isBefore(DateTime(DateTime.now().year, DateTime.now().month));

  // ---------------------------------------------------------------- BUILD
  @override
  Widget build(BuildContext context) {
    final todos = _carregarMovs();
    final doMes = todos.where((m) => _mesmoMes(m.data, _mes)).toList();
    final ent = _soma(todos, _mes, true);
    final sai = _soma(todos, _mes, false);
    final lucro = ent - sai;
    final ant = _addMes(_mes, -1);
    final lucroAnt = _soma(todos, ant, true) - _soma(todos, ant, false);

    final lista = doMes.where((m) {
      if (_filtro == 1 && !m.entrada) return false;
      if (_filtro == 2 && m.entrada) return false;
      if (_catFiltro != null && m.cat != _catFiltro) return false;
      if (_busca.isNotEmpty && !m.desc.toLowerCase().contains(_busca.toLowerCase()) && !m.cat.toLowerCase().contains(_busca.toLowerCase())) return false;
      return true;
    }).toList();

    final itens = <Object>[];
    String? ultimo;
    for (final m in lista) {
      final k = dataBr(m.data);
      if (k != ultimo) {
        itens.add(_rotuloDia(m.data));
        ultimo = k;
      }
      itens.add(m);
    }

    final c = context.c;
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Aparece(ordem: 0, child: _cabecalho(context)),
                  const SizedBox(height: 14),
                  _Aparece(ordem: 0, child: _seletorMes(context)),
                  const SizedBox(height: 12),
                  _Aparece(ordem: 1, child: _hero(context, lucro, ent, sai, lucroAnt)),
                  const SizedBox(height: 12),
                  _Aparece(ordem: 2, child: _grafico(context, todos)),
                  const SizedBox(height: 12),
                  _Aparece(ordem: 3, child: _categorias(context, doMes, sai)),
                  const SizedBox(height: 12),
                  _Aparece(ordem: 4, child: _aurora(context, doMes, lucro, sai)),
                  const SizedBox(height: 22),
                  Text('Movimentações', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3, color: c.text)),
                  const SizedBox(height: 10),
                  _busca_(context),
                  const SizedBox(height: 10),
                  FiltroChips(opcoes: const ['Tudo', 'Entradas', 'Gastos'], selecionado: _filtro, onChanged: (i) => setState(() => _filtro = i)),
                  if (_catFiltro != null) ...[
                    const SizedBox(height: 10),
                    BotaoAnimado(
                      onTap: () => setState(() => _catFiltro = null),
                      child: Selo(texto: '${_emojiCat(_catFiltro!)} $_catFiltro  ✕', cor: c.brandDark, fundo: c.brandSoft),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (itens.isEmpty)
            SliverToBoxAdapter(child: SizedBox(height: 220, child: estadoVazio(context, '🧾', 'Nenhuma movimentação', 'Nada por aqui neste mês ou filtro.')))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final it = itens[i];
                    if (it is String) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
                        child: Text(it, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: c.text3)),
                      );
                    }
                    return _tile(ctx, it as _Mov);
                  },
                  childCount: itens.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- PARTES
  Widget _iconBtn(BuildContext context, IconData ic, String rotulo, VoidCallback onTap) {
    final c = context.c;
    return Semantics(
      button: true,
      label: rotulo,
      child: BotaoAnimado(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, border: Border.all(color: c.border, width: c.bw)),
          child: Icon(ic, size: 20, color: c.text2),
        ),
      ),
    );
  }

  Widget _cabecalho(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Financeiro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: c.text)),
              Text('Seu caixa em tempo real', style: TextStyle(fontSize: 13, color: c.text2)),
            ],
          ),
        ),
        _iconBtn(context, _oculto ? Icons.visibility_off_rounded : Icons.visibility_rounded, _oculto ? 'Mostrar valores' : 'Ocultar valores', () {
          HapticFeedback.selectionClick();
          setState(() => _oculto = !_oculto);
        }),
        const SizedBox(width: 8),
        BotaoSolido(label: 'Novo gasto', glifo: '−', color: c.red, onTap: _novoGasto),
      ],
    );
  }

  Widget _seletorMes(BuildContext context) {
    final c = context.c;
    Widget seta(IconData ic, bool ativo, VoidCallback onTap) => BotaoAnimado(
          onTap: ativo ? onTap : () {},
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(ic, size: 22, color: ativo ? c.text : c.text3.withValues(alpha: 0.4)),
          ),
        );
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(99), border: Border.all(color: c.border, width: c.bw)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seta(Icons.chevron_left_rounded, true, () => setState(() => _mes = _addMes(_mes, -1))),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: SizedBox(
                key: ValueKey(_mes),
                width: 150,
                child: Text(
                  '${_mesesNome[_mes.month - 1][0].toUpperCase()}${_mesesNome[_mes.month - 1].substring(1)} ${_mes.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.text),
                ),
              ),
            ),
            seta(Icons.chevron_right_rounded, !_ehMesAtual, () => setState(() => _mes = _addMes(_mes, 1))),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, double lucro, double ent, double sai, double lucroAnt) {
    final c = context.c;
    final negativo = lucro < 0;
    final base = negativo ? c.red : c.brand;
    final fg = textoSobre(base);
    final margem = ent > 0 ? lucro / ent * 100 : 0.0;
    final gasto = ent > 0 ? (sai / ent).clamp(0.0, 1.0) : (sai > 0 ? 1.0 : 0.0);

    String? delta;
    if (lucroAnt != 0) {
      final p = (lucro - lucroAnt) / lucroAnt.abs() * 100;
      delta = '${p >= 0 ? '▲' : '▼'} ${p.abs().toStringAsFixed(0)}% vs mês anterior';
    }

    Widget pill(IconData ic, String t, double v) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: fg.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(ic, size: 16, color: fg),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg.withValues(alpha: 0.75))),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(_v(v), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: base,
        gradient: c.hc
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(base, Colors.white, 0.25)!, base, Color.lerp(base, Colors.black, 0.22)!],
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: c.hc ? const [] : [BoxShadow(color: base.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(negativo ? 'Prejuízo do mês' : 'Lucro líquido do mês', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg.withValues(alpha: 0.8)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: fg.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
                child: Text('Margem ${margem.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: lucro),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(_v(v), style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1, color: fg)),
            ),
          ),
          if (delta != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(delta, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg.withValues(alpha: 0.8))),
            ),
          const SizedBox(height: 16),
          Row(children: [pill(Icons.south_west_rounded, 'Entradas', ent), const SizedBox(width: 10), pill(Icons.north_east_rounded, 'Gastos', sai)]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: gasto),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 7, backgroundColor: fg.withValues(alpha: 0.2), color: fg),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ent > 0 ? '${(gasto * 100).toStringAsFixed(0)}% da receita virou gasto' : (sai > 0 ? 'Gastos sem receita no mês' : 'Sem movimentações no mês'),
            style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _grafico(BuildContext context, List<_Mov> todos) {
    final c = context.c;
    final meses = List.generate(6, (i) => _addMes(_mes, i - 5));
    final dados = meses.map((m) => (m, _soma(todos, m, true), _soma(todos, m, false))).toList();
    final maxV = dados.fold<double>(0, (a, d) => math.max(a, math.max(d.$2, d.$3)));
    const altura = 96.0;

    Widget barra(double v, Color cor) {
      final h = maxV > 0 ? (v / maxV * altura) : 0.0;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: v > 0 ? math.max(h, 4) : 0),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (_, hh, _) => Container(width: 9, height: hh, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(4))),
      );
    }

    Widget legenda(Color cor, String t) => Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.text2)),
        ]);

    return HCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Últimos 6 meses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text))),
              legenda(c.green, 'Entradas'),
              const SizedBox(width: 12),
              legenda(c.red, 'Gastos'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: dados.map((d) {
              final sel = _mesmoMes(d.$1, _mes);
              return Expanded(
                child: BotaoAnimado(
                  onTap: () => setState(() => _mes = d.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? c.brandSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? c.brand.withValues(alpha: 0.6) : Colors.transparent, width: c.bw),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: altura,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [barra(d.$2, c.green), const SizedBox(width: 3), barra(d.$3, c.red)],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_mesesAbrev[d.$1.month - 1], style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w800 : FontWeight.w600, color: sel ? c.brandDark : c.text3)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _categorias(BuildContext context, List<_Mov> doMes, double sai) {
    final c = context.c;
    final mapa = <String, double>{};
    for (final m in doMes.where((m) => !m.entrada)) {
      mapa[m.cat] = (mapa[m.cat] ?? 0) + m.valor;
    }
    final ordenado = mapa.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return HCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Para onde o dinheiro foi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
          const SizedBox(height: 2),
          Text('Toque numa categoria para filtrar', style: TextStyle(fontSize: 12, color: c.text2)),
          const SizedBox(height: 12),
          if (ordenado.isEmpty)
            Row(children: [
              const Emo('🎉', tamanho: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Nenhum gasto neste mês.', style: TextStyle(fontSize: 13, color: c.text2))),
            ])
          else
            ...ordenado.map((e) {
              final pct = sai > 0 ? e.value / sai : 0.0;
              final ativo = _catFiltro == e.key;
              return BotaoAnimado(
                onTap: () => setState(() {
                  _catFiltro = ativo ? null : e.key;
                  _filtro = 2;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ativo ? c.brandSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ativo ? c.brand.withValues(alpha: 0.6) : Colors.transparent, width: c.bw),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.redSoft, borderRadius: BorderRadius.circular(11)),
                        child: Emo(_emojiCat(e.key), tamanho: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(e.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text))),
                                Text(_v(e.value), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.text)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: pct),
                                      duration: const Duration(milliseconds: 700),
                                      curve: Curves.easeOutCubic,
                                      builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: c.track, color: c.red),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${(pct * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.text3)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _insight(List<_Mov> doMes, double lucro, double sai) {
    if (doMes.isEmpty) {
      return 'Ainda não há movimentações neste mês. Registre um gasto ou faça um check-in e eu analiso tudo para você.';
    }
    final mapa = <String, double>{};
    for (final m in doMes.where((m) => !m.entrada)) {
      mapa[m.cat] = (mapa[m.cat] ?? 0) + m.valor;
    }
    final abertura = lucro < 0 ? 'Atenção: o caixa está negativo em ${moeda(lucro.abs())}. ' : 'O caixa está positivo em ${moeda(lucro)}. ';
    if (mapa.isEmpty) return '${abertura}Nenhum gasto registrado no mês.';
    final top = mapa.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final pct = sai > 0 ? (top.value / sai * 100).toStringAsFixed(0) : '0';
    return '$abertura${top.key} é o maior gasto ($pct% das saídas). Quer que eu procure onde economizar?';
  }

  Widget _aurora(BuildContext context, List<_Mov> doMes, double lucro, double sai) {
    final c = context.c;
    const perguntas = <(String, String)>[('📊', 'Resumo do mês'), ('🧾', 'Maiores gastos'), ('💰', 'Como está o caixa?')];

    return Semantics(
      button: true,
      label: 'Abrir assistente $kNomeAssistente',
      child: BotaoAnimado(
        onTap: () => abrirAssistente(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface,
            gradient: c.hc ? null : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.brandSoft, c.surface]),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.brand.withValues(alpha: c.hc ? 1 : 0.55), width: c.bw),
            boxShadow: c.hc ? const [] : [BoxShadow(color: c.brand.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AvatarAssistente(tamanho: 46, online: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kNomeAssistente, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.text)),
                        Text('Sua assistente financeira com IA', style: TextStyle(fontSize: 12, color: c.text2)),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
                    child: Icon(Icons.arrow_forward_rounded, size: 18, color: c.onBrand),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: c.bg.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: c.border, width: c.bw),
                ),
                child: Text(_insight(doMes, lucro, sai), style: TextStyle(fontSize: 13, height: 1.4, color: c.text)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: perguntas
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(99), border: Border.all(color: c.brand.withValues(alpha: 0.5), width: c.bw)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Emo(p.$1, tamanho: 13),
                            const SizedBox(width: 5),
                            Text(p.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text)),
                          ]),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _busca_(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border, width: c.bw)),
      child: TextField(
        onChanged: (t) => setState(() => _busca = t.trim()),
        cursorColor: c.brand,
        style: TextStyle(color: c.text, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar movimentação...',
          hintStyle: TextStyle(color: c.text3),
          prefixIcon: Icon(Icons.search_rounded, color: c.text3),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, _Mov m) {
    final c = context.c;
    final cor = m.entrada ? c.green : c.red;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BotaoAnimado(
        onTap: () => _detalhe(m),
        child: HCard(
          radius: 16,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: m.entrada ? c.greenSoft : c.redSoft, borderRadius: BorderRadius.circular(13)),
                child: Emo(_emojiCat(m.cat), tamanho: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: c.text)),
                    Text('${m.cat} · ${_hhmm(m.data)}', style: TextStyle(fontSize: 12, color: c.text2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${m.entrada ? '+' : '-'} ${_v(m.valor)}', style: TextStyle(fontWeight: FontWeight.w800, color: cor, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- SHEETS
  BoxDecoration _decoSheet(HotelColors c) => BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: c.border, width: c.bw),
      );

  void _detalhe(_Mov m) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 412),
      builder: (ctx) {
        final c = ctx.c;
        final cor = m.entrada ? c.green : c.red;
        Widget linha(String t, String v) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t, style: TextStyle(fontSize: 14, color: c.text2)),
                  Flexible(child: Text(v, textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text))),
                ],
              ),
            );
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: _decoSheet(c),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44, height: 5, decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: m.entrada ? c.greenSoft : c.redSoft, shape: BoxShape.circle),
                child: Emo(_emojiCat(m.cat), tamanho: 30),
              ),
              const SizedBox(height: 12),
              Text('${m.entrada ? '+' : '-'} ${moeda(m.valor)}', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: cor)),
              const SizedBox(height: 6),
              Selo(texto: m.entrada ? 'Entrada' : 'Gasto', cor: cor, fundo: m.entrada ? c.greenSoft : c.redSoft),
              const SizedBox(height: 14),
              Divider(color: c.border, height: 1),
              linha('Descrição', m.desc),
              linha('Categoria', m.cat),
              linha('Data', '${dataBr(m.data)} às ${_hhmm(m.data)}'),
            ],
          ),
        );
      },
    );
  }

  void _novoGasto() {
    final descCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    var cat = 'Outros';
    String? erro;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 412),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          final c = ctx.c;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: _decoSheet(c),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(99)))),
                    const SizedBox(height: 18),
                    Text('Registrar gasto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.text)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: valorCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      cursorColor: c.brand,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.red),
                      decoration: deco(ctx, 'Valor (R\$) *'),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [20, 50, 100, 200, 500].map((v) {
                        return BotaoAnimado(
                          onTap: () => setS(() {
                            valorCtrl.text = (lerValor(valorCtrl.text) + v).toStringAsFixed(2).replaceAll('.', ',');
                            erro = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(99), border: Border.all(color: c.border, width: c.bw)),
                            child: Text('+ $v', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text2)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text('Categoria', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.text2)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _catsGasto.map((k) {
                        final sel = cat == k.$2;
                        return BotaoAnimado(
                          onTap: () => setS(() => cat = k.$2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: sel ? c.brand : c.surface,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: sel ? c.brand : c.border, width: c.bw),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Emo(k.$1, tamanho: 14),
                              const SizedBox(width: 6),
                              Text(k.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? c.onBrand : c.text2)),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    campo(ctx, descCtrl, 'Descrição (opcional)'),
                    if (erro != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(erro!, style: TextStyle(color: c.red, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    const SizedBox(height: 18),
                    BotaoAnimado(
                      onTap: () {
                        final valor = lerValor(valorCtrl.text);
                        if (valor <= 0) {
                          setS(() => erro = 'Informe um valor maior que zero.');
                          return;
                        }
                        final d = descCtrl.text.trim();
                        globalGerenciador.adicionarGasto(d.isEmpty ? cat : '$cat · $d', valor);
                        Navigator.pop(ctx);
                        setState(() {});
                        aviso(context, 'Gasto de ${moeda(valor)} registrado');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.red, borderRadius: BorderRadius.circular(16)),
                        child: Text('Salvar gasto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textoSobre(c.red))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}