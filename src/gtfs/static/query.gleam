//// GTFS Static Feed Query Utilities
////
//// Provides convenient query functions for accessing and filtering
//// GTFS feed data. These functions complement the basic getters
//// in the feed module with more advanced query capabilities.
////
//// # Example
////
//// ```gleam
//// import gtfs/static/feed
//// import gtfs/static/query
////
//// pub fn main() {
////   // Load a feed
////   let assert Ok(my_feed) = feed.load("path/to/gtfs.zip")
////
////   // Index the feed for fast lookups
////   let indexed = query.index_feed(my_feed)
////
////   // Fast O(1) lookup
////   let stop = query.get_stop(indexed, "STOP_123")
//// }
//// ```

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gtfs/common/types as common_types
import gtfs/static/feed.{type Feed}
import gtfs/static/types.{
  type Agency, type Calendar, type Route, type RouteType, type ShapePoint,
  type Stop, type StopTime, type Trip, ServiceAdded, ServiceRemoved,
}

/// Type alias for Date from common types
pub type Date =
  common_types.Date

// =============================================================================
// Index Types for Fast Lookup
// =============================================================================

/// Indexed feed for O(1) lookups by ID
pub type IndexedFeed {
  IndexedFeed(
    feed: Feed,
    stops_by_id: Dict(String, Stop),
    routes_by_id: Dict(String, Route),
    trips_by_id: Dict(String, Trip),
    agencies_by_id: Dict(String, Agency),
    stop_times_by_trip: Dict(String, List(StopTime)),
    stop_times_by_stop: Dict(String, List(StopTime)),
    trips_by_route: Dict(String, List(Trip)),
    shapes_by_id: Dict(String, List(ShapePoint)),
  )
}

/// Create an indexed feed for faster lookups
pub fn index_feed(feed: Feed) -> IndexedFeed {
  let stops_by_id =
    list.fold(feed.stops, dict.new(), fn(acc, stop) {
      dict.insert(acc, stop.stop_id, stop)
    })

  let routes_by_id =
    list.fold(feed.routes, dict.new(), fn(acc, route) {
      dict.insert(acc, route.route_id, route)
    })

  let trips_by_id =
    list.fold(feed.trips, dict.new(), fn(acc, trip) {
      dict.insert(acc, trip.trip_id, trip)
    })

  let agencies_by_id =
    list.fold(feed.agencies, dict.new(), fn(acc, agency) {
      case agency.agency_id {
        Some(id) -> dict.insert(acc, id, agency)
        None -> acc
      }
    })

  let stop_times_by_trip = list.group(feed.stop_times, fn(st) { st.trip_id })

  let stop_times_by_stop =
    list.fold(feed.stop_times, dict.new(), fn(acc, st) {
      case st.stop_id {
        Some(stop_id) -> {
          let existing =
            dict.get(acc, stop_id) |> option.from_result |> option.unwrap([])
          dict.insert(acc, stop_id, [st, ..existing])
        }
        None -> acc
      }
    })

  let trips_by_route = list.group(feed.trips, fn(t) { t.route_id })

  let shapes_by_id = case feed.shapes {
    Some(shapes) -> list.group(shapes, fn(s) { s.shape_id })
    None -> dict.new()
  }

  IndexedFeed(
    feed: feed,
    stops_by_id: stops_by_id,
    routes_by_id: routes_by_id,
    trips_by_id: trips_by_id,
    agencies_by_id: agencies_by_id,
    stop_times_by_trip: stop_times_by_trip,
    stop_times_by_stop: stop_times_by_stop,
    trips_by_route: trips_by_route,
    shapes_by_id: shapes_by_id,
  )
}

// =============================================================================
// Fast Indexed Lookups
// =============================================================================

/// Get a stop by ID using indexed lookup (O(1))
pub fn get_stop(indexed: IndexedFeed, stop_id: String) -> Option(Stop) {
  dict.get(indexed.stops_by_id, stop_id) |> option.from_result
}

/// Get a route by ID using indexed lookup (O(1))
pub fn get_route(indexed: IndexedFeed, route_id: String) -> Option(Route) {
  dict.get(indexed.routes_by_id, route_id) |> option.from_result
}

/// Get a trip by ID using indexed lookup (O(1))
pub fn get_trip(indexed: IndexedFeed, trip_id: String) -> Option(Trip) {
  dict.get(indexed.trips_by_id, trip_id) |> option.from_result
}

/// Get an agency by ID using indexed lookup (O(1))
pub fn get_agency(indexed: IndexedFeed, agency_id: String) -> Option(Agency) {
  dict.get(indexed.agencies_by_id, agency_id) |> option.from_result
}

