//// Parser for transfers.txt
////
//// transfers.txt - Rules for making connections at transfer points between routes.
//// Source: GTFS reference.md - Dataset Files > transfers.txt

import gleam/list
import gleam/option
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type Transfer, type TransferType, InSeatTransfer, MinimumTimeTransfer,
  NoTransfer, ReBoardTransfer, RecommendedTransfer, TimedTransfer, Transfer,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse transfers.txt CSV content into a list of Transfer records
pub fn parse(content: String) -> Result(List(Transfer), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Transfer),
) -> Result(List(Transfer), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use transfer <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [transfer, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Transfer, csv.ParseError) {
  // Transfer type is required
  use transfer_type <- result.try(csv.get_required_parsed(
    row,
    "transfer_type",
    row_num,
    parse_transfer_type,
  ))

  // Conditionally required/optional fields
  let from_stop_id = csv.get_optional(row, "from_stop_id")
  let to_stop_id = csv.get_optional(row, "to_stop_id")
  let from_route_id = csv.get_optional(row, "from_route_id")
  let to_route_id = csv.get_optional(row, "to_route_id")
  let from_trip_id = csv.get_optional(row, "from_trip_id")
  let to_trip_id = csv.get_optional(row, "to_trip_id")
  let min_transfer_time =
    csv.get_optional(row, "min_transfer_time")
    |> option.then(fn(s) {
      case csv.parse_int(s) {
        Ok(i) -> option.Some(i)
        Error(_) -> option.None
      }
    })

  Ok(Transfer(
    from_stop_id: from_stop_id,
    to_stop_id: to_stop_id,
    from_route_id: from_route_id,
    to_route_id: to_route_id,
    from_trip_id: from_trip_id,
    to_trip_id: to_trip_id,
    transfer_type: transfer_type,
    min_transfer_time: min_transfer_time,
  ))
}

fn parse_transfer_type(s: String) -> Result(TransferType, String) {
  case s {
    "" | "0" -> Ok(RecommendedTransfer)
    "1" -> Ok(TimedTransfer)
    "2" -> Ok(MinimumTimeTransfer)
    "3" -> Ok(NoTransfer)
    "4" -> Ok(InSeatTransfer)
    "5" -> Ok(ReBoardTransfer)
    _ -> Error("Invalid transfer_type value: " <> s)
  }
}
