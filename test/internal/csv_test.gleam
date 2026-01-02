//// CSV Parser Tests
////
//// Comprehensive tests for RFC 4180 compliant CSV parsing

import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import gtfs/internal/csv

// =============================================================================
// Basic Parsing Tests
// =============================================================================

pub fn parse_simple_csv_test() {
  let content =
    "name,age,city
John,30,NYC
Jane,25,LA"

  let assert Ok(rows) = csv.parse(content)
  list.length(rows) |> should.equal(2)

  let assert Ok(first) = list.first(rows)
  dict.get(first, "name") |> should.equal(Ok("John"))
  dict.get(first, "age") |> should.equal(Ok("30"))
  dict.get(first, "city") |> should.equal(Ok("NYC"))
}

pub fn parse_empty_file_test() {
  let content = ""
  csv.parse(content) |> should.equal(Error(csv.EmptyFile))
}

pub fn parse_header_only_test() {
  let content = "name,age,city"
  let assert Ok(rows) = csv.parse(content)
  list.length(rows) |> should.equal(0)
}

// =============================================================================
// RFC 4180 Quoting Tests
// =============================================================================

pub fn parse_quoted_fields_test() {
  let content =
    "name,description
\"Smith, John\",\"A person\""

  let assert Ok(rows) = csv.parse(content)
  let assert Ok(first) = list.first(rows)
  dict.get(first, "name") |> should.equal(Ok("Smith, John"))
}

pub fn parse_escaped_quotes_test() {
  let content =
    "name,quote
John,\"He said \"\"hello\"\"\""

  let assert Ok(rows) = csv.parse(content)
  let assert Ok(first) = list.first(rows)
  dict.get(first, "quote") |> should.equal(Ok("He said \"hello\""))
}

pub fn parse_newline_in_quotes_test() {
  let content =
    "name,address
John,\"123 Main St
Apt 4\""

  let assert Ok(rows) = csv.parse(content)
  let assert Ok(first) = list.first(rows)
  dict.get(first, "address") |> should.equal(Ok("123 Main St\nApt 4"))
}

pub fn parse_empty_quoted_field_test() {
  let content =
    "name,value
John,\"\""

  let assert Ok(rows) = csv.parse(content)
  let assert Ok(first) = list.first(rows)
  dict.get(first, "value") |> should.equal(Ok(""))
}

// =============================================================================
// Line Ending Tests
// =============================================================================

pub fn parse_crlf_line_endings_test() {
  let content = "name,age\r\nJohn,30\r\nJane,25"

  let assert Ok(rows) = csv.parse(content)
  list.length(rows) |> should.equal(2)
}

pub fn parse_lf_line_endings_test() {
  let content = "name,age\nJohn,30\nJane,25"

  let assert Ok(rows) = csv.parse(content)
  list.length(rows) |> should.equal(2)
}

pub fn parse_cr_line_endings_test() {
  let content = "name,age\rJohn,30\rJane,25"

  let assert Ok(rows) = csv.parse(content)
  list.length(rows) |> should.equal(2)
}

// =============================================================================
// UTF-8 BOM Tests
// =============================================================================

pub fn parse_with_utf8_bom_test() {
  // UTF-8 BOM: EF BB BF
  let content = "\u{FEFF}name,age\nJohn,30"

  let assert Ok(rows) = csv.parse(content)
  let assert Ok(first) = list.first(rows)
  // BOM should be stripped, first header is "name" not "\uFEFFname"
  dict.get(first, "name") |> should.equal(Ok("John"))
}

// =============================================================================
// Empty Field Tests
// =============================================================================

pub fn parse_empty_fields_test() {
  let content =
    "a,b,c
1,,3
,2,"

  let assert Ok(rows) = csv.parse(content)
  list.length(rows) |> should.equal(2)

  let assert Ok(first) = list.first(rows)
  dict.get(first, "a") |> should.equal(Ok("1"))
  dict.get(first, "b") |> should.equal(Ok(""))
  dict.get(first, "c") |> should.equal(Ok("3"))
}

