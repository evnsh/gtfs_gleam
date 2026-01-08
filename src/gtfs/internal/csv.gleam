//// RFC 4180 compliant CSV parser for GTFS files
////
//// This module provides CSV parsing following the GTFS specification:
//// - UTF-8 encoded (BOM acceptable but ignored)
//// - Fields may be quoted with double quotes
//// - Double quotes in fields are escaped as ""
//// - CRLF or LF line endings are accepted
//// - First row contains field names (headers)
////
//// Source: GTFS reference.md - File Requirements

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gsv

// =============================================================================
// Types
// =============================================================================

/// A parsed CSV row as a dictionary of field names to values
pub type CsvRow =
  Dict(String, String)

/// Errors that can occur during CSV parsing
pub type ParseError {
  /// A required field is missing from the row
  MissingRequiredField(field: String, row: Int)
  /// A field value is invalid for its expected type
  InvalidFieldValue(field: String, value: String, expected: String, row: Int)
  /// The row format is malformed
  InvalidRowFormat(row: Int, reason: String)
  /// Invalid UTF-8 encoding
  InvalidUtf8(row: Int)
  /// Quoting error (unclosed quote, etc.)
  QuotingError(row: Int, reason: String)
  /// No header row found
  EmptyFile
  /// Mismatched field count
  FieldCountMismatch(row: Int, expected: Int, got: Int)
}

// =============================================================================
// Main Parsing Function
// =============================================================================

/// Parse CSV content following RFC 4180 rules
/// Returns a list of rows, each as a dictionary mapping field names to values
pub fn parse(content: String) -> Result(List(CsvRow), ParseError) {
  let content = strip_bom(content)
  let content = string.replace(content, "\r\n", "\n")
  let content = string.replace(content, "\r", "\n")

  use rows <- result.try(
    gsv.to_lists(content, separator: ",")
    |> result.map_error(gsv_error_to_parse_error),
  )

  case rows {
    [] -> Error(EmptyFile)
    [headers, ..data_rows] -> parse_data_rows(data_rows, headers, 2, [])
  }
}

/// Parse CSV content and return raw rows (list of field lists)
/// Useful when you need the raw data without header mapping
pub fn parse_raw(content: String) -> Result(List(List(String)), ParseError) {
  let content = strip_bom(content)
  let content = string.replace(content, "\r\n", "\n")
  let content = string.replace(content, "\r", "\n")

  use rows <- result.try(
    gsv.to_lists(content, separator: ",")
    |> result.map_error(gsv_error_to_parse_error),
  )

  case rows {
    [] -> Error(EmptyFile)
    rows -> Ok(rows)
  }
}

// =============================================================================
// Field Access Helpers
// =============================================================================

/// Get a required field from a row
/// Returns an error if the field is missing or empty
pub fn get_required(
  row: CsvRow,
  field: String,
  row_num: Int,
) -> Result(String, ParseError) {
  case dict.get(row, field) {
    Ok(value) if value != "" -> Ok(value)
    _ -> Error(MissingRequiredField(field: field, row: row_num))
  }
}

/// Get an optional field from a row
/// Returns None if the field is missing or empty
pub fn get_optional(row: CsvRow, field: String) -> Option(String) {
  case dict.get(row, field) {
    Ok(value) if value != "" -> Some(value)
    _ -> None
  }
}

/// Get a field and parse it with a custom parser
pub fn get_parsed(
  row: CsvRow,
  field: String,
  row_num: Int,
  parser: fn(String) -> Result(a, String),
) -> Result(Option(a), ParseError) {
  case dict.get(row, field) {
    Ok(value) if value != "" -> {
      case parser(value) {
        Ok(parsed) -> Ok(Some(parsed))
        Error(msg) ->
          Error(InvalidFieldValue(
            field: field,
            value: value,
            expected: msg,
            row: row_num,
          ))
      }
    }
    _ -> Ok(None)
  }
}

/// Get a required field and parse it with a custom parser
pub fn get_required_parsed(
  row: CsvRow,
  field: String,
  row_num: Int,
  parser: fn(String) -> Result(a, String),
) -> Result(a, ParseError) {
  case dict.get(row, field) {
    Ok(value) if value != "" -> {
      case parser(value) {
        Ok(parsed) -> Ok(parsed)
        Error(msg) ->
          Error(InvalidFieldValue(
            field: field,
            value: value,
            expected: msg,
            row: row_num,
          ))
      }
    }
    _ -> Error(MissingRequiredField(field: field, row: row_num))
  }
}

