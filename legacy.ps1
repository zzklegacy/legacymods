#Requires -Version 5.1
<#
    LegacyMods - Painel de Otimizacao para Windows (v2.1 - Dashboard Compacto)
    Uso local:    powershell -ExecutionPolicy Bypass -File .\LegacyMods.ps1
    Uso remoto:   irm https://SEU-LINK/LegacyMods.ps1 | iex
#>

# ------------------------------------------------------------
# 0. Checagem de administrador
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# 1. XAML - Interface (Dashboard com sidebar, layout compacto tipo painel tecnico)
# ------------------------------------------------------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="LegacyMods" Height="740" Width="1020"
        WindowStartupLocation="CenterScreen"
        Background="#0B0B0D" Foreground="White"
        FontFamily="Segoe UI">

    <Window.Resources>

        <SolidColorBrush x:Key="Purple" Color="#9B5DE5"/>
        <SolidColorBrush x:Key="PurpleSoft" Color="#2A1F3D"/>
        <SolidColorBrush x:Key="Sidebar" Color="#111114"/>
        <SolidColorBrush x:Key="Card" Color="#17171B"/>
        <SolidColorBrush x:Key="CardHover" Color="#1F1F25"/>
        <SolidColorBrush x:Key="Border0" Color="#2A2A30"/>
        <SolidColorBrush x:Key="TextMuted" Color="#8A8A93"/>
        <SolidColorBrush x:Key="Console" Color="#0E0E10"/>
        <SolidColorBrush x:Key="ConsoleText" Color="#C9C9D1"/>

        <!-- Scrollbar minimalista -->
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="8"/>
            <Setter Property="Background" Value="Transparent"/>
        </Style>

        <!-- Botao padrao (roxo) -->
        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource Purple}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bg" Property="Opacity" Value="0.88"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bg" Property="Opacity" Value="0.4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Botao secundario (contorno) -->
        <Style x:Key="GhostButton" TargetType="Button" BasedOn="{StaticResource PrimaryButton}">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bg" Background="Transparent" BorderBrush="{StaticResource Border0}" BorderThickness="1" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bg" Property="BorderBrush" Value="{StaticResource Purple}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Item de navegacao lateral (RadioButton) -->
        <Style x:Key="NavItem" TargetType="RadioButton">
            <Setter Property="Foreground" Value="{StaticResource TextMuted}"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Height" Value="40"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RadioButton">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="4"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Border x:Name="ind" Grid.Column="0" Background="Transparent" CornerRadius="0,3,3,0"/>
                            <Border x:Name="bg" Grid.Column="1" Background="Transparent" CornerRadius="0,6,6,0" Margin="0,2,10,2">
                                <TextBlock Text="{TemplateBinding Content}" VerticalAlignment="Center" Margin="16,0,0,0"
                                           FontFamily="Consolas" Foreground="{TemplateBinding Foreground}" FontSize="{TemplateBinding FontSize}"/>
                            </Border>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="ind" Property="Background" Value="{StaticResource Purple}"/>
                                <Setter TargetName="bg" Property="Background" Value="{StaticResource PurpleSoft}"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Checkbox estilo "toggle quadrado" -->
        <Style x:Key="ModernCheck" TargetType="CheckBox">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Border x:Name="box" Width="19" Height="19" CornerRadius="5" BorderThickness="1.5" BorderBrush="#3A3A42" Background="Transparent">
                            <Path x:Name="check" Data="M2,7 L6,11 L14,2" Stroke="White" StrokeThickness="2.1"
                                  StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round"
                                  Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="box" Property="Background" Value="{StaticResource Purple}"/>
                                <Setter TargetName="box" Property="BorderBrush" Value="{StaticResource Purple}"/>
                                <Setter TargetName="check" Property="Visibility" Value="Visible"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <SolidColorBrush x:Key="Warning" Color="#E5A339"/>
        <SolidColorBrush x:Key="WarningSoft" Color="#3A2E17"/>

        <!-- Linha de opcao compacta (checkbox + titulo, descricao vai em tooltip) -->
        <Style x:Key="OptionRow" TargetType="Border">
            <Setter Property="Background" Value="{StaticResource Card}"/>
            <Setter Property="CornerRadius" Value="8"/>
            <Setter Property="Padding" Value="12,10"/>
            <Setter Property="Margin" Value="0,0,8,8"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border0}"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>

        <!-- Linha de opcao de risco (fundo aquecido, borda ambar) -->
        <Style x:Key="OptionRowWarning" TargetType="Border" BasedOn="{StaticResource OptionRow}">
            <Setter Property="Background" Value="{StaticResource WarningSoft}"/>
            <Setter Property="BorderBrush" Value="#4A3A20"/>
        </Style>

        <!-- Cabecalho de secao/pagina -->
        <Style x:Key="PageTitle" TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Consolas"/>
            <Setter Property="FontSize" Value="20"/>
            <Setter Property="FontWeight" Value="Bold"/>
        </Style>

        <!-- Cabecalho de categoria dentro da pagina -->
        <Style x:Key="CategoryHeader" TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Consolas"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="{StaticResource Purple}"/>
            <Setter Property="Margin" Value="2,14,0,8"/>
        </Style>

        <!-- Cabecalho de categoria de risco (ambar) -->
        <Style x:Key="CategoryHeaderWarning" TargetType="TextBlock" BasedOn="{StaticResource CategoryHeader}">
            <Setter Property="Foreground" Value="{StaticResource Warning}"/>
        </Style>

        <Style TargetType="ProgressBar">
            <Setter Property="Background" Value="#232329"/>
            <Setter Property="Foreground" Value="{StaticResource Purple}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Height" Value="7"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ProgressBar">
                        <Border Background="{TemplateBinding Background}" CornerRadius="4">
                            <Grid ClipToBounds="True" HorizontalAlignment="Left">
                                <Border x:Name="PART_Track" CornerRadius="4"/>
                                <Border x:Name="PART_Indicator" Background="{TemplateBinding Foreground}" CornerRadius="4" HorizontalAlignment="Left"/>
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

        <!-- ===================== SIDEBAR ===================== -->
        <Border Grid.Column="0" Background="{StaticResource Sidebar}">
            <DockPanel LastChildFill="False">
                <StackPanel DockPanel.Dock="Top" Margin="20,24,0,26">
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="Legacy" FontFamily="Consolas" FontSize="19" FontWeight="Bold" Foreground="White"/>
                        <TextBlock Text="Mods" FontFamily="Consolas" FontSize="19" FontWeight="Bold" Foreground="{StaticResource Purple}"/>
                    </StackPanel>
                    <TextBlock Text="v2.1 // painel tecnico" FontFamily="Consolas" FontSize="10" Foreground="{StaticResource TextMuted}" Margin="0,3,0,0"/>
                </StackPanel>

                <StackPanel DockPanel.Dock="Top">
                    <RadioButton Name="navOtimizacao" Content="OTIMIZACAO" GroupName="Nav" Style="{StaticResource NavItem}" IsChecked="True"/>
                    <RadioButton Name="navLimpeza" Content="LIMPEZA" GroupName="Nav" Style="{StaticResource NavItem}"/>
                    <RadioButton Name="navPrivacidade" Content="PRIVACIDADE" GroupName="Nav" Style="{StaticResource NavItem}"/>
                    <RadioButton Name="navAvancado" Content="AVANCADO" GroupName="Nav" Style="{StaticResource NavItem}"/>
                    <RadioButton Name="navStatus" Content="STATUS" GroupName="Nav" Style="{StaticResource NavItem}"/>
                    <RadioButton Name="navSobre" Content="SOBRE" GroupName="Nav" Style="{StaticResource NavItem}"/>
                </StackPanel>

                <TextBlock DockPanel.Dock="Bottom" Text="build 2024" FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="10" Margin="20,0,0,18"/>
            </DockPanel>
        </Border>

        <!-- ===================== CONTEUDO ===================== -->
        <Grid Grid.Column="1">
            <Grid.RowDefinitions>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- Area de paginas -->
            <Grid Grid.Row="0" Margin="26,24,26,8">

                <!-- PAGINA: OTIMIZACAO -->
                <StackPanel Name="pageOtimizacao">
                    <TextBlock Text="OTIMIZACAO" Style="{StaticResource PageTitle}"/>
                    <TextBlock Text="Ajustes de desempenho e sistema — passe o mouse sobre um item para detalhes" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,0"/>
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Height="452">
                        <StackPanel>
                            <TextBlock Text="DESEMPENHO" Style="{StaticResource CategoryHeader}" Margin="2,4,0,8"/>
                            <UniformGrid Columns="2">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Ativa o plano de energia de alto desempenho do Windows">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkPowerPlan" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Plano de Alto Desempenho" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Reduz efeitos graficos priorizando velocidade">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkVisualEffects" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Efeitos visuais p/ desempenho" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desliga Game Bar e Game DVR (pode reduzir consumo em jogos)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkGameBar" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Xbox Game Bar" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Apps de startup abrem imediatamente ao logar">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkStartupDelay" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover atraso de inicializacao" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Deixa janelas e menus com transicoes mais rapidas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkAnimacoes" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Reduzir animacoes" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="SISTEMA / ARMAZENAMENTO" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="2">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove o arquivo hiberfil.sys e libera espaco em disco">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkHibernacao" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar hibernacao" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Reduz uso de disco em segundo plano (busca fica mais lenta)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkIndexacao" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar indexacao de busca" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Recomendado para SSDs; reduz uso de disco em segundo plano">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkSuperfetch" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar SysMain/Superfetch" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>
                        </StackPanel>
                    </ScrollViewer>
                </StackPanel>

                <!-- PAGINA: LIMPEZA -->
                <StackPanel Name="pageLimpeza" Visibility="Collapsed">
                    <TextBlock Text="LIMPEZA" Style="{StaticResource PageTitle}"/>
                    <TextBlock Text="Liberar espaco e remover arquivos desnecessarios" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,0"/>
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Height="452">
                        <StackPanel>
                            <TextBlock Text="ARQUIVOS E CACHE" Style="{StaticResource CategoryHeader}" Margin="2,4,0,8"/>
                            <UniformGrid Columns="2">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Limpa %TEMP% e C:\Windows\Temp">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkTemp" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Arquivos temporarios" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove definitivamente os arquivos da lixeira">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkLixeira" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Esvaziar Lixeira" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Limpa a pasta SoftwareDistribution\Download">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkWinUpdateCache" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Cache do Windows Update" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove arquivos de pre-carregamento do Windows">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkPrefetch" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Pasta Prefetch" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Executa ipconfig /flushdns">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkDNS" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Cache DNS" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Reinicia o Explorer e limpa thumbcache">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkMiniaturas" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Cache de miniaturas" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Limpa os registros do Visualizador de Eventos">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkLogs" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Logs de eventos" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>
                        </StackPanel>
                    </ScrollViewer>
                </StackPanel>

                <!-- PAGINA: PRIVACIDADE -->
                <StackPanel Name="pagePrivacidade" Visibility="Collapsed">
                    <TextBlock Text="PRIVACIDADE" Style="{StaticResource PageTitle}"/>
                    <TextBlock Text="Telemetria, rastreamento e coleta de dados" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,0"/>
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Height="452">
                        <StackPanel>
                            <TextBlock Text="COLETA DE DADOS" Style="{StaticResource CategoryHeader}" Margin="2,4,0,8"/>
                            <UniformGrid Columns="2">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa o servico DiagTrack e a coleta de dados">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkTelemetria" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Telemetria do Windows" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa a assistente virtual do Windows">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkCortana" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Cortana" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa anuncios personalizados entre apps">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkAdsID" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="ID de publicidade" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Impede que apps rodem sem estarem abertos">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkBackgroundApps" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Apps em segundo plano" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa o servico de geolocalizacao do sistema">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkLocalizacao" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Rastreamento de localizacao" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove sugestoes e anuncios no menu Iniciar">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkDicas" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Dicas e sugestoes" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Para de pedir feedback periodicamente">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkFeedback" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Solicitacoes de feedback" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>
                        </StackPanel>
                    </ScrollViewer>
                </StackPanel>

                <!-- PAGINA: AVANCADO -->
                <StackPanel Name="pageAvancado" Visibility="Collapsed">
                    <TextBlock Text="AVANCADO" Style="{StaticResource PageTitle}"/>
                    <TextBlock Text="Ajustes profundos de sistema, rede, GPU e registro — para quem sabe o que esta fazendo" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,0"/>
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Height="452">
                        <StackPanel>
                            <TextBlock Text="SISTEMA E DESEMPENHO" Style="{StaticResource CategoryHeader}" Margin="2,4,0,8"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Ajusta servicos para Manual/Desabilitado e recalcula o SvcHostSplitThresholdInKB conforme a RAM instalada, reduzindo processos svchost.exe">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkServicesManual" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Otimizar servicos" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Ajusta delay de menu, sombra de lista, animacoes de taskbar e outros efeitos para o modo mais leve possivel">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkVisualExtra" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Efeitos visuais - extremo" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Storage Sense apaga arquivos temporarios automaticamente; aqui ele e desativado">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkStorageSense" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Storage Sense" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Impede o Windows de usar sua banda para enviar updates a outros PCs (Delivery Optimization)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkDeliveryOpt" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Delivery Optimization" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Habilita a opcao 'Finalizar Tarefa' ao clicar com botao direito num app na barra de tarefas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkEndTaskTaskbar" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Finalizar tarefa pela taskbar" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Se ativado, o WPBT permite que o fabricante execute programas no boot sem consentimento; aqui e desabilitado por seguranca">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkWPBT" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar WPBT" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Util em dual boot com Linux; corrige a sincronizacao de hora entre os sistemas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkUTC" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Relogio em UTC" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove avisos ao abrir arquivos .rdp nao assinados (introduzidos em updates recentes do Windows)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkRdpWarning" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Sem aviso de RDP" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Limpeza segura de registro: cache MUI, lista de documentos recentes (RecentDocs) e historico da caixa Executar (RunMRU). Nao mexe em programas instalados">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkRegistryOptimize" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Otimizar registro" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="REDE E INPUT LAG" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Zera a aceleracao do ponteiro (MouseSpeed/MouseThreshold). Movimento do mouse fica 1 para 1, sem curva do Windows — reduz sensacao de input lag">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkMouseAccel" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover aceleracao do mouse" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Zera o SystemResponsiveness e maximiza o NetworkThrottlingIndex, priorizando tarefas multimidia/jogos sobre tarefas em segundo plano">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkGameResponsiveness" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Priorizar resposta em jogos" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa o algoritmo de Nagle (TcpAckFrequency/TCPNoDelay) em todas as interfaces de rede, reduzindo latencia em jogos online e apps sensiveis a ping">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkNagle" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar algoritmo de Nagle" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Ativa o GPU Hardware Scheduling (HAGS), deixando a propria GPU gerenciar a fila de quadros — pode reduzir input lag em placas compativeis">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkHAGS" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="GPU Scheduling por hardware" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Ajusta o Win32PrioritySeparation para dar mais fatias de CPU ao aplicativo em primeiro plano (janela ativa), melhorando a responsividade percebida">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkForegroundPriority" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Priorizar app em foco" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="PRIVACIDADE E TELEMETRIA EXTRA" Style="{StaticResource CategoryHeader}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRow}" ToolTip="Apaga historico de documentos recentes, area de transferencia e historico de execucao (Activity Feed)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkActivityHistory" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Apagar historico de atividades" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Bloqueia recomendacoes de apps da Microsoft Store ao buscar no menu Iniciar (via icacls no store.db)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkStoreSearch" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Bloquear sugestoes da Store" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Impede instalacao automatica de jogos/apps/links promovidos pela Microsoft Store">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkConsumerFeatures" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Consumer Features" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Alem da telemetria basica: desativa envio de amostras do Defender, servico wermgr, telemetria do PowerShell 7 e mais chaves de coleta">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkTelemetriaExtra" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Telemetria - modo estendido" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa varias opcoes de telemetria, popups e sugestoes especificas do navegador Microsoft Edge">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkEdgeDebloat" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Debloat do Microsoft Edge" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Desativa Brave Rewards, Leo AI, carteira cripto, VPN e telemetria do navegador Brave (nao tem efeito se o Brave nao estiver instalado)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkBraveDebloat" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Debloat do navegador Brave" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRow}" ToolTip="Remove ou desativa recursos e pacotes de IA do Windows (Copilot, Recall, etc)">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkWindowsAI" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar Windows AI / Copilot" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>

                            <TextBlock Text="⚠ REMOVER COMPONENTES — RISCO" Style="{StaticResource CategoryHeaderWarning}"/>
                            <UniformGrid Columns="3">
                                <Border Style="{StaticResource OptionRowWarning}" ToolTip="Remove os widgets no canto inferior esquerdo da barra de tarefas">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkRemoveWidgets" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover Widgets" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRowWarning}" ToolTip="Remove Home e Galeria do Explorer e define 'Este Computador' como pagina padrao">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkRemoveHomeGallery" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover Home/Galeria" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRowWarning}" ToolTip="Remove servicos do Xbox, o app Xbox, Game Bar e componentes de autenticacao relacionados">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkXboxRemoval" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover Xbox/Gaming" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRowWarning}" ToolTip="Remove apps pre-instalados indesejados: Feedback Hub, Bing News/Weather, Clipchamp, Solitaire, Teams e outros">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkDebloatApps" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover apps pre-instalados" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRowWarning}" ToolTip="ATENCAO: usa o desinstalador nativo do OneDrive e limpa pastas residuais. Seus arquivos locais no OneDrive nao sao apagados, mas a sincronizacao para">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkRemoveOneDrive" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Remover OneDrive" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                                <Border Style="{StaticResource OptionRowWarning}" ToolTip="ATENCAO: desativa a criptografia BitLocker da unidade do sistema. So use se souber o que esta fazendo">
                                    <StackPanel Orientation="Horizontal">
                                        <CheckBox Name="chkDisableBitLocker" Style="{StaticResource ModernCheck}" VerticalAlignment="Center"/>
                                        <TextBlock Text="Desativar BitLocker" FontSize="12" FontWeight="SemiBold" Margin="12,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>
                        </StackPanel>
                    </ScrollViewer>
                </StackPanel>

                <!-- PAGINA: STATUS -->
                <StackPanel Name="pageStatus" Visibility="Collapsed">
                    <TextBlock Text="STATUS DO SISTEMA" Style="{StaticResource PageTitle}"/>
                    <TextBlock Text="Uso de recursos em tempo real" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,16"/>

                    <UniformGrid Columns="2" Rows="2">
                        <!-- CPU -->
                        <Border Style="{StaticResource OptionRow}" Margin="0,0,8,8" Padding="16">
                            <StackPanel>
                                <Grid>
                                    <TextBlock Text="CPU" FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="12"/>
                                    <TextBlock Name="txtCpuPercent" Text="--%" FontFamily="Consolas" FontSize="12" FontWeight="Bold" HorizontalAlignment="Right" Foreground="{StaticResource Purple}"/>
                                </Grid>
                                <ProgressBar Name="barCpu" Value="0" Margin="0,9,0,7"/>
                                <TextBlock Name="txtCpuName" Text="Carregando..." Foreground="{StaticResource TextMuted}" FontSize="10" TextWrapping="Wrap"/>
                            </StackPanel>
                        </Border>
                        <!-- RAM -->
                        <Border Style="{StaticResource OptionRow}" Margin="0,0,0,8" Padding="16">
                            <StackPanel>
                                <Grid>
                                    <TextBlock Text="MEMORIA RAM" FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="12"/>
                                    <TextBlock Name="txtRamPercent" Text="--%" FontFamily="Consolas" FontSize="12" FontWeight="Bold" HorizontalAlignment="Right" Foreground="{StaticResource Purple}"/>
                                </Grid>
                                <ProgressBar Name="barRam" Value="0" Margin="0,9,0,7"/>
                                <TextBlock Name="txtRamDetail" Text="Carregando..." Foreground="{StaticResource TextMuted}" FontSize="10"/>
                            </StackPanel>
                        </Border>
                        <!-- DISCO -->
                        <Border Style="{StaticResource OptionRow}" Margin="0,0,8,0" Padding="16">
                            <StackPanel>
                                <Grid>
                                    <TextBlock Text="DISCO (C:)" FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="12"/>
                                    <TextBlock Name="txtDiskPercent" Text="--%" FontFamily="Consolas" FontSize="12" FontWeight="Bold" HorizontalAlignment="Right" Foreground="{StaticResource Purple}"/>
                                </Grid>
                                <ProgressBar Name="barDisk" Value="0" Margin="0,9,0,7"/>
                                <TextBlock Name="txtDiskDetail" Text="Carregando..." Foreground="{StaticResource TextMuted}" FontSize="10"/>
                            </StackPanel>
                        </Border>
                        <!-- GPU -->
                        <Border Style="{StaticResource OptionRow}" Margin="0,0,0,0" Padding="16">
                            <StackPanel>
                                <Grid>
                                    <TextBlock Text="GPU" FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="12"/>
                                    <TextBlock Name="txtGpuPercent" Text="--%" FontFamily="Consolas" FontSize="12" FontWeight="Bold" HorizontalAlignment="Right" Foreground="{StaticResource Purple}"/>
                                </Grid>
                                <ProgressBar Name="barGpu" Value="0" Margin="0,9,0,7"/>
                                <TextBlock Name="txtGpuName" Text="Carregando..." Foreground="{StaticResource TextMuted}" FontSize="10" TextWrapping="Wrap"/>
                            </StackPanel>
                        </Border>
                    </UniformGrid>

                    <Border Style="{StaticResource OptionRow}" Margin="0,4,0,0" Padding="16">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="TEMPO LIGADO: " FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="11"/>
                            <TextBlock Name="txtUptime" Text="--" FontFamily="Consolas" FontSize="11" FontWeight="SemiBold"/>
                            <TextBlock Text="//  atualiza a cada 2s" FontFamily="Consolas" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="10,0,0,0"/>
                        </StackPanel>
                    </Border>
                </StackPanel>

                <!-- PAGINA: SOBRE -->
                <StackPanel Name="pageSobre" Visibility="Collapsed">
                    <TextBlock Text="SOBRE" Style="{StaticResource PageTitle}"/>
                    <TextBlock Text="Informacoes do painel" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,3,0,18"/>
                    <Border Style="{StaticResource OptionRow}" Padding="20" Margin="0">
                        <StackPanel>
                            <TextBlock Text="LegacyMods" FontFamily="Consolas" FontSize="17" FontWeight="Bold" Foreground="{StaticResource Purple}"/>
                            <TextBlock Margin="0,10,0,0" Foreground="#CCCCCC" FontSize="12" TextWrapping="Wrap"
                                       Text="Painel de otimizacao, limpeza e privacidade para Windows. Selecione as opcoes desejadas e clique em 'Aplicar Selecionados'. Recomenda-se criar um ponto de restauracao antes de aplicar mudancas em massa."/>
                            <Button Name="btnRestorePoint" Content="Criar Ponto de Restauracao" Style="{StaticResource GhostButton}" Width="230" HorizontalAlignment="Left" Margin="0,16,0,0"/>
                        </StackPanel>
                    </Border>
                </StackPanel>

            </Grid>

            <!-- ===================== RODAPE ===================== -->
            <Border Grid.Row="1" Name="footerBar" Background="{StaticResource Card}" Margin="26,0,26,18" CornerRadius="8" Padding="16,12" BorderBrush="{StaticResource Border0}" BorderThickness="1">
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

                    <!-- Console de log estilo terminal -->
                    <Border Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="4" Background="{StaticResource Console}" CornerRadius="6" Padding="10,6" Margin="0,0,0,10" BorderBrush="{StaticResource Border0}" BorderThickness="1">
                        <ScrollViewer Name="logScroll" VerticalScrollBarVisibility="Auto" Height="76">
                            <TextBox Name="txtLog" FontFamily="Consolas" FontSize="11" Foreground="{StaticResource ConsoleText}" Background="Transparent"
                                     BorderThickness="0" IsReadOnly="True" TextWrapping="Wrap" IsUndoEnabled="False"
                                     Text="&gt; pronto. selecione as opcoes e clique em aplicar selecionados_"/>
                        </ScrollViewer>
                    </Border>

                    <ProgressBar Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="4" Name="progBar" Minimum="0" Maximum="100" Value="0" Margin="0,0,0,12"/>

                    <Button Grid.Row="2" Grid.Column="1" Name="btnSelectAll" Content="Selecionar Tudo" Style="{StaticResource GhostButton}" Margin="0,0,8,0"/>
                    <Button Grid.Row="2" Grid.Column="2" Name="btnClear" Content="Limpar" Style="{StaticResource GhostButton}" Margin="0,0,8,0"/>
                    <Button Grid.Row="2" Grid.Column="3" Name="btnApply" Content="Aplicar Selecionados" Style="{StaticResource PrimaryButton}" Width="200"/>
                </Grid>
            </Border>

        </Grid>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# ------------------------------------------------------------
