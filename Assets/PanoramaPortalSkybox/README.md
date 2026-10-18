# Panorama Portal Skybox

Unity Built-in Render Pipeline 用のパノラマ表示シェーダーです。
カメラがポータルの内側に入ると、メッシュに 360 度画像を表示します。
URP / HDRP 非対応。パノラマ画像は同梱していません。

## 使い方

1. 横:縦 2:1 の equirectangular 画像を Unity に追加します。
2. 画像の Texture Shape は 2D、Wrap Mode は U: Repeat / V: Clamp にします。
3. 同梱の PanoramaPortalSkybox.mat を複製し、360 Panorama に画像を割り当てます。
4. 標準 Cube を作成し、複製したマテリアルを割り当てます。
5. Cube を内部へ入れる大きさに拡大し、不要な Box Collider を無効化または削除します。
6. カメラを内部に移動して確認します。外側では初期設定で何も描画しません。

Shader: VRChat/Panorama Portal Sky (Equirectangular)
Portal Bounds: (0.5, 0.5, 0.5) / Virtual Sky Half Size: 50
Render From Outside: Off / Exposure: 1

標準 Cube の Scale を変えても Portal Bounds は変更不要です。
向きは Panorama Y Rotation、上下は Flip Panorama Vertically で調整できます。
ピンク色になる場合は描画パイプラインとシェーダーの割り当てを確認してください。
グレーになる場合は画像の割り当てを確認してください。
VRChat / VR 実機での動作は、利用する環境でテストしてください。

## ライセンス・詳細

ライセンスは未決定です。改変・再配布・商用利用などの包括的な許諾は付与していません。
必要な利用許諾は作者に確認してください。画像の利用条件は別途確認してください。

詳細な手順、制限、更新履歴:
https://github.com/yoogen99/PanoramaPortalSkybox
