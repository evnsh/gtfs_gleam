//// Parser for attributions.txt
////
//// attributions.txt - Dataset attributions.
//// Source: GTFS reference.md - Dataset Files > attributions.txt

import gleam/list
import gleam/option
import gleam/result
import gtfs/common/types as common
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type Attribution, Attribution}

// =============================================================================
// Parsing
// =============================================================================

/// Parse attributions.txt CSV content into a list of Attribution records
pub fn parse(content: String) -> Result(List(Attribution), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Attribution),
) -> Result(List(Attribution), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use attribution <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [attribution, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Attribution, csv.ParseError) {
  // Required field
  use organization_name <- result.try(csv.get_required(
    row,
    "organization_name",
    row_num,
  ))

  // Optional fields
  let attribution_id = csv.get_optional(row, "attribution_id")
  let agency_id = csv.get_optional(row, "agency_id")
  let route_id = csv.get_optional(row, "route_id")
  let trip_id = csv.get_optional(row, "trip_id")
  let is_producer = parse_optional_bool(row, "is_producer", False)
  let is_operator = parse_optional_bool(row, "is_operator", False)
  let is_authority = parse_optional_bool(row, "is_authority", False)
  let attribution_url =
    csv.get_optional(row, "attribution_url") |> option.map(common.Url)
  let attribution_email =
    csv.get_optional(row, "attribution_email") |> option.map(common.Email)
  let attribution_phone =
    csv.get_optional(row, "attribution_phone") |> option.map(common.PhoneNumber)

  Ok(Attribution(
    attribution_id: attribution_id,
    agency_id: agency_id,
    route_id: route_id,
    trip_id: trip_id,
    organization_name: organization_name,
    is_producer: is_producer,
    is_operator: is_operator,
    is_authority: is_authority,
    attribution_url: attribution_url,
    attribution_email: attribution_email,
    attribution_phone: attribution_phone,
  ))
}

fn parse_optional_bool(row: CsvRow, field: String, default: Bool) -> Bool {
  case csv.get_optional(row, field) {
    option.None -> default
    option.Some("") -> default
    option.Some("0") -> False
    option.Some("1") -> True
    option.Some(_) -> default
  }
}