/// Get all stop times for a trip using indexed lookup (O(1))
pub fn get_stop_times_for_trip(
  indexed: IndexedFeed,
  trip_id: String,
) -> List(StopTime) {
  dict.get(indexed.stop_times_by_trip, trip_id)
  |> option.from_result
  |> option.unwrap([])
  |> list.sort(fn(a, b) { int.compare(a.stop_sequence, b.stop_sequence) })
}

/// Get all stop times at a stop using indexed lookup (O(1))
pub fn get_stop_times_at_stop(
  indexed: IndexedFeed,
  stop_id: String,
) -> List(StopTime) {
  dict.get(indexed.stop_times_by_stop, stop_id)
  |> option.from_result
  |> option.unwrap([])
}

/// Get all trips on a route using indexed lookup (O(1))
pub fn get_trips_on_route(indexed: IndexedFeed, route_id: String) -> List(Trip) {
  dict.get(indexed.trips_by_route, route_id)
  |> option.from_result
  |> option.unwrap([])
}

/// Get shape points for a shape ID using indexed lookup (O(1))
pub fn get_shape(indexed: IndexedFeed, shape_id: String) -> List(ShapePoint) {
  dict.get(indexed.shapes_by_id, shape_id)
  |> option.from_result
  |> option.unwrap([])
  |> list.sort(fn(a, b) {
    int.compare(a.shape_pt_sequence, b.shape_pt_sequence)
  })
}

// =============================================================================
// Service Date Queries
// =============================================================================

/// Check if a service is active on a given date
pub fn is_service_active(feed: Feed, service_id: String, date: Date) -> Bool {
  // First check calendar.txt
  let calendar_active = case feed.calendar {
    Some(calendars) -> {
      case list.find(calendars, fn(c) { c.service_id == service_id }) {
        Ok(cal) -> is_calendar_active_on_date(cal, date)
        Error(_) -> False
      }
    }
    None -> False
  }

  // Then check calendar_dates.txt for exceptions
  let exception = case feed.calendar_dates {
    Some(dates) -> {
      list.find(dates, fn(cd) {
        cd.service_id == service_id && dates_equal(cd.date, date)
      })
    }
    None -> Error(Nil)
  }

  // Apply exception
  case exception {
    Ok(cd) ->
      case cd.exception_type {
        ServiceAdded -> True
        ServiceRemoved -> False
      }
    Error(_) -> calendar_active
  }
}

/// Get all service IDs active on a given date
pub fn get_active_services(feed: Feed, date: Date) -> List(String) {
  let from_calendar = case feed.calendar {
    Some(calendars) -> {
      list.filter_map(calendars, fn(cal) {
        case is_calendar_active_on_date(cal, date) {
          True -> Ok(cal.service_id)
          False -> Error(Nil)
        }
      })
    }
    None -> []
  }

  // Add services from calendar_dates with ServiceAdded
  let added = case feed.calendar_dates {
    Some(dates) -> {
      list.filter_map(dates, fn(cd) {
        case cd.exception_type == ServiceAdded && dates_equal(cd.date, date) {
          True -> Ok(cd.service_id)
          False -> Error(Nil)
        }
      })
    }
    None -> []
  }

  // Remove services from calendar_dates with ServiceRemoved
  let removed = case feed.calendar_dates {
    Some(dates) -> {
      list.filter_map(dates, fn(cd) {
        case cd.exception_type == ServiceRemoved && dates_equal(cd.date, date) {
          True -> Ok(cd.service_id)
          False -> Error(Nil)
        }
      })
    }
    None -> []
  }

  list.flatten([from_calendar, added])
  |> list.unique
  |> list.filter(fn(sid) { !list.contains(removed, sid) })
}

/// Get all trips active on a given date
pub fn get_active_trips(feed: Feed, date: Date) -> List(Trip) {
  let active_services = get_active_services(feed, date)
  list.filter(feed.trips, fn(trip) {
    list.contains(active_services, trip.service_id)
  })
}

fn is_calendar_active_on_date(cal: Calendar, date: Date) -> Bool {
  // Check date range
  let in_range =
    compare_dates(date, cal.start_date) != Lt
    && compare_dates(date, cal.end_date) != Gt

  case in_range {
    False -> False
    True -> {
      // Check day of week
      let dow = day_of_week(date)
      case dow {
        0 -> cal.sunday
        1 -> cal.monday
        2 -> cal.tuesday
        3 -> cal.wednesday
        4 -> cal.thursday
        5 -> cal.friday
        6 -> cal.saturday
        _ -> False
      }
    }
  }
}

