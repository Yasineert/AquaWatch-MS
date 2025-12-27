# Script de configuration et démarrage de Jenkins pour AquaWatch-MS
# Usage: .\scripts\jenkins-setup.ps1

param(
    [switch]$Build = $false,
    [switch]$Start = $true,
    [switch]$ShowPassword = $true
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

Write-ColorOutput Cyan "`n🚀 Configuration de Jenkins pour AquaWatch-MS`n"

# Build de l'image Jenkins si demandé
if ($Build) {
    Write-ColorOutput Yellow "📦 Build de l'image Jenkins personnalisée..."
    docker-compose build jenkins
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✅ Image Jenkins construite avec succès"
    } else {
        Write-ColorOutput Red "❌ Erreur lors du build de l'image Jenkins"
        exit 1
    }
}

# Démarrage de Jenkins
if ($Start) {
    Write-ColorOutput Yellow "`n🔄 Démarrage de Jenkins..."
    docker-compose up -d jenkins
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✅ Jenkins démarré avec succès"
    } else {
        Write-ColorOutput Red "❌ Erreur lors du démarrage de Jenkins"
        exit 1
    }
    
    Write-ColorOutput Yellow "`n⏳ Attente du démarrage complet de Jenkins (cela peut prendre 2-3 minutes)..."
    Start-Sleep -Seconds 30
    
    # Vérifier que Jenkins est accessible
    $maxAttempts = 10
    $attempt = 0
    $jenkinsReady = $false
    
    while ($attempt -lt $maxAttempts -and -not $jenkinsReady) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 403) {
                $jenkinsReady = $true
                Write-ColorOutput Green "`n✅ Jenkins est accessible !"
            }
        } catch {
            $attempt++
            Write-ColorOutput Yellow "   Tentative $attempt/$maxAttempts - Jenkins n'est pas encore prêt..."
            Start-Sleep -Seconds 10
        }
    }
    
    if (-not $jenkinsReady) {
        Write-ColorOutput Red "`n❌ Jenkins n'est pas accessible après $maxAttempts tentatives"
        Write-ColorOutput Yellow "💡 Vérifiez les logs avec: docker-compose logs jenkins"
        exit 1
    }
}

# Afficher les informations de connexion
if ($ShowPassword) {
    Write-ColorOutput Cyan "`n📋 INFORMATIONS DE CONNEXION"
    Write-ColorOutput Cyan "============================"
    Write-ColorOutput Yellow "🌐 URL: http://localhost:8080"
    Write-ColorOutput Yellow "👤 Username: admin"
    Write-ColorOutput Yellow "🔑 Password: admin123"
    Write-ColorOutput Red "`n⚠️  IMPORTANT: Changez le mot de passe après la première connexion !"
}

# Informations supplémentaires
Write-ColorOutput Cyan "`n📚 INFORMATIONS SUPPLÉMENTAIRES"
Write-ColorOutput Cyan "================================"
Write-ColorOutput White "• Blue Ocean (interface moderne): http://localhost:8080/blue"
Write-ColorOutput White "• GeoServer (déplacé): http://localhost:8090"
Write-ColorOutput White "• SonarQube: http://localhost:9090"
Write-ColorOutput White ""
Write-ColorOutput White "📖 Documentation complète: infrastructure/jenkins/README.md"

Write-ColorOutput Cyan "`n🎯 PROCHAINES ÉTAPES"
Write-ColorOutput Cyan "===================="
Write-ColorOutput White "1. Connectez-vous à Jenkins: http://localhost:8080"
Write-ColorOutput White "2. Changez le mot de passe admin"
Write-ColorOutput White "3. Configurez SonarQube dans Jenkins (si SonarQube est démarré)"
Write-ColorOutput White "4. Créez les jobs pour chaque service"
Write-ColorOutput White "5. Configurez les webhooks GitHub (optionnel)"

Write-ColorOutput Green "`n✨ Configuration terminée !`n"
