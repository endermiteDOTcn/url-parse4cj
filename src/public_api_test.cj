package url_parse4cj

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
class PublicApiTest {
    @TestCase
    func constructorsAndBaseOverloads(): Unit {
        @Expect(Url().href, "")
        @Expect(parse().href, "")
        @Expect(Url("https://host/?x=1", false).query.rawText, "?x=1")
        let base = Url.location("https://host/a/b")
        for (url in [Url("../child?x=1", "https://host/a/b", parseQuery: true),
                Url("../child?x=1", base, parseQuery: true)]) {
            @Expect(url.href, "https://host/child?x=1")
            @Expect(url.query["x"], Some("1"))
        }
        @Expect(parse("../child?x=1", "https://host/a/b", {_: String => "token=1"}).href,
            "https://host/child?token=1")
        @Expect(parse("../child?x=1", base, {_: String => "token=1"}).href,
            "https://host/child?token=1")
        let extracted = Url.extractProtocol("//next/path", base)
        @Expect(extracted.protocol, "")
        @Expect(extracted.slashes, true)
        @Expect(extracted.slashesCount, 2)
        @Expect(extracted.rest, "next/path")
    }

    @TestCase
    func typedCollectionsAndSerializerDispatch(): Unit {
        let raw = parse("https://host/?x=1", {_: String => "token=1"})
        let calls = ArrayList<String>()
        @Expect(raw.toString({text: String => calls.add(text); "ignored"}), "https://host/?token=1")
        @Expect(calls.size, 0)
        let array = parse("https://host/", {_: String => ["x y", "z"]})
        @Expect(array.href, "https://host/?0=x%20y&1=z")
        @Expect(array.toString({_: Array<String> => "override"}), "https://host/?override")
        let map = parse("https://host/", {_: String => HashMap<String, String>([("q", "x y")])})
        @Expect(map.href, "https://host/?q=x%20y")
        let optional = parse("https://host/", {_: String => HashMap<String, ?String>([("q", None)])})
        @Expect(optional.href, "https://host/?q=")
    }

    @TestCase
    func emptyQueryAndNonQuerySetterDoNotCallParser(): Unit {
        let calls = ArrayList<String>()
        let original = parse("https://host/?q=1", {_: String => "token=1"})
        let cleared = original.set("query", "", {text: String => calls.add(text); "ignored"})
        @Expect(calls.size, 0)
        @Expect(cleared.query, "")
        @Expect(original.query, "")
        @Expect(original.href, "https://host/")
        let protocol = parse("http://host/?q=1").set("protocol", "mailto",
            {text: String => calls.add(text); "ignored"})
        @Expect(calls.size, 0)
        @Expect(protocol.href, "mailto:host/?q=1")
        @Expect(protocol.slashes, false)
        @Expect(protocol.query, "?q=1")
    }

    @TestCase
    func typedAliasesRequireTheReturnedQueryType(): Unit {
        let original = parse("https://host/", {_: String => 1i64}, {value: Int64 => "page=" + value.toString()})
        let changed = original.set("query", "x=1", {_: String => "replacement"})
        @Expect(changed.query, "replacement")
        @Expect(original.href, "https://host/?replacement")
        @Expect(original.href, changed.href)
        var wrongView = false
        try {
            original.query
        } catch (_: IllegalArgumentException) {
            wrongView = true
        }
        @Expect(wrongView, true)
        var wrongValue = false
        try {
            changed.set("query", Query([("x", "2")]))
        } catch (_: IllegalArgumentException) {
            wrongValue = true
        }
        @Expect(wrongValue, true)
        @Expect(changed.query, "replacement")
        @Expect(changed.href, "https://host/?replacement")
        changed.set("hostname", "next")
        @Expect(original.href, "https://next/?replacement")
    }

    @TestCase
    func linkedHostAndPasswordSetters(): Unit {
        let url = parse("http://host:81/a")
        url.set("hostname", "NEXT")
        @Expect(url.host, "next:81")
        url.set("host", "else:82")
        @Expect(url.hostname, "else")
        @Expect(url.port, "82")
        url.set("host", "plain")
        @Expect(url.port, "")
        url.set("password", "a@b")
        @Expect(url.href, "http://:a%40b@plain/a")
        url.set("slashes", false)
        @Expect(url.slashes, true)
        @Expect(url.href, "http://:a%40b@plain/a")
    }

    @TestCase
    func directAssignmentsKeepCachedFieldsUntilSet(): Unit {
        let url = parse("http://u:p@host:81/a?x=1#old")
        url.auth = "stale"
        url.hash = "new"
        url.host = "else:82"
        url.hostname = "other"
        url.href = "manual"
        url.origin = "manual-origin"
        url.password = "secret"
        url.pathname = "b"
        url.port = "83"
        url.protocol = "https"
        url.slashes = false
        url.username = "name"
        url.query = Query.raw("q=2")
        @Expect(url.href, "manual")
        @Expect(url.origin, "manual-origin")
        @Expect(url.auth, "stale")
        @Expect(url.hash, "new")
        @Expect(url.hostname, "other")
        @Expect(url.toString(), "https://name:secret@else:82b?q=2new")
    }

    @TestCase
    func queryMetadataOrderingAndPrefix(): Unit {
        let query = Query([("1x", "odd"), ("0", "zero")])
        query.set("missing", None)
        @Expect(query.count, 3)
        @Expect(query.get("absent"), None)
        @Expect(Url.qs.stringify(query, "#"), "#0=zero&1x=odd&missing=")
        @Expect(Url.qs.parse("&&?=").count, 0)
        @Expect(QueryString.stringify(Query(), true), "")
    }

    @TestCase
    func blobUnicodeAndRelativeDotPaths(): Unit {
        let blob = Location(protocol: "blob:", pathname: "https%3A//host/%u4e2d/%uD83D%uDE00/é中😀")
        @Expect(Url.location(blob).pathname, "/中/😀/é中😀")
        @Expect(parse(".", "https://host/a/b").href, "https://host/a/")
        @Expect(parse("..", "https://host/a/b").href, "https://host/")
        @Expect(parse("../../../child", "https://host/a/b").href, "https://host/child")
    }

    @TestCase
    func malformedAuthenticationThrowsAndInvalidQueryPairsAreOmitted(): Unit {
        for (value in ["%", "%a", "%e4%xx", "%C0%80", "%ED%A0%80", "%F4%90%80%80"]) {
            var threw = false
            try {
                parse("https://" + value + "@host/")
            } catch (_: Exception) {
                threw = true
            }
            @Expect(threw, true)
            let query = Url.qs.parse("bad=" + value + "&ok=%e4%b8%ad")
            @Expect(query.contains("bad"), false)
            @Expect(query["ok"], Some("中"))
        }
    }
}
