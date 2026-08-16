import Foundation
import HTML
import Saga
import SagaSwimRenderer

func renderAlbums(context: ItemsRenderingContext<AlbumMetadata>) -> Node {
  baseHtml(title: "My favorite albums", section: .albums) {
    main(class: "mx-auto max-w-6xl px-6 py-12") {
      header(class: "mb-12 border-b border-white/10 pb-8") {
        h1 {
          "My favorite albums"
        }
        p(class: "mt-4 max-w-2xl text-white/80") {
          "\(context.items.count) albums, ranked"
        }
      }

      ul(class: "grid grid-cols-2 gap-x-5 gap-y-10 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5") {
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
}

@NodeBuilder
private func albumCardContents(_ album: Item<AlbumMetadata>) -> Node {
  div(class: "relative aspect-square overflow-hidden rounded-xl bg-zinc-900 transition duration-300") {
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

  h2(class: "mt-3 text-sm font-semibold leading-snug text-zinc-100 transition group-hover:text-white") {
    album.title
  }

  p(class: "mt-0.5 text-xs text-white/80") {
    "\(album.metadata.artist) · \(album.metadata.year)"
  }
}
