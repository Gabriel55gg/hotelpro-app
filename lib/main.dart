import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, AuthState;
import 'models/quartos.dart';
import 'screens/login_screen.dart';
import 'ia_supabase.dart';
import 'assistente_sheet.dart';
import 'financeiro_screen.dart';
import 'inicio_screen.dart';
import 'ia_historico.dart';
import 'ia_acoes.dart';



// >>> COLE AQUI os dados do seu projeto (Supabase > Project Settings > API) <<<
const String kSupabaseUrl = 'https://iibdqeacrombeqerratn.supabase.co';
const String kSupabaseChave = 'sb_publishable_cPtt2IL5y1lESjhQ6CIOSw_VWw7cJjk'; // nunca use a service_role aqui

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseChave);
  runApp(const HotelProApp());
}

const bool kSeguirTemaDoSistema = false;

// =============================================================================
//  PALETA DE CORES (4 combinações: claro/escuro x normal/alto contraste)
//  Qualquer widget acessa as cores com:  context.c.text, context.c.brand, ...
//  Tema atual: PRETO + DOURADO.
//  Obs.: `purple` e `purpleSoft` mantêm o nome, mas agora são champanhe/bronze.
// =============================================================================
class HotelColors extends ThemeExtension<HotelColors> {
  const HotelColors({
    required this.dark,
    required this.hc,
    required this.page,
    required this.frame,
    required this.bg,
    required this.surface,
    required this.border,
    required this.borderSoft,
    required this.text,
    required this.text2,
    required this.text3,
    required this.brand,
    required this.brandDark,
    required this.brandSoft,
    required this.onBrand,
    required this.purple,
    required this.purpleSoft,
    required this.green,
    required this.greenSoft,
    required this.red,
    required this.redSoft,
  });

  final bool dark, hc;
  final Color page, frame, bg, surface, border, borderSoft;
  final Color text, text2, text3;
  final Color brand, brandDark, brandSoft, onBrand;
  final Color purple, purpleSoft, green, greenSoft, red, redSoft;

  double get bw => hc ? 2 : 1;
  Color get track => text3.withValues(alpha: 0.25);

  List<BoxShadow> get shadow => hc
      ? const []
      : [
          BoxShadow(
            color: dark ? Colors.black.withValues(alpha: 0.45) : const Color(0xFF1A1408).withValues(alpha: 0.08),
            blurRadius: dark ? 20 : 16,
            offset: const Offset(0, 6),
          ),
        ];

    // ---- CLARO: marfim com latão ----
  static const _claro = HotelColors(
    dark: false, hc: false,
    page: Color(0xFFE8E5DD), frame: Color(0xFF14181F),
    bg: Color(0xFFF6F4EF), surface: Color(0xFFFFFFFF),
    border: Color(0xFFE3DFD5), borderSoft: Color(0xFFEEEBE2),
    text: Color(0xFF14181F), text2: Color(0xFF4D5665), text3: Color(0xFF6D7686),
    brand: Color(0xFFB08D45), brandDark: Color(0xFF6E5420), brandSoft: Color(0xFFF3EBDA), onBrand: Color(0xFF14181F),
    purple: Color(0xFF3B5B8C), purpleSoft: Color(0xFFE6ECF6),
    green: Color(0xFF1F7A4F), greenSoft: Color(0xFFE0F2E9),
    red: Color(0xFFB4323E), redSoft: Color(0xFFF8E3E5),
  );

  // ---- ESCURO: grafite com latão (padrão) ----
  static const _escuro = HotelColors(
    dark: true, hc: false,
    page: Color(0xFF07090C), frame: Color(0xFF232A35),
    bg: Color(0xFF0E1116), surface: Color(0xFF151A22),
    border: Color(0xFF252C38), borderSoft: Color(0xFF1C222C),
    text: Color(0xFFEDEAE3), text2: Color(0xFFA9B0BC), text3: Color(0xFF7C8594),
    brand: Color(0xFFC6A664), brandDark: Color(0xFFDCC48E), brandSoft: Color(0xFF1B2130), onBrand: Color(0xFF0E1116),
    purple: Color(0xFF8FA8D0), purpleSoft: Color(0xFF172033),
    green: Color(0xFF3DBE8B), greenSoft: Color(0xFF11281F),
    red: Color(0xFFE5606E), redSoft: Color(0xFF2C171B),
  );

  // ---- CLARO + ALTO CONTRASTE ----
  static const _claroHc = HotelColors(
    dark: false, hc: true,
    page: Color(0xFFE7E1D3), frame: Color(0xFF1A1408),
    bg: Color(0xFFFFFFFF), surface: Color(0xFFFFFFFF),
    border: Color(0xFF1A1408), borderSoft: Color(0xFF1A1408),
    text: Color(0xFF000000), text2: Color(0xFF2A2210), text3: Color(0xFF4A3E20),
    brand: Color(0xFF7A5A00), brandDark: Color(0xFF5C4300), brandSoft: Color(0xFFF7ECCB), onBrand: Color(0xFFFFFFFF),
    purple: Color(0xFF7A3E00), purpleSoft: Color(0xFFF6E7D4),
    green: Color(0xFF0B6B2E), greenSoft: Color(0xFFDCF5E5),
    red: Color(0xFFA30000), redSoft: Color(0xFFFDE4E4),
  );

  // ---- ESCURO + ALTO CONTRASTE ----
  static const _escuroHc = HotelColors(
    dark: true, hc: true,
    page: Color(0xFF000000), frame: Color(0xFFFFFFFF),
    bg: Color(0xFF000000), surface: Color(0xFF000000),
    border: Color(0xFFFFFFFF), borderSoft: Color(0xFFE6E0D0),
    text: Color(0xFFFFFFFF), text2: Color(0xFFF5F0E3), text3: Color(0xFFD8D0BC),
    brand: Color(0xFFF2C94C), brandDark: Color(0xFFFFE08A), brandSoft: Color(0xFF2A2110), onBrand: Color(0xFF000000),
    purple: Color(0xFFF2E3B0), purpleSoft: Color(0xFF2A2418),
    green: Color(0xFF7CF5A6), greenSoft: Color(0xFF12301F),
    red: Color(0xFFFF9A9A), redSoft: Color(0xFF3A1818),
  );

  static HotelColors pick(bool escuro, bool altoContraste) =>
      escuro ? (altoContraste ? _escuroHc : _escuro) : (altoContraste ? _claroHc : _claro);

  @override
  ThemeExtension<HotelColors> copyWith() => this;

  @override
  ThemeExtension<HotelColors> lerp(ThemeExtension<HotelColors>? other, double t) =>
      other is HotelColors ? (t < 0.5 ? this : other) : this;
}

extension HotelContext on BuildContext {
  HotelColors get c => Theme.of(this).extension<HotelColors>()!;
}

