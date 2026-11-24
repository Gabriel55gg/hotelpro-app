import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

/// >>> O NOME DA SUA ASSISTENTE: troque aqui e pronto (app e IA usam o mesmo nome). <<<
const String kNomeAssistente = 'Aurora';

LinearGradient? _gradMarca(HotelColors c) => c.hc
    ? null
    : LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(c.brand, Colors.white, 0.2)!, c.brand],
      );

String _saudacao() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Bom dia';
  if (h < 18) return 'Boa tarde';
  return 'Boa noite';
}

String _hora(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Avatar da assistente (círculo dourado com brilho e bolinha de "online").
class AvatarAssistente extends StatelessWidget {
  final double tamanho;
  final bool online;
  const AvatarAssistente({super.key, this.tamanho = 44, this.online = false});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      label: 'Assistente $kNomeAssistente',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: tamanho,
            height: tamanho,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.brand,
              gradient: _gradMarca(c),
              boxShadow: c.hc ? const [] : [BoxShadow(color: c.brand.withValues(alpha: 0.4), blurRadius: tamanho * 0.35, offset: const Offset(0, 4))],
            ),
            child: Icon(Icons.auto_awesome_rounded, color: c.onBrand, size: tamanho * 0.5),
          ),
          if (online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: tamanho * 0.28,
                height: tamanho * 0.28,
                decoration: BoxDecoration(color: c.green, shape: BoxShape.circle, border: Border.all(color: c.bg, width: 2)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Msg {
  final bool minha;
  final String texto;
  final DateTime hora = DateTime.now();
  _Msg(this.minha, this.texto);
}

void abrirAssistente(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 412),
    builder: (_) => const AssistenteIASheet(),
  );
}

class AssistenteIASheet extends StatefulWidget {
  const AssistenteIASheet({super.key});

  @override
  State<AssistenteIASheet> createState() => _AssistenteIASheetState();
}

class _AssistenteIASheetState extends State<AssistenteIASheet> {
  final _msgs = <_Msg>[];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _pensando = false;

  static const _sugestoes = <(String, String, String)>[
    ('📊', 'Resumo do mês', 'Entradas, gastos e lucro'),
    ('🧾', 'Maiores gastos', 'Para onde o dinheiro foi'),
    ('💰', 'Como está o caixa?', 'Saldo e lucro líquido'),
    ('🛏️', 'Ocupação', 'Quartos livres e ocupados'),
  ];

