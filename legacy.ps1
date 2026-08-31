#Requires -Version 5.1
<#
    LegacyMods v4.0 (corrigido)
    Painel de otimizacao, limpeza, privacidade, desempenho em jogos e instalacao de apps para Windows.

    Uso local:  powershell -ExecutionPolicy Bypass -File .\LegacyMods.ps1
    Uso remoto: irm https://SEU-LINK/LegacyMods.ps1 | iex

    CORRECAO APLICADA (ver comentario mais abaixo, proximo a "$script:statusTimer"):
    o timer de status era criado DEPOIS da primeira chamada a Show-Page, o que
    causava "Nao e possivel chamar um metodo em uma expressao de valor nulo"
    na primeira execucao "limpa" do script (sem estado residual na sessao do
    PowerShell). A criacao do timer foi movida para antes da navegacao inicial,
    e a funcao Show-Page tambem ganhou uma checagem de nulo defensiva.
#>

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Reiniciando como Administrador..." -ForegroundColor Yellow
    $psCmd = if ($PSCommandPath) { "-File `"$PSCommandPath`"" } else { "-Command `"irm https://SEU-LINK/LegacyMods.ps1 | iex`"" }
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass $psCmd"
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ---------------------------------------------------------------------------
# Interface (XAML)
# ---------------------------------------------------------------------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="LegacyMods" Height="760" Width="1060"
        WindowStartupLocation="CenterScreen"
        Background="#0B0B0D" Foreground="White"
        FontFamily="Segoe UI">

    <Window.Resources>

        <SolidColorBrush x:Key="Purple" Color="#8B6CF2"/>
        <SolidColorBrush x:Key="PurpleSoft" Color="#211C33"/>
        <SolidColorBrush x:Key="Sidebar" Color="#0D0D10"/>
        <SolidColorBrush x:Key="Card" Color="#131316"/>
        <SolidColorBrush x:Key="CardHover" Color="#18181C"/>
        <SolidColorBrush x:Key="Border0" Color="#232328"/>
        <SolidColorBrush x:Key="TextMuted" Color="#87878F"/>
        <SolidColorBrush x:Key="Console" Color="#0E0E10"/>
        <SolidColorBrush x:Key="ConsoleText" Color="#C9C9D1"/>
        <SolidColorBrush x:Key="Warning" Color="#D9A54B"/>
        <SolidColorBrush x:Key="WarningSoft" Color="#2A2419"/>
        <SolidColorBrush x:Key="Online" Color="#4ADE80"/>

        <LinearGradientBrush x:Key="PurpleGradient" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#9C7CF5" Offset="0"/>
            <GradientStop Color="#7A57DE" Offset="1"/>
        </LinearGradientBrush>

        <DropShadowEffect x:Key="CardShadow" BlurRadius="16" ShadowDepth="1" Direction="270" Opacity="0.18" Color="#000000"/>
        <DropShadowEffect x:Key="ButtonGlow" BlurRadius="10" ShadowDepth="0" Opacity="0.25" Color="#8B6CF2"/>

        <Style x:Key="ScrollThumbStyle" TargetType="Thumb">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Thumb">
                        <Border Background="#38383F" CornerRadius="4" Margin="1"/>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="8"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="Transparent">
                            <Track Name="PART_Track" IsDirectionReversed="True">
                                <Track.Thumb>
                                    <Thumb Style="{StaticResource ScrollThumbStyle}"/>
                                </Track.Thumb>
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageUpCommand" Opacity="0" Focusable="False"/>
                                </Track.DecreaseRepeatButton>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageDownCommand" Opacity="0" Focusable="False"/>
                                </Track.IncreaseRepeatButton>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource PurpleGradient}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="14,10"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="RenderTransformOrigin" Value="0.5,0.5"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="10">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bg" Property="Opacity" Value="0.92"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bg" Property="Opacity" Value="0.35"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="GhostButton" TargetType="Button" BasedOn="{StaticResource PrimaryButton}">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bg" Background="{StaticResource Card}" BorderBrush="{StaticResource Border0}" BorderThickness="1" CornerRadius="10">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bg" Property="BorderBrush" Value="{StaticResource Purple}"/>
                                <Setter TargetName="bg" Property="Background" Value="{StaticResource CardHover}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="NavItem" TargetType="RadioButton">
            <Setter Property="Foreground" Value="{StaticResource TextMuted}"/>
            <Setter Property="FontSize" Value="12.5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Height" Value="38"/>
            <Setter Property="Margin" Value="14,1,14,1"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RadioButton">
                        <Border x:Name="bg" Background="#00000000" CornerRadius="9" Padding="14,0">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="3"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border x:Name="bar" Grid.Column="0" Width="3" CornerRadius="2" Background="{StaticResource Purple}" Opacity="0" HorizontalAlignment="Left" VerticalAlignment="Stretch" Margin="-14,7,0,7"/>
                                <TextBlock Grid.Column="1" Text="{TemplateBinding Content}" VerticalAlignment="Center" Margin="12,0,0,0"
                                           FontWeight="Medium" Foreground="{TemplateBinding Foreground}" FontSize="{TemplateBinding FontSize}"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="bg" Property="Background" Value="{StaticResource PurpleSoft}"/>
                                <Setter TargetName="bar" Property="Opacity" Value="1"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                            <MultiTrigger>
                                <MultiTrigger.Conditions>
                                    <Condition Property="IsMouseOver" Value="True"/>
                                    <Condition Property="IsChecked" Value="False"/>
                                </MultiTrigger.Conditions>
                                <Setter TargetName="bg" Property="Background" Value="{StaticResource CardHover}"/>
                            </MultiTrigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="NavSection" TargetType="TextBlock">
            <Setter Property="FontSize" Value="10"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="#4E4E56"/>
            <Setter Property="Margin" Value="26,18,0,6"/>
        </Style>

        <Style x:Key="ModernCheck" TargetType="CheckBox">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Border x:Name="box" Width="17" Height="17" CornerRadius="5" BorderThickness="1.5" BorderBrush="#3A3A42" Background="Transparent">
                            <Path x:Name="check" Data="M2,7 L6,11 L14,2" Stroke="White" StrokeThickness="2"
                                  StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round"
                                  Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="box" Property="Background" Value="{StaticResource PurpleGradient}"/>
                                <Setter TargetName="box" Property="BorderBrush" Value="{StaticResource Purple}"/>
                                <Setter TargetName="check" Property="Visibility" Value="Visible"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="OptionRow" TargetType="Border">
            <Setter Property="Background" Value="{StaticResource Card}"/>
            <Setter Property="CornerRadius" Value="10"/>
            <Setter Property="Padding" Value="12,10"/>
            <Setter Property="Margin" Value="0,0,8,8"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border0}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="BorderBrush" Value="{StaticResource Purple}"/>
                    <Setter Property="Background" Value="{StaticResource CardHover}"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style x:Key="OptionRowWarning" TargetType="Border" BasedOn="{StaticResource OptionRow}">
            <Setter Property="Background" Value="{StaticResource WarningSoft}"/>
            <Setter Property="BorderBrush" Value="#4A3A20"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="BorderBrush" Value="{StaticResource Warning}"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style x:Key="BigCard" TargetType="Border" BasedOn="{StaticResource OptionRow}">
            <Setter Property="CornerRadius" Value="12"/>
            <Setter Property="Effect" Value="{StaticResource CardShadow}"/>
        </Style>

        <Style x:Key="PageTitle" TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Consolas"/>
            <Setter Property="FontSize" Value="19"/>
            <Setter Property="FontWeight" Value="Bold"/>
        </Style>

        <Style x:Key="CategoryHeader" TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Consolas"/>
            <Setter Property="FontSize" Value="10"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="{StaticResource Purple}"/>
            <Setter Property="Margin" Value="2,12,0,8"/>
        </Style>

        <Style x:Key="CategoryHeaderWarning" TargetType="TextBlock" BasedOn="{StaticResource CategoryHeader}">
            <Setter Property="Foreground" Value="{StaticResource Warning}"/>
        </Style>

        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="{StaticResource Card}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="8,5"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border0}"/>
        </Style>

        <Style TargetType="ProgressBar">
            <Setter Property="Background" Value="#232329"/>
            <Setter Property="Foreground" Value="{StaticResource Purple}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Height" Value="6"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ProgressBar">
                        <Border Background="{TemplateBinding Background}" CornerRadius="3">
                            <Grid ClipToBounds="True" HorizontalAlignment="Left">
                                <Border x:Name="PART_Track" CornerRadius="3"/>
                                <Border x:Name="PART_Indicator" Background="{StaticResource PurpleGradient}" CornerRadius="3" HorizontalAlignment="Left"/>
                            </Grid>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="190"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- SIDEBAR -->
        <Border Grid.Column="0" Background="{StaticResource Sidebar}">
            <DockPanel LastChildFill="False">
                <StackPanel DockPanel.Dock="Top" Margin="18,22,0,18">
                    <Border Width="38" Height="38" CornerRadius="10" Background="{StaticResource PurpleGradient}" HorizontalAlignment="Left">
                        <TextBlock Text="LM" FontFamily="Consolas" FontWeight="Bold" FontSize="14" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <StackPanel Orientation="Horizontal" Margin="0,10,0,0">
                        <TextBlock Text="Legacy" FontFamily="Consolas" FontSize="17" FontWeight="Bold" Foreground="White"/>
                        <TextBlock Text="Mods" FontFamily="Consolas" FontSize="17" FontWeight="Bold" Foreground="{StaticResource Purple}"/>
                    </StackPanel>
                </StackPanel>

                <StackPanel DockPanel.Dock="Top">
                    <TextBlock Text="COMECAR" Style="{StaticResource NavSection}"/>
                    <RadioButton Name="navInicio" Content="INICIO" GroupName="Nav" Style="{StaticResource NavItem}" IsChecked="True"/>
                    <RadioButton Name="navInstalar" Content="INSTALAR APPS" GroupName="Nav" Style="{StaticResource NavItem}"/>

                    <TextBlock Text="OTIMIZAR" Style="{StaticResource NavSection}"/>
                    <RadioButton Name="navOtimizacao" Content="OTIMIZACAO" GroupName="Nav" Style="{StaticResource NavItem}"/>
                    <RadioButton Name="navLimpeza" Content="LIMPEZA" GroupName="Nav" Style="{StaticResource NavItem}"/>
                    <RadioButton Name="navPrivacidade" Content="PRIVACIDADE" GroupName="Nav" Style="{StaticResource NavItem}"/>
                    <RadioButton Name="navAvancado" Content="AVANCADO" GroupName="Nav" Style="{StaticResource NavItem}"/>
                    <RadioButton Name="navLegacy" Content="MODO LEGACY" GroupName="Nav" Style="{StaticResource NavItem}"/>

                    <TextBlock Text="SISTEMA" Style="{StaticResource NavSection}"/>
                    <RadioButton Name="navStatus" Content="STATUS" GroupName="Nav" Style="{StaticResource NavItem}"/>
                    <RadioButton Name="navSobre" Content="SOBRE" GroupName="Nav" Style="{StaticResource NavItem}"/>
                </StackPanel>

                <StackPanel DockPanel.Dock="Bottom" Margin="18,0,0,18">
                    <StackPanel Orientation="Horizontal">
                        <Ellipse Width="7" Height="7" Fill="{StaticResource Online}" VerticalAlignment="Center"/>
                        <TextBlock Text="Executando como Admin" FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="9" Margin="6,0,0,0" VerticalAlignment="Center"/>
                    </StackPanel>
                </StackPanel>
            </DockPanel>
        </Border>

        <!-- CONTEUDO -->
        <Grid Grid.Column="1">
            <Grid.RowDefinitions>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0" Margin="24,22,24,6">

                <!-- INICIO -->
                <StackPanel Name="pageInicio">
                    <TextBlock Text="INICIO" Style="{StaticResource PageTitle}"/>
                    <Border Width="34" Height="3" CornerRadius="2" Background="{StaticResource PurpleGradient}" HorizontalAlignment="Left" Margin="2,6,0,4"/>
                    <TextBlock Text="Recomendado antes de aplicar qualquer alteracao" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,16"/>

                    <Border Style="{StaticResource BigCard}" Padding="18" Margin="0,0,0,10">
                        <StackPanel>
                            <TextBlock Text="PONTO DE RESTAURACAO" Style="{StaticResource CategoryHeader}" Margin="0,0,0,4"/>
                            <TextBlock Foreground="#CCCCCC" FontSize="12" TextWrapping="Wrap"
                                       Text="Cria um ponto de restauracao do sistema, permitindo desfazer as alteracoes caso algo de errado. Recomendado antes de aplicar otimizacoes em massa ou o Modo Legacy."/>
                            <Button Name="btnRestorePointHome" Content="Criar Ponto de Restauracao" Style="{StaticResource PrimaryButton}" Width="220" HorizontalAlignment="Left" Margin="0,10,0,0"/>
                            <TextBlock Name="txtInicioStatus" Text="" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,8,0,0"/>
                        </StackPanel>
                    </Border>

                    <Border Style="{StaticResource BigCard}" Padding="18" Margin="0,0,0,10">
                        <StackPanel>
                            <TextBlock Text="ATALHO" Style="{StaticResource CategoryHeader}" Margin="0,0,0,4"/>
                            <TextBlock Foreground="#CCCCCC" FontSize="12" TextWrapping="Wrap"
                                       Text="Aplica um conjunto seguro de otimizacoes de desempenho e limpeza, sem mexer em privacidade ou remover componentes."/>
                            <Button Name="btnQuickApply" Content="Aplicar Otimizacoes Essenciais" Style="{StaticResource GhostButton}" Width="220" HorizontalAlignment="Left" Margin="0,10,0,0"/>
                        </StackPanel>
                    </Border>

                    <Border Style="{StaticResource BigCard}" Padding="18">
                        <StackPanel>
                            <TextBlock Text="PRIMEIROS PASSOS" Style="{StaticResource CategoryHeader}" Margin="0,0,0,4"/>
                            <TextBlock Foreground="#CCCCCC" FontSize="12" TextWrapping="Wrap"
                                       Text="Acabou de formatar? Va na aba INSTALAR APPS para baixar seus programas essenciais via winget antes de otimizar o sistema."/>
                        </StackPanel>
                    </Border>
                </StackPanel>

                <!-- INSTALAR APPS -->
                <StackPanel Name="pageInstalar" Visibility="Collapsed">
                    <TextBlock Text="INSTALAR APPS" Style="{StaticResource PageTitle}"/>
                    <Border Width="34" Height="3" CornerRadius="2" Background="{StaticResource PurpleGradient}" HorizontalAlignment="Left" Margin="2,6,0,4"/>
                    <TextBlock Text="Programas essenciais pos-formatacao, instalados via winget" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,0"/>
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Height="410">
                        <StackPanel>
                            <TextBlock Text="NAVEGADORES" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Google.Chrome">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Chrome" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Google Chrome" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Mozilla.Firefox">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Firefox" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Mozilla Firefox" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Brave.Brave">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Brave" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Brave Browser" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="COMUNICACAO" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Discord.Discord">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Discord" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Discord" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Telegram.TelegramDesktop">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Telegram" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Telegram Desktop" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: WhatsApp.WhatsApp">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_WhatsApp" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="WhatsApp" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Zoom.Zoom">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Zoom" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Zoom" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="UTILITARIOS" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: 7zip.7zip">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_7zip" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="7-Zip" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: voidtools.Everything">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Everything" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Everything" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Microsoft.PowerToys">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_PowerToys" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Microsoft PowerToys" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Notepad++.Notepad++">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_NotepadPlus" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Notepad++" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: RevoUninstaller.RevoUninstaller">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Revo" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Revo Uninstaller" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="MIDIA" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: VideoLAN.VLC">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_VLC" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="VLC Media Player" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Spotify.Spotify">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Spotify" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Spotify" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: OBSProject.OBSStudio">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_OBS" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="OBS Studio" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: CodecGuide.K-LiteCodecPack.Standard">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_KLite" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="K-Lite Codec Pack" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="DESENVOLVIMENTO" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Microsoft.VisualStudioCode">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_VSCode" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Visual Studio Code" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Git.Git">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Git" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Git" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Python.Python.3.12">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Python" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Python 3" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: OpenJS.NodeJS.LTS">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_NodeJS" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Node.js LTS" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Microsoft.WindowsTerminal">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Terminal" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Windows Terminal" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="JOGOS" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Valve.Steam">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Steam" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Steam" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: EpicGames.EpicGamesLauncher">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Epic" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Epic Games Launcher" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="winget id: Blizzard.BattleNet">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkApp_Battlenet" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Battle.net" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Foreground="{StaticResource TextMuted}" FontSize="10" Margin="2,6,0,0" TextWrapping="Wrap"
                                       Text="Requer o winget (App Installer) instalado. Em Windows 10/11 atualizados ele ja vem por padrao; caso falte, instale o 'App Installer' pela Microsoft Store."/>
                        </StackPanel>
                    </ScrollViewer>
                </StackPanel>

                <!-- OTIMIZACAO -->
                <StackPanel Name="pageOtimizacao" Visibility="Collapsed">
                    <TextBlock Text="OTIMIZACAO" Style="{StaticResource PageTitle}"/>
                    <Border Width="34" Height="3" CornerRadius="2" Background="{StaticResource PurpleGradient}" HorizontalAlignment="Left" Margin="2,6,0,4"/>
                    <TextBlock Text="Ajustes de desempenho e sistema - passe o mouse sobre um item para detalhes" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,0"/>
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Height="400">
                        <StackPanel>
                            <TextBlock Text="DESEMPENHO" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Ativa o plano de energia de alto desempenho do Windows">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkPowerPlan" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Plano de Alto Desempenho" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Reduz efeitos graficos priorizando velocidade">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkVisualEffects" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Efeitos visuais p/ desempenho" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desliga Game Bar e Game DVR (pode reduzir consumo em jogos)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkGameBar" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Xbox Game Bar" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Apps de startup abrem imediatamente ao logar">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkStartupDelay" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover atraso de inicializacao" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Deixa janelas e menus com transicoes mais rapidas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkAnimacoes" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Reduzir animacoes" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Impede o PC de dormir/hibernar durante sessoes longas (util para downloads e renders)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkNoSleep" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Nunca suspender (energia AC)" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="SISTEMA / ARMAZENAMENTO" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove o arquivo hiberfil.sys e libera espaco em disco">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkHibernacao" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar hibernacao" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Reduz uso de disco em segundo plano (busca fica mais lenta)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkIndexacao" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar indexacao de busca" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Recomendado para SSDs; reduz uso de disco em segundo plano">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkSuperfetch" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar SysMain/Superfetch" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desliga o boot rapido (Fast Startup); util se o PC apresenta travamentos apos desligar">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkFastStartup" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Inicializacao Rapida" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="CONFORTO E INTERFACE" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove os popups de ativacao de teclas de aderencia/alternancia ao segurar Shift ou pressionar teclas repetidamente">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkStickyKeys" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Sem avisos de teclas de aderencia" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Zera o delay de abertura de menus e acelera as transicoes de janelas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkFastMenus" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Acelerar menus" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desliga a transparencia da barra de tarefas e janelas (Acrylic), reduzindo uso de GPU">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkTransparencia" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar transparencia" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa baloes e notificacoes do sistema (toasts)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkNotificacoes" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar notificacoes" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="REDE" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Configura os servidores DNS 1.1.1.1 e 1.0.0.1 (Cloudflare) em todas as interfaces de rede ativas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkFastDNS" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="DNS rapido (Cloudflare)" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Impede que o Windows desligue o adaptador de rede para economizar energia">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkNetAdapterPower" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Sem economia de energia na rede" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>
                        </StackPanel>
                    </ScrollViewer>
                </StackPanel>

                <!-- LIMPEZA -->
                <StackPanel Name="pageLimpeza" Visibility="Collapsed">
                    <TextBlock Text="LIMPEZA" Style="{StaticResource PageTitle}"/>
                    <Border Width="34" Height="3" CornerRadius="2" Background="{StaticResource PurpleGradient}" HorizontalAlignment="Left" Margin="2,6,0,4"/>
                    <TextBlock Text="Liberar espaco e remover arquivos desnecessarios" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,0"/>
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Height="400">
                        <StackPanel>
                            <TextBlock Text="ARQUIVOS E CACHE" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Limpa %TEMP% e C:\Windows\Temp">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkTemp" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Arquivos temporarios" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove definitivamente os arquivos da lixeira">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkLixeira" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Esvaziar Lixeira" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Limpa a pasta SoftwareDistribution\Download">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkWinUpdateCache" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Cache do Windows Update" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove arquivos de pre-carregamento do Windows">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkPrefetch" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Pasta Prefetch" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Executa ipconfig /flushdns">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkDNS" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Cache DNS" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Reinicia o Explorer e limpa thumbcache">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkMiniaturas" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Cache de miniaturas" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Limpa os registros do Visualizador de Eventos">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkLogs" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Logs de eventos" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove dumps de memoria e minidumps de travamentos antigos">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkCrashDumps" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Dumps de memoria" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Limpa a fila de relatorios de erro do Windows (WER)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkWER" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Relatorios de erro" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove listas de arquivos recentes fixadas na barra de tarefas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkJumplists" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Jump lists / recentes" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Reconstroi o cache de fontes do sistema (util quando fontes aparecem corrompidas)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkFontCache" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Cache de fontes" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>
                        </StackPanel>
                    </ScrollViewer>
                </StackPanel>

                <!-- PRIVACIDADE -->
                <StackPanel Name="pagePrivacidade" Visibility="Collapsed">
                    <TextBlock Text="PRIVACIDADE" Style="{StaticResource PageTitle}"/>
                    <Border Width="34" Height="3" CornerRadius="2" Background="{StaticResource PurpleGradient}" HorizontalAlignment="Left" Margin="2,6,0,4"/>
                    <TextBlock Text="Telemetria, rastreamento e coleta de dados" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,0"/>
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Height="400">
                        <StackPanel>
                            <TextBlock Text="COLETA DE DADOS" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa o servico DiagTrack e a coleta de dados">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkTelemetria" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Telemetria do Windows" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa a assistente virtual do Windows">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkCortana" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Cortana" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa anuncios personalizados entre apps">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkAdsID" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="ID de publicidade" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Impede que apps rodem sem estarem abertos">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkBackgroundApps" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Apps em segundo plano" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa o servico de geolocalizacao do sistema">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkLocalizacao" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Rastreamento de localizacao" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove sugestoes e anuncios no menu Iniciar">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkDicas" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Dicas e sugestoes" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Para de pedir feedback periodicamente">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkFeedback" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Solicitacoes de feedback" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa o historico e a sincronizacao da area de transferencia">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkClipboardHistory" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Historico da area de transf." FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>
                        </StackPanel>
                    </ScrollViewer>
                </StackPanel>

                <!-- AVANCADO -->
                <StackPanel Name="pageAvancado" Visibility="Collapsed">
                    <TextBlock Text="AVANCADO" Style="{StaticResource PageTitle}"/>
                    <Border Width="34" Height="3" CornerRadius="2" Background="{StaticResource PurpleGradient}" HorizontalAlignment="Left" Margin="2,6,0,4"/>
                    <TextBlock Text="Ajustes profundos de sistema, rede, GPU e registro - para quem sabe o que esta fazendo" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,0"/>
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Height="400">
                        <StackPanel>
                            <TextBlock Text="SISTEMA E DESEMPENHO" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Ajusta servicos para Manual/Desabilitado e recalcula o SvcHostSplitThresholdInKB conforme a RAM instalada, reduzindo processos svchost.exe">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkServicesManual" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Otimizar servicos" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Ajusta delay de menu, sombra de lista, animacoes de taskbar e outros efeitos para o modo mais leve possivel">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkVisualExtra" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Efeitos visuais - extremo" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Storage Sense apaga arquivos temporarios automaticamente; aqui ele e desativado">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkStorageSense" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Storage Sense" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Impede o Windows de usar sua banda para enviar updates a outros PCs (Delivery Optimization)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkDeliveryOpt" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Delivery Optimization" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Habilita a opcao 'Finalizar Tarefa' ao clicar com botao direito num app na barra de tarefas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkEndTaskTaskbar" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Finalizar tarefa pela taskbar" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Se ativado, o WPBT permite que o fabricante execute programas no boot sem consentimento; aqui e desabilitado por seguranca">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkWPBT" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar WPBT" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Util em dual boot com Linux; corrige a sincronizacao de hora entre os sistemas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkUTC" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Relogio em UTC" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove avisos ao abrir arquivos .rdp nao assinados (introduzidos em updates recentes do Windows)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkRdpWarning" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Sem aviso de RDP" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Limpeza segura de registro: cache MUI, lista de documentos recentes (RecentDocs) e historico da caixa Executar (RunMRU). Nao mexe em programas instalados">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkRegistryOptimize" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Otimizar registro" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Executa TRIM apenas nas unidades identificadas como SSD, ajudando a manter a velocidade de escrita ao longo do tempo">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkTrimSSD" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Otimizar/TRIM em SSDs" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Pausa o Windows Update automatico por 7 dias, evitando reinicializacoes ou quedas de desempenho inesperadas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkPauseWU" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Pausar Windows Update (7 dias)" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="REDE E INPUT LAG" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Zera a aceleracao do ponteiro (MouseSpeed/MouseThreshold). Movimento do mouse fica 1 para 1, sem curva do Windows - reduz sensacao de input lag">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkMouseAccel" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover aceleracao do mouse" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Zera o SystemResponsiveness e maximiza o NetworkThrottlingIndex, priorizando tarefas multimidia/jogos sobre tarefas em segundo plano">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkGameResponsiveness" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Priorizar resposta em jogos" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa o algoritmo de Nagle (TcpAckFrequency/TCPNoDelay) em todas as interfaces de rede, reduzindo latencia em jogos online e apps sensiveis a ping">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkNagle" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar algoritmo de Nagle" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Ativa o GPU Hardware Scheduling (HAGS), deixando a propria GPU gerenciar a fila de quadros - pode reduzir input lag em placas compativeis">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkHAGS" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="GPU Scheduling por hardware" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Ajusta o Win32PrioritySeparation para dar mais fatias de CPU ao aplicativo em primeiro plano (janela ativa), melhorando a responsividade percebida">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkForegroundPriority" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Priorizar app em foco" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="PERFORMANCE EXTREMA" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Cria e ativa o plano de energia oculto 'Ultimate Performance', ainda mais agressivo que o Alto Desempenho">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkUltimatePerf" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Plano Ultimate Performance" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Impede o Windows de reduzir o desempenho de processos em segundo plano para economizar energia">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkPowerThrottling" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Power Throttling" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Mantem todos os nucleos da CPU ativos no plano de energia atual, evitando o delay de 'acordar' nucleos parados (core parking)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkCoreParking" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Core Parking" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa as otimizacoes de tela cheia do Windows para todos os jogos, evitando limitacao de FPS e travamentos em algumas placas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkFSEGlobal" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Fullscreen Opt. global" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="PRIVACIDADE E TELEMETRIA EXTRA" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Apaga historico de documentos recentes, area de transferencia e historico de execucao (Activity Feed)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkActivityHistory" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Apagar historico de atividades" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Bloqueia recomendacoes de apps da Microsoft Store ao buscar no menu Iniciar (via icacls no store.db)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkStoreSearch" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Bloquear sugestoes da Store" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Impede instalacao automatica de jogos/apps/links promovidos pela Microsoft Store">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkConsumerFeatures" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Consumer Features" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Alem da telemetria basica: desativa envio de amostras do Defender, servico wermgr, telemetria do PowerShell 7 e mais chaves de coleta">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkTelemetriaExtra" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Telemetria - modo estendido" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa varias opcoes de telemetria, popups e sugestoes especificas do navegador Microsoft Edge">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkEdgeDebloat" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Debloat do Microsoft Edge" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa Brave Rewards, Leo AI, carteira cripto, VPN e telemetria do navegador Brave (nao tem efeito se o Brave nao estiver instalado)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkBraveDebloat" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Debloat do navegador Brave" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove ou desativa recursos e pacotes de IA do Windows (Copilot, Recall, etc)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkWindowsAI" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Windows AI / Copilot" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="ATENCAO: REMOVER COMPONENTES - RISCO" Style="{StaticResource CategoryHeaderWarning}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRowWarning}" ToolTip="Remove os widgets no canto inferior esquerdo da barra de tarefas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkRemoveWidgets" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover Widgets" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRowWarning}" ToolTip="Remove Home e Galeria do Explorer e define 'Este Computador' como pagina padrao">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkRemoveHomeGallery" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover Home/Galeria" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRowWarning}" ToolTip="Remove servicos do Xbox, o app Xbox, Game Bar e componentes de autenticacao relacionados">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkXboxRemoval" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover Xbox/Gaming" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRowWarning}" ToolTip="Remove apps pre-instalados indesejados: Feedback Hub, Bing News/Weather, Clipchamp, Solitaire, Teams e outros">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkDebloatApps" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover apps pre-instalados" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRowWarning}" ToolTip="ATENCAO: usa o desinstalador nativo do OneDrive e limpa pastas residuais. Seus arquivos locais no OneDrive nao sao apagados, mas a sincronizacao para">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkRemoveOneDrive" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover OneDrive" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRowWarning}" ToolTip="ATENCAO: desativa a criptografia BitLocker da unidade do sistema. So use se souber o que esta fazendo">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkDisableBitLocker" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar BitLocker" FontSize="11" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>
                        </StackPanel>
                    </ScrollViewer>
                </StackPanel>

                <!-- MODO LEGACY -->
                <StackPanel Name="pageLegacy" Visibility="Collapsed">
                    <TextBlock Text="MODO LEGACY" Style="{StaticResource PageTitle}"/>
                    <Border Width="34" Height="3" CornerRadius="2" Background="{StaticResource PurpleGradient}" HorizontalAlignment="Left" Margin="2,6,0,4"/>
                    <TextBlock Text="Otimizacao completa do sistema com foco no jogo em uso" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,12"/>

                    <Border Style="{StaticResource BigCard}" Padding="16" Margin="0,0,0,10">
                        <StackPanel>
                            <TextBlock Text="JOGO" Style="{StaticResource CategoryHeader}" Margin="0,0,0,4"/>
                            <StackPanel Orientation="Horizontal">
                                <Button Name="btnDetectGame" Content="Detectar Automaticamente" Style="{StaticResource GhostButton}" Width="190" Margin="0,0,10,0"/>
                                <ComboBox Name="cmbGames" Width="210" Margin="0,0,10,0"/>
                                <TextBlock Name="txtDetectedGame" Text="Nenhum jogo detectado" VerticalAlignment="Center" Foreground="{StaticResource TextMuted}" FontSize="11"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>

                    <Border Style="{StaticResource BigCard}" Padding="16" Margin="0,0,0,10">
                        <StackPanel>
                            <TextBlock Text="APLICAR" Style="{StaticResource CategoryHeader}" Margin="0,0,0,4"/>
                            <StackPanel Orientation="Horizontal">
                                <Button Name="btnApplyGameOnly" Content="Otimizar Apenas o Jogo" Style="{StaticResource GhostButton}" Width="190" Margin="0,0,10,0"/>
                                <Button Name="btnApplyLegacyFull" Content="Aplicar Modo Legacy Completo" Style="{StaticResource PrimaryButton}" Width="220"/>
                            </StackPanel>
                            <TextBlock Foreground="{StaticResource TextMuted}" FontSize="10" Margin="0,8,0,0" TextWrapping="Wrap"
                                       Text="O modo completo aplica todas as otimizacoes de desempenho, limpeza, privacidade e rede do painel, alem de priorizar o jogo selecionado."/>
                        </StackPanel>
                    </Border>

                    <Border Style="{StaticResource BigCard}" Padding="14,12">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal">
                                <Ellipse Name="legacyStatusDot" Width="8" Height="8" Fill="{StaticResource Purple}" VerticalAlignment="Center"/>
                                <TextBlock Name="txtLegacyStatus" Text="Modo legacy pronto" FontFamily="Consolas" FontSize="12" Foreground="{StaticResource ConsoleText}" Margin="8,0,0,0" VerticalAlignment="Center"/>
                            </StackPanel>
                            <ProgressBar Name="progLegacyBar" Minimum="0" Maximum="100" Value="0" Margin="0,10,0,0"/>
                        </StackPanel>
                    </Border>
                </StackPanel>

                <!-- STATUS -->
                <StackPanel Name="pageStatus" Visibility="Collapsed">
                    <TextBlock Text="STATUS DO SISTEMA" Style="{StaticResource PageTitle}"/>
                    <Border Width="34" Height="3" CornerRadius="2" Background="{StaticResource PurpleGradient}" HorizontalAlignment="Left" Margin="2,6,0,4"/>
                    <TextBlock Text="Uso de recursos em tempo real" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,14"/>

                    <UniformGrid Columns="2" Rows="2">
                        <Border Style="{StaticResource BigCard}" Margin="0,0,8,8" Padding="14">
                            <StackPanel>
                                <Grid>
                                    <TextBlock Text="CPU" FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="11"/>
                                    <TextBlock Name="txtCpuPercent" Text="--%" FontFamily="Consolas" FontSize="11" FontWeight="Bold" HorizontalAlignment="Right" Foreground="{StaticResource Purple}"/>
                                </Grid>
                                <ProgressBar Name="barCpu" Value="0" Margin="0,8,0,6"/>
                                <TextBlock Name="txtCpuName" Text="Carregando..." Foreground="{StaticResource TextMuted}" FontSize="10" TextWrapping="Wrap"/>
                            </StackPanel>
                        </Border>
                        <Border Style="{StaticResource BigCard}" Margin="0,0,0,8" Padding="14">
                            <StackPanel>
                                <Grid>
                                    <TextBlock Text="MEMORIA RAM" FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="11"/>
                                    <TextBlock Name="txtRamPercent" Text="--%" FontFamily="Consolas" FontSize="11" FontWeight="Bold" HorizontalAlignment="Right" Foreground="{StaticResource Purple}"/>
                                </Grid>
                                <ProgressBar Name="barRam" Value="0" Margin="0,8,0,6"/>
                                <TextBlock Name="txtRamDetail" Text="Carregando..." Foreground="{StaticResource TextMuted}" FontSize="10"/>
                            </StackPanel>
                        </Border>
                        <Border Style="{StaticResource BigCard}" Margin="0,0,8,0" Padding="14">
                            <StackPanel>
                                <Grid>
                                    <TextBlock Text="DISCO (C:)" FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="11"/>
                                    <TextBlock Name="txtDiskPercent" Text="--%" FontFamily="Consolas" FontSize="11" FontWeight="Bold" HorizontalAlignment="Right" Foreground="{StaticResource Purple}"/>
                                </Grid>
                                <ProgressBar Name="barDisk" Value="0" Margin="0,8,0,6"/>
                                <TextBlock Name="txtDiskDetail" Text="Carregando..." Foreground="{StaticResource TextMuted}" FontSize="10"/>
                            </StackPanel>
                        </Border>
                        <Border Style="{StaticResource BigCard}" Margin="0,0,0,0" Padding="14">
                            <StackPanel>
                                <Grid>
                                    <TextBlock Text="GPU" FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="11"/>
                                    <TextBlock Name="txtGpuPercent" Text="--%" FontFamily="Consolas" FontSize="11" FontWeight="Bold" HorizontalAlignment="Right" Foreground="{StaticResource Purple}"/>
                                </Grid>
                                <ProgressBar Name="barGpu" Value="0" Margin="0,8,0,6"/>
                                <TextBlock Name="txtGpuName" Text="Carregando..." Foreground="{StaticResource TextMuted}" FontSize="10" TextWrapping="Wrap"/>
                            </StackPanel>
                        </Border>
                    </UniformGrid>

                    <Border Style="{StaticResource BigCard}" Margin="0,4,0,0" Padding="14">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="TEMPO LIGADO: " FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="11"/>
                            <TextBlock Name="txtUptime" Text="--" FontFamily="Consolas" FontSize="11" FontWeight="SemiBold"/>
                            <TextBlock Text="//  atualiza a cada 2s" FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="10,0,0,0"/>
                        </StackPanel>
                    </Border>
                </StackPanel>

                <!-- SOBRE -->
                <StackPanel Name="pageSobre" Visibility="Collapsed">
                    <TextBlock Text="SOBRE" Style="{StaticResource PageTitle}"/>
                    <Border Width="34" Height="3" CornerRadius="2" Background="{StaticResource PurpleGradient}" HorizontalAlignment="Left" Margin="2,6,0,4"/>
                    <TextBlock Text="Informacoes do painel" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,16"/>
                    <Border Style="{StaticResource BigCard}" Padding="18" Margin="0">
                        <StackPanel>
                            <TextBlock Text="LegacyMods" FontFamily="Consolas" FontSize="16" FontWeight="Bold" Foreground="{StaticResource Purple}"/>
                            <TextBlock Margin="0,10,0,0" Foreground="#CCCCCC" FontSize="12" TextWrapping="Wrap"
                                       Text="Painel de otimizacao, limpeza, privacidade, desempenho em jogos e instalacao de apps para Windows. Selecione as opcoes desejadas e clique em 'Aplicar Selecionados', ou use o Modo Legacy para uma otimizacao completa. Crie um ponto de restauracao na pagina Inicio antes de aplicar mudancas em massa."/>
                        </StackPanel>
                    </Border>
                </StackPanel>

            </Grid>

            <!-- RODAPE (paginas de tweaks / apps) -->
            <Border Grid.Row="1" Name="footerBar" Background="{StaticResource Card}" Margin="24,0,24,18" CornerRadius="12" Padding="14,12" BorderBrush="{StaticResource Border0}" BorderThickness="1" Visibility="Collapsed" Effect="{StaticResource CardShadow}">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>

                    <StackPanel Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="4" Orientation="Horizontal" Margin="0,0,0,10">
                        <Ellipse Width="8" Height="8" Fill="{StaticResource Purple}" VerticalAlignment="Center"/>
                        <TextBlock Name="txtStatus" Text="Pronto. Selecione as opcoes e clique em aplicar selecionados." FontFamily="Consolas" FontSize="11" Foreground="{StaticResource ConsoleText}" Margin="8,0,0,0" VerticalAlignment="Center"/>
                    </StackPanel>

                    <ProgressBar Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="4" Name="progBar" Minimum="0" Maximum="100" Value="0" Margin="0,0,0,10"/>

                    <TextBlock Grid.Row="2" Grid.Column="0" Text="Aplica tudo que estiver marcado em Otimizacao, Limpeza, Privacidade, Avancado e Instalar Apps." Foreground="{StaticResource TextMuted}" FontSize="9" VerticalAlignment="Center" TextWrapping="Wrap"/>
                    <Button Grid.Row="2" Grid.Column="1" Name="btnSelectAll" Content="Selecionar Tudo" Style="{StaticResource GhostButton}" Margin="0,0,8,0"/>
                    <Button Grid.Row="2" Grid.Column="2" Name="btnClear" Content="Limpar" Style="{StaticResource GhostButton}" Margin="0,0,8,0"/>
                    <Button Grid.Row="2" Grid.Column="3" Name="btnApply" Content="Aplicar Selecionados" Style="{StaticResource PrimaryButton}" Width="190" ToolTip="Aplica todas as opcoes marcadas em todas as abas (Otimizacao, Limpeza, Privacidade, Avancado, Instalar Apps)."/>
                </Grid>
            </Border>

        </Grid>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Coleta referencias de todos os controles nomeados
