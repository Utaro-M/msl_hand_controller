# Matsuura Hand

# 実機での実行手順

## 起動手順
1. lockが外れていること、ケーブルがかんでいないことを確認し、両手のスイッチをONにする
1. 以下のコマンドでscripts/start-matsuura.shを実行し制御PCからvisionPCにsshしてcontrollerのlaunchファイルを実行
```
cd ~
./start-matsuura.sh ##~以下に無い場合はscripts/start-matsuura.shからコピーする
```
1. 以下のコマンドでeuslisp/msl-hand-interface.l を実行しmsl-hand-initを呼ぶ。
```
roscd msl_hand_controller/euslisp
roseus msl-hand-interface.l
(msl-hand-init) ##roseus
```
## msl-hand-interface.lの関数について
1. (defun lock-finger (arm &key (lock-angles #f(90 90)) (effort #f(0.2 0.2 0.2 0.2 0.2 0.1)) (send? nil))
   指をロックする
   - arm 動かすハンドを指定 :larm or :rarm or :arms
   - lock-angles ロックする角度を指定 #f(0 0) #f(60 60) #f(90 90) #f(120 120) #f(60 120)...
   - effort モータの発揮effortを指定 #f(0.2 0.2 0.2 0.2 0.2 0.1)
   - send? 実機に送るかどうかを指定
```
(lock-finger :rarm :lock-angles #f(90 90) :effort #f(0.2 0.2 0.2 0.2 0.2 0.1) :send? t)
```
1. (defun release-finger(arm &key (effort #f(0.2 0.2 0.2 0.2 0.2 0.1)) (send? nil))
   ロックを解除する
   - arm 動かすハンドを指定 :larm or :rarm or :arms
   - effort モータの発揮effortを指定 #f(0.2 0.2 0.2 0.2 0.2 0.1)
   - send? 実機に送るかどうかを指定
```
(release-finger :rarm :effort #f(0.2 0.2 0.2 0.2 0.2 0.1) :send? t)
```

## デバッグ
- USBの抜き差しや電源の入り切りを試す
- launch ファイルの上げ直し

# モデルの変換手順
1. solidworksの外観からRGBの色を指定(個別パーツごとに指定する必要あり)
1. solidworksからVRML出力(指定保存→ｵﾌﾟｼｮﾝ→VRML97→ﾄﾞｷｭﾒﾝﾄﾌﾟﾛﾊﾟﾃｨ→ｲﾒｰｼﾞ品質→スライドバー最低設定)
1. wrlファイルをoriginal_wrlへ入れる
1. exchange.shを実行しモデルのミラーを呼び圧縮を行う（exchanged_wrl/）
1. SolidworksからVRMLに質量特性反映を行う
1. caktin build matsuura_hand により、mass propがmatsuura_hand_main_*.wrlへ埋め込まれる

# SolidworksからVRMLに質量特性反映
Solidworksで各リンクのアセンブリを開いて(全身アセンブリで選択しただけではダメ)評価→質量特性→ｵﾌﾟｼｮﾝ→単位→ﾕｰｻﾞｰ定義→長さm,少数位数５，質量ｷﾛｸﾞﾗﾑ，容積meters^3にしてから，値をクリップボードにコピーしてwrlディレクトリ内のall_mass_props_from_solidworks.txtに適当に貼り付けてから`./parse_mass_props.sh`を実行するとVRML記法のall_mass_props_for_vrml.txtが生成されるので，TABLISmain.wrl.in内にコピペしていく．

# manus gloveの起動手順
1. linuxでrossetlocal,rossetip,roscoreを立ち上げる
1. windowsでros対応のshellを立ち上げる
1. win_manus_ros_node.batを実行しmanus_ros_nodeを上げる(ipconfigでipアドレスを確認、変更)
1. linuxでmanus_node.lを立ち上げる
- /manus/left_hand/joint_states: 関節角度列
- /manus/left_hand/rumble: 振動司令

# memo
## モデルファイルの変換
- meshlabserver コマンドによるobjファイルの変換時にはobjファイルと同じディレクトリ内でコマンド実行の必要あり
- .objとともに生成される.obj.mtlに色情報が含まれておりコマンド実行時のファイル探索では実行ディレクトリ内しか探索しないらしい
## min_maxの設定
- config/*_min_max.yamlとmatsuura_hand_main_*.wrl.inの2箇所にmin,max角度を記述する
  config/*_min_max.yamlはserver.pyで使用）
- dynamixelモータのposition 180度がeusなどからの司令時の0度に対応している？
  (homing offsetの設定はこれを考慮しwizardでeus等で0度としたい角度で１positionが180度となるように決めれば良い)
- モータをつけ直した際はwizardで可動域を確認する
## build
- configやモデルを更新した際のcatkin build時は、古い生成ファイルが残ったままだと新しく生成されないため、削除してからビルドすること
 （matsuura_hand_l.l、（大文字）.*ファイルなど）
