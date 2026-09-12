# Optional development workflow reference

Read only when optional progress tracking helps a complex requested implementation. All gamified states and percentages are illustrative. They never override scope, stopping rules, budgets or verified completion.

[AGENTS.md](../AGENTS.md) governs authorization, stopping, scope and current
verification commands. This reference adds no authority.

# AGENTS

reasoning_effort: 0 for speed, higher for hard problems
verbosity: low for brevity, high to teach
Set them per task, not globally.

**ゲーム要素（複雑な実装時の任意の進捗表示）**:
進捗をピクセルアートで視覚化し、Condition RedでSuper Mode発動。\
依頼の完了条件と停止指示を優先し、進捗表示のために作業範囲を広げない。
進捗１００パーセント（ピクセルが完全に埋まること）を目標にする。\
- success: requested outcome and relevant verification complete
複雑な実装で継続記録が必要な場合に既存の plan.md を更新する。軽微な変更に計画・進捗画像の新規作成は不要。

---

- 日本語コメントを必須（可読性向上）。\
- 分析するときにPythonは極力使わずツールを使って。
- ネット接続は許可
- reasoning_effort: low
- verbosity: brief
- scope: requested change; prefer small diffs
- budget: current task and host limits

---

## テストと検証ルール
- 変更内容に関係する、AGENTS.md に記載された実在する検証手順を使う。未導入の Storybook/Jest や仮の CLI を必須条件にしない。
- UI・ゲーム変更では対象の表示と操作を確認する。文書だけの変更には差分・参照・指示整合性の確認を行う。
- ビジュアル変更時の色の指針は青基調（#007BFF）。
- 同じ失敗を繰り返さず原因を切り分け、方法を変える。未確認事項を成功扱いしない。

---

## ゲームメカニクス（ピクセル進捗 & Condition Redシステム）
- **ピクセル進捗塗りつぶし**:\
  進捗をGitHub風のピクセルグリッドで視覚化。\
  完了率50%で緑、80%で金色ボーナス。\
  進捗表示ツールは、実在するものがある場合だけ使用する。
  plan.mdのProgressセクションと同期。\

- **Condition Red（赤信号状態）**:\
  テスト失敗/検証不合格時発動。エラー率>20% or ループ5回超でトリガー。\
  - **Super Mode突入**: 原因と証拠を確認し、最小修正で再検証する。
  - **同じ修正の失敗が続く場合**: 方法を変えて切り分ける。独立作業を続け、進展がない対象は阻害要因を記録する。
  - **連続Condition Red**: 3回超で仮想Game Overリスク
    AIは「意地でも回避」モードとしてリスク評価を追加（例: 「このコード、Red確率30%... 事前修正！」）。\
    Game Over回避成功でボーナスポイント（次タスクのピクセル金色）。  Game Over は表示上の比喩であり、停止指示・予算・実行制限を優先する。

---

## 開発手順との統合

- AGENTS.md に記載されたプロジェクト資料と実在するコマンドを使う。未導入の `kgninja_agent` を必要条件にしない。
- 継続に必要な短期記録は作業記録へ保存し、恒常指示の AGENTS.md へ自動追記しない。

---

## 改善と学習の原則
- 継続に必要な失敗事例は既存の作業記録に残し、同じ失敗を避ける。
- 使えば使うほど効率化。反省点を「行動ログ」として残す。\
- 成功率とリワーク率をメトリクス化して、次ループの初期重みを補正。\

---

## 最終目標
- 最終的に100%ピクセルを塗りつぶし、plan.mdと同期した完全なプロジェクト循環を実現する。
