//// Example: Working with GTFS Realtime Data
////
//// This example demonstrates how to decode and work with GTFS Realtime feeds
//// containing live transit information like vehicle positions and service alerts.

import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gtfs/realtime/decoder
import gtfs/realtime/feed
import gtfs/realtime/types
import simplifile

/// Decode and display GTFS Realtime data
pub fn main() {
  // Example: Load from a local Protocol Buffer file
  // In practice, you would fetch this from a URL
  let pb_path = "./realtime_feed.pb"

  case simplifile.read_bits(pb_path) {
    Ok(data) -> {
      case decoder.decode(data) {
        Ok(feed_message) -> {
          io.println("=== GTFS Realtime Feed ===")
          io.println("")

          // Display feed header info
          display_header(feed_message.header)

          // Get and display vehicle positions
          let vehicles = feed.get_vehicle_positions(feed_message)
          display_vehicles(vehicles)

          // Get and display trip updates
          let trip_updates = feed.get_trip_updates(feed_message)
          display_trip_updates(trip_updates)

          // Get and display service alerts
          let alerts = feed.get_alerts(feed_message)
          display_alerts(alerts)

          io.println("Feed processed successfully!")
        }
        Error(err) -> {
          io.println("Error decoding feed:")
          io.debug(err)
        }
      }
    }
    Error(_) -> {
      io.println("Could not read file: " <> pb_path)
      io.println("")
      io.println("To use this example:")
      io.println("1. Obtain a GTFS Realtime feed from a transit agency")
      io.println("2. Save the Protocol Buffer data to 'realtime_feed.pb'")
      io.println("3. Run this example again")
    }
  }
}

fn display_header(header: types.FeedHeader) {
  io.println("--- Feed Header ---")
  io.print("  Version: ")
  io.println(header.gtfs_realtime_version)
  io.print("  Incrementality: ")
  case header.incrementality {
    types.FullDataset -> io.println("Full Dataset")
    types.Differential -> io.println("Differential")
  }
  case header.timestamp {
    Some(ts) -> {
      io.print("  Timestamp: ")
      io.debug(ts)
    }
    None -> Nil
  }
  io.println("")
}

fn display_vehicles(vehicles: List(types.VehiclePosition)) {
  let count = list.length(vehicles)
  io.print("--- Vehicle Positions (")
  io.debug(count)
  io.println(") ---")

  vehicles
  |> list.take(5)
  |> list.each(fn(v) {
    io.print("  • Vehicle: ")
    case v.vehicle {
      Some(desc) -> {
        case desc.id {
          Some(id) -> io.print(id)
          None -> io.print("(no id)")
        }
        case desc.label {
          Some(label) -> io.print(" - " <> label)
          None -> Nil
        }
      }
      None -> io.print("(unknown)")
    }
    io.println("")

    case v.position {
      Some(pos) -> {
        io.print("    Location: ")
        io.debug(pos.latitude)
        io.print(", ")
        io.debug(pos.longitude)
        io.println("")
      }
      None -> Nil
    }

    io.print("    Status: ")
    case v.current_status {
      types.IncomingAt -> io.println("Incoming")
      types.StoppedAt -> io.println("Stopped")
      types.InTransitTo -> io.println("In Transit")
    }
  })

  case count > 5 {
    True -> {
      io.print("  ... and ")
      io.debug(count - 5)
      io.println(" more vehicles")
    }
    False -> Nil
  }
  io.println("")
}

fn display_trip_updates(updates: List(types.TripUpdate)) {
  let count = list.length(updates)
  io.print("--- Trip Updates (")
  io.debug(count)
  io.println(") ---")

  updates
  |> list.take(3)
  |> list.each(fn(update) {
    case update.trip {
      trip -> {
        io.print("  • Trip: ")
        case trip.trip_id {
          Some(id) -> io.print(id)
          None -> io.print("(no id)")
        }
        case trip.route_id {
          Some(route) -> io.print(" on route " <> route)
          None -> Nil
        }
        io.println("")

        // Show delay if available
        case update.delay {
          Some(delay) -> {
            io.print("    Delay: ")
            io.debug(delay)
            io.println(" seconds")
          }
          None -> Nil
        }
      }
    }
  })

  case count > 3 {
    True -> {
      io.print("  ... and ")
      io.debug(count - 3)
      io.println(" more updates")
    }
    False -> Nil
  }
  io.println("")
}

fn display_alerts(alerts: List(types.Alert)) {
  let count = list.length(alerts)
  io.print("--- Service Alerts (")
  io.debug(count)
  io.println(") ---")

  list.each(alerts, fn(alert) {
    io.print("  ⚠ ")

    // Show header text
    case alert.header_text {
      Some(text) -> {
        case list.first(text.translation) {
          Ok(t) -> io.println(t.text)
          Error(_) -> io.println("(no header)")
        }
      }
      None -> io.println("(no header)")
    }

    // Show effect
    io.print("    Effect: ")
    case alert.effect {
      types.NoService -> io.println("No Service")
      types.ReducedService -> io.println("Reduced Service")
      types.SignificantDelays -> io.println("Significant Delays")
      types.Detour -> io.println("Detour")
      types.AdditionalService -> io.println("Additional Service")
      types.ModifiedService -> io.println("Modified Service")
      types.OtherEffect -> io.println("Other Effect")
      types.UnknownEffect -> io.println("Unknown")
      types.StopMoved -> io.println("Stop Moved")
      types.NoEffect -> io.println("No Effect")
      types.AccessibilityIssue -> io.println("Accessibility Issue")
    }

    // Show severity
    io.print("    Severity: ")
    case alert.severity_level {
      types.UnknownSeverity -> io.println("Unknown")
      types.Info -> io.println("Info")
      types.Warning -> io.println("Warning")
      types.Severe -> io.println("Severe")
    }

    // Show affected entities
    case list.length(alert.informed_entity) {
      n if n > 0 -> {
        io.print("    Affects ")
        io.debug(n)
        io.println(" entities")
      }
      _ -> Nil
    }
    io.println("")
  })
}
