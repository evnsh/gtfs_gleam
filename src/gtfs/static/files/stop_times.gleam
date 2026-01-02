//// Parser for stop_times.txt
////
//// stop_times.txt - Times that a vehicle arrives at and departs
//// from stops for each trip.
//// Source: GTFS reference.md - Dataset Files > stop_times.txt

import gleam/list
import gleam/result
import gtfs/common/time
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type ContinuousDropOff, type ContinuousPickup, type DropOffType,
  type PickupType, type StopTime, type Timepoint, Approximate,
  ContinuousStoppingDropOff, ContinuousStoppingPickup,
  CoordinateWithDriverForDropOff, CoordinateWithDriverForPickup,
  DriverCoordinatedDropOff, DriverCoordinatedPickup, Exact,
  NoContinuousStoppingDropOff, NoContinuousStoppingPickup, NoDropOff, NoPickup,
  PhoneAgencyForDropOff, PhoneAgencyForPickup, PhoneForDropOff, PhoneForPickup,
  RegularDropOff, RegularPickup, StopTime,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse stop_times.txt CSV content into a list of StopTime records
pub fn parse(content: String) -> Result(List(StopTime), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(StopTime),
) -> Result(List(StopTime), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use stop_time <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [stop_time, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(StopTime, csv.ParseError) {
  // Required fields
  use trip_id <- result.try(csv.get_required(row, "trip_id", row_num))
  use stop_sequence <- result.try(csv.get_required_parsed(
    row,
    "stop_sequence",
    row_num,
    csv.parse_non_negative_int,
  ))

  // Parse times (can exceed 24:00:00)
  use arrival_time <- result.try(csv.get_parsed(
    row,
    "arrival_time",
    row_num,
    time.parse_time,
  ))
  use departure_time <- result.try(csv.get_parsed(
    row,
    "departure_time",
    row_num,
    time.parse_time,
  ))

  // Location fields (mutually exclusive in validation)
  let stop_id = csv.get_optional(row, "stop_id")
  let location_group_id = csv.get_optional(row, "location_group_id")
  let location_id = csv.get_optional(row, "location_id")

  let stop_headsign = csv.get_optional(row, "stop_headsign")

  // GTFS-Flex pickup/drop-off windows
  use start_pickup_drop_off_window <- result.try(csv.get_parsed(
    row,
    "start_pickup_drop_off_window",
    row_num,
    time.parse_time,
  ))
  use end_pickup_drop_off_window <- result.try(csv.get_parsed(
    row,
    "end_pickup_drop_off_window",
    row_num,
    time.parse_time,
  ))

  // Parse pickup/drop-off types with defaults
  let pickup_type =
    csv.get_with_default(row, "pickup_type", RegularPickup, parse_pickup_type)
  let drop_off_type =
    csv.get_with_default(
      row,
      "drop_off_type",
      RegularDropOff,
      parse_drop_off_type,
    )

  // Parse continuous pickup/drop-off
  let continuous_pickup =
    csv.get_with_default(
      row,
      "continuous_pickup",
      NoContinuousStoppingPickup,
      parse_continuous_pickup,
    )
  let continuous_drop_off =
    csv.get_with_default(
      row,
      "continuous_drop_off",
      NoContinuousStoppingDropOff,
      parse_continuous_drop_off,
    )

  // Parse shape_dist_traveled
  use shape_dist_traveled <- result.try(csv.get_parsed(
    row,
    "shape_dist_traveled",
    row_num,
    csv.parse_non_negative_float,
  ))

  // Parse timepoint with default
  let timepoint = csv.get_with_default(row, "timepoint", Exact, parse_timepoint)

  // GTFS-Flex booking rules
  let pickup_booking_rule_id = csv.get_optional(row, "pickup_booking_rule_id")
  let drop_off_booking_rule_id =
    csv.get_optional(row, "drop_off_booking_rule_id")

  Ok(StopTime(
    trip_id: trip_id,
    arrival_time: arrival_time,
    departure_time: departure_time,
    stop_id: stop_id,
    location_group_id: location_group_id,
    location_id: location_id,
    stop_sequence: stop_sequence,
    stop_headsign: stop_headsign,
    start_pickup_drop_off_window: start_pickup_drop_off_window,
    end_pickup_drop_off_window: end_pickup_drop_off_window,
    pickup_type: pickup_type,
    drop_off_type: drop_off_type,
    continuous_pickup: continuous_pickup,
    continuous_drop_off: continuous_drop_off,
    shape_dist_traveled: shape_dist_traveled,
    timepoint: timepoint,
    pickup_booking_rule_id: pickup_booking_rule_id,
    drop_off_booking_rule_id: drop_off_booking_rule_id,
  ))
}

// =============================================================================
// Enum Parsers
// =============================================================================

fn parse_pickup_type(value: String) -> Result(PickupType, String) {
  case value {
    "" | "0" -> Ok(RegularPickup)
    "1" -> Ok(NoPickup)
    "2" -> Ok(PhoneForPickup)
    "3" -> Ok(DriverCoordinatedPickup)
    _ -> Error("pickup_type (0-3)")
  }
}

fn parse_drop_off_type(value: String) -> Result(DropOffType, String) {
  case value {
    "" | "0" -> Ok(RegularDropOff)
    "1" -> Ok(NoDropOff)
    "2" -> Ok(PhoneForDropOff)
    "3" -> Ok(DriverCoordinatedDropOff)
    _ -> Error("drop_off_type (0-3)")
  }
}

fn parse_continuous_pickup(value: String) -> Result(ContinuousPickup, String) {
  case value {
    "0" -> Ok(ContinuousStoppingPickup)
    "" | "1" -> Ok(NoContinuousStoppingPickup)
    "2" -> Ok(PhoneAgencyForPickup)
    "3" -> Ok(CoordinateWithDriverForPickup)
    _ -> Error("continuous_pickup (0-3)")
  }
}

fn parse_continuous_drop_off(value: String) -> Result(ContinuousDropOff, String) {
  case value {
    "0" -> Ok(ContinuousStoppingDropOff)
    "" | "1" -> Ok(NoContinuousStoppingDropOff)
    "2" -> Ok(PhoneAgencyForDropOff)
    "3" -> Ok(CoordinateWithDriverForDropOff)
    _ -> Error("continuous_drop_off (0-3)")
  }
}

fn parse_timepoint(value: String) -> Result(Timepoint, String) {
  case value {
    "0" -> Ok(Approximate)
    "" | "1" -> Ok(Exact)
    _ -> Error("timepoint (0 or 1)")
  }
}
