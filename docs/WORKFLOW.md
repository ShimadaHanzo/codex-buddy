# 本机 Codex → GitHub → 用户更新

## 仓库与分支

公开仓库：`https://github.com/duoduocats/codex-buddy`。
只提交当前项目根目录，绝不提交父级工作区、auth.json、本机登录信息或日志。
许可证：GPL-3.0-only；应用标识：`com.duoduocat.codexbuddy`。

`main` 保存可发布代码。日常工作使用 `feat/…` 或 `fix/…` 分支，经 PR、CI 通过后合并。
建议在 GitHub Ruleset 要求 PR 和 CI；个人紧急修复也至少本地测试后再发布。

## 本机开发

```sh
git switch -c fix/short-description
bash scripts/test.sh
BUILD_DIR="$(mktemp -d /private/tmp/codex-buddy-dev.XXXXXX)" bash build.sh
git add Sources Tests scripts Info.plist
git commit -m "fix: describe the change"
git push -u origin HEAD
```

让 Codex 基于明确需求实现、检查差异、测试，并创建 PR。签名密钥、GitHub token 不进入对话或源码；使用系统凭据存储。

## 准备版本

版本使用 `MAJOR.MINOR.PATCH`，对应 `vMAJOR.MINOR.PATCH` Git tag。

```sh
python3 scripts/prepare-release.py 1.2.1
# 编辑 releases/v1.2.1.md，写真实变更说明
bash scripts/test.sh
```

只有你明确要求“这个版本需要重大更新弹窗”时才加 `--important`。
这会在对应 Release 正文添加独立行：

```html
<!-- codex-buddy:important -->
```

主版本号改变本身不会弹窗。日常发布绝不自动加这个标记。
该标记由发布维护者控制，不允许从用户输入或更新说明普通文字推断。

## 发布

版本 PR 合并 main 后：

```sh
git switch main
git pull --ff-only
git tag -a v1.2.1 -m "Codex Buddy 1.2.1"
git push origin v1.2.1
```

Actions 在 macos-26 ARM runner 测试并构建，上传 DMG 与 SHA-256，然后创建 **Draft Release**。
维护者查看更新说明和资产后点击 Publish release；这一步才使用户可见。
也可在 Actions 手动运行 Release，选择已存在 tag，`important` 默认 false。
重复发布同 tag 会失败，避免覆盖已经发布的二进制；修复用新版本。

每个 Release 必须包含：
- `Codex-Buddy-X.Y.Z-arm64.dmg`
- 同名 `.sha256`
- 更新说明（GitHub 自动附带该 tag 的源代码 ZIP/TAR，满足对应源码可获取）。

将正式发布设置为 Latest。草稿与预发布不进入更新通道。

## 客户端行为

| 场景 | 行为 |
|---|---|
| 启动/每 6 小时 | 后台查 latest；普通新版本不弹窗、不发系统通知、不自动安装 |
| 点击“检查更新” | 立即查询并显示当前状态，可下载并更新 |
| 维护者明确标记重要版本 | 每个版本自动提示最多一次；可立即更新、稍后或忽略 |
| 忽略版本 | 本机持久保存；主动检查仍可重新发现并安装 |
| 点击“下载并更新” | 原生 URLSession 下载 GitHub DMG、校验、替换和重新启动 |
| 下载/校验失败 | 保留当前版本并在设置中显示错误 |
| 替换失败 | 尝试还原旧版并重新打开 |

重要提醒只作用于 latest 正式版本；重要版本后若有普通补丁，是否继续提醒旧用户需由你明确决定，并在新版本正文保留标记。
“稍后”不会反复骚扰；该版本仍可从设置手动安装。

## 自动安装细节

不需要用户登录 GitHub，不读取 GitHub token。更新源固定为本仓库的公开 HTTPS Releases。
下载链接校验仓库、tag、文件名；重定向只允许 GitHub 官方资产主机。
使用 GitHub Release asset 的 SHA-256 digest，校验包大小、应用标识、版本、最低系统版本、代码签名。
在安装目录旁建立私有临时目录，旧进程退出后将旧 app 移为备份，再将已校验新 app 移到原位置。
更新需要安装目录可写；不弹管理员密码框。请安装到有写入权限的 Applications 目录。
旧版备份在同目录 `.codex-buddy-update-UUID.noindex/previous.app`，可手动恢复；不显示为正常搜索结果。

当前使用 ad hoc 签名和 GitHub HTTPS 发布链路，SHA-256 校验保证下载内容与 GitHub 记录一致，不等同于独立发行者签名。公开长期分发建议后续接入 Developer ID + notarization；证书仅放 GitHub Secrets。

## 首次接入

1. 创建公开仓库并使用 GPL-3.0-only。
2. 提交、推送这个项目目录；CI 测试通过。
3. 发布 v1.2.0（普通静默版本），先检查草稿资产再发布。
4. 用户手动安装一次 v1.2.0，后续版本可应用内更新。
5. 本机应用标识已更换，需要重新选择是否开机启动。

官方参考：
- https://docs.github.com/en/rest/releases/releases
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- https://docs.github.com/en/actions/reference/runners/github-hosted-runners
