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