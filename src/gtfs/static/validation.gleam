//// GTFS Static Feed Validation
////
//// Validates GTFS feeds for:
//// - Required files presence
//// - Required fields presence
//// - Foreign key relationships
//// - Semantic rules (time sequences, coordinates, etc.)

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/set.{type Set}
import gtfs/common/types as common_types
import gtfs/static/types.{
  type Agency, type Calendar, type Route, type Stop, type StopTime, type Trip,
}

// =============================================================================
// Error Types
// =============================================================================

/// Validation errors that can occur during feed validation
pub type ValidationError {
  /// Missing required file
  MissingRequiredFile(filename: String)

  /// Missing conditionally required file
  MissingConditionalFile(filename: String, condition: String)

  /// Missing required field in a record
  MissingRequiredField(file: String, field: String, record_id: String, row: Int)

  /// Invalid field value
  InvalidFieldValue(
    file: String,
    field: String,
    value: String,
    expected: String,
    row: Int,
  )

  /// Foreign key reference to non-existent record
  InvalidForeignKey(
    file: String,
    field: String,
    value: String,
    references: String,
    row: Int,
  )

  /// Duplicate primary key
  DuplicatePrimaryKey(file: String, key: String, value: String, row: Int)

  /// Invalid coordinate value
  InvalidCoordinate(
    file: String,
    record_id: String,
    lat: Float,
    lon: Float,
    reason: String,
  )

  /// Invalid time sequence
  InvalidTimeSequence(file: String, trip_id: String, reason: String)

  /// Circular reference detected
  CircularReference(file: String, field: String, value: String)

  /// Orphaned record (referenced by nothing)
  OrphanedRecord(file: String, record_id: String, expected_reference: String)

  /// Inconsistent agency timezones when single agency
  InconsistentTimezone(reason: String)
}

// =============================================================================
// Validation Context
// =============================================================================

/// Context for validation with collected IDs
pub type ValidationContext {
  ValidationContext(
    agency_ids: Set(String),
    stop_ids: Set(String),
    route_ids: Set(String),
    trip_ids: Set(String),
    service_ids: Set(String),
    shape_ids: Set(String),
    fare_ids: Set(String),
    level_ids: Set(String),
    area_ids: Set(String),
    network_ids: Set(String),
    zone_ids: Set(String),
    pathway_ids: Set(String),
  )
}

/// Create an empty validation context
pub fn new_context() -> ValidationContext {
  ValidationContext(
    agency_ids: set.new(),
    stop_ids: set.new(),
    route_ids: set.new(),
    trip_ids: set.new(),
    service_ids: set.new(),
    shape_ids: set.new(),
    fare_ids: set.new(),
    level_ids: set.new(),
    area_ids: set.new(),
    network_ids: set.new(),
    zone_ids: set.new(),
    pathway_ids: set.new(),
  )
}

// =============================================================================
// Required Files Validation
// =============================================================================

/// Check that required files are present
/// Required: agency.txt, routes.txt, trips.txt, stop_times.txt
/// Conditionally required: stops.txt OR locations.geojson, calendar.txt OR calendar_dates.txt
pub fn validate_required_files(
  has_agency: Bool,
  has_stops: Bool,
  has_routes: Bool,
  has_trips: Bool,
  has_stop_times: Bool,
  has_calendar: Bool,
  has_calendar_dates: Bool,
  has_locations_geojson: Bool,
) -> List(ValidationError) {
  let errors = []

  let errors = case has_agency {
    False -> [MissingRequiredFile("agency.txt"), ..errors]
    True -> errors
  }

  let errors = case has_routes {
    False -> [MissingRequiredFile("routes.txt"), ..errors]
    True -> errors
  }

  let errors = case has_trips {
    False -> [MissingRequiredFile("trips.txt"), ..errors]
    True -> errors
  }

  let errors = case has_stop_times {
    False -> [MissingRequiredFile("stop_times.txt"), ..errors]
    True -> errors
  }

  // stops.txt OR locations.geojson must be present
  let errors = case has_stops || has_locations_geojson {
    False -> [
      MissingConditionalFile(
        "stops.txt",
        "Either stops.txt or locations.geojson must be present",
      ),
      ..errors
    ]
    True -> errors
  }

  // calendar.txt OR calendar_dates.txt must be present
  let errors = case has_calendar || has_calendar_dates {
    False -> [
      MissingConditionalFile(
        "calendar.txt",
        "Either calendar.txt or calendar_dates.txt must be present",
      ),
      ..errors
    ]
    True -> errors
  }

  errors
}

