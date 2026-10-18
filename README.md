# Panorama Portal Skybox

360 度パノラマ画像を使い、オブジェクトの内側にカメラが入ったときだけ景色を切り替える Unity シェーダーです。VRChat のワールドでの利用を想定しています。

横:縦が **2:1** の equirectangular（緯度経度）画像を 1 枚割り当てて使用します。Unity の Lighting の Skybox 自体を変更するものではなく、ポータル用メッシュにパノラマを描画します。

## ダウンロード

[PanoramaPortalSkybox.unitypackage をダウンロード](https://github.com/yoogen99/PanoramaPortalSkybox/raw/refs/heads/main/PanoramaPortalSkybox.unitypackage)

上のリンクは `main` の配布ファイルです。バージョン固定の配布がある場合は [Releases](https://github.com/yoogen99/PanoramaPortalSkybox/releases) から取得できます。

パッケージにはシェーダー、設定済みマテリアル、簡易 README が含まれます。パノラマ画像・サンプルシーン・VRChat SDK は含まれません。

## 対応範囲

- Unity Built-in Render Pipeline 向け、Shader Model 3.0 以上。
- URP / HDRP には対応していません。
- VR の左右目用の処理と Instancing 用の分岐を実装しています。実機での見え方は利用する環境で確認してください。
- VRChat の PC ワールドでの利用を想定しています。Android / Quest 単体およびアバター用途の動作は未検証です。
- Unity / VRChat SDK の特定バージョンでの動作保証はありません。VRChat へ導入する際は、使用中の SDK が指定する Unity のプロジェクトを使用してください。

配布整備時の確認: Unity **2022.3.22f1 / Windows** の新規プロジェクトで、バッチモードによるパッケージのインポート、マテリアルから同梱シェーダーへの参照、初期値、インポート時にシェーダーエラーがないことを確認しています。描画の目視確認・VRChat SDK・VR 実機での確認は未実施です。

## 導入手順

1. Unity のプロジェクトを開き、`Assets > Import Package > Custom Package...` からダウンロードした `.unitypackage` を選び、すべての項目を Import します。更新時はプロジェクトをバックアップしてから同じ場所へ上書きしてください。
2. `Assets/PanoramaPortalSkybox/` にシェーダーとマテリアルが追加されたことを確認します。
3. 使用する 2:1 のパノラマ画像を Assets に追加します。画像の Inspector では `Texture Shape` を `2D` にし、`Wrap Mode` の軸別設定で U を `Repeat`、V を `Clamp` にして Apply します。
4. 同梱の `PanoramaPortalSkybox.mat` を複製し、`360 Panorama (Equirectangular)` に画像を割り当てます。シェーダー名は `VRChat/Panorama Portal Sky (Equirectangular)` です。
5. `GameObject > 3D Object > Cube` を作り、複製したマテリアルを Mesh Renderer に割り当てます。
6. Cube をプレイヤーが入れる大きさに拡大します。例: Scale `(4, 4, 4)`。内部へ移動できるよう、不要な Box Collider は削除または無効化します。
7. `Portal Bounds` は `(0.5, 0.5, 0.5)`、`Render From Outside` は Off のまま、カメラを Cube の外側・内側へ移動して表示を確認します。VRChat では SDK のローカルテストと VR 実機でも確認してください。

ソースを直接導入する場合は、このリポジトリの `Assets/PanoramaPortalSkybox/` フォルダーと対応する `.meta` を Unity プロジェクトの Assets へコピーする方法も使えます。UPM / VCC 用のパッケージではありません。

## マテリアル設定

| 項目 | 初期値 | 内容 |
| --- | --- | --- |
| 360 Panorama (Equirectangular) | 未設定 | 2:1 のパノラマ画像。未設定ではグレーが表示されます。 |
| Virtual Sky Half Size | `50` | オブジェクトのローカル座標での仮想的な空の半サイズ。大きくすると移動による見え方の変化が穏やかになります。カメラが動く範囲より大きい値を使用してください。 |
| Panorama Y Rotation | `0` | パノラマの水平方向の回転（度）。 |
| Exposure | `1` | 明るさの倍率（0〜8）。 |
| Flip Panorama Vertically | Off | 画像の上下を反転。 |
| Render From Outside | Off | On にすると外側からもメッシュにパノラマを描画。通常は Off。 |
| Portal Bounds (Local Half Extents) | `(0.5, 0.5, 0.5)` | 入室判定に使うローカル座標の半サイズ。W 成分は未使用。 |

標準 Cube の Scale を変更しても `Portal Bounds` は変更不要です。入室判定は、オブジェクトのローカル軸に沿った、原点中心の直方体です。回転はオブジェクトに追従します。別のメッシュでは、原点と寸法を合わせ、内側から視界を覆う閉じた形状にしてください。

## 表示の仕組みと制限

カメラからの視線と仮想直方体の交点を計算し、その方向からパノラマの色を取得します。反復型のレイマーチングは使用しません。左右目で視点を分けて計算しますが、画像そのものに立体視用の奥行き情報はありません。

メッシュの深度に描画されるため、内部のオブジェクトをすべて非表示にする機能ではありません。カメラとポータルの面との間にある物体は表示されることがあります。また、境界付近では近クリップ面でメッシュが切れる場合があります。極端に薄い形状や、ポータル同士の重なりは避けて確認してください。

## うまく表示されないとき

| 症状 | 確認すること |
| --- | --- |
| マテリアルがピンク色 | Built-in Render Pipeline のプロジェクトか、上記シェーダーが選択されているか、Console にエラーがないか。旧版から更新した場合もシェーダーの割り当てを確認してください。 |
| グレー一色 | 複製したマテリアルの `360 Panorama` に画像が入っているか。 |
| 外から見えない | `Render From Outside` が Off の場合は正常です。カメラを Cube の内側へ移動してください。 |
| 中に入れない | Cube の Box Collider が移動を妨げていないか。 |
| 内側でも見えない | Mesh Renderer とマテリアルの割り当て、カメラ位置、`Portal Bounds`、メッシュの原点を確認してください。 |
| 向き・上下が逆 | `Panorama Y Rotation` / `Flip Panorama Vertically` を調整してください。 |
| 継ぎ目やぼけが目立つ | 画像が全天球の 2:1 画像か、Wrap Mode、Max Size、圧縮設定を確認してください。 |

## リポジトリ構成

```text
Assets/
├─ PanoramaPortalSkybox.meta
└─ PanoramaPortalSkybox/
   ├─ PanoramaPortalSky.shader / .meta
   ├─ PanoramaPortalSkybox.mat / .meta
   └─ README.md / .meta
scripts/build_package.py           # 配布物を生成・検証
PanoramaPortalSkybox.unitypackage   # Unity インポート用
CHANGELOG.md
RELEASING.md
```

開発・配布手順は [RELEASING.md](RELEASING.md)、変更履歴は [CHANGELOG.md](CHANGELOG.md) を参照してください。不具合は [Issues](https://github.com/yoogen99/PanoramaPortalSkybox/issues) に、Unity のバージョン、描画環境、再現手順、Console のエラーを添えて報告できます。画像は共有可能なものを使用してください。

## ライセンス・利用条件

**ライセンスは未決定です。** 現時点で、このリポジトリは改変・再配布・商用利用などを包括的に許諾するライセンスを付与していません。必要な利用許諾は作者に確認してください。パノラマ画像は別途用意し、その画像の利用条件に従ってください。

着想の参考: [BOOTH の関連作品](https://booth.pm/ja/items/2121677)。本リポジトリの配布物・利用条件とは別の作品です。
