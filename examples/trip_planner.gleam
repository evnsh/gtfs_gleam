//// Example: Simple Trip Planner
////
//// This example demonstrates how to use the GTFS library to:
//// - Find routes serving a specific stop
//// - Get trips on a route for a given day
//// - List stop times in order
//// - Check service availability for a date

import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gtfs/common/types as common_types
import gtfs/static/feed
import gtfs/static/query
import gtfs/static/types

/// Simple trip planner demonstration
pub fn main() {
  let feed_path = "./gtfs_feed.zip"

  case feed.load(feed_path) {
    Ok(f) -> {
      io.println("=== GTFS Trip Planner ===")
      io.println("")

      // Create an indexed feed for fast lookups
      let indexed = query.index_feed(f)

      // Example 1: Find all routes
      io.println("--- Available Routes ---")
      f.routes
      |> list.take(10)
      |> list.each(fn(route) { display_route(route) })
      io.println("")

      // Example 2: Get trips for the first route
      case list.first(f.routes) {
        Ok(route) -> {
          io.println("--- Trips on route " <> route.route_id <> " ---")
          let trips = query.get_trips_on_route(indexed, route.route_id)
          io.print("  Total trips: ")
          io.debug(list.length(trips))
          io.println("")

          // Get stop times for the first trip
          case list.first(trips) {
            Ok(trip) -> {
              io.println("--- Stop Times for trip " <> trip.trip_id <> " ---")
              let stop_times =
                query.get_stop_times_for_trip(indexed, trip.trip_id)
              display_stop_times(stop_times, indexed)
            }
            Error(_) -> io.println("  No trips found")
          }
        }
        Error(_) -> io.println("No routes in feed")
      }

      // Example 3: Check service for a date
      io.println("")
      io.println("--- Service Check ---")
      let test_date = common_types.Date(2025, 1, 15)
      let active_services = query.get_active_services(f, test_date)
      io.print("  Active services on 2025-01-15: ")
      io.debug(list.length(active_services))

      // Example 4: Find stops near a coordinate (if we had coordinates)
      io.println("")
      io.println("--- Station Information ---")
      let stations =
        list.filter(f.stops, fn(stop) { stop.location_type == types.Station })
      io.print("  Total stations: ")
      io.debug(list.length(stations))

      stations
      |> list.take(5)
      |> list.each(fn(stop) {
        io.print("    • ")
        case stop.stop_name {
          Some(name) -> io.println(name)
          None -> io.println("(unnamed)")
        }
      })

      io.println("")
      io.println("Trip planner demo complete!")
    }
    Error(err) -> {
      io.println("Error loading feed:")
      io.debug(err)
      io.println("")
      io.println("To use this example:")
      io.println("1. Download a GTFS feed from a transit agency")
      io.println("2. Save it as 'gtfs_feed.zip' in the current directory")
      io.println("3. Run this example again")
    }
  }
}

fn display_route(route: types.Route) {
  io.print("  ")
  case route.route_short_name {
    Some(short) -> io.print(short <> " ")
    None -> Nil
  }
  case route.route_long_name {
    Some(long) -> io.print("- " <> long)
    None -> Nil
  }
  io.print(" (")
  io.print(route_type_name(route.route_type))
  io.println(")")
}

fn route_type_name(rt: types.RouteType) -> String {
  case rt {
    types.Tram -> "Tram"
    types.Subway -> "Subway"
    types.Rail -> "Rail"
    types.Bus -> "Bus"
    types.Ferry -> "Ferry"
    types.CableTram -> "Cable Tram"
    types.AerialLift -> "Aerial Lift"
    types.Funicular -> "Funicular"
    types.Trolleybus -> "Trolleybus"
    types.Monorail -> "Monorail"
  }
}

fn display_stop_times(
  stop_times: List(types.StopTime),
  indexed: query.IndexedFeed,
) {
  stop_times
  |> list.take(10)
  |> list.each(fn(st) {
    io.print("  ")
    io.print(int.to_string(st.stop_sequence))
    io.print(". ")

    // Show arrival time
    case st.arrival_time {
      Some(t) -> {
        io.print(format_time(t))
        io.print(" ")
      }
      None -> io.print("--:--:-- ")
    }

    // Show stop name
    case st.stop_id {
      Some(stop_id) -> {
        case query.get_stop(indexed, stop_id) {
          Some(stop) -> {
            case stop.stop_name {
              Some(name) -> io.print(name)
              None -> io.print(stop_id)
            }
          }
          None -> io.print(stop_id)
        }
      }
      None -> io.print("(flex zone)")
    }
    io.println("")
  })

  let remaining = list.length(stop_times) - 10
  case remaining > 0 {
    True -> {
      io.print("  ... and ")
      io.print(int.to_string(remaining))
      io.println(" more stops")
    }
    False -> Nil
  }
}

fn format_time(t: common_types.Time) -> String {
  let hours = int.to_string(t.hours) |> pad_left(2, "0")
  let minutes = int.to_string(t.minutes) |> pad_left(2, "0")
  let seconds = int.to_string(t.seconds) |> pad_left(2, "0")
  hours <> ":" <> minutes <> ":" <> seconds
}

fn pad_left(s: String, len: Int, pad: String) -> String {
  case len - string_length(s) {
    n if n > 0 -> pad_left(pad <> s, len, pad)
    _ -> s
  }
}

@external(erlang, "string", "length")
fn string_length(s: String) -> Int
