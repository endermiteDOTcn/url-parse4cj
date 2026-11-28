# [Unreleased]

## Feature

+ 主仓库切换为与仓颉中心仓一致的模块及根包名 `url_parse4cj`，将依赖切换为中心仓声明 `requires_port = "1.0.0"`，最低 `cjc-version` 调整为 `1.1.0`，并同步更新示例、对照工程与文档导入路径。
+ 补齐 Cangjie-TPC 规范要求的根目录 `README.OpenSource`、README 模板结构及 `cjpm.toml` 展示元数据。
+ 2026-11-26 已将 `url_parse4cj` `1.5.10` 发布至仓颉中心仓并通过空缓存匿名拉取验证，仓库保留 `release/url_parse4cj-1.5.10.patch` 供复现。
+ 完成六个 SDK（1.0.5、1.1.0、1.1.3、1.1.5、1.2.0、1.2.1）在 Windows x86_64、Linux x86_64（WSL2）及 Linux AArch64 的 release/debug 构建、单测、示例及消费端验证。
+ 补充 9 个公开 API 回归用例，原生单测增至 26 项，SDK 1.2.1 生产行覆盖率提升至 97.83%（722/738）。
+ 上游对照脚本支持 `UPSTREAM_SEED` 非空十进制 uint32 校验，并记录输入 SHA-256。

## Bugfix

+ 为 URL 空密码字段和解析测试字符串添加带原因的精确同行 `cjlint-ignore` 例外说明（0 MANDATORY），公共 API 与执行逻辑不变。

## Remove

+ 移除主仓库中 `url_parse` 旧根包名与同级相对路径依赖 `requires_port = { path = "../requires-port4cj" }`，统一使用中心仓包名 `url_parse4cj` 与依赖 `requires_port = "1.0.0"`。

<br>

# [1.5.10]

## Feature

+ 移植 `unshiftio/url-parse` 1.5.10 的解析、相对地址合并、字段修改和序列化行为。
+ 参考 DefinitelyTyped 类型定义提供 `Url`、`URLParse<T>`、查询回调与辅助函数。
+ 移植 `querystringify` 2.2.0 的查询参数解析与序列化行为，提供 `Query` 与 `QueryString`。
+ 复用 `requires_port` 的默认端口判断，添加单元测试、上游行为对照程序与 JS/TS 迁移示例。

## Bugfix

+ 无。

## Remove

+ 无。
