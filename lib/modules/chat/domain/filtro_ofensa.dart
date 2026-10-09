bool frasePermitida(String texto, Iterable<String> palavras) {
  final limpo = _normalizar(texto);
  for (final palavra in palavras) {
    final alvo = _normalizar(palavra);
    if (alvo.isEmpty) continue;
    if (limpo.contains(alvo)) return false;
  }
  return true;
}

String _normalizar(String texto) {
  return texto
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');
}
