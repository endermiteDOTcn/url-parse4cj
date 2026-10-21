// Copyright (c) 2015 Unshift.io, Arnout Kazemier, the Contributors.
// Ported to Cangjie in 2026. Licensed under the MIT License.
package url_parse

import requires_port.required
import std.unicode.*
import std.collection.*

class UrlState {
    var auth = ""
    var hash = ""
    var host = ""
    var hostname = ""
    var href = ""
    var origin = "null"
    var password = ""
    var pathname = ""
    var port = ""
    var protocol = ""
    var rawQuery = ""
    var slashes = false
    var username = ""
    var queryData: Any = Query.raw("")
    var queryStringify: () -> String = {=> ""}

    init(address: String, base: Location) {
        let extracted = extractProtocol(address, base)
        let relative = extracted.protocol == "" && !extracted.slashes
        let baseSlashes = base.slashes.getOrDefault({=> false})
        slashes = extracted.slashes || (relative && baseSlashes)
        protocol = if (extracted.protocol != "") {
            extracted.protocol
        } else {
            base.protocol
        }
        var rest = extracted.rest
        let r = rest.toRuneArray()
        let drive = r.size >= 2 && asciiAlpha(r[0]) && r[1] == r':'
        let pathOnly = (extracted.protocol == "file:" && (extracted.slashesCount != 2 || drive)) || (!extracted.slashes &&
            (extracted.protocol != "" || extracted.slashesCount < 2 || !special(protocol)))
        var index = find(rest, r'#')
        if (index >= 0) {
            hash = slice(rest, index, size(rest))
            rest = slice(rest, 0, index)
        }
        index = find(rest, r'?')
        if (index >= 0) {
            rawQuery = slice(rest, index, size(rest))
            rest = slice(rest, 0, index)
        }
        if (special(protocol)) {
            rest = rest.replace("\\", "/")
        }
        if (pathOnly) {
            // The upstream pathname rule uses /(.*)/, whose dot stops at U+2028/U+2029.
            let line = rest.toRuneArray()
            var end = 0
            while (end < line.size && line[end] != r'\u{2028}' && line[end] != r'\u{2029}') {
                end++
            }
            pathname = String(line[..end])
            rest = ""
        } else {
            index = find(rest, r'/')
            if (index >= 0) {
                pathname = slice(rest, index, size(rest))
                rest = slice(rest, 0, index)
            }
        }
        index = find(rest, r'@', last: true)
        if (index >= 0) {
            auth = slice(rest, 0, index)
            rest = slice(rest, index + 1, size(rest))
        }
        host = if (rest != "") {
            rest
        } else if (relative) {
            base.host
        } else {
            ""
        }
        host = host.toLower()
        index = portIndex(rest, allowEmpty: true)
        if (index >= 0) {
            port = slice(rest, index + 1, size(rest))
            rest = slice(rest, 0, index)
        }
        if (port == "" && relative) {
            port = base.port
        }
        hostname = if (rest != "") {
            rest
        } else if (relative) {
            base.hostname
        } else {
            ""
        }
        hostname = hostname.toLower()
        if (relative && baseSlashes && !pathname.startsWith("/") && (pathname != "" || base.pathname != "")) {
            pathname = resolvePath(pathname, base.pathname)
        }
        if (!pathname.startsWith("/") && special(protocol)) {
            pathname = "/" + pathname
        }
        if (!required(port, protocol)) {
            host = hostname
            port = ""
        }
        if (auth != "") {
            setAuth(auth)
        }
        refreshAuthOrigin()
    }

    func setAuth(value: String): Unit {
        let index = find(value, r':')
        if (index >= 0) {
            username = normalizeAuth(slice(value, 0, index))
            password = normalizeAuth(slice(value, index + 1, size(value)))
        } else {
            username = normalizeAuth(value)
        }
    }

    func refreshAuthOrigin(): Unit {
        host = host.toLower()
        hostname = hostname.toLower()
        auth = if (password != "") {
            username + ":" + password
        } else {
            username
        }
        origin = if (protocol != "file:" && special(protocol) && host != "") {
            protocol + "//" + host
        } else {
            "null"
        }
    }

