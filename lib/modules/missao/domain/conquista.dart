bool podeConceder(Set<String> feitas, String cap, String mis) {
  return !feitas.contains('$cap/$mis');
}

String chaveConquista(String cap, String mis) => '$cap/$mis';
