//// Parser for feed_info.txt
////
//// feed_info.txt - Dataset metadata, including publisher, version, and expiration information.
//// Source: GTFS reference.md - Dataset Files > feed_info.txt

import gleam/list
import gleam/option
import gleam/result
import gtfs/common/time
import gtfs/common/types as common
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type FeedInfo, FeedInfo}

// =============================================================================
// Parsing
// =============================================================================

/// Parse feed_info.txt CSV content into a FeedInfo record
/// Note: feed_info.txt should only have one row
pub fn parse(content: String) -> Result(option.Option(FeedInfo), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  case rows {
    [] -> Ok(option.None)
    [row, ..] -> {
      use info <- result.try(parse_row(row, 2))
      Ok(option.Some(info))
    }
  }
}

/// Parse multiple rows (returns list for consistency with other parsers)
pub fn parse_list(content: String) -> Result(List(FeedInfo), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(FeedInfo),
) -> Result(List(FeedInfo), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use info <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [info, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(FeedInfo, csv.ParseError) {
  // Required fields
  use feed_publisher_name <- result.try(csv.get_required(
    row,
    "feed_publisher_name",
    row_num,
  ))
  use feed_publisher_url <- result.try(csv.get_required(
    row,
    "feed_publisher_url",
    row_num,
  ))
  use feed_lang <- result.try(csv.get_required(row, "feed_lang", row_num))

  // Optional fields
  let default_lang =
    csv.get_optional(row, "default_lang") |> option.map(common.LanguageCode)
  let feed_start_date =
    csv.get_optional(row, "feed_start_date")
    |> option.then(fn(s) {
      case time.parse_date(s) {
        Ok(d) -> option.Some(d)
        Error(_) -> option.None
      }
    })
  let feed_end_date =
    csv.get_optional(row, "feed_end_date")
    |> option.then(fn(s) {
      case time.parse_date(s) {
        Ok(d) -> option.Some(d)
        Error(_) -> option.None
      }
    })
  let feed_version = csv.get_optional(row, "feed_version")
  let feed_contact_email =
    csv.get_optional(row, "feed_contact_email") |> option.map(common.Email)
  let feed_contact_url =
    csv.get_optional(row, "feed_contact_url") |> option.map(common.Url)

  Ok(FeedInfo(
    feed_publisher_name: feed_publisher_name,
    feed_publisher_url: common.Url(feed_publisher_url),
    feed_lang: common.LanguageCode(feed_lang),
    default_lang: default_lang,
    feed_start_date: feed_start_date,
    feed_end_date: feed_end_date,
    feed_version: feed_version,
    feed_contact_email: feed_contact_email,
    feed_contact_url: feed_contact_url,
  ))
}
