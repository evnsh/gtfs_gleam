//// Example: Service Alerts Handler
////
//// This example demonstrates how to:
//// - Decode GTFS Realtime alerts
//// - Filter alerts by route/stop
//// - Display alert information with translations
//// - Check if alerts are currently active

import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gtfs/realtime/decoder
import gtfs/realtime/feed
import gtfs/realtime/types
import simplifile

/// Service alerts demonstration
pub fn main() {
  io.println("=== GTFS Realtime Service Alerts ===")
  io.println("")

  // Try to load from a local file, or show usage instructions
  let pb_path = "./alerts.pb"

  case simplifile.read_bits(pb_path) {
    Ok(data) -> process_alerts_from_data(data)
    Error(_) -> {
      io.println("No local alerts.pb file found.")
      io.println("")
      io.println("Demonstrating with sample alert data structure:")
      io.println("")
      demonstrate_alert_handling()
    }
  }
}

fn process_alerts_from_data(data: BitArray) {
  case decoder.decode(data) {
    Ok(feed_message) -> {
      let alerts = feed.get_alerts(feed_message)
      io.print("Found ")
      io.print(int.to_string(list.length(alerts)))
      io.println(" alerts")
      io.println("")

      list.each(alerts, display_alert)
    }
    Error(err) -> {
      io.println("Error decoding feed:")
      io.debug(err)
    }
  }
}

fn demonstrate_alert_handling() {
  // Create sample alerts to demonstrate the API
  let sample_alerts = [
    types.Alert(
      active_period: [
        types.TimeRange(start: Some(1_704_067_200), end: Some(1_704_153_600)),
      ],
      informed_entity: [
        types.EntitySelector(
          agency_id: None,
          route_id: Some("Red"),
          route_type: None,
          trip: None,
          stop_id: None,
          direction_id: None,
        ),
      ],
      cause: types.Maintenance,
      effect: types.ReducedService,
      url: None,
      header_text: Some(
        types.TranslatedString(translation: [
          types.Translation(
            text: "Red Line: Reduced Service",
            language: Some("en"),
          ),
          types.Translation(
            text: "Ligne Rouge: Service Réduit",
            language: Some("fr"),
          ),
        ]),
      ),
      description_text: Some(
        types.TranslatedString(translation: [
          types.Translation(
            text: "Due to scheduled maintenance, Red Line trains are running every 15 minutes instead of every 10 minutes.",
            language: Some("en"),
          ),
        ]),
      ),
      tts_header_text: None,
      tts_description_text: None,
      severity_level: types.Warning,
      image: None,
      image_alternative_text: None,
      cause_detail: None,
      effect_detail: None,
    ),
    types.Alert(
      active_period: [types.TimeRange(start: Some(1_704_100_000), end: None)],
      informed_entity: [
        types.EntitySelector(
          agency_id: None,
          route_id: None,
          route_type: None,
          trip: None,
          stop_id: Some("CENTRAL"),
          direction_id: None,
        ),
      ],
      cause: types.Construction,
      effect: types.StopMoved,
      url: Some(
        types.TranslatedString(translation: [
          types.Translation(
            text: "https://transit.example.com/alerts/central-closure",
            language: None,
          ),
        ]),
      ),
      header_text: Some(
        types.TranslatedString(translation: [
          types.Translation(
            text: "Central Station: Temporary Stop Relocation",
            language: Some("en"),
          ),
        ]),
      ),
      description_text: Some(
        types.TranslatedString(translation: [
          types.Translation(
            text: "Due to construction, the Central Station stop has been temporarily moved 100m north.",
            language: Some("en"),
          ),
        ]),
      ),
      tts_header_text: None,
      tts_description_text: None,
      severity_level: types.Info,
      image: None,
      image_alternative_text: None,
      cause_detail: None,
      effect_detail: None,
    ),
  ]

  io.print("Sample alerts: ")
  io.debug(list.length(sample_alerts))
  io.println("")

  list.each(sample_alerts, display_alert)

  io.println("")
  io.println("--- Filtering Examples ---")
  io.println("")

  // Filter alerts for a specific route
  let red_line_alerts =
    list.filter(sample_alerts, fn(alert) { affects_route(alert, "Red") })
  io.print("Alerts affecting Red Line: ")
  io.debug(list.length(red_line_alerts))

  // Filter alerts for a specific stop
  let central_alerts =
    list.filter(sample_alerts, fn(alert) { affects_stop(alert, "CENTRAL") })
  io.print("Alerts affecting Central Station: ")
  io.debug(list.length(central_alerts))

  // Filter by severity
  let warnings =
    list.filter(sample_alerts, fn(alert) {
      alert.severity_level == types.Warning
    })
  io.print("Warning-level alerts: ")
  io.debug(list.length(warnings))
}

