//// Validation Tests
////
//// Tests for the GTFS static feed validation logic.

import gleam/option.{None, Some}
import gleam/set
import gleeunit/should
import gtfs/common/types as common_types
import gtfs/static/types
import gtfs/static/validation.{
  DuplicatePrimaryKey, InvalidForeignKey, InvalidTimeSequence,
  MissingConditionalFile, MissingRequiredFile,
}

// =============================================================================
// Required Files Tests
// =============================================================================

pub fn validate_required_files_test() {
  // All present
  validation.validate_required_files(
    True,
    True,
    True,
    True,
    True,
    True,
    False,
    False,
  )
  |> should.equal([])

  // Missing agency
  validation.validate_required_files(
    False,
    True,
    True,
    True,
    True,
    True,
    False,
    False,
  )
  |> should.equal([MissingRequiredFile("agency.txt")])
}

pub fn validate_conditional_stops_test() {
  // Missing both stops.txt and locations.geojson
  validation.validate_required_files(
    True,
    False,
    True,
    True,
    True,
    True,
    False,
    False,
  )
  |> list_contains_error(MissingConditionalFile(
    "stops.txt",
    "Either stops.txt or locations.geojson must be present",
  ))
  |> should.be_true

  // Has locations.geojson only (valid)
  validation.validate_required_files(
    True,
    False,
    True,
    True,
    True,
    True,
    False,
    True,
  )
  |> should.equal([])
}

// =============================================================================
// ID Uniqueness Tests
// =============================================================================

pub fn validate_route_ids_test() {
  let r1 = create_route("R1")
  let r2 = create_route("R2")
  let r3 = create_route("R1")
  // Duplicate

  let #(_, errors) = validation.validate_route_ids([r1, r2, r3])

  errors
  |> list_contains_error(DuplicatePrimaryKey("routes.txt", "route_id", "R1", 4))
  |> should.be_true
}

// =============================================================================
// Foreign Key Tests
// =============================================================================

pub fn validate_route_agency_refs_test() {
  let r1 = create_route("R1") |> set_agency("A1")
  let r2 = create_route("R2") |> set_agency("A2")
  // A2 does not exist

  let agency_ids = set.from_list(["A1"])

  let errors =
    validation.validate_route_agency_refs([r1, r2], agency_ids, False)

  errors
  |> list_contains_error(InvalidForeignKey(
    "routes.txt",
    "agency_id",
    "A2",
    "agency.txt",
    3,
  ))
  |> should.be_true
}

// =============================================================================
// Time Sequence Tests
// =============================================================================

pub fn validate_time_sequence_test() {
  let t1 = common_types.Time(8, 0, 0)
  let t2 = common_types.Time(8, 30, 0)
  let t3 = common_types.Time(8, 15, 0)
  // Backwards in time

  let st1 = create_stop_time("T1", 1, t1, t1)
  let st2 = create_stop_time("T1", 2, t2, t2)
  let st3 = create_stop_time("T1", 3, t3, t3)
  // Invalid

  let errors = validation.validate_stop_time_sequences([st1, st2, st3])

  // Should fail between st2 (8:30) and st3 (8:15)
  // Logic: Dep(st2) > Arr(st3) -> 8:30 > 8:15 -> Error
  list_contains_string(
    errors,
    "Departure time at sequence 2 is after arrival time at sequence 3",
  )
  |> should.be_true
}

// =============================================================================
// Helpers
// =============================================================================

fn list_contains_error(
  errors: List(validation.ValidationError),
  target: validation.ValidationError,
) -> Bool {
  case errors {
    [] -> False
    [e, ..rest] ->
      case e == target {
        True -> True
        False -> list_contains_error(rest, target)
      }
  }
}

fn list_contains_string(
  errors: List(validation.ValidationError),
  match: String,
) -> Bool {
  case errors {
    [] -> False
    [InvalidTimeSequence(_, _, reason), ..rest] -> {
      case reason == match {
        True -> True
        False -> list_contains_string(rest, match)
      }
    }
    [_, ..rest] -> list_contains_string(rest, match)
  }
}

fn create_route(id: String) -> types.Route {
  types.Route(
    route_id: id,
    agency_id: None,
    route_short_name: None,
    route_long_name: None,
    route_desc: None,
    route_type: types.Bus,
    route_url: None,
    route_color: None,
    route_text_color: None,
    route_sort_order: None,
    continuous_pickup: types.NoContinuousStoppingPickup,
    continuous_drop_off: types.NoContinuousStoppingDropOff,
    network_id: None,
  )
}

fn set_agency(route: types.Route, agency_id: String) -> types.Route {
  types.Route(..route, agency_id: Some(agency_id))
}

fn create_stop_time(
  trip_id: String,
  seq: Int,
  arr: common_types.Time,
  dep: common_types.Time,
) -> types.StopTime {
  types.StopTime(
    trip_id: trip_id,
    arrival_time: Some(arr),
    departure_time: Some(dep),
    stop_id: None,
    stop_sequence: seq,
    stop_headsign: None,
    pickup_type: types.RegularPickup,
    drop_off_type: types.RegularDropOff,
    continuous_pickup: types.NoContinuousStoppingPickup,
    continuous_drop_off: types.NoContinuousStoppingDropOff,
    shape_dist_traveled: None,
    timepoint: types.Exact,
    pickup_booking_rule_id: None,
    drop_off_booking_rule_id: None,
    start_pickup_drop_off_window: None,
    end_pickup_drop_off_window: None,
    location_group_id: None,
    location_id: None,
  )
}
