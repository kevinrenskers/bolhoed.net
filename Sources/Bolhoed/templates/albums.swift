import Foundation
import HTML
import Saga
import SagaSwimRenderer

func renderAlbums(context: ItemsRenderingContext<AlbumMetadata>) -> Node {
  baseHtml(title: "Bolhoed.net | My favorite albums", canonicalPath: context.outputPath.url, section: .albums) {
    header(class: "page-header") {
      h1 {
        "My favorite albums"
      }
      p {
        "\(context.items.count) albums, ranked"
      }
    }

    ul(class: "grid grid-cols-2 gap-8 lg:gap-12 md:grid-cols-3 lg:grid-cols-4") {
      context.items.map { album in
        li {
          if let url = album.metadata.linkURL {
            a(class: "group block", href: url, target: "_blank") {
              albumCardContents(album)
            }
          } else {
            albumCardContents(album)
          }
        }
      }
    }

    if Saga.isDev {
      script(src: "/static/enhance.js")
      Node.raw("<script>enhance('albums');</script>")
    }
  }
}

@NodeBuilder
private func albumCardContents(_ album: Item<AlbumMetadata>) -> Node {
  div(class: "relative aspect-square overflow-hidden rounded-xl bg-white transition duration-300") {
    img(
      alt: "\(album.metadata.artist) - \(album.title)",
      class: "absolute inset-0 h-full w-full object-cover transition duration-500 group-hover:scale-105",
      loading: "lazy",
      src: album.metadata.posterURL
    )

    span(class: "absolute left-2 top-2 rounded-md bg-black/70 px-2 py-0.5 text-xs font-semibold tabular-nums text-zinc-300 backdrop-blur-sm") {
      "#\(album.metadata.position)"
    }
  }

  h2(class: "mt-3 text-sm font-semibold leading-snug transition") {
    album.title
  }

  p(class: "mt-0.5 text-xs text-white/80") {
    "\(album.metadata.artist) · \(album.metadata.year)"
  }
}