# 2. Referencias aos controles
# ------------------------------------------------------------
$ctrl = @{}
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    $ctrl[$_.Name] = $window.FindName($_.Name)
}

# ------------------------------------------------------------
# 3. Navegacao entre paginas
# ------------------------------------------------------------
$pages = @{
    navOtimizacao  = $ctrl.pageOtimizacao
    navLimpeza     = $ctrl.pageLimpeza
    navPrivacidade = $ctrl.pagePrivacidade
    navAvancado    = $ctrl.pageAvancado
    navStatus      = $ctrl.pageStatus
    navSobre       = $ctrl.pageSobre
}

function Show-Page($navKey) {
    foreach ($key in $pages.Keys) {
        $pages[$key].Visibility = if ($key -eq $navKey) { 'Visible' } else { 'Collapsed' }
    }
    # rodape so aparece nas paginas de tweaks
    $ctrl.footerBar.Visibility = if ($navKey -in @('navOtimizacao','navLimpeza','navPrivacidade','navAvancado')) { 'Visible' } else { 'Collapsed' }

    # timer de status so roda quando a pagina esta visivel (economiza recursos)
    if ($navKey -eq 'navStatus') { $script:statusTimer.Start() } else { $script:statusTimer.Stop() }
}

foreach ($navKey in $pages.Keys) {
    $ctrl[$navKey].Add_Checked({ Show-Page $this.Name }.GetNewClosure())
}

