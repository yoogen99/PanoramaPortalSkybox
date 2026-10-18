# 開発・配布手順

## ソースと配布物

`Assets/PanoramaPortalSkybox/` と対応する `.meta` が編集元です。Unity プロジェクト全体や UPM パッケージではありません。作業用 Unity プロジェクトの Assets へコピーして確認してください。

既存の GUID を維持するため、`.meta` は削除・再生成せず、アセットと一緒に管理します。配布物の中身を直接編集せず、ソースを変更して再生成してください。

Python 3.10 以降の標準ライブラリだけでパッケージを生成できます。Unity のインストールは生成処理には不要です。

```sh
python scripts/build_package.py
python scripts/build_package.py --check
```

通常実行でルートの `PanoramaPortalSkybox.unitypackage` を更新します。`--check` は配布ファイルを変更せず、GUID・マテリアルの参照・同梱内容と生成結果の一致を検証します。CI でも同じ検証を行います。アセット追加時は Unity が作成した `.meta` もコミットしてください。

生成対象は `.shader`、`.mat`、`.md` とフォルダーです。プレビュー画像は含めません。画像などのアセット形式を追加する場合は、生成スクリプトの対象形式と改行処理も対応させてください。

## 公開前の確認

- クリーンな Built-in Render Pipeline のプロジェクトに生成パッケージをインポートできること。
- マテリアルに同梱シェーダーが割り当たり、Console にシェーダーエラーが出ないこと。
- 自分で用意した 2:1 画像で、Cube の外側・内側、向き・明るさ・上下反転を確認すること。
- VRChat 用には SDK のローカルテスト、デスクトップ・VR の左右目を確認すること。
- 確認した Unity / SDK / 機器と制限をリリースノートに記録すること。CI のパッケージ検査は実機動作確認を代替しません。
- ライセンスは保留中です。利用条件を決めたら README、同梱 README、必要なライセンスファイルを更新し、再生成すること。

## GitHub Release

1. `CHANGELOG.md` の `Unreleased` を、公開するバージョンと日付の見出しへ変更し、次の `Unreleased` を追加します。
2. ソースと `.unitypackage` を一緒にコミットして `main` へ反映します。
3. 公開するコミットに `v` で始まるバージョンタグ（例: `v0.1.0`）を作成して GitHub に push します。
4. `.github/workflows/release.yml` が整合性を確認したあと、**ドラフトの Release** を作成し、`.unitypackage` と `SHA256SUMS.txt` を添付します。
5. GitHub でドラフトを開き、変更点・動作確認環境・ライセンスの状態を確認してリリースノートを編集し、公開します。

タグの push で一般公開はされません。同じタグで再実行した場合は既存 Release を上書きせず失敗します。修正が必要なら既存ドラフトを確認し、別バージョンとして作成してください。GitHub Actions の実行と `GITHUB_TOKEN` による Release 作成がリポジトリ設定で許可されている必要があります。