    func change(part: String, value: String, flag: Bool): Unit {
        match (part) {
            case "port" =>
                port = value
                if (!required(value, protocol)) {
                    host = hostname
                    port = ""
                } else if (value != "") {
                    host = hostname + ":" + value
                }
            case "hostname" =>
                hostname = value
                host = value + if (port != "") {
                    ":" + port
                } else {
                    ""
                }
            case "host" =>
                host = value
                let index = portIndex(value)
                if (index >= 0) {
                    port = slice(value, index + 1, size(value))
                    hostname = slice(value, 0, index)
                } else {
                    hostname = value
                    port = ""
                }
            case "protocol" =>
                protocol = value.toLower()
                if (protocol != "" && !protocol.endsWith(":")) {
                    protocol += ":"
                }
                slashes = !flag
            case "pathname" => pathname = if (value != "" && !flag && !value.startsWith("/")) {
                "/" + value
            } else {
                value
            }
            case "hash" => hash = if (value != "" && !flag && !value.startsWith("#")) {
                "#" + value
            } else {
                value
            }
            case "username" => username = encodeComponent(value)
            case "password" => password = encodeComponent(value)
            case "auth" => setAuth(value)
            case _ => ()
        }
        refreshAuthOrigin()
    }

    func render(query: String): String {
        let scheme = protocol + if (protocol != "" && !protocol.endsWith(":")) {
            ":"
        } else {
            ""
        }
        var result = scheme + if ((scheme != "" && slashes) || special(scheme)) {
            "//"
        } else {
            ""
        }
        if (username != "") {
            result += username
            if (password != "") {
                result += ":" + password
            }
            result += "@"
        } else if (password != "") {
            result += ":" + password + "@"
        } else if (scheme != "file:" && special(scheme) && host == "" && pathname != "/") {
            result += "@"
        }
        var authority = host
        if (authority.endsWith(":") || (portIndex(hostname) >= 0 && port == "")) {
            authority += ":"
        }
        result += authority + pathname
        if (query != "") {
            result += if (query.startsWith("?")) {
                query
            } else {
                "?" + query
            }
        }
        return result + hash
    }

    func asLocation(): Location {
        return Location(protocol: protocol, slashes: Some(slashes), host: host, hostname: hostname, port: port,
            pathname: pathname, href: href)
    }
}

/** A typed URL result, including a custom query parser and serializer. */
public open class URLParse<T> <: ToString {
    private let state: UrlState
    private let stringify: (T) -> String

    public init(address: String, parser: (String) -> T, stringify: (T) -> String, base!: Location = Location()) {
        state = UrlState(address, location(base))
        this.stringify = stringify
        let value = parser(state.rawQuery)
        state.queryData = value
        state.queryStringify = {=> stringify(value)}
        state.href = state.render(stringify(value))
    }

    protected init(address: String, base: Location, parser: (String) -> T, stringify: (T) -> String) {
        state = UrlState(address, location(base))
        this.stringify = stringify
        let value = parser(state.rawQuery)
        state.queryData = value
        state.queryStringify = {=> stringify(value)}
        state.href = state.render(stringify(value))
    }

    public init(address: String, parser: (String) -> T, base!: Location = Location()) {
        state = UrlState(address, location(base))
        let render = defaultStringify<T>
        this.stringify = render
        let value = parser(state.rawQuery)
        state.queryData = value
        state.queryStringify = {=> render(value)}
        state.href = state.render(render(value))
    }

    private init(state: UrlState, stringify: (T) -> String) {
        this.state = state
        this.stringify = stringify
    }

    private func replaceQuery(value: T): Unit {
        state.queryData = value
        state.queryStringify = {=> stringify(value)}
    }

