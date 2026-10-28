import 'package:intl/intl.dart';

/// Utilitários de formatação no padrão brasileiro (pt_BR)
class Formatador {
  static final NumberFormat _inteiro = NumberFormat('#,##0', 'pt_BR');
  static final NumberFormat _decimal = NumberFormat('#,##0.0', 'pt_BR');
  static final NumberFormat _moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  /// Formata número inteiro com ponto de milhar (ex: 1.234)
  static String numero(num valor) => _inteiro.format(valor);

  /// Formata percentual com vírgula (ex: "85,4%")
  static String percentual(double valor) =>
      '${_decimal.format(valor)}%';

  /// Formata valor monetário (ex: "R$ 1.234,56")
  static String moeda(num valor) => _moeda.format(valor);

  /// Formata data/hora (ex: "27/10 às 10:42")
  static String dataHora(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m às $hora:$min';
  }

  /// Formata data simples (ex: "27/10/2026")
  static String data(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final a = dt.year;
    return '$d/$m/$a';
  }
}
