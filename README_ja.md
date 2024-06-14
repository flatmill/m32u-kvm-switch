# KVM Switch for M32U

( [English version](./README.md) / 日本語版 )

Windows 上で動作する、GIGABYTE M32U ディスプレイ向けのソフトウェア KVM スイッチです。

## 説明

- ディスプレイの後ろに手を回さなくても、シェルコマンドや通知領域からディスプレイを切り替えることができます。
- 本ツールを接続している２台の Windows PC にインストールすることで、切り替え先 PC の映像出力をオンにしてからディスプレイを切り替えることができます。これによって、安定した表示切替を実現します。

## 必要条件

以下のデバイスが必要です：

- [GIGABYTE M32U Gaming Monitor](https://www.gigabyte.com/jp/Monitor/M32U#kf)
  - 他の GIGABYTE 製ディスプレイでも動作する可能性があります。
- 上記ディスプレイに接続された Windows PC ×２台
  - 切り替え先 PC の映像出力をオンにする場合は、２台の PC が同一ネットワーク上にある必要があります。

## インストール方法

２台の PC でそれぞれ実行します。

リポジトリからファイルをダウンロード（クローン）してください。

```powershell
PS> git clone https://github.com/flatmill/m32u-kvm-switch
```

インターネットからダウンロードしたファイルは、スクリプトの実行がブロックされる場合があります。
リポジトリ内の `setup.ps1` ファイルと `m32u-kvm-switch.ps1` ファイルに対してブロックを解除してください。

```powershell
PS> cd m32u-kvm-switch
PS> Unblock-File -Path setup.ps1
PS> Unblock-File -Path m32u-kvm-switch.ps1
```

## 使用方法

### Windows ログオン時に通知アイコンを追加する

Windows ログオン時に、KVM 切り替えスイッチを通知領域に追加するスタートアップショートカット `startup-m32u-kvm-switch` を設置します。
設置のために、リポジトリに同梱の `setup.ps1` スクリプトを使用します。

```powershell
PS> cd C:\path\to\m32u-kvm-switch
PS> .\setup.ps1 -Install -IPAddr xxx.xxx.xxx.xxx -MacAddr XX-XX-XX-XX-XX-XX
```

`setup.ps1` スクリプトのオプションの意味は次の通りです。

- `-Install` ... スタートアップショートカットを設置します
- `-Uninstall` ... 設置したスタートアップショートカットを削除します
- `-IPAddr xxx.xxx.xxx.xxx` ... 切り替え先の PC の IP アドレス、もしくはネットワークのブロードキャスト IP アドレスを指定します
  - 例）ネットワークアドレスが `192.168.0.0/24` の場合、以下のような値が有効になります
    - `-IPAddr 192.168.0.22`（切り替え先 PC の IP アドレス）
    - `-IPAddr 192.168.0.255`（ブロードキャスト IP アドレス）
- `-MacAddr XX-XX-XX-XX-XX-XX` ... 切り替え先の PC の Mac アドレスを指定します。区切り文字は `-`, `:` のいずれか、または省略できます

`-Install` と `-Uninstall` のいずれも指定しない場合は、スタートアップフォルダをエクスプローラーで開きます。

### 通知アイコンを使用する

常駐すると、以下のアイコンが通知領域に表示されます。

![ライトモード用アイコン](./kvm-switch-light.ico)（ライトモード用） / ![ダークモード用アイコン](./kvm-switch-dark.ico)（ダークモード用）

このアイコンを左クリックすると、 ディスプレイが切り替わります。

このアイコンを右クリックすると、以下のコンテキストメニューが表示されます。

- KVM Switch ... ディスプレイが切り替わります
- Shutdown after KVM Switch ... ディスプレイを切り替えてから Windows をシャットダウンします（確認ダイアログが表示されます）
- Exit ... 常駐を終了し、アイコンを通知領域から削除します

### コマンドラインを利用して操作する

`m32u-kvm-switch.ps1` スクリプトを以下のように直接実行することで、コマンドラインからディスプレイを切り替えることができます。

```powershell
PS> cd C:\path\to\m32u-kvm-switch
PS> powershell -NoProfile -NoLogo -ExecutionPolicy Unrestricted -File .\m32u-kvm-switch.ps1 -IPAddr xxx.xxx.xxx.xxx -MacAddr XX-XX-XX-XX-XX-XX
```

また、以下のように `m32u-kvm-switch.ps1` スクリプトのオプションに `-Notify` を追加することで、
KVM 切り替えスイッチを通知領域に追加します。

```powershell
PS> cd C:\path\to\m32u-kvm-switch
PS> powershell -NoProfile -NoLogo -ExecutionPolicy Unrestricted -File .\m32u-kvm-switch.ps1 -Notify -IPAddr xxx.xxx.xxx.xxx -MacAddr XX-XX-XX-XX-XX-XX
```

`-IPAddr` オプションと `-MacAddr` オプションの指定はセットアップスクリプトで指定したものと同様です。
ただし、 `-MacAddr` の区切り文字は `-` のみ有効で、かつ省略できません。

### 本ツールをアンインストールする

スタートアップショートカットを削除します。
以下のコマンドを実行してください。

```powershell
PS> cd C:\path\to\m32u-kvm-switch
PS> .\setup.ps1 -Uninstall
```

ダウンロード（クローン）したファイルを全て削除して完了です。

## 作者

flatmill

## ライセンス

[MIT](LICENSE.txt)