    private func readQuery(): T {
        if (let Some(value) <- (state.queryData as T)) {
            return value
        }
        if (let Some(value) <- (state.queryData as Query)) {
            if (!value.isParsed) {
                if (let Some(text) <- (value.rawText as T)) {
                    return text
                }
            }
        }
        if (let Some(text) <- (state.queryData as String)) {
            if (let Some(query) <- (Query.raw(text) as T)) {
                return query
            }
        }
        throw IllegalArgumentException("Read query through the typed result returned by set")
    }

    public mut prop auth: String {
        get() {
            return state.auth
        }
        set(value) {
            state.auth = value
        }
    }
    public mut prop hash: String {
        get() {
            return state.hash
        }
        set(value) {
            state.hash = value
        }
    }
    public mut prop host: String {
        get() {
            return state.host
        }
        set(value) {
            state.host = value
        }
    }
    public mut prop hostname: String {
        get() {
            return state.hostname
        }
        set(value) {
            state.hostname = value
        }
    }
    public mut prop href: String {
        get() {
            return state.href
        }
        set(value) {
            state.href = value
        }
    }
    public mut prop origin: String {
        get() {
            return state.origin
        }
        set(value) {
            state.origin = value
        }
    }
    public mut prop password: String {
        get() {
            return state.password
        }
        set(value) {
            state.password = value
        }
    }
    public mut prop pathname: String {
        get() {
            return state.pathname
        }
        set(value) {
            state.pathname = value
        }
    }
    public mut prop port: String {
        get() {
            return state.port
        }
        set(value) {
            state.port = value
        }
    }
    public mut prop protocol: String {
        get() {
            return state.protocol
        }
        set(value) {
            state.protocol = value
        }
    }
    public mut prop query: T {
        get() {
            return readQuery()
        }
        set(value) {
            replaceQuery(value)
        }
    }
    public mut prop slashes: Bool {
        get() {
            return state.slashes
        }
        set(value) {
            state.slashes = value
        }
    }
    public mut prop username: String {
        get() {
            return state.username
        }
        set(value) {
            state.username = value
        }
    }

    public func set(part: String, value: String): URLParse<T> {
        return set(part, value, false)
    }
    public func set(part: String, value: String, flag: Bool): URLParse<T> {
        if (part == "query") {
            if (flag && value != "") {
                throw IllegalArgumentException("Query parser must be a function")
            }
            let query = querySetter(value)
            state.queryData = query
            state.queryStringify = {=> query.toString()}
        } else {
            state.change(part, value, flag)
        }
        state.refreshAuthOrigin()
        state.href = toString()
        return this
    }

    public func set(part: String, value: Int64): URLParse<T> {
        return set(part, value.toString())
    }
    public func set(part: String, value: Bool): URLParse<T> {
        // The upstream switch leaves the slashes field unchanged.
        return set(part, if (value) {
            "true"
        } else {
            "false"
        })
    }

    public func setQuery(value: T): URLParse<T> {
        replaceQuery(value)
        state.refreshAuthOrigin()
        state.href = toString()
        return this
    }

    public func set(part: String, value: Query): URLParse<T> {
        if (part == "query") {
            if (let Some(typed) <- (value as T)) {
                return setQuery(typed)
            }
            throw IllegalArgumentException("Query type does not match the URL query parser")
        }
        return set(part, value.toString())
    }

    public func set<U>(part: String, value: String, parser: (String) -> U): URLParse<U> {
        let result = URLParse<U>(state, defaultStringify<U>)
        if (part == "query" && value != "") {
            result.setQuery(parser(value))
        } else {
            set(part, value, true)
        }
        return result
    }

    public func toString(): String {
        return state.render(state.queryStringify())
    }
    public func toString(stringify: (T) -> String): String {
        if (let Some(text) <- (state.queryData as String)) {
            return state.render(text)
        }
        if (let Some(value) <- (state.queryData as Query)) {
            if (!value.isParsed) {
                return state.render(value.rawText)
            }
        }
        return state.render(stringify(query))
    }
    public func asLocation(): Location {
        return state.asLocation()
    }
}

