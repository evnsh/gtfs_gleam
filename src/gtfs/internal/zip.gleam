//// ZIP File Handling
////
//// Provides ZIP archive extraction using Erlang's :zlib module.
//// Used to load GTFS feeds from ZIP archives.

import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/list
import gleam/result

// =============================================================================
// Error Types
// =============================================================================

/// Errors that can occur during ZIP operations
pub type ZipError {
  /// File not found in archive
  FileNotFound(filename: String)
  /// Archive is corrupted or invalid
  CorruptedArchive(reason: String)
  /// I/O error reading archive
  IoError(reason: String)
  /// Decompression error
  DecompressionError(reason: String)
}

// =============================================================================
// ZIP Archive Types
// =============================================================================

/// Represents a ZIP archive
pub opaque type ZipArchive {
  ZipArchive(entries: Dict(String, ZipEntry))
}

/// A single entry in a ZIP archive
type ZipEntry {
  ZipEntry(name: String, compressed_data: BitArray, uncompressed_size: Int)
}

// =============================================================================
// Public API
// =============================================================================

/// Open a ZIP archive from bytes
pub fn open(data: BitArray) -> Result(ZipArchive, ZipError) {
  // Use Erlang's zip module to parse the archive
  case zip_open(data) {
    Ok(entries) -> Ok(ZipArchive(entries))
    Error(reason) -> Error(CorruptedArchive(reason))
  }
}

/// List all files in the archive
pub fn list_files(archive: ZipArchive) -> List(String) {
  let ZipArchive(entries) = archive
  dict.keys(entries)
}

/// Check if a file exists in the archive
pub fn file_exists(archive: ZipArchive, filename: String) -> Bool {
  let ZipArchive(entries) = archive
  dict.has_key(entries, filename)
}

/// Extract a file from the archive as a string (UTF-8)
pub fn extract_string(
  archive: ZipArchive,
  filename: String,
) -> Result(String, ZipError) {
  use bytes <- result.try(extract_bytes(archive, filename))
  case bit_array.to_string(bytes) {
    Ok(s) -> Ok(s)
    Error(_) -> Error(IoError("File is not valid UTF-8: " <> filename))
  }
}

/// Extract a file from the archive as bytes
pub fn extract_bytes(
  archive: ZipArchive,
  filename: String,
) -> Result(BitArray, ZipError) {
  let ZipArchive(entries) = archive
  case dict.get(entries, filename) {
    Ok(entry) -> decompress_entry(entry)
    Error(_) -> Error(FileNotFound(filename))
  }
}

/// Extract all files matching a predicate
pub fn extract_matching(
  archive: ZipArchive,
  predicate: fn(String) -> Bool,
) -> Result(Dict(String, String), ZipError) {
  let ZipArchive(entries) = archive
  let matching =
    dict.filter(entries, fn(name, _) { predicate(name) })
    |> dict.keys()

  list.try_fold(matching, dict.new(), fn(acc, name) {
    use content <- result.try(extract_string(archive, name))
    Ok(dict.insert(acc, name, content))
  })
}

// =============================================================================
// Internal Functions
// =============================================================================

fn decompress_entry(entry: ZipEntry) -> Result(BitArray, ZipError) {
  let ZipEntry(_, compressed_data, _) = entry
  // Data is already decompressed by erlang's zip module
  Ok(compressed_data)
}

// =============================================================================
// Erlang FFI
// =============================================================================

/// Open and parse a ZIP archive using Erlang's zip module
fn zip_open(data: BitArray) -> Result(Dict(String, ZipEntry), String) {
  case do_zip_unzip(data) {
    Ok(entries) -> {
      let entry_dict =
        list.fold(entries, dict.new(), fn(acc, entry) {
          let #(name, content) = entry
          let zip_entry = ZipEntry(name, content, bit_array.byte_size(content))
          dict.insert(acc, name, zip_entry)
        })
      Ok(entry_dict)
    }
    Error(reason) -> Error(reason)
  }
}

@external(erlang, "gtfs_zip_ffi", "unzip")
fn do_zip_unzip(data: BitArray) -> Result(List(#(String, BitArray)), String)
