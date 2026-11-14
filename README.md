# url-parse4cj

`url-parse` 的仓颉移植，面向 JavaScript 和 TypeScript 项目迁移。
运行行为对齐 [unshiftio/url-parse](https://github.com/unshiftio/url-parse) **1.5.10**，
接口参考 [DefinitelyTyped/types/url-parse](https://github.com/DefinitelyTyped/DefinitelyTyped/tree/master/types/url-parse)。

提供 URL 字段解析、相对路径合并、链式 `set`、查询解析回调、序列化及辅助函数。
端口规则复用 [requires-port4cj](https://gitcode.com/gcw_kMd990Oo/requires-port4cj)，
查询参数处理移植自 `querystringify`。

## 项目结构

```text
url-parse4cj/
├── cjpm.toml
├── src/
│   ├── url.cj                      # URL 状态、构造、set 和 toString
│   ├── location.cj                 # 基准地址、协议提取与相对路径合并
│   ├── query.cj                    # 原始/对象查询数据、parse 和 stringify
│   ├── strings.cj                  # URI 编解码及字符串处理
│   ├── types.cj                    # 查询回调类型别名
│   └── url_test.cj                 # 仓颉单元测试
├── examples/migration/             # JS 调用到仓颉调用的可运行示例
├── tests/compatibility/            # 行为对照程序
├── scripts/check_upstream.cjs      # 执行上游测试并对照两版结果
├── doc/
│   ├── feature_api.md              # API 说明
│   ├── migration.md                # JS/TS 迁移对应表
│   └── porting.md                  # 上游来源与实现对应关系
└── upstream/                       # 运行库、类型定义、测试及许可证快照
```

## 环境与依赖

- 最低仓颉 SDK **1.0.5**，加载 SDK 环境后使用 `cjc`、`cjpm`。
- 验证环境：Windows x86_64、Cangjie 1.0.5 和 1.2.1。
- 上游行为对照脚本使用 Node.js。

2026-11-14 使用 SDK 1.2.1、Node.js 22.20.0，清理构建缓存后执行现有 release 流程：
`cjpm build`、`cjpm test`（17/17）、迁移示例及上游对照（101 个测试体、5,240 次比较）
均通过，行为差异为 0。清单中的 `cjc-version = "1.0.5"` 继续作为最低 SDK 要求。

两个仓库放在同一级目录：

```text
cj/
├── requires-port4cj/
└── url-parse4cj/
```

根目录 `cjpm.toml` 通过 `path = "../requires-port4cj"` 引入端口判断库。

## 编译与验证

在根目录执行：

```shell
cjpm build
cjpm test
node scripts/check_upstream.cjs
```

对照脚本执行上游 **101 个测试体**，回放其中的解析、字段修改和序列化操作，
再加入协议、基准地址、Unicode、认证、查询、异常及固定种子的生成用例，
共完成 **5,240 项行为比较**。比较字段包括 `auth`、`hash`、`host`、`hostname`、
`href`、`origin`、`password`、`pathname`、`port`、`protocol`、`slashes`、`username`、
查询数据与 `toString()` 结果。报告写入 `target/compatibility-results.json`。

运行迁移示例：

```shell
cd examples/migration
cjpm run
```

## 使用

在消费端 `cjpm.toml` 中添加：

```toml
[dependencies]
url_parse = { path = "../url-parse4cj" }
```

```cangjie
import url_parse.*

main() {
    let url = parse("../users?id=42", "https://api.example.com/v1/items", parseQuery: true)
    println(url.href) // https://api.example.com/users?id=42
    println(url.query["id"]) // Some(42)

    url.set("hostname", "mirror.example.com").set("port", "8443")
    url.set("query", Query([("page", "2")]))
    println(url.href) // https://mirror.example.com:8443/users?page=2
}
```

`Url(address)` 和 `parse(address)` 都创建 URL 实例。`Query` 保留查询字符串和对象两种形态：
`query.rawText` 读取原始文本，`query["key"]` 读取对象中的值，`query.isParsed` 标识当前形态。
自定义解析器返回 `URLParse<T>`，其 `query` 为回调返回的类型。

完整示例及调用对应关系见 [JS/TS 迁移说明](doc/migration.md)，签名见 [API 文档](doc/feature_api.md)。

## 开源协议

采用 [MIT License](LICENSE)。上游源码、类型定义及各自许可证保存在 `upstream/`。
