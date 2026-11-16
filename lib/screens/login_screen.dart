import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, AuthException;

/// Paleta do HotelPro: preto + dourado.
/// Combinações texto/fundo seguem contraste WCAG AA.
class _Paleta {
  static const fundo = Color(0xFF0A0A0A);
  static const campo = Color(0xFF161513);
  static const borda = Color(0xFF76705F); // contorno dos campos (>= 3:1)
  static const texto = Color(0xFFF5F1E8);
  static const textoSuave = Color(0xFFB8B09E);
  static const dica = Color(0xFF918A78);
  static const ouro = Color(0xFFD4A537); // botão (texto preto = 9:1)
  static const ouroClaro = Color(0xFFE8C36A); // links e foco
  static const ouroSuave = Color(0xFFF2DDA0);
  static const ouroProfundo = Color(0xFF2A2110);
  static const erro = Color(0xFFFF6B6B);
}

class LoginScreen extends StatefulWidget {
  /// Chamado quando o login dá certo. O main.dart usa isso para liberar o app.
  final VoidCallback? onLoginSucesso;

  const LoginScreen({super.key, this.onLoginSucesso});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _senhaFocus = FocusNode();

  bool _ocultarSenha = true;
  bool _carregando = false;
  String? _erro; // mensagem de erro geral (login/rede), mostrada acima do botão

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  bool _emailValido(String texto) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto.trim());

  String _traduzirErro(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar. Veja sua caixa de entrada.';
    }
    if (msg.contains('too many') || e.statusCode == '429') {
      return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
    }
    return 'Não foi possível entrar. Tente novamente.';
  }

  Future<void> _entrar() async {
    if (_carregando) return;
    setState(() => _erro = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _carregando = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );
      if (!mounted) return;
      widget.onLoginSucesso?.call();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _erro = _traduzirErro(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível conectar. Verifique sua internet e tente de novo.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _esqueciSenha() async {
    if (_carregando) return;
    final email = _emailController.text.trim();
    if (!_emailValido(email)) {
      setState(() => _erro = 'Digite seu e-mail acima para receber o link de redefinição.');
      return;
    }

    setState(() {
      _erro = null;
      _carregando = true;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } on AuthException {
      // Resposta neutra de propósito: não revela se o e-mail existe ou não.
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível conectar. Verifique sua internet e tente de novo.';
      });
      return;
    }
    if (!mounted) return;
    setState(() => _carregando = false);
    _aviso('Se esse e-mail estiver cadastrado, enviamos um link para redefinir a senha.');
  }

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensagem,
          style: const TextStyle(color: _Paleta.texto),
        ),
        backgroundColor: _Paleta.ouroProfundo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _decoracao({
    required String dica,
    required IconData icone,
    Widget? sufixo,
  }) {
    OutlineInputBorder borda(Color cor, double largura) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cor, width: largura),
        );

    return InputDecoration(
      hintText: dica,
      hintStyle: const TextStyle(color: _Paleta.dica),
      prefixIcon: Icon(icone, color: _Paleta.ouroClaro, size: 20),
      suffixIcon: sufixo,
      filled: true,
      fillColor: _Paleta.campo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      border: borda(_Paleta.borda, 1),
      enabledBorder: borda(_Paleta.borda, 1),
      focusedBorder: borda(_Paleta.ouroClaro, 2),
      errorBorder: borda(_Paleta.erro, 1.5),
      focusedErrorBorder: borda(_Paleta.erro, 2),
      errorStyle: const TextStyle(
        color: _Paleta.erro,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Rótulo fixo acima do campo (sempre visível), com ação opcional à direita.
  Widget _rotulo(String texto, {Widget? acao}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                texto,
                style: const TextStyle(
                  color: _Paleta.texto,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          ?acao,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Paleta.fundo,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final telaLarga = constraints.maxWidth >= 900;
          final painelLogin = _construirPainelLogin();

          return Row(
            children: [
              if (telaLarga)
                SizedBox(width: 500, child: painelLogin)
              else
                Expanded(child: painelLogin),
              if (telaLarga) const Expanded(child: _PainelTech()),
            ],
          );
        },
      ),
    );
  }

  Widget _construirPainelLogin() {
    return ClipRect(
      child: Stack(
        children: [
          // Brilho dourado suave no canto (decorativo)
          Positioned(
            top: -140,
            right: -140,
            width: 380,
            height: 380,
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _Paleta.ouro.withAlpha(70),
                      _Paleta.ouro.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _MarcaHotelPro(),
                          const SizedBox(height: 44),
                          Semantics(
                            header: true,
                            child: const Text(
                              'Bem-vindo de volta',
                              style: TextStyle(
                                color: _Paleta.texto,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Use o e-mail do responsável para acessar.',
                            style: TextStyle(
                              color: _Paleta.textoSuave,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // E-mail
                          _rotulo('E-mail'),
                          Semantics(
                            label: 'E-mail',
                            child: TextFormField(
                              controller: _emailController,
                              enabled: !_carregando,
                              keyboardType: TextInputType.emailAddress,
                              keyboardAppearance: Brightness.dark,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              enableSuggestions: false,
                              cursorColor: _Paleta.ouroClaro,
                              style: const TextStyle(
                                color: _Paleta.texto,
                                fontSize: 16,
                              ),
                              decoration: _decoracao(
                                dica: 'voce@pousada.com',
                                icone: Icons.mail_outline_rounded,
                              ),
                              validator: (valor) {
                                final texto = valor ?? '';
                                if (texto.trim().isEmpty) {
                                  return 'Digite seu e-mail.';
                                }
                                if (!_emailValido(texto)) {
                                  return 'E-mail inválido. Confira o que digitou.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _senhaFocus.requestFocus(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Senha (com "Esqueci a senha" na linha do rótulo)
                          _rotulo(
                            'Senha',
                            acao: TextButton(
                              onPressed: _carregando ? null : _esqueciSenha,
                              style: TextButton.styleFrom(
                                foregroundColor: _Paleta.ouroClaro,
                                minimumSize: const Size(48, 32),
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                tapTargetSize: MaterialTapTargetSize.padded,
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Esqueci a senha'),
                            ),
                          ),
                          Semantics(
                            label: 'Senha',
                            child: TextFormField(
                              controller: _senhaController,
                              focusNode: _senhaFocus,
                              enabled: !_carregando,
                              obscureText: _ocultarSenha,
                              keyboardAppearance: Brightness.dark,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              cursorColor: _Paleta.ouroClaro,
                              style: const TextStyle(
                                color: _Paleta.texto,
                                fontSize: 16,
                              ),
                              decoration: _decoracao(
                                dica: 'Digite sua senha',
                                icone: Icons.lock_outline_rounded,
                                sufixo: IconButton(
                                  tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  icon: Icon(
                                    _ocultarSenha
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: _Paleta.textoSuave,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                                ),
                              ),
                              validator: (valor) {
                                if (valor == null || valor.isEmpty) {
                                  return 'Digite sua senha.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _entrar(),
                            ),
                          ),

                          // Erro geral (login incorreto, sem internet...)
                          if (_erro != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _Paleta.erro.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _Paleta.erro.withAlpha(120)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 1),
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        size: 18,
                                        color: _Paleta.erro,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _erro!,
                                        style: const TextStyle(
                                          color: _Paleta.texto,
                                          fontSize: 13.5,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Botão principal
                          Semantics(
                            button: true,
                            enabled: !_carregando,
                            label: _carregando ? 'Entrando, aguarde' : 'Entrar',
                            excludeSemantics: true,
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _carregando ? null : _entrar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _Paleta.ouro,
                                  foregroundColor: _Paleta.fundo,
                                  disabledBackgroundColor: _Paleta.ouro,
                                  disabledForegroundColor: _Paleta.fundo,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _carregando
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: _Paleta.fundo,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Entrar',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(Icons.arrow_forward_rounded, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Nota de acesso
                          const Row(
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 16,
                                color: _Paleta.textoSuave,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Acesso exclusivo do responsável pela pousada.',
                                  style: TextStyle(
                                    color: _Paleta.textoSuave,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo (ícone da cama de hotel) + nome.
class _MarcaHotelPro extends StatelessWidget {
  const _MarcaHotelPro();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'HotelPro, gestão de pousadas',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8C36A), _Paleta.ouro],
              ),
              boxShadow: [
                BoxShadow(
                  color: _Paleta.ouro.withAlpha(90),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.hotel_rounded,
              color: _Paleta.fundo,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Hotel',
                      style: TextStyle(
                        color: _Paleta.texto,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: 'Pro',
                      style: TextStyle(
                        color: _Paleta.ouroClaro,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: -0.6,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Gestão de pousadas',
                style: TextStyle(
                  color: _Paleta.textoSuave,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lado direito (só em telas largas): decorativo, fora da leitura de tela.
class _PainelTech extends StatelessWidget {
  const _PainelTech();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Paleta.ouroProfundo, _Paleta.fundo],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _FundoTechPainter())),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sua pousada organizada, do check-in ao caixa.',
                        style: TextStyle(
                          color: _Paleta.texto,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                          letterSpacing: -0.9,
                        ),
                      ),
                      SizedBox(height: 40),
                      _Beneficio(
                        icone: Icons.event_available_rounded,
                        texto: 'Reservas e check-in em um só lugar',
                      ),
                      SizedBox(height: 16),
                      _Beneficio(
                        icone: Icons.king_bed_outlined,
                        texto: 'Quartos e limpeza sempre atualizados',
                      ),
                      SizedBox(height: 16),
                      _Beneficio(
                        icone: Icons.payments_outlined,
                        texto: 'Hóspedes e caixa sem planilha',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Beneficio extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _Beneficio({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Paleta.ouroClaro.withAlpha(70)),
            color: _Paleta.ouro.withAlpha(36),
          ),
          child: Icon(icone, color: _Paleta.ouroSuave, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: _Paleta.texto,
              fontSize: 16,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Grade de pontos + linhas de onda finas (estilo "tech", bem discreto).
class _FundoTechPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ponto = Paint()..color = Colors.white.withAlpha(18);
    for (double x = 24; x < size.width; x += 28) {
      for (double y = 24; y < size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 1.1, ponto);
      }
    }

    for (var i = 0; i < 5; i++) {
      final linha = Paint()
        ..color = _Paleta.ouroClaro.withAlpha(24 + i * 9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      final base = size.height * 0.78 + i * 16;
      final caminho = Path()..moveTo(0, base);
      for (double x = 0; x <= size.width; x += 4) {
        final y = base +
            math.sin((x / size.width) * 2 * math.pi * 1.5 + i * 0.7) *
                (14 + i * 2);
        caminho.lineTo(x, y);
      }
      canvas.drawPath(caminho, linha);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter antigo) => false;
}