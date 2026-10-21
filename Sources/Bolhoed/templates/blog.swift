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
  baseHtml(title: "Bolhoed.net | Blog", section: .blog) {
    header(class: "page-header") {
      h1 {
        "Blog"
      }
      p {
        "\(context.items.count) \(context.items.count == 1 ? "article" : "articles")"
      }
    }
    
    div(class: "prose") {
      context.items.map(articleSummary)
    }
  }
}

@NodeBuilder
private func articleSummary(_ article: Item<ArticleMetadata>) -> Node {
  h2 {
    a(class: "text-2xl", href: article.url) { article.title }
  }
  p(class: "text-sm text-white/80 mb-2") {
    article.date.formatted("MMMM dd, yyyy")
  }
  p { article.metadata.summary }
}

func renderArticle(context: ItemRenderingContext<ArticleMetadata>) -> Node {
  baseHtml(title: "Bolhoed.net | \(context.item.title)", section: .blog) {
    article {
      header(class: "page-header") {
        h1 { context.item.title }
        p {
          "Posted on"
          context.item.date.formatted("MMMM dd, yyyy")
        }
      }
      div(class: "prose") {
        Node.raw(context.item.body)
      }
    }
  }
}
