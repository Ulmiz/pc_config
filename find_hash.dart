void main() {
  var hash = 0xcbf29ce484222325;
  var s = 'PCPartModel';
  for (var i = 0; i < s.length; i++) {
    hash ^= s.codeUnitAt(i) >> 8;
    hash *= 0x100000001b3;
    hash ^= s.codeUnitAt(i) & 0xFF;
    hash *= 0x100000001b3;
  }
  print('Hash of PCPartModel is: $hash');
}
