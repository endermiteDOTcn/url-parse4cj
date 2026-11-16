# Changelog

## Unreleased

- 验证六个 SDK（1.0.5、1.1.0、1.1.3、1.1.5、1.2.0、1.2.1）在 Windows/Linux x86_64 的 release/debug 构建、单测、示例及消费端集成。
- 已合并的 9 个公开 API 回归用例使原生单测增至 26 个，补充 SDK 1.2.1 / Windows 的行覆盖率报告。
- 上游对照脚本支持 `UPSTREAM_SEED`，在入口校验非空十进制 uint32，并记录实际输入 SHA-256；保持默认种子并记录八种子 release 对照结果。
- 为 URL 空密码字段和解析测试字符串添加精确 cjlint 例外说明；公共 API 和执行逻辑不变。

## 1.5.10

- 移植 `url-parse` 1.5.10 的解析、相对地址合并、字段修改和序列化行为。
- 参考 DefinitelyTyped 定义提供 `Url`、`URLParse<T>`、查询回调和辅助函数。
- 添加 `Query` 查询数据类型及 `querystringify` 转换。
- 复用 `requires-port4cj` 的端口判断。
- 添加仓颉测试、上游行为对照和 JS/TS 迁移示例。
