import Foundation
import HTML
import Saga
import SagaSwimRenderer

func renderShows(context: ItemsRenderingContext<ImdbMetadata>) -> Node {
  baseHtml(title: "Bolhoed.net | My favorite TV Shows", section: .shows) {
    header(class: "page-header") {
      h1 {
        "My favorite TV Shows"
      }
      p {
        "\(context.items.count) shows, ranked"
      }
    }

    ul(class: "grid grid-cols-2 gap-8 lg:gap-12 md:grid-cols-3 lg:grid-cols-4") {
      context.items.map(showCard)
    }
    
    if Saga.isDev {
      script(src: "/static/enhance.js")
      Node.raw("<script>enhance('shows');</script>")
    }
  }
}

func renderMovies(context: ItemsRenderingContext<ImdbMetadata>) -> Node {
  baseHtml(title: "Bolhoed.net | My favorite movies", section: .movies) {
    header(class: "page-header") {
      h1 {
        "My favorite movies"
      }
      p {
        "\(context.items.count) movies, ranked"
      }
    }

    ul(class: "grid grid-cols-2 gap-8 lg:gap-12 md:grid-cols-3 lg:grid-cols-4") {
      context.items.map(showCard)
    }
    
    if Saga.isDev {
      script(src: "/static/enhance.js")
      Node.raw("<script>enhance('movies');</script>")
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

      h2(class: "mt-3 text-sm font-semibold leading-snug transition") {
        show.title
      }

      p(class: "mt-0.5 text-xs text-textfg/80") {
        show.metadata.genres.prefix(2).joined(separator: ", ")
      }
    }
  }
}