/** Default URL parser, with query text or querystringify-style object data. */
public class Url <: URLParse<Query> {
    public init() {
        super("", Location(), {text => Query.raw(text)}, {query => query.toString()})
    }
    public init(address: String) {
        super(address, Location(), {text => Query.raw(text)}, {query => query.toString()})
    }
    public init(address: String, parseQuery: Bool) {
        super(address, Location(), {
            text => if (parseQuery) {
                QueryString.parse(text)
            } else {
                Query.raw(text)
            }
        }, {query => query.toString()})
    }
    public init(address: String, base: String, parseQuery!: Bool = false) {
        super(address, location(base), {
            text => if (parseQuery) {
                QueryString.parse(text)
            } else {
                Query.raw(text)
            }
        }, {query => query.toString()})
    }
    public init(address: String, base: Location, parseQuery!: Bool = false) {
        super(address, location(base), {
            text => if (parseQuery) {
                QueryString.parse(text)
            } else {
                Query.raw(text)
            }
        }, {query => query.toString()})
    }

    public static func extractProtocol(address: String): ProtocolExtract {
        return extractForUrl(address)
    }
    public static func extractProtocol(address: String, base: Location): ProtocolExtract {
        return extractForUrl(address, base)
    }
    public static func location(address: String): Location {
        return locationForUrl(address)
    }
    public static func location(base: Location): Location {
        return locationForUrl(base)
    }
    public static func trimLeft(text: String): String {
        return trimForUrl(text)
    }
    public static prop qs: QueryStringApi {
        get() {
            return QueryStringApi()
        }
    }
}

func extractForUrl(address: String): ProtocolExtract {
    return extractProtocol(address)
}

func extractForUrl(address: String, base: Location): ProtocolExtract {
    return extractProtocol(address, base)
}

func locationForUrl(address: String): Location {
    return location(address)
}

func locationForUrl(base: Location): Location {
    return location(base)
}

func trimForUrl(text: String): String {
    return trimLeft(text)
}

func querySetter(text: String): Query {
    return if (text == "") {
        Query.raw("")
    } else {
        QueryString.parse(text)
    }
}

public func parse(address: String): Url {
    return Url(address)
}

public func parse(address: String, parseQuery: Bool): Url {
    return Url(address, parseQuery)
}

public func parse(address: String, base: String, parseQuery!: Bool = false): Url {
    return Url(address, base, parseQuery: parseQuery)
}

public func parse(address: String, base: Location, parseQuery!: Bool = false): Url {
    return Url(address, base, parseQuery: parseQuery)
}

public func parse<T>(address: String, parser: (String) -> T, stringify: (T) -> String, base!: Location = Location()): URLParse<T> {
    return URLParse<T>(address, parser, stringify, base: base)
}

public func parse(): Url {
    return Url()
}

public func parse<T>(address: String, base: URLParse<T>, parseQuery!: Bool = false): Url {
    return Url(address, base.asLocation(), parseQuery: parseQuery)
}

public func parse<T>(address: String, parser: (String) -> T, base!: Location = Location()): URLParse<T> {
    return URLParse<T>(address, parser, defaultStringify<T>, base: base)
}

public func parse<T>(address: String, base: String, parser: (String) -> T): URLParse<T> {
    return parse(address, parser, base: location(base))
}

public func parse<T>(address: String, base: Location, parser: (String) -> T): URLParse<T> {
    return parse(address, parser, base: base)
}

func defaultStringify<T>(value: T): String {
    if (let Some(text) <- (value as String)) {
        return text
    }
    if (let Some(query) <- (value as Query)) {
        return query.toString()
    }
    if (let Some(entries) <- (value as HashMap<String, String>)) {
        let query = Query()
        for ((key, text) in entries) {
            query.set(key, text)
        }
        return QueryString.stringify(query)
    }
    if (let Some(entries) <- (value as HashMap<String, ?String>)) {
        let query = Query()
        for ((key, text) in entries) {
            query.set(key, text)
        }
        return QueryString.stringify(query)
    }
    if (let Some(entries) <- (value as Array<String>)) {
        let query = Query()
        for (i in 0..entries.size) {
            query.set(i.toString(), entries[i])
        }
        return QueryString.stringify(query)
    }
    return ""
}
