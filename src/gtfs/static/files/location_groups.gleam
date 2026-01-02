//// Parser for location_groups.txt
////
//// location_groups.txt - Defines groups of stops for flexible routing.
//// Source: GTFS reference.md - Dataset Files > location_groups.txt

import gleam/list
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type LocationGroup, LocationGroup}

// =============================================================================
// Parsing
// =============================================================================

/// Parse location_groups.txt CSV content into a list of LocationGroup records
pub fn parse(content: String) -> Result(List(LocationGroup), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(LocationGroup),
) -> Result(List(LocationGroup), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use location_group <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [location_group, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(LocationGroup, csv.ParseError) {
  // Required field
  use location_group_id <- result.try(csv.get_required(
    row,
    "location_group_id",
    row_num,
  ))

  // Optional fields
  let location_group_name = csv.get_optional(row, "location_group_name")

  Ok(LocationGroup(
    location_group_id: location_group_id,
    location_group_name: location_group_name,
  ))
}
