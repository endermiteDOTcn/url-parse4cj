// Copyright (c) 2015 Unshift.io, Arnout Kazemier, the Contributors.
// Ported to Cangjie in 2026. Licensed under the MIT License.
package url_parse

import std.collection.*

public class Location {
    public var protocol: String
    public var slashes: ?Bool
    public var host: String
    public var hostname: String
    public var port: String
    public var pathname: String
    public var href: String

    public init(protocol!: String = "", slashes!: ?Bool = None, host!: String = "", hostname!: String = "",
        port!: String = "", pathname!: String = "", href!: String = "") {
        this.protocol = protocol
        this.slashes = slashes
        this.host = host
        this.hostname = hostname
        this.port = port
        this.pathname = pathname
        this.href = href
    }
}

public struct ProtocolExtract {
    public let protocol: String
    public let slashes: Bool
    public let slashesCount: Int64
    public let rest: String

    init(protocol: String, slashes: Bool, count: Int64, rest: String) {
        this.protocol = protocol
        this.slashes = slashes
        this.slashesCount = count
        this.rest = rest
    }
}

public func extractProtocol(address: String): ProtocolExtract {
    return extractProtocol(address, Location())
}

public func extractProtocol(address: String, base: Location): ProtocolExtract {
    let text = trimAddress(address)
    let runes = text.toRuneArray()
    var index = 0
    var scheme = ""
    if (runes.size > 0 && asciiAlpha(runes[0])) {
        var end = 1
        while (end < runes.size && (asciiAlpha(runes[end]) || (runes[end] >= r'0' && runes[end] <= r'9') ||
                runes[end] == r'.' || runes[end] == r'+' || runes[end] == r'-')) {
            end++
        }
        if (end < runes.size && runes[end] == r':') {
            index = end + 1
            scheme = String(runes[..index]).toAsciiLower()
        }
    }
    let forward = index + 1 < runes.size && runes[index] == r'/' && runes[index + 1] == r'/'
    let slashStart = index
    while (index < runes.size && (runes[index] == r'/' || runes[index] == r'\\')) {
        index++
    }
    let count = index - slashStart
    var rest = String(runes[slashStart..runes.size])
    if (scheme == "file:") {
        if (count >= 2) {
            rest = String(runes[slashStart + 2..runes.size])
        }
    } else if (special(scheme)) {
        rest = String(runes[index..runes.size])
    } else if (scheme != "") {
        if (forward) {
            rest = String(runes[slashStart + 2..runes.size])
        }
    } else if (count >= 2 && special(base.protocol)) {
        rest = String(runes[index..runes.size])
    }
    return ProtocolExtract(scheme, forward || special(scheme), count, rest)
}

public func location(address: String): Location {
    let url = Url(address)
    return url.asLocation()
}

public func location(base: Location): Location {
    if (base.protocol == "blob:") {
        return location(unescapeLocation(base.pathname))
    }
    return Location(protocol: base.protocol, slashes: Some(base.slashes.getOrDefault({=> hasSchemeSlashes(base.href)})),
        host: base.host, hostname: base.hostname, port: base.port, pathname: base.pathname, href: base.href)
}

func hasSchemeSlashes(address: String): Bool {
    let runes = address.toRuneArray()
    if (runes.size == 0 || !asciiAlpha(runes[0])) {
        return false
    }
    var i = 1
    // The upstream slashes regexp uses the range +-. which also includes comma.
    while (i < runes.size && (asciiAlpha(runes[i]) || (runes[i] >= r'0' && runes[i] <= r'9') || (runes[i] >= r'+' &&
            runes[i] <= r'.'))) {
        i++
    }
    return i + 2 < runes.size && runes[i] == r':' && runes[i + 1] == r'/' && runes[i + 2] == r'/'
}

func resolvePath(relative: String, base: String): String {
    if (relative == "") {
        return base
    }
    let path = splitKeep(if (base == "") {
        "/"
    } else {
        base
    }, r'/')
    let combined = ArrayList<String>()
    for (i in 0..path.size - 1) {
        combined.add(path[i])
    }
    for (part in splitKeep(relative, r'/')) {
        combined.add(part)
    }
    let last = combined[combined.size - 1]
    let reverse = ArrayList<String>()
    var up = 0
    var unshift = false
    var i = combined.size
    while (i > 0) {
        i--
        if (combined[i] == ".") {
            continue
        }
        if (combined[i] == "..") {
            up++;
            continue
        }
        if (up > 0) {
            if (i == 0) {
                unshift = true
            }
            up--
        } else {
            reverse.add(combined[i])
        }
    }
    let result = ArrayList<String>()
    if (unshift) {
        result.add("")
    }
    i = reverse.size
    while (i > 0) {
        i--;
        result.add(reverse[i])
    }
    if (last == "." || last == "..") {
        result.add("")
    }
    return join(result, "/")
}
