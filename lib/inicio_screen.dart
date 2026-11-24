import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'assistente_sheet.dart';

// =============================================================================
//  NOME DA POUSADA (carregado no login, usado em várias telas)
// =============================================================================
final ValueNotifier<String> globalNomePousada = ValueNotifier<String>('');

String nomeDoEmail(String email) {
  final u = email.split('@').first.trim();
  if (u.isEmpty) return 'Minha Pousada';
  return u[0].toUpperCase() + u.substring(1);
}

/// Procura o nome da pousada na linha da tabela `empresas`.
/// Se não achar nenhuma coluna de nome, usa o começo do e-mail.
String nomeDaPousada(Map<String, dynamic> emp, String email) {
  for (final k in ['nome_pousada', 'nome_fantasia', 'nome', 'pousada', 'name', 'razao_social', 'empresa']) {
    final v = emp[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return nomeDoEmail(email);
}

// =============================================================================
//  ANIMAÇÕES SUTIS
// =============================================================================
class _Entra extends StatelessWidget {
  final int ordem;
  final Widget child;
  const _Entra({required this.ordem, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + ordem * 70),
      curve: Curves.easeOutCubic,
      builder: (_, v, ch) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: ch)),
      child: child,
    );
  }
}

class _Conta extends StatelessWidget {
  final double valor;
  final String Function(double) formato;
  final TextStyle estilo;
  const _Conta({required this.valor, required this.formato, required this.estilo});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(formato(v), style: estilo),
    );
  }
}

// =============================================================================
//  TELA INÍCIO (painel da recepção)
// =============================================================================
const _diasLongo = ['segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado', 'domingo'];
const _mesesLongo = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];

String _saud() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Bom dia';
  if (h < 18) return 'Boa tarde';
  return 'Boa noite';
}

String _hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

Widget _rotulo(BuildContext context, String t) =>
    Text(t.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: context.c.text3));

Widget _iconeBox(BuildContext context, IconData ic, {Color? cor, Color? bg, double tam = 40}) {
  final c = context.c;
  return Container(
    width: tam,
    height: tam,
    decoration: BoxDecoration(color: bg ?? c.brandSoft, borderRadius: BorderRadius.circular(12)),
    child: Icon(ic, size: tam * 0.5, color: cor ?? c.brand),
  );
}

class InicioHotelScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;

  /// Troca a aba do app: 0 Início, 1 Quartos, 2 Hóspedes, 3 Financeiro.
  final ValueChanged<int>? onNavegar;

  const InicioHotelScreen({super.key, required this.onOpenDrawer, this.onNavegar});

  @override
  State<InicioHotelScreen> createState() => _InicioHotelScreenState();
}

class _InicioHotelScreenState extends State<InicioHotelScreen> {
  late final Timer _relogio;
  DateTime _agora = DateTime.now();
  int _filtro = 0; // 0 todos, 1 livres, 2 ocupados
  bool _ocultar = false;

  @override
  void initState() {
    super.initState();
    _relogio = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _agora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _relogio.cancel();
    super.dispose();
  }

  String _v(double v) => _ocultar ? 'R\$ ••••' : moeda(v);