  @override
  void initState() {
    super.initState();
    globalFinanceiroIA.novaConversa();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _rolar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      }
    });
  }

  void _novaConversa() {
    HapticFeedback.selectionClick();
    globalFinanceiroIA.novaConversa();
    setState(() {
      _msgs.clear();
      _pensando = false;
    });
  }

  Future<void> _enviar(String texto) async {
    final t = texto.trim();
    if (t.isEmpty || _pensando) return;
    HapticFeedback.selectionClick();
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(true, t));
      _pensando = true;
    });
    _rolar();

    String resposta;
    try {
      resposta = await globalFinanceiroIA.perguntar(t, contextoFinanceiroParaIA());
    } catch (_) {
      resposta = 'Não consegui responder agora. Tente de novo em instantes.';
    }
    if (!mounted) return;
    setState(() {
      _msgs.add(_Msg(false, resposta));
      _pensando = false;
    });
    _rolar();
  }

  // ------------------------------------------------------------ partes da tela
  Widget _cabecalho(BuildContext context) {
    final c = context.c;
    final demo = globalFinanceiroIA is IaLocalDemo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 6, 12),
      child: Row(
        children: [
          const AvatarAssistente(tamanho: 46, online: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kNomeAssistente, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.text)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Assistente financeira', style: TextStyle(fontSize: 12, color: c.text2)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(99), border: Border.all(color: c.brand.withValues(alpha: 0.5), width: c.bw)),
                      child: Text(demo ? 'DEMO' : 'IA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c.brandDark)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_msgs.isNotEmpty)
            IconButton(
              tooltip: 'Nova conversa',
              onPressed: _novaConversa,
              icon: Icon(Icons.refresh_rounded, color: c.text2),
            ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: c.text2),
          ),
        ],
      ),
    );
  }

  Widget _boasVindas(BuildContext context) {
    final c = context.c;

    Widget cartao((String, String, String) s) {
      return Expanded(
        child: Semantics(
          button: true,
          label: '${s.$2}. ${s.$3}',
          excludeSemantics: true,
          child: BotaoAnimado(
            onTap: () => _enviar(s.$2),
            child: Container(
              height: 104,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border, width: c.bw),
                boxShadow: c.shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Emo(s.$1, tamanho: 22),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.text)),
                      const SizedBox(height: 2),
                      Text(s.$3, style: TextStyle(fontSize: 11, color: c.text2)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      children: [
        const SizedBox(height: 10),
        const Center(child: AvatarAssistente(tamanho: 84)),
        const SizedBox(height: 16),
        Text('${_saudacao()}! Eu sou a $kNomeAssistente.', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.text)),
        const SizedBox(height: 6),
        Text(
          'Cuido do financeiro do seu hotel. Posso resumir o caixa, apontar os maiores gastos e acompanhar a ocupação.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.4, color: c.text2),
        ),
        const SizedBox(height: 22),
        Text('Comece por aqui', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.text3, letterSpacing: 0.4)),
        const SizedBox(height: 10),
        Row(children: [cartao(_sugestoes[0]), const SizedBox(width: 10), cartao(_sugestoes[1])]),
        const SizedBox(height: 10),
        Row(children: [cartao(_sugestoes[2]), const SizedBox(width: 10), cartao(_sugestoes[3])]),
      ],
    );
  }

  Widget _balao(BuildContext context, _Msg m) {
    final c = context.c;
    final bolha = Container(
      constraints: const BoxConstraints(maxWidth: 270),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: m.minha ? c.brand : c.surface,
        gradient: m.minha ? _gradMarca(c) : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(m.minha ? 18 : 4),
          bottomRight: Radius.circular(m.minha ? 4 : 18),
        ),
        border: m.minha ? null : Border.all(color: c.border, width: c.bw),
      ),
      child: Text(m.texto, style: TextStyle(fontSize: 14, height: 1.4, color: m.minha ? c.onBrand : c.text)),
    );

    final hora = Padding(
      padding: EdgeInsets.only(top: 3, left: m.minha ? 0 : 36, right: m.minha ? 2 : 0),
      child: Text(_hora(m.hora), style: TextStyle(fontSize: 11, color: c.text3)),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: child)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: m.minha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (m.minha)
              bolha
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const AvatarAssistente(tamanho: 28),
                  const SizedBox(width: 8),
                  Flexible(
                    child: GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: m.texto));
                        HapticFeedback.mediumImpact();
                        aviso(context, 'Resposta copiada');
                      },
                      child: bolha,
                    ),
                  ),
                ],
              ),
            hora,
          ],
        ),
      ),
    );
  }

  Widget _conversa(BuildContext context) {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      children: [
        ..._msgs.map((m) => _balao(context, m)),
        if (_pensando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [AvatarAssistente(tamanho: 28), SizedBox(width: 8), _Pontinhos()]),
          ),
      ],
    );
  }

  Widget _chipsRapidos(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _sugestoes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => BotaoAnimado(
          onTap: () => _enviar(_sugestoes[i].$2),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: c.brand.withValues(alpha: c.hc ? 1 : 0.55), width: c.bw),
            ),
            child: Row(children: [
              Emo(_sugestoes[i].$1, tamanho: 14),
              const SizedBox(width: 6),
              Text(_sugestoes[i].$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _campoEnvio(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: c.border, width: c.bw),
              ),
              child: TextField(
                controller: _ctrl,
                onSubmitted: _enviar,
                textInputAction: TextInputAction.send,
                cursorColor: c.brand,
                style: TextStyle(color: c.text),
                decoration: InputDecoration(
                  hintText: 'Pergunte à $kNomeAssistente...',
                  hintStyle: TextStyle(color: c.text3),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: _pensando ? 'Aguarde a resposta' : 'Enviar pergunta',
            excludeSemantics: true,
            child: BotaoAnimado(
              onTap: () => _enviar(_ctrl.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.brand.withValues(alpha: _pensando ? 0.6 : 1),
                  gradient: _pensando ? null : _gradMarca(c),
                ),
                child: _pensando
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.onBrand))
                    : Icon(Icons.arrow_upward_rounded, color: c.onBrand, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final altura = MediaQuery.of(context).size.height * 0.88;
    final vazio = _msgs.isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: altura,
        decoration: BoxDecoration(
          color: c.bg,
          gradient: c.hc
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: const Alignment(0, -0.4),
                  colors: [c.brand.withValues(alpha: c.dark ? 0.14 : 0.18), c.bg],
                ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: c.border, width: c.bw),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 44, height: 5, decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(99))),
            _cabecalho(context),
            Divider(height: 1, color: c.border),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(key: ValueKey(vazio), child: vazio ? _boasVindas(context) : _conversa(context)),
              ),
            ),
            if (!vazio) _chipsRapidos(context),
            _campoEnvio(context),
          ],
        ),
      ),
    );
  }
}

class _Pontinhos extends StatefulWidget {
  const _Pontinhos();

  @override
  State<_Pontinhos> createState() => _PontinhosState();
}

class _PontinhosState extends State<_Pontinhos> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      label: '$kNomeAssistente está digitando',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border, width: c.bw),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final v = (math.sin(_c.value * 2 * math.pi - i * 0.9) + 1) / 2;
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(color: c.brand.withValues(alpha: 0.3 + 0.7 * v), shape: BoxShape.circle),
              );
            }),
          ),
        ),
      ),
    );
  }
}