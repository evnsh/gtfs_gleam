//// Parser for levels.txt
////
//// levels.txt - Levels within a station.
//// Source: GTFS reference.md - Dataset Files > levels.txt

import gleam/list
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type Level, Level}

// =============================================================================
// Parsing
// =============================================================================

/// Parse levels.txt CSV content into a list of Level records
pub fn parse(content: String) -> Result(List(Level), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Level),
) -> Result(List(Level), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use level <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [level, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Level, csv.ParseError) {
  // Required fields
  use level_id <- result.try(csv.get_required(row, "level_id", row_num))
  use level_index <- result.try(csv.get_required_parsed(
    row,
    "level_index",
    row_num,
    csv.parse_float,
  ))

  // Optional fields
  let level_name = csv.get_optional(row, "level_name")

  Ok(Level(level_id: level_id, level_index: level_index, level_name: level_name))
}
