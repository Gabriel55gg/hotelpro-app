class Produto {
  String id;
  String nome;
  double precoCusto;
  double precoVenda;
  String codigoBarras;
  int estoqueAtual;
  String imagemUrl; // URL ou ícone para ilustrar o produto

  Produto({
    required this.id,
    required this.nome,
    required this.precoCusto,
    required this.precoVenda,
    required this.codigoBarras,
    required this.estoqueAtual,
    this.imagemUrl = '',
  });

  double get lucroUnitario => precoVenda - precoCusto;
}

class GerenciadorProdutos {
  final List<Produto> listaProdutos = [
    Produto(
      id: '1',
      nome: 'Água Mineral 500ml',
      precoCusto: 2.00,
      precoVenda: 5.00,
      codigoBarras: '7891000100101',
      estoqueAtual: 48,
      imagemUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=200',
    ),
    Produto(
      id: '2',
      nome: 'Refrigerante Lata',
      precoCusto: 3.50,
      precoVenda: 7.00,
      codigoBarras: '7892000200202',
      estoqueAtual: 36,
      imagemUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=200',
    ),
    Produto(
      id: '3',
      nome: 'Cerveja Long Neck',
      precoCusto: 5.00,
      precoVenda: 10.00,
      codigoBarras: '7893000300303',
      estoqueAtual: 24,
      imagemUrl: 'https://images.unsplash.com/photo-1608270154045-31362e3d368e?w=200',
    ),
    Produto(
      id: '4',
      nome: 'Chocolate / Snacks',
      precoCusto: 3.00,
      precoVenda: 6.00,
      codigoBarras: '7894000400404',
      estoqueAtual: 15,
      imagemUrl: 'https://images.unsplash.com/photo-1549007994-cb92caebd54b?w=200',
    ),
  ];

  void adicionarProduto({
    required String nome,
    required double precoCusto,
    required double precoVenda,
    required String codigoBarras,
    required int estoqueInicial,
    String imagemUrl = '',
  }) {
    listaProdutos.add(
      Produto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nome: nome,
        precoCusto: precoCusto,
        precoVenda: precoVenda,
        codigoBarras: codigoBarras,
        estoqueAtual: estoqueInicial,
        imagemUrl: imagemUrl,
      ),
    );
  }

  void adicionarEstoque(String codigoBarras, int quantidade) {
    var prod = listaProdutos.firstWhere(
      (p) => p.codigoBarras == codigoBarras,
      orElse: () => Produto(id: '', nome: '', precoCusto: 0, precoVenda: 0, codigoBarras: '', estoqueAtual: 0),
    );
    if (prod.id.isNotEmpty) {
      prod.estoqueAtual += quantidade;
    }
  }

  void decrementarEstoque(String nomeProduto, int quantidade) {
    for (var p in listaProdutos) {
      if (p.nome == nomeProduto) {
        p.estoqueAtual = (p.estoqueAtual - quantidade >= 0) ? p.estoqueAtual - quantidade : 0;
      }
    }
  }

  void removerProduto(int index) {
    listaProdutos.removeAt(index);
  }
}

final GerenciadorProdutos globalProdutos = GerenciadorProdutos();