package url_parse_compatibility

import std.collection.*
import std.convert.*
import std.env.*
import url_parse.*

func unhex(text: String): String {
    if (text == "-") {
        return ""
    }
    let runes = text.toRuneArray()
    let bytes = ArrayList<UInt8>()
    var i = 0
    while (i < runes.size) {
        bytes.add(UInt8.parse(String(runes[i..i + 2]), radix: 16))
        i += 2
    }
    return String.fromUtf8(bytes.toArray())
}

func hex(text: String): String {
    if (text == "") {
        return "-"
    }
    var result = ""
    for (byte in text.toArray()) {
        let part = byte.toString(radix: 16)
        result += if (part.size == 1) {
            "0" + part
        } else {
            part
        }
    }
    return result
}

func output(parts: Array<String>): Unit {
    var line = ""
    for (i in 0..parts.size) {
        if (i > 0) {
            line += "|"
        }
        line += hex(parts[i])
    }
    println(line)
}

func baseFrom(text: String): Location {
    let parts = text.split(",")
    let flag: ?Bool = if (parts[6] == "-") {
        None
    } else {
        Some(parts[6] == "1")
    }
    return Location(protocol: unhex(parts[0]), host: unhex(parts[1]), hostname: unhex(parts[2]), port: unhex(parts[3]),
        pathname: unhex(parts[4]), href: unhex(parts[5]), slashes: flag)
}

func queryFrom(text: String): Query {
    let result = Query()
    if (text == "-") {
        return result
    }
    for (pair in text.split(",")) {
        let fields = pair.split(":")
        if (fields[1] == "U") {
            result.set(unhex(fields[0]), None)
        } else {
            result.set(unhex(fields[0]), unhex(fields[1]))
        }
    }
    return result
}

func snapshot(url: URLParse<Query>, stringify: String): Unit {
    let query = if (url.query.isParsed) {
        "O:" + QueryString.stringify(url.query)
    } else {
        "S:" + url.query.rawText
    }
    let rendered = if (stringify == "-") {
        url.toString()
    } else {
        url.toString({_: Query => unhex(stringify)})
    }
    output(
        [url.auth, url.hash, url.host, url.hostname, url.href, url.origin, url.password, url.pathname, url.port,
            url.protocol, url.slashes.toString(), url.username, query, rendered])
}

func assign(url: URLParse<Query>, key: String, value: String): Unit {
    match (key) {
        case "auth" => url.auth = value
        case "hash" => url.hash = value
        case "host" => url.host = value
        case "hostname" => url.hostname = value
        case "href" => url.href = value
        case "origin" => url.origin = value
        case "password" => url.password = value
        case "pathname" => url.pathname = value
        case "port" => url.port = value
        case "protocol" => url.protocol = value
        case "username" => url.username = value
        case "slashes" => url.slashes = value == "true"
        case "query" => url.query = Query.raw(value)
        case _ => throw Exception("Unknown direct field: " + key)
    }
}

main() {
    var current: URLParse<Query> = Url()
    var failed = false
    let input = getStdIn()
    while (let Some(line) <- input.readln()) {
        if (line == "") {
            continue
        }
        let p = line.split("|")
        try {
            match (p[0]) {
                case "N" =>
                    failed = false
                    let address = unhex(p[1])
                    let base = if (p[2] == "S") {
                        location(unhex(p[3]))
                    } else if (p[2] == "O") {
                        baseFrom(p[3])
                    } else {
                        Location()
                    }
                    if (p[4] == "C") {
                        current = URLParse<Query>(address, {_: String => Query.raw(unhex(p[5]))},
                            {query: Query => query.toString()}, base: base)
                    } else {
                        current = Url(address, base, parseQuery: p[4] == "1")
                    }
                case "S" =>
                    let key = unhex(p[1])
                    if (p[2] == "O") {
                        current.set(key, queryFrom(p[3]))
                    } else if (p[2] == "B") {
                        current.set(key, p[3] == "1")
                    } else if (p[2] == "I") {
                        current.set(key, Int64.parse(unhex(p[3])))
                    } else if (p[5] != "-") {
                        current.set(key, unhex(p[3]), {_: String => Query.raw(unhex(p[5]))})
                    } else {
                        current.set(key, unhex(p[3]), p[4] == "1")
                    }
                    failed = false
                case "D" =>
                    if (unhex(p[1]) == "query" && p[2] == "O") {
                        current.query = queryFrom(p[3])
                    } else {
                        assign(current, unhex(p[1]), unhex(p[3]))
                    }
                case "O" =>
                    if (failed) {
                        println("E")
                    } else {
                        snapshot(current, p[1])
                    }
                case "T" => output([trimLeft(unhex(p[1]))])
                case "X" =>
                    let value = extractProtocol(unhex(p[1]), baseFrom(p[2]))
                    output([value.protocol, value.slashes.toString(), value.slashesCount.toString(), value.rest])
                case "Q" =>
                    let query = QueryString.parse(unhex(p[1]))
                    output([QueryString.stringify(query), query.count.toString()])
                case "F" =>
                    let query = queryFrom(p[1])
                    if (p[2] == "B") {
                        output([QueryString.stringify(query, p[3] == "1")])
                    } else {
                        output([QueryString.stringify(query, unhex(p[3]))])
                    }
                case "L" =>
                    let value = if (p[1] == "S") {
                        location(unhex(p[2]))
                    } else {
                        location(baseFrom(p[2]))
                    }
                    output(
                        [value.protocol, value.slashes.getOrDefault({=> false}).toString(), value.host, value.hostname,
                            value.port, value.pathname, value.href])
                case _ => throw Exception("Unknown command " + p[0])
            }
        } catch (_: Exception) {
            failed = true
            if (p[0] == "O" || p[0] == "X" || p[0] == "T" || p[0] == "Q" || p[0] == "L") {
                println("E")
            }
        }
    }
}
