# Lelics / Godot 4.7.2

Godot版を主実装とする16ビット風の憑依アクション。`index.html`は比較用の旧HTML版。

- Windows: `exports/Lelics-Windows.zip`を展開して`Lelics-16bit.exe`を起動。
- Web: `exports/web/`をHTTPサーバーで配信。`file://`の直接起動には対応しない。
- ソース: `godot/project.godot`をGodot 4.7.2で開く。
- 操作: 矢印で移動、Spaceで跳躍、Zで離脱、Xで憑依、Cで会話・端末操作。

関門は守衛以上の位階、端末への憑依は主任の位階が必要。端末操作で扉を開け、ランナーへ戻って出口へ進む。ステージ2では3人のボディーガードをそれぞれボスに接近させ、Cで拘束する。倒れた器は再使用できない。最後はランナーで脱出する。

物理60Hz、速度150px/s、加速420、減速300、反転260、ジャンプ-480、重力1350。描画位置と関節姿勢を補間し、低解像度640x360を最近傍で拡大する。外部API・オンライン依存はない。BGMなしで、波の環境音・電子機器の操作音・攻撃ヒット音のみ。音は標準ライブラリによるオリジナル合成で、`scripts/generate_audio.py`から再生成できる。

## 再ビルドと検証

Windows PowerShellで `./scripts/build.ps1 -Godot 'Godotの実行ファイルパス'`。Godot 4.7.2のWindows/Webエクスポートテンプレートが必要。既定のテンプレートパスはSteam版で、別配置なら`godot/export_presets.cfg`を変更する。

- ソース検証: `godot --headless --path godot --script tests.gd`
- Windows出力検証: `exports/Lelics-16bit.exe --headless -- --verify`
- Web出力検証: ローカル配信URLに`?verify=1`を付ける。タイトルが`LELICS VERIFY`と結果JSONになる。
- 録画: `godot --path godot --script verification/movie.gd --write-movie movement.avi --fixed-fps 60`

`godot/verification_suite.gd`は同じルール検証を3環境で実行する。UI手動操作とは別の自動検証。検証結果は`verification.json`を参照。

人物・端末・ボスはオリジナルのプログラム描画。日本語フォントはNoto Sans JP（SIL OFL 1.1）。Godotの著作権表示は`exports/GODOT-LICENSES.txt`。