// =============================================================================
// Primary Key Validation
// =============================================================================

/// Validate that agency_ids are unique (when present)
pub fn validate_agency_ids(
  agencies: List(Agency),
) -> #(Set(String), List(ValidationError)) {
  validate_unique_ids(agencies, "agency.txt", "agency_id", fn(a) {
    option.unwrap(a.agency_id, "")
  })
}

/// Validate that stop_ids are unique
pub fn validate_stop_ids(
  stops: List(Stop),
) -> #(Set(String), List(ValidationError)) {
  validate_unique_ids(stops, "stops.txt", "stop_id", fn(s) { s.stop_id })
}

/// Validate that route_ids are unique
pub fn validate_route_ids(
  routes: List(Route),
) -> #(Set(String), List(ValidationError)) {
  validate_unique_ids(routes, "routes.txt", "route_id", fn(r) { r.route_id })
}

/// Validate that trip_ids are unique
pub fn validate_trip_ids(
  trips: List(Trip),
) -> #(Set(String), List(ValidationError)) {
  validate_unique_ids(trips, "trips.txt", "trip_id", fn(t) { t.trip_id })
}

/// Validate that service_ids are unique
pub fn validate_service_ids_calendar(
  calendars: List(Calendar),
) -> #(Set(String), List(ValidationError)) {
  validate_unique_ids(calendars, "calendar.txt", "service_id", fn(c) {
    c.service_id
  })
}

fn validate_unique_ids(
  items: List(a),
  file: String,
  key_name: String,
  get_id: fn(a) -> String,
) -> #(Set(String), List(ValidationError)) {
  list.fold(items, #(set.new(), []), fn(acc, item) {
    let #(seen, errors) = acc
    let id = get_id(item)
    case id == "" {
      True -> acc
      False ->
        case set.contains(seen, id) {
          True -> #(seen, [
            DuplicatePrimaryKey(
              file: file,
              key: key_name,
              value: id,
              row: set.size(seen) + 2,
            ),
            ..errors
          ])
          False -> #(set.insert(seen, id), errors)
        }
    }
  })
}

// =============================================================================
// Foreign Key Validation
// =============================================================================

/// Validate routes reference valid agency_ids
pub fn validate_route_agency_refs(
  routes: List(Route),
  agency_ids: Set(String),
  single_agency: Bool,
) -> List(ValidationError) {
  list.index_fold(routes, [], fn(errors, route, idx) {
    case route.agency_id {
      None ->
        case single_agency {
          True -> errors
          False -> [
            MissingRequiredField(
              file: "routes.txt",
              field: "agency_id",
              record_id: route.route_id,
              row: idx + 2,
            ),
            ..errors
          ]
        }
      Some(aid) ->
        case set.contains(agency_ids, aid) {
          True -> errors
          False -> [
            InvalidForeignKey(
              file: "routes.txt",
              field: "agency_id",
              value: aid,
              references: "agency.txt",
              row: idx + 2,
            ),
            ..errors
          ]
        }
    }
  })
}

/// Validate trips reference valid route_ids and service_ids
pub fn validate_trip_refs(
  trips: List(Trip),
  route_ids: Set(String),
  service_ids: Set(String),
  shape_ids: Set(String),
) -> List(ValidationError) {
  list.index_fold(trips, [], fn(errors, trip, idx) {
    let errors = case set.contains(route_ids, trip.route_id) {
      True -> errors
      False -> [
        InvalidForeignKey(
          file: "trips.txt",
          field: "route_id",
          value: trip.route_id,
          references: "routes.txt",
          row: idx + 2,
        ),
        ..errors
      ]
    }

    let errors = case set.contains(service_ids, trip.service_id) {
      True -> errors
      False -> [
        InvalidForeignKey(
          file: "trips.txt",
          field: "service_id",
          value: trip.service_id,
          references: "calendar.txt/calendar_dates.txt",
          row: idx + 2,
        ),
        ..errors
      ]
    }

    case trip.shape_id {
      None -> errors
      Some(sid) ->
        case set.contains(shape_ids, sid) {
          True -> errors
          False -> [
            InvalidForeignKey(
              file: "trips.txt",
              field: "shape_id",
              value: sid,
              references: "shapes.txt",
              row: idx + 2,
            ),
            ..errors
          ]
        }
    }
  })
}

