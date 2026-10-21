# API 说明

## 构造与解析

```cangjie
Url()
Url(address: String)
Url(address: String, parseQuery: Bool)
Url(address: String, base: String, parseQuery!: Bool = false)
Url(address: String, base: Location, parseQuery!: Bool = false)

parse(): Url
parse(address: String): Url
parse(address: String, parseQuery: Bool): Url
parse(address: String, base: String, parseQuery!: Bool = false): Url
parse(address: String, base: Location, parseQuery!: Bool = false): Url
parse<T>(address: String, base: URLParse<T>, parseQuery!: Bool = false): Url
parse<T>(address: String, parser: (String) -> T, base!: Location = Location()): URLParse<T>
parse<T>(address: String, base: String, parser: (String) -> T): URLParse<T>
parse<T>(address: String, base: Location, parser: (String) -> T): URLParse<T>
parse<T>(address: String, parser: (String) -> T, stringify: (T) -> String,
    base!: Location = Location()): URLParse<T>
```

`Url` 继承 `URLParse<Query>`。`URLParse<T>` 也提供带解析回调的构造函数。
`parseQuery: true` 使用内置查询解析器，默认保留原始查询文本。
回调类型别名为 `QueryParser<T> = (String) -> T` 和 `StringifyQuery<T> = (T) -> String`。

## URL 字段

| 字段 | 类型 | 内容 |
| --- | --- | --- |
| `protocol` | `String` | 协议，通常以 `:` 结尾 |
| `slashes` | `Bool` | 斜杠标志 |
| `auth` | `String` | 编码后的认证信息 |
| `username` | `String` | 编码后的用户名 |
| `password` | `String` | 编码后的密码 |
| `host` | `String` | 主机与端口 |
| `hostname` | `String` | 主机名 |
| `port` | `String` | 显式端口 |
| `pathname` | `String` | 路径 |
| `query` | `T` | 查询数据，`Url` 中为 `Query` |
| `hash` | `String` | 包含 `#` 的片段 |
| `origin` | `String` | 源地址，按上游规则返回协议与主机或 `"null"` |
| `href` | `String` | 构造或 `set` 时生成的完整地址 |

## 修改与序列化

```cangjie
set(part: String, value: String): URLParse<T>
set(part: String, value: String, flag: Bool): URLParse<T>
set(part: String, value: Int64): URLParse<T>
set(part: String, value: Bool): URLParse<T>
set(part: String, value: Query): URLParse<T>
set<U>(part: String, value: String, parser: (String) -> U): URLParse<U>
setQuery(value: T): URLParse<T>
toString(): String
toString(stringify: (T) -> String): String
asLocation(): Location
```

| `part` | `set` 的行为 |
| --- | --- |
| `query` | 非空文本使用查询解析器，`Query` 对象替换查询数据 |
| `port` | 按协议移除默认端口，并同步 `host` |
| `hostname` | 同步 `host` 中的主机名，保留端口 |
| `host` | 解析尾部数字端口，并同步 `hostname`、`port` |
| `protocol` | 转小写、补 `:`，`flag` 决定 `slashes` |
| `pathname` | `flag` 为 `false` 时为非空值补 `/` |
| `hash` | `flag` 为 `false` 时为非空值补 `#` |
| `username`、`password` | 进行 `encodeURIComponent` 编码 |
| `auth` | 分离用户名与密码，先解码再编码 |
| `href`、`origin`、`slashes` | 保持上游 `set` 分支的处理方式，重算关联字段和 `href` |

`set("query", nonEmptyText, true)` 抛出 `IllegalArgumentException`。
认证中的非法百分号编码也通过异常报告。内置查询解析器将非法编码的键值对跳过。

原始文本查询直接参与 URL 拼接；对象查询使用序列化回调。
默认序列化支持 `Query`、`HashMap<String, String>`、`HashMap<String, ?String>` 及 `Array<String>`。

## 查询参数

```cangjie
Query()
Query(entries: Array<(String, String)>)
Query.raw(text: String): Query

query.isParsed: Bool
query.rawText: String
query.count: Int64
query[key: String]: ?String
query.get(key: String): ?String
query.contains(key: String): Bool
query.set(key: String, value: String): Query
query.set(key: String, value: ?String): Query
query.entries(): Array<(String, ?String)>
query.toString(): String

QueryString.parse(text: String): Query
QueryString.stringify(query: Query): String
QueryString.stringify(query: Query, prefix: String): String
QueryString.stringify(query: Query, prefix: Bool): String
```

同一组查询函数也可通过 `Url.qs.parse` 和 `Url.qs.stringify` 调用。
解析将 `+` 转为空格，重复键取第一个值，沿用 `querystringify` 对对象原型键的处理规则。
序列化使用 `encodeURIComponent` 的字符集合，空缺值编码为空字符串。

## 协议与基准地址辅助函数

```cangjie
extractProtocol(address: String): ProtocolExtract
extractProtocol(address: String, base: Location): ProtocolExtract
location(address: String): Location
location(base: Location): Location
trimLeft(text: String): String
```

以上函数同时可通过 `Url` 的静态接口调用。
`ProtocolExtract` 包含 `protocol`、`slashes`、`slashesCount`、`rest`。
`Location` 构造参数为命名参数：`protocol`、`slashes: ?Bool`、`host`、`hostname`、
`port`、`pathname`、`href`。
