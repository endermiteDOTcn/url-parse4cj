// Copyright (c) 2015 Unshift.io, Arnout Kazemier, the Contributors.
// Query conversion derived from querystringify. Licensed under the MIT License.
package url_parse

import std.collection.*
import std.convert.*

/** Query data in its upstream string or object representation. */
public class Query <: ToString {
    private var text = ""
    private var objectMode = true
    private let pairs = ArrayList<(String, ?String)>()

    public init() {}
    public init(entries: Array<(String, String)>) {
        for ((key, value) in entries) {
            set(key, value)
        }
    }

    public static func raw(text: String): Query {
        let result = Query()
        result.text = text
        result.objectMode = false
        return result
    }

    public prop isParsed: Bool {
        get() {
            return objectMode
        }
    }
    public prop rawText: String {
        get() {
            return text
        }
    }
    public prop count: Int64 {
        get() {
            return pairs.size
        }
    }

    public operator func [](key: String): ?String {
        return get(key)
    }

    public func get(key: String): ?String {
        for ((name, value) in pairs) {
            if (name == key) {
                return value
            }
        }
        return None
    }

    public func contains(key: String): Bool {
        for ((name, _) in pairs) {
            if (name == key) {
                return true
            }
        }
        return false
    }

    public func set(key: String, value: String): Query {
        return set(key, Some(value))
    }
    public func set(key: String, value: ?String): Query {
        objectMode = true
        for (i in 0..pairs.size) {
            if (pairs[i][0] == key) {
                pairs[i] = (key, value)
                return this
            }
        }
        pairs.add((key, value))
        return this
    }

    // JavaScript Object.keys order: array-index keys first, then insertion order.
    public func entries(): Array<(String, ?String)> {
        let indices = ArrayList<(String, ?String)>()
        let others = ArrayList<(String, ?String)>()
        for (pair in pairs) {
            if (arrayIndex(pair[0]) >= 0) {
                indices.add(pair)
            } else {
                others.add(pair)
            }
        }
        for (i in 0..indices.size) {
            for (j in i + 1..indices.size) {
                if (arrayIndex(indices[j][0]) < arrayIndex(indices[i][0])) {
                    let old = indices[i];
                    indices[i] = indices[j]
                    indices[j] = old
                }
            }
        }
        for (pair in others) {
            indices.add(pair)
        }
        return indices.toArray()
    }

    public func toString(): String {
        return if (objectMode) {
            QueryString.stringify(this)
        } else {
            text
        }
    }
}

func arrayIndex(text: String): Int64 {
    if (text == "0") {
        return 0
    }
    let bytes = text.toArray()
    if (bytes.size == 0 || bytes[0] < b'1' || bytes[0] > b'9') {
        return -1
    }
    for (byte in bytes) {
        if (byte < b'0' || byte > b'9') {
            return -1
        }
    }
    let value = Int64.tryParse(text).getOrDefault({=> -1})
    return if (value >= 0 && value < 4294967295) {
        value
    } else {
        -1
    }
}

func inheritedKey(key: String): Bool {
    return key == "__proto__" || key == "constructor" || key == "toString" || key == "toLocaleString" || key == "valueOf" ||
        key == "hasOwnProperty" || key == "isPrototypeOf" || key == "propertyIsEnumerable" || key == "__defineGetter__" ||
        key == "__defineSetter__" || key == "__lookupGetter__" || key == "__lookupSetter__"
}

/** The querystringify parse/stringify interface exposed as Url.qs. */
public class QueryString {
    public init() {}

    public static func parse(query: String): Query {
        let result = Query()
        let runes = query.toRuneArray()
        var i = 0
        while (i < runes.size) {
            // /([^=?#&]+)=?([^&]*)/g scans past separators before each key.
            while (i < runes.size && (runes[i] == r'=' || runes[i] == r'?' || runes[i] == r'#' || runes[i] == r'&')) {
                i++
            }
            let start = i
            while (i < runes.size && runes[i] != r'=' && runes[i] != r'?' && runes[i] != r'#' && runes[i] != r'&') {
                i++
            }
            if (start == i) {
                break
            }
            let keyText = String(runes[start..i])
            if (i < runes.size && runes[i] == r'=') {
                i++
            }
            let valueStart = i
            while (i < runes.size && runes[i] != r'&') {
                i++
            }
            try {
                let key = decodeComponent(keyText, plus: true)
                let value = decodeComponent(String(runes[valueStart..i]), plus: true)
                if (!inheritedKey(key) && !result.contains(key)) {
                    result.set(key, value)
                }
            } catch (_: Exception) { /* Invalid percent encoding omits this pair. */ }
        }
        return result
    }

    public static func stringify(query: Query): String {
        return stringify(query, "")
    }

    public static func stringify(query: Query, prefix: String): String {
        let parts = ArrayList<String>()
        for ((key, value) in query.entries()) {
            parts.add(encodeComponent(key) + "=" + encodeComponent(value.getOrDefault({=> ""})))
        }
        return if (parts.size > 0) {
            prefix + join(parts, "&")
        } else {
            ""
        }
    }

    public static func stringify(query: Query, prefix: Bool): String {
        return stringify(query, if (prefix) {
            "?"
        } else {
            ""
        })
    }
}

public class QueryStringApi {
    public init() {}
    public func parse(text: String): Query {
        return QueryString.parse(text)
    }
    public func stringify(query: Query): String {
        return QueryString.stringify(query)
    }
    public func stringify(query: Query, prefix: String): String {
        return QueryString.stringify(query, prefix)
    }
    public func stringify(query: Query, prefix: Bool): String {
        return QueryString.stringify(query, prefix)
    }
}
