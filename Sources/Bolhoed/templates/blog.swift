import Saga
import HTML
import Foundation

extension Date {
  func formatted(_ format: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: self)
  }
}

func renderArticles(context: ItemsRenderingContext<ArticleMetadata>) -> Node {
  renderArticleList(context.items, allItems: context.allItems, currentTag: nil)
}

func renderTag(context: PartitionedRenderingContext<String, ArticleMetadata>) -> Node {
  renderArticleList(context.items, allItems: context.allItems, currentTag: context.key)
}

private func renderArticleList(_ articles: [Item<ArticleMetadata>], allItems: [AnyItem], currentTag: String?) -> Node {
  let allArticles = allItems.compactMap { $0 as? Item<ArticleMetadata> }
  let tags = tagsWithCounts(allArticles)

  return baseHtml(title: currentTag.map { "Bolhoed.net | Blog | \($0)" } ?? "Bolhoed.net | Blog", section: .blog) {
    // Same grid as the article page, with the list in the text column so nothing shifts when you open an article
    div(class: "article-grid") {
      aside(class: "max-lg:hidden") {
        nav(class: "sticky top-24 text-sm", customAttributes: ["aria-label": "Tags"]) {
          p(class: "mb-4 text-xs uppercase tracking-wide text-textfg/60") { "Tags" }
          ul(class: "flex flex-col gap-2") {
            li { tagLink("All articles (\(allArticles.count))", href: "/blog/", isCurrent: currentTag == nil) }
            tags.map { tag, count in
              li { tagLink("\(tag) (\(count))", href: "/blog/tag/\(tag.slugified)/", isCurrent: tag == currentTag) }
            }
          }
        }
      }

      div {
        header(class: "page-header") {
          h1 {
            "Blog"
          }
          div(class: "mt-4 flex flex-wrap gap-x-4 gap-y-2 text-sm lg:hidden") {
            tagLink("All (\(allArticles.count))", href: "/blog/", isCurrent: currentTag == nil)
            tags.map { tag, count in
              tagLink("\(tag) (\(count))", href: "/blog/tag/\(tag.slugified)/", isCurrent: tag == currentTag)
            }
          }
        }

        div(class: "prose") {
          articles.map(articleSummary)
        }
      }
    }
  }
}

private func tagsWithCounts(_ articles: [Item<ArticleMetadata>]) -> [(String, Int)] {
  articles
    .flatMap(\.tags)
    .reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
    .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
    .map { ($0.key, $0.value) }
}

private func tagSeparator(index: Int, totalTags: Int) -> Node {
  if index == 0 {
    return ""
  }
  if index == totalTags - 1 {
    return totalTags > 2 ? ", and " : " and "
  }
  return ", "
}

private func tagLink(_ title: String, href: String, isCurrent: Bool) -> Node {
  a(class: isCurrent ? "text-accent" : "text-textfg/80 hover:text-accent", href: href) { title }
}

@NodeBuilder
private func articleSummary(_ article: Item<ArticleMetadata>) -> Node {
  h2(class: "mb-0!") {
    a(class: "text-2xl", href: article.url) { article.title }
  }
  div(class: "text-sm text-textfg/80") {
    article.date.formatted("MMMM dd, yyyy")
  }
  p(class: "mt-2!") { a(class: "no-underline! hover:text-textfg!", href: article.url) { article.metadata.summary } }
}

func renderArticle(context: ItemRenderingContext<ArticleMetadata>) -> Node {
  let date = context.item.date.formatted("MMMM dd, yyyy")
  let toc = context.item.metadata.toc
  let tags = context.item.tags

  return baseHtml(title: "Bolhoed.net | \(context.item.title)", section: .blog) {
    div(class: "article-grid") {
      aside(class: "max-lg:hidden") {
        div(class: "sticky top-24 flex max-h-[calc(100vh-7rem)] flex-col gap-8 overflow-y-auto text-sm") {
          if let toc {
            nav(class: "article-toc", customAttributes: ["aria-label": "Contents"]) {
              p(class: "mb-4 text-xs uppercase tracking-wide text-textfg/60") { "Contents" }
              Node.raw(toc)
            }
          }

          if !tags.isEmpty {
            nav(customAttributes: ["aria-label": "Tags"]) {
              p(class: "mb-4 text-xs uppercase tracking-wide text-textfg/60") { "Tags" }
              ul(class: "flex flex-col gap-2") {
                tags.map { tag in
                  li { tagLink(tag, href: "/blog/tag/\(tag.slugified)/", isCurrent: false) }
                }
              }
            }
          }

          p(class: "text-textfg/60") { date }
        }
      }

      article {
        header(class: "page-header") {
          h1 { context.item.title }
          p(class: "lg:hidden") {
            "Posted on"
            date
            if !tags.isEmpty {
              "in "
              tags.enumerated().map { index, tag in
                Node.fragment([
                  %tagSeparator(index: index, totalTags: tags.count),
                  %tagLink(tag, href: "/blog/tag/\(tag.slugified)/", isCurrent: false),
                ])
              }
            }
          }
          if let toc {
            details(class: "article-toc group mt-4 lg:hidden") {
              summary(class: "flex cursor-pointer list-none items-center gap-1.5 text-textfg/80 [&::-webkit-details-marker]:hidden") {
                Node.raw(#"<svg class="h-3.5 w-3.5 group-open:rotate-90" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M9 6l6 6-6 6"/></svg>"#)
                "Contents"
              }
              div(class: "mt-3") { Node.raw(toc) }
            }
          }
        }
        div(class: "prose") {
          Node.raw(context.item.body)
        }
      }
    }
  }
}