# ------------------------------------------------------------
# 4. Clique na linha inteira ativa o checkbox
#    (estrutura agora e StackPanel Horizontal: [checkbox, texto])
# ------------------------------------------------------------
foreach ($key in ($ctrl.Keys | Where-Object { $_ -like 'chk*' })) {
    $cb = $ctrl[$key]
    $rowBorder = $cb.Parent.Parent   # StackPanel -> Border (OptionRow)
    if ($rowBorder) {
        $rowBorder.Add_MouseLeftButtonUp({ $cb.IsChecked = -not $cb.IsChecked }.GetNewClosure())
        $rowBorder.Cursor = [System.Windows.Input.Cursors]::Hand
    }
}

# ------------------------------------------------------------
# 5. Console de log (rodape estilo terminal)
# ------------------------------------------------------------
function Add-LogLine {
    param([string]$Text)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "[$timestamp] $Text"
    if ($ctrl.txtLog.Text -like "&gt; pronto*" -or $ctrl.txtLog.Text -like "> pronto*") {
        $ctrl.txtLog.Text = $line
    } else {
        $ctrl.txtLog.Text += "`r`n$line"
    }
    $ctrl.txtLog.CaretIndex = $ctrl.txtLog.Text.Length
    $ctrl.logScroll.ScrollToEnd()
}

