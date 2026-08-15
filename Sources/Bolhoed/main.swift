import Bonsai
import Foundation
import Saga
import SagaParsleyMarkdownReader
import SagaSwimRenderer
import SwiftTailwind
import SagaPathKit
import SwiftCSV
import SwiftDotenv

try? Dotenv.configure()

let tailwind = SwiftTailwind(version: "4.2.4")

struct ImdbMetadata: Metadata {
  let position: Int
  let id: String
  let title: String
  let rating: Int
  let genres: [String]

  var posterURL: String {
    "/static/posters/imdb/\(id).jpg"
  }
}

struct AlbumMetadata: Metadata {
  let position: Int
  let id: String
  let artist: String
  let title: String
  let year: Int

  var posterURL: String {
    "/static/posters/albums/\(id).jpg"
  }

  /// Albums that aren't on Apple Music get a short hand-picked id instead of a collection id
  var appleMusicURL: String? {
    id.count >= 8 ? "https://music.apple.com/album/\(id)" : nil
  }
}

struct GameMetadata: Metadata {
  let position: Int
  let id: String
  let title: String

  var posterURL: String {
    "/static/posters/games/\(id).jpg"
  }
}

try await Saga(input: "content", output: "deploy")
  // Compile tailwind to output.css
  .beforeRead { saga in
    if let path = saga.buildReason.changedFile(),
       path.extension != "css",
       !path.components.contains("templates")
    {
      // It needs to be a css file or a template file, otherwise, skip it
      return
    }
    
    try await tailwind.run(
      input: "content/static/input.css",
      output: "content/static/output.css",
      options: .minify
    )
  }

  // Don't trigger a rebuild when output.css changes, otherwise we get into an endless loop
  .ignoreChanges("output.css")

  // Same for the posters we download during the build
  .ignoreChanges("content/static/posters/*/*")

  // Load tv shows
  .register(
    metadata: ImdbMetadata.self,
    fetch: { try await fetch(csvName: "shows") },
    cacheKey: nil,
    sorting: { $0.metadata.position < $1.metadata.position },
    writers: [.listWriter(swim(renderShows), output: "shows/index.html")]
  )

  // Load movies
  .register(
    metadata: ImdbMetadata.self,
    fetch: { try await fetch(csvName: "movies") },
    cacheKey: nil,
    sorting: { $0.metadata.position < $1.metadata.position },
    writers: [.listWriter(swim(renderMovies), output: "movies/index.html")]
  )

  // Load games
  .register(
    metadata: GameMetadata.self,
    fetch: { try await fetchGames() },
    cacheKey: nil,
    sorting: { $0.metadata.position < $1.metadata.position },
    writers: [.listWriter(swim(renderGames), output: "games/index.html")]
  )

  // Load albums
  .register(
    metadata: AlbumMetadata.self,
    fetch: { try await fetchAlbums() },
    cacheKey: nil,
    sorting: { $0.metadata.position < $1.metadata.position },
    writers: [.listWriter(swim(renderAlbums), output: "albums/index.html")]
  )

  // The rest of the pages
  .register(
    metadata: EmptyMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemWriteMode: .keepAsFile,
    writers: [.itemWriter(swim(renderPage))]
  )

  // Minify all HTML output (prod only)
  .postProcess { html, _ in
    guard !Saga.isDev else { return html }
    return Bonsai.minifyHTML(html)
  }

  // Run everything!
  .run()