/// Validate stop_times reference valid trip_ids and stop_ids
pub fn validate_stop_time_refs(
  stop_times: List(StopTime),
  trip_ids: Set(String),
  stop_ids: Set(String),
) -> List(ValidationError) {
  list.index_fold(stop_times, [], fn(errors, st, idx) {
    let errors = case set.contains(trip_ids, st.trip_id) {
      True -> errors
      False -> [
        InvalidForeignKey(
          file: "stop_times.txt",
          field: "trip_id",
          value: st.trip_id,
          references: "trips.txt",
          row: idx + 2,
        ),
        ..errors
      ]
    }

    case st.stop_id {
      None -> errors
      Some(sid) ->
        case set.contains(stop_ids, sid) {
          True -> errors
          False -> [
            InvalidForeignKey(
              file: "stop_times.txt",
              field: "stop_id",
              value: sid,
              references: "stops.txt",
              row: idx + 2,
            ),
            ..errors
          ]
        }
    }
  })
}

// =============================================================================
// Coordinate Validation
// =============================================================================

/// Validate stop coordinates are within valid bounds
pub fn validate_stop_coordinates(stops: List(Stop)) -> List(ValidationError) {
  list.filter_map(stops, fn(stop) {
    case stop.stop_lat, stop.stop_lon {
      Some(lat), Some(lon) -> {
        case is_valid_coordinate(lat, lon) {
          True -> Error(Nil)
          False ->
            Ok(InvalidCoordinate(
              file: "stops.txt",
              record_id: stop.stop_id,
              lat: lat,
              lon: lon,
              reason: "Coordinates out of valid range (lat: -90 to 90, lon: -180 to 180)",
            ))
        }
      }
      _, _ -> Error(Nil)
    }
  })
}

fn is_valid_coordinate(lat: Float, lon: Float) -> Bool {
  lat >=. -90.0 && lat <=. 90.0 && lon >=. -180.0 && lon <=. 180.0
}

// =============================================================================
// Time Sequence Validation
// =============================================================================

/// Validate that stop times have increasing arrival/departure times
pub fn validate_stop_time_sequences(
  stop_times: List(StopTime),
) -> List(ValidationError) {
  // Group by trip_id
  let by_trip = group_by(stop_times, fn(st) { st.trip_id })

  dict.fold(by_trip, [], fn(errors, trip_id, times) {
    // Sort by stop_sequence
    let sorted =
      list.sort(times, fn(a, b) {
        int_compare(a.stop_sequence, b.stop_sequence)
      })

    // Check time progression
    validate_time_sequence(sorted, trip_id, errors)
  })
}

fn validate_time_sequence(
  stop_times: List(StopTime),
  trip_id: String,
  errors: List(ValidationError),
) -> List(ValidationError) {
  case stop_times {
    [] -> errors
    [_] -> errors
    [first, second, ..rest] -> {
      let new_errors = case first.departure_time, second.arrival_time {
        Some(dep), Some(arr) -> {
          let dep_secs = time_to_seconds(dep)
          let arr_secs = time_to_seconds(arr)
          case dep_secs > arr_secs {
            True -> [
              InvalidTimeSequence(
                file: "stop_times.txt",
                trip_id: trip_id,
                reason: "Departure time at sequence "
                  <> int_to_string(first.stop_sequence)
                  <> " is after arrival time at sequence "
                  <> int_to_string(second.stop_sequence),
              ),
              ..errors
            ]
            False -> errors
          }
        }
        _, _ -> errors
      }
      validate_time_sequence([second, ..rest], trip_id, new_errors)
    }
  }
}

fn time_to_seconds(time: common_types.Time) -> Int {
  let common_types.Time(h, m, s) = time
  h * 3600 + m * 60 + s
}

// =============================================================================
// Helper Functions
// =============================================================================

fn group_by(items: List(a), key_fn: fn(a) -> String) -> Dict(String, List(a)) {
  list.fold(items, dict.new(), fn(acc, item) {
    let key = key_fn(item)
    let current = dict.get(acc, key) |> option_unwrap_or([])
    dict.insert(acc, key, [item, ..current])
  })
}

fn option_unwrap_or(opt: Result(a, b), default: a) -> a {
  case opt {
    Ok(v) -> v
    Error(_) -> default
  }
}

fn int_compare(a: Int, b: Int) -> order.Order {
  case a < b {
    True -> order.Lt
    False ->
      case a > b {
        True -> order.Gt
        False -> order.Eq
      }
  }
}

import gleam/int
import gleam/order

fn int_to_string(i: Int) -> String {
  int.to_string(i)
}
