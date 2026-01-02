//// Color Parsing and Manipulation Utilities
////
//// GTFS represents colors as 6-character hexadecimal strings without
//// the # prefix (e.g., "FFFFFF" for white, "000000" for black).
//// This module provides parsing, validation, and manipulation utilities.
////
//// Source: GTFS reference.md - Field Types

import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gtfs/common/types.{type Color, Color}

// =============================================================================
// Parsing
// =============================================================================

/// Parse a GTFS color string (6 hex characters without #)
/// Examples: "FFFFFF" (white), "000000" (black), "FF5733" (orange)
pub fn parse(value: String) -> Result(Color, String) {
  let value = string.trim(value)

  // Remove # if present (be lenient)
  let value = case value {
    "#" <> rest -> rest
    _ -> value
  }

  case string.length(value) {
    6 -> {
      let red_str = string.slice(value, 0, 2)
      let green_str = string.slice(value, 2, 2)
      let blue_str = string.slice(value, 4, 2)

      use red <- result.try(parse_hex_byte(red_str))
      use green <- result.try(parse_hex_byte(green_str))
      use blue <- result.try(parse_hex_byte(blue_str))

      Ok(Color(red: red, green: green, blue: blue))
    }
    _ -> Error("color must be 6 hex characters (e.g., FFFFFF)")
  }
}

/// Parse an optional color string
pub fn parse_optional(value: String) -> Result(Option(Color), String) {
  case string.trim(value) {
    "" -> Ok(None)
    v -> parse(v) |> result.map(Some)
  }
}

fn parse_hex_byte(s: String) -> Result(Int, String) {
  case int.base_parse(s, 16) {
    Ok(n) if n >= 0 && n <= 255 -> Ok(n)
    Ok(_) -> Error("invalid hex byte value")
    Error(_) -> Error("invalid hex characters")
  }
}

// =============================================================================
// Formatting
// =============================================================================

/// Format a color as a GTFS color string (6 hex characters, uppercase)
pub fn to_string(color: Color) -> String {
  let r = int_to_hex_padded(color.red)
  let g = int_to_hex_padded(color.green)
  let b = int_to_hex_padded(color.blue)
  r <> g <> b
}

/// Format a color with # prefix for CSS/HTML use
pub fn to_css_string(color: Color) -> String {
  "#" <> to_string(color)
}

fn int_to_hex_padded(n: Int) -> String {
  let hex = case int.to_base_string(n, 16) {
    Ok(h) -> h
    Error(_) -> "00"
  }
  case string.length(hex) {
    1 -> "0" <> string.uppercase(hex)
    _ -> string.uppercase(hex)
  }
}

// =============================================================================
// Color Operations
// =============================================================================

/// Create a Color from RGB values (0-255 each)
pub fn from_rgb(red: Int, green: Int, blue: Int) -> Result(Color, String) {
  case
    red >= 0
    && red <= 255
    && green >= 0
    && green <= 255
    && blue >= 0
    && blue <= 255
  {
    True -> Ok(Color(red: red, green: green, blue: blue))
    False -> Error("RGB values must be between 0 and 255")
  }
}

/// Calculate the perceived luminance of a color (0.0 to 1.0)
/// Uses the relative luminance formula from WCAG
pub fn luminance(color: Color) -> Float {
  let r = srgb_to_linear(int.to_float(color.red) /. 255.0)
  let g = srgb_to_linear(int.to_float(color.green) /. 255.0)
  let b = srgb_to_linear(int.to_float(color.blue) /. 255.0)

  0.2126 *. r +. 0.7152 *. g +. 0.0722 *. b
}

fn srgb_to_linear(c: Float) -> Float {
  case c <=. 0.03928 {
    True -> c /. 12.92
    False -> {
      let base = { c +. 0.055 } /. 1.055
      pow(base, 2.4)
    }
  }
}

/// Simple power function for gamma correction
fn pow(base: Float, exp: Float) -> Float {
  // Use Erlang's math:pow
  do_pow(base, exp)
}

@external(erlang, "math", "pow")
fn do_pow(base: Float, exp: Float) -> Float

/// Determine if a color is "light" (useful for choosing text color)
/// Returns True if the color is light (use dark text)
/// Returns False if the color is dark (use light text)
pub fn is_light(color: Color) -> Bool {
  luminance(color) >. 0.5
}

/// Get a contrasting text color (black or white) for the given background
pub fn contrasting_text_color(background: Color) -> Color {
  case is_light(background) {
    True -> Color(red: 0, green: 0, blue: 0)
    // Black text
    False -> Color(red: 255, green: 255, blue: 255)
    // White text
  }
}

/// Calculate contrast ratio between two colors (1:1 to 21:1)
/// WCAG AA requires 4.5:1 for normal text, 3:1 for large text
pub fn contrast_ratio(color1: Color, color2: Color) -> Float {
  let l1 = luminance(color1)
  let l2 = luminance(color2)

  let lighter = float_max(l1, l2)
  let darker = float_min(l1, l2)

  { lighter +. 0.05 } /. { darker +. 0.05 }
}

fn float_max(a: Float, b: Float) -> Float {
  case a >. b {
    True -> a
    False -> b
  }
}

fn float_min(a: Float, b: Float) -> Float {
  case a <. b {
    True -> a
    False -> b
  }
}

// =============================================================================
// Common Colors
// =============================================================================

/// White color (#FFFFFF)
pub fn white() -> Color {
  Color(red: 255, green: 255, blue: 255)
}

/// Black color (#000000)
pub fn black() -> Color {
  Color(red: 0, green: 0, blue: 0)
}

/// Default GTFS route color (white)
pub fn default_route_color() -> Color {
  white()
}

/// Default GTFS text color (black)
pub fn default_text_color() -> Color {
  black()
}
