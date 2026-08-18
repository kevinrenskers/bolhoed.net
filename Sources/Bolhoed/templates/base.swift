import Foundation
import HTML
import Saga
import SagaSwimRenderer

enum Section: CaseIterable {
  case home
  case games
  case shows
  case movies
  case albums

  var title: String {
    switch self {
      case .home: "Home"
      case .games: "Games"
      case .shows: "TV shows"
      case .movies: "Movies"
      case .albums: "Albums"
    }
  }

  var path: String {
    switch self {
      case .home: "/"
      case .games: "/games/"
      case .shows: "/shows/"
      case .movies: "/movies/"
      case .albums: "/albums/"
    }
  }
}

func baseHtml(title pageTitle: String, section: Section, @NodeBuilder children: () -> NodeConvertible) -> Node {
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
        if !Saga.isDev {
          script(defer: true, src: "/script.js", customAttributes: ["data-website-id": "dacace94-20ac-45f3-96f9-2d35b19d665e"])
        }
      }
      body(class: "bg-[#3a677d] flex min-h-screen flex-col text-zinc-100 antialiased \(section)") {
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

        children()
      }
    }
  ]
}

private func navLink(_ section: Section, currentSection: Section) -> Node {
  a(
    class: section == currentSection
      ? "font-medium text-accent"
      : "text-white transition hover:text-accent",
    href: section.path
  ) {
    section.title
  }
}

