import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';

class BemScreen extends StatefulWidget {
  final String tombamento;

  const BemScreen({
    super.key,
    required this.tombamento,
  });

  @override
  State<BemScreen> createState() => _BemScreenState();
}

class _BemScreenState extends State<BemScreen> {
  String _estadoSelecionado = 'bom';
  final TextEditingController _observacaoController = TextEditingController();
  bool _fotoCapturada = false;

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Ficha do Bem #${widget.tombamento}',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Computador Desktop Dell Optiplex',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Tombamento:', widget.tombamento),
                    _buildInfoRow('Categoria:', 'Equipamentos de Informática'),
                    _buildInfoRow('Local Esperado:', 'Fórum Central / 1º Andar / Sala 101'),
                    _buildInfoRow('Nº de Série:', 'BR-DELL-883921'),
                    _buildInfoRow('Fabricante / Modelo:', 'Dell / OptiPlex 7090'),
                    _buildInfoRow('Responsável:', 'Matrícula 84920'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de Conservação',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        ChoiceChip(
                          label: const Text('Bom'),
                          selected: _estadoSelecionado == 'bom',
                          onSelected: (selected) {
                            if (selected) setState(() => _estadoSelecionado = 'bom');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Regular'),
                          selected: _estadoSelecionado == 'regular',
                          onSelected: (selected) {
                            if (selected) setState(() => _estadoSelecionado = 'regular');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Ruim'),
                          selected: _estadoSelecionado == 'ruim',
                          onSelected: (selected) {
                            if (selected) setState(() => _estadoSelecionado = 'ruim');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Inservível'),
                          selected: _estadoSelecionado == 'inservivel',
                          onSelected: (selected) {
                            if (selected) setState(() => _estadoSelecionado = 'inservivel');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _observacaoController,
                      decoration: const InputDecoration(
                        labelText: 'Observação ou Divergência',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Plaqueta gasta, sem monitor...',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: Icon(_fotoCapturada ? Icons.check_circle : Icons.camera_alt),
                      label: Text(_fotoCapturada ? 'Foto Anexada (SHA-256)' : 'Fotografar Bem ou Plaqueta'),
                      onPressed: () {
                        setState(() => _fotoCapturada = !_fotoCapturada);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _fotoCapturada
                                  ? 'Foto simulada registrada com hash criptográfico!'
                                  : 'Foto removida.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              child: const Text('Salvar e Voltar para Conferência'),
              onPressed: () {
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
