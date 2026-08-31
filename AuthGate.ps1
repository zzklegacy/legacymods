<#
    AuthGate.ps1
    ---------------------------------------------------------------------
    Tela de login que roda ANTES do painel principal (LegacyMods.ps1).

    Fluxo:
      1. Usuario digita o Discord ID dele.
      2. O script pega o IP publico da maquina (via ipify).
      3. Envia { discordId, ip } pro SEU backend (server.js incluso).
      4. O backend gera uma key vinculada aquele IP e manda por DM no
         Discord do usuario (via bot).
      5. O usuario cola a key recebida no painel.
      6. O script valida a key + IP com o backend antes de liberar o app.

    IMPORTANTE - leia antes de usar:
      - O bot do Discord SO consegue mandar DM pra quem estiver num
        servidor em comum com ele. Ou seja: seus usuarios precisam ja
        estar no seu servidor Discord antes de pedirem a key.
      - Isso NAO substitui autenticacao real (o Discord ID e algo que
        qualquer um pode digitar, nao prova identidade sozinho). O que
        de fato impede uso indevido e o backend so aceitar UMA key por
        IP/ID e expira-la, e a validacao ficar centralizada no server
        (nunca confie so no cliente).
      - Troque $ApiBaseUrl pelo endereco real do seu backend.
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$ApiBaseUrl = "https://zezekaaaaaaaaa-production.up.railway.app"

function Get-PublicIP {
    try {
        return (Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -TimeoutSec 8).ip
    } catch {
        return $null
    }
}

function Request-LicenseKey {
    param([string]$DiscordId, [string]$Ip)
    try {
        $body = @{ discordId = $DiscordId; ip = $Ip } | ConvertTo-Json
        $resp = Invoke-RestMethod -Uri "$ApiBaseUrl/api/generate-key" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 15
        return $resp   # espera-se algo como @{ ok = $true; message = "Key enviada no seu Discord" }
    } catch {
        return @{ ok = $false; message = "Falha ao contatar o servidor: $($_.Exception.Message)" }
    }
}

function Confirm-LicenseKey {
    param([string]$DiscordId, [string]$Ip, [string]$Key)
    try {
        $body = @{ discordId = $DiscordId; ip = $Ip; key = $Key } | ConvertTo-Json
        $resp = Invoke-RestMethod -Uri "$ApiBaseUrl/api/validate-key" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 15
        return $resp   # espera-se @{ valid = $true/$false; message = "..." }
    } catch {
        return @{ valid = $false; message = "Falha ao contatar o servidor: $($_.Exception.Message)" }
    }
}

[xml]$loginXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="LegacyMods - Login" Height="380" Width="420"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#0B0B0D" Foreground="White" FontFamily="Segoe UI">
    <StackPanel Margin="26" VerticalAlignment="Center">
        <TextBlock Text="LegacyMods" FontFamily="Consolas" FontSize="22" FontWeight="Bold" Foreground="#8B6CF2"/>
        <TextBlock Text="Faca login com seu Discord ID para gerar sua key" Foreground="#87878F" FontSize="11" Margin="0,4,0,20"/>

        <TextBlock Text="DISCORD ID" FontSize="10" FontWeight="Bold" Foreground="#8B6CF2" Margin="0,0,0,4"/>
        <TextBox Name="txtDiscordId" Height="34" Padding="8,6" Background="#131316" Foreground="White" BorderBrush="#232328" BorderThickness="1"/>
        <Button Name="btnRequestKey" Content="Enviar e receber key no Discord" Height="38" Margin="0,12,0,0" Background="#8B6CF2" Foreground="White" BorderThickness="0" Cursor="Hand"/>

        <TextBlock Text="KEY RECEBIDA" FontSize="10" FontWeight="Bold" Foreground="#8B6CF2" Margin="0,18,0,4"/>
        <TextBox Name="txtKey" Height="34" Padding="8,6" Background="#131316" Foreground="White" BorderBrush="#232328" BorderThickness="1"/>
        <Button Name="btnValidate" Content="Entrar" Height="38" Margin="0,12,0,0" Background="#131316" BorderBrush="#232328" BorderThickness="1" Foreground="White" Cursor="Hand"/>

        <TextBlock Name="txtLoginStatus" Text="" Foreground="#87878F" FontSize="10.5" Margin="0,14,0,0" TextWrapping="Wrap"/>
    </StackPanel>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $loginXaml
$loginWindow = [Windows.Markup.XamlReader]::Load($reader)

$txtDiscordId  = $loginWindow.FindName("txtDiscordId")
$txtKey        = $loginWindow.FindName("txtKey")
$btnRequestKey = $loginWindow.FindName("btnRequestKey")
$btnValidate   = $loginWindow.FindName("btnValidate")
$txtLoginStatus= $loginWindow.FindName("txtLoginStatus")

$script:currentIp = $null
$script:authOk = $false

$btnRequestKey.Add_Click({
    $id = $txtDiscordId.Text.Trim()
    if ($id -eq "") { $txtLoginStatus.Text = "Digite seu Discord ID."; return }

    $btnRequestKey.IsEnabled = $false
    $txtLoginStatus.Text = "Obtendo IP e solicitando key..."
    $loginWindow.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)

    $script:currentIp = Get-PublicIP
    if (-not $script:currentIp) {
        $txtLoginStatus.Text = "Nao foi possivel obter seu IP publico. Verifique sua conexao."
        $btnRequestKey.IsEnabled = $true
        return
    }

    $resp = Request-LicenseKey -DiscordId $id -Ip $script:currentIp
    if ($resp.ok) {
        $txtLoginStatus.Text = "Key enviada no seu Discord (PV do bot). Cole ela abaixo."
    } else {
        $txtLoginStatus.Text = $resp.message
    }
    $btnRequestKey.IsEnabled = $true
})

$btnValidate.Add_Click({
    $id  = $txtDiscordId.Text.Trim()
    $key = $txtKey.Text.Trim()
    if ($id -eq "" -or $key -eq "") { $txtLoginStatus.Text = "Preencha o Discord ID e a key."; return }
    if (-not $script:currentIp) { $script:currentIp = Get-PublicIP }

    $btnValidate.IsEnabled = $false
    $txtLoginStatus.Text = "Validando..."
    $loginWindow.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)

    $resp = Confirm-LicenseKey -DiscordId $id -Ip $script:currentIp -Key $key
    if ($resp.valid) {
        $script:authOk = $true
        $loginWindow.Close()
    } else {
        $txtLoginStatus.Text = $resp.message
        $btnValidate.IsEnabled = $true
    }
})

$loginWindow.ShowDialog() | Out-Null

if (-not $script:authOk) {
    [System.Windows.MessageBox]::Show("Acesso nao autorizado. Encerrando.", "LegacyMods", "OK", "Error") | Out-Null
    exit
}

# Login validado -> baixa e executa o painel principal.
# Troque a URL abaixo pela URL raw do seu LegacyMods.clean.ps1 no GitHub.
$PanelUrl = "https://raw.githubusercontent.com/zzklegacy/legacymods/refs/heads/main/legacy.ps1"
try {
    $panelCode = (Invoke-WebRequest -Uri $PanelUrl -UseBasicParsing -TimeoutSec 20).Content
    Invoke-Expression $panelCode
} catch {
    [System.Windows.MessageBox]::Show("Falha ao carregar o painel: $($_.Exception.Message)", "LegacyMods", "OK", "Error") | Out-Null
}
