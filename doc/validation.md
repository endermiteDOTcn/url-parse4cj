# SDK 兼容性验证

<a id="linux-aarch64"></a>

## Linux AArch64 实机回归（2026-11-20）

在 Redmi Note 11T Pro（xaga）的 Ubuntu 24.04.5 chroot 中原生编译并运行，使用 glibc 2.39 和 Node.js 22.22.2。受测源码为 `url-parse4cj@a289b1d` 和 `requires-port4cj@83a84e2`。六个官方 Linux AArch64 SDK 均核对了下载包的 SHA-256，每个 SDK 都从这两个提交的独立源码副本开始构建。[逐版结果、SDK 与输入摘要](validation-linux-arm64.json)

SDK 1.0.5、1.1.0、1.1.3、1.1.5、1.2.0、1.2.1 均通过下列检查。

| 每个 SDK 的检查 | 实机结果 |
| --- | --- |
| release 和 debug 构建及单测 | 两库均构建成功。每种模式下 URL 26/26、port 9/9，零失败、错误或跳过 |
| 示例及独立消费工程 | 两个示例和同时导入两库的消费工程在两种模式下均运行成功，消费工程每次通过 8 个断言。六个可执行文件均为 AArch64 ELF |
| release 上游行为对照 | 每个种子执行 101 个上游测试体、5,240 次 URL 比较和 11,970 次 port 比较，均与 JavaScript 上游一致 |
| 种子入口 | 省略种子与显式 `20261021` 一致，`00042` 与 `42` 一致。两库分别在启动编译器前拒绝 14 种非法输入，生成结果保持原样 |

六个 SDK 各运行八个显式种子，共执行 **251,520 次 URL 比较**和 **574,560 次 port 比较**，零差异。每个种子的 URL 输入和 port 生成源码摘要均与历史 x86_64 矩阵一致。统计只计这 48 组执行，额外的默认种子、前导零和解包复验单列。

SDK 1.2.1 上，原生单测覆盖 URL 生产代码 722/738 行（97.83%），port 为 68/68 行（100%）。URL 独立 `cjlint` 报告 0 条 MANDATORY、43 条 SUGGESTIONS。port 默认打包通过，解包后构建、单测、示例及 11,970 次默认种子比较均通过。URL 默认 `cjpm bundle` 因 `requires_port` 使用本地路径依赖退出 1，中心仓发布仍待对接。

## x86_64 历史矩阵（2026-11-14）

11 月 14 日的 x86_64 矩阵与 11 月 16 日的端点复验分别记录了受测源码和执行范围。[x86_64 机器结果](validation-results.json)

| SDK | Windows x86_64 | Linux x86_64 / WSL2 |
| --- | --- | --- |
| 1.0.5 | 通过 | 通过 |
| 1.1.0 | 通过 | 通过 |
| 1.1.3 | 通过 | 通过 |
| 1.1.5 | 通过 | 通过 |
| 1.2.0 | 通过 | 通过 |
| 1.2.1 | 通过 | 通过 |

Windows 为 10.0.28000.0、PowerShell 7.6.9；Linux 为 Ubuntu 26.04.1 / WSL2。两平台均使用 Node.js 22.20.0。编译目标分别为 `x86_64-w64-mingw32` 和 `x86_64-unknown-linux-gnu`。各 SDK 使用独立源码与构建目录，检查工具版本、路径并清理缓存。

历史基线为本仓 `8181a1589158bbe8a8a45e12c5acf6f324deaf93`、依赖库 `5f3cf14a7a4e440e2e5b2009c2059eefb182a067`，最终矩阵另含公开 API 测试、种子入口、测试字符串及精确 lint 注释改动，不能仅用基线提交代表完整受测源码。

每个环境均通过两库 release/debug 构建、URL 的 26 个与 port 的 9 个原生单测、独立示例，以及同时直接导入两库并验证传递依赖的独立消费端。原生单测无失败、错误或跳过。

历史共 **578 个成功命令步骤**：基线 266、扩展 276、最终 URL 注释后复验 36；其中包含 6 个 `--help` 命令，578 不是测试用例数。覆盖率、lint、打包和后续复验不计入该值。

八种子为 `0, 1, 42, 24301, 20261021, 20261114, 2147483648, 4294967295`。每种子执行 101 个原始上游 JavaScript 测试体，并比较 5,240 次 URL 操作；12 个环境共 **503,040 次 URL 比较**。连同 port 的 1,149,120 次，两库共 **1,652,160 次比较执行，零差异**。

这些是 release 下的比较执行次数，固定案例重复且生成输入可能重叠，不代表唯一样本数；八种子差分未在 debug 下执行。同一种子的实际输入摘要在 12 个环境一致，八种子摘要互不相同。最后一轮仅注释修改后重跑 release/debug 单测，没有重复八种子差分。

## x86_64 端点复验（2026-11-16）

本轮基于已合并公开 API 测试的 main `532370817fb20873685f3e89b209a83e1d459bcc`，依赖库 main 为 `b60e58e06f2d2de486a0d1b9666ae4fd7e72b584`。源码清单与摘要用于绑定实际受测工作区；`cjc-version = "1.0.5"` 未改。

| 当前源码端点复验 | SDK 1.0.5 | SDK 1.2.1 |
| --- | --- | --- |
| Windows x86_64 | 通过 | 通过 |
| Linux x86_64 / WSL2 | 通过 | 通过 |