$ctrl = @{}
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    $ctrl[$_.Name] = $window.FindName($_.Name)
}

# ---------------------------------------------------------------------------
# Metricas de sistema (aba Status)
# ---------------------------------------------------------------------------
# CORRECAO: esta secao foi MOVIDA para cima, antes da navegacao (Show-Page),
# porque $script:statusTimer precisa existir ANTES de Show-Page ser chamado
# pela primeira vez (ver comentario detalhado logo abaixo de sua criacao).
$cachedCpuName = $null
$cachedGpuName = $null

function Get-CpuPercent {
    try { [math]::Round((Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime, 0) }
    catch { $null }
}
function Get-RamStats {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
        $usedGB  = [math]::Round($totalGB - $freeGB, 1)
        $pct     = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 0) } else { 0 }
        [PSCustomObject]@{ Total = $totalGB; Used = $usedGB; Percent = $pct }
    } catch { $null }
}
function Get-DiskStats {
    try {
        $d = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $totalGB = [math]::Round($d.Size / 1GB, 1)
        $freeGB  = [math]::Round($d.FreeSpace / 1GB, 1)
        $usedGB  = [math]::Round($totalGB - $freeGB, 1)
        $pct     = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 0) } else { 0 }
        [PSCustomObject]@{ Total = $totalGB; Used = $usedGB; Percent = $pct }
    } catch { $null }
}
function Get-GpuPercent {
    try {
        $samples = (Get-Counter '\GPU Engine(*engtype_3D)\Utilization Percentage' -ErrorAction Stop).CounterSamples
        $sum = ($samples | Group-Object InstanceName | ForEach-Object { ($_.Group | Measure-Object -Property CookedValue -Maximum).Maximum } | Measure-Object -Sum).Sum
        [math]::Round([math]::Min([double]$sum, 100), 0)
    } catch { $null }
}
function Get-UptimeText {
    try {
        $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $span = (Get-Date) - $boot
        "{0}d {1}h {2}min" -f $span.Days, $span.Hours, $span.Minutes
    } catch { "--" }
}

