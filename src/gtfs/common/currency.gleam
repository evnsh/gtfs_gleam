//// Currency Handling Utilities
////
//// GTFS uses ISO 4217 currency codes and handles monetary amounts.
//// This module provides parsing and formatting utilities with proper
//// decimal handling to avoid floating-point precision issues.
////
//// Source: GTFS reference.md - Field Types

import gleam/float
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gtfs/common/types.{
  type CurrencyAmount, type CurrencyCode, CurrencyAmount, CurrencyCode,
}

// =============================================================================
// Currency Code Parsing
// =============================================================================

/// Parse an ISO 4217 currency code (3-letter code)
pub fn parse_code(value: String) -> Result(CurrencyCode, String) {
  let value = string.uppercase(string.trim(value))
  case string.length(value) {
    3 -> Ok(CurrencyCode(value))
    _ -> Error("currency code must be 3 letters (e.g., USD, EUR)")
  }
}

/// Parse an optional currency code
pub fn parse_code_optional(
  value: String,
) -> Result(Option(CurrencyCode), String) {
  case string.trim(value) {
    "" -> Ok(None)
    v -> parse_code(v) |> result.map(Some)
  }
}

// =============================================================================
// Currency Amount Parsing
// =============================================================================

/// Parse a currency amount from a string
/// Handles decimal amounts properly using integer arithmetic
/// Examples: "2.50" -> CurrencyAmount(250, 2), "100" -> CurrencyAmount(100, 0)
pub fn parse_amount(value: String) -> Result(CurrencyAmount, String) {
  let value = string.trim(value)

  case string.split(value, ".") {
    [whole] -> {
      use amount <- result.try(
        int.parse(whole) |> result.replace_error("invalid amount"),
      )
      Ok(CurrencyAmount(amount: amount, decimal_places: 0))
    }
    [whole, decimal] -> {
      let decimal_places = string.length(decimal)
      use whole_part <- result.try(
        int.parse(whole) |> result.replace_error("invalid whole part"),
      )
      use decimal_part <- result.try(
        int.parse(decimal) |> result.replace_error("invalid decimal part"),
      )

      // Combine: e.g., "12.34" -> 1234 with decimal_places=2
      let multiplier = pow10(decimal_places)
      let amount = whole_part * multiplier + decimal_part

      Ok(CurrencyAmount(amount: amount, decimal_places: decimal_places))
    }
    _ -> Error("invalid currency amount format")
  }
}

/// Parse an optional currency amount
pub fn parse_amount_optional(
  value: String,
) -> Result(Option(CurrencyAmount), String) {
  case string.trim(value) {
    "" -> Ok(None)
    v -> parse_amount(v) |> result.map(Some)
  }
}

fn pow10(n: Int) -> Int {
  case n {
    0 -> 1
    1 -> 10
    2 -> 100
    3 -> 1000
    4 -> 10_000
    5 -> 100_000
    _ -> 10 * pow10(n - 1)
  }
}

// =============================================================================
// Currency Amount Formatting
// =============================================================================

/// Format a currency amount as a decimal string
/// Example: CurrencyAmount(250, 2) -> "2.50"
pub fn amount_to_string(amount: CurrencyAmount) -> String {
  case amount.decimal_places {
    0 -> int.to_string(amount.amount)
    places -> {
      let divisor = pow10(places)
      let whole = amount.amount / divisor
      let decimal = amount.amount % divisor

      let decimal_str = int.to_string(decimal)
      let padded_decimal = string.pad_start(decimal_str, places, "0")

      int.to_string(whole) <> "." <> padded_decimal
    }
  }
}

/// Format a currency amount with its currency code
/// Example: CurrencyAmount(250, 2), CurrencyCode("USD") -> "USD 2.50"
pub fn format(amount: CurrencyAmount, currency: CurrencyCode) -> String {
  currency.code <> " " <> amount_to_string(amount)
}

/// Format with symbol (for common currencies)
pub fn format_with_symbol(
  amount: CurrencyAmount,
  currency: CurrencyCode,
) -> String {
  let symbol = currency_symbol(currency)
  symbol <> amount_to_string(amount)
}

/// Get the symbol for common currencies
pub fn currency_symbol(currency: CurrencyCode) -> String {
  case currency.code {
    "USD" -> "$"
    "EUR" -> "€"
    "GBP" -> "£"
    "JPY" -> "¥"
    "CNY" -> "¥"
    "CAD" -> "$"
    "AUD" -> "$"
    "CHF" -> "Fr."
    "INR" -> "₹"
    "MXN" -> "$"
    "BRL" -> "R$"
    "KRW" -> "₩"
    _ -> currency.code <> " "
  }
}

