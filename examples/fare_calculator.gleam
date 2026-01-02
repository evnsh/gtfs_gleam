//// Example: Fare Calculator (GTFS-Fares v2)
////
//// This example demonstrates GTFS-Fares v2 features:
//// - Fare products and pricing
//// - Fare media (payment methods)
//// - Fare leg rules (origin/destination based pricing)
//// - Fare transfer rules
//// - Rider categories (adult, senior, student, etc.)

import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gtfs/common/types as common_types
import gtfs/static/feed
import gtfs/static/types

/// Fare calculator demonstration
pub fn main() {
  io.println("=== GTFS-Fares v2 Calculator ===")
  io.println("")

  let feed_path = "./gtfs_feed.zip"

  case feed.load(feed_path) {
    Ok(f) -> analyze_fares(f)
    Error(_) -> {
      io.println("No feed found. Demonstrating Fares v2 concepts:")
      io.println("")
      demonstrate_fares_v2()
    }
  }
}

fn analyze_fares(f: feed.Feed) {
  io.println("--- Fare Components Analysis ---")
  io.println("")

  // Legacy fares (v1)
  case f.fare_attributes {
    Some(fares) -> {
      io.println("Legacy Fares (fare_attributes.txt):")
      io.print("  Fare classes: ")
      io.debug(list.length(fares))
      list.take(fares, 5)
      |> list.each(fn(fare) {
        io.print("    • ")
        io.print(fare.fare_id)
        io.print(": ")
        io.print(int.to_string(fare.price.amount))
        io.print(" ")
        io.println(fare.currency_type.code)
      })
      io.println("")
    }
    None -> Nil
  }

  // Fares v2 - Fare Products
  case f.fare_products {
    Some(products) -> {
      io.println("Fare Products (fare_products.txt):")
      io.print("  Products: ")
      io.debug(list.length(products))
      list.take(products, 5)
      |> list.each(fn(p) {
        io.print("    • ")
        io.print(p.fare_product_id)
        case p.fare_product_name {
          Some(name) -> io.print(" - " <> name)
          None -> Nil
        }
        io.println("")
      })
      io.println("")
    }
    None -> io.println("No fare products defined (Fares v2)")
  }

  // Fare Media
  case f.fare_media {
    Some(media) -> {
      io.println("Fare Media (fare_media.txt):")
      io.print("  Payment methods: ")
      io.debug(list.length(media))
      list.each(media, fn(m) {
        io.print("    • ")
        io.print(m.fare_media_id)
        case m.fare_media_name {
          Some(name) -> io.print(" - " <> name)
          None -> Nil
        }
        io.print(" (")
        io.print(media_type_string(m.fare_media_type))
        io.println(")")
      })
      io.println("")
    }
    None -> Nil
  }

  // Fare Leg Rules
  case f.fare_leg_rules {
    Some(rules) -> {
      io.println("Fare Leg Rules (fare_leg_rules.txt):")
      io.print("  Rules: ")
      io.debug(list.length(rules))
      io.println("")
    }
    None -> Nil
  }

  // Fare Transfer Rules
  case f.fare_transfer_rules {
    Some(rules) -> {
      io.println("Fare Transfer Rules (fare_transfer_rules.txt):")
      io.print("  Transfer rules: ")
      io.debug(list.length(rules))
      io.println("")
    }
    None -> Nil
  }

  // Rider Categories
  case f.rider_categories {
    Some(categories) -> {
      io.println("Rider Categories (rider_categories.txt):")
      list.each(categories, fn(c) {
        io.print("    • ")
        io.print(c.rider_category_id)
        io.print(" - ")
        io.println(c.rider_category_name)
      })
      io.println("")
    }
    None -> Nil
  }
}