function Update-StatusMetrics {
    if (-not $cachedCpuName) {
        try { $cachedCpuName = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name } catch { $cachedCpuName = "CPU nao identificada" }
    }
    if (-not $cachedGpuName) {
        try { $cachedGpuName = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name } catch { $cachedGpuName = "GPU nao identificada" }
    }

    $cpu = Get-CpuPercent
    if ($null -ne $cpu) { $ctrl.barCpu.Value = $cpu; $ctrl.txtCpuPercent.Text = "$cpu%" } else { $ctrl.txtCpuPercent.Text = "N/D" }
    $ctrl.txtCpuName.Text = $cachedCpuName

    $ram = Get-RamStats
    if ($ram) {
        $ctrl.barRam.Value = $ram.Percent
        $ctrl.txtRamPercent.Text = "$($ram.Percent)%"
        $ctrl.txtRamDetail.Text = "$($ram.Used) GB / $($ram.Total) GB"
    }

    $disk = Get-DiskStats
    if ($disk) {
        $ctrl.barDisk.Value = $disk.Percent
        $ctrl.txtDiskPercent.Text = "$($disk.Percent)%"
        $ctrl.txtDiskDetail.Text = "$($disk.Used) GB / $($disk.Total) GB"
    }

    $gpu = Get-GpuPercent
    if ($null -ne $gpu) { $ctrl.barGpu.Value = $gpu; $ctrl.txtGpuPercent.Text = "$gpu%" } else { $ctrl.txtGpuPercent.Text = "N/D" }
    $ctrl.txtGpuName.Text = $cachedGpuName

    $ctrl.txtUptime.Text = Get-UptimeText
}

