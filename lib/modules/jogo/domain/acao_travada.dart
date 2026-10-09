enum ModoAcao { nenhuma, ataque, interagir, poder }

/// Trava a ação no instante do clique. Segurar 2s deixa a ação contínua
/// depois de soltar. Andar não entra aqui: quem chama não deve limpar no movimento.
class AcaoTravada {
  static const limiar = Duration(seconds: 2);

  ModoAcao modo = ModoAcao.nenhuma;
  bool continua = false;
  bool _segurando = false;
  Duration _acumulado = Duration.zero;

  void pointerDown({required bool sobreObjetoPerto, bool poder = false}) {
    continua = false;
    _acumulado = Duration.zero;
    _segurando = true;
    if (poder) {
      modo = ModoAcao.poder;
      return;
    }
    modo = sobreObjetoPerto ? ModoAcao.interagir : ModoAcao.ataque;
  }

  void tickSegurando(Duration dt) {
    if (!_segurando || continua || modo == ModoAcao.nenhuma || modo == ModoAcao.poder) return;
    _acumulado += dt;
    if (_acumulado >= limiar) continua = true;
  }

  void pointerUp() {
    _segurando = false;
  }

  bool get disparoUnico => modo != ModoAcao.nenhuma && !continua && !_segurando;

  void consumirDisparo() {
    if (!continua) {
      modo = ModoAcao.nenhuma;
      _acumulado = Duration.zero;
    }
  }

  void encerrar() {
    modo = ModoAcao.nenhuma;
    continua = false;
    _segurando = false;
    _acumulado = Duration.zero;
  }
}

class EspacoPose {
  static const limiar = Duration(seconds: 2);
  Duration acumulado = Duration.zero;
  bool segurando = false;
  bool ativa = false;

  void down() {
    segurando = true;
    if (!ativa) acumulado = Duration.zero;
  }

  void tick(Duration dt, {required bool topDown}) {
    if (!segurando || !topDown || ativa) return;
    acumulado += dt;
    if (acumulado >= limiar) ativa = true;
  }

  bool up() {
    final curto = segurando && !ativa;
    segurando = false;
    if (!ativa) acumulado = Duration.zero;
    return curto;
  }

  void levantar() {
    ativa = false;
    acumulado = Duration.zero;
    segurando = false;
  }
}
