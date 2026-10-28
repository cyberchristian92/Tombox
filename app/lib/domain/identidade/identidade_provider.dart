import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'identidade_service.dart';

final identidadeAparelhoProvider = FutureProvider<IdentidadeAparelho>((ref) async {
  return await IdentidadeService.obterOuCriarIdentidade();
});
