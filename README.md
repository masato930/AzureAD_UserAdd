# はじめに
AzureAD上にcsvを利用したユーザーを追加するPowerShellスクリプトを作成してみましたので、アウトプットしていきます。
**※エラー処理等深く考慮できておりません。AzureAD学習の一環でさくっと作成してみました。**
<br>

# 作業環境

|  項目 |  内容  |
| ---- | ---- |
|  OS |  Windows10 Pro |
| PowerShellバージョン | 5.1.19041.610 |
| AzureAD(モジュール)  | 2.0.2.76  |
※AzureAD登録済み(Office365 E3試用版)

```powershell:確認
PS C:\WINDOWS\system32> Get-Module

ModuleType Version    Name                                ExportedCommands                                                                                                                                                                                                          
---------- -------    ----                                ----------------                                                                                                                                                                                                          
Binary     2.0.2.76   AzureAD                             {Add-AzureADApplicationOwner, Add-AzureADDeviceRegisteredOwner, Add-AzureADDeviceRegisteredUser, Add-AzureADDirectoryRoleMember...}                                                                                       
Script     5.8.2      AzureRM.profile                     {Add-AzureRmEnvironment, Clear-AzureRmContext, Clear-AzureRmDefault, Connect-AzureRmAccount...}                                                                                                                           
Script     1.0.0.0    ISE                                 {Get-IseSnippet, Import-IseSnippet, New-IseSnippet}                                                                                                                                                                       
Manifest   3.1.0.0    Microsoft.PowerShell.Management     {Add-Computer, Add-Content, Checkpoint-Computer, Clear-Content...}                                                                                                                                                        
Manifest   3.1.0.0    Microsoft.PowerShell.Utility        {Add-Member, Add-Type, Clear-Variable, Compare-Object...}                                                                                                                                                                 
Script     1.4.6      PackageManagement                   {Find-Package, Find-PackageProvider, Get-Package, Get-PackageProvider...}                                                                                                                                                 
Script     1.0.0.1    PowerShellGet                       {Find-Command, Find-DscResource, Find-Module, Find-RoleCapability...}                                                                                                                                                     

PS C:\WINDOWS\system32> $PSVersionTable

Name                           Value                                                                                                                                                                                                                                                
----                           -----                                                                                                                                                                                                                                                
PSVersion                      5.1.19041.610                                                                                                                                                                                                                                        
PSEdition                      Desktop                                                                                                                                                                                                                                              
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}                                                                                                                                                                                                                              
BuildVersion                   10.0.19041.610                                                                                                                                                                                                                                       
CLRVersion                     4.0.30319.42000                                                                                                                                                                                                                                      
WSManStackVersion              3.0                                                                                                                                                                                                                                                  
PSRemotingProtocolVersion      2.3                                                                                                                                                                                                                                                  
SerializationVersion           1.1.0.1                                                                                                                                                                                                                                              

PS C:\WINDOWS\system32> 
```


<br>

# スクリプトのフロー

