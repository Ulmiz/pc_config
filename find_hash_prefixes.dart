void main() {
  int fastHash(String string) {
    var hash = 0xcbf29ce484222325;
    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }
    return hash;
  }

  bool isSafe(int hash) {
    return hash.abs() <= 9007199254740991;
  }

  print('Searching for safe collection names for PCPart...');
  for (int i = 0; i < 100000; i++) {
    String name = 'PCPart$i';
    int h = fastHash(name);
    if (isSafe(h)) {
      print('Found name: $name with hash: $h');
      break;
    }
  }

  print('Searching for safe collection names for Config...');
  for (int i = 0; i < 100000; i++) {
    String name = 'Config$i';
    int h = fastHash(name);
    if (isSafe(h)) {
      print('Found name: $name with hash: $h');
      break;
    }
  }

  print('Searching for safe index names for partId...');
  for (int i = 0; i < 100000; i++) {
    String name = 'partId$i';
    int h = fastHash(name);
    if (isSafe(h)) {
      print('Found index: $name with hash: $h');
      break;
    }
  }

  print('Searching for safe index names for type...');
  for (int i = 0; i < 100000; i++) {
    String name = 'type$i';
    int h = fastHash(name);
    if (isSafe(h)) {
      print('Found index: $name with hash: $h');
      break;
    }
  }
}