pub fn parse_trailing_comma_test() {
  // Trailing commas create an extra empty field, which causes field count mismatch
  let content =
    "a,b,c
1,2,3,"

  // Parser should reject this as a field count mismatch (4 fields in row vs 3 in header)
  let result = csv.parse(content)
  case result {
    Error(csv.FieldCountMismatch(_, _, _)) -> should.be_true(True)
    _ -> should.fail()
  }
}

// =============================================================================
// Field Access Helper Tests
// =============================================================================

pub fn get_required_field_test() {
  let row = dict.from_list([#("name", "John"), #("age", "30")])

  csv.get_required(row, "name", 1) |> should.equal(Ok("John"))
}

pub fn get_required_missing_field_test() {
  let row = dict.from_list([#("name", "John")])

  csv.get_required(row, "missing", 1)
  |> should.equal(Error(csv.MissingRequiredField(field: "missing", row: 1)))
}

pub fn get_required_empty_field_test() {
  let row = dict.from_list([#("name", "")])

  csv.get_required(row, "name", 1)
  |> should.equal(Error(csv.MissingRequiredField(field: "name", row: 1)))
}

pub fn get_optional_field_test() {
  let row = dict.from_list([#("name", "John"), #("age", "")])

  csv.get_optional(row, "name") |> should.equal(Some("John"))
  csv.get_optional(row, "age") |> should.equal(None)
  csv.get_optional(row, "missing") |> should.equal(None)
}

// =============================================================================
// GTFS-specific Field Tests
// =============================================================================

pub fn parse_gtfs_agency_format_test() {
  let content =
    "agency_id,agency_name,agency_url,agency_timezone
1,Test Transit,https://example.com,America/New_York"

  let assert Ok(rows) = csv.parse(content)
  let assert Ok(first) = list.first(rows)

  dict.get(first, "agency_id") |> should.equal(Ok("1"))
  dict.get(first, "agency_name") |> should.equal(Ok("Test Transit"))
  dict.get(first, "agency_url") |> should.equal(Ok("https://example.com"))
  dict.get(first, "agency_timezone") |> should.equal(Ok("America/New_York"))
}

pub fn parse_gtfs_stops_format_test() {
  let content =
    "stop_id,stop_name,stop_lat,stop_lon
S1,\"Main St Station\",40.7128,-74.0060"

  let assert Ok(rows) = csv.parse(content)
  let assert Ok(first) = list.first(rows)

  dict.get(first, "stop_id") |> should.equal(Ok("S1"))
  dict.get(first, "stop_name") |> should.equal(Ok("Main St Station"))
  dict.get(first, "stop_lat") |> should.equal(Ok("40.7128"))
  dict.get(first, "stop_lon") |> should.equal(Ok("-74.0060"))
}

// =============================================================================
// Raw Parsing Tests
// =============================================================================

pub fn parse_raw_csv_test() {
  let content =
    "a,b,c
1,2,3
4,5,6"

  let assert Ok(rows) = csv.parse_raw(content)
  list.length(rows) |> should.equal(3)

  let assert Ok(first) = list.first(rows)
  first |> should.equal(["a", "b", "c"])
}

// =============================================================================
// Whitespace Handling Tests
// =============================================================================

pub fn parse_preserves_whitespace_in_fields_test() {
  let content =
    "name,value
\" spaces \",\"  trimmed  \""

  let assert Ok(rows) = csv.parse(content)
  let assert Ok(first) = list.first(rows)

  dict.get(first, "name") |> should.equal(Ok(" spaces "))
  dict.get(first, "value") |> should.equal(Ok("  trimmed  "))
}

// =============================================================================
// Unicode Tests
// =============================================================================

pub fn parse_unicode_content_test() {
  let content =
    "name,city
田中,東京
Müller,München"

  let assert Ok(rows) = csv.parse(content)
  list.length(rows) |> should.equal(2)

  let assert Ok(first) = list.first(rows)
  dict.get(first, "name") |> should.equal(Ok("田中"))
  dict.get(first, "city") |> should.equal(Ok("東京"))
}