/// Get a field with a default value if missing or empty
pub fn get_with_default(
  row: CsvRow,
  field: String,
  default: a,
  parser: fn(String) -> Result(a, String),
) -> a {
  case dict.get(row, field) {
    Ok(value) if value != "" -> {
      case parser(value) {
        Ok(parsed) -> parsed
        Error(_) -> default
      }
    }
    _ -> default
  }
}

// =============================================================================
// Internal Parsing Functions
// =============================================================================

/// Strip UTF-8 BOM if present
fn strip_bom(content: String) -> String {
  case content {
    "\u{FEFF}" <> rest -> rest
    _ -> content
  }
}

fn gsv_error_to_parse_error(error: gsv.Error) -> ParseError {
  case error {
    gsv.UnescapedQuote(line) ->
      QuotingError(row: line, reason: "Unescaped quote")

    gsv.MissingClosingQuote(starting_line) ->
      QuotingError(row: starting_line, reason: "Missing closing quote")
  }
}

/// Parse data rows into row dictionaries
fn parse_data_rows(
  rows: List(List(String)),
  headers: List(String),
  row_num: Int,
  acc: List(CsvRow),
) -> Result(List(CsvRow), ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [fields, ..rest] -> {
      let header_count = list.length(headers)
      let field_count = list.length(fields)

      case field_count == header_count {
        True -> {
          let row = create_row(headers, fields, dict.new())
          parse_data_rows(rest, headers, row_num + 1, [row, ..acc])
        }
        False -> {
          Error(FieldCountMismatch(
            row: row_num,
            expected: header_count,
            got: field_count,
          ))
        }
      }
    }
  }
}

/// Create a row dictionary from headers and field values
fn create_row(
  headers: List(String),
  fields: List(String),
  acc: CsvRow,
) -> CsvRow {
  case headers, fields {
    [h, ..hs], [f, ..fs] -> create_row(hs, fs, dict.insert(acc, h, f))
    _, _ -> acc
  }
}

// =============================================================================
// Value Parsers
// =============================================================================

/// Parse an integer value
pub fn parse_int(value: String) -> Result(Int, String) {
  case int.parse(value) {
    Ok(n) -> Ok(n)
    Error(_) -> Error("integer")
  }
}

/// Parse a non-negative integer
pub fn parse_non_negative_int(value: String) -> Result(Int, String) {
  case int.parse(value) {
    Ok(n) if n >= 0 -> Ok(n)
    Ok(_) -> Error("non-negative integer")
    Error(_) -> Error("non-negative integer")
  }
}

/// Parse a positive integer
pub fn parse_positive_int(value: String) -> Result(Int, String) {
  case int.parse(value) {
    Ok(n) if n > 0 -> Ok(n)
    Ok(_) -> Error("positive integer")
    Error(_) -> Error("positive integer")
  }
}

/// Parse a float value
pub fn parse_float(value: String) -> Result(Float, String) {
  case float.parse(value) {
    Ok(f) -> Ok(f)
    Error(_) -> {
      // Try parsing as int and convert
      case int.parse(value) {
        Ok(n) -> Ok(int.to_float(n))
        Error(_) -> Error("float")
      }
    }
  }
}

/// Parse a non-negative float
pub fn parse_non_negative_float(value: String) -> Result(Float, String) {
  case parse_float(value) {
    Ok(f) if f >=. 0.0 -> Ok(f)
    Ok(_) -> Error("non-negative float")
    Error(e) -> Error(e)
  }
}

/// Parse a boolean (0 = false, 1 = true)
pub fn parse_bool(value: String) -> Result(Bool, String) {
  case value {
    "0" -> Ok(False)
    "1" -> Ok(True)
    _ -> Error("boolean (0 or 1)")
  }
}

/// Parse an enum value with a mapping function
pub fn parse_enum(
  value: String,
  parser: fn(String) -> Result(a, Nil),
) -> Result(a, String) {
  case parser(value) {
    Ok(v) -> Ok(v)
    Error(_) -> Error("valid enum value")
  }
}
