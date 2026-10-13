/// Hash determinista FNV-1a de 32 bits.
///
/// A diferencia de [String.hashCode], este valor es estable entre
/// ejecuciones e isolates (Dart no garantiza la estabilidad de
/// `hashCode` entre arranques de la app), por lo que es seguro usarlo
/// como identificador persistente de alarmas y notificaciones nativas.
int stableHash(String input) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < input.length; i++) {
    hash ^= input.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
