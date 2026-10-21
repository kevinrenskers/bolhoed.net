import Foundation
import HTML
import Saga
import SagaSwimRenderer

enum Section: String, CaseIterable, Codable {
  case home
  case blog
  case photos
  case games
  case shows
  case movies
  case albums
  
  var title: String {
    switch self {
      case .home: "Home"
      case .blog: "Blog"
      case .photos: "Photos"
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
      case .photos: "/photos/"
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
    html(class: "font-main lg:text-lg", lang: "en-US") {
      head {
        meta(charset: "utf-8")
        meta(content: "width=device-width, initial-scale=1", name: "viewport")
        title { pageTitle }
        link(href: Saga.hashed("/static/output.css"), rel: "stylesheet")
        style {
          Node.raw("""
          @font-face {
            font-family: "Title Serif";
            src: url(/static/fonts/title.woff2) format("woff2");
            font-style: normal;
            font-weight: 100 900;
            font-display: swap;
          }
          @font-face {
            font-family: "Main Sans";
            src: url(/static/fonts/main.woff2) format("woff2");
            font-style: normal;
            font-weight: 400 700;
            font-display: swap;
          }
          """)
        }

        link(href: "/blog/feed.xml", rel: "alternate", title: SiteMetadata.name, type: "application/atom+xml")

        link(href: "/favicon-96x96.png", rel: "icon", sizes: "96x96", type: "image/png")
        link(href: "/favicon.svg", rel: "icon", type: "image/svg+xml")
        link(href: "/favicon.ico", rel: "shortcut icon")
        link(href: "/apple-touch-icon.png", rel: "apple-touch-icon", sizes: "180x180")
        meta(content: "Bolhoed.net", name: "apple-mobile-web-app-title")
        link(href: "/site.webmanifest", rel: "manifest")

        meta(content: "https://www.bolhoed.net/static/opengraph.png", customAttributes: ["property": "og:image"])
        meta(content: "1200", customAttributes: ["property": "og:image:width"])
        meta(content: "630", customAttributes: ["property": "og:image:height"])

        if !Saga.isDev {
          script(defer: true, src: "/script.js", customAttributes: ["data-website-id": "dacace94-20ac-45f3-96f9-2d35b19d665e"])
        }
      }
      body(class: "bg-bodybg flex min-h-screen flex-col text-textfg antialiased \(section?.rawValue ?? "")") {
        nav(class: "sticky -top-12 z-50 border-b border-transparent bg-bodybg sticky-nav-border") {
          div(class: "relative container flex items-center pt-16 pb-4 text-sm") {
            a(class: "text-textfg hover:text-accent", href: Section.home.path, title: Section.home.title) {
              if section == .home {
                span(class: "font-title text-2xl font-bold") { "Bolhoed" }
              } else {
                Node.raw(#"<svg class="h-7 w-auto" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="15 130 770 535"><path transform="translate(0,800) scale(0.1,-0.1)" d="M3645 6623 c-611 -13 -1176 -127 -1541 -311 -191 -96 -371 -244 -442 -365 -169 -284 -275 -808 -312 -1547 -5 -107 -10 -239 -10 -293 0 -108 -8 -133 -62 -184 -87 -83 -193 -101 -521 -85 -281 14 -338 8 -444 -43 -207 -101 -240 -290 -80 -448 58 -56 142 -108 367 -227 875 -465 1751 -826 3190 -1319 640 -219 976 -298 1535 -363 70 -8 243 -13 475 -13 298 0 390 3 500 18 713 97 1190 346 1436 752 169 277 186 570 48 835 -59 114 -123 197 -235 305 -117 112 -238 203 -395 295 -95 56 -317 166 -368 183 -5 2 1 68 13 147 43 294 58 593 42 823 -25 347 -90 595 -210 802 -129 224 -555 548 -951 726 -502 225 -1190 330 -2035 312z"/></svg>"#)
              }
            }

            input(class: "peer sr-only", id: "nav-toggle", type: "checkbox")

            label(
              class: "-m-2 ml-auto cursor-pointer p-2 text-textfg peer-focus-visible:text-accent hover:text-accent md:hidden peer-checked:hidden",
              for: "nav-toggle",
              customAttributes: ["aria-label": "Open menu"]
            ) {
              Node.raw(#"<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" viewBox="0 0 24 24"><path d="M3 6h18M3 12h18M3 18h18"/></svg>"#)
            }

            label(
              class: "-m-2 ml-auto hidden cursor-pointer p-2 text-textfg peer-focus-visible:text-accent hover:text-accent peer-checked:max-md:block",
              for: "nav-toggle",
              customAttributes: ["aria-label": "Close menu"]
            ) {
              Node.raw(#"<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg>"#)
            }

            div(
              class: "hidden md:ml-auto md:flex md:items-center gap-4 md:gap-8 max-md:absolute max-md:top-full max-md:right-0 max-md:left-0 max-md:flex-col max-md:border-b max-md:border-black max-md:bg-bodybg max-md:px-6 max-md:py-4 peer-checked:max-md:flex"
            ) {
              Section.allCases
                .filter { $0 != .home }
                .map { navLink($0, currentSection: section) }

              a(class: "text-textfg hover:text-accent", href: "/blog/feed.xml", title: "RSS feed") {
                Node.raw(#"<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24"><path d="M3 17a4 4 0 0 1 4 4H3zm0-7c6.075 0 11 4.925 11 11h-2a9 9 0 0 0-9-9zm0-7c9.941 0 18 8.059 18 18h-2c0-8.837-7.163-16-16-16z"/></svg>"#)
              }
            }
          }
        }

        main(class: "container flex flex-1 flex-col py-8 md:py-16") {
          children()
        }

        if section != .home {
          footer(class: "container flex justify-center gap-2 py-8 text-sm text-textfg/60 links") {
            p { "© \(Calendar.current.component(.year, from: SiteMetadata.now)) Kevin Renskers" }
            a(href: "/legal/") { "legal notice" }
          }
        }
      }
    }
  ]
}

private func navLink(_ section: Section, currentSection: Section?) -> Node {
  a(
    class: section == currentSection
      ? "font-medium text-accent"
      : "text-textfg hover:text-accent",
    href: section.path
  ) {
    section.title
  }
}
