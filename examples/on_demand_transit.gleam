//// Example: On-Demand Transit (GTFS-Flex)
////
//// This example demonstrates GTFS-Flex features for flexible/on-demand transit:
//// - Flexible stop locations using location_id and location_group_id
//// - Pickup/drop-off time windows
//// - Booking rules for advance reservation
//// - Zone-based service areas from locations.geojson

import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gtfs/common/types as common_types
import gtfs/static/feed
import gtfs/static/types

/// On-demand transit (GTFS-Flex) demonstration
pub fn main() {
  io.println("=== GTFS-Flex On-Demand Transit ===")
  io.println("")

  let feed_path = "./flex_feed.zip"

  case feed.load(feed_path) {
    Ok(f) -> analyze_flex_feed(f)
    Error(_) -> {
      io.println("No flex feed found at " <> feed_path)
      io.println("")
      io.println("Demonstrating GTFS-Flex concepts with sample data:")
      io.println("")
      demonstrate_flex_concepts()
    }
  }
}

fn analyze_flex_feed(f: feed.Feed) {
  io.println("--- Feed Overview ---")
  io.print("  Routes: ")
  io.debug(list.length(f.routes))
  io.print("  Trips: ")
  io.debug(list.length(f.trips))
  io.print("  Stop Times: ")
  io.debug(list.length(f.stop_times))
  io.println("")

  // Find flexible stop times (those with pickup windows or location_id)
  let flex_stop_times =
    list.filter(f.stop_times, fn(st) {
      option.is_some(st.start_pickup_drop_off_window)
      || option.is_some(st.location_id)
      || option.is_some(st.location_group_id)
    })

  io.println("--- Flexible Service Analysis ---")
  io.print("  Flexible stop times: ")
  io.debug(list.length(flex_stop_times))

  // Count by type
  let with_windows =
    list.filter(flex_stop_times, fn(st) {
      option.is_some(st.start_pickup_drop_off_window)
    })
  let with_location_id =
    list.filter(flex_stop_times, fn(st) { option.is_some(st.location_id) })
  let with_location_group =
    list.filter(flex_stop_times, fn(st) { option.is_some(st.location_group_id) })

  io.print("    - With time windows: ")
  io.debug(list.length(with_windows))
  io.print("    - With location_id (zone): ")
  io.debug(list.length(with_location_id))
  io.print("    - With location_group_id: ")
  io.debug(list.length(with_location_group))
  io.println("")

  // Display booking rules
  case f.booking_rules {
    Some(rules) -> {
      io.println("--- Booking Rules ---")
      io.print("  Total rules: ")
      io.debug(list.length(rules))
      io.println("")
      list.each(rules, display_booking_rule)
    }
    None -> io.println("  No booking rules defined")
  }

  // Display location groups
  case f.location_groups {
    Some(groups) -> {
      io.println("--- Location Groups ---")
      list.each(groups, fn(g) {
        io.print("  • ")
        io.print(g.location_group_id)
        case g.location_group_name {
          Some(name) -> io.print(" - " <> name)
          None -> Nil
        }
        io.println("")
      })
    }
    None -> Nil
  }

  // Display GeoJSON locations
  case f.locations {
    Some(locations) -> {
      io.println("--- Service Zones (locations.geojson) ---")
      io.print("  Zones defined: ")
      io.debug(list.length(locations.features))
      list.each(locations.features, fn(feature) {
        io.print("  • ")
        io.print(feature.id)
        case feature.properties.stop_name {
          Some(name) -> io.print(" - " <> name)
          None -> Nil
        }
        io.println("")
      })
    }
    None -> Nil
  }
}

