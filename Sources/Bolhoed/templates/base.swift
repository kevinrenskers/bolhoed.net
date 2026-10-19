import Foundation
import HTML
import Saga
import SagaSwimRenderer

enum Section: String, CaseIterable, Codable {
  case home
  case blog
  case games
  case shows
  case movies
  case albums
  
  var title: String {
    switch self {
      case .home: "Home"
      case .blog: "Blog"
      case .games: "Games"
      case .shows: "TV shows"
      case .movies: "Movies"
      case .albums: "Albums"
    }
  }

  var path: String {
    switch self {
      case .home: "/"
      case .blog: "/blog/"
      case .games: "/games/"
      case .shows: "/shows/"
      case .movies: "/movies/"
      case .albums: "/albums/"
    }
  }
}

func baseHtml(title pageTitle: String, section: Section?, @NodeBuilder children: () -> NodeConvertible) -> Node {
  return [
    .documentType("html"),
    html(lang: "en-US") {
      head {
        meta(charset: "utf-8")
        meta(content: "width=device-width, initial-scale=1", name: "viewport")
        title { pageTitle }
        link(href: Saga.hashed("/static/output.css"), rel: "stylesheet")
        link(href: "/apple-touch-icon.png", rel: "apple-touch-icon", sizes: "180x180")
        link(href: "/favicon-32x32.png", rel: "icon", sizes: "32x32", type: "image/png")
        link(href: "/favicon-16x16.png", rel: "icon", sizes: "16x16", type: "image/png")
        link(href: "/site.webmanifest", rel: "manifest")
        link(color: "#3a677d", href: "/safari-pinned-tab.svg", rel: "mask-icon")
        meta(content: "#3a677d", name: "msapplication-TileColor")
        meta(content: "#294858", name: "theme-color")
        meta(content: "https://www.bolhoed.net/static/opengraph.png", customAttributes: ["property": "og:image"])
        meta(content: "1200", customAttributes: ["property": "og:image:width"])
        meta(content: "630", customAttributes: ["property": "og:image:height"])
        if !Saga.isDev {
          script(defer: true, src: "/script.js", customAttributes: ["data-website-id": "dacace94-20ac-45f3-96f9-2d35b19d665e"])
        }
      }
      body(class: "bg-[#3a677d] flex min-h-screen flex-col text-zinc-100 antialiased \(section?.rawValue ?? "")") {
        nav(class: "sticky top-0 z-50 border-b border-white/20 md:backdrop-blur-md bg-[#294858] md:bg-black/30") {
          div(class: "relative mx-auto flex max-w-6xl items-center px-6 py-4 text-sm") {
            input(class: "peer sr-only", id: "nav-toggle", type: "checkbox")

            label(
              class: "-m-2 cursor-pointer p-2 text-white transition peer-focus-visible:text-accent hover:text-accent md:hidden peer-checked:hidden",
              for: "nav-toggle",
              customAttributes: ["aria-label": "Open menu"]
            ) {
              Node.raw(#"<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" viewBox="0 0 24 24"><path d="M3 6h18M3 12h18M3 18h18"/></svg>"#)
            }

            label(
              class: "-m-2 hidden cursor-pointer p-2 text-white transition peer-focus-visible:text-accent hover:text-accent peer-checked:max-md:block",
              for: "nav-toggle",
              customAttributes: ["aria-label": "Close menu"]
            ) {
              Node.raw(#"<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg>"#)
            }

            div(
              class: [
                "hidden md:flex md:items-center md:gap-8",
                "max-md:absolute max-md:top-full max-md:right-0 max-md:left-0 max-md:flex-col max-md:gap-4 max-md:border-b max-md:border-white/20 max-md:bg-[#294858] max-md:px-6 max-md:py-4",
                "peer-checked:max-md:flex",
              ].joined(separator: " ")
            ) {
              Section.allCases
                .enumerated()
                .flatMap { index, favorite -> [Node] in
                  let link = navLink(favorite, currentSection: section)
                  guard index > 0 else { return [link] }
                  return [span(class: "text-white/40 max-md:hidden") { "/" }, link]
                }
            }
          }
        }

        main(class: "mx-auto flex w-full max-w-6xl flex-1 flex-col px-6 py-12") {
          children()
        }
      }
    }
  ]
}

private func navLink(_ section: Section, currentSection: Section?) -> Node {
  a(
    class: section == currentSection
      ? "font-medium text-accent"
      : "text-white transition hover:text-accent",
    href: section.path
  ) {
    section.title
  }
}
