---
name: provider-dry-run
description: 外部API、外部provider、Web source、新しい provider adapter を接続する前に実データ dry-run を設計・実行する時に使う。生の観測結果、正規化、データ品質、部分結果、provider 側の完了度、契約有無、欠損、誤判定、未検証点を安全に切り分ける。
---

# Provider Dry Run

外部provider連携を、最初から賢く見せるより先に、現実データで嘘をつかない形へ立ち上げる手順。
本番運用、scheduled job、retry、summary metric、failure taxonomy を固める段階では、配備済みの本番運用化手順や定期実行用の専門workflowへ進む。

## 手順

1. 範囲を最小にする。
   - 1 provider、1用途、少数 wallet / entity、短い期間、明示的な件数上限で始める。
   - 最初から全パターン対応や enrichment を入れない。
2. provider 境界を閉じる。
   - provider 固有レスポンスは adapter 内で受け、domain へは正規化後の public model だけを渡す。
   - raw event をいきなり業務 event へ確定せず、必要なら観測レイヤーを置く。
3. provider contract の有無を確認する。
   - 公式ドキュメント/ OpenAPI / schema / typed SDK があるかを見る。
   - どれを正本にできそうか、まだ未確認の endpoint / query / payload shape が何かを記録する。
   - 生成client、ランタイム guard、retry設計の詳細は、この段階で抱え込みすぎず未検証点として残す。
4. 区別する軸を先に決める。
   - `confidence`: event 解釈の信頼度
   - `valuation`: 金額評価できたか
   - `provider completeness`: 取得が complete / partial / failed のどれか
   - これらを1つの「品質」に潰さない。
5. 最小正規化だけで real data を流す。
   - conservative な reliable 条件だけを通す。
   - 足りない値は無理に埋めず、flags / excluded reason / stop reason として残す。
   - 補完は、欠損率と失敗形が観測できてから後段で足す。
6. dry-run 結果を説明可能に出す。
   - fetched / in-scope / excluded
   - raw observations / normalized models / reliable events
   - flags / excluded reasons
   - confidence / valuation / provider completeness
   - partial result / stop reason / usage
7. 次の一段だけ決める。
   - 実測した現実パターンだけを救済する。
   - 本番 job / webhook / CI へ載せる段階では、provider contract、失敗分類、summary metric を再点検する。
   - 定期実行の外枠を固める段階では、対象リポジトリに定期実行用の専門workflowが配備されているか確認する。
   - UI / report / DB viewer など人間向け readback surface が後からできた場合は、代表ケースが同じ値と理由で見えるか確認する。

## 原則

- まず「賢く見える」より「嘘をつかない」を優先する。
- transfer、trade、valuation、activity のような概念を早い段階で混ぜない。
- 現実データで見えていないパターンを、机上だけで大量実装しない。
- enrichment provider は主役ではなく、観測済み欠損を埋める後段として足す。
- partial result を静かに成功扱いせず、status と stop reason を残す。
- dry-run で分かったことは、次の作業者が再現できる形で開発記録や引き継ぎへ残す。
- 推定値を便利な実測値のように扱わない。名前と判定条件で差を残す。

## 出力

- 初回 dry-run の実行条件
- 観測できた raw observation 数、normalized model 数、除外理由
- confidence / valuation / completeness の現状
- partial result / stop reason / provider contract の未検証点
- まだ補完していない欠損
- 次に救済すべき現実パターン
- 本番運用へ進める前に、配備済みの本番運用化手順や定期実行用の専門workflowで見るべき論点

## 参照

- HTML、検索ページ、browser-rendered DOM を読む Web source の初回観測では、必要に応じて `references/web-source-intake.md` を読む。
- 複数URLや複数 selector 候補を親エージェントの本流作業と並列に探索したい時は `references/optional-source-scout.md` を読む。
- dry-run 後に UI / report / DB viewer などの readback surface で代表ケースを再確認する時は、観測値、正規化値、除外理由が同じ値として見えるか確認する。
