# Script d'analyse SonarQube pour AquaWatch-MS
# Usage: .\scripts\sonarqube-analyze.ps1 [-Service <nom_service>] [-SonarHost <url>]

param(
    [string]$Service = "all",
    [string]$SonarHost = "http://localhost:9090"
)

# Couleurs pour les messages
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Vérifier que SonarQube est accessible
Write-ColorOutput Yellow "🔍 Vérification de la disponibilité de SonarQube..."
try {
    $response = Invoke-WebRequest -Uri "$SonarHost/api/system/status" -UseBasicParsing -TimeoutSec 5
    $status = ($response.Content | ConvertFrom-Json).status
    if ($status -eq "UP") {
        Write-ColorOutput Green "✅ SonarQube est accessible et opérationnel"
    } else {
        Write-ColorOutput Red "❌ SonarQube n'est pas prêt (status: $status)"
        exit 1
    }
} catch {
    Write-ColorOutput Red "❌ Impossible de se connecter à SonarQube sur $SonarHost"
    Write-ColorOutput Yellow "💡 Assurez-vous que SonarQube est démarré: docker-compose up -d sonarqube"
    exit 1
}

# Liste des services
$services = @(
    @{Name="service_capteurs"; Type="Node.js"},
    @{Name="service_alertes"; Type="Node.js"},
    @{Name="service_api_sig"; Type="Next.js/TypeScript"},
    @{Name="service_satellite"; Type="Python"},
    @{Name="service_stmodel"; Type="Python"}
)

# Fonction pour analyser un service
function Analyze-Service {
    param(
        [string]$ServiceName,
        [string]$ServiceType
    )
    
    Write-ColorOutput Cyan "`n📊 Analyse de $ServiceName ($ServiceType)..."
    
    $servicePath = ".\services\$ServiceName"
    
    if (-not (Test-Path "$servicePath\sonar-project.properties")) {
        Write-ColorOutput Red "❌ Fichier sonar-project.properties introuvable pour $ServiceName"
        return $false
    }
    
    Push-Location $servicePath
    
    try {
        # Télécharger le scanner si nécessaire
        if (-not (Test-Path "..\..\sonar-scanner")) {
            Write-ColorOutput Yellow "📥 Téléchargement du SonarScanner..."
            $scannerVersion = "5.0.1.3006"
            $scannerZip = "sonar-scanner-cli-$scannerVersion-windows.zip"
            $downloadUrl = "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/$scannerZip"
            
            Invoke-WebRequest -Uri $downloadUrl -OutFile "..\..\$scannerZip"
            Expand-Archive -Path "..\..\$scannerZip" -DestinationPath "..\..\" -Force
            Rename-Item -Path "..\..\sonar-scanner-$scannerVersion-windows" -NewName "sonar-scanner"
            Remove-Item "..\..\$scannerZip"
            
            Write-ColorOutput Green "✅ SonarScanner installé"
        }
        
        # Exécuter l'analyse
        $scannerPath = "..\..\sonar-scanner\bin\sonar-scanner.bat"
        & $scannerPath "-Dsonar.host.url=$SonarHost"
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput Green "✅ Analyse de $ServiceName terminée avec succès"
            Pop-Location
            return $true
        } else {
            Write-ColorOutput Red "❌ Erreur lors de l'analyse de $ServiceName"
            Pop-Location
            return $false
        }
    } catch {
        Write-ColorOutput Red "❌ Exception lors de l'analyse de $ServiceName : $_"
        Pop-Location
        return $false
    }
}

# Exécution de l'analyse
Write-ColorOutput Cyan "`n🚀 Démarrage de l'analyse SonarQube pour AquaWatch-MS`n"

$results = @()

if ($Service -eq "all") {
    Write-ColorOutput Yellow "📋 Analyse de tous les services..."
    foreach ($svc in $services) {
        $success = Analyze-Service -ServiceName $svc.Name -ServiceType $svc.Type
        $results += @{Service=$svc.Name; Success=$success}
    }
} else {
    $selectedService = $services | Where-Object { $_.Name -eq $Service }
    if ($selectedService) {
        $success = Analyze-Service -ServiceName $selectedService.Name -ServiceType $selectedService.Type
        $results += @{Service=$selectedService.Name; Success=$success}
    } else {
        Write-ColorOutput Red "❌ Service '$Service' introuvable"
        Write-ColorOutput Yellow "Services disponibles: $($services.Name -join ', ')"
        exit 1
    }
}

# Résumé
Write-ColorOutput Cyan "`n📈 RÉSUMÉ DE L'ANALYSE"
Write-ColorOutput Cyan "====================="
$successCount = ($results | Where-Object { $_.Success }).Count
$totalCount = $results.Count

foreach ($result in $results) {
    if ($result.Success) {
        Write-ColorOutput Green "✅ $($result.Service)"
    } else {
        Write-ColorOutput Red "❌ $($result.Service)"
    }
}

Write-ColorOutput Cyan "`n📊 $successCount/$totalCount services analysés avec succès"
Write-ColorOutput Yellow "`n🌐 Consultez les résultats sur: $SonarHost"
Write-ColorOutput Yellow "   Identifiants par défaut: admin / admin (à changer au premier démarrage)"

if ($successCount -eq $totalCount) {
    exit 0
} else {
    exit 1
}
