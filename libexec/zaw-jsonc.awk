# Strip JSONC (// and /* */ comments, trailing commas) to plain JSON so jq
# can parse it. Streaming state machine: comments outside strings are
# removed; block comments may span lines. Insignificant whitespace around a
# stripped trailing comma is not preserved (jq reparses the output anyway).
BEGIN { in_block = 0 }
{
  line = $0
  n = length(line)
  out = ""
  i = 1
  in_string = 0
  while (i <= n) {
    c = substr(line, i, 1)
    if (in_block) {
      if (c == "*" && substr(line, i + 1, 1) == "/") { in_block = 0; i += 2 } else { i += 1 }
      continue
    }
    if (in_string) {
      out = out c
      if (c == "\\" && i < n) { out = out substr(line, i + 1, 1); i += 2; continue }
      if (c == "\"") in_string = 0
      i += 1
      continue
    }
    if (c == "\"") { in_string = 1; out = out c; i += 1; continue }
    if (c == "/" && substr(line, i + 1, 1) == "/") { break }
    if (c == "/" && substr(line, i + 1, 1) == "*") { in_block = 1; i += 2; continue }
    out = out c
    i += 1
  }
  buf = buf out "\n"
}
END {
  gsub(/,[ \t\r\n]*}/, "}", buf)
  gsub(/,[ \t\r\n]*]/, "]", buf)
  printf "%s", buf
}
