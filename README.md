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
- 验证平台：Windows x86_64、Linux x86_64（Ubuntu 26.04.1 / WSL2）。
- 上游行为对照脚本使用 Node.js。

2026-11-14 使用各 SDK 的独立构建目录及 Node.js 22.20.0，完成以下版本回归：

| 仓颉 SDK | Windows x86_64 | Linux x86_64 / WSL2 |
| --- | --- | --- |
| 1.0.5 | 通过 | 通过 |
| 1.1.0 | 通过 | 通过 |
| 1.1.3 | 通过 | 通过 |
| 1.1.5 | 通过 | 通过 |
| 1.2.0 | 通过 | 通过 |
| 1.2.1 | 通过 | 通过 |

每个环境均通过 release/debug 静态库及依赖构建、原有 **17/17 单元测试**、
`examples/migration` 及同时引入两库的消费端验证；单测无失败、错误或跳过。
release 模式的上游对照使用脚本原有固定种子 `20261021`，每个环境执行
**101 个上游测试体、5,240 次行为比较，零差异**。debug 模式未运行上游差分。

验证对应本仓源码基线 `8181a1589158bbe8a8a45e12c5acf6f324deaf93`，
`requires-port4cj` 依赖基线为 `5f3cf14a7a4e440e2e5b2009c2059eefb182a067`。
清单中的 `cjc-version = "1.0.5"` 继续作为最低 SDK 要求；结论限于表中平台从源码
重新构建后的兼容性，未验证跨 SDK 二进制混用。

两个仓库放在同一级目录：

```text
cj/
├── requires-port4cj/
└── url-parse4cj/
```

根目录 `cjpm.toml` 通过 `path = "../requires-port4cj"` 引入端口判断库。

## 编译与验证

加载待测 SDK 环境后，在根目录执行。切换 SDK 时还需清理兄弟目录 `requires-port4cj`、
迁移示例和 `tests/compatibility` 的构建缓存：

```shell
cjpm clean
cjpm build
cjpm test
cjpm build -g
cjpm test -g
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
cjpm clean
cjpm run
cjpm run -g
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
