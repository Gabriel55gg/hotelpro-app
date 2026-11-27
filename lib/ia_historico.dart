import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Id da pousada logada (preenchido no main.dart quando o app carrega os dados).
String globalEmpresaId = '';

class ConversaResumo {
  final String id;
  final String titulo;
  final DateTime data;
  ConversaResumo(this.id, this.titulo, this.data);
}

class MsgSalva {
  final bool minha;
  final String texto;
  final DateTime hora;
  MsgSalva(this.minha, this.texto, this.hora);
}

/// Salva e lê as conversas com a assistente nas tabelas
/// `ia_conversas` e `ia_mensagens` (veja o arquivo ia_historico.sql).
class IaHistorico {
  static SupabaseClient get _db => Supabase.instance.client;

  /// Conversa que está aberta agora (null = ainda não foi criada).
  static String? conversaId;

  static void nova() => conversaId = null;

  static Future<void> salvar(bool minha, String texto) async {
    if (globalEmpresaId.isEmpty) return;
    try {
      if (conversaId == null) {
        final t = texto.trim();
        final titulo = t.length > 45 ? '${t.substring(0, 45)}…' : t;
        final r = await _db
            .from('ia_conversas')
            .insert({'empresa_id': globalEmpresaId, 'titulo': titulo})
            .select('id')
            .single();
        conversaId = r['id'].toString();
      }
      await _db.from('ia_mensagens').insert({
        'conversa_id': conversaId,
        'empresa_id': globalEmpresaId,
        'minha': minha,
        'texto': texto,
      });
      await _db
          .from('ia_conversas')
          .update({'atualizado_em': DateTime.now().toUtc().toIso8601String()})
          .eq('id', conversaId!);
    } catch (e) {
      debugPrint('Erro ao salvar conversa: $e');
    }
  }

  static Future<List<ConversaResumo>> listar() async {
    if (globalEmpresaId.isEmpty) return [];
    try {
      final r = await _db
          .from('ia_conversas')
          .select('id, titulo, atualizado_em')
          .eq('empresa_id', globalEmpresaId)
          .order('atualizado_em', ascending: false)
          .limit(50);
      return (r as List)
          .map((e) => ConversaResumo(
                e['id'].toString(),
                (e['titulo'] ?? 'Conversa').toString(),
                DateTime.parse(e['atualizado_em'].toString()).toLocal(),
              ))
          .toList();
    } catch (e) {
      debugPrint('Erro ao listar conversas: $e');
      return [];
    }
  }

  static Future<List<MsgSalva>> carregar(String id) async {
    try {
      final r = await _db
          .from('ia_mensagens')
          .select('minha, texto, criado_em')
          .eq('conversa_id', id)
          .order('criado_em', ascending: true);
      return (r as List)
          .map((e) => MsgSalva(
                e['minha'] == true,
                (e['texto'] ?? '').toString(),
                DateTime.parse(e['criado_em'].toString()).toLocal(),
              ))
          .toList();
    } catch (e) {
      debugPrint('Erro ao carregar conversa: $e');
      return [];
    }
  }

  static Future<void> apagar(String id) async {
    try {
      await _db.from('ia_conversas').delete().eq('id', id);
      if (conversaId == id) conversaId = null;
    } catch (e) {
      debugPrint('Erro ao apagar conversa: $e');
    }
  }
}