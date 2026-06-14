# Health Connect / Location Spike

Android で Health Connect、位置情報、センサー系の個人データを扱う時の確認メモ。
公式仕様は変わるため、実装前に Android Developers の該当ページを確認し、ここは観点と順番のメモとして扱う。

## Health Connect availability

- Android 14 以降では Health Connect は framework module として扱われる。
- Android 13 以下では Health Connect app の導入が必要になる場合がある。
- 実機では、未対応、未インストール、更新必要、利用可能を UI と log で分けて観測する。

## Permission spike

- request する data type を最小にする。
- permission は利用前に毎回 grant 状態を再確認する。ユーザーは後から revoke できる。
- permission UI が開いたことだけで完了にしない。許可後に required permissions が granted へ反映されることまで見る。
- sample manifest は広い権限、write 権限、route 権限を含みやすい。必要な宣言だけを移す。
- Health Connect の permission rationale / usage activity は、対象 SDK と Jetpack version に合わせて公式ドキュメントで確認する。

## Read spike

- steps や distance のような累積値は、まず aggregate で読む。
- raw records は page size / pagination、空データ、provider差分を考える。
- dataなしは正常系として扱い、`0` / 空一覧と error を分ける。
- historical read や background read は追加permissionや制約がある。v0 / spike では defer を基本にする。
- Exercise route や詳細な位置情報は privacy risk が高いため、必要になるまで読まない。

## Location

- 位置情報は foreground / background、precise / approximate を分ける。
- background location は本当に core feature に必要かを先に確認する。
- Android 10 以降は background location に `ACCESS_BACKGROUND_LOCATION` が必要になる。
- Android 11 以降は background location の許可導線が foreground permission と異なる。教育UIや設定画面への導線が必要になる場合がある。
- 位置情報を外部へ送る前に、詳細座標、route points、自宅/職場が推定できる地点を除外または加工する。

## MAUI / C# binding で見た注意

- `adb` が PATH にない時は Android SDK の `platform-tools/adb` を直接確認する。
- Debug APK を直接 `adb install` する場合、Fast Deployment 前提の生成物で起動直後に落ちることがある。必要なら assemblies を APK に埋め込む設定を確認する。
- build timeout や途中停止後は壊れた APK が残ることがある。clean / rebuild し、APK 内に dex とランタイムライブラリがあるか確認する。
- Kotlin `suspend` 関数の C# binding では、`COROUTINE_SUSPENDED` ではなく即値が返る場合がある。bridge は即値も Task 完了として扱う。
- Android binding や Java Callable Wrapper が絡む helper は、生成される Java/Kotlin 側の名前も意識する。

## 実機確認の順番

1. `adb devices` で対象端末が `device` になっていることを確認する。
2. install / launch の前に crash log を消す。
3. APK install。
4. app launch。
5. process 生存確認。
6. crash log 確認。
7. UI dump またはスクリーンショットで availability / permission state を記録する。
8. permission request は必要ならユーザー操作を挟む。
9. grant 後に app へ戻り、granted / missing を再確認する。

## 参照

- Android Health Connect get started: https://developer.android.com/guide/health-and-fitness/health-connect/get-started
- Android Health Connect read data: https://developer.android.com/health-and-fitness/health-connect/read-data
- Android Health Connect aggregate data: https://developer.android.com/health-and-fitness/health-connect/aggregate-data
- Health Connect data types / additional permissions: https://developer.android.com/health-and-fitness/health-connect/data-types
- Android location permissions: https://developer.android.com/develop/sensors-and-location/location/permissions
- Android background location: https://developer.android.com/develop/sensors-and-location/location/background
- OpenAI API key safety: https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety
