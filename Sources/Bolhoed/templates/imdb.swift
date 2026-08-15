import Foundation
import HTML
import Saga
import SagaSwimRenderer

func renderShows(context: ItemsRenderingContext<ImdbMetadata>) -> Node {
  baseHtml(title: "My favorite TV Shows", section: .shows) {
    main(class: "mx-auto max-w-6xl px-6 py-12") {
      header(class: "mb-12 border-b border-white/10 pb-8") {
        h1 {
          "My favorite TV Shows"
        }
        p(class: "mt-4 max-w-2xl text-white/80") {
          "\(context.items.count) shows, ranked"
        }
      }

      ul(class: "grid grid-cols-2 gap-x-5 gap-y-10 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5") {
        context.items.map(showCard)
      }
    }
  }
}

func renderMovies(context: ItemsRenderingContext<ImdbMetadata>) -> Node {
  baseHtml(title: "My favorite movies", section: .movies) {
    main(class: "mx-auto max-w-6xl px-6 py-12") {
      header(class: "mb-12 border-b border-white/10 pb-8") {
        h1 {
          "My favorite movies"
        }
        p(class: "mt-4 max-w-2xl text-white/80") {
          "\(context.items.count) movies, ranked"
        }
      }

      ul(class: "grid grid-cols-2 gap-x-5 gap-y-10 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5") {
        context.items.map(showCard)
      }
    }
  }
}

private func showCard(_ show: Item<ImdbMetadata>) -> Node {
  li {
    a(class: "group block", href: "https://www.imdb.com/title/\(show.metadata.id)/", target: "_blank") {
      div(class: "relative aspect-[2/3] overflow-hidden rounded-xl bg-zinc-900 transition duration-300") {
        img(
          alt: show.title,
          class: "h-full w-full object-cover transition duration-500 group-hover:scale-105",
          loading: "lazy",
          src: show.metadata.posterURL
        )

        span(class: "absolute left-2 top-2 rounded-md bg-black/70 px-2 py-0.5 text-xs font-semibold tabular-nums text-zinc-300 backdrop-blur-sm") {
          "#\(show.metadata.position)"
        }

        span(class: "absolute right-2 top-2 rounded-md bg-accent px-2 py-0.5 text-xs font-bold tabular-nums text-black") {
          "\(show.metadata.rating)/10"
        }
      }

      h2(class: "mt-3 text-sm font-semibold leading-snug text-zinc-100 transition group-hover:text-white") {
        show.title
      }

      p(class: "mt-0.5 text-xs text-white/80") {
        show.metadata.genres.prefix(2).joined(separator: ", ")
      }

//      if !show.metadata.description.isEmpty {
//        p(class: "mt-2 text-xs leading-relaxed text-zinc-400") {
//          show.metadata.description
//        }
//      }
    }
  }
}
