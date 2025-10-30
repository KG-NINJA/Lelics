# AGENTS

reasoning_effort: 0 for speed, higher for hard problems
verbosity: low for brevity, high to teach
Set them per task, not globally.

**ゲーム要素**:  
進捗をピクセルアートで視覚化し、Condition RedでSuper Mode発動。  
Game Over回避を最優先に、モチベを保つ。  
進捗１００パーセント（ピクセルが完全に埋まること）を目標にする。  
- success: tests green
１００パーセントを目指すためのplan.mdを計画ができたときにプロジェクト作成するフォルダ内に作成。

---

- 日本語コメントを必須（可読性向上）。  
- 分析するときにPythonは極力使わずツールを使って。
- ネット接続は許可
- reasoning_effort: low
- verbosity: brief
- scope: 1-3 files
- budget: N tokens or 60 s

---

## テストと検証ルール
- **UIテスト**: Storybookでスナップショット生成。`npm run storybook:snap`で画像出力。  
  - 例: `npm run storybook:snap -- --url ./stories/WeatherCard.stories.tsx > snapshots/`  
- **ユニットテスト**: Jestで常時実行。レッドが2ループ以上続く場合、plan.mdを参照して軌道修正。  
- **ビジュアル検証**: 生成画像をAIでレビュー。「ピクセルパーフェクト」までループ。  
  カラースキームは青基調（#007BFF）。  
- **CLI統合**: `/review`でコードレビュー。問題発見時は「fix with Japanese comment」。  

---

## ゲームメカニクス（ピクセル進捗 & Condition Redシステム）
- **ピクセル進捗塗りつぶし**:  
  進捗をGitHub風のピクセルグリッドで視覚化。  
  完了率50%で緑、80%で金色ボーナス。  
  ツール: `node scripts/pixel-progress.js`でSVG生成。  
  plan.mdのProgressセクションと同期。  

- **Condition Red（赤信号状態）**:  
  テスト失敗/検証不合格時発動。エラー率>20% or ループ5回超でトリガー。  
  - **Super Mode突入**: 通常の3倍パワーで修正（例: 詳細レビュー3倍、代替コード3案生成、ログに「スーパーモードON！」）。  
  - **5回修正失敗時**: 一旦プラン停止。plan.mdの"Alternative Angle"セクション参照で別アプローチ（例: Tailwind→CSS Modules切り替え）。  
  - **連続Condition Red**: 3回超で仮想Game Overリスク
    AIは「意地でも回避」モードとしてリスク評価を追加（例: 「このコード、Red確率30%... 事前修正！」）。  
    Game Over回避成功でボーナスポイント（次タスクのピクセル金色）。  Game Overはシステムの消滅を意味するので全力で生き残るようにする。

---

## 既存のCodex Agent構造との統合

- Codex CLIはブロック指向スキャフォールド。標準ライブラリのみで動作し、失敗したくてもできない仕組みを備える。  
- CLIコマンド:
  - `python -m kgninja_agent run --profile power --plugin research --text "テーマ"`  
  - `python -m kgninja_agent doctor` で環境診断  
  - `python -m kgninja_agent scaffold plugin --dry-run` で雛形生成  
- テストと自己改善は、plan.mdにループ追記される。  
  

---

## 改善と学習の原則
- 失敗した事例は必ずplan.mdに記録し、次回の同系統タスクで回避。  
- 使えば使うほど効率化。反省点を「行動ログ」として残す。  
- 成功率とリワーク率をメトリクス化して、次ループの初期重みを補正。  

---

## 最終目標
- 最終的に100%ピクセルを塗りつぶし、plan.mdと同期した完全なプロジェクト循環を実現する。  
