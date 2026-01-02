//// Parser for location_group_stops.txt
////
//// location_group_stops.txt - Assigns stops to location groups.
//// Source: GTFS reference.md - Dataset Files > location_group_stops.txt

import gleam/list
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type LocationGroupStop, LocationGroupStop}

// =============================================================================
// Parsing
// =============================================================================

/// Parse location_group_stops.txt CSV content into a list of LocationGroupStop records
pub fn parse(content: String) -> Result(List(LocationGroupStop), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(LocationGroupStop),
) -> Result(List(LocationGroupStop), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use lgs <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [lgs, ..acc])
    }
  }
}

fn parse_row(
  row: CsvRow,
  row_num: Int,
) -> Result(LocationGroupStop, csv.ParseError) {
  // Required fields
  use location_group_id <- result.try(csv.get_required(
    row,
    "location_group_id",
    row_num,
  ))
  use stop_id <- result.try(csv.get_required(row, "stop_id", row_num))

  Ok(LocationGroupStop(location_group_id: location_group_id, stop_id: stop_id))
}