# --- CORRECAO PRINCIPAL DO BUG ---
# Antes, esta criacao do timer estava la embaixo (na secao original "Metricas
# de sistema"), DEPOIS da chamada "Show-Page 'navInicio'". Como Show-Page usa
# $script:statusTimer.Start()/Stop(), a primeira chamada (disparada logo
# abaixo) tentava usar uma variavel que ainda nao existia -> $null -> erro
# "Nao e possivel chamar um metodo em uma expressao de valor nulo".
# Agora o timer e criado aqui, ANTES de qualquer chamada a Show-Page.
$script:statusTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:statusTimer.Interval = [TimeSpan]::FromSeconds(2)
$script:statusTimer.Add_Tick({ Update-StatusMetrics })

# ---------------------------------------------------------------------------
# Navegacao entre paginas (com fade-in animado)
# ---------------------------------------------------------------------------
$pages = @{
    navInicio      = $ctrl.pageInicio
    navInstalar    = $ctrl.pageInstalar
    navOtimizacao  = $ctrl.pageOtimizacao
    navLimpeza     = $ctrl.pageLimpeza
    navPrivacidade = $ctrl.pagePrivacidade
    navAvancado    = $ctrl.pageAvancado
    navLegacy      = $ctrl.pageLegacy
    navStatus      = $ctrl.pageStatus
    navSobre       = $ctrl.pageSobre
}