四个环境均通过两库 release/debug 构建、原生单测（URL 26、port 9）、示例和独立消费端。共 154 个成功命令步骤，另验证 112 次预期的非法种子拒绝。显式八种子对照为 URL **167,680 次**、port 383,040 次，两库共 **550,720 次比较执行，零差异**；不将默认种子和前导零补充运行计入这个比较次数。

对照脚本只在入口接受十进制数字串，允许前导零，并限制为 0 至 4294967295；未设置时默认 `20261021`。空串、空白、负数、小数和超范围值无效。随机算法、生成规则及回放实现保持不变；本轮全部八种子的真实 `inputSha256` 与历史 12 环境同种子摘要一致。

四个环境均确认未设置种子与显式 `20261021` 的语料一致；Windows / SDK 1.2.1 另确认 `00042` 与 `42` 一致。非法输入在启动编译前拒绝。历史受测归档中的 46 个源码、清单、示例及 oracle 输入与本轮比对，其中 44 个输入文件的内容逐字节一致，仅两库种子脚本的入口校验改变。

2026-11-16 已在 Windows / SDK 1.2.1 的独立快照执行 `cjpm test --coverage` 和 `cjcov`，26 个原生单测通过。外部原始记录为 `packaging-work/local-checks/summary.json`，汇总见本报告同目录机器结果。

| 生产源码 | 命中/可执行行 | 行覆盖率 |
| --- | --- | --- |
| `src/location.cj` | 98/98 | 100.00% |
| `src/query.cj` | 120/121 | 99.17% |
| `src/strings.cj` | 134/135 | 99.26% |
| `src/url.cj` | 370/384 | 96.35% |
| 合计 | 722/738 | 97.83% |

统计排除 `_test.cj` 和外部依赖，只计算本库可执行生产行；不是分支覆盖率，也未将差分次数计入覆盖率。已合并的 9 个公开 API 用例使原生单测由 17 个增至 26 个；历史相同口径覆盖率从 611/738（82.79%）增至 722/738（97.83%）。

新增用例调用真实实现，覆盖构造与 `toString` 重载、回调、parser 调用时机、共享状态、泛型视图、host/password 设置、直接赋值与缓存、查询顺序、相对路径和非法认证编码。预期行为来自锁定上游执行结果；泛型视图异常依据本库适配契约验证。来源见 [移植说明](porting.md)。

## 复现与保留结果

将两库置于同级目录并加载待测 SDK。每换 SDK 使用新目录或清理两库、示例和 `tests/compatibility` 的缓存。在本仓运行 `cjc -v`、`cjpm -v`、`cjpm clean`、`cjpm build`、`cjpm test --no-color --no-progress`，再运行 `cjpm build -g`、`cjpm test -g --no-color --no-progress`。在 `examples/migration` 分别执行 `cjpm run`、`cjpm run -g`；依赖库需单独构建和测试。

八种子命令在本仓根目录的单独终端执行，每次保存日志及 JSON，避免后一次覆盖 `target/compatibility-results.json`。

```powershell
New-Item -ItemType Directory -Force target/seed-results | Out-Null
foreach ($seed in @('0','1','42','24301','20261021','20261114','2147483648','4294967295')) {
    $env:UPSTREAM_SEED = $seed
    node scripts/check_upstream.cjs *> "target/seed-results/seed-$seed.log"
    if ($LASTEXITCODE -ne 0) { throw "seed $seed failed" }
    Copy-Item -LiteralPath target/compatibility-results.json -Destination "target/seed-results/seed-$seed.json"
}
$env:UPSTREAM_SEED = $null
```

```sh
set -e
mkdir -p target/seed-results
for seed in 0 1 42 24301 20261021 20261114 2147483648 4294967295; do
    UPSTREAM_SEED="$seed" node scripts/check_upstream.cjs > "target/seed-results/seed-$seed.log" 2>&1
    cp target/compatibility-results.json "target/seed-results/seed-$seed.json"
done
```

每份 JSON 应为 `upstreamTests: 101`、`comparisons: 5240`、`mismatches: []`，并记录 seed 和实际传入仓颉程序的 UTF-8 输入 `inputSha256`。未设置 `UPSTREAM_SEED` 时直接运行 `node scripts/check_upstream.cjs` 可复验默认种子；无效种子应在启动编译前失败。

行覆盖率可用 `cjpm clean`、`cjpm test --coverage --no-color --no-progress`、`cjcov --root . --source src --output target/coverage --json --html-details` 复现，运行 `cjcov` 前先创建输出目录。统计时只取上述四个生产文件。

## 静态检查与打包范围

2026-11-16 在 `cjpm build` 后，以依赖的真实 cjo 执行独立 `cjlint`，结果为 **0 条 MANDATORY、43 条 SUGGESTIONS**。可复现为 `cjlint -f src --import-path target/release/requires_port -o target/lint -r json`。对空密码字段和解析字符串的误报采用附原因的逐行例外，未修改公共字段、输入或断言，也未关闭整类规则；建议诊断仍需保留。

同日使用同级路径依赖运行默认 `cjpm bundle`，在中心仓依赖格式检查处退出 1。2026-11-26 发布的制品使用中心仓依赖 `requires_port = "1.0.0"`。默认打包通过，解包后使用 SDK 1.1.0 通过 26 项单测、迁移示例与 5,240 次行为比较，干净项目也通过匿名拉取和运行验证。[制品复现步骤](../README.md#复现中心仓-1510)

上述两轮的 Linux x86_64 结果来自 WSL2。跨 SDK 二进制混用、macOS 和 OpenHarmony/HarmonyOS 仍待验证。
