---
name: godot-smoke-test
description: Godot 4 / .NET / C# project の変更後に build、headless起動、scene起動、Godot実行ファイル確認をしたい時に使う。Godot.NET.Sdk、project.godot、autoload、input map、sandbox / tooling 由来の失敗と project 由来の失敗を分けて smoke test する。
---

# Godot Smoke Test

Godot project の「build は通るが、起動できるとは限らない」を潰すための最小検証 workflow。

## 使う場面

- Godot project を新規作成した時。
- Godot C# script、scene、project.godot、input map、autoload などを変更した時。
- ユーザーが Godot の場所を教えてくれた、または Godot が PATH にない時。
- GUI で遊ぶ前に、最低限 project / scene が読めるか確認したい時。

## 手順

1. project を確認する。
   - `project.godot` の場所を見つける。
   - `run/main_scene` または確認対象 scene を確認する。
   - C# project の場合は `*.csproj` と Godot.NET.Sdk version を確認する。
2. Godot 実行ファイルを探す。
   - `godot` / `godot4` が PATH にあるか見る。
   - ユーザーが示した path があれば優先して確認する。
   - Windows では C# project なら `*_mono_*` build を優先する。
   - リポジトリや環境固有の絶対 path を project file に書き込まない。
3. version / help を確認する。
   - `--version` または `--help` で実行ファイルが正しいか見る。
4. C# build を確認する。
   - C# project がある場合は `dotnet build <project.csproj>` を実行する。
   - build 成功と ランタイム成功を混同しない。
5. headless scene 起動を確認する。
   - 例: `<godot-console> --headless --path <project-dir> --scene <scene> --quit-after 5`
   - scene 指定が不要な場合は main scene を使う。
   - import が必要な project では `--import` や editor 起動の必要性を切り分ける。
6. 失敗を分類する。
   - sandbox / permission / `user://logs` / local user data 書き込みの失敗は、すぐ project bug と断定しない。
   - 重要な確認が sandbox 由来で失敗した場合は、承認を得て unrestricted に再実行する。
   - Godot engine crash、project load error、script error、scene missing を分けて記録する。

## 出力

- 使用した Godot executable
- Godot version
- build 結果
- headless scene 起動結果
- sandbox / tooling 由来の問題があったか
- GUI 実プレイ確認が必要か

## 注意

- GUI の editor / game window を開く必要がある時は、明示的に許可を取る。
- local machine 固有の Godot install path は、skill や template にハードコードしない。
- headless 起動が通っても、入力や描画の手触りは最終的に人間の実プレイ確認が必要なことがある。