fn demonstrate_flex_concepts() {
  // Sample booking rules
  let sample_rules = [
    types.BookingRule(
      booking_rule_id: "same_day",
      booking_type: types.SameDayBooking,
      prior_notice_duration_min: Some(60),
      prior_notice_duration_max: Some(480),
      prior_notice_last_day: None,
      prior_notice_last_time: None,
      prior_notice_start_day: None,
      prior_notice_start_time: None,
      prior_notice_service_id: None,
      message: Some("Book at least 1 hour before your trip"),
      pickup_message: Some("Driver will call when arriving"),
      drop_off_message: None,
      phone_number: Some(common_types.PhoneNumber("555-RIDE")),
      info_url: Some(common_types.Url("https://transit.example.com/flex")),
      booking_url: Some(common_types.Url("https://book.transit.example.com")),
    ),
    types.BookingRule(
      booking_rule_id: "advance",
      booking_type: types.PriorDayBooking,
      prior_notice_duration_min: None,
      prior_notice_duration_max: None,
      prior_notice_last_day: Some(1),
      prior_notice_last_time: Some(common_types.Time(17, 0, 0)),
      prior_notice_start_day: Some(7),
      prior_notice_start_time: None,
      prior_notice_service_id: None,
      message: Some("Book by 5pm the day before"),
      pickup_message: None,
      drop_off_message: None,
      phone_number: Some(common_types.PhoneNumber("555-FLEX")),
      info_url: None,
      booking_url: None,
    ),
    types.BookingRule(
      booking_rule_id: "realtime",
      booking_type: types.RealTimeBooking,
      prior_notice_duration_min: None,
      prior_notice_duration_max: None,
      prior_notice_last_day: None,
      prior_notice_last_time: None,
      prior_notice_start_day: None,
      prior_notice_start_time: None,
      prior_notice_service_id: None,
      message: Some("Request a ride through the app"),
      pickup_message: None,
      drop_off_message: None,
      phone_number: None,
      info_url: None,
      booking_url: Some(common_types.Url("app://transit-flex")),
    ),
  ]

  io.println("--- Sample Booking Rules ---")
  list.each(sample_rules, display_booking_rule)

  // Sample flexible stop times
  io.println("--- Sample Flexible Stop Times ---")
  let flex_examples = [
    types.StopTime(
      trip_id: "flex_trip_1",
      arrival_time: None,
      departure_time: None,
      stop_id: None,
      location_group_id: None,
      location_id: Some("downtown_zone"),
      stop_sequence: 1,
      stop_headsign: Some("Downtown Flex Zone"),
      start_pickup_drop_off_window: Some(common_types.Time(7, 0, 0)),
      end_pickup_drop_off_window: Some(common_types.Time(9, 0, 0)),
      pickup_type: types.PhoneForPickup,
      drop_off_type: types.NoDropOff,
      continuous_pickup: types.NoContinuousStoppingPickup,
      continuous_drop_off: types.NoContinuousStoppingDropOff,
      shape_dist_traveled: None,
      timepoint: types.Approximate,
      pickup_booking_rule_id: Some("same_day"),
      drop_off_booking_rule_id: None,
    ),
    types.StopTime(
      trip_id: "flex_trip_1",
      arrival_time: None,
      departure_time: None,
      stop_id: Some("TRANSIT_HUB"),
      location_group_id: None,
      location_id: None,
      stop_sequence: 2,
      stop_headsign: None,
      start_pickup_drop_off_window: Some(common_types.Time(7, 30, 0)),
      end_pickup_drop_off_window: Some(common_types.Time(9, 30, 0)),
      pickup_type: types.NoPickup,
      drop_off_type: types.RegularDropOff,
      continuous_pickup: types.NoContinuousStoppingPickup,
      continuous_drop_off: types.NoContinuousStoppingDropOff,
      shape_dist_traveled: None,
      timepoint: types.Exact,
      pickup_booking_rule_id: None,
      drop_off_booking_rule_id: None,
    ),
  ]

  list.each(flex_examples, display_flex_stop_time)

  io.println("")
  io.println("--- GTFS-Flex Summary ---")
  io.println("GTFS-Flex extends GTFS to support demand-responsive transit:")
  io.println("")
  io.println("  1. TIME WINDOWS: Instead of fixed arrival/departure times,")
  io.println("     flexible services define pickup/drop-off windows.")
  io.println("")
  io.println("  2. ZONES: Services can pick up/drop off anywhere within")
  io.println("     a geographic zone (defined in locations.geojson).")
  io.println("")
  io.println("  3. BOOKING RULES: Define advance booking requirements,")
  io.println("     including notice periods and booking methods.")
  io.println("")
  io.println("  4. LOCATION GROUPS: Group multiple stops or zones that")
  io.println("     can be served interchangeably.")
}