  @override
  Widget build(BuildContext context) {
    final g = globalGerenciador;
    final quartos = g.listaQuartos;
    final total = quartos.length;
    final ocupados = quartos.where((q) => q.status == 'Ocupado').toList();
    final ocup = ocupados.length;
    final livres = total - ocup;
    final entradas = g.getTotalEntradasMesAtual();
    final saidas = g.getTotalSaidasMesAtual();
    final lucro = g.getLucroLiquidoMesAtual();

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Entra(ordem: 0, child: _topo(context)),
            const SizedBox(height: 18),
            _Entra(ordem: 1, child: _titulo(context)),
            const SizedBox(height: 18),
            _Entra(ordem: 2, child: _situacao(context, ocup, livres, total)),
            const SizedBox(height: 22),
            _Entra(ordem: 3, child: _mapa(context, quartos, ocup, livres)),
            const SizedBox(height: 22),
            _Entra(ordem: 4, child: _hospedes(context, ocupados)),
            const SizedBox(height: 22),
            _Entra(ordem: 5, child: _financeiro(context, lucro, entradas, saidas)),
            const SizedBox(height: 12),
            _Entra(ordem: 6, child: _aurora(context)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ topo
  Widget _botaoTopo(BuildContext context, IconData ic, String rotulo, VoidCallback onTap) {
    final c = context.c;
    return Semantics(
      button: true,
      label: rotulo,
      child: BotaoAnimado(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: c.border, width: c.bw)),
          child: Icon(ic, size: 21, color: c.text),
        ),
      ),
    );
  }

  Widget _topo(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        _botaoTopo(context, Icons.menu_rounded, 'Abrir menu', widget.onOpenDrawer),
        const Spacer(),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: c.border, width: c.bw)),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: c.brand),
              const SizedBox(width: 8),
              Text(_hhmm(_agora), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _botaoTopo(context, Icons.auto_awesome_rounded, 'Abrir assistente', () => abrirAssistente(context)),
      ],
    );
  }

  Widget _titulo(BuildContext context) {
    final c = context.c;
    return ValueListenableBuilder<String>(
      valueListenable: globalNomePousada,
      builder: (_, nome, _) {
        final n = nome.trim().isEmpty ? 'Sua pousada' : nome.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PAINEL DA POUSADA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2.2, color: c.brand)),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(n, key: ValueKey(n), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.9, height: 1.08, color: c.text)),
            ),
            const SizedBox(height: 8),
            Text('${_saud()}  ·  ${_diasLongo[_agora.weekday - 1]}, ${_agora.day} de ${_mesesLongo[_agora.month - 1]}', style: TextStyle(fontSize: 13, color: c.text2)),
            const SizedBox(height: 16),
            Container(height: 1.5, decoration: BoxDecoration(gradient: LinearGradient(colors: [c.brand, c.brand.withValues(alpha: 0)]))),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------- situação agora
  Widget _situacao(BuildContext context, int ocup, int livres, int total) {
    final c = context.c;
    final taxa = total > 0 ? ocup / total : 0.0;
    final semVaga = total > 0 && livres == 0;

    Widget bloco(String t, int v, Color cor, {bool grande = false}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t, style: TextStyle(fontSize: 12, color: c.text2, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              _Conta(valor: v.toDouble(), formato: (x) => '${x.round()}', estilo: TextStyle(fontSize: grande ? 44 : 30, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.1, color: cor)),
            ],
          ),
        );

    return HCard(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rotulo(context, 'Situação agora'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              bloco('Disponíveis', livres, semVaga ? c.red : c.green, grande: true),
              bloco('Ocupados', ocup, c.text),
              bloco('Total', total, c.text3),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: taxa),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 8, backgroundColor: c.track, color: c.brand),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  total == 0
                      ? 'Cadastre os quartos na aba Quartos.'
                      : semVaga
                          ? 'Sem quartos disponíveis no momento.'
                          : '$livres quarto(s) disponível(is) para check-in.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: semVaga ? c.red : c.text2),
                ),
              ),
              Text('${(taxa * 100).round()}% ocupado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.brandDark)),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- mapa
  Widget _mapa(BuildContext context, List quartos, int ocup, int livres) {
    final c = context.c;
    final visiveis = quartos.where((q) {
      final o = q.status == 'Ocupado';
      return _filtro == 0 || (_filtro == 1 && !o) || (_filtro == 2 && o);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rotulo(context, 'Quartos'),
        const SizedBox(height: 10),
        if (quartos.isEmpty)
          HCard(
            radius: 16,
            child: Row(children: [
              _iconeBox(context, Icons.meeting_room_outlined, cor: c.text3, bg: c.track),
              const SizedBox(width: 12),
              Expanded(child: Text('Nenhum quarto cadastrado. Adicione na aba Quartos.', style: TextStyle(fontSize: 13, color: c.text2))),
            ]),
          )
        else ...[
          FiltroChips(
            opcoes: ['Todos (${quartos.length})', 'Livres ($livres)', 'Ocupados ($ocup)'],
            selecionado: _filtro,
            onChanged: (i) => setState(() => _filtro = i),
          ),
          const SizedBox(height: 12),
          HCard(
            radius: 16,
            child: visiveis.isEmpty
                ? Text('Nenhum quarto neste filtro.', style: TextStyle(fontSize: 13, color: c.text2))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: visiveis.map((q) {
                      final ocupado = q.status == 'Ocupado';
                      final cor = ocupado ? c.red : c.green;
                      return BotaoAnimado(
                        onTap: () => _sheetQuarto(context, q),
                        child: Container(
                          width: 60,
                          height: 52,
                          decoration: BoxDecoration(
                            color: ocupado ? c.redSoft : c.greenSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cor.withValues(alpha: c.hc ? 1 : 0.55), width: c.bw),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${q.id}', style: TextStyle(color: c.text, fontWeight: FontWeight.w800, fontSize: 15)),
                              const SizedBox(height: 1),
                              Text(ocupado ? 'Ocupado' : 'Livre', style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 9.5)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------- hóspedes
  Widget _hospedes(BuildContext context, List ocupados) {
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: _rotulo(context, 'Hóspedes na casa')),
          Text('${ocupados.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.brand)),
        ]),
        const SizedBox(height: 10),
        if (ocupados.isEmpty)
          HCard(
            radius: 16,
            child: Row(children: [
              _iconeBox(context, Icons.bedtime_outlined, cor: c.text3, bg: c.track),
              const SizedBox(width: 12),
              Expanded(child: Text('Nenhum hóspede no momento.', style: TextStyle(fontSize: 13, color: c.text2))),
            ]),
          )
        else
          HCard(
            radius: 16,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < ocupados.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: c.borderSoft),
                  _linhaHospede(context, ocupados[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _linhaHospede(BuildContext context, dynamic q) {
    final c = context.c;
    final nome = '${q.hospedePrincipal}'.trim();
    final tel = '${q.telefone}'.trim();
    final temTel = tel.isNotEmpty && tel != 'null';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: BotaoAnimado(
              onTap: () => _sheetQuarto(context, q),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle, border: Border.all(color: c.brand.withValues(alpha: 0.5), width: c.bw)),
                    child: Text(nome.isEmpty ? '?' : nome[0].toUpperCase(), style: TextStyle(color: c.brandDark, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                        Text('Quarto ${q.id} · ${q.tipo}', style: TextStyle(fontSize: 12, color: c.text2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (temTel)
            Semantics(
              button: true,
              label: 'Copiar telefone de $nome',
              child: BotaoAnimado(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: tel));
                  HapticFeedback.mediumImpact();
                  aviso(context, 'Telefone copiado: $tel');
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border, width: c.bw)),
                  child: Icon(Icons.call_outlined, size: 18, color: c.text2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- financeiro
  Widget _financeiro(BuildContext context, double lucro, double ent, double sai) {
    final c = context.c;
    final neg = lucro < 0;

    Widget coluna(String t, double v, Color cor, {bool destaque = false}) => Expanded(
          flex: destaque ? 6 : 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t, style: TextStyle(fontSize: 12, color: c.text2, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_v(v), style: TextStyle(fontSize: destaque ? 20 : 15, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: cor)),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: _rotulo(context, 'Resumo financeiro do mês')),
          Semantics(
            button: true,
            label: _ocultar ? 'Mostrar valores' : 'Ocultar valores',
            child: BotaoAnimado(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _ocultar = !_ocultar);
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(_ocultar ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: c.text3),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        BotaoAnimado(
          onTap: () => widget.onNavegar?.call(3),
          child: HCard(
            radius: 16,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                coluna('Lucro líquido', lucro, neg ? c.red : c.text, destaque: true),
                Container(width: c.bw, height: 36, color: c.border, margin: const EdgeInsets.symmetric(horizontal: 12)),
                coluna('Entradas', ent, c.green),
                const SizedBox(width: 8),
                coluna('Gastos', sai, c.red),
                if (widget.onNavegar != null) Icon(Icons.chevron_right_rounded, color: c.text3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _aurora(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: 'Abrir assistente $kNomeAssistente',
      child: BotaoAnimado(
        onTap: () => abrirAssistente(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.brandSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.brand.withValues(alpha: c.hc ? 1 : 0.4), width: c.bw),
          ),
          child: Row(
            children: [
              const AvatarAssistente(tamanho: 40, online: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pergunte à $kNomeAssistente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.text)),
                    Text('Análises do caixa, gastos e ocupação', style: TextStyle(fontSize: 12, color: c.text2)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 20, color: c.brand),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ detalhe quarto
  void _sheetQuarto(BuildContext context, dynamic q) {
    HapticFeedback.lightImpact();
    final ocupado = q.status == 'Ocupado';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 412),
      builder: (ctx) {
        final c = ctx.c;
        final cor = ocupado ? c.red : c.green;

        Widget linha(String t, String v) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(t, style: TextStyle(fontSize: 14, color: c.text2)),
                Flexible(child: Text(v, textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text))),
              ]),
            );

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: c.border, width: c.bw),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44, height: 5, decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 18),
              Row(
                children: [
                  _iconeBox(ctx, ocupado ? Icons.luggage_outlined : Icons.king_bed_outlined, cor: cor, bg: ocupado ? c.redSoft : c.greenSoft, tam: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quarto ${q.id}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.text)),
                        Text('${q.tipo}', style: TextStyle(fontSize: 13, color: c.text2)),
                      ],
                    ),
                  ),
                  Selo(texto: ocupado ? 'Ocupado' : 'Disponível', cor: cor, fundo: ocupado ? c.redSoft : c.greenSoft),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: c.border, height: 1),
              linha('Diária', moeda((q.valorDiaria as num).toDouble())),
              if (ocupado) ...[
                Divider(color: c.borderSoft, height: 1),
                linha('Hóspede', '${q.hospedePrincipal}'),
                Divider(color: c.borderSoft, height: 1),
                linha('Telefone', '${q.telefone}'),
                Divider(color: c.borderSoft, height: 1),
                linha('Placa do veículo', '${q.placaVeiculo}'),
              ],
              if (widget.onNavegar != null) ...[
                const SizedBox(height: 16),
                BotaoAnimado(
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onNavegar!(1);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: ocupado ? kAmarelo : c.green, borderRadius: BorderRadius.circular(14)),
                    child: Text(
                      ocupado ? 'Ir para o check-out' : 'Ir para o check-in',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textoSobre(ocupado ? kAmarelo : c.green)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}