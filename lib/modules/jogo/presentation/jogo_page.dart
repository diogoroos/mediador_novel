import 'package:bonfire/bonfire.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novel/modules/jogo/presentation/jogo_controller.dart';
import 'package:novel/modules/missao/domain/aceite.dart';

class JogoPage extends StatefulWidget {
  const JogoPage({super.key});

  @override
  State<JogoPage> createState() => _JogoPageState();
}

class _JogoPageState extends State<JogoPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = Get.find<JogoController>();
      if (c.mundo == null) c.montar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<JogoController>();
    return Scaffold(
      backgroundColor: const Color(0xFF1C1914),
      body: GetBuilder<JogoController>(
        id: 'cena',
        builder: (_) {
          if (c.carregando || c.mundo == null || c.jogador == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              Listener(
                onPointerDown: (e) {
                  final jogador = c.jogador;
                  if (jogador == null || !jogador.isMounted) return;
                  final mundo = jogador.gameRef.screenToWorld(Vector2(e.localPosition.dx, e.localPosition.dy));
                  c.clique(mundo, poder: e.buttons == kSecondaryMouseButton);
                },
                onPointerUp: (_) => c.soltar(),
                child: BonfireWidget(
                  key: ValueKey(c.chave),
                  map: c.mundo!,
                  player: c.jogador,
                  components: c.extras,
                  playerControllers: [
                    Keyboard(config: KeyboardConfig(directionalKeys: [KeyboardDirectionalKeys.wasd()])),
                    if (c.toque) Joystick(directional: JoystickDirectional()),
                  ],
                  cameraConfig: CameraConfig(zoom: 1.6),
                  backgroundColor: const Color(0xFF87A85A),
                ),
              ),
              GetBuilder<JogoController>(id: 'hud', builder: (_) => _Hud(c)),
            ],
          );
        },
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud(this.c);
  final JogoController c;

  @override
  Widget build(BuildContext context) {
    final missao = c.missao;
    final texto = missao?.tr(c.locale, 'desMis') ?? '';
    return Stack(
      children: [
        Positioned(
          left: 12,
          right: 12,
          top: 8,
          child: Row(
            children: [
              _barra('vida'.tr, c.jogador?.life.value ?? c.progresso.vida, c.jogador?.life.max ?? c.progresso.vidaMax),
              const SizedBox(width: 8),
              _barra('mana'.tr, c.jogador?.mana ?? c.progresso.mana, c.jogador?.manaMax ?? c.progresso.manaMax),
              const Spacer(),
              Text(texto, style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              _botao('tenda'.tr, () => c.abrirPainel('tenda')),
              _botao('mochila'.tr, () => c.abrirPainel('mochila')),
              _botao('mapa'.tr, () => Get.toNamed('/mapa')),
              _botao('amigos'.tr, () => Get.toNamed('/amigos')),
              _botao('loja'.tr, () => Get.toNamed('/loja')),
            ],
          ),
        ),
        if (c.slides.isNotEmpty)
          _painel(
            c.slides[c.slideI],
            onPressed: c.proximoSlide,
            rotulo: 'avancar'.tr,
          ),
        if (c.balaoI >= 0 && c.balao.isNotEmpty)
          _painel(c.balao[c.balaoI], onPressed: c.proximoBalao, rotulo: 'avancar'.tr),
        if (c.balaoI < 0 && c.balao.isNotEmpty)
          Positioned(top: 48, right: 12, child: _botao('reler'.tr, c.relerBalao)),
        if (c.guia != null)
          _painel(
            missao?.tr(c.locale, c.guia!.txt) ?? '',
            child: Wrap(
              spacing: 8,
              children: c.guia!.op
                  .map((op) => ElevatedButton(
                        onPressed: () => c.escolherGuia(op),
                        child: Text(missao?.tr(c.locale, op.rot) ?? op.rot),
                      ))
                  .toList(),
            ),
          ),
        if (c.painel == 'tenda' || c.painel == 'mochila') _inventario(context),
        if (c.progresso.hades) _hades(),
        if (c.novoMundo) _painel('novo_mundo'.tr, rotulo: 'mapa'.tr, onPressed: () => Get.toNamed('/mapa')),
        Positioned(
          left: 12,
          right: 12,
          bottom: 8,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: c.chatCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: 'chat'.tr, hintStyle: const TextStyle(color: Colors.white54)),
                ),
              ),
              _botao('enviar'.tr, c.enviarChat),
              if (c.aviso.isNotEmpty) Text(c.aviso, style: const TextStyle(color: Color(0xFFE6C27A))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inventario(BuildContext context) {
    final tenda = c.painel == 'tenda';
    final itens = tenda ? c.progresso.tenda.espacos : c.progresso.mochila;
    final missao = c.missao;
    return _painel(
      tenda ? 'tenda'.tr : 'mochila'.tr,
      child: SizedBox(
        height: 180,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
          itemCount: itens.length,
          itemBuilder: (_, i) {
            final item = itens[i];
            final aceito = missao == null || item.vazio || itemAceito(missao, item);
            return GestureDetector(
              onTap: () => tenda ? c.retirarTenda(i) : c.guardarNaTenda(i),
              onDoubleTap: tenda ? () => c.dividirTenda(i) : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                color: aceito ? const Color(0xFF3A3428) : const Color(0xFF5A3030),
                child: Center(
                  child: Text(item.vazio ? '' : '${item.id} ${item.qtd}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _hades() {
    return _painel(
      c.missao?.tr(c.locale, 'perg') ?? '',
      child: Row(
        children: [
          Expanded(child: TextField(controller: c.hadesCtrl, style: const TextStyle(color: Colors.white))),
          _botao('avancar'.tr, c.responderHades),
        ],
      ),
    );
  }
}

Widget _barra(String nome, double valor, double max) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$nome ${(valor).round()}/${max.round()}', style: const TextStyle(color: Colors.white)),
    ],
  );
}

Widget _botao(String rotulo, VoidCallback onPressed) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: TextButton(onPressed: onPressed, child: Text(rotulo)),
  );
}

Widget _painel(String texto, {VoidCallback? onPressed, String? rotulo, Widget? child}) {
  return Center(
    child: Container(
      width: 520,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      color: const Color(0xF21C1914),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(texto, style: const TextStyle(color: Color(0xFFF2E6CF), fontSize: 18)),
          if (child != null) Padding(padding: const EdgeInsets.only(top: 12), child: child),
          if (onPressed != null) TextButton(onPressed: onPressed, child: Text(rotulo ?? '')),
        ],
      ),
    ),
  );
}
