<div align="center">
<h1>url-parse4cj</h1>
</div>

<p align="center">
<img alt="release" src="https://img.shields.io/badge/release-v1.5.10-brightgreen" style="display: inline-block;" />
<img alt="cjc" src="https://img.shields.io/badge/cjc-v1.1.0%2B-brightgreen" style="display: inline-block;" />
<img alt="cjcov" src="https://img.shields.io/badge/cjcov-97.83%25-brightgreen" style="display: inline-block;" />
<img alt="state" src="https://img.shields.io/badge/state-%E5%AD%B5%E5%8C%96-brightgreen" style="display: inline-block;" />
<img alt="domain" src="https://img.shields.io/badge/domain-OHOS%2FCloud-brightgreen" style="display: inline-block;" />
</p>

## 介绍

`url-parse4cj`（中心仓模块与根包名 `url_parse4cj`）是 [unshiftio/url-parse](https://github.com/unshiftio/url-parse) **1.5.10** 的纯仓颉移植，面向 JavaScript / TypeScript 项目迁移。接口设计参考 [DefinitelyTyped/types/url-parse](https://github.com/DefinitelyTyped/DefinitelyTyped/tree/master/types/url-parse)，查询参数解析与序列化移植自 [unshiftio/querystringify](https://github.com/unshiftio/querystringify) 2.2.0，端口规则通过仓颉中心仓依赖复用 `requires_port` 1.0.0（[requires-port4cj](https://github.com/endermiteDOTcn/requires-port4cj)）。

本库对应 [Cangjie-TPC/TPC-Resource](https://gitcode.com/Cangjie-TPC/TPC-Resource/blob/main/TPC-LIST.md) 适配清单中的 `url-parse`。

### 项目特性

- 完整支持 URL 字段解析、相对路径合并、`blob:` 基准地址处理、认证信息编解码与默认端口归一。
- 提供链式 `set` 字段更新、泛型 `URLParse<T>` 自定义查询解析与序列化回调，以及 `Query`（原始文本与键值对象双形态）。
- 提供 `Url.extractProtocol`、`Url.location`、`Url.trimLeft`、`Url.qs.parse`、`Url.qs.stringify` 辅助接口。
- 26 项原生单元测试，SDK 1.2.1 生产代码行覆盖率 **97.83%**（722/738）；`cjlint` 强制规则 0 报错；101 个上游测试体与多种子行为对照零差异。

### 项目计划

- **已完成**：完成 `url-parse` 1.5.10 与 `querystringify` 2.2.0 行为对齐实现、26 项原生单测、Windows x86_64 / Linux x86_64 / Linux AArch64 六版 SDK 兼容性验证，以及仓颉中心仓 `url_parse4cj` 1.5.10 制品发布；主仓库已统一为中心仓包名 `url_parse4cj` 与依赖 `requires_port = "1.0.0"`。
- **当前阶段**：推进 Cangjie-TPC 社区收录评审（如孵化期需采用 `<1.0.0` 版本号策略，将按社区评审意见在 TPC 主线发布对应孵化版本）。
- **后续维护**：随新版本仓颉 SDK 持续回归验证；跟踪上游安全通告与社区 issue，按需补充 OpenHarmony/HarmonyOS 真机与 macOS 验证。

## 项目架构

本库为纯仓颉静态库（根包 `url_parse4cj`），运行时通过 `cjpm` 中心仓依赖引入 `requires_port` 1.0.0，未嵌套任何第三方运行时依赖源码：

- `src/url.cj`：`Url`、`URLParse<T>` 核心状态、构造、`set` 联动更新与 `toString` 序列化。
- `src/location.cj`：`Location`、协议提取 `extractProtocol`、基准地址解析与相对路径合并。
- `src/query.cj`：`Query` 数据结构与 `QueryString`（`querystringify` 解析/序列化规则）。
- `src/strings.cj`：空白裁剪与 URI 认证编解码。
- `src/types.cj`：查询解析/序列化回调类型别名。

### 源码目录

```text
url-parse4cj/
├── cjpm.toml                       # 模块配置（包名 url_parse4cj，依赖 requires_port 1.0.0）
├── README.md                       # 项目说明
├── README.OpenSource               # 上游开源溯源与许可清单
├── CHANGELOG.md                    # 版本变更记录
├── LICENSE                         # MIT 许可证（保留上游版权）
├── src/
│   ├── url.cj                      # URL 状态、构造、set 和 toString
│   ├── location.cj                 # 基准地址、协议提取与相对路径合并
│   ├── query.cj                    # 原始/对象查询数据、parse 和 stringify
│   ├── strings.cj                  # URI 编解码及字符串处理
│   ├── types.cj                    # 查询回调类型别名
│   ├── url_test.cj                 # 仓颉单元测试（17 项）
│   └── public_api_test.cj          # 公开 API 回归测试（9 项）
├── examples/migration/             # JS/TS 到仓颉的可运行迁移示例
├── tests/compatibility/            # 上游行为对照仓颉回放程序
├── scripts/check_upstream.cjs      # 执行上游测试并对照两版结果
├── doc/
│   ├── feature_api.md              # API 接口说明
│   ├── migration.md                # JS/TS 迁移对应表
│   ├── porting.md                  # 上游来源与实现对应关系
│   ├── validation.md               # 扩展回归、覆盖率与复现方法
│   ├── validation-results.json     # x86_64 机器可读验证汇总
│   └── validation-linux-arm64.json # ARM64 机器可读验证汇总
├── release/
│   └── url_parse4cj-1.5.10.patch   # 2026-11-26 中心仓 1.5.10 制品历史复现补丁
└── upstream/                       # 运行库、类型定义、测试及许可证快照（仅溯源与对照）
```

### 接口说明

主要公开类型与函数包括 `Url`、`URLParse<T>`、`parse`、`Query`、`QueryString`、`Location`、`extractProtocol`、`location`、`trimLeft`。完整签名与行为约定见 [API 文档](doc/feature_api.md)，JS/TS 对照写法见 [迁移说明](doc/migration.md)。

## 使用说明

### 引入与安装

在消费项目的 `cjpm.toml` 中添加仓颉中心仓依赖（[中心仓制品](https://pkg.cangjie-lang.cn/package/url_parse4cj/1.5.10/readme) · [中心仓索引](https://pkg.cangjie-lang.cn/registry/index/ur/l_/url_parse4cj)）：

```toml
[dependencies]
url_parse4cj = "1.5.10"
```

在代码中使用 `import url_parse4cj.*` 导入。因中心仓已存在其他作者的 `url_parse` 包，本库统一采用 `url_parse4cj` 作为中心仓模块名与仓颉根包名。

### 编译构建与验证

加载仓颉 SDK（1.1.0 及以上）后，在仓库根目录执行：

```shell
cjpm clean
cjpm build
cjpm test
cjpm build -g
cjpm test -g
node scripts/check_upstream.cjs
```

切换 SDK 时需同时清理 `examples/migration` 与 `tests/compatibility` 的构建缓存。运行迁移示例：

```shell
cd examples/migration
cjpm clean
cjpm run
cjpm run -g
```

对照脚本执行上游 **101 个测试体**及扩展用例，每次完成 **5,240 项行为比较**并写入 `target/compatibility-results.json`。`UPSTREAM_SEED` 支持 `0` 至 `4294967295` 的非空十进制数字串（默认 `20261021`）。完整八种子复现方法、覆盖率命令与历史矩阵见 [兼容性验证报告](doc/validation.md)。

### 功能示例

#### 解析、修改与自定义查询回调

示例代码（对应 `examples/migration/src/main.cj`）：

```cangjie
import url_parse4cj.*

main() {
    let url = parse("../users?id=42", "https://api.example.com/v1/items", parseQuery: true)
    println(url.href)
    println(url.query["id"].getOrDefault({=> ""}))

    url.set("hostname", "mirror.example.com").set("port", "8443")
    println(url.origin)

    url.set("query", Query([("page", "2"), ("limit", "20")]))
    println(url.toString())

    let custom = parse("/search?q=cangjie", "https://example.com/", {query: String => Query([("raw", query)])})
    println(custom.query["raw"].getOrDefault({=> ""}))
    println(custom.toString({_: Query => "q=custom"}))

    let typed = url.set("query", "token=123", {query: String => query})
    println(typed.query)
}
```

执行结果：

```text
https://api.example.com/users?id=42
42
https://mirror.example.com:8443
https://mirror.example.com:8443/users?page=2&limit=20
?q=cangjie
https://example.com/search?q=custom
token=123
```

## 约束与限制

- **最低 SDK 版本**：主仓库与中心仓制品均要求仓颉 SDK **1.1.0** 及以上（因为 `cjpm.toml` 使用中心仓依赖声明 `requires_port = "1.0.0"`，SDK 1.0.5 无法解析该依赖格式；1.0.5 历史源码兼容基线见提交 `8b142b3`）。
- **已验证平台与 SDK**：
  - 源码历史六版矩阵（SDK `1.0.5 / 1.1.0 / 1.1.3 / 1.1.5 / 1.2.0 / 1.2.1`）：Windows x86_64、Linux x86_64（WSL2）与 Linux AArch64（Ubuntu 24.04.5 chroot），八种子行为对照均零差异（[x86_64 结果](doc/validation-results.json) · [ARM64 结果](doc/validation-linux-arm64.json)）。
  - 中心仓包名 `url_parse4cj` 与依赖 `requires_port = "1.0.0"`：已在 Windows x86_64 上通过 SDK `1.1.0` 与 `1.2.1` 验证（构建、26/26 单测、迁移示例、上游对照、默认 `cjpm bundle` 及空缓存匿名拉取运行）。
- **未验证范围**：尚未实测 macOS、OpenHarmony/HarmonyOS 真机及跨 SDK 二进制混用。
- **历史 1.5.10 制品复现**：2026-11-26 上传的 `url_parse4cj-1.5.10.cjp`（SHA-256：`9fc4f02037e591357712f27f2731add840d6189d26669026e225cdff31f6ebbc`）基于提交 `8b142b3` 应用 [release/url_parse4cj-1.5.10.patch](release/url_parse4cj-1.5.10.patch) 打包，相关补丁保留供溯源。
- **上游维护说明**：上游 `unshiftio/url-parse` 1.5.10 最后提交时间为 2023-01（其 README 亦提及浏览器/Node 环境可优先使用原生 WHATWG URL API）。本库定位为 JS/TS 存量 `url-parse` 代码向仓颉迁移的兼容移植库，锁定版本目前无已知公开安全漏洞，后续由本仓库维护者独立跟进仓颉侧维护。

## 开源协议

采用 [MIT License](LICENSE)，完整保留上游版权与许可证声明。所有上游来源、锁定提交及许可证路径见 [README.OpenSource](README.OpenSource)。

## 参与贡献

- **维护者 / Committer**：`endermite`（GitHub: `endermiteDOTcn`，AtomGit/GitCode: `King_king178`，联系邮箱：`endermite@endermite.cn`）

欢迎提交 Issue 与 PR。修改实现或公共 API 时，请同步更新单元测试与文档，并运行 `cjpm test`、`cjpm bundle` 及 `node scripts/check_upstream.cjs` 验证兼容性。