function Set-StatusText($text) { Add-LogLine $text }

# ------------------------------------------------------------
# 6. Funcoes de otimizacao / limpeza / privacidade
# ------------------------------------------------------------
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
function Disable-Hibernacao { powercfg -h off }
function Disable-Indexacao {
    Get-Service "WSearch" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
    Set-Service "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue
}
function Disable-Superfetch {
    Get-Service "SysMain" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
    Set-Service "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
}
function Reduce-Animacoes {
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Value 0 -Force -ErrorAction SilentlyContinue
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
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
    Start-Process explorer
}
function Clear-EventLogs { wevtutil el | ForEach-Object { wevtutil cl "$_" 2>$null } }

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
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BackgroundAppGlobalToggle" -Value 0 -ErrorAction SilentlyContinue
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
function New-SystemRestorePoint {
    Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "LegacyMods - antes das alteracoes" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------
# 5b. Funcoes "Avancado (CTT)" - equivalentes aos tweaks do WinUtil (config/tweaks.json)
# ------------------------------------------------------------
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
        "HKCU:\Control Panel\Desktop"                                             = @{ MenuShowDelay = 200 }
        "HKCU:\Control Panel\Desktop\WindowMetrics"                               = @{ }
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"       = @{ ListviewAlphaSelect = 0; ListviewShadow = 0; TaskbarAnimations = 0; TaskbarMn = 0; ShowTaskViewButton = 0 }
        "HKCU:\Software\Microsoft\Windows\DWM"                                    = @{ EnableAeroPeek = 0 }
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"                  = @{ SearchboxTaskbarMode = 0 }
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

$TweakMap = @{
    chkPowerPlan     = @("Ativando plano de Alto Desempenho", { Enable-HighPerformancePlan })
    chkVisualEffects = @("Ajustando efeitos visuais", { Set-VisualEffectsPerformance })
    chkGameBar       = @("Desativando Game Bar", { Disable-GameBar })
    chkStartupDelay  = @("Removendo atraso de inicializacao", { Remove-StartupDelay })
    chkHibernacao    = @("Desativando hibernacao", { Disable-Hibernacao })
    chkIndexacao     = @("Desativando indexacao", { Disable-Indexacao })
    chkSuperfetch    = @("Desativando SysMain/Superfetch", { Disable-Superfetch })
    chkAnimacoes     = @("Reduzindo animacoes", { Reduce-Animacoes })
    chkTemp           = @("Limpando arquivos temporarios", { Clear-TempFiles })
    chkLixeira        = @("Esvaziando lixeira", { Clear-Lixeira })
    chkWinUpdateCache = @("Limpando cache do Windows Update", { Clear-WinUpdateCache })
    chkPrefetch       = @("Limpando Prefetch", { Clear-Prefetch })
    chkDNS            = @("Limpando cache DNS", { Clear-DNSCache })
    chkMiniaturas     = @("Limpando miniaturas", { Clear-Thumbnails })
    chkLogs           = @("Limpando logs de eventos", { Clear-EventLogs })
    chkTelemetria     = @("Desativando telemetria", { Disable-Telemetria })
    chkCortana        = @("Desativando Cortana", { Disable-Cortana })
    chkAdsID          = @("Desativando ID de publicidade", { Disable-AdsID })
    chkBackgroundApps = @("Desativando apps em segundo plano", { Disable-BackgroundApps })
    chkLocalizacao    = @("Desativando localizacao", { Disable-Localizacao })
    chkDicas          = @("Desativando dicas do Windows", { Disable-Dicas })
    chkFeedback       = @("Desativando feedback", { Disable-Feedback })
    chkServicesManual     = @("Otimizando servicos do sistema", { Set-ServicesManual })
    chkVisualExtra        = @("Aplicando efeitos visuais - modo extremo", { Set-VisualEffectsExtreme })
    chkStorageSense       = @("Desativando Storage Sense", { Disable-StorageSense })
    chkDeliveryOpt        = @("Desativando Delivery Optimization", { Disable-DeliveryOptimization })
    chkEndTaskTaskbar     = @("Habilitando Finalizar Tarefa na taskbar", { Enable-EndTaskTaskbar })
    chkWPBT               = @("Desativando WPBT", { Disable-WPBT })
    chkUTC                = @("Definindo relogio para UTC", { Set-ClockUTC })
    chkRdpWarning         = @("Removendo aviso de RDP nao assinado", { Disable-RdpUnsignedWarning })
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

# ------------------------------------------------------------
# 7. Metricas de sistema (aba Status)
# ------------------------------------------------------------
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
        $sum = ($samples | Measure-Object -Property CookedValue -Sum).Sum
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
    if ($null -ne $cpu) {
        $ctrl.barCpu.Value = $cpu
        $ctrl.txtCpuPercent.Text = "$cpu%"
    } else {
        $ctrl.txtCpuPercent.Text = "N/D"
    }
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
    if ($null -ne $gpu) {
        $ctrl.barGpu.Value = $gpu
        $ctrl.txtGpuPercent.Text = "$gpu%"
    } else {
        $ctrl.txtGpuPercent.Text = "N/D"
    }
    $ctrl.txtGpuName.Text = $cachedGpuName

    $ctrl.txtUptime.Text = Get-UptimeText
}

$script:statusTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:statusTimer.Interval = [TimeSpan]::FromSeconds(2)
$script:statusTimer.Add_Tick({ Update-StatusMetrics })

# ------------------------------------------------------------
# 8. Eventos dos botoes
# ------------------------------------------------------------
$ctrl.btnSelectAll.Add_Click({ foreach ($key in $TweakMap.Keys) { $ctrl[$key].IsChecked = $true } })
$ctrl.btnClear.Add_Click({ foreach ($key in $TweakMap.Keys) { $ctrl[$key].IsChecked = $false } })

$ctrl.btnRestorePoint.Add_Click({
    Add-LogLine "Criando ponto de restauracao..."
    New-SystemRestorePoint
    Add-LogLine "Ponto de restauracao criado (se o sistema permitir)."
})

$ctrl.btnApply.Add_Click({
    $selecionados = $TweakMap.Keys | Where-Object { $ctrl[$_].IsChecked -eq $true }
    if ($selecionados.Count -eq 0) { Add-LogLine "Nenhuma opcao selecionada."; return }

    $ctrl.btnApply.IsEnabled = $false
    $total = $selecionados.Count
    $i = 0

    foreach ($key in $selecionados) {
        $i++
        $desc = $TweakMap[$key][0]
        $fn   = $TweakMap[$key][1]

        Add-LogLine "($i/$total) $desc..."
        $ctrl.progBar.Value = [int](($i / $total) * 100)
        $window.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)

        try { & $fn } catch { Add-LogLine "ERRO em '$desc': $($_.Exception.Message)"; Start-Sleep -Milliseconds 800 }
    }

    Add-LogLine "Concluido! $total otimizacao(oes) aplicada(s). Reinicie o PC para efeito completo."
    $ctrl.btnApply.IsEnabled = $true
})

$window.Add_Closing({ $script:statusTimer.Stop() })

# ------------------------------------------------------------
# 9. Exibir janela
# ------------------------------------------------------------
$window.ShowDialog() | Out-Null