fn display_booking_rule(rule: types.BookingRule) {
  io.println("")
  io.print("  📋 ")
  io.println(rule.booking_rule_id)

  io.print("     Type: ")
  case rule.booking_type {
    types.RealTimeBooking -> io.println("Real-time (book now)")
    types.SameDayBooking -> io.println("Same-day booking")
    types.PriorDayBooking -> io.println("Advance booking required")
  }

  case rule.prior_notice_duration_min {
    Some(mins) -> {
      io.print("     Min notice: ")
      io.print(int.to_string(mins))
      io.println(" minutes")
    }
    None -> Nil
  }

  case rule.prior_notice_last_day {
    Some(days) -> {
      io.print("     Book by: ")
      io.print(int.to_string(days))
      io.print(" day(s) before")
      case rule.prior_notice_last_time {
        Some(t) -> {
          io.print(" at ")
          io.print(int.to_string(t.hours))
          io.print(":")
          io.print(int.to_string(t.minutes) |> pad_zero)
        }
        None -> Nil
      }
      io.println("")
    }
    None -> Nil
  }

  case rule.message {
    Some(msg) -> {
      io.print("     Message: ")
      io.println(msg)
    }
    None -> Nil
  }

  case rule.phone_number {
    Some(phone) -> {
      io.print("     Phone: ")
      io.println(phone.value)
    }
    None -> Nil
  }

  case rule.booking_url {
    Some(url) -> {
      io.print("     Book at: ")
      io.println(url.value)
    }
    None -> Nil
  }
}

fn display_flex_stop_time(st: types.StopTime) {
  io.println("")
  io.print("  🚐 Stop #")
  io.print(int.to_string(st.stop_sequence))
  io.print(" on trip ")
  io.println(st.trip_id)

  // Location
  io.print("     Location: ")
  case st.location_id {
    Some(loc) -> io.println("Zone '" <> loc <> "'")
    None ->
      case st.stop_id {
        Some(stop) -> io.println("Stop '" <> stop <> "'")
        None -> io.println("(undefined)")
      }
  }

  // Time window
  case st.start_pickup_drop_off_window, st.end_pickup_drop_off_window {
    Some(start), Some(end) -> {
      io.print("     Window: ")
      io.print(format_time(start))
      io.print(" - ")
      io.println(format_time(end))
    }
    _, _ -> Nil
  }

  // Pickup/drop-off types
  io.print("     Pickup: ")
  io.print(pickup_type_string(st.pickup_type))
  io.print(" | Drop-off: ")
  io.println(dropoff_type_string(st.drop_off_type))

  // Booking rule
  case st.pickup_booking_rule_id {
    Some(rule) -> {
      io.print("     Booking rule: ")
      io.println(rule)
    }
    None -> Nil
  }
}

fn pickup_type_string(pt: types.PickupType) -> String {
  case pt {
    types.RegularPickup -> "Regular"
    types.NoPickup -> "None"
    types.PhoneForPickup -> "Phone agency"
    types.DriverCoordinatedPickup -> "Coordinate with driver"
  }
}

fn dropoff_type_string(dt: types.DropOffType) -> String {
  case dt {
    types.RegularDropOff -> "Regular"
    types.NoDropOff -> "None"
    types.PhoneForDropOff -> "Phone agency"
    types.DriverCoordinatedDropOff -> "Coordinate with driver"
  }
}

fn format_time(t: common_types.Time) -> String {
  int.to_string(t.hours)
  <> ":"
  <> pad_zero(int.to_string(t.minutes))
  <> ":"
  <> pad_zero(int.to_string(t.seconds))
}

fn pad_zero(s: String) -> String {
  case string_length(s) {
    1 -> "0" <> s
    _ -> s
  }
}

@external(erlang, "string", "length")
fn string_length(s: String) -> Int