fn dates_equal(a: Date, b: Date) -> Bool {
  a.year == b.year && a.month == b.month && a.day == b.day
}

type Order {
  Lt
  Eq
  Gt
}

fn compare_dates(a: Date, b: Date) -> Order {
  case int.compare(a.year, b.year) {
    order.Lt -> Lt
    order.Gt -> Gt
    order.Eq ->
      case int.compare(a.month, b.month) {
        order.Lt -> Lt
        order.Gt -> Gt
        order.Eq ->
          case int.compare(a.day, b.day) {
            order.Lt -> Lt
            order.Gt -> Gt
            order.Eq -> Eq
          }
      }
  }
}

import gleam/order

/// Calculate day of week (0=Sunday, 1=Monday, ..., 6=Saturday)
/// Uses Zeller's congruence
fn day_of_week(date: Date) -> Int {
  let y = case date.month < 3 {
    True -> date.year - 1
    False -> date.year
  }
  let m = case date.month < 3 {
    True -> date.month + 12
    False -> date.month
  }
  let d = date.day

  let q = d
  let k = y % 100
  let j = y / 100

  let h = { q + { 13 * { m + 1 } } / 5 + k + k / 4 + j / 4 - 2 * j } % 7

  // Convert to 0=Sunday format
  { h + 6 } % 7
}

// =============================================================================
// Route Queries
// =============================================================================

/// Get all routes of a specific type
pub fn get_routes_by_type(feed: Feed, route_type: RouteType) -> List(Route) {
  list.filter(feed.routes, fn(r) { r.route_type == route_type })
}

/// Get all bus routes
pub fn get_bus_routes(feed: Feed) -> List(Route) {
  get_routes_by_type(feed, types.Bus)
}

/// Get all rail routes (includes subway, rail, tram)
pub fn get_rail_routes(feed: Feed) -> List(Route) {
  list.filter(feed.routes, fn(r) {
    case r.route_type {
      types.Tram | types.Subway | types.Rail -> True
      _ -> False
    }
  })
}

// =============================================================================
// Stop Queries
// =============================================================================

/// Get all parent stations (location_type = 1)
pub fn get_stations(feed: Feed) -> List(Stop) {
  list.filter(feed.stops, fn(s) { s.location_type == types.Station })
}

/// Get all stops belonging to a parent station
pub fn get_stops_in_station(feed: Feed, station_id: String) -> List(Stop) {
  list.filter(feed.stops, fn(s) { s.parent_station == Some(station_id) })
}

/// Get all wheelchair accessible stops
pub fn get_accessible_stops(feed: Feed) -> List(Stop) {
  list.filter(feed.stops, fn(s) {
    s.wheelchair_boarding == types.WheelchairAccessible
  })
}

// =============================================================================
// Trip Queries
// =============================================================================

/// Get all trips in a direction (0 or 1)
pub fn get_trips_by_direction(feed: Feed, direction: Int) -> List(Trip) {
  list.filter(feed.trips, fn(t) {
    case t.direction_id {
      Some(d) ->
        case d {
          types.Outbound -> direction == 0
          types.Inbound -> direction == 1
        }
      None -> False
    }
  })
}

/// Get the route for a trip
pub fn get_route_for_trip(feed: Feed, trip: Trip) -> Option(Route) {
  feed.get_route(feed, trip.route_id)
}

/// Get all stops visited by a trip (in order)
pub fn get_stops_for_trip(feed: Feed, trip_id: String) -> List(Stop) {
  feed.get_stop_times_for_trip(feed, trip_id)
  |> list.filter_map(fn(st) {
    case st.stop_id {
      Some(sid) ->
        case feed.get_stop(feed, sid) {
          Some(stop) -> Ok(stop)
          None -> Error(Nil)
        }
      None -> Error(Nil)
    }
  })
}

// =============================================================================
// Statistics
// =============================================================================

/// Get basic statistics about the feed
pub type FeedStats {
  FeedStats(
    agency_count: Int,
    route_count: Int,
    stop_count: Int,
    trip_count: Int,
    stop_time_count: Int,
    shape_point_count: Int,
  )
}

pub fn get_feed_stats(feed: Feed) -> FeedStats {
  FeedStats(
    agency_count: list.length(feed.agencies),
    route_count: list.length(feed.routes),
    stop_count: list.length(feed.stops),
    trip_count: list.length(feed.trips),
    stop_time_count: list.length(feed.stop_times),
    shape_point_count: case feed.shapes {
      Some(shapes) -> list.length(shapes)
      None -> 0
    },
  )
}