// =============================================================================
//  HELPERS
// =============================================================================
String moeda(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String dataBr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

double lerValor(String t, [double padrao = 0.0]) {
  var s = t.replaceAll('R\$', '').trim();
  if (s.contains(',')) s = s.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(s) ?? padrao;
}

/// Escolhe branco ou escuro para o texto sobre [fundo], garantindo leitura.
Color textoSobre(Color fundo) =>
    fundo.computeLuminance() > 0.35 ? const Color(0xFF14110A) : Colors.white;

// =============================================================================
//  APP
// =============================================================================
class HotelProApp extends StatefulWidget {
  const HotelProApp({super.key});

  @override
  State<HotelProApp> createState() => _HotelProAppState();
}

class _HotelProAppState extends State<HotelProApp> with WidgetsBindingObserver {
  // Se já existe sessão salva no aparelho, o app abre direto, sem pedir login.
  bool _estaLogado = Supabase.instance.client.auth.currentSession != null;
  late final StreamSubscription<AuthState> _authSub;
  bool _modoEscuro = true;
  bool _altoContraste = false;
  double _escalaFonte = 1.0;
  bool _manualTema = false;
  bool _manualContraste = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() => _estaLogado = data.session != null);
    });
    _lerSistema();
  }

  @override
  void dispose() {
    _authSub.cancel();
    WidgetsBinding.instance.removeObserver(this);
    globalGerenciador.pararDeEscutar();
    super.dispose();
  }

  void _lerSistema() {
    final d = WidgetsBinding.instance.platformDispatcher;
    if (kSeguirTemaDoSistema && !_manualTema) {
      _modoEscuro = d.platformBrightness == Brightness.dark;
    }
    if (!_manualContraste) {
      _altoContraste = d.accessibilityFeatures.highContrast;
    }
  }

  @override
  void didChangePlatformBrightness() => setState(_lerSistema);

  @override
  void didChangeAccessibilityFeatures() => setState(_lerSistema);

  @override
  Widget build(BuildContext context) {
    final c = HotelColors.pick(_modoEscuro, _altoContraste);

    return MaterialApp(
      title: 'HOTEL PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: _modoEscuro ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: c.bg,
        cardColor: c.surface,
        dividerColor: c.borderSoft,
        colorScheme: ColorScheme(
          brightness: _modoEscuro ? Brightness.dark : Brightness.light,
          primary: c.brand,
          onPrimary: c.onBrand,
          secondary: c.brandDark,
          onSecondary: c.onBrand,
          error: c.red,
          onError: Colors.white,
          surface: c.surface,
          onSurface: c.text,
          surfaceTint: Colors.transparent,
        ),
        extensions: [c],
        fontFamily: 'sans-serif', dialogTheme: DialogThemeData(backgroundColor: c.surface),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_escalaFonte)),
          child: child!,
        );
      },
      home: MobileFrameWrapper(
        child: _estaLogado
            ? MainScreenHolder(
                onLogout: () => Supabase.instance.client.auth.signOut(),
                modoEscuro: _modoEscuro,
                altoContraste: _altoContraste,
                escalaFonte: _escalaFonte,
                onToggleDarkMode: (v) => setState(() {
                  _manualTema = true;
                  _modoEscuro = v;
                }),
                onToggleContraste: (v) => setState(() {
                  _manualContraste = true;
                  _altoContraste = v;
                }),
                onChangeFontScale: (v) => setState(() => _escalaFonte = v),
              )
            : LoginScreen(onLoginSucesso: () => setState(() => _estaLogado = true)),
      ),
    );
  }
}

/// Moldura de celular (só aparece em telas largas, tipo desktop/web).
/// Em um celular de verdade o app ocupa a tela inteira.
class MobileFrameWrapper extends StatelessWidget {
  final Widget child;
  const MobileFrameWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final size = MediaQuery.of(context).size;
    if (size.width < 520) return child;

    return Scaffold(
      backgroundColor: c.page,
      body: Center(
        child: Container(
          width: 412,
          height: math.min(870, size.height - 32),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: c.frame, width: 10),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 15))],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(30), child: child),
        ),
      ),
    );
  }
}

// =============================================================================
//  COMPONENTES REUTILIZÁVEIS
// =============================================================================
class BotaoAnimado extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const BotaoAnimado({super.key, required this.child, required this.onTap});

  @override
  State<BotaoAnimado> createState() => _BotaoAnimadoState();
}

class _BotaoAnimadoState extends State<BotaoAnimado> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Card padrão: fundo, borda e sombra seguem o tema.
class HCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  const HCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.border, width: c.bw),
        boxShadow: c.shadow,
      ),
      child: child,
    );
  }
}

/// Ícone em emoji (os mesmos das telas de design). Para glifos de texto
/// (como "$", "+" ou "✓") a cor [cor] é aplicada; emojis mantêm as próprias cores.
class Emo extends StatelessWidget {
  final String glifo;
  final double tamanho;
  final Color? cor;
  final String? rotulo;
  const Emo(this.glifo, {super.key, this.tamanho = 20, this.cor, this.rotulo});

  @override
  Widget build(BuildContext context) {
    final t = Text(
      glifo,
      style: TextStyle(
        fontSize: tamanho,
        height: 1.1,
        color: cor,
        fontWeight: FontWeight.w800,
        fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji', 'Segoe UI Emoji'],
      ),
    );
    return rotulo == null
        ? ExcludeSemantics(child: t)
        : Semantics(label: rotulo, excludeSemantics: true, child: t);
  }
}

class IconChip extends StatelessWidget {
  final String glifo;
  final Color bg;
  final Color? cor;
  final double tamanho;
  const IconChip({super.key, required this.glifo, required this.bg, this.cor, this.tamanho = 20});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: c.hc ? Border.all(color: c.border, width: 1) : null,
      ),
      child: Emo(glifo, tamanho: tamanho, cor: cor),
    );
  }
}

class BotaoSolido extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final String? glifo;
  const BotaoSolido({super.key, required this.label, required this.onTap, required this.color, this.glifo});

  @override
  Widget build(BuildContext context) {
    final fg = textoSobre(color);
    return BotaoAnimado(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (glifo != null) ...[Emo(glifo!, tamanho: 15, cor: fg), const SizedBox(width: 6)],
            Text(label, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class BotaoIcone extends StatelessWidget {
  final String glifo;
  final String rotulo;
  final Color bg;
  final VoidCallback onTap;
  const BotaoIcone({super.key, required this.glifo, required this.rotulo, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BotaoAnimado(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Emo(glifo, tamanho: 18, rotulo: rotulo),
      ),
    );
  }
}

class FiltroChips extends StatelessWidget {
  final List<String> opcoes;
  final int selecionado;
  final ValueChanged<int> onChanged;
  const FiltroChips({super.key, required this.opcoes, required this.selecionado, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(opcoes.length, (i) {
        final ativo = i == selecionado;
        return BotaoAnimado(
          onTap: () => onChanged(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: ativo ? c.brand : c.surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: ativo ? c.brand : c.border, width: c.bw),
            ),
            child: Text(opcoes[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ativo ? c.onBrand : c.text2)),
          ),
        );
      }),
    );
  }
}

class Selo extends StatelessWidget {
  final String texto;
  final Color cor;
  final Color fundo;
  const Selo({super.key, required this.texto, required this.cor, required this.fundo});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: cor.withValues(alpha: c.hc ? 1 : 0.45), width: c.bw),
      ),
      child: Text(texto, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

Widget estadoVazio(BuildContext context, String glifo, String titulo, String dica) {
  final c = context.c;
  return LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconChip(glifo: glifo, bg: c.brandSoft, tamanho: 26),
                const SizedBox(height: 14),
                Text(titulo, textAlign: TextAlign.center, style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(dica, textAlign: TextAlign.center, style: TextStyle(color: c.text2, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}


// ----- Avisos (snackbar) e erros dentro do diálogo -----
void aviso(BuildContext context, String msg, {bool erro = false}) {
  final c = context.c;
  final fundo = erro ? c.red : c.text;
  final frente = erro ? textoSobre(c.red) : c.bg;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: frente, fontWeight: FontWeight.w700)),
      backgroundColor: fundo,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 2),
    ));
}

Widget erroNoDialogo(BuildContext context, ValueNotifier<String?> erro) {
  final c = context.c;
  return ValueListenableBuilder<String?>(
    valueListenable: erro,
    builder: (_, msg, _) => msg == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const Emo('⚠️', tamanho: 14),
                const SizedBox(width: 6),
                Expanded(child: Text(msg, style: TextStyle(color: c.red, fontSize: 13, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
  );
}

// ----- Diálogos e campos de texto no estilo do tema -----
Future<void> mostrarDialogo(
  BuildContext context, {
  required String titulo,
  required Widget conteudo,
  required List<Widget> acoes,
}) {
  return showDialog(
    context: context,
    builder: (ctx) {
      final c = ctx.c;
      return AlertDialog(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: c.border, width: c.bw),
        ),
        title: Text(titulo, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(child: conteudo),
        actions: acoes,
      );
    },
  );
}

Widget botaoCancelar(BuildContext context, [BuildContext? ctxDialogo]) {
  return TextButton(
    onPressed: () => Navigator.pop(ctxDialogo ?? context),
    style: TextButton.styleFrom(foregroundColor: context.c.text2),
    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
  );
}

InputDecoration deco(BuildContext context, String label) {
  final c = context.c;
  OutlineInputBorder borda(Color cor, double w) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cor, width: w));
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: c.text2, fontSize: 14),
    floatingLabelStyle: TextStyle(color: c.brandDark, fontWeight: FontWeight.w700),
    filled: true,
    fillColor: c.bg,
    border: borda(c.border, c.bw),
    enabledBorder: borda(c.border, c.bw),
    focusedBorder: borda(c.brand, 2),
  );
}