func renderPage(context: ItemRenderingContext<EmptyMetadata>) -> Node {
  baseHtml(title: "Bolhoed.net", section: .home) {
    main(class: "px-6 py-12 md:mt-auto md:mr-12 md:mb-12 md:ml-auto md:max-w-xl md:rounded-2xl md:border-4 md:border-white/20 md:bg-black/30 md:p-10 md:shadow-2xl md:backdrop-blur-md") {
      article(class: "[&_a]:text-white [&_a]:underline [&_a]:underline-offset-2 [&_a:hover]:text-accent [&_h1]:mb-6 [&_p]:mt-4") {
        h1 { context.item.title }
        Node.raw(context.item.body)
      }

      div(class: "mt-8 flex gap-4 [&_a]:block [&_a]:h-6 [&_a]:w-6 [&_a]:text-white [&_a]:transition [&_a:hover]:text-accent md:[&_a]:h-7 md:[&_a]:w-7") {
        a(href: "mailto:kevin@bolhoed.net", title: "Email") {
          Node.raw(#"<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 512 512"><path d="M256 48C141.1 48 48 141.1 48 256s93.1 208 208 208h32v48H256C114.6 512 0 397.4 0 256S114.6 0 256 0S512 114.6 512 256v96 24H488 440c-36.9 0-69.6-17.8-90-45.4c-22 27.6-55.9 45.4-94 45.4c-66.3 0-120-53.7-120-120s53.7-120 120-120c27 0 51.9 8.9 72 24v-8h48v24 80 8c0 35.3 28.7 64 64 64h24V256c0-114.9-93.1-208-208-208zm72 208a72 72 0 1 0 -144 0 72 72 0 1 0 144 0z"/></svg>"#)
        }

        a(href: "https://hachyderm.io/@kevinrenskers", rel: "me", target: "_blank", title: "Mastodon") {
          Node.raw(#"<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 448 512"><path d="M433 179.1c0-97.2-63.7-125.7-63.7-125.7-62.5-28.7-228.6-28.4-290.5 0 0 0-63.7 28.5-63.7 125.7 0 115.7-6.6 259.4 105.6 289.1 40.5 10.7 75.3 13 103.3 11.4 50.8-2.8 79.3-18.1 79.3-18.1l-1.7-36.9s-36.3 11.4-77.1 10.1c-40.4-1.4-83-4.4-89.6-54a102.5 102.5 0 0 1 -.9-13.9c85.6 20.9 158.7 9.1 178.8 6.7 56.1-6.7 105-41.3 111.2-72.9 9.8-49.8 9-121.5 9-121.5zm-75.1 125.2h-46.6v-114.2c0-49.7-64-51.6-64 6.9v62.5h-46.3V197c0-58.5-64-56.6-64-6.9v114.2H90.2c0-122.1-5.2-147.9 18.4-175 25.9-28.9 79.8-30.8 103.8 6.1l11.6 19.5 11.6-19.5c24.1-37.1 78.1-34.8 103.8-6.1 23.7 27.3 18.4 53 18.4 175z"/></svg>"#)
        }

        a(href: "https://www.loopwerk.io", target: "_blank", title: "Loopwerk") {
          Node.raw(#"<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 315 315"><path d="m529 315h-315v-315h143v26h-114v263h258v-79h-173v-131h-28v157h172v26h-201v-209h86v130h172z" transform="translate(-214)"/></svg>"#)
        }

        a(href: "https://github.com/kevinrenskers", target: "_blank", title: "GitHub") {
          Node.raw(#"<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 496 512"><path d="M165.9 397.4c0 2-2.3 3.6-5.2 3.6-3.3 .3-5.6-1.3-5.6-3.6 0-2 2.3-3.6 5.2-3.6 3-.3 5.6 1.3 5.6 3.6zm-31.1-4.5c-.7 2 1.3 4.3 4.3 4.9 2.6 1 5.6 0 6.2-2s-1.3-4.3-4.3-5.2c-2.6-.7-5.5 .3-6.2 2.3zm44.2-1.7c-2.9 .7-4.9 2.6-4.6 4.9 .3 2 2.9 3.3 5.9 2.6 2.9-.7 4.9-2.6 4.6-4.6-.3-1.9-3-3.2-5.9-2.9zM244.8 8C106.1 8 0 113.3 0 252c0 110.9 69.8 205.8 169.5 239.2 12.8 2.3 17.3-5.6 17.3-12.1 0-6.2-.3-40.4-.3-61.4 0 0-70 15-84.7-29.8 0 0-11.4-29.1-27.8-36.6 0 0-22.9-15.7 1.6-15.4 0 0 24.9 2 38.6 25.8 21.9 38.6 58.6 27.5 72.9 20.9 2.3-16 8.8-27.1 16-33.7-55.9-6.2-112.3-14.3-112.3-110.5 0-27.5 7.6-41.3 23.6-58.9-2.6-6.5-11.1-33.3 2.6-67.9 20.9-6.5 69 27 69 27 20-5.6 41.5-8.5 62.8-8.5s42.8 2.9 62.8 8.5c0 0 48.1-33.6 69-27 13.7 34.7 5.2 61.4 2.6 67.9 16 17.7 25.8 31.5 25.8 58.9 0 96.5-58.9 104.2-114.8 110.5 9.2 7.9 17 22.9 17 46.4 0 33.7-.3 75.4-.3 83.6 0 6.5 4.6 14.4 17.3 12.1C428.2 457.8 496 362.9 496 252 496 113.3 383.5 8 244.8 8zM97.2 352.9c-1.3 1-1 3.3 .7 5.2 1.6 1.6 3.9 2.3 5.2 1 1.3-1 1-3.3-.7-5.2-1.6-1.6-3.9-2.3-5.2-1zm-10.8-8.1c-.7 1.3 .3 2.9 2.3 3.9 1.6 1 3.6 .7 4.3-.7 .7-1.3-.3-2.9-2.3-3.9-2-.6-3.6-.3-4.3 .7zm32.4 35.6c-1.6 1.3-1 4.3 1.3 6.2 2.3 2.3 5.2 2.6 6.5 1 1.3-1.3 .7-4.3-1.3-6.2-2.2-2.3-5.2-2.6-6.5-1zm-11.4-14.7c-1.6 1-1.6 3.6 0 5.9s4.3 3.3 5.6 2.3c1.6-1.3 1.6-3.9 0-6.2-1.4-2.3-4-3.3-5.6-2z"/></svg>"#)
        }

        a(href: "https://www.linkedin.com/in/kevinrenskers/", target: "_blank", title: "LinkedIn") {
          Node.raw(#"<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 448 512"><path d="M100.28 448H7.4V148.9h92.88zM53.79 108.1C24.09 108.1 0 83.5 0 53.8a53.79 53.79 0 0 1 107.58 0c0 29.7-24.1 54.3-53.79 54.3zM447.9 448h-92.68V302.4c0-34.7-.7-79.2-48.29-79.2-48.29 0-55.69 37.7-55.69 76.7V448h-92.78V148.9h89.08v40.8h1.3c12.4-23.5 42.69-48.3 87.88-48.3 94 0 111.28 61.9 111.28 142.3V448z"/></svg>"#)
        }

        a(href: "https://glass.photo/kevinrenskers", target: "_blank", title: "Glass") {
          Node.raw(#"<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 88 88"><path fill-rule="evenodd" clip-rule="evenodd" d="M44 0C19.6995 0 0 19.6995 0 44C0 68.3007 19.6995 88 44 88C68.3007 88 88 68.3007 88 44C88 19.6995 68.3007 0 44 0ZM52.0065 69.8208C53.0482 68.1228 53.5764 65.4722 53.5764 61.9432V57.4029C50.8813 59.6505 48.4252 61.8002 46.7579 63.5815C44.6067 65.8792 43.8626 68.396 44.7687 70.3143C45.3384 71.5202 46.5074 72.2405 47.8956 72.2405C49.7612 72.2405 50.9523 71.5391 52.0065 69.8208ZM56.3504 51.5513C58.168 50.0708 60.0475 48.5392 61.7212 47.1254C62.3038 46.6328 63.1776 46.7046 63.6717 47.2859C64.1658 47.8673 64.0943 48.7374 63.5107 49.23C61.8181 50.6608 59.9294 52.1997 58.102 53.6881C57.5171 54.1645 56.9298 54.6433 56.3444 55.1212V61.9432C56.3444 66.0448 55.698 69.0923 54.368 71.2604C52.8032 73.8116 50.7461 75 47.8956 75C45.445 75 43.2869 73.6547 42.2641 71.4899C40.8589 68.5119 41.782 64.8518 44.7341 61.6986C46.8668 59.4205 50.1381 56.6421 53.5764 53.8173V44.404C52.4106 46.3288 51.0538 48.4601 49.9582 49.8771C47.3097 53.304 43.0751 57.8596 36.908 57.8596C29.3081 57.8596 24 50.7505 24 40.572C24 33.7283 25.802 27.5363 29.2117 22.6648C33.3835 16.7033 39.5445 13 45.2895 13C51.9156 13 56.5441 17.7299 56.5441 24.5022C56.5441 30.0898 53.5418 35.2299 48.0893 38.9765C47.4605 39.4093 46.5987 39.2506 46.1651 38.6233C45.731 37.9959 45.8897 37.1368 46.5189 36.7045C51.1987 33.4887 53.7761 29.1548 53.7761 24.5022C53.7761 20.1504 51.1516 15.7595 45.2895 15.7595C40.5087 15.7595 35.0885 19.0898 31.4809 24.2442C28.3979 28.6498 26.768 34.2958 26.768 40.572C26.768 49.2618 30.8429 55.1 36.908 55.1C40.7251 55.1 44.0734 52.9697 47.7659 48.1929C50.0426 45.2471 53.7143 38.6817 53.7512 38.6154C54.0571 38.0663 54.697 37.7931 55.3082 37.9509C55.9181 38.1086 56.3444 38.6578 56.3444 39.2865V51.5559L56.3504 51.5513Z"/></svg>"#)
        }
      }
    }
  }
}
