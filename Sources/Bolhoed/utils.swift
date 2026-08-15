import Foundation
import SagaPathKit
import SwiftCSV

private let csvFolder: Path = "Sources/Bolhoed/csv"

/// Reads a CSV straight from the source folder instead of the SwiftPM resource bundle.
///
/// The bundle copy is only refreshed when the package recompiles, but editing a .csv doesn't
/// trigger a recompile — only a site rebuild. Reading the file directly means CSV edits show up
/// on the very next rebuild.
func loadCSV(named name: String) throws -> CSV<Named> {
  try CSV<Named>(url: (csvFolder + "\(name).csv").url)
}