fn demonstrate_fares_v2() {
  // Sample fare media
  let sample_media = [
    types.FareMedia(
      fare_media_id: "cash",
      fare_media_name: Some("Cash"),
      fare_media_type: types.Cash,
    ),
    types.FareMedia(
      fare_media_id: "transit_card",
      fare_media_name: Some("Transit Card"),
      fare_media_type: types.TransitCard,
    ),
    types.FareMedia(
      fare_media_id: "mobile_app",
      fare_media_name: Some("Mobile App"),
      fare_media_type: types.MobileApp,
    ),
    types.FareMedia(
      fare_media_id: "contactless",
      fare_media_name: Some("Contactless Bank Card"),
      fare_media_type: types.Cemv,
    ),
  ]

  io.println("--- Fare Media (Payment Methods) ---")
  list.each(sample_media, fn(m) {
    io.print("  💳 ")
    io.print(m.fare_media_id)
    case m.fare_media_name {
      Some(name) -> io.print(" - " <> name)
      None -> Nil
    }
    io.print(" [")
    io.print(media_type_string(m.fare_media_type))
    io.println("]")
  })
  io.println("")

  // Sample fare products
  let sample_products = [
    types.FareProduct(
      fare_product_id: "single_ride",
      fare_product_name: Some("Single Ride"),
      fare_media_id: None,
      amount: common_types.CurrencyAmount(275, 2),
      currency: common_types.CurrencyCode("USD"),
      rider_category_id: None,
      bundle: types.NotBundled,
      duration_type: types.NotDurationLimited,
      duration_start: types.AtFareValidation,
      duration_amount: None,
      duration_unit: None,
      offset_amount: None,
      offset_unit: None,
    ),
    types.FareProduct(
      fare_product_id: "day_pass",
      fare_product_name: Some("Day Pass"),
      fare_media_id: Some("transit_card"),
      amount: common_types.CurrencyAmount(700, 2),
      currency: common_types.CurrencyCode("USD"),
      rider_category_id: None,
      bundle: types.BundleSingleTrip,
      duration_type: types.SingleDay,
      duration_start: types.AtFareValidation,
      duration_amount: None,
      duration_unit: None,
      offset_amount: None,
      offset_unit: None,
    ),
    types.FareProduct(
      fare_product_id: "monthly_pass",
      fare_product_name: Some("Monthly Pass"),
      fare_media_id: Some("transit_card"),
      amount: common_types.CurrencyAmount(10_000, 2),
      currency: common_types.CurrencyCode("USD"),
      rider_category_id: None,
      bundle: types.BundleSingleTrip,
      duration_type: types.CalendarMonth,
      duration_start: types.AtFareValidation,
      duration_amount: Some(1),
      duration_unit: Some(types.Month),
      offset_amount: None,
      offset_unit: None,
    ),
    types.FareProduct(
      fare_product_id: "senior_single",
      fare_product_name: Some("Senior Single Ride"),
      fare_media_id: None,
      amount: common_types.CurrencyAmount(135, 2),
      currency: common_types.CurrencyCode("USD"),
      rider_category_id: Some("senior"),
      bundle: types.NotBundled,
      duration_type: types.NotDurationLimited,
      duration_start: types.AtFareValidation,
      duration_amount: None,
      duration_unit: None,
      offset_amount: None,
      offset_unit: None,
    ),
  ]

  io.println("--- Fare Products ---")
  list.each(sample_products, fn(p) {
    io.print("  🎫 ")
    case p.fare_product_name {
      Some(name) -> io.print(name)
      None -> io.print(p.fare_product_id)
    }
    io.print(": $")
    let dollars = p.amount.amount / 100
    let cents = p.amount.amount % 100
    io.print(int.to_string(dollars))
    io.print(".")
    io.print(pad_zero(int.to_string(cents)))
    io.print(" ")
    io.print(p.currency.code)
    case p.rider_category_id {
      Some(cat) -> io.print(" [" <> cat <> "]")
      None -> Nil
    }
    io.println("")
  })
  io.println("")

  // Sample rider categories
  let sample_categories = [
    types.RiderCategory(
      rider_category_id: "adult",
      rider_category_name: "Adult",
      min_age: Some(18),
      max_age: Some(64),
      eligibility_url: None,
    ),
    types.RiderCategory(
      rider_category_id: "senior",
      rider_category_name: "Senior (65+)",
      min_age: Some(65),
      max_age: None,
      eligibility_url: None,
    ),
    types.RiderCategory(
      rider_category_id: "youth",
      rider_category_name: "Youth (6-17)",
      min_age: Some(6),
      max_age: Some(17),
      eligibility_url: None,
    ),
    types.RiderCategory(
      rider_category_id: "child",
      rider_category_name: "Child (under 6)",
      min_age: None,
      max_age: Some(5),
      eligibility_url: None,
    ),
  ]

  io.println("--- Rider Categories ---")
  list.each(sample_categories, fn(c) {
    io.print("  👤 ")
    io.print(c.rider_category_name)
    case c.min_age, c.max_age {
      Some(min), Some(max) -> {
        io.print(" (ages ")
        io.print(int.to_string(min))
        io.print("-")
        io.print(int.to_string(max))
        io.print(")")
      }
      Some(min), None -> {
        io.print(" (")
        io.print(int.to_string(min))
        io.print("+)")
      }
      None, Some(max) -> {
        io.print(" (under ")
        io.print(int.to_string(max + 1))
        io.print(")")
      }
      None, None -> Nil
    }
    io.println("")
  })
  io.println("")

  // Explain fare leg rules concept
  io.println("--- Fare Leg Rules (Zone-Based Pricing) ---")
  io.println("  Fare leg rules define pricing based on:")
  io.println("    • Origin/destination areas (zones)")
  io.println("    • Network (operator)")
  io.println("    • Time of travel (timeframes)")
  io.println("")
  io.println("  Example:")
  io.println("    Zone A → Zone A: $2.75")
  io.println("    Zone A → Zone B: $3.50")
  io.println("    Zone A → Zone C: $4.25")
  io.println("")

  // Explain transfer rules
  io.println("--- Fare Transfer Rules ---")
  io.println("  Transfer rules define discounts when changing vehicles:")
  io.println("")
  io.println("  Example:")
  io.println("    • Free transfer within 2 hours (same network)")
  io.println("    • $0.50 transfer between bus and rail")
  io.println("    • No transfer discount after 3 hours")
  io.println("")

  // Summary
  io.println("--- GTFS-Fares v2 Summary ---")
  io.println("")
  io.println("Fares v2 provides a flexible fare modeling system:")
  io.println("")
  io.println("  fare_media.txt      - How riders can pay")
  io.println("  fare_products.txt   - What riders can buy")
  io.println("  fare_leg_rules.txt  - Pricing by origin/destination")
  io.println("  fare_transfer_rules.txt - Transfer discounts")
  io.println("  rider_categories.txt - Passenger types (discounts)")
  io.println("  areas.txt           - Geographic fare zones")
  io.println("  timeframes.txt      - Peak/off-peak pricing")
  io.println("")
  io.println("This replaces the simpler fare_attributes.txt/fare_rules.txt")
  io.println("model for agencies with complex fare structures.")
}

fn media_type_string(mt: types.FareMediaType) -> String {
  case mt {
    types.NoFareMedia -> "None"
    types.PhysicalPaper -> "Paper"
    types.TransitCard -> "Transit Card"
    types.Cemv -> "Contactless EMV"
    types.MobileApp -> "Mobile App"
    types.Cash -> "Cash"
  }
}

fn pad_zero(s: String) -> String {
  case string_length(s) {
    1 -> "0" <> s
    _ -> s
  }
}

@external(erlang, "string", "length")
fn string_length(s: String) -> Int
