String capitalizePerWords(String input) {
  String output = "";
  for (final word in input.split(" ")) {
    if (word.length > 1) {
      output += "${word[0].toUpperCase() + word.substring(1).toLowerCase()} " ;
    } else {
      output += word.toUpperCase();
    }
  }
  return output;
}
