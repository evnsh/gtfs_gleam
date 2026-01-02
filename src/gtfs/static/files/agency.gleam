//// Parser for agency.txt
////
//// agency.txt - Transit agencies with service represented in this dataset.
//// Source: GTFS reference.md - Dataset Files > agency.txt

import gleam/list
import gleam/option
import gleam/result
import gtfs/common/types as common
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type Agency, type CemvSupport, Agency, CemvNotSupported, CemvSupported,
  NoCemvInfo,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse agency.txt CSV content into a list of Agency records
pub fn parse(content: String) -> Result(List(Agency), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Agency),
) -> Result(List(Agency), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use agency <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [agency, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Agency, csv.ParseError) {
  // Required fields
  use agency_name <- result.try(csv.get_required(row, "agency_name", row_num))
  use agency_url_str <- result.try(csv.get_required(row, "agency_url", row_num))
  use agency_timezone_str <- result.try(csv.get_required(
    row,
    "agency_timezone",
    row_num,
  ))

  // Optional fields
  let agency_id = csv.get_optional(row, "agency_id")
  let agency_lang =
    csv.get_optional(row, "agency_lang") |> option.map(common.LanguageCode)
  let agency_phone =
    csv.get_optional(row, "agency_phone") |> option.map(common.PhoneNumber)
  let agency_fare_url =
    csv.get_optional(row, "agency_fare_url") |> option.map(common.Url)
  let agency_email =
    csv.get_optional(row, "agency_email") |> option.map(common.Email)

  // Parse cemv_support with default
  let cemv_support =
    csv.get_with_default(row, "cemv_support", NoCemvInfo, parse_cemv_support)

  Ok(Agency(
    agency_id: agency_id,
    agency_name: agency_name,
    agency_url: common.Url(agency_url_str),
    agency_timezone: common.Timezone(agency_timezone_str),
    agency_lang: agency_lang,
    agency_phone: agency_phone,
    agency_fare_url: agency_fare_url,
    agency_email: agency_email,
    cemv_support: cemv_support,
  ))
}

// =============================================================================
// Enum Parsers
// =============================================================================

fn parse_cemv_support(value: String) -> Result(CemvSupport, String) {
  case value {
    "" | "0" -> Ok(NoCemvInfo)
    "1" -> Ok(CemvSupported)
    "2" -> Ok(CemvNotSupported)
    _ -> Error("cemv_support (0-2)")
  }
}
