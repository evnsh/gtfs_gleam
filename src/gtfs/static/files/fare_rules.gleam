//// Parser for fare_rules.txt
////
//// fare_rules.txt - Rules to apply fares for itineraries.
//// Source: GTFS reference.md - Dataset Files > fare_rules.txt

import gleam/list
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type FareRule, FareRule}

// =============================================================================
// Parsing
// =============================================================================

/// Parse fare_rules.txt CSV content into a list of FareRule records
pub fn parse(content: String) -> Result(List(FareRule), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(FareRule),
) -> Result(List(FareRule), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use rule <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [rule, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(FareRule, csv.ParseError) {
  // Required fields
  use fare_id <- result.try(csv.get_required(row, "fare_id", row_num))

  // Optional fields
  let route_id = csv.get_optional(row, "route_id")
  let origin_id = csv.get_optional(row, "origin_id")
  let destination_id = csv.get_optional(row, "destination_id")
  let contains_id = csv.get_optional(row, "contains_id")

  Ok(FareRule(
    fare_id: fare_id,
    route_id: route_id,
    origin_id: origin_id,
    destination_id: destination_id,
    contains_id: contains_id,
  ))
}
