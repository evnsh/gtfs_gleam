//// Example: Loading a GTFS Static Feed
////
//// This example demonstrates how to load and work with a GTFS static feed
//// containing transit schedule information from a zip file.

import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gtfs/static/feed
import gtfs/static/types

/// Load and display information from a GTFS static feed
pub fn main() {
  // Load a GTFS feed from a zip file
  // Replace with your actual GTFS feed path
  let feed_path = "./gtfs_feed.zip"

  case feed.load(feed_path) {
    Ok(f) -> {
      io.println("=== GTFS Static Feed Loaded ===")
      io.println("")

      // Display agencies
      display_agencies(f.agencies)

      // Display routes summary
      display_routes_summary(f.routes)

      // Display stops summary
      display_stops_summary(f.stops)

      // Display trips summary
      display_trips_summary(f.trips)

      io.println("Feed loaded successfully!")
    }
    Error(err) -> {
      io.println("Error loading feed:")
      io.debug(err)
    }
  }
}

fn display_agencies(agencies: List(types.Agency)) {
  io.println("--- Agencies ---")
  list.each(agencies, fn(agency) {
    io.print("  • ")
    io.println(agency.agency_name)
    case agency.agency_url {
      url -> {
        io.print("    URL: ")
        io.println(url.value)
      }
    }
    io.print("    Timezone: ")
    io.println(agency.agency_timezone.name)
  })
  io.println("")
}

fn display_routes_summary(routes: List(types.Route)) {
  let count = list.length(routes)
  io.print("--- Routes (")
  io.debug(count)
  io.println(" total) ---")

  // Group routes by type
  let bus_count =
    list.filter(routes, fn(r) { r.route_type == types.Bus })
    |> list.length

  let rail_count =
    list.filter(routes, fn(r) { r.route_type == types.Rail })
    |> list.length

  let subway_count =
    list.filter(routes, fn(r) { r.route_type == types.Subway })
    |> list.length

  io.print("  Bus routes: ")
  io.debug(bus_count)
  io.print("  Rail routes: ")
  io.debug(rail_count)
  io.print("  Subway routes: ")
  io.debug(subway_count)
  io.println("")

  // Display first 5 routes
  io.println("  First 5 routes:")
  routes
  |> list.take(5)
  |> list.each(fn(route) {
    io.print("    • ")
    case route.route_short_name {
      Some(name) -> io.print(name <> " - ")
      None -> Nil
    }
    case route.route_long_name {
      Some(name) -> io.println(name)
      None -> io.println("(unnamed)")
    }
  })
  io.println("")
}

fn display_stops_summary(stops: List(types.Stop)) {
  let count = list.length(stops)
  io.print("--- Stops (")
  io.debug(count)
  io.println(" total) ---")

  // Count by location type
  let stations =
    list.filter(stops, fn(s) { s.location_type == types.Station })
    |> list.length

  let platforms =
    list.filter(stops, fn(s) { s.location_type == types.StopOrPlatform })
    |> list.length

  io.print("  Stations: ")
  io.debug(stations)
  io.print("  Stop/Platforms: ")
  io.debug(platforms)
  io.println("")
}

fn display_trips_summary(trips: List(types.Trip)) {
  let count = list.length(trips)
  io.print("--- Trips (")
  io.debug(count)
  io.println(" total) ---")
  io.println("")
}
