# はじめに
AzureAD上にcsvを利用したユーザーを追加するPowerShellスクリプトを作成してみましたので、アウトプットしていきます。
<br>
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

![スクリプトのフロー](https://user-images.githubusercontent.com/61190510/141425450-44ff62a2-d610-495a-a453-b2d0bafe648a.jpg)


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

![①](https://user-images.githubusercontent.com/61190510/141425757-3b27f00d-5de8-43eb-991f-9e127fb8b4c1.jpg)


- csvファイル/ログ保存先フォルダを指定する。

![②](https://user-images.githubusercontent.com/61190510/141425766-1b6fc17a-efd2-4bca-8fb7-63dba8217bca.jpg)


- 以下コマンドにてAzureADへログインを実施する。

```powershell:コマンド
 Connect-AzureAD
```

- ログインポップアップが表示されるため、AzureADの管理者アカウントにてログインを実施する。

![③](https://user-images.githubusercontent.com/61190510/141425778-365d5b40-7a46-4f89-9afc-93e7f1b9f3b9.jpg)


- ログインが完了すると、以下のように結果が表示される。

![④](https://user-images.githubusercontent.com/61190510/141425798-665a2750-6d34-4f54-9b74-27f1d3bbc2cf.jpg)

## スクリプト実行

- 「PowerShell ISE」の実行ボタンを押下する。

![⑤](https://user-images.githubusercontent.com/61190510/141425812-38f49606-1682-4f32-9ae5-cdac7624b480.jpg)


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

問題なければ**はい**を押下する。

![⑥](https://user-images.githubusercontent.com/61190510/141426048-683f1ed7-7fb8-4a56-8a5d-b87930153bd2.jpg)

※**いいえ**を押下した場合は、以下のように表示され、スクリプトが終了する。

![⑦](https://user-images.githubusercontent.com/61190510/141426106-3daad2f5-0373-4fa5-927d-7ac24ac203bf.jpg)


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


![⑧](https://user-images.githubusercontent.com/61190510/141426128-9b077d9f-8302-4ee9-afb7-330a8a0590df.jpg)


- AzureADのGUI画面

![⑨](https://user-images.githubusercontent.com/61190510/141426162-5bc8e5c5-03f5-49fd-804a-2dece9c80dfa.jpg)



※AzureADの管理画面のリンクは以下になります。
[Azure Active Directory admin center](https://aad.portal.azure.com)

<br>