Widget campo(
  BuildContext context,
  TextEditingController ctrl,
  String label, {
  TextInputType? tipo,
  List<TextInputFormatter>? formatadores,
}) {
  return TextField(
    controller: ctrl,
    keyboardType: tipo,
    inputFormatters: formatadores,
    cursorColor: context.c.brand,
    style: TextStyle(color: context.c.text),
    decoration: deco(context, label),
  );
}

// =============================================================================
//  FORMATADORES
// =============================================================================
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 11) text = text.substring(0, 11);
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) formatted += '.';
      if (i == 9) formatted += '-';
      formatted += text[i];
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 11) text = text.substring(0, 11);
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 0) formatted += '(';
      if (i == 2) formatted += ') ';
      if (i == 7) formatted += '-';
      formatted += text[i];
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

final GerenciadorQuartos globalGerenciador = GerenciadorQuartos();

// =============================================================================
//  CHECK-IN / CHECK-OUT: DESLIZAR PARA CONFIRMAR + ANIMAÇÃO DE SUCESSO
// =============================================================================
const kAmarelo = Color(0xFFF59E0B);

enum TipoAcao { checkin, checkout }

/// Botão "deslize para confirmar". [onConfirm] devolve true se deu certo
/// (o botão fica confirmado) ou false se algo faltou (o botão volta ao início).
/// Com leitor de tela ativo vira um botão comum de toque.
class SlideToConfirm extends StatefulWidget {
  final String texto;
  final String glifo;
  final Color cor;
  final double largura;
  final bool Function() onConfirm;
  const SlideToConfirm({
    super.key,
    required this.texto,
    required this.glifo,
    required this.cor,
    required this.onConfirm,
    this.largura = 260,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> with SingleTickerProviderStateMixin {
  static const double _alturaTrilho = 60;
  static const double _polegar = 52;
  double _x = 0;
  double _de = 0;
  bool _feito = false;

  late final AnimationController _volta = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))
    ..addListener(() => setState(() => _x = _de * (1 - Curves.easeOut.transform(_volta.value))));

  double get _max => widget.largura - _polegar - 8;

  @override
  void dispose() {
    _volta.dispose();
    super.dispose();
  }

  void _voltar() {
    _de = _x;
    _volta.forward(from: 0);
  }

  void _confirmar() {
    if (_feito) return;
    HapticFeedback.heavyImpact();
    final ok = widget.onConfirm();
    if (ok) {
      setState(() {
        _x = _max;
        _feito = true;
      });
    } else {
      _voltar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = textoSobre(widget.cor);

    if (MediaQuery.of(context).accessibleNavigation) {
      return SizedBox(
        width: widget.largura,
        child: BotaoAnimado(
          onTap: _confirmar,
          child: Container(
            height: _alturaTrilho,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: widget.cor, borderRadius: BorderRadius.circular(99)),
            child: Text(widget.texto.replaceFirst('Deslize para', 'Toque para'), style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
          ),
        ),
      );
    }

    final progresso = _max > 0 ? (_x / _max).clamp(0.0, 1.0) : 0.0;

    return Semantics(
      button: true,
      label: widget.texto,
      onTap: _confirmar,
      child: SizedBox(
        width: widget.largura,
        height: _alturaTrilho,
        child: Container(
          decoration: BoxDecoration(
            color: widget.cor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: widget.cor, width: c.bw),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _x + _polegar + 4,
                child: Container(decoration: BoxDecoration(color: widget.cor.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(99))),
              ),
              Center(
                child: Opacity(
                  opacity: 1 - progresso,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text(widget.texto, style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              Positioned(
                left: 4 + _x,
                top: 3,
                child: GestureDetector(
                  onHorizontalDragUpdate: _feito ? null : (d) => setState(() => _x = (_x + d.delta.dx).clamp(0.0, _max)),
                  onHorizontalDragEnd: _feito
                      ? null
                      : (_) {
                          if (_x >= _max * 0.88) {
                            _confirmar();
                          } else {
                            _voltar();
                          }
                        },
                  child: Container(
                    width: _polegar,
                    height: _polegar,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.cor,
                      shape: BoxShape.circle,
                      boxShadow: c.hc ? const [] : [BoxShadow(color: widget.cor.withValues(alpha: 0.45), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Transform.rotate(
                      angle: progresso * 0.6,
                      child: Emo(_feito ? '✓' : widget.glifo, tamanho: 22, cor: fg),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double anel;
  final double check;
  final Color cor;
  final double largura;
  _CheckPainter(this.anel, this.check, this.cor, this.largura);

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    canvas.drawCircle(centro, r, Paint()..color = cor.withValues(alpha: 0.12 * anel));
    canvas.drawCircle(centro, r, Paint()
      ..color = cor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = largura);
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: r),
      -math.pi / 2,
      2 * math.pi * anel,
      false,
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = largura
        ..strokeCap = StrokeCap.round,
    );
    if (check > 0) {
      final p = Path()
        ..moveTo(size.width * 0.30, size.height * 0.52)
        ..lineTo(size.width * 0.45, size.height * 0.67)
        ..lineTo(size.width * 0.72, size.height * 0.36);
      final m = p.computeMetrics().first;
      canvas.drawPath(
        m.extractPath(0, m.length * check),
        Paint()
          ..color = cor
          ..style = PaintingStyle.stroke
          ..strokeWidth = largura + 1
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckPainter o) => o.anel != anel || o.check != check || o.cor != cor;
}

class _Particula {
  final String glifo;
  final double angulo;
  final double vel;
  final double tam;
  final double giro;
  _Particula(this.glifo, this.angulo, this.vel, this.tam, this.giro);
}

/// Animação de tela cheia: chave girando + anel + check desenhado + confete (check-in),
/// ou mala saindo rolando + check + tchau (check-out). Toque para fechar.
Future<void> mostrarAnimacaoAcao(
  BuildContext context, {
  required TipoAcao tipo,
  required String titulo,
  required String subtitulo,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, _, _) => _AnimacaoAcao(tipo: tipo, titulo: titulo, subtitulo: subtitulo),
    transitionBuilder: (ctx, a, _, child) => FadeTransition(opacity: a, child: child),
  );
}

class _AnimacaoAcao extends StatefulWidget {
  final TipoAcao tipo;
  final String titulo;
  final String subtitulo;
  const _AnimacaoAcao({required this.tipo, required this.titulo, required this.subtitulo});

  @override
  State<_AnimacaoAcao> createState() => _AnimacaoAcaoState();
}

class _AnimacaoAcaoState extends State<_AnimacaoAcao> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final List<_Particula> _parts;
  bool _haptico = false;

  bool get _checkin => widget.tipo == TipoAcao.checkin;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    final glifos = _checkin ? ['🎉', '✨', '⭐', '🎊', '🔑', '🌟'] : ['👋', '✨', '🧳', '💫'];
    final qtd = _checkin ? 22 : 10;
    _parts = List.generate(qtd, (i) {
      return _Particula(
        glifos[i % glifos.length],
        -math.pi * (0.04 + 0.92 * rnd.nextDouble()),
        90 + 130 * rnd.nextDouble(),
        16 + 12 * rnd.nextDouble(),
        (rnd.nextDouble() - 0.5) * 2,
      );
    });
    HapticFeedback.lightImpact();
    _ctrl.addListener(() {
      if (!_haptico && _ctrl.value > 0.5) {
        _haptico = true;
        HapticFeedback.mediumImpact();
      }
    });
    _ctrl.forward().whenComplete(() async {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final cor = _checkin ? c.green : kAmarelo;
    final reduz = MediaQuery.of(context).disableAnimations;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = _ctrl.value;
              double faixa(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

              final entrada = Curves.elasticOut.transform(faixa(0, 0.3));
              final anel = Curves.easeInOut.transform(faixa(0.15, 0.55));
              final check = Curves.easeOut.transform(faixa(0.5, 0.72));
              final texto = Curves.easeOutCubic.transform(faixa(0.55, 0.82));
              final sumir = 1 - faixa(0.45, 0.6);

              double dx;
              double giro;
              if (_checkin) {
                final k = Curves.easeOutBack.transform(faixa(0, 0.3));
                dx = -90 * (1 - k);
                giro = -0.9 * (1 - k) + faixa(0.3, 0.5) * math.pi / 2;
              } else {
                dx = 100 * Curves.easeIn.transform(faixa(0.15, 0.55));
                giro = 0.25 * math.sin(faixa(0, 0.5) * math.pi * 6);
              }

              final explosao = Curves.easeOut.transform(faixa(0.5, 1.0));
              final opacidadeParticulas = 1 - faixa(0.78, 1.0);

              return SizedBox(
                width: 320,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Opacity(
                      opacity: faixa(0, 0.15),
                      child: Transform.scale(
                        scale: 0.5 + 0.5 * entrada,
                        child: Container(
                          width: 300,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: cor, width: c.bw),
                            boxShadow: c.hc ? const [] : [BoxShadow(color: cor.withValues(alpha: 0.35), blurRadius: 40, spreadRadius: 2)],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(size: const Size(110, 110), painter: _CheckPainter(anel, check, cor, 6)),
                                    Transform.translate(
                                      offset: Offset(dx, 0),
                                      child: Transform.rotate(
                                        angle: giro,
                                        child: Opacity(opacity: sumir.clamp(0.0, 1.0), child: Emo(_checkin ? '🔑' : '🧳', tamanho: 46)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Opacity(
                                opacity: texto,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - texto) * 14),
                                  child: Semantics(
                                    liveRegion: true,
                                    label: '${widget.titulo}. ${widget.subtitulo}',
                                    child: ExcludeSemantics(
                                      child: Column(
                                        children: [
                                          Text(widget.titulo, textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.text)),
                                          const SizedBox(height: 4),
                                          Text(widget.subtitulo, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.text2)),
                                          const SizedBox(height: 10),
                                          Text('Toque para fechar', style: TextStyle(fontSize: 12, color: c.text3)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!reduz && t > 0.5)
                      ..._parts.map((p) {
                        final off = Offset(
                          math.cos(p.angulo) * p.vel * explosao,
                          -45 + math.sin(p.angulo) * p.vel * explosao + 190 * explosao * explosao,
                        );
                        return Transform.translate(
                          offset: off,
                          child: Opacity(
                            opacity: opacidadeParticulas.clamp(0.0, 1.0),
                            child: Transform.rotate(angle: p.giro * explosao * 6, child: Emo(p.glifo, tamanho: p.tam)),
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  IA FINANCEIRA: contrato + contexto + assistente (tela de conversa)
// =============================================================================

/// >>> É AQUI que você pluga a sua IA. <<<
/// Implemente [perguntar] chamando o SEU servidor (que fala com a IA).
/// Nunca coloque chave de API dentro do app: qualquer pessoa consegue extrair.
abstract class FinanceiroIA {
  Future<String> perguntar(String pergunta, Map<String, dynamic> contexto);
    void novaConversa() {}
}

Map<String, dynamic> contextoFinanceiroParaIA() {
  final g = globalGerenciador;
  final quartos = g.listaQuartos;
  final ocupados = quartos.where((q) => q.status == 'Ocupado').length;

  // O CPF do hóspede atual vem do cadastro (CRM), ligado pelo nome.
  String cpfDe(String nome) {
    for (final cli in g.historicoClientes) {
      if (cli.nome.toString().trim().toLowerCase() == nome.trim().toLowerCase()) {
        return cli.cpf.toString();
      }
    }
    return '';
  }

  final detalhes = quartos.map((q) {
    final ocupado = q.status == 'Ocupado';
    final nome = '${q.hospedePrincipal}'.trim();
    return <String, dynamic>{
      'numero': q.id,
      'tipo': q.tipo,
      'diaria': q.valorDiaria,
      'status': q.status,
      if (ocupado) ...{
        'hospede': nome,
        'cpf': cpfDe(nome),
        'telefone': '${q.telefone}',
        'placa': '${q.placaVeiculo}',
      },
    };
  }).toList();

  final diariasEmCurso = quartos
      .where((q) => q.status == 'Ocupado')
      .fold<double>(0, (a, q) => a + (q.valorDiaria as num).toDouble());

  final movs = g.historicoCaixa.toList()..sort((a, b) => b.data.compareTo(a.data));

  return <String, dynamic>{
    'moeda': 'BRL',
    'hoje': DateTime.now().toIso8601String(),
    'pousada': globalNomePousada.value,
    'mes_atual': <String, dynamic>{
      'entradas': g.getTotalEntradasMesAtual(),
      'saidas': g.getTotalSaidasMesAtual(),
      'lucro_liquido': g.getLucroLiquidoMesAtual(),
    },
    'quartos': <String, dynamic>{'total': quartos.length, 'ocupados': ocupados, 'livres': quartos.length - ocupados},
    'detalhes_dos_quartos': detalhes,
    'soma_das_diarias_dos_quartos_ocupados': diariasEmCurso,
    'observacao_hospedes': 'hospedes_cadastrados lista todos que já fizeram check-in alguma vez. Se o nome está nessa lista, o hóspede já se hospedou antes.',
    'hospedes_cadastrados': g.historicoClientes
        .take(500)
        .map((cli) => <String, dynamic>{'nome': cli.nome, 'cpf': cli.cpf, 'telefone': cli.telefone})
        .toList(),
    'movimentacoes': movs
        .take(300)
        .map((t) => <String, dynamic>{
              'tipo': t.tipo,
              'descricao': t.descricao,
              'data': t.data.toIso8601String(),
              'valor': t.valor,
            })
        .toList(),
  };
}

/// Versão de demonstração (responde com regras simples, sem internet).
/// Troque pela sua: `globalFinanceiroIA = MinhaIA();`
class IaLocalDemo extends FinanceiroIA {
  @override
  Future<String> perguntar(String pergunta, Map<String, dynamic> contexto) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final p = pergunta.toLowerCase();
    final mes = contexto['mes_atual'] as Map<String, dynamic>;
    final entradas = (mes['entradas'] as num).toDouble();
    final saidas = (mes['saidas'] as num).toDouble();
    final lucro = (mes['lucro_liquido'] as num).toDouble();
    final quartos = contexto['quartos'] as Map<String, dynamic>;
    final movs = (contexto['movimentacoes'] as List).cast<Map<String, dynamic>>();

    if (p.contains('gast') || p.contains('despes') || p.contains('maior')) {
      final gastos = movs.where((m) => m['tipo'] != 'Entrada').toList()
        ..sort((a, b) => (b['valor'] as num).compareTo(a['valor'] as num));
      if (gastos.isEmpty) return 'Você ainda não registrou nenhum gasto neste mês.';
      final top = gastos.take(3).map((m) => '• ${m['descricao']}: ${moeda((m['valor'] as num).toDouble())}').join('\n');
      return 'Seus maiores gastos:\n$top\n\nTotal de gastos no mês: ${moeda(saidas)}.';
    }
    if (p.contains('lucro') || p.contains('caixa') || p.contains('saldo')) {
      return lucro < 0
          ? 'O caixa está negativo em ${moeda(lucro.abs())}. As entradas (${moeda(entradas)}) ainda não cobrem os gastos (${moeda(saidas)}).'
          : 'O lucro líquido do mês está em ${moeda(lucro)}. Entradas: ${moeda(entradas)} | Gastos: ${moeda(saidas)}.';
    }
    if (p.contains('ocupa') || p.contains('quarto')) {
      return 'Hoje são ${quartos['ocupados']} quartos ocupados e ${quartos['livres']} livres, de ${quartos['total']} no total.';
    }
    if (p.contains('resumo') || p.contains('mês') || p.contains('mes')) {
      return 'Resumo do mês:\n• Entradas: ${moeda(entradas)}\n• Gastos: ${moeda(saidas)}\n• Lucro líquido: ${moeda(lucro)}\n• Quartos ocupados: ${quartos['ocupados']}/${quartos['total']}';
    }
    return 'Ainda estou em modo demonstração. Pergunte por "resumo do mês", "maiores gastos", "lucro" ou "ocupação". Quando a sua IA estiver conectada, eu respondo qualquer coisa sobre o financeiro.';
  }
}

FinanceiroIA globalFinanceiroIA = IaSupabase();

void abrirAssistenteFinanceiro(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 412),
    builder: (_) => const AssistenteIASheet(),
  );
}

class _Msg {
  final bool minha;
  final String texto;
  _Msg(this.minha, this.texto);
}

class AssistenteFinanceiroSheet extends StatefulWidget {
  const AssistenteFinanceiroSheet({super.key});

  @override
  State<AssistenteFinanceiroSheet> createState() => _AssistenteFinanceiroSheetState();
}

class _AssistenteFinanceiroSheetState extends State<AssistenteFinanceiroSheet> {
  final _msgs = <_Msg>[
    _Msg(false, 'Olá! Eu cuido do financeiro do hotel. Posso resumir o caixa, apontar os maiores gastos e acompanhar a ocupação. O que você quer saber?'),
  ];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _pensando = false;

  static const _sugestoes = ['Resumo do mês', 'Maiores gastos', 'Como está o caixa?', 'Ocupação'];


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
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
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

  Widget _balao(BuildContext context, _Msg m) {
    final c = context.c;
    return Align(
      alignment: m.minha ? Alignment.centerRight : Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: child)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: m.minha ? c.brand : c.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(m.minha ? 18 : 4),
              bottomRight: Radius.circular(m.minha ? 4 : 18),
            ),
            border: m.minha ? null : Border.all(color: c.border, width: c.bw),
          ),
          child: Text(m.texto, style: TextStyle(fontSize: 14, height: 1.35, color: m.minha ? c.onBrand : c.text)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final altura = MediaQuery.of(context).size.height * 0.86;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: altura,
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: c.border, width: c.bw),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 44, height: 5, decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(99))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Row(
                children: [
                  IconChip(glifo: '🤖', bg: c.purpleSoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assistente financeiro', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text)),
                        Text('Cuida do caixa para você', style: TextStyle(fontSize: 12, color: c.text2)),
                      ],
                    ),
                  ),
                  Selo(texto: globalFinanceiroIA is IaLocalDemo ? 'Demo' : 'IA', cor: c.purple, fundo: c.purpleSoft),
                ],
              ),
            ),
            Divider(height: 1, color: c.border),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  ..._msgs.map((m) => _balao(context, m)),
                  if (_pensando) const Align(alignment: Alignment.centerLeft, child: _Digitando()),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _sugestoes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => BotaoAnimado(
                  onTap: () => _enviar(_sugestoes[i]),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: c.purple, width: c.bw),
                    ),
                    child: Text(_sugestoes[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: _enviar,
                      textInputAction: TextInputAction.send,
                      cursorColor: c.brand,
                      style: TextStyle(color: c.text),
                      decoration: deco(context, 'Pergunte sobre o financeiro'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Semantics(
                    button: true,
                    label: 'Enviar pergunta',
                    child: BotaoAnimado(
                      onTap: () => _enviar(_ctrl.text),
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
                        child: Emo('↑', tamanho: 22, cor: c.onBrand),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Digitando extends StatefulWidget {
  const _Digitando();

  @override
  State<_Digitando> createState() => _DigitandoState();
}

class _DigitandoState extends State<_Digitando> with SingleTickerProviderStateMixin {
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
      label: 'Assistente digitando',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
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
                decoration: BoxDecoration(color: c.text3.withValues(alpha: 0.3 + 0.7 * v), shape: BoxShape.circle),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  TELA PRINCIPAL + MENU LATERAL + BARRA INFERIOR
// =============================================================================
class MainScreenHolder extends StatefulWidget {
  final VoidCallback onLogout;
  final bool modoEscuro;
  final bool altoContraste;
  final double escalaFonte;
  final ValueChanged<bool> onToggleDarkMode;
  final ValueChanged<bool> onToggleContraste;
  final ValueChanged<double> onChangeFontScale;

  const MainScreenHolder({
    super.key,
    required this.onLogout,
    required this.modoEscuro,
    required this.altoContraste,
    required this.escalaFonte,
    required this.onToggleDarkMode,
    required this.onToggleContraste,
    required this.onChangeFontScale,
  });

  @override
  State<MainScreenHolder> createState() => _MainScreenHolderState();
}

class _MainScreenHolderState extends State<MainScreenHolder> {
  int _indice = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _carregarDadosDaPousada();
  }

   Future<void> _carregarDadosDaPousada() async {
    final g = globalGerenciador;
    g.limpar();
    try {
      final client = Supabase.instance.client;
      final email = client.auth.currentUser?.email;
      if (email == null) return;

      // Mostra algo já, enquanto busca o nome verdadeiro
      globalNomePousada.value = nomeDoEmail(email);

      final emp = await client
          .from('empresas')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (emp == null) {
        debugPrint('Nenhuma pousada com o e-mail $email');
        if (mounted) {
          aviso(context, 'Esta conta não está vinculada a uma pousada. Nada será salvo. Fale com o administrador.', erro: true);
        }
        return;
      }

      globalNomePousada.value = nomeDaPousada(emp, email);
      globalEmpresaId = emp['id'].toString();
      await g.iniciar(emp['id'].toString());
      g.escutarMudancas(() => globalAtualizar.value++);
    } catch (e) {
      debugPrint('Erro ao carregar a pousada: $e');
    }
    if (mounted) setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    // As telas são criadas aqui (e não no initState) para sempre refletirem o tema atual.
    final telas = <Widget>[
    InicioHotelScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
      const QuartosScreenTab(),
      const HospedesScreenTab(),
      const FinanceiroScreenTab(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _menuLateral(context),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(_indice), child: telas[_indice]),
      ),
      bottomNavigationBar: _BarraInferior(
        selecionado: _indice,
        onSelecionar: (i) => setState(() => _indice = i),
      ),
    );
  }

  Widget _secao(BuildContext context, String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8, left: 4),
      child: Text(titulo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.c.text2)),
    );
  }

  Widget _menuLateral(BuildContext context) {
    final c = context.c;

    return Drawer(
      backgroundColor: c.bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.hotel_rounded, color: c.onBrand, size: 26),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HOTEL PRO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: c.brandDark)),
                    Text('Painel do gestor', style: TextStyle(fontSize: 12, color: c.text2)),
                  ],
                ),
              ],
            ),
            _secao(context, 'Aparência'),
            HCard(
              padding: EdgeInsets.zero,
              radius: 16,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text('Modo escuro', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                    secondary: const Emo('🌙', tamanho: 22),
                    value: widget.modoEscuro,
                    onChanged: widget.onToggleDarkMode,
                  ),
                  Divider(height: 1, color: c.borderSoft),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text('Alto contraste', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                    subtitle: Text('Acompanha o celular até você mudar aqui', style: TextStyle(fontSize: 12, color: c.text2)),
                    secondary: const Emo('🌓', tamanho: 22),
                    value: widget.altoContraste,
                    onChanged: widget.onToggleContraste,
                  ),
                ],
              ),
            ),
            _secao(context, 'Acessibilidade de texto'),
            HCard(
              radius: 16,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Emo('🔠', tamanho: 22),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Tamanho da fonte', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text))),
                      Text('${(widget.escalaFonte * 100).round()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.brandDark)),
                    ],
                  ),
                  Slider(
                    min: 0.85,
                    max: 1.3,
                    divisions: 3,
                    value: widget.escalaFonte,
                    activeColor: c.brand,
                    inactiveColor: c.track,
                    onChanged: widget.onChangeFontScale,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('A', style: TextStyle(fontSize: 12, color: c.text2, fontWeight: FontWeight.w700)),
                      Text('A', style: TextStyle(fontSize: 20, color: c.text2, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            BotaoAnimado(
              onTap: () {
                Navigator.pop(context);
                widget.onLogout();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.redSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.red, width: c.bw),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Emo('👋', tamanho: 18),
                    const SizedBox(width: 8),
                    Text('Sair do aplicativo', style: TextStyle(color: c.red, fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemNav {
  final String glifo;
  final String rotulo;
  const _ItemNav(this.glifo, this.rotulo);
}

class _BarraInferior extends StatelessWidget {
  final int selecionado;
  final ValueChanged<int> onSelecionar;
  const _BarraInferior({required this.selecionado, required this.onSelecionar});

  static const _itens = [
    _ItemNav('🏠', 'Início'),
    _ItemNav('🚪', 'Quartos'),
    _ItemNav('👥', 'Hóspedes'),
    _ItemNav('\$', 'Financeiro'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border, width: c.bw)),
        boxShadow: c.shadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_itens.length, (i) {
              final ativo = i == selecionado;
              final cor = ativo ? c.onBrand : c.text2;
              return Semantics(
                button: true,
                selected: ativo,
                label: _itens[i].rotulo,
                child: BotaoAnimado(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelecionar(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    constraints: const BoxConstraints(minWidth: 76),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: ativo ? c.brand : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Emo(_itens[i].glifo, tamanho: 22, cor: cor),
                        const SizedBox(height: 2),
                        ExcludeSemantics(
                          child: Text(_itens[i].rotulo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cor)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  INÍCIO (DASHBOARD)
// =============================================================================
const _diasSemanaLongo = ['segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado', 'domingo'];
const _meses = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];

class DashboardScreen extends StatelessWidget {
  final VoidCallback onOpenDrawer;
  const DashboardScreen({super.key, required this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hoje = DateTime.now();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cabecalho(context),
            const SizedBox(height: 16),
            _alertaCaixa(context),
            const SizedBox(height: 22),
            Text('Visão Geral do Dia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.text)),
            const SizedBox(height: 2),
            Text('${_diasSemanaLongo[hoje.weekday - 1]}, ${hoje.day} de ${_meses[hoje.month - 1]}', style: TextStyle(fontSize: 13, color: c.text2)),
            const SizedBox(height: 12),
            _metricas(context),
            const SizedBox(height: 12),
            _acessosRapidos(context),
            const SizedBox(height: 12),
            _calendario(context),
            const SizedBox(height: 12),
            _statusQuartos(context),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho(BuildContext context) {
    final c = context.c;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Abrir menu',
              child: BotaoAnimado(
                onTap: onOpenDrawer,
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: c.brand,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: c.hc ? const [] : [BoxShadow(color: c.brand.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Icon(Icons.menu_rounded, color: c.onBrand, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: 'HOTEL ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: c.brandDark)),
                  TextSpan(text: 'PRO', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: c.text2)),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: c.brandSoft,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: c.brand.withValues(alpha: c.hc ? 1 : 0.5), width: c.bw),
          ),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: c.brandDark, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Ativo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.brandDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _alertaCaixa(BuildContext context) {
    final c = context.c;
    final lucro = globalGerenciador.getLucroLiquidoMesAtual();
    final gastos = globalGerenciador.getTotalSaidasMesAtual();
    final negativo = lucro < 0;
    final destaque = negativo ? c.red : c.green;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border, width: c.bw),
        boxShadow: c.shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: destaque),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      IconChip(glifo: '🔔', bg: negativo ? c.redSoft : c.greenSoft),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alerta de Caixa em Tempo Real', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: c.text)),
                            const SizedBox(height: 3),
                            Text.rich(
                              TextSpan(
                                style: TextStyle(fontSize: 12, color: c.text2),
                                children: [
                                  const TextSpan(text: 'Lucro líquido: '),
                                  TextSpan(text: moeda(lucro), style: TextStyle(fontWeight: FontWeight.w800, color: destaque)),
                                  const TextSpan(text: '  |  Gastos: '),
                                  TextSpan(text: moeda(gastos), style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricas(BuildContext context) {
    final c = context.c;
    final total = globalGerenciador.listaQuartos.length;
    final ocupados = globalGerenciador.listaQuartos.where((q) => q.status == 'Ocupado').length;
    final livres = globalGerenciador.listaQuartos.where((q) => q.status == 'Disponível').length;
    final taxa = total > 0 ? ocupados / total : 0.0;

    Widget rotulo(String t, TextAlign a) =>
        Text(t, textAlign: a, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text3));
    TextStyle numero([Color? cor]) => TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: cor ?? c.text);
    Widget divisor() => Container(width: c.bw, height: 52, color: c.border);

    return HCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                rotulo('Livres', TextAlign.left),
                const SizedBox(height: 4),
                Row(children: [
                  Text('$livres', style: numero(c.green)),
                  const SizedBox(width: 4),
                  Emo('✓', tamanho: 20, cor: c.green),
                ]),
              ],
            ),
          ),
          divisor(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  rotulo('Ocupação', TextAlign.center),
                  const SizedBox(height: 4),
                  Text('${(taxa * 100).toStringAsFixed(0)}%', style: numero()),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: taxa, minHeight: 6, backgroundColor: c.track, color: c.brand),
                  ),
                ],
              ),
            ),
          ),
          divisor(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                rotulo('Total', TextAlign.right),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('$total', style: numero()),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _acessosRapidos(BuildContext context) {
    final c = context.c;

    Widget atalho(String glifo, Color fundo, String titulo, String sub, VoidCallback onTap) {
      return Expanded(
        child: Semantics(
          button: true,
          label: '$titulo. $sub',
          child: BotaoAnimado(
            onTap: onTap,
            child: SizedBox(
              height: 124,
              child: HCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconChip(glifo: glifo, bg: fundo),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.text)),
                        const SizedBox(height: 2),
                        Text(sub, style: TextStyle(fontSize: 12, color: c.text2)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        atalho('🪪', c.purpleSoft, 'Check-ins ativos', 'Ver hóspedes agora', () => _dialogoHospedesAtivos(context)),
        const SizedBox(width: 12),
        atalho('📊', c.brandSoft, 'Balanço rápido', 'Status financeiro', () => _dialogoBalanco(context)),
      ],
    );
  }

  Widget _calendario(BuildContext context) {
    final c = context.c;
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));
    const nomes = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return HCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Calendário Operacional ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
                      TextSpan(text: '(${dataBr(hoje)})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.text2)),
                    ],
                  ),
                ),
              ),
              const Emo('📅', tamanho: 20),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(7, (i) {
              final dia = inicioSemana.add(Duration(days: i));
              final ehHoje = dia.year == hoje.year && dia.month == hoje.month && dia.day == hoje.day;
              return Expanded(
                child: Column(
                  children: [
                    Text(nomes[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text3)),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ehHoje ? c.brand : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: ehHoje && !c.hc ? [BoxShadow(color: c.brand.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))] : const [],
                      ),
                      child: Text(
                        '${dia.day}',
                        style: TextStyle(fontSize: 14, fontWeight: ehHoje ? FontWeight.w800 : FontWeight.w600, color: ehHoje ? c.onBrand : c.text),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _statusQuartos(BuildContext context) {
    final c = context.c;
    final quartos = globalGerenciador.listaQuartos;

    Widget legenda(Color cor, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(t, style: TextStyle(fontSize: 12, color: c.text2, fontWeight: FontWeight.w600)),
          ],
        );

    return HCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status rápido dos quartos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
          const SizedBox(height: 12),
          if (quartos.isEmpty)
            Row(
              children: [
                const Emo('🚪', tamanho: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Nenhum quarto cadastrado. Adicione na aba Quartos.', style: TextStyle(fontSize: 13, color: c.text2))),
              ],
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quartos.map((q) {
                final ocupado = q.status == 'Ocupado';
                final cor = ocupado ? c.red : c.green;
                return Container(
                  width: 56,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ocupado ? c.redSoft : c.greenSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cor, width: c.bw),
                  ),
                  child: Text(q.id, style: TextStyle(color: cor, fontWeight: FontWeight.w800, fontSize: 13)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(children: [legenda(c.green, 'Livre'), const SizedBox(width: 16), legenda(c.red, 'Ocupado')]),
          ],
        ],
      ),
    );
  }

  void _dialogoHospedesAtivos(BuildContext context) {
    final c = context.c;
    final ativos = globalGerenciador.listaQuartos.where((q) => q.status == 'Ocupado').toList();
    mostrarDialogo(
      context,
      titulo: 'Hóspedes hospedados agora',
      conteudo: SizedBox(
        width: double.maxFinite,
        child: ativos.isEmpty
            ? Text('Nenhum hóspede no momento.', style: TextStyle(color: c.text2))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: ativos.map((q) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        IconChip(glifo: '👤', bg: c.brandSoft, tamanho: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quarto ${q.id}: ${q.hospedePrincipal}', style: TextStyle(fontWeight: FontWeight.w800, color: c.text)),
                              Text('Tel: ${q.telefone}  |  Placa: ${q.placaVeiculo}', style: TextStyle(fontSize: 12, color: c.text2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
      acoes: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: c.brandDark),
          child: const Text('Fechar', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  void _dialogoBalanco(BuildContext context) {
    final c = context.c;
    final entradas = globalGerenciador.getTotalEntradasMesAtual();
    final saidas = globalGerenciador.getTotalSaidasMesAtual();
    final lucro = entradas - saidas;

    Widget linha(String t, String v, Color cor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t, style: TextStyle(color: c.text2, fontSize: 14)),
              Text(v, style: TextStyle(color: cor, fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
        );

    mostrarDialogo(
      context,
      titulo: 'Balanço rápido do mês',
      conteudo: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          linha('Entradas totais', moeda(entradas), c.green),
          linha('Gastos totais', moeda(saidas), c.red),
          Divider(color: c.border, height: 20),
          linha('Lucro líquido', moeda(lucro), lucro < 0 ? c.red : c.brandDark),
        ],
      ),
      acoes: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: c.brandDark),
          child: const Text('Fechar', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

// =============================================================================
//  QUARTOS
// =============================================================================
class QuartosScreenTab extends StatefulWidget {
  const QuartosScreenTab({super.key});

  @override
  State<QuartosScreenTab> createState() => _QuartosScreenTabState();
}

class _QuartosScreenTabState extends State<QuartosScreenTab> {
  static const _amarelo = Color(0xFFF59E0B);
  int _filtro = 0; // 0 = todos, 1 = livres, 2 = ocupados
  int? _destaque;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final todos = globalGerenciador.listaQuartos;
    final ocupados = todos.where((q) => q.status == 'Ocupado').length;
    final livres = todos.length - ocupados;

    // guarda o índice real de cada quarto, assim editar/remover funciona mesmo filtrado
    final visiveis = <int>[
      for (int i = 0; i < todos.length; i++)
        if (_filtro == 0 || (_filtro == 1 && todos[i].status != 'Ocupado') || (_filtro == 2 && todos[i].status == 'Ocupado')) i,
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quartos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.text)),
                      Text('${todos.length} cadastrado(s)', style: TextStyle(fontSize: 13, color: c.text2)),
                    ],
                  ),
                ),
                BotaoSolido(label: 'Novo quarto', glifo: '+', color: c.brand, onTap: () => _modalNovoQuarto(context)),
              ],
            ),
            if (todos.isNotEmpty) ...[
              const SizedBox(height: 14),
              FiltroChips(
                opcoes: ['Todos (${todos.length})', 'Livres ($livres)', 'Ocupados ($ocupados)'],
                selecionado: _filtro,
                onChanged: (i) => setState(() => _filtro = i),
              ),
            ],
            const SizedBox(height: 14),
            Expanded(
              child: todos.isEmpty
                  ? estadoVazio(context, '🚪', 'Nenhum quarto cadastrado ainda', 'Toque em "Novo quarto" para começar.')
                  : visiveis.isEmpty
                      ? estadoVazio(context, '🔍', 'Nenhum quarto nesse filtro', 'Escolha outro filtro acima.')
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: visiveis.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, pos) => _cartaoQuarto(context, visiveis[pos]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartaoQuarto(BuildContext context, int index) {
    final c = context.c;
    final q = globalGerenciador.listaQuartos[index];
    final ocupado = q.status == 'Ocupado';
    final destaque = _destaque == index;

    return AnimatedScale(
      scale: destaque ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: destaque && !c.hc ? [BoxShadow(color: c.brand.withValues(alpha: 0.45), blurRadius: 24, spreadRadius: 1)] : const [],
        ),
        child: HCard(
          padding: const EdgeInsets.all(14),
          borderColor: destaque ? c.brand : null,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconChip(glifo: '🚪', bg: ocupado ? c.redSoft : c.greenSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quarto ${q.id} - ${q.tipo}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
                          const SizedBox(height: 2),
                          Text('Diária: ${moeda(q.valorDiaria)}', style: TextStyle(fontSize: 13, color: c.text2)),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      transitionBuilder: (w, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: w)),
                      child: Selo(
                        key: ValueKey(ocupado),
                        texto: ocupado ? 'Ocupado' : 'Livre',
                        cor: ocupado ? c.red : c.green,
                        fundo: ocupado ? c.redSoft : c.greenSoft,
                      ),
                    ),
                  ],
                ),
                if (ocupado) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Emo('👤', tamanho: 14),
                      const SizedBox(width: 6),
                      Expanded(child: Text('${q.hospedePrincipal}', style: TextStyle(fontSize: 13, color: c.text, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (w, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: w)),
                        child: ocupado
                            ? BotaoSolido(
                                key: const ValueKey('out'),
                                label: 'Check-out',
                                glifo: '🧳',
                                color: kAmarelo,
                                onTap: () => _modalCheckOut(context, index),
                              )
                            : BotaoSolido(
                                key: const ValueKey('in'),
                                label: 'Check-in',
                                glifo: '🔑',
                                color: c.green,
                                onTap: () => _modalCheckIn(context, index),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BotaoIcone(glifo: '✏️', rotulo: 'Editar quarto', bg: c.brandSoft, onTap: () => _modalEditarQuarto(context, index)),
                    const SizedBox(width: 8),
                    BotaoIcone(glifo: '🗑️', rotulo: 'Remover quarto', bg: c.redSoft, onTap: () => _confirmarRemocao(context, index)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dá um "pulso" no cartão do quarto que acabou de mudar.
  void _pulsar(int index) {
    setState(() => _destaque = index);
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted && _destaque == index) setState(() => _destaque = null);
    });
  }

  void _confirmarRemocao(BuildContext context, int index) {
    final c = context.c;
    final q = globalGerenciador.listaQuartos[index];
    mostrarDialogo(
      context,
      titulo: 'Remover quarto ${q.id}?',
      conteudo: Text('Essa ação não pode ser desfeita.', style: TextStyle(color: c.text2)),
      acoes: [
        botaoCancelar(context),
        BotaoSolido(
          label: 'Remover',
          glifo: '🗑️',
          color: c.red,
          onTap: () {
            globalGerenciador.removerQuarto(index);
            Navigator.pop(context);
            setState(() {});
            aviso(context, 'Quarto ${q.id} removido');
          },
        ),
      ],
    );
  }

  void _modalNovoQuarto(BuildContext context) {
    final numeroCtrl = TextEditingController();
    final tipoCtrl = TextEditingController();
    final diariaCtrl = TextEditingController();
    final erro = ValueNotifier<String?>(null);

    mostrarDialogo(
      context,
      titulo: 'Adicionar quarto',
      conteudo: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          campo(context, numeroCtrl, 'Número do quarto * (ex: 101)'),
          const SizedBox(height: 12),
          campo(context, tipoCtrl, 'Tipo * (ex: Chalé Casal)'),
          const SizedBox(height: 12),
          campo(context, diariaCtrl, 'Valor da diária * (ex: 150,00)', tipo: TextInputType.number),
          erroNoDialogo(context, erro),
        ],
      ),
      acoes: [
        botaoCancelar(context),
        BotaoSolido(
          label: 'Salvar',
          color: context.c.brand,
          onTap: () {
            if (numeroCtrl.text.trim().isEmpty || tipoCtrl.text.trim().isEmpty || diariaCtrl.text.trim().isEmpty) {
              erro.value = 'Preencha todos os campos com *.';
              return;
            }
            final existe = globalGerenciador.listaQuartos.any((q) => q.id == numeroCtrl.text.trim());
            if (existe) {
              erro.value = 'Já existe um quarto com esse número.';
              return;
            }
            globalGerenciador.adicionarQuarto(numeroCtrl.text.trim(), tipoCtrl.text.trim(), lerValor(diariaCtrl.text, 100.0));
            Navigator.pop(context);
            setState(() {});
            aviso(context, 'Quarto ${numeroCtrl.text.trim()} cadastrado');
          },
        ),
      ],
    );
  }

  void _modalEditarQuarto(BuildContext context, int index) {
    final q = globalGerenciador.listaQuartos[index];
    final numeroCtrl = TextEditingController(text: q.id);
    final tipoCtrl = TextEditingController(text: q.tipo);
    final diariaCtrl = TextEditingController(text: q.valorDiaria.toStringAsFixed(2).replaceAll('.', ','));
    final erro = ValueNotifier<String?>(null);

    mostrarDialogo(
      context,
      titulo: 'Editar quarto ${q.id}',
      conteudo: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          campo(context, numeroCtrl, 'Número do quarto *'),
          const SizedBox(height: 12),
          campo(context, tipoCtrl, 'Tipo *'),
          const SizedBox(height: 12),
          campo(context, diariaCtrl, 'Valor da diária *', tipo: TextInputType.number),
          erroNoDialogo(context, erro),
        ],
      ),
      acoes: [
        botaoCancelar(context),
        BotaoSolido(
          label: 'Atualizar',
          color: context.c.brand,
          onTap: () {
            if (numeroCtrl.text.trim().isEmpty || tipoCtrl.text.trim().isEmpty || diariaCtrl.text.trim().isEmpty) {
              erro.value = 'Preencha todos os campos com *.';
              return;
            }
            globalGerenciador.editarQuarto(index, numeroCtrl.text.trim(), tipoCtrl.text.trim(), lerValor(diariaCtrl.text, q.valorDiaria));
            Navigator.pop(context);
            setState(() {});
            aviso(context, 'Quarto atualizado');
          },
        ),
      ],
    );
  }

  void _modalCheckIn(BuildContext context, int index) {
    final c = context.c;
    final nomeCtrl = TextEditingController();
    final cpfCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final placaCtrl = TextEditingController();
    final erro = ValueNotifier<String?>(null);
    final idQuarto = globalGerenciador.listaQuartos[index].id;

    mostrarDialogo(
      context,
      titulo: 'Check-in - Quarto $idQuarto',
      conteudo: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            campo(context, nomeCtrl, 'Nome completo *'),
            const SizedBox(height: 12),
            campo(context, cpfCtrl, 'CPF *', tipo: TextInputType.number, formatadores: [CpfInputFormatter()]),
            const SizedBox(height: 12),
            campo(context, telCtrl, 'Telefone *', tipo: TextInputType.phone, formatadores: [TelefoneInputFormatter()]),
            const SizedBox(height: 12),
            campo(context, placaCtrl, 'Placa do veículo (opcional)'),
            erroNoDialogo(context, erro),
            const SizedBox(height: 18),
            SlideToConfirm(
              texto: 'Deslize para fazer check-in',
              glifo: '🔑',
              cor: c.green,
              onConfirm: () {
                final nome = nomeCtrl.text.trim();
                if (nome.isEmpty) {
                  erro.value = 'Informe o nome do hóspede.';
                  return false;
                }
                if (cpfCtrl.text.isNotEmpty && cpfCtrl.text.length < 14) {
                  erro.value = 'CPF incompleto.';
                  return false;
                }
                erro.value = null;
                globalGerenciador.realizarCheckInCompleto(
                  index: index,
                  nome: nome,
                  cpf: cpfCtrl.text,
                  telefone: telCtrl.text,
                  placa: placaCtrl.text,
                  listaAcompanhantes: [],
                );
                Navigator.pop(context);
                _pulsar(index);
                mostrarAnimacaoAcao(
                  context,
                  tipo: TipoAcao.checkin,
                  titulo: 'Check-in realizado!',
                  subtitulo: 'Quarto $idQuarto - $nome',
                );
                return true;
              },
            ),
          ],
        ),
      ),
      acoes: [botaoCancelar(context)],
    );
  }

  void _modalCheckOut(BuildContext context, int index) {
    final c = context.c;
    final q = globalGerenciador.listaQuartos[index];
    final idQuarto = q.id;
    final nome = '${q.hospedePrincipal}';
    final telefone = '${q.telefone}';
    final diaria = q.valorDiaria;

    mostrarDialogo(
      context,
      titulo: 'Check-out - Quarto $idQuarto',
      conteudo: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconChip(glifo: '👤', bg: c.brandSoft, tamanho: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
                      Text('Tel: $telefone', style: TextStyle(fontSize: 12, color: c.text2)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.brandSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.brand.withValues(alpha: c.hc ? 1 : 0.4), width: c.bw),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Diária do quarto', style: TextStyle(fontSize: 13, color: c.text2)),
                  Text(moeda(diaria), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.brandDark)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SlideToConfirm(
              texto: 'Deslize para fazer check-out',
              glifo: '🧳',
              cor: kAmarelo,
              onConfirm: () {
                globalGerenciador.realizarCheckOut(index);
                Navigator.pop(context);
                _pulsar(index);
                mostrarAnimacaoAcao(
                  context,
                  tipo: TipoAcao.checkout,
                  titulo: 'Check-out realizado!',
                  subtitulo: 'Quarto $idQuarto liberado. Até logo, $nome!',
                );
                return true;
              },
            ),
          ],
        ),
      ),
      acoes: [botaoCancelar(context)],
    );
  }
}

// =============================================================================
//  HÓSPEDES
// =============================================================================
class HospedesScreenTab extends StatelessWidget {
  const HospedesScreenTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final clientes = globalGerenciador.historicoClientes;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hóspedes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.text)),
            const SizedBox(height: 2),
            Text('Histórico (CRM) gerado automaticamente nos check-ins.', style: TextStyle(fontSize: 13, color: c.text2)),
            const SizedBox(height: 14),
            Expanded(
              child: clientes.isEmpty
                  ? estadoVazio(context, '👥', 'Nenhum hóspede no histórico', 'Os hóspedes aparecem aqui depois do primeiro check-in.')
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: clientes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final cli = clientes[index];
                        final inicial = cli.nome.trim().isEmpty ? '?' : cli.nome.trim()[0].toUpperCase();
                        return HCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle, border: Border.all(color: c.brand, width: c.bw)),
                                child: Text(inicial, style: TextStyle(color: c.brandDark, fontWeight: FontWeight.w800, fontSize: 18)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cli.nome, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
                                    const SizedBox(height: 2),
                                    Text('CPF: ${cli.cpf}', style: TextStyle(fontSize: 12, color: c.text2)),
                                    Text('Tel: ${cli.telefone}', style: TextStyle(fontSize: 12, color: c.text2)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
