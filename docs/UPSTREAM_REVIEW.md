# 上游变更审查记录

## 当前已采纳基线

- 官方仓库：https://github.com/pujiaxin33/JXPagingView
- 已采纳官方基线：`a55dd07adfa9729677e2287943af5aa40f5df31f`。
- 已验收 fork 修订：`76740c71b212b9ac491763e36a5744d73bc9c172`。
- 迁移前 fork master 快照：`8aa5663720ebfab0c4df41cfca04b113f832c5b2`。

## 2026-10-29 主分支迁移：以下内容尚未采纳

以下提交存在于迁移前 master，相对选定基线属于额外更新。本次只登记其历史，
保留已验收的源码、资源、manifest、测试和分发结构；没有把这些提交的内容引入维护版本。

- `8aa5663720ebfab0c4df41cfca04b113f832c5b2` — 添加 paging 嵌套 paging 的示例 gif
- `03c0996af335a359c6c5793673484beb1bcca0eb` — 添加 paging 嵌套 paging 示例
- `2f11692c7401aa9a024c11a864528fce5447bb16` — 添加PagingView 嵌套 两级CategoryView 示例
- `3c8280f01efb6f78ca980ec99acbeb69d3eff767` — 添加 paging 嵌套 category example
- `96ac053f5f1819ad2869c83bab3ec7503bce0e1c` — update podfile
- `38b834a039c124545b8995a5aa4ddce62f8163ac` — 添加侧滑手势处理文档
- `943eb2af9ebe27e0857558ff650ba946fed4c627` — update smooth example
- `bfea789aebd923d5da3289b802329041d84c80f6` — add compiler conditional statement
- `a2961ddb44883676dfb6d49064f4907b1f3a0279` — update list content inset behavior
- `8daafd7b29f1f0825fb068b03dda1c3c693a6fd9` — update example
- `a25b6c67cc20c2548a295058a54213691e114df3` — fix bug #487
- `0fcd07ddfa774553262a5eab011a0a875b0c32e4` — update example
- `aad2a2322348976e08d71267d53535d633997723` — Merge pull request #451 from Xigong93/fix-JXPagerSmoothView-header
- `7118635344871173b0f35fadfe8808cfac66b735` — Merge pull request #512 from TsengWenJian/fix-allowsCacheList
- `f4db2fa0e78c8dc0a70e62aa71d18e6f4e41424f` — Merge pull request #515 from woaiyouxi0803/2.1.4-dev
- `3c665b8f5f471a4cec9227711cc4f44a6b0c4a83` — 2.1.4-dev
- `660d219e3509c705211a51aadb40dc845ddc7907` — 2.1.4 JXRTLFlowLayout 的RTL适配
- `6ab0a94ee75581478d03a7d5dc1ab2b5f230fafa` — fix: allowsCacheList 有開 validListDict 沒同步
- `5699ea390cb1691e2a6afd6dba3b90019f1cf5aa` — 修复了JXPagerSmoothView调用了reloadData后会有空的header，导致header无法点击的bug

首次历史合并后，这些提交已成为 master 的祖先，但这不代表其修改已采纳。
因此再次 merge 同一个 upstream/master 不会补回这些内容。后续升级必须以本记录中的
真实已采纳基线为起点审查差异，再在独立升级分支选择性移植并回归；完成后在本文件
追加已采纳补丁、验证结果与新基线。部分移植不能记为整体升级到该上游 revision。

原始内容仍可使用 `git show <上述提交>:<文件路径>` 查阅，无需改写任何历史。