fn display_alert(alert: types.Alert) {
  io.println("┌─────────────────────────────────────")

  // Header
  io.print("│ ")
  case alert.header_text {
    Some(ts) -> io.println(get_translation(ts, "en"))
    None -> io.println("(No header)")
  }

  // Severity and Effect
  io.print("│ Severity: ")
  io.print(severity_to_string(alert.severity_level))
  io.print(" | Effect: ")
  io.println(effect_to_string(alert.effect))

  // Cause
  io.print("│ Cause: ")
  io.println(cause_to_string(alert.cause))

  // Active period
  io.print("│ Active: ")
  case alert.active_period {
    [period, ..] -> {
      case period.start {
        Some(s) -> io.print("from " <> int.to_string(s))
        None -> io.print("from (open)")
      }
      case period.end {
        Some(e) -> io.print(" to " <> int.to_string(e))
        None -> io.print(" to (ongoing)")
      }
      io.println("")
    }
    [] -> io.println("(always)")
  }

  // Affected entities
  io.print("│ Affects: ")
  alert.informed_entity
  |> list.map(entity_to_string)
  |> list.intersperse(", ")
  |> list.each(io.print)
  io.println("")

  // Description
  case alert.description_text {
    Some(ts) -> {
      io.print("│ ")
      io.println(get_translation(ts, "en"))
    }
    None -> Nil
  }

  // URL
  case alert.url {
    Some(ts) -> {
      io.print("│ URL: ")
      io.println(get_translation(ts, "en"))
    }
    None -> Nil
  }

  io.println("└─────────────────────────────────────")
  io.println("")
}

fn get_translation(ts: types.TranslatedString, preferred_lang: String) -> String {
  // Try to find preferred language first
  case
    list.find(ts.translation, fn(t) {
      t.language == Some(preferred_lang) || t.language == None
    })
  {
    Ok(t) -> t.text
    Error(_) -> {
      // Fall back to first translation
      case list.first(ts.translation) {
        Ok(t) -> t.text
        Error(_) -> "(no translation)"
      }
    }
  }
}

fn severity_to_string(s: types.SeverityLevel) -> String {
  case s {
    types.UnknownSeverity -> "Unknown"
    types.Info -> "Info"
    types.Warning -> "Warning"
    types.Severe -> "SEVERE"
  }
}

fn effect_to_string(e: types.AlertEffect) -> String {
  case e {
    types.NoService -> "No Service"
    types.ReducedService -> "Reduced Service"
    types.SignificantDelays -> "Significant Delays"
    types.Detour -> "Detour"
    types.AdditionalService -> "Additional Service"
    types.ModifiedService -> "Modified Service"
    types.OtherEffect -> "Other"
    types.UnknownEffect -> "Unknown"
    types.StopMoved -> "Stop Moved"
    types.NoEffect -> "No Effect"
    types.AccessibilityIssue -> "Accessibility Issue"
  }
}

fn cause_to_string(c: types.AlertCause) -> String {
  case c {
    types.UnknownCause -> "Unknown"
    types.OtherCause -> "Other"
    types.TechnicalProblem -> "Technical Problem"
    types.Strike -> "Strike"
    types.Demonstration -> "Demonstration"
    types.Accident -> "Accident"
    types.Holiday -> "Holiday"
    types.Weather -> "Weather"
    types.Maintenance -> "Maintenance"
    types.Construction -> "Construction"
    types.PoliceActivity -> "Police Activity"
    types.MedicalEmergency -> "Medical Emergency"
  }
}

fn entity_to_string(e: types.EntitySelector) -> String {
  case e {
    types.EntitySelector(route_id: Some(r), ..) -> "Route " <> r
    types.EntitySelector(stop_id: Some(s), ..) -> "Stop " <> s
    types.EntitySelector(agency_id: Some(a), ..) -> "Agency " <> a
    _ -> "Unknown entity"
  }
}

fn affects_route(alert: types.Alert, route_id: String) -> Bool {
  list.any(alert.informed_entity, fn(e) { e.route_id == Some(route_id) })
}

fn affects_stop(alert: types.Alert, stop_id: String) -> Bool {
  list.any(alert.informed_entity, fn(e) { e.stop_id == Some(stop_id) })
}
