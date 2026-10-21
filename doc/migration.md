# JavaScript / TypeScript 迁移

## 模块与调用

JavaScript：

```javascript
const parse = require('url-parse');
const url = parse('../users?id=42', 'https://api.example.com/v1/items', true);
console.log(url.query.id);
url.set('hostname', 'mirror.example.com').set('port', '8443');
url.set('query', { page: '2' });
console.log(url.href);
```

仓颉：

```cangjie
import url_parse.*

main() {
    let url = parse("../users?id=42", "https://api.example.com/v1/items", parseQuery: true)
    println(url.query["id"].getOrDefault({=> ""}))
    url.set("hostname", "mirror.example.com").set("port", "8443")
    url.set("query", Query([("page", "2")]))
    println(url.href)
}
```

## 调用对应表

| JS / TS | 仓颉 |
| --- | --- |
| `new URL(address)` | `Url(address)` |
| `parse(address)` | `parse(address)` |
| `parse(address, true)` | `parse(address, true)` |
| `parse(address, base, true)` | `parse(address, base, parseQuery: true)` |
| `parse(address, baseObject)` | `parse(address, Location(...))` |
| `parse(address, parsedBase)` | `parse(address, parsedBase)` |
| `url.query.key` | `url.query["key"]`，返回 `?String` |
| `url.query` 为原始字符串 | `url.query.rawText` |
| `url.set('query', {a: 'b'})` | `url.set("query", Query([("a", "b")]))` |
| `url.set('query', 'a=b')` | `url.set("query", "a=b")` |
| `url.set('port', 8080)` | `url.set("port", 8080)` |
| `url.set('protocol', 'mailto', true)` | `url.set("protocol", "mailto", true)` |
| `url.toString(stringify)` | `url.toString(stringify)` |
| `URL.extractProtocol(address)` | `Url.extractProtocol(address)` |
| `URL.location(base)` | `Url.location(base)` |
| `URL.trimLeft(text)` | `Url.trimLeft(text)` |
| `URL.qs.parse(text)` | `Url.qs.parse(text)` |
| `URL.qs.stringify(object)` | `Url.qs.stringify(query)` |

## 查询数据

`Query` 用同一个仓颉类型表示上游的字符串和对象查询数据：

```cangjie
let raw = parse("https://example.com/?a=b+c")
raw.query.rawText // ?a=b+c
raw.query.isParsed // false

let parsed = parse("https://example.com/?a=b+c", true)
parsed.query["a"] // Some("b c")
parsed.query.isParsed // true
```

用 `getOrDefault` 提供缺省值，用 `contains` 检查键是否存在。
`Query.set(key, None)` 对应查询对象中的 `undefined` 值，序列化为 `key=`。

```cangjie
let query = Query([("page", "2")])
query.set("optional", None)
Url.qs.stringify(query) // page=2&optional=
```

重复键保留第一个值。查询对象的数字索引键按升序序列化，其余键保留插入顺序。
修改 `url.query` 中的对象后，`url.toString()` 使用当前数据；调用 `set` 时同步更新 `href`。

## 自定义解析器与序列化

`parse<T>` 的 `query` 使用回调返回类型：

```cangjie
let url = parse("/search?q=cangjie", "https://example.com/",
    {text: String => Query([("raw", text)])})
url.query["raw"] // Some("?q=cangjie")
url.toString({_: Query => "q=custom"}) // https://example.com/search?q=custom
```

泛型 `set<U>` 返回共享 URL 状态的 `URLParse<U>`。通过返回值读取新类型的查询数据：

```cangjie
let original = parse("https://example.com/", true)
let updated = original.set("query", "token=123", {text: String => text})
updated.query // token=123，类型为 String
original.href // https://example.com/?token=123
```

应用自定义结构时，可以同时提供解析和序列化回调：

```cangjie
let url = parse("https://example.com/?a=b",
    {text: String => text.size},
    {count: Int64 => count.toString()})
url.query // 4，类型为 Int64
url.href // https://example.com/?4
```

## 基准地址

相对地址通过字符串、`Location` 或已有解析结果提供上下文：

```cangjie
let base = Location(protocol: "https:", slashes: Some(true),
    host: "example.com", hostname: "example.com", pathname: "/a/b")
let url = parse("../c", base)
url.href // https://example.com/c
```

`blob:` 基准地址从 `pathname` 提取原始地址。协议、主机、端口及路径按照上游规则参与相对地址解析。

## 字段更新

`set` 会同步相关字段、`auth`、`origin` 和 `href`，并支持链式调用。
直接赋值修改当前字段，`toString()` 按当前字段生成 URL。

```cangjie
let url = parse("http://example.com/")
url.protocol = "https"
url.toString() // https://example.com/
url.href // http://example.com/

url.set("protocol", "https")
url.href // https://example.com/
```
