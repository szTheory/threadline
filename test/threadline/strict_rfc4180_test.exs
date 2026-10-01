defmodule Threadline.Test.StrictRFC4180Test do
  use ExUnit.Case, async: true

  alias Threadline.Test.StrictRFC4180

  describe "accepts" do
    test "empty input decodes to no records" do
      assert StrictRFC4180.decode!("") == []
    end

    test "a plain unquoted record" do
      assert StrictRFC4180.decode!("a,b\r\n") == [["a", "b"]]
    end

    test "quoted fields with a comma and a doubled escaped quote" do
      assert StrictRFC4180.decode!(~s("a,b","c""d"\r\n)) == [["a,b", "c\"d"]]
    end

    test "CRLF inside a quoted field is data, not a record break" do
      assert StrictRFC4180.decode!("\"x\r\ny\",z\r\n") == [["x\r\ny", "z"]]
    end

    test "a bare CR inside a quoted field is data" do
      assert StrictRFC4180.decode!("\"a\rb\",z\r\n") == [["a\rb", "z"]]
    end

    test "a bare LF inside a quoted field is data" do
      assert StrictRFC4180.decode!("\"a\nb\",z\r\n") == [["a\nb", "z"]]
    end

    test "a tab and non-ASCII (including astral) codepoints" do
      assert StrictRFC4180.decode!("\t,é😀\r\n") == [["\t", "é😀"]]
    end

    test "two empty fields" do
      assert StrictRFC4180.decode!(",\r\n") == [["", ""]]
    end
  end

  describe "rejects" do
    test "a bare CR in an unquoted field" do
      assert_raise ArgumentError, ~r/bare CR/, fn ->
        StrictRFC4180.decode!("a\rb,c\r\n")
      end
    end

    test "a bare LF in an unquoted field" do
      assert_raise ArgumentError, ~r/bare LF/, fn ->
        StrictRFC4180.decode!("a\nb\r\n")
      end
    end

    test "a stray quote in an unquoted field" do
      assert_raise ArgumentError, ~r/stray quote/, fn ->
        StrictRFC4180.decode!("a\"b,c\r\n")
      end
    end

    test "data after a closing quote" do
      assert_raise ArgumentError, fn ->
        StrictRFC4180.decode!("\"ab\"c\r\n")
      end
    end

    test "an unterminated quoted field" do
      assert_raise ArgumentError, ~r/unterminated quoted field/, fn ->
        StrictRFC4180.decode!("\"abc")
      end
    end

    test "a final record without a trailing CRLF" do
      assert_raise ArgumentError, ~r/without CRLF/, fn ->
        StrictRFC4180.decode!("a,b")
      end
    end
  end
end
