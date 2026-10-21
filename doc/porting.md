# 移植说明

## 上游来源

| 内容 | 来源 |
| --- | --- |
| 运行库与测试 | [unshiftio/url-parse](https://github.com/unshiftio/url-parse)，1.5.10，提交 `877225add9c3a2e33ef20ebef94dd397a0965666` |
| 类型定义与调用样例 | [DefinitelyTyped/types/url-parse](https://github.com/DefinitelyTyped/DefinitelyTyped/tree/master/types/url-parse) |
| 查询转换 | [unshiftio/querystringify](https://github.com/unshiftio/querystringify)，提交 `60d8dd92aeb5550fb79b93e6dae193d02e029daf` |
| 默认端口判断 | [requires-port4cj](https://gitcode.com/gcw_kMd990Oo/requires-port4cj)，模块 `requires_port` |

源码快照位于 `upstream/`，包含原始许可。`upstream/manifest.json` 记录版本、提交和类型文件摘要。

## 实现对应

| 上游模块或规则 | 仓颉实现 |
| --- | --- |
| `Url` 构造、`rules`、`set`、`toString` | `src/url.cj` |
| `extractProtocol`、`lolcation`、`resolve` | `src/location.cj` |
| `querystringify` | `src/query.cj` |
| `trimLeft`、`trim`、URI 认证编解码 | `src/strings.cj` |
| TypeScript `URLParse<Query>` | 仓颉 `URLParse<T>` |
| 默认查询的字符串 / 对象形态 | 仓颉 `Query` |
| TypeScript 查询回调改变返回类型 | `set<U>` 返回共享状态的 `URLParse<U>` |

构造和 `set` 分别沿用上游的处理顺序。默认端口、认证规范化、特殊协议斜杠、
`file:` 驱动器路径、未知协议、空认证、尾部冒号及相对路径合并都由对照测试验证。

上游在纯路径分支使用 `/(.*)/`，会在 U+2028/U+2029 处截断路径；仓颉实现保留这一行为。
`set("auth", "username")` 会保留已有密码，`set("host", "host:80")` 与
`set("port", "80")` 按各自分支更新字段。这些规则均有回归用例。

## 验证流程

1. `cjpm test` 运行仓颉 API、查询、认证、相对地址、泛型回调和共享状态的单元测试。
2. 对照脚本在 Node.js 中执行保留的上游测试体，使用 `node:assert` 实现其断言接口。
3. 脚本记录解析输入、基准地址、`set` 操作、直接赋值及序列化回调，再回放到仓颉程序。
4. 协议与斜杠矩阵、字段修改矩阵、Unicode 控制字符、查询编码、blob 基准地址和固定种子生成输入补充对照。
5. 两版输出按字段比较；差异报告包含输入命令、期望字段和实际字段。

`scripts/check_upstream.cjs` 的运行产物保存在 `target/`，仓颉对照程序位于 `tests/compatibility/`。
可运行迁移示例位于 `examples/migration/`。
