import Foundation
import SwiftDotenv
import Saga
import SagaPathKit
import SwiftCSV

private let postersFolder: Path = "content/static/posters/imdb"

// TMDB's /find endpoint, which looks up a title by its IMDb id
private struct TMDBFindResponse: Decodable {
  struct Result: Decodable {
    let posterPath: String?
  }
  
  let tvResults: [Result]
  let movieResults: [Result]
  
  var posterPath: String? {
    (tvResults + movieResults).compactMap(\.posterPath).first
  }
}

/// Downloads the poster for an IMDb id into content/static/posters/{id}.jpg.
/// Does nothing when we already have the image on disk.
func downloadPoster(imdbID: String) async {
  let destination = postersFolder + "\(imdbID).jpg"
  guard !destination.exists else { return }
  
  guard let token = Dotenv["TMDB_ACCESS_TOKEN"]?.stringValue else {
    print("⚠️ TMDB_ACCESS_TOKEN is not set, skipping poster downloads")
    return
  }

  var request = URLRequest(url: URL(string: "https://api.themoviedb.org/3/find/\(imdbID)?external_source=imdb_id")!)
  request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
  request.setValue("application/json", forHTTPHeaderField: "accept")
  
  do {
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    guard let posterPath = try decoder.decode(TMDBFindResponse.self, from: data).posterPath else {
      print("⚠️ No poster found for \(imdbID)")
      return
    }
    
    let (imageData, _) = try await URLSession.shared.data(from: URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")!)
    try postersFolder.mkpath()
    try destination.write(imageData)
  } catch {
    print("⚠️ Failed to download poster for \(imdbID): \(error)")
  }
}

func fetch(csvName: String) async throws -> [Item<ImdbMetadata>] {
  let csvFile = try loadCSV(named: csvName)
  
  let items = csvFile.rows.enumerated().map { index, row in
    let metadata = ImdbMetadata(
      position: index + 1,
      id: row["Id"]!,
      title: row["Title"]!,
      rating: Int(row["Rating"]!)!,
      genres: row["Genres"]!.components(separatedBy: ", ")
    )
    return Item(title: metadata.title, metadata: metadata)
  }
  
  for item in items {
    await downloadPoster(imdbID: item.metadata.id)
  }
  
  return items
}