/// Get the number of decimal places typically used for a currency
pub fn currency_decimal_places(currency: CurrencyCode) -> Int {
  case currency.code {
    "JPY" -> 0
    // Japanese Yen has no decimal places
    "KRW" -> 0
    // Korean Won
    "VND" -> 0
    // Vietnamese Dong
    "BHD" -> 3
    // Bahraini Dinar has 3 decimal places
    "KWD" -> 3
    // Kuwaiti Dinar
    "OMR" -> 3
    // Omani Rial
    _ -> 2
    // Most currencies use 2 decimal places
  }
}

// =============================================================================
// Currency Amount Operations
// =============================================================================

/// Convert amount to a Float (for display purposes only, not calculations)
pub fn amount_to_float(amount: CurrencyAmount) -> Float {
  int.to_float(amount.amount) /. int.to_float(pow10(amount.decimal_places))
}

/// Create a CurrencyAmount from a Float (convenience function)
/// Note: For precise amounts, use parse_amount instead
pub fn amount_from_float(value: Float, decimal_places: Int) -> CurrencyAmount {
  let multiplier = int.to_float(pow10(decimal_places))
  let amount = float.round(value *. multiplier)
  CurrencyAmount(amount: amount, decimal_places: decimal_places)
}

/// Add two currency amounts (normalizes to higher precision)
pub fn add(a: CurrencyAmount, b: CurrencyAmount) -> CurrencyAmount {
  let #(norm_a, norm_b, places) = normalize_precision(a, b)
  CurrencyAmount(amount: norm_a + norm_b, decimal_places: places)
}

/// Subtract two currency amounts (normalizes to higher precision)
pub fn subtract(a: CurrencyAmount, b: CurrencyAmount) -> CurrencyAmount {
  let #(norm_a, norm_b, places) = normalize_precision(a, b)
  CurrencyAmount(amount: norm_a - norm_b, decimal_places: places)
}

/// Multiply a currency amount by an integer
pub fn multiply(amount: CurrencyAmount, factor: Int) -> CurrencyAmount {
  CurrencyAmount(
    amount: amount.amount * factor,
    decimal_places: amount.decimal_places,
  )
}

/// Compare two currency amounts
pub fn compare(a: CurrencyAmount, b: CurrencyAmount) -> order.Order {
  let #(norm_a, norm_b, _) = normalize_precision(a, b)
  int.compare(norm_a, norm_b)
}

import gleam/order

/// Check if amount is zero
pub fn is_zero(amount: CurrencyAmount) -> Bool {
  amount.amount == 0
}

/// Check if amount is positive
pub fn is_positive(amount: CurrencyAmount) -> Bool {
  amount.amount > 0
}

/// Check if amount is negative
pub fn is_negative(amount: CurrencyAmount) -> Bool {
  amount.amount < 0
}

fn normalize_precision(a: CurrencyAmount, b: CurrencyAmount) -> #(Int, Int, Int) {
  case int.compare(a.decimal_places, b.decimal_places) {
    order.Eq -> #(a.amount, b.amount, a.decimal_places)
    order.Lt -> {
      let diff = b.decimal_places - a.decimal_places
      #(a.amount * pow10(diff), b.amount, b.decimal_places)
    }
    order.Gt -> {
      let diff = a.decimal_places - b.decimal_places
      #(a.amount, b.amount * pow10(diff), a.decimal_places)
    }
  }
}

// =============================================================================
// Common Currency Codes
// =============================================================================

/// US Dollar
pub fn usd() -> CurrencyCode {
  CurrencyCode("USD")
}

/// Euro
pub fn eur() -> CurrencyCode {
  CurrencyCode("EUR")
}

/// British Pound
pub fn gbp() -> CurrencyCode {
  CurrencyCode("GBP")
}

/// Japanese Yen
pub fn jpy() -> CurrencyCode {
  CurrencyCode("JPY")
}

/// Canadian Dollar
pub fn cad() -> CurrencyCode {
  CurrencyCode("CAD")
}

/// Australian Dollar
pub fn aud() -> CurrencyCode {
  CurrencyCode("AUD")
}

/// Zero amount with specified decimal places
pub fn zero(decimal_places: Int) -> CurrencyAmount {
  CurrencyAmount(amount: 0, decimal_places: decimal_places)
}
