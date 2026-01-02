//// Parser for areas.txt
////
//// areas.txt - Area identifiers.
//// Source: GTFS reference.md - Dataset Files > areas.txt

import gleam/list
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type Area, Area}

// =============================================================================
// Parsing
// =============================================================================

/// Parse areas.txt CSV content into a list of Area records
pub fn parse(content: String) -> Result(List(Area), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Area),
) -> Result(List(Area), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use area <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [area, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Area, csv.ParseError) {
  // Required field
  use area_id <- result.try(csv.get_required(row, "area_id", row_num))

  // Optional fields
  let area_name = csv.get_optional(row, "area_name")

  Ok(Area(area_id: area_id, area_name: area_name))
}
