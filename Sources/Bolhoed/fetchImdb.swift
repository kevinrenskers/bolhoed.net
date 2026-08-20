import Foundation
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
import SwiftDotenv
import Saga
import SagaPathKit
import SwiftCSV

private let postersFolder: Path = "content/static/posters/imdb"

/// TMDB sometimes has an unrelated title tagged with the same IMDb id, so we pick
/// the poster from the kind of result we're actually looking for.
enum MediaKind {
  case movie
  case tv
}

// TMDB's /find endpoint, which looks up a title by its IMDb id
private struct TMDBFindResponse: Decodable {
  struct Result: Decodable {
    let posterPath: String?
  }
  
  let tvResults: [Result]
  let movieResults: [Result]
  
  func posterPath(preferring kind: MediaKind) -> String? {
    let results = switch kind {
      case .movie: movieResults + tvResults
      case .tv: tvResults + movieResults
    }
    return results.compactMap(\.posterPath).first
  }
}

/// Downloads the poster for an IMDb id into content/static/posters/{id}.jpg.
/// Does nothing when we already have the image on disk.
func downloadPoster(imdbID: String, kind: MediaKind) async {
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
    
    guard let posterPath = try decoder.decode(TMDBFindResponse.self, from: data).posterPath(preferring: kind) else {
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

func fetch(csvName: String, kind: MediaKind) async throws -> [Item<ImdbMetadata>] {
  let csvFile = try loadCSV(named: csvName)
  
  let items = compactMapRows(csvFile) { position, row in
    let metadata = try ImdbMetadata(
      position: position,
      id: row.required("Id"),
      title: row.required("Title"),
      rating: row.requiredInt("Rating"),
      genres: row.required("Genres").components(separatedBy: ", ")
    )
    return Item(title: metadata.title, metadata: metadata)
  }
  
  for item in items {
    await downloadPoster(imdbID: item.metadata.id, kind: kind)
  }
  
  return items
}