![](https://storage.googleapis.com/zenn-user-upload/yjrj9bjfxkwtlmrkdq8cjcu0p516)
<br>

# 読み込むcsvファイル

```powershell:users.csv
DisplayName,UPN,Location,MailNickname
TestTaro,ttest@contoso.com,JP,ttaro
YamadaSaburo,syamada@contoso.com,JP,syamada
```
※ドメイン名は、暫定的に「contoso.com」としています。
<br>

## csvの項目説明

|  項目 |  説明  | 入力例
| ---- | ---- | ---- |
|  DisplayName |  ユーザーの名前 | TestTaro |
| UPN | ユーザープリンシパル名 | ttest@contoso.com |
| Location  | 利用場所  | JP |
| MailNickname  | 組織内でのユーザーのエイリアス  | ttaro |
<br>

# 作成したスクリプト

```powershell:AzureAD_Useradd.ps1
###############################################
# 【AzureAD】ユーザー追加スクリプト
###############################################

# ①各種指定

## csvファイル指定
$users = Import-Csv "C:\Users\owner\Desktop\AzureAD\users.csv"

## ログ保存先指定
$Log = "C:\Users\owner\Desktop\AzureAD\Log"

# ②ログ取得開始
$formatted_date = (Get-Date).ToString("yyyyMMdd-hhmmdd")
Start-Transcript -Path ($Log + "\" + $formatted_date + ".log") | Out-Null

# ③csv事前確認
Write-Host "`r`n"
Write-Host "#####################################"
Write-Host "csv処理前事前確認"
Write-Host "#####################################"
Write-Host "※誤りがある場合は、「Ctrl+C」を押下"
$users | Format-Table
Read-Host "問題ない場合は、「Enter」を押下"

# ④パスワード指定(永続的にパスワード変更無しの設定も付与)
$PW=New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PW.Password="P@ssw0rd"
$PW.ForceChangePasswordNextLogin=$false

# ⑤ユーザー追加処理
$msgBoxInput = [System.Windows.MessageBox]::Show('本当に実行して良いですか？','ユーザー追加処理前確認','YesNo','Question')
 
switch ($msgBoxInput) {
 
    'Yes' {
        Write-Host "#####################################"
        Write-Host "AzureADへのユーザー追加処理"
        Write-Host "-------------------------------------"
        Write-Host "True :追加処理成功"
        Write-Host "False:追加処理失敗"
        Write-Host "#####################################"

        foreach($user in $users){

          # エラー無効化ON
          $ErrorActionPreference = "silentlycontinue"

          # csvの値を各変数に入力
          $displayname = $user.DisplayName
          $upn = $user.UPN
          $location = $user.Location
          $mailnickname = $user.MailNickname

          # ユーザー作成処理
          New-AzureADUser -DisplayName $displayname -UserPrincipalName $upn -PasswordProfile $PW -AccountEnabled $true -UsageLocation $location -MailNickName $mailnickname | Out-Null
          
          # 結果確認処理
          $result = echo $?

  　　　　if($result -eq "True"){
    　　　  Write-Host($displayname + ":True")
          }else{
            Write-Host($displayname + ":False") -ForegroundColor Red
          }

          # エラー無効化OFF
          $ErrorActionPreference = "continue"
        }
    }
 
    'No' {
 
        Write-Host "スクリプトを終了します。"
        exit
    }
}

# ⑥ログ取得停止
Stop-Transcript | Out-Null
```
<br>

# スクリプト実行手順

## 事前準備

- 「PowerShell ISE」起動後、本スクリプト「AzureAD_Useradd.ps1」を開く。

![](https://storage.googleapis.com/zenn-user-upload/0wzzbo68p9gn9ybj9tcnflmti8op)

- csvファイル/ログ保存先フォルダを指定する。

![](https://storage.googleapis.com/zenn-user-upload/2xqym4j5qf1ooxelyja5cgychhcr)

- 以下コマンドにてAzureADへログインを実施する。

```powershell:コマンド
 Connect-AzureAD
```

- ログインポップアップが表示されるため、AzureADの管理者アカウントにてログインを実施する。

![](https://storage.googleapis.com/zenn-user-upload/e7wn0aucen2r7yyytefau2i3rejv)

- ログインが完了すると、以下のように結果が表示される。

![](https://storage.googleapis.com/zenn-user-upload/ubehdvw0llk2lwy4jwwsvuwyxw94)

## スクリプト実行

- 「PowerShell ISE」の実行ボタンを押下する。

![](https://storage.googleapis.com/zenn-user-upload/3y0hv69hhyo4odu4e31t5jfmjjt7)

- csv処理前事前確認が表示される。

問題なければ、「Enter」を押下する。

```powershell:csv処理前事前確認
#####################################
csv処理前事前確認
#####################################
※誤りがある場合は、「Ctrl+C」を押下

DisplayName  UPN                        Location MailNickname
-----------  ---                        -------- ------------
TestTaro     ttest@contoso.com   JP       ttaro       
YamadaSaburo syamada@contoso.com JP       syamada     


問題ない場合は、「Enter」を押下: 
```

- ユーザー追加処理前の確認ポップアップが表示される。

問題なければ**Yes**を押下する。

![](https://storage.googleapis.com/zenn-user-upload/qmw8ikikbn8drj4xab8avgjm7pjn)

※**No**を押下した場合は、以下のように表示され、スクリプトが終了する。

![](https://storage.googleapis.com/zenn-user-upload/59f8xresbkuj3zv8vcyhebv71r8l)

- AzureADへのユーザー追加処理が走る。

```powershell:ユーザー追加処理
#####################################
AzureADへのユーザー追加処理
-------------------------------------
True :追加処理成功
False:追加処理失敗
#####################################
TestTaro:True
YamadaSaburo:True
```

## スクリプト実行後確認

- 以下コマンドにて、ユーザーが追加されていることを確認する。

```powershell:コマンド
Get-AzureADUser
```

実行例)

![](https://storage.googleapis.com/zenn-user-upload/3vm195qxxznl7i004y8v2b33vwj6)

- AzureADのGUI画面

![](https://storage.googleapis.com/zenn-user-upload/y6o2sm9y7byhc5yi6kmxivjn0oih)

※AzureADの管理画面のリンクは以下になります。
[Azure Active Directory admin center](https://aad.portal.azure.com)

<br>

# さいごに
このような形で、さくっとAzureADにユーザーを追加するためのスクリプトを作成しました。
AzureAD学習中のため、今後もAzureAD関連の知識をアウトプットする予定です。
※余裕があれば、YouTubeでもご紹介したいと思います。

私のYouTubeチャンネル
[さっとん【SIerインフラチャンネル】](https://www.youtube.com/channel/UCYaSYnagyhKzdOXK_RsiKiA)


