//// Parser for stops.txt
////
//// stops.txt - Stops where vehicles pick up or drop off riders.
//// Also defines stations, entrances, and other location types.
//// Source: GTFS reference.md - Dataset Files > stops.txt

import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gtfs/common/types as common
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type LocationType, type Stop, type StopAccess, type WheelchairBoarding,
  BoardingArea, DirectStreetAccess, EntranceExit, GenericNode, MustUsePathways,
  NoWheelchairInfo, NotWheelchairAccessible, Station, Stop, StopOrPlatform,
  WheelchairAccessible,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse stops.txt CSV content into a list of Stop records
pub fn parse(content: String) -> Result(List(Stop), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Stop),
) -> Result(List(Stop), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use stop <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [stop, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Stop, csv.ParseError) {
  // Required field
  use stop_id <- result.try(csv.get_required(row, "stop_id", row_num))

  // Optional/conditionally required fields
  let stop_code = csv.get_optional(row, "stop_code")
  let stop_name = csv.get_optional(row, "stop_name")
  let tts_stop_name = csv.get_optional(row, "tts_stop_name")
  let stop_desc = csv.get_optional(row, "stop_desc")

  // Parse coordinates
  use stop_lat <- result.try(csv.get_parsed(
    row,
    "stop_lat",
    row_num,
    csv.parse_float,
  ))
  use stop_lon <- result.try(csv.get_parsed(
    row,
    "stop_lon",
    row_num,
    csv.parse_float,
  ))

  let zone_id = csv.get_optional(row, "zone_id")
  let stop_url = csv.get_optional(row, "stop_url") |> option.map(common.Url)

  // Parse location_type with default
  let location_type =
    csv.get_with_default(
      row,
      "location_type",
      StopOrPlatform,
      parse_location_type,
    )

  let parent_station = csv.get_optional(row, "parent_station")
  let stop_timezone =
    csv.get_optional(row, "stop_timezone") |> option.map(common.Timezone)

  // Parse wheelchair_boarding with default
  let wheelchair_boarding =
    csv.get_with_default(
      row,
      "wheelchair_boarding",
      NoWheelchairInfo,
      parse_wheelchair_boarding,
    )

  let level_id = csv.get_optional(row, "level_id")
  let platform_code = csv.get_optional(row, "platform_code")

  // Parse stop_access (conditionally forbidden for some location types)
  let stop_access = case csv.get_optional(row, "stop_access") {
    Some(val) ->
      case parse_stop_access(val) {
        Ok(access) -> Some(access)
        Error(_) -> None
      }
    None -> None
  }

  Ok(Stop(
    stop_id: stop_id,
    stop_code: stop_code,
    stop_name: stop_name,
    tts_stop_name: tts_stop_name,
    stop_desc: stop_desc,
    stop_lat: stop_lat,
    stop_lon: stop_lon,
    zone_id: zone_id,
    stop_url: stop_url,
    location_type: location_type,
    parent_station: parent_station,
    stop_timezone: stop_timezone,
    wheelchair_boarding: wheelchair_boarding,
    level_id: level_id,
    platform_code: platform_code,
    stop_access: stop_access,
  ))
}

// =============================================================================
// Enum Parsers
// =============================================================================

fn parse_location_type(value: String) -> Result(LocationType, String) {
  case value {
    "" | "0" -> Ok(StopOrPlatform)
    "1" -> Ok(Station)
    "2" -> Ok(EntranceExit)
    "3" -> Ok(GenericNode)
    "4" -> Ok(BoardingArea)
    _ -> Error("location_type (0-4)")
  }
}

fn parse_wheelchair_boarding(
  value: String,
) -> Result(WheelchairBoarding, String) {
  case value {
    "" | "0" -> Ok(NoWheelchairInfo)
    "1" -> Ok(WheelchairAccessible)
    "2" -> Ok(NotWheelchairAccessible)
    _ -> Error("wheelchair_boarding (0-2)")
  }
}

fn parse_stop_access(value: String) -> Result(StopAccess, String) {
  case value {
    "0" -> Ok(MustUsePathways)
    "1" -> Ok(DirectStreetAccess)
    _ -> Error("stop_access (0-1)")
  }
}
