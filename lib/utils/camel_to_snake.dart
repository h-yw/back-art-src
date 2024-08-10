String camelToSnake(String input) {
  if (input.isEmpty) {
    return input;
  }
  final buffer = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    if (input[i].toUpperCase() == input[i] && i != 0) {
      buffer.write('_');
    }
    buffer.write(input[i].toLowerCase());
  }
  return buffer.toString();
}