function Show-Page($navKey) {
    foreach ($key in $pages.Keys) {
        if ($key -eq $navKey) {
            $pages[$key].Visibility = 'Visible'
            $pages[$key].Opacity = 0
            $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
            $fadeIn.From = 0
            $fadeIn.To = 1
            $fadeIn.Duration = [TimeSpan]::FromMilliseconds(220)
            $pages[$key].BeginAnimation([System.Windows.FrameworkElement]::OpacityProperty, $fadeIn)
        } else {
            $pages[$key].Visibility = 'Collapsed'
        }
    }
    $ctrl.footerBar.Visibility = if ($navKey -in @('navInstalar','navOtimizacao','navLimpeza','navPrivacidade','navAvancado')) { 'Visible' } else { 'Collapsed' }
    # Checagem de nulo defensiva: mesmo com a criacao movida para cima, mantemos
    # esta protecao para o caso de o codigo ser reorganizado de novo no futuro.
    if ($script:statusTimer) {
        if ($navKey -eq 'navStatus') { $script:statusTimer.Start() } else { $script:statusTimer.Stop() }
    }
}

foreach ($navKey in $pages.Keys) {
    $ctrl[$navKey].Add_Checked({ Show-Page $this.Name }.GetNewClosure())
}

# Chamada explicita: o RadioButton navInicio ja nasce com IsChecked="True" no XAML,
# entao o evento Checked (registrado acima) nunca dispara para ele - o WPF so
# levanta o evento numa MUDANCA de estado. Sem esta chamada, a pagina Inicio
# ate aparece (porque e a unica sem Visibility="Collapsed" no XAML), mas o
# footerBar e o statusTimer nunca sao inicializados corretamente pelo fluxo
# normal. Chamamos aqui para garantir que o estado inicial fique 100% consistente.
Show-Page 'navInicio'

# Clicar em qualquer parte da linha marca/desmarca o checkbox correspondente.
foreach ($key in ($ctrl.Keys | Where-Object { $_ -like 'chk*' })) {
    $cb = $ctrl[$key]
    $rowBorder = $cb.Parent.Parent
    if ($rowBorder) {
        $rowBorder.Add_MouseLeftButtonUp({
            param($rbSender, $rbArgs)
            $src = $rbArgs.OriginalSource
            $isOnCheckbox = $false
            while ($src) {
                if ($src -is [System.Windows.Controls.CheckBox]) { $isOnCheckbox = $true; break }
                if ($src -is [System.Windows.Media.Visual] -or $src -is [System.Windows.Media.Media3D.Visual3D]) {
                    $src = [System.Windows.Media.VisualTreeHelper]::GetParent($src)
                } else {
                    $src = $null
                }
            }
            if (-not $isOnCheckbox) { $cb.IsChecked = -not $cb.IsChecked }
        }.GetNewClosure())
        $rowBorder.Cursor = [System.Windows.Input.Cursors]::Hand
    }
}

# ---------------------------------------------------------------------------
# Status animado (substitui o console de log por um indicador com fade)
# ---------------------------------------------------------------------------
function Show-Status {
    param([string]$Text, $Target)
    if (-not $Target) { $Target = $ctrl.txtStatus }
    $msg = $Text
    $tgt = $Target
    $fadeOut = New-Object System.Windows.Media.Animation.DoubleAnimation
    $fadeOut.From = 1
    $fadeOut.To = 0.25
    $fadeOut.Duration = [TimeSpan]::FromMilliseconds(100)
    $fadeOut.Add_Completed({
        $tgt.Text = $msg
        $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fadeIn.From = 0.25
        $fadeIn.To = 1
        $fadeIn.Duration = [TimeSpan]::FromMilliseconds(180)
        $tgt.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty, $fadeIn)
    }.GetNewClosure())
    $Target.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty, $fadeOut)
}

# ---------------------------------------------------------------------------
# Funcoes de otimizacao, limpeza e privacidade
# ---------------------------------------------------------------------------
function Enable-HighPerformancePlan { powercfg -setactive SCHEME_MIN }
function Set-VisualEffectsPerformance {
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Force -ErrorAction SilentlyContinue
}
function Disable-GameBar {
    New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue
}
function Remove-StartupDelay {
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -Value 0
}
function Reduce-Animacoes {
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Value 0 -Force -ErrorAction SilentlyContinue
}
function Set-NoSleepOnAC { powercfg -change -standby-timeout-ac 0; powercfg -change -monitor-timeout-ac 0 }
function Disable-Hibernacao { powercfg -h off }
function Disable-Indexacao {
    Get-Service "WSearch" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
    Set-Service "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue
}
function Disable-Superfetch {
    Get-Service "SysMain" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
    Set-Service "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
}
function Disable-FastStartup {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Force -ErrorAction SilentlyContinue
}

