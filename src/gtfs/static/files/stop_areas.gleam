//// Parser for stop_areas.txt
////
//// stop_areas.txt - Rules to assign stops to areas.
//// Source: GTFS reference.md - Dataset Files > stop_areas.txt

import gleam/list
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type StopArea, StopArea}

// =============================================================================
// Parsing
// =============================================================================

/// Parse stop_areas.txt CSV content into a list of StopArea records
pub fn parse(content: String) -> Result(List(StopArea), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(StopArea),
) -> Result(List(StopArea), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use stop_area <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [stop_area, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(StopArea, csv.ParseError) {
  // Required fields
  use area_id <- result.try(csv.get_required(row, "area_id", row_num))
  use stop_id <- result.try(csv.get_required(row, "stop_id", row_num))

  Ok(StopArea(area_id: area_id, stop_id: stop_id))
}
