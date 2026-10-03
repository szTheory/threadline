# RFC 4180's default reserved set (the characters a dumper quotes) covers the
# separator, the escape character, and the line separator — but not a lone
# carriage return. Excel and Python's `csv` module both treat an unquoted
# bare CR as a line break, so a raw-string column containing one (e.g.
# `table_name`, `table_schema`, `op`, or a correlation id) can split a single
# audit row into two apparent CSV records. Adding `"\r"` to the reserved set
# only widens which values get wrapped in quotes; every value that was
# already unquoted stays byte-identical, and a value that gains quoting
# round-trips unchanged for any RFC 4180-compliant reader.
NimbleCSV.define(Threadline.Export.CSV,
  separator: ",",
  escape: "\"",
  line_separator: "\r\n",
  reserved: [",", "\"", "\r", "\n"],
  moduledoc: false
)
