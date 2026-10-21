package url_parse

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.*

@Test
class UrlParseTest {
    @TestCase
    func parseFields(): Unit {
        let url = parse("HTTPS://User:p%40ss@EXAMPLE.com:443/Path?a=b#fragment", true)
        @Expect(url.protocol, "https:")
        @Expect(url.host, "example.com")
        @Expect(url.port, "")
        @Expect(url.username, "User")
        @Expect(url.password, "p%40ss")
        @Expect(url.query["a"], Some("b"))
        @Expect(url.href, "https://User:p%40ss@example.com/Path?a=b#fragment")
        @Expect(url.origin, "https://example.com")
    }

    @TestCase
    func resolveRelative(): Unit {
        @Expect(parse("../c", "https://example.com/a/b").href, "https://example.com/c")
        @Expect(parse("?new=1", "http://u:p@example.com:808/a/b?old=1#old").href,
            "http://example.com:808/a/b?new=1")
        @Expect(parse("//other/path", "https://base/a").href, "https://other/path")
        @Expect(parse("/foo", parse("http://google.com")).href, "http://google.com/foo")
    }

    @TestCase
    func setFields(): Unit {
        let url = parse("http://example.com/", true)
        let result = url.set("hostname", "OTHER.com").set("port", 8080).set("pathname", "a").set("hash", "b")
        @Expect(result.href, "http://other.com:8080/a#b")
        @Expect(url.origin, "http://other.com:8080")
        url.set("port", 80)
        @Expect(url.host, "other.com")
        url.set("query", "x=1&x=2")
        @Expect(url.query["x"], Some("1"))
        url.set("query", Query([("y", "2")]))
        @Expect(url.href, "http://other.com/a?y=2#b")
    }

    @TestCase
    func authentication(): Unit {
        let url = parse("https://u:p@example.com")
        url.set("auth", "next")
        @Expect(url.auth, "next:p")
        url.set("username", "a@b")
        @Expect(url.username, "a%40b")
        url.set("auth", "a%40b:c:d")
        @Expect(url.password, "c%3Ad")
    }

    @TestCase
    func queryConversion(): Unit {
        let query = Url.qs.parse("?a=b+c&a=second&__proto__=x&toString=y&bad=%FF&good=%E4%B8%AD&2=b&1=a")
        @Expect(query["a"], Some("b c"))
        @Expect(query["good"], Some("中"))
        @Expect(query.contains("bad"), false)
        @Expect(query.contains("__proto__"), false)
        @Expect(Url.qs.stringify(query), "1=a&2=b&a=b%20c&good=%E4%B8%AD")
        @Expect(Url.qs.stringify(Query([("a", "b")]), true), "?a=b")
        let url = parse("http://host/?a=b")
        var threw = false
        try {
            url.set("query", "x=1", true)
        } catch (_: IllegalArgumentException) {
            threw = true
        }
        @Expect(threw, true)
        @Expect(url.href, "http://host/?a=b")
    }

    @TestCase
    func rawQueryAndDirectMutation(): Unit {
        let raw = parse("http://example.com/?a=b+c")
        @Expect(raw.query.isParsed, false)
        @Expect(raw.query.rawText, "?a=b+c")
        @Expect(raw.toString({_: Query => "changed"}), "http://example.com/?a=b+c")
        raw.protocol = "https"
        @Expect(raw.toString(), "https://example.com/?a=b+c")
        @Expect(raw.href, "http://example.com/?a=b+c")
        raw.set("query", "x=1")
        @Expect(raw.query.isParsed, true)
    }

    @TestCase
    func customParser(): Unit {
        let custom = parse("http://example.com/?x=1", {_: String => "1337"})
        @Expect(custom.query, "1337")
        @Expect(custom.href, "http://example.com/?1337")
        let count = parse("http://example.com/?a=b", {query: String => query.size}, {count: Int64 => count.toString()})
        @Expect(count.query, 4)
        @Expect(count.toString({_: Int64 => "custom"}), "http://example.com/?custom")
        let values = parse("http://example.com/?a=b", {_: String => HashSet<Int64>([1])})
        @Expect(values.query.contains(1), true)
        @Expect(values.href, "http://example.com/")
        let original = parse("http://example.com/?x=1", true)
        let changed = original.set("query", "a=b", {_: String => "1337"})
        @Expect(changed.query, "1337")
        @Expect(original.query.rawText, "1337")
        @Expect(original.href, "http://example.com/?1337")
        @Expect(original.toString(), changed.toString())
        changed.set("hostname", "other.com")
        @Expect(original.host, "other.com")
    }

    @TestCase
    func helpersAndBlob(): Unit {
        let protocol = Url.extractProtocol("\u{000B}jav\nascript://foo\t")
        @Expect(protocol.protocol, "javascript:")
        @Expect(protocol.rest, "foo")
        @Expect(protocol.slashesCount, 2)
        @Expect(Url.trimLeft("\u{0000}\u{FEFF}  url"), "url")
        let blob = Location(protocol: "blob:", pathname: "https%3A//example.com/a/b")
        @Expect(parse("/next", blob).href, "https://example.com/next")
    }

    @TestCase
    func fileAndEmptyAuthority(): Unit {
        @Expect(parse("file:///C:/a").href, "file:///C:/a")
        @Expect(parse("http://@/127.0.0.1").href, "http://@/127.0.0.1")
        @Expect(parse("http://example.com::").href, "http://example.com::/")
        @Expect(parse("mailto:user@example.com").pathname, "user@example.com")
        @Expect(parse("ht\u{2028}tp://host/a").pathname, "ht")
        @Expect(parse("ht\u{2029}tp://host/a").pathname, "ht")
    }
}
