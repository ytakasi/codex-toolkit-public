---
name: android-mobile-risk-burndown
description: Android / Kotlin / .NET MAUI などの mobile app で、Health Connect、位置情報、センサー、個人データ、OpenAI API などの外部API proxy を扱う前に使う。実装へ直行せず、toolchain、公式ドキュメント、参考実装、ライセンス、permission UI、実機 availability、read spike、secret境界、privacy/data boundary を順に潰す。
---

# Android Mobile Risk Burn-down

Android / mobile app で、健康データ、位置情報、センサー、個人データ、外部APIを扱う前に、大きな実装へ入らず小さい観測でリスクを潰す。

## 正本

- 既存リポジトリなら README、`AGENTS.md`、roadmap、privacy model、risk register、decision log、setup docs を先に見る。
- 新規リポジトリなら `repo-bootstrap` と `project-preflight` で、MVP、やらないこと、privacy / secret 境界、risk register を先に置く。
- toolchain で詰まったら `local-toolchain-diagnostics` を使う。
- 外部APIやproviderの現実データを見る時は、外部連携用の専門workflowが配備されているか確認し、なければこの skill 内で最小観測、raw data、正規化、未検証点だけを分ける。
- 設定や保存値、CI/CD、署名、deployを触る時は、該当profileの専門workflowが配備されているか確認し、なければこの skill では境界と未解決事項だけを残す。

## 手順

1. MVP とやらないことを切る。
   - 最初に読むデータ型、送るデータ、保存するデータを限定する。
   - 位置情報、route、background access、外部保存、公開配布は、必要になるまで defer する。
2. privacy / secret 境界を先に書く。
   - 生GPS、route points、自宅/職場を推定できる詳細座標、実在個人の活動ログを外部送信や fixture に入れない。
   - OpenAI API key などの secret は mobile app に置かず、backend / Worker / server 側へ置く。
   - 外部送信前に、raw data、processed data、推定、表示文を分ける。
3. toolchain を確認する。
   - Android Studio / Android SDK / JDK / Gradle / adb / emulator / MAUI workload など、使う stack だけを確認する。
   - 「PATHにある」と「実際に起動できる」と「実機/エミュレータで動く」を分ける。
4. 公式ドキュメント、参考実装、license を確認する。
   - Android / Health Connect / location / Play policy / OpenAI など、変わりやすい仕様は公式ドキュメントを確認する。
   - 参考リポジトリは commit / tag / license / 借りる概念 / そのまま持ち込まない範囲を記録する。
5. permission / availability spike を作る。
   - 権限宣言、rationale、request UI、grant / revoke 後の再確認を実機で見る。
   - build が通るだけで完了扱いにしない。
6. read / data spike を小さく進める。
   - 最初は1データ型、1日、少数record、実データあり/なしを分ける。
   - 空データは正常系として扱い、error と区別する。
7. 外部API proxy を先に固定 fixture で通す。
   - mobile app から直接 secret を使わない。
   - Worker / backend は入力 schema、secret 未設定時の error、出力 schema を先に固める。
   - OpenAI など LLM 連携では structured output / schema validation を使えるか確認する。
8. privacy / data boundary review を実装前後に行う。
   - schema、fixture、log、docs、`.gitignore` を privacy model と照合する。
   - 生データ、secret、実在個人ログがリポジトリや外部APIに混ざっていないか見る。

## Health Connect / location

Health Connect、位置情報、background location、Android 実機確認の詳細は `references/health-connect-and-location-spikes.md` を読む。

## 出力

- 実行した command と結果。
- 確認した公式ドキュメント / 参考リポジトリ / ライセンス。
- risk status の変更。
- 変更した files。
- まだ不明な端末差分、権限差分、provider差分。
- 次に潰す risk item。

## 判断チェック

- mobile app に secret を置いていないか。
- raw data と processed data と diary / display data を混ぜていないか。
- permission UI 起動だけでなく、grant / revoke 後の再確認まで見たか。
- 実機未確認なのに risk を mitigated にしていないか。
- fixture や docs に実在の健康データ、位置情報、private URL が入っていないか。
- 公式ドキュメントと参考リポジトリのどちらを根拠にした判断か分けているか。
