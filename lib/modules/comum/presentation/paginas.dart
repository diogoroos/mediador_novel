import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novel/core/consts/core_consts.dart';
import 'package:novel/modules/amigos/data/amigos_repositorio.dart';
import 'package:novel/modules/auth/presentation/sessao_controller.dart';
import 'package:novel/modules/jogo/presentation/jogo_controller.dart';
import 'package:novel/modules/pagamento/data/pagamento_repositorio.dart';

class EntradaPage extends StatefulWidget {
  const EntradaPage({super.key});

  @override
  State<EntradaPage> createState() => _EntradaPageState();
}

class _EntradaPageState extends State<EntradaPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Get.find<SessaoController>().iniciar());
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SessaoController>();
    return _fundo(
      child: GetBuilder<SessaoController>(
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Novel', style: TextStyle(color: Color(0xFFF2E6CF), fontSize: 36)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: c.ocupado ? null : c.google, child: Text('entrar_google'.tr)),
            TextButton(onPressed: c.aparelho, child: Text('entrar_aparelho'.tr)),
            if (c.aviso.isNotEmpty) Text(c.aviso, style: const TextStyle(color: Color(0xFFE6C27A))),
          ],
        ),
      ),
    );
  }
}

class CadastroPage extends StatelessWidget {
  const CadastroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SessaoController>();
    return _fundo(
      child: GetBuilder<SessaoController>(
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: c.nomeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'usuario'.tr),
              onChanged: c.gravarRascunhoNome,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final data = await showDatePicker(
                  context: context,
                  initialDate: c.nascimento,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (data != null) {
                  c.nascimento = data;
                  c.update();
                }
              },
              child: Text('${'nascimento'.tr}: ${c.nascimento.day}/${c.nascimento.month}/${c.nascimento.year}'),
            ),
            TextField(
              controller: c.paisCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'E002CTR'),
            ),
            ElevatedButton(onPressed: c.confirmar, child: Text('continuar'.tr)),
            if (c.aviso.isNotEmpty) Text(c.aviso, style: const TextStyle(color: Color(0xFFE6C27A))),
          ],
        ),
      ),
    );
  }
}

class BanidoPage extends StatelessWidget {
  const BanidoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _fundo(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('banido'.tr, style: const TextStyle(color: Color(0xFFF2E6CF), fontSize: 28)),
          const SizedBox(height: 8),
          Text('banido_txt'.tr, style: const TextStyle(color: Colors.white)),
          Text(CoreConsts.emailBan, style: const TextStyle(color: Color(0xFFE6C27A))),
        ],
      ),
    );
  }
}

class MapaPage extends StatelessWidget {
  const MapaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final jogo = Get.find<JogoController>();
    final catalogo = jogo.catalogo;
    return _fundo(
      child: Column(
        children: [
          Text('mapa'.tr, style: const TextStyle(color: Color(0xFFF2E6CF), fontSize: 24)),
          Text(jogo.missao?.tr(jogo.locale, 'desMis') ?? '', style: const TextStyle(color: Colors.white)),
          SizedBox(
            height: 280,
            width: 520,
            child: ListView(
              children: [
                for (final cap in catalogo.caps)
                  for (final mis in cap.mis)
                    if (catalogo.desbloqueada(cap.id, mis.id, jogo.progresso.cap, jogo.progresso.mis))
                      ListTile(
                        title: Text('${cap.id} ${mis.id} ${mis.tr(jogo.locale, 'desMis')}', style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          jogo.progresso
                            ..cap = cap.id
                            ..mis = mis.id
                            ..passo = 0
                            ..hades = false;
                          jogo.gravar();
                          Get.offAllNamed('/jogo');
                          jogo.montar();
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AmigosPage extends StatefulWidget {
  const AmigosPage({super.key});

  @override
  State<AmigosPage> createState() => _AmigosPageState();
}

class _AmigosPageState extends State<AmigosPage> {
  final repo = AmigosRepositorio();
  final nome = TextEditingController();
  List<AmigoPedido> itens = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final jogo = Get.find<JogoController>();
    itens = await repo.listar(jogo.progresso.nome);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final jogo = Get.find<JogoController>();
    return _fundo(
      child: Column(
        children: [
          Text('amigos'.tr, style: const TextStyle(color: Color(0xFFF2E6CF), fontSize: 24)),
          TextField(controller: nome, style: const TextStyle(color: Colors.white)),
          TextButton(
            onPressed: () async {
              await repo.pedir(de: jogo.progresso.nome, deNom: jogo.progresso.nome, paraNom: nome.text.trim());
              await _carregar();
            },
            child: Text('pedir_amigo'.tr),
          ),
          for (final item in itens)
            ListTile(
              title: Text('${item.deNom} → ${item.paraNom} (${item.sta})', style: const TextStyle(color: Colors.white)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: () => repo.atualizar(item.id, 'A').then((_) => _carregar()), child: Text('aceitar'.tr)),
                  TextButton(onPressed: () => repo.atualizar(item.id, 'B').then((_) => _carregar()), child: Text('bloquear'.tr)),
                  TextButton(onPressed: () => repo.remover(item.id).then((_) => _carregar()), child: Text('remover'.tr)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class LojaPage extends StatelessWidget {
  const LojaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final jogo = Get.find<JogoController>();
    final pais = jogo.catalogo.paises[jogo.progresso.pais] ?? jogo.catalogo.paises['BR'];
    final cap = jogo.catalogo.ordemCap(jogo.progresso.cap);
    final mis = jogo.catalogo.ordemMis(jogo.progresso.cap, jogo.progresso.mis);
    final cobrar = CriarCobrancaUsecase(PagamentoRepositorio());
    return _fundo(
      child: Column(
        children: [
          Text('loja'.tr, style: const TextStyle(color: Color(0xFFF2E6CF), fontSize: 24)),
          if (pais == null)
            Text('firebase_ausente'.tr, style: const TextStyle(color: Colors.white))
          else
            for (final item in pais.itm)
              ListTile(
                title: Text('${item.id} ${pais.simMoe} ${item.vlr}', style: const TextStyle(color: Colors.white)),
                subtitle: Text(item.liberado(cap, mis) ? item.tip : 'indisponivel'.tr, style: const TextStyle(color: Colors.white70)),
                trailing: TextButton(
                  onPressed: item.liberado(cap, mis)
                      ? () => cobrar(item: item, pais: pais.id, cap: cap, mis: mis)
                      : null,
                  child: Text('comprar'.tr),
                ),
              ),
        ],
      ),
    );
  }
}

Widget _fundo({required Widget child}) {
  return Scaffold(
    backgroundColor: const Color(0xFF1C1914),
    body: Center(child: child),
  );
}