function Clear-TempFiles {
    Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path "$env:WINDIR\Temp" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
function Clear-Lixeira { Clear-RecycleBin -Force -ErrorAction SilentlyContinue }
function Clear-WinUpdateCache {
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
}
function Clear-Prefetch { Remove-Item "$env:WINDIR\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue }
function Clear-DNSCache { ipconfig /flushdns | Out-Null }
function Clear-Thumbnails {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 400
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
    Start-Process explorer
}
function Clear-EventLogs { wevtutil el | ForEach-Object { wevtutil cl "$_" 2>$null } }
function Clear-CrashDumps {
    Remove-Item "$env:WINDIR\Minidump\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:WINDIR\MEMORY.DMP" -Force -ErrorAction SilentlyContinue
}
function Clear-WER {
    Remove-Item "$env:ProgramData\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -ErrorAction SilentlyContinue
}
function Clear-Jumplists {
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations\*" -Force -ErrorAction SilentlyContinue
}
function Clear-FontCache {
    Stop-Service FontCache -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:WINDIR\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service FontCache -ErrorAction SilentlyContinue
}

function Disable-Telemetria {
    Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
}
function Disable-Cortana {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0
}
function Disable-AdsID {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
}
function Disable-BackgroundApps {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1
}
function Disable-Localizacao {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 0 -ErrorAction SilentlyContinue
}
function Disable-Dicas {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SoftLandingEnabled" -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0 -ErrorAction SilentlyContinue
}
function Disable-Feedback {
    New-Item -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value 0
}
function Disable-ClipboardHistory {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Value 0 -Force -ErrorAction SilentlyContinue
}
function New-SystemRestorePoint {
    Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "LegacyMods - antes das alteracoes" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Novas funcoes de conforto / rede
# ---------------------------------------------------------------------------
function Disable-StickyKeysPrompts {
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Value "58" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Flags" -Value "122" -Force -ErrorAction SilentlyContinue
}
function Set-FastMenus {
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Force -ErrorAction SilentlyContinue
}
function Disable-Transparencia {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Force -ErrorAction SilentlyContinue
}
function Disable-Notificacoes {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Force -ErrorAction SilentlyContinue
}
function Set-FastDNS {
    try {
        Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } |
            ForEach-Object {
                Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses ("1.1.1.1","1.0.0.1") -ErrorAction SilentlyContinue
            }
    } catch {}
}
function Disable-NetAdapterPowerSaving {
    try {
        Get-NetAdapter -ErrorAction Stop | ForEach-Object {
            Set-NetAdapterPowerManagement -Name $_.Name -AllowComputerToTurnOffDevice Disabled -ErrorAction SilentlyContinue
        }
    } catch {}
}
function Optimize-SSDTrim {
    try {
        $ssdLetters = @()
        try {
            Get-PhysicalDisk -ErrorAction Stop | Where-Object { $_.MediaType -eq 'SSD' } | ForEach-Object {
                $disk = $_
                Get-Partition -DiskNumber ([int]$disk.DeviceId) -ErrorAction SilentlyContinue |
                    Where-Object { $_.DriveLetter } |
                    ForEach-Object { $ssdLetters += $_.DriveLetter }
            }
        } catch { $ssdLetters = @() }

        if ($ssdLetters.Count -gt 0) {
            foreach ($letter in ($ssdLetters | Select-Object -Unique)) {
                Optimize-Volume -DriveLetter $letter -ReTrim -ErrorAction SilentlyContinue
            }
        } else {
            Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | ForEach-Object {
                Optimize-Volume -DriveLetter $_.DriveLetter -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}
function Suspend-WindowsUpdate {
    $startTime  = (Get-Date).ToString("yyyy-MM-ddT00:00:00Z")
    $expiryTime = (Get-Date).AddDays(7).ToString("yyyy-MM-ddT00:00:00Z")
    $path = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    New-Item -Path $path -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $path -Name "PauseUpdatesStartTime" -Value $startTime -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name "PauseUpdatesExpiryTime" -Value $expiryTime -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name "PauseFeatureUpdatesStartTime" -Value $startTime -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name "PauseFeatureUpdatesEndTime" -Value $expiryTime -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name "PauseQualityUpdatesStartTime" -Value $startTime -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name "PauseQualityUpdatesEndTime" -Value $expiryTime -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Instalacao de apps via winget
# ---------------------------------------------------------------------------
function Install-WingetApp {
    param([string]$Id)
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget nao encontrado. Instale o 'App Installer' pela Microsoft Store."
    }
    $proc = Start-Process -FilePath "winget" -ArgumentList @("install","--id",$Id,"-e","--silent","--accept-package-agreements","--accept-source-agreements") -Wait -PassThru -WindowStyle Hidden
    $okCodes = @(0, -1978335189, -1978335135, -1978334963)
    if ($proc.ExitCode -notin $okCodes) {
        throw "winget retornou codigo $($proc.ExitCode)"
    }
}

# ---------------------------------------------------------------------------
# Funcoes avancadas (servicos, rede, registro)
# ---------------------------------------------------------------------------
function Set-ServicesManual {
    $svc = @(
        @{ Name = "CscService";   Type = "Disabled" },
        @{ Name = "DiagTrack";    Type = "Disabled" },
        @{ Name = "MapsBroker";   Type = "Manual"   },
        @{ Name = "StorSvc";      Type = "Manual"   },
        @{ Name = "SharedAccess"; Type = "Disabled" }
    )
    foreach ($s in $svc) {
        Get-Service $s.Name -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
        Set-Service $s.Name -StartupType $s.Type -ErrorAction SilentlyContinue
    }
    try {
        $memKB = (Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1KB
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Value ([int]$memKB) -Force
    } catch {}
}
function Set-VisualEffectsExtreme {
    $props = @{
        "HKCU:\Control Panel\Desktop"                                       = @{ MenuShowDelay = 200 }
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" = @{ ListviewAlphaSelect = 0; ListviewShadow = 0; TaskbarAnimations = 0; TaskbarMn = 0; ShowTaskViewButton = 0 }
        "HKCU:\Software\Microsoft\Windows\DWM"                              = @{ EnableAeroPeek = 0 }
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"            = @{ SearchboxTaskbarMode = 0 }
    }
    foreach ($path in $props.Keys) {
        New-Item -Path $path -Force -ErrorAction SilentlyContinue | Out-Null
        foreach ($name in $props[$path].Keys) {
            Set-ItemProperty -Path $path -Name $name -Value $props[$path][$name] -Force -ErrorAction SilentlyContinue
        }
    }
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value 0 -Force -ErrorAction SilentlyContinue
}
function Disable-StorageSense {
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Force -ErrorAction SilentlyContinue
}
function Disable-DeliveryOptimization {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 -Force -ErrorAction SilentlyContinue
}
function Enable-EndTaskTaskbar {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1 -Force -ErrorAction SilentlyContinue
}
function Disable-WPBT {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "DisableWpbtExecution" -Value 1 -Force -ErrorAction SilentlyContinue
}
function Set-ClockUTC {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1 -Type QWord -Force -ErrorAction SilentlyContinue
}
function Disable-RdpUnsignedWarning {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client" -Name "RedirectionWarningDialogVersion" -Value 1 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Terminal Server Client" -Name "RdpLaunchConsentAccepted" -Value 1 -Force -ErrorAction SilentlyContinue
}
function Clear-ActivityHistory {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0 -Force -ErrorAction SilentlyContinue
}
function Disable-StoreSearchSuggestions {
    $dbPath = "$Env:LocalAppData\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db"
    if (Test-Path $dbPath) { icacls "$dbPath" /deny Everyone:F | Out-Null }
}
function Disable-ConsumerFeatures {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Force -ErrorAction SilentlyContinue
}
function Set-TelemetriaExtendida {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" -Name "HasAccepted" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Input\TIPC" -Name "Enabled" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 1 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0 -Force -ErrorAction SilentlyContinue
    try { Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue } catch {}
    Set-Service -Name wermgr -StartupType Disabled -ErrorAction SilentlyContinue
    [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')
}
function Set-EdgeDebloat {
    $edgePol = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    New-Item -Path $edgePol -Force -ErrorAction SilentlyContinue | Out-Null
    $vals = @{
        PersonalizationReportingEnabled = 0; ShowRecommendationsEnabled = 0; HideFirstRunExperience = 1
        UserFeedbackAllowed = 0; ConfigureDoNotTrack = 1; AlternateErrorPagesEnabled = 0
        EdgeCollectionsEnabled = 0; EdgeShoppingAssistantEnabled = 0; MicrosoftEdgeInsiderPromotionEnabled = 0
        ShowMicrosoftRewards = 0; WebWidgetAllowed = 0; DiagnosticData = 0
        EdgeAssetDeliveryServiceEnabled = 0; WalletDonationEnabled = 0; DefaultBrowserSettingsCampaignEnabled = 0
    }
    foreach ($k in $vals.Keys) { Set-ItemProperty -Path $edgePol -Name $k -Value $vals[$k] -Force -ErrorAction SilentlyContinue }
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "CreateDesktopShortcutDefault" -Value 0 -Force -ErrorAction SilentlyContinue
}
function Set-BraveDebloat {
    $bravePol = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave"
    New-Item -Path $bravePol -Force -ErrorAction SilentlyContinue | Out-Null
    $vals = @{
        BraveRewardsDisabled = 1; BraveWalletDisabled = 1; BraveVPNDisabled = 1; BraveAIChatEnabled = 0
        BraveStatsPingEnabled = 0; BraveNewsDisabled = 1; BraveTalkDisabled = 1; TorDisabled = 1
        BraveP3AEnabled = 0; UrlKeyedAnonymizedDataCollectionEnabled = 0; SafeBrowsingExtendedReportingEnabled = 0
        MetricsReportingEnabled = 0
    }
    foreach ($k in $vals.Keys) { Set-ItemProperty -Path $bravePol -Name $k -Value $vals[$k] -Force -ErrorAction SilentlyContinue }
}
function Disable-WindowsAI {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "SettingsPageVisibility" -Value "hide:aicomponents" -Force -ErrorAction SilentlyContinue
    New-Item -Path "HKLM:\SOFTWARE\Policies\WindowsNotepad" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\WindowsNotepad" -Name "DisableAIFeatures" -Value 1 -Force -ErrorAction SilentlyContinue
    try {
        Get-AppxPackage -AllUsers *Copilot* | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Set-Service -Name WSAIFabricSvc -StartupType Disabled -ErrorAction SilentlyContinue
        Disable-WindowsOptionalFeature -FeatureName Recall -Online -NoRestart -ErrorAction SilentlyContinue | Out-Null
    } catch {}
}
function Remove-WidgetsApp {
    Get-Process *Widget* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-AppxPackage Microsoft.WidgetsPlatformRuntime -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxPackage MicrosoftWindows.Client.WebExperience -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
}
function Remove-HomeAndGallery {
    Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -Force -ErrorAction SilentlyContinue
}
function Remove-XboxGamingComponents {
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Force -ErrorAction SilentlyContinue
    $pkgs = @("Microsoft.XboxIdentityProvider","Microsoft.XboxSpeechToTextOverlay","Microsoft.GamingApp","Microsoft.Xbox.TCUI","Microsoft.XboxGamingOverlay")
    foreach ($p in $pkgs) { Get-AppxPackage -AllUsers $p -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue }
}
function Remove-DebloatApps {
    $pkgs = @(
        "Microsoft.WindowsFeedbackHub","Microsoft.BingNews","Microsoft.BingSearch","Microsoft.BingWeather",
        "Clipchamp.Clipchamp","Microsoft.Todos","Microsoft.PowerAutomateDesktop","Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.WindowsSoundRecorder","Microsoft.MicrosoftStickyNotes","Microsoft.Windows.DevHome","Microsoft.Paint",
        "Microsoft.OutlookForWindows","Microsoft.WindowsAlarms","Microsoft.StartExperiencesApp","Microsoft.GetHelp",
        "Microsoft.ZuneMusic","MicrosoftCorporationII.QuickAssist","MSTeams"
    )
    foreach ($p in $pkgs) { Get-AppxPackage -AllUsers $p -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue }
    $teamsPath = "$Env:LocalAppData\Microsoft\Teams\Update.exe"
    if (Test-Path $teamsPath) {
        Start-Process $teamsPath -ArgumentList "-uninstall" -Wait -ErrorAction SilentlyContinue
        Remove-Item $teamsPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
function Remove-OneDriveApp {
    if (-not $env:OneDrive) { return }
    icacls $env:OneDrive /deny "Administrators:(D,DC)" | Out-Null
    $setup = "C:\Windows\System32\OneDriveSetup.exe"
    if (Test-Path $setup) { Start-Process $setup -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue }
    Stop-Process -Name FileCoAuth, Explorer -Force -ErrorAction SilentlyContinue
    Remove-Item "$Env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    icacls $env:OneDrive /grant "Administrators:(D,DC)" | Out-Null
    Set-Service -Name OneSyncSvc -StartupType Disabled -ErrorAction SilentlyContinue
    Start-Process explorer
}
function Disable-BitLockerSystemDrive {
    try { Disable-BitLocker -MountPoint $Env:SystemDrive -ErrorAction Stop } catch {}
}

# ---------------------------------------------------------------------------
# Funcoes de performance extrema (usadas na aba Avancado e no Modo Legacy)
# ---------------------------------------------------------------------------
function Enable-UltimatePerformance {
    try {
        $output = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
        if ($output -match '([0-9a-fA-F-]{36})') { powercfg -setactive $Matches[1] }
    } catch {}
}
function Disable-PowerThrottling {
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Value 1 -Force -ErrorAction SilentlyContinue
}
function Disable-CoreParking {
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null
    powercfg -setdcvalueindex scheme_current sub_processor CPMINCORES 100 2>$null
    powercfg -setactive scheme_current 2>$null
}
function Disable-FullscreenOptimizationsGlobal {
    New-Item -Path "HKCU:\System\GameConfigStore" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Modo Legacy - deteccao e otimizacao de jogos
# ---------------------------------------------------------------------------
$script:GameList = [ordered]@{
    "Valorant"           = "VALORANT-Win64-Shipping"
    "Counter-Strike 2"   = "cs2"
    "CS:GO"              = "csgo"
    "League of Legends"  = "League of Legends"
    "Fortnite"           = "FortniteClient-Win64-Shipping"
    "GTA V"              = "GTA5"
    "Apex Legends"       = "r5apex"
    "Call of Duty"       = "cod"
    "Rainbow Six Siege"  = "RainbowSix"
    "Dota 2"             = "dota2"
    "PUBG"               = "TslGame"
    "Rocket League"      = "RocketLeague"
    "Minecraft (Java)"   = "javaw"
}

function Find-RunningGame {
    foreach ($entry in $script:GameList.GetEnumerator()) {
        if (Get-Process -Name $entry.Value -ErrorAction SilentlyContinue) { return $entry.Key }
    }
    return $null
}

function Optimize-GameProcess {
    param([string]$DisplayName)
    if (-not $DisplayName -or -not $script:GameList.Contains($DisplayName)) { return $false }
    $procName = $script:GameList[$DisplayName]
    $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if (-not $procs) { return $false }
    foreach ($p in $procs) {
        try { $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High } catch {}
    }
    try {
        $exePath = ($procs | Select-Object -First 1).Path
        if ($exePath) {
            New-Item -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name $exePath -Value "~ DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE" -Force -ErrorAction SilentlyContinue
        }
    } catch {}
    return $true
}

# Tweaks de rede/registro/input que dependem de valores calculados na hora (RAM, interfaces etc.)
function Optimize-Registry {
    Remove-Item "HKCU:\Software\Classes\MuiCache" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" -Name "*" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -ErrorAction SilentlyContinue
}
function Disable-MouseAcceleration {
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Force
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Force
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Force
}
function Set-GameResponsiveness {
    $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty -Path $path -Name "SystemResponsiveness" -Value 0 -Force -ErrorAction SilentlyContinue
    New-Item -Path "$path\Tasks\Games" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "$path\Tasks\Games" -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Force -ErrorAction SilentlyContinue
}
function Disable-NagleAlgorithm {
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue | ForEach-Object {
        Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -Force -ErrorAction SilentlyContinue
    }
}
function Enable-HAGS {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\DirectX\GraphicsSettings" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectX\GraphicsSettings" -Name "HwSchMode" -Value 2 -Force -ErrorAction SilentlyContinue
}
function Set-ForegroundPriority {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Mapa: checkbox -> (descricao, funcao)
# ---------------------------------------------------------------------------
$TweakMap = @{
    chkPowerPlan     = @("Ativando plano de Alto Desempenho", { Enable-HighPerformancePlan })
    chkVisualEffects = @("Ajustando efeitos visuais", { Set-VisualEffectsPerformance })
    chkGameBar       = @("Desativando Game Bar", { Disable-GameBar })
    chkStartupDelay  = @("Removendo atraso de inicializacao", { Remove-StartupDelay })
    chkAnimacoes     = @("Reduzindo animacoes", { Reduce-Animacoes })
    chkNoSleep       = @("Desativando suspensao em energia AC", { Set-NoSleepOnAC })
    chkHibernacao    = @("Desativando hibernacao", { Disable-Hibernacao })
    chkIndexacao     = @("Desativando indexacao", { Disable-Indexacao })
    chkSuperfetch    = @("Desativando SysMain/Superfetch", { Disable-Superfetch })
    chkFastStartup   = @("Desativando Inicializacao Rapida", { Disable-FastStartup })
    chkStickyKeys    = @("Removendo avisos de teclas de aderencia", { Disable-StickyKeysPrompts })
    chkFastMenus     = @("Acelerando menus", { Set-FastMenus })
    chkTransparencia = @("Desativando transparencia", { Disable-Transparencia })
    chkNotificacoes  = @("Desativando notificacoes", { Disable-Notificacoes })
    chkFastDNS         = @("Configurando DNS rapido (Cloudflare)", { Set-FastDNS })
    chkNetAdapterPower = @("Desativando economia de energia da rede", { Disable-NetAdapterPowerSaving })
    chkTemp           = @("Limpando arquivos temporarios", { Clear-TempFiles })
    chkLixeira        = @("Esvaziando lixeira", { Clear-Lixeira })
    chkWinUpdateCache = @("Limpando cache do Windows Update", { Clear-WinUpdateCache })
    chkPrefetch       = @("Limpando Prefetch", { Clear-Prefetch })
    chkDNS            = @("Limpando cache DNS", { Clear-DNSCache })
    chkMiniaturas     = @("Limpando miniaturas", { Clear-Thumbnails })
    chkLogs           = @("Limpando logs de eventos", { Clear-EventLogs })
    chkCrashDumps     = @("Limpando dumps de memoria", { Clear-CrashDumps })
    chkWER            = @("Limpando relatorios de erro", { Clear-WER })
    chkJumplists      = @("Limpando jump lists", { Clear-Jumplists })
    chkFontCache      = @("Limpando cache de fontes", { Clear-FontCache })
    chkTelemetria     = @("Desativando telemetria", { Disable-Telemetria })
    chkCortana        = @("Desativando Cortana", { Disable-Cortana })
    chkAdsID          = @("Desativando ID de publicidade", { Disable-AdsID })
    chkBackgroundApps = @("Desativando apps em segundo plano", { Disable-BackgroundApps })
    chkLocalizacao    = @("Desativando localizacao", { Disable-Localizacao })
    chkDicas          = @("Desativando dicas do Windows", { Disable-Dicas })
    chkFeedback       = @("Desativando feedback", { Disable-Feedback })
    chkClipboardHistory = @("Desativando historico da area de transferencia", { Disable-ClipboardHistory })
    chkServicesManual     = @("Otimizando servicos do sistema", { Set-ServicesManual })
    chkVisualExtra        = @("Aplicando efeitos visuais - modo extremo", { Set-VisualEffectsExtreme })
    chkStorageSense       = @("Desativando Storage Sense", { Disable-StorageSense })
    chkDeliveryOpt        = @("Desativando Delivery Optimization", { Disable-DeliveryOptimization })
    chkEndTaskTaskbar     = @("Habilitando Finalizar Tarefa na taskbar", { Enable-EndTaskTaskbar })
    chkWPBT               = @("Desativando WPBT", { Disable-WPBT })
    chkUTC                = @("Definindo relogio para UTC", { Set-ClockUTC })
    chkRdpWarning         = @("Removendo aviso de RDP nao assinado", { Disable-RdpUnsignedWarning })
    chkRegistryOptimize   = @("Otimizando registro", { Optimize-Registry })
    chkTrimSSD            = @("Otimizando/TRIM em SSDs", { Optimize-SSDTrim })
    chkPauseWU            = @("Pausando Windows Update por 7 dias", { Suspend-WindowsUpdate })
    chkMouseAccel          = @("Removendo aceleracao do mouse", { Disable-MouseAcceleration })
    chkGameResponsiveness  = @("Priorizando resposta em jogos", { Set-GameResponsiveness })
    chkNagle                = @("Desativando algoritmo de Nagle", { Disable-NagleAlgorithm })
    chkHAGS                 = @("Ativando GPU Scheduling por hardware", { Enable-HAGS })
    chkForegroundPriority   = @("Priorizando app em foco", { Set-ForegroundPriority })
    chkUltimatePerf       = @("Ativando plano Ultimate Performance", { Enable-UltimatePerformance })
    chkPowerThrottling    = @("Desativando Power Throttling", { Disable-PowerThrottling })
    chkCoreParking        = @("Desativando Core Parking", { Disable-CoreParking })
    chkFSEGlobal          = @("Desativando Fullscreen Optimizations global", { Disable-FullscreenOptimizationsGlobal })
    chkActivityHistory    = @("Apagando historico de atividades", { Clear-ActivityHistory })
    chkStoreSearch        = @("Bloqueando sugestoes da Store", { Disable-StoreSearchSuggestions })
    chkConsumerFeatures   = @("Desativando Consumer Features", { Disable-ConsumerFeatures })
    chkTelemetriaExtra    = @("Aplicando telemetria estendida", { Set-TelemetriaExtendida })
    chkEdgeDebloat        = @("Aplicando debloat do Edge", { Set-EdgeDebloat })
    chkBraveDebloat       = @("Aplicando debloat do Brave", { Set-BraveDebloat })
    chkWindowsAI          = @("Desativando Windows AI/Copilot", { Disable-WindowsAI })
    chkRemoveWidgets      = @("Removendo Widgets", { Remove-WidgetsApp })
    chkRemoveHomeGallery  = @("Removendo Home/Galeria do Explorer", { Remove-HomeAndGallery })
    chkXboxRemoval        = @("Removendo componentes Xbox/Gaming", { Remove-XboxGamingComponents })
    chkDebloatApps        = @("Removendo apps pre-instalados", { Remove-DebloatApps })
    chkRemoveOneDrive     = @("Removendo OneDrive", { Remove-OneDriveApp })
    chkDisableBitLocker   = @("Desativando BitLocker", { Disable-BitLockerSystemDrive })
}

# Catalogo de apps instalaveis via winget (aba Instalar Apps)
$AppMap = [ordered]@{
    chkApp_Chrome     = @("Instalando Google Chrome", { Install-WingetApp "Google.Chrome" })
    chkApp_Firefox    = @("Instalando Mozilla Firefox", { Install-WingetApp "Mozilla.Firefox" })
    chkApp_Brave      = @("Instalando Brave Browser", { Install-WingetApp "Brave.Brave" })
    chkApp_Discord    = @("Instalando Discord", { Install-WingetApp "Discord.Discord" })
    chkApp_Telegram   = @("Instalando Telegram Desktop", { Install-WingetApp "Telegram.TelegramDesktop" })
    chkApp_WhatsApp   = @("Instalando WhatsApp", { Install-WingetApp "WhatsApp.WhatsApp" })
    chkApp_Zoom       = @("Instalando Zoom", { Install-WingetApp "Zoom.Zoom" })
    chkApp_7zip       = @("Instalando 7-Zip", { Install-WingetApp "7zip.7zip" })
    chkApp_Everything = @("Instalando Everything", { Install-WingetApp "voidtools.Everything" })
    chkApp_PowerToys  = @("Instalando Microsoft PowerToys", { Install-WingetApp "Microsoft.PowerToys" })
    chkApp_NotepadPlus = @("Instalando Notepad++", { Install-WingetApp "Notepad++.Notepad++" })
    chkApp_Revo       = @("Instalando Revo Uninstaller", { Install-WingetApp "RevoUninstaller.RevoUninstaller" })
    chkApp_VLC        = @("Instalando VLC Media Player", { Install-WingetApp "VideoLAN.VLC" })
    chkApp_Spotify    = @("Instalando Spotify", { Install-WingetApp "Spotify.Spotify" })
    chkApp_OBS        = @("Instalando OBS Studio", { Install-WingetApp "OBSProject.OBSStudio" })
    chkApp_KLite      = @("Instalando K-Lite Codec Pack", { Install-WingetApp "CodecGuide.K-LiteCodecPack.Standard" })
    chkApp_VSCode     = @("Instalando Visual Studio Code", { Install-WingetApp "Microsoft.VisualStudioCode" })
    chkApp_Git        = @("Instalando Git", { Install-WingetApp "Git.Git" })
    chkApp_Python     = @("Instalando Python 3", { Install-WingetApp "Python.Python.3.12" })
    chkApp_NodeJS     = @("Instalando Node.js LTS", { Install-WingetApp "OpenJS.NodeJS.LTS" })
    chkApp_Terminal   = @("Instalando Windows Terminal", { Install-WingetApp "Microsoft.WindowsTerminal" })
    chkApp_Steam      = @("Instalando Steam", { Install-WingetApp "Valve.Steam" })
    chkApp_Epic       = @("Instalando Epic Games Launcher", { Install-WingetApp "EpicGames.EpicGamesLauncher" })
    chkApp_Battlenet  = @("Instalando Battle.net", { Install-WingetApp "Blizzard.BattleNet" })
}
foreach ($k in $AppMap.Keys) { $TweakMap[$k] = $AppMap[$k] }

$script:statusTimer.Add_Tick({ Update-StatusMetrics }) 2>$null | Out-Null

# ---------------------------------------------------------------------------
# Eventos - Inicio
# ---------------------------------------------------------------------------
$ctrl.btnRestorePointHome.Add_Click({
    $ctrl.txtInicioStatus.Text = "Criando ponto de restauracao..."
    New-SystemRestorePoint
    $ctrl.txtInicioStatus.Text = "Ponto de restauracao criado (se o sistema permitir)."
})

$ctrl.btnQuickApply.Add_Click({
    $ctrl.txtInicioStatus.Text = "Aplicando otimizacoes essenciais..."
    $keys = @('chkPowerPlan','chkVisualEffects','chkStartupDelay','chkAnimacoes','chkTemp','chkLixeira','chkPrefetch','chkDNS','chkMiniaturas')
    foreach ($k in $keys) {
        if ($TweakMap.ContainsKey($k)) { try { & $TweakMap[$k][1] } catch {} }
    }
    $ctrl.txtInicioStatus.Text = "Otimizacoes essenciais aplicadas."
})

# ---------------------------------------------------------------------------
# Eventos - paginas de tweaks / apps (footer)
# ---------------------------------------------------------------------------
$ctrl.btnSelectAll.Add_Click({ foreach ($key in $TweakMap.Keys) { $ctrl[$key].IsChecked = $true } })
$ctrl.btnClear.Add_Click({ foreach ($key in $TweakMap.Keys) { $ctrl[$key].IsChecked = $false } })

$ctrl.btnApply.Add_Click({
    $selecionados = $TweakMap.Keys | Where-Object { $ctrl[$_].IsChecked -eq $true }
    if ($selecionados.Count -eq 0) { Show-Status "Nenhuma opcao selecionada."; return }

    $ctrl.btnApply.IsEnabled = $false
    $total = $selecionados.Count
    $i = 0

    foreach ($key in $selecionados) {
        $i++
        $desc = $TweakMap[$key][0]
        $fn   = $TweakMap[$key][1]

        Show-Status "($i/$total) $desc..."
        $ctrl.progBar.Value = [int](($i / $total) * 100)
        $window.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)

        try { & $fn } catch { Show-Status "ERRO em '$desc': $($_.Exception.Message)"; Start-Sleep -Milliseconds 600 }
    }

    Show-Status "Concluido! $total item(ns) aplicado(s)/instalado(s). Reinicie o PC para efeito completo."
    $ctrl.btnApply.IsEnabled = $true
})

# ---------------------------------------------------------------------------
# Eventos - Modo Legacy
# ---------------------------------------------------------------------------
foreach ($name in $script:GameList.Keys) { $ctrl.cmbGames.Items.Add($name) | Out-Null }

$ctrl.btnDetectGame.Add_Click({
    $found = Find-RunningGame
    if ($found) {
        $ctrl.txtDetectedGame.Text = "Detectado: $found"
        $ctrl.cmbGames.SelectedItem = $found
    } else {
        $ctrl.txtDetectedGame.Text = "Nenhum jogo conhecido em execucao"
    }
})

$ctrl.btnApplyGameOnly.Add_Click({
    $game = $ctrl.cmbGames.SelectedItem
    if (-not $game) { $game = Find-RunningGame }
    if (-not $game) { Show-Status "Nenhum jogo selecionado ou detectado." $ctrl.txtLegacyStatus; return }

    Show-Status "Otimizando $game..." $ctrl.txtLegacyStatus
    if (Optimize-GameProcess $game) { Show-Status "$game otimizado." $ctrl.txtLegacyStatus }
    else { Show-Status "$game nao esta em execucao no momento." $ctrl.txtLegacyStatus }
})

$ctrl.btnApplyLegacyFull.Add_Click({
    $ctrl.btnApplyLegacyFull.IsEnabled = $false

    $steps = New-Object System.Collections.ArrayList
    foreach ($k in $TweakMap.Keys) {
        if ($AppMap.Contains($k)) { continue }
        [void]$steps.Add(@($TweakMap[$k][0], $TweakMap[$k][1]))
    }
    [void]$steps.Add(@("Ativando Ultimate Performance", { Enable-UltimatePerformance }))
    [void]$steps.Add(@("Desativando Power Throttling", { Disable-PowerThrottling }))
    [void]$steps.Add(@("Desativando Core Parking", { Disable-CoreParking }))
    [void]$steps.Add(@("Desativando Fullscreen Optimizations", { Disable-FullscreenOptimizationsGlobal }))

    $total = $steps.Count
    $i = 0
    foreach ($step in $steps) {
        $i++
        Show-Status "($i/$total) $($step[0])..." $ctrl.txtLegacyStatus
        $ctrl.progLegacyBar.Value = [int](($i / $total) * 100)
        $window.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
        try { & $step[1] } catch { Show-Status "ERRO em $($step[0]): $($_.Exception.Message)" $ctrl.txtLegacyStatus }
    }

    $game = $ctrl.cmbGames.SelectedItem
    if (-not $game) { $game = Find-RunningGame }
    if ($game) {
        Show-Status "Otimizando $game..." $ctrl.txtLegacyStatus
        if (Optimize-GameProcess $game) { Show-Status "$game priorizado." $ctrl.txtLegacyStatus }
        else { Show-Status "$game nao esta em execucao." $ctrl.txtLegacyStatus }
    } else {
        Show-Status "Nenhum jogo detectado - apenas otimizacoes do sistema aplicadas." $ctrl.txtLegacyStatus
    }

    Show-Status "Modo Legacy concluido. Reinicie o PC para efeito completo." $ctrl.txtLegacyStatus
    $ctrl.btnApplyLegacyFull.IsEnabled = $true
})

$window.Add_Closing({ $script:statusTimer.Stop() })

$window.ShowDialog() | Out-Null
