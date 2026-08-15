import Foundation
import HTML
import Saga
import SagaSwimRenderer

func renderGames(context: ItemsRenderingContext<GameMetadata>) -> Node {
  baseHtml(title: "My favorite games", section: .games) {
    main(class: "mx-auto max-w-6xl px-6 py-12") {
      header(class: "mb-12 border-b border-white/10 pb-8") {
        h1 {
          "My favorite games"
        }
        p(class: "mt-4 max-w-2xl text-white/80") {
          "\(context.items.count) games, ranked"
        }
      }

      ul(class: "grid grid-cols-2 gap-x-5 gap-y-10 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5") {
        context.items.map(gameCard)
      }
    }
  }
}

private func gameCard(_ game: Item<GameMetadata>) -> Node {
  li {
    a(class: "group block", href: "https://store.steampowered.com/app/\(game.metadata.id)/", target: "_blank") {
      div(class: "relative aspect-[2/3] overflow-hidden rounded-xl bg-zinc-900 transition duration-300") {
        // Wide fallback art gets cropped to a 2:3 slice by object-cover. Steam puts the logo
        // on the left of those, so crop from there instead of the middle.
        img(
          alt: game.title,
          class: "absolute inset-0 h-full w-full object-cover object-left transition duration-500 group-hover:scale-105",
          loading: "lazy",
          src: game.metadata.posterURL
        )

        span(class: "absolute left-2 top-2 z-10 rounded-md bg-black/70 px-2 py-0.5 text-xs font-semibold tabular-nums text-zinc-300 backdrop-blur-sm") {
          "#\(game.metadata.position)"
        }
      }

      h2(class: "mt-3 text-sm font-semibold leading-snug text-zinc-100 transition group-hover:text-white") {
        game.title
      }
    }
  }
}
