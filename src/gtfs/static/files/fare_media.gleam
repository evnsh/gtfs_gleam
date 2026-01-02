//// Parser for fare_media.txt
////
//// fare_media.txt - Fare media that can be used to pay for fares.
//// Source: GTFS reference.md - Dataset Files > fare_media.txt

import gleam/list
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type FareMedia, type FareMediaType, Cemv, FareMedia, MobileApp, NoFareMedia,
  PaperTicket, TransitCard,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse fare_media.txt CSV content into a list of FareMedia records
pub fn parse(content: String) -> Result(List(FareMedia), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(FareMedia),
) -> Result(List(FareMedia), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use fare_media <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [fare_media, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(FareMedia, csv.ParseError) {
  // Required fields
  use fare_media_id <- result.try(csv.get_required(
    row,
    "fare_media_id",
    row_num,
  ))
  use fare_media_type <- result.try(csv.get_required_parsed(
    row,
    "fare_media_type",
    row_num,
    parse_fare_media_type,
  ))

  // Optional fields
  let fare_media_name = csv.get_optional(row, "fare_media_name")

  Ok(FareMedia(
    fare_media_id: fare_media_id,
    fare_media_name: fare_media_name,
    fare_media_type: fare_media_type,
  ))
}

fn parse_fare_media_type(s: String) -> Result(FareMediaType, String) {
  case s {
    "0" -> Ok(NoFareMedia)
    "1" -> Ok(PaperTicket)
    "2" -> Ok(TransitCard)
    "3" -> Ok(Cemv)
    "4" -> Ok(MobileApp)
    _ -> Error("Invalid fare_media_type value: " <> s)
  }
}
