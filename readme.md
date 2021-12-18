# Matsuura Hand
<!-- ### TABLISmain.wrl -->
# todo
1.solidworksからwrlファイルをoriginal_wrlへ入れる
2.exchange.shを実行しモデルのミラーを呼び圧縮を行う（exchanged_wrl/）
2.SolidworksからVRMLに質量特性反映を行う
3.caktin build matsuura_hand により、mass propがmatsuura_hand_main_*.wrlへ埋め込まれる

# SolidworksからVRMLに質量特性反映
Solidworksで各リンクのアセンブリを開いて(全身アセンブリで選択しただけではダメ)評価→質量特性→ｵﾌﾟｼｮﾝ→単位→ﾕｰｻﾞｰ定義→長さm,少数位数５，質量ｷﾛｸﾞﾗﾑ，容積meters^3にしてから，値をクリップボードにコピーしてwrlディレクトリ内のall_mass_props_from_solidworks.txtに適当に貼り付けてから`./parse_mass_props.sh`を実行するとVRML記法のall_mass_props_for_vrml.txtが生成されるので，TABLISmain.wrl.in内にコピペしていく．
