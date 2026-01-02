//// Parser for rider_categories.txt
////
//// rider_categories.txt - Defines categories of riders for fare calculations.
//// Source: GTFS reference.md - Dataset Files > rider_categories.txt (Fares v2)

import gleam/list
import gleam/option
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type RiderCategory, RiderCategory}

// =============================================================================
// Parsing
// =============================================================================

/// Parse rider_categories.txt CSV content into a list of RiderCategory records
pub fn parse(content: String) -> Result(List(RiderCategory), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(RiderCategory),
) -> Result(List(RiderCategory), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use category <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [category, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(RiderCategory, csv.ParseError) {
  // Required fields
  use rider_category_id <- result.try(csv.get_required(
    row,
    "rider_category_id",
    row_num,
  ))
  use rider_category_name <- result.try(csv.get_required(
    row,
    "rider_category_name",
    row_num,
  ))

  // Optional fields
  let min_age = csv.get_optional(row, "min_age")
  let max_age = csv.get_optional(row, "max_age")
  let eligibility_url = csv.get_optional(row, "eligibility_url")

  // Parse integer ages if present
  let min_age_int = case min_age {
    option.Some(val) ->
      case csv.parse_int(val) {
        Ok(i) -> option.Some(i)
        Error(_) -> option.None
      }
    option.None -> option.None
  }

  let max_age_int = case max_age {
    option.Some(val) ->
      case csv.parse_int(val) {
        Ok(i) -> option.Some(i)
        Error(_) -> option.None
      }
    option.None -> option.None
  }

  Ok(RiderCategory(
    rider_category_id: rider_category_id,
    rider_category_name: rider_category_name,
    min_age: min_age_int,
    max_age: max_age_int,
    eligibility_url: eligibility_url,
  ))
}
