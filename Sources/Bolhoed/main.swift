import Bonsai
import Foundation
import Saga
import SagaImageReader
import SagaParsleyMarkdownReader
import SagaPathKit
import SagaSwimRenderer
import SagaUtils
import SwiftCSV
import SwiftDotenv
import SwiftTailwind

try? Dotenv.configure()

let tailwind = SwiftTailwind(version: "4.2.4")

enum SiteMetadata {
  static let url = URL(string: "https://www.bolhoed.net")!
  static let name = "Bolhoed.net"
  static let author = "Kevin Renskers"
  static let now = Date()
}

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
  let url: String?

  var posterURL: String {
    "/static/posters/albums/\(id).jpg"
  }

  /// Albums that aren't on Apple Music get a hand-picked slug instead of a collection id
  var appleMusicURL: String? {
    Int(id) != nil ? "https://music.apple.com/album/\(id)" : nil
  }

  /// The URL column from the csv wins, so an album can point anywhere. Albums with neither
  /// a URL nor a store page aren't linked at all.
  var linkURL: String? {
    url ?? appleMusicURL
  }
}

struct GameMetadata: Metadata {
  let position: Int
  let id: String
  let title: String
  let url: String?

  var posterURL: String {
    "/static/posters/games/\(id).jpg"
  }

  /// Games that aren't on Steam get a hand-picked slug instead of an appid
  var steamURL: String? {
    Int(id) != nil ? "https://store.steampowered.com/app/\(id)/" : nil
  }

  /// The URL column from the csv wins, so a game can point anywhere. Games with neither
  /// a URL nor a store page aren't linked at all.
  var linkURL: String? {
    url ?? steamURL
  }
}

struct ArticleMetadata: Metadata {
  let summary: String
  var tags: [String]?
  var toc: String?
}

struct PhotoAlbumMetadata: Metadata {}

extension Item where M == ArticleMetadata {
  var tags: [String] {
    metadata.tags ?? []
  }

  var year: Int {
    Calendar.current.component(.year, from: date)
  }

  var creationDate: Date {
    // Use file modification date if it matches the filename date (accounting for timezone)
    // The git-restore-mtime script should have set proper file timestamps to the FIRST commit
    let amsterdamTimeZone = TimeZone(identifier: "Europe/Amsterdam")!
    var calendar = Calendar.current
    calendar.timeZone = amsterdamTimeZone

    let fileCreationComponents = calendar.dateComponents([.year, .month, .day], from: lastModified)
    let selfDateComponents = calendar.dateComponents([.year, .month, .day], from: date)

    // Check if the dates match in Amsterdam timezone
    if fileCreationComponents.year == selfDateComponents.year,
       fileCreationComponents.month == selfDateComponents.month,
       fileCreationComponents.day == selfDateComponents.day
    {
      return lastModified
    }

    // Fallback to self.date (filename date at noon)
    var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
    components.hour = 12
    components.minute = 0
    components.second = 0
    components.timeZone = TimeZone.current

    return Calendar.current.date(from: components) ?? date
  }
}

try await Saga(input: "content", output: ".deploy")
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
  .ignoreChanges("content/static/maps/*")

  // Blog (articles)
  .register(
    folder: "blog",
    metadata: ArticleMetadata.self,
    readers: [.parsleyMarkdownWithAttributesReader],
    itemProcessor: sequence(publicationDateInFilename, swiftSoupProcessor({ doc, item in item.metadata.toc = try buildTOCList(doc) }, processExternalLinks, convertAsides)),
    writers: [
      .itemWriter(swim(renderArticle)),
      .listWriter(swim(renderArticles)),
      .tagWriter(swim(renderTag), tags: \.tags),
      .listWriter(
        Saga.atomFeed(
          title: SiteMetadata.name,
          author: SiteMetadata.author,
          baseURL: SiteMetadata.url,
          summary: \.metadata.summary,
          dateKeyPath: \.creationDate
        ),
        output: "feed.xml"
      ),
    ]
  )

  // Photo albums from markdown files, with nested photo pages per album
  .register(
    folder: "photos",
    metadata: PhotoAlbumMetadata.self,
    itemProcessor: { album in
      let words = album.title.replacingOccurrences(of: "-", with: " ")
      album.title = words.prefix(1).uppercased() + words.dropFirst()
    },
    writers: [
      .listWriter(swim(renderPhotoAlbums)),
      .itemWriter(swim(renderPhotoAlbum)),
    ],
    nested: { nested in
      nested.register(
        metadata: ImageMetadata.self,
        readers: [.imageReader],
        itemProcessor: downloadMap,
        writers: [
          .itemWriter(swim(renderPhoto)),
        ]
      )
    }
  )

  // Load tv shows
  .register(
    metadata: ImdbMetadata.self,
    fetch: { try await fetch(csvName: "shows", kind: .tv) },
    cacheKey: nil,
    sorting: { $0.metadata.position < $1.metadata.position },
    writers: [.listWriter(swim(renderShows), output: "shows/index.html")]
  )

  // Load movies
  .register(
    metadata: ImdbMetadata.self,
    fetch: { try await fetch(csvName: "movies", kind: .movie) },
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

  // Home
  .register(
    metadata: EmptyMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: swiftSoupProcessor(processExternalLinks),
    filter: { $0.relativeSource == "index.md" },
    claimExcludedItems: false,
    writers: [.itemWriter(swim(renderHome))]
  )

  // Other markdown pages, like the legal notice
  .register(
    metadata: EmptyMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: swiftSoupProcessor(processExternalLinks),
    writers: [.itemWriter(swim(renderPage))]
  )

  // Sitemap
  .createPage("sitemap.xml", using: Saga.sitemap(baseURL: SiteMetadata.url, filter: { path, _ in
    if path.string.hasSuffix("feed.xml") {
      return false
    }
    return true
  }))

  // 404
  .createPage("404.html", using: swim(render404))

  // Minify all HTML output (prod only)
  .postProcess { html, _ in
    guard !Saga.isDev else { return html }
    return Bonsai.minifyHTML(html)
  }

  // Markdown twins of articles, for content negotiation (see nginx.conf)
  .afterWrite(writeMarkdownFiles)

  // Run everything!
  .run()
