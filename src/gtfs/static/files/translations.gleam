//// Parser for translations.txt
////
//// translations.txt - Translated information for GTFS entities.
//// Source: GTFS reference.md - Dataset Files > translations.txt

import gleam/list
import gleam/result
import gtfs/common/types as common
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type TableName, type Translation, AgencyTable, AttributionsTable,
  FeedInfoTable, LevelsTable, PathwaysTable, RoutesTable, StopTimesTable,
  StopsTable, Translation, TripsTable,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse translations.txt CSV content into a list of Translation records
pub fn parse(content: String) -> Result(List(Translation), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Translation),
) -> Result(List(Translation), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use translation <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [translation, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Translation, csv.ParseError) {
  // Required fields
  use table_name <- result.try(csv.get_required_parsed(
    row,
    "table_name",
    row_num,
    parse_table_name,
  ))
  use field_name <- result.try(csv.get_required(row, "field_name", row_num))
  use language <- result.try(csv.get_required(row, "language", row_num))
  use translation_text <- result.try(csv.get_required(
    row,
    "translation",
    row_num,
  ))

  // Conditionally required fields
  let record_id = csv.get_optional(row, "record_id")
  let record_sub_id = csv.get_optional(row, "record_sub_id")
  let field_value = csv.get_optional(row, "field_value")

  Ok(Translation(
    table_name: table_name,
    field_name: field_name,
    language: common.LanguageCode(language),
    translation: translation_text,
    record_id: record_id,
    record_sub_id: record_sub_id,
    field_value: field_value,
  ))
}

fn parse_table_name(s: String) -> Result(TableName, String) {
  case s {
    "agency" -> Ok(AgencyTable)
    "stops" -> Ok(StopsTable)
    "routes" -> Ok(RoutesTable)
    "trips" -> Ok(TripsTable)
    "stop_times" -> Ok(StopTimesTable)
    "pathways" -> Ok(PathwaysTable)
    "levels" -> Ok(LevelsTable)
    "feed_info" -> Ok(FeedInfoTable)
    "attributions" -> Ok(AttributionsTable)
    _ -> Error("Invalid table_name value: " <> s)
  }
}
