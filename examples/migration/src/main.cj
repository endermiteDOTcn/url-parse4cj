package url_parse_migration

import url_parse.*

main() {
    // const url = parse('../users?id=42', 'https://api.example.com/v1/items', true)
    let url = parse("../users?id=42", "https://api.example.com/v1/items", parseQuery: true)
    println(url.href)
    println(url.query["id"].getOrDefault({=> ""}))

    // url.set('hostname', 'mirror.example.com').set('port', '8443')
    url.set("hostname", "mirror.example.com").set("port", "8443")
    println(url.origin)

    // url.set('query', {page: '2', limit: '20'})
    url.set("query", Query([("page", "2"), ("limit", "20")]))
    println(url.toString())

    // parse('/search?q=cangjie', base, query => ({raw: query}))
    let custom = parse("/search?q=cangjie", "https://example.com/", {query: String => Query([("raw", query)])})
    println(custom.query["raw"].getOrDefault({=> ""}))
    println(custom.toString({_: Query => "q=custom"}))

    // set(..., parser) returns a result with the callback's query type.
    let typed = url.set("query", "token=123", {query: String => query})
    println(typed.query)
}
