// Copyright (c) 2015 Unshift.io, Arnout Kazemier, the Contributors.
// Ported to Cangjie in 2026. Licensed under the MIT License.
package url_parse

import std.collection.*

func slice(text: String, start: Int64, end: Int64): String {
    let runes = text.toRuneArray()
    return String(runes[start..end])
}

func size(text: String): Int64 {
    return text.toRuneArray().size
}

func find(text: String, needle: Rune, last!: Bool = false): Int64 {
    let runes = text.toRuneArray()
    var result = -1
    for (i in 0..runes.size) {
        if (runes[i] == needle) {
            result = i
            if (!last) {
                return i
            }
        }
    }
    return result
}

func splitKeep(text: String, separator: Rune): ArrayList<String> {
    let result = ArrayList<String>()
    let runes = text.toRuneArray()
    var start = 0
    for (i in 0..runes.size) {
        if (runes[i] == separator) {
            result.add(String(runes[start..i]))
            start = i + 1
        }
    }
    result.add(String(runes[start..runes.size]))
    return result
}

func join(parts: ArrayList<String>, separator: String): String {
    var result = ""
    for (i in 0..parts.size) {
        if (i > 0) {
            result += separator
        }
        result += parts[i]
    }
    return result
}

func urlWhitespace(value: Rune): Bool {
    let code = UInt32(value)
    return code <= 0x20 || code == 0xA0 || code == 0x1680 || (code >= 0x2000 && code <= 0x200A) || code == 0x2028 ||
        code == 0x2029 || code == 0x202F || code == 0x205F || code == 0x3000 || code == 0xFEFF
}

public func trimLeft(text: String): String {
    let runes = text.toRuneArray()
    var start = 0
    while (start < runes.size && urlWhitespace(runes[start])) {
        start++
    }
    return String(runes[start..runes.size])
}

func trimAddress(text: String): String {
    let runes = trimLeft(text).toRuneArray()
    var end = runes.size
    while (end > 0 && UInt32(runes[end - 1]) <= 0x20) {
        end--
    }
    var result = ""
    for (i in 0..end) {
        if (runes[i] != r'\n' && runes[i] != r'\r' && runes[i] != r'\t') {
            result += String([runes[i]])
        }
    }
    return result
}

func asciiAlpha(value: Rune): Bool {
    return (value >= r'a' && value <= r'z') || (value >= r'A' && value <= r'Z')
}

func special(protocol: String): Bool {
    return protocol == "file:" || protocol == "ftp:" || protocol == "http:" || protocol == "https:" || protocol == "ws:" ||
        protocol == "wss:"
}

func portIndex(host: String, allowEmpty!: Bool = false): Int64 {
    let index = find(host, r':', last: true)
    if (index < 0 || (!allowEmpty && index == size(host) - 1)) {
        return -1
    }
    let runes = host.toRuneArray()
    for (i in index + 1..runes.size) {
        if (runes[i] < r'0' || runes[i] > r'9') {
            return -1
        }
    }
    return index
}

func hexDigit(value: UInt8): Int64 {
    if (value >= b'0' && value <= b'9') {
        return Int64(value - b'0')
    }
    if (value >= b'a' && value <= b'f') {
        return Int64(value - b'a') + 10
    }
    if (value >= b'A' && value <= b'F') {
        return Int64(value - b'A') + 10
    }
    return -1
}

// encodeURIComponent, with its exact ASCII safe set.
func encodeComponent(text: String): String {
    var result = ""
    let hex = "0123456789ABCDEF".toArray()
    for (byte in text.toArray()) {
        if ((byte >= b'a' && byte <= b'z') || (byte >= b'A' && byte <= b'Z') || (byte >= b'0' && byte <= b'9') ||
            byte == b'-' || byte == b'_' || byte == b'.' || byte == b'!' || byte == b'~' || byte == b'*' || byte == b'\'' ||
            byte == b'(' || byte == b')') {
            result += String([Rune(UInt32(byte))])
        } else {
            result += "%" + String([Rune(UInt32(hex[Int64(byte) / 16])), Rune(UInt32(hex[Int64(byte) % 16]))])
        }
    }
    return result
}

func decodeComponent(text: String, plus!: Bool = false): String {
    let input = text.toArray()
    let output = ArrayList<UInt8>()
    var i = 0
    while (i < input.size) {
        if (input[i] == b'%') {
            if (i + 2 >= input.size) {
                throw IllegalArgumentException("URI malformed")
            }
            let high = hexDigit(input[i + 1])
            let low = hexDigit(input[i + 2])
            if (high < 0 || low < 0) {
                throw IllegalArgumentException("URI malformed")
            }
            output.add(UInt8(high * 16 + low))
            i += 3
        } else {
            output.add(if (plus && input[i] == b'+') {
                b' '
            } else {
                input[i]
            })
            i++
        }
    }
    // String.fromUtf8 validates overlong sequences, surrogates and invalid continuations.
    return String.fromUtf8(output.toArray())
}

func normalizeAuth(text: String): String {
    return encodeComponent(decodeComponent(text))
}

// JavaScript unescape used by blob locations: percent bytes are Latin-1 code units.
func unescapeLocation(text: String): String {
    let bytes = text.toArray()
    var result = ""
    var i = 0
    while (i < bytes.size) {
        if (bytes[i] == b'%' && i + 2 < bytes.size && hexDigit(bytes[i + 1]) >= 0 && hexDigit(bytes[i + 2]) >= 0) {
            result += String([Rune(UInt32(hexDigit(bytes[i + 1]) * 16 + hexDigit(bytes[i + 2])))])
            i += 3
        } else if (bytes[i] == b'%' && i + 5 < bytes.size && bytes[i + 1] == b'u' && hexDigit(bytes[i + 2]) >= 0 &&
            hexDigit(bytes[i + 3]) >= 0 && hexDigit(bytes[i + 4]) >= 0 && hexDigit(bytes[i + 5]) >= 0) {
            var code = hexDigit(bytes[i + 2]) * 4096 + hexDigit(bytes[i + 3]) * 256 + hexDigit(bytes[i + 4]) * 16 +
                hexDigit(bytes[i + 5])
            if (code >= 0xD800 && code <= 0xDBFF && i + 11 < bytes.size && bytes[i + 6] == b'%' && bytes[i + 7] == b'u' &&
                hexDigit(bytes[i + 8]) >= 0 && hexDigit(bytes[i + 9]) >= 0 && hexDigit(bytes[i + 10]) >= 0 &&
                hexDigit(bytes[i + 11]) >= 0) {
                let low = hexDigit(bytes[i + 8]) * 4096 + hexDigit(bytes[i + 9]) * 256 + hexDigit(bytes[i + 10]) * 16 +
                    hexDigit(bytes[i + 11])
                if (low >= 0xDC00 && low <= 0xDFFF) {
                    code = 0x10000 + (code - 0xD800) * 1024 + low - 0xDC00
                    i += 6
                }
            }
            result += String([Rune(UInt32(code))])
            i += 6
        } else {
            // Preserve literal Unicode by consuming a complete UTF-8 sequence.
            var count = 1
            if (bytes[i] >= 0xF0) {
                count = 4
            } else if (bytes[i] >= 0xE0) {
                count = 3
            } else if (bytes[i] >= 0xC0) {
                count = 2
            }
            result += String.fromUtf8(bytes[i..i + count])
            i += count
        }
    }
    return result
}
