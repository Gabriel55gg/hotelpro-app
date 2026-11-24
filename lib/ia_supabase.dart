import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, FunctionException;
import 'main.dart' show FinanceiroIA;

class IaSupabase extends FinanceiroIA {
  static const _funcao = 'rapid-worker';
  static const _maxHistorico = 10;
  final List<Map<String, String>> _historico = [];

  @override
  void novaConversa() => _historico.clear();

  @override
  Future<String> perguntar(String pergunta, Map<String, dynamic> contexto) async {
    try {
      final res = await Supabase.instance.client.functions
          .invoke(
            _funcao,
            body: {
              'pergunta': pergunta,
              'contexto': contexto,
              'historico': List<Map<String, String>>.from(_historico),
            },
          )
          .timeout(const Duration(seconds: 45));

      final data = res.data;
      final resposta = data is Map ? data['resposta'] : null;
      if (resposta is String && resposta.trim().isNotEmpty) {
        _historico
          ..add({'role': 'user', 'content': pergunta})
          ..add({'role': 'assistant', 'content': resposta});
        while (_historico.length > _maxHistorico) {
          _historico.removeRange(0, 2);
        }
        return resposta.trim();
      }
      return 'Não consegui gerar uma resposta agora. Tente reformular a pergunta.';
    } on FunctionException catch (e) {
      if (e.status == 401) return 'Sua sessão expirou. Saia e entre de novo no app.';
      if (e.status == 429) return 'Muitas perguntas em pouco tempo. Aguarde um instante e tente de novo.';
      return 'O assistente está indisponível no momento. Tente de novo em instantes.';
    } on TimeoutException {
      return 'A resposta demorou demais. Tente de novo.';
    }
  }
}