# Script PowerShell pour créer automatiquement les jobs Jenkins
# Usage: .\scripts\create-jenkins-jobs.ps1

param(
    [string]$JenkinsUrl = "http://localhost:8080",
    [string]$Username = "admin",
    [string]$Password = "admin123"
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

Write-ColorOutput Cyan "`n🚀 Création automatique des jobs Jenkins pour AquaWatch-MS`n"

# Vérifier que Jenkins est accessible
Write-ColorOutput Yellow "🔍 Vérification de la connexion à Jenkins..."
try {
    $response = Invoke-WebRequest -Uri $JenkinsUrl -UseBasicParsing -TimeoutSec 5
    Write-ColorOutput Green "✅ Jenkins est accessible"
} catch {
    Write-ColorOutput Red "❌ Impossible de se connecter à Jenkins sur $JenkinsUrl"
    Write-ColorOutput Yellow "💡 Assurez-vous que Jenkins est démarré: docker-compose ps jenkins"
    exit 1
}

# Copier le script Groovy dans le conteneur Jenkins
Write-ColorOutput Yellow "`n📋 Copie du script de création des jobs..."
docker cp infrastructure/jenkins/create-jobs.groovy aquawatch-ms-jenkins-1:/tmp/create-jobs.groovy

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput Red "❌ Erreur lors de la copie du script"
    exit 1
}

Write-ColorOutput Green "✅ Script copié avec succès"

# Exécuter le script Groovy dans Jenkins
Write-ColorOutput Yellow "`n⚙️  Exécution du script de création des jobs..."
Write-ColorOutput Cyan "Cela peut prendre quelques secondes...`n"

$output = docker exec aquawatch-ms-jenkins-1 java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ -auth ${Username}:${Password} groovy = < /tmp/create-jobs.groovy 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput Green "`n✅ Jobs créés avec succès !`n"
    Write-Output $output
} else {
    Write-ColorOutput Yellow "`n⚠️  Tentative alternative avec curl...`n"
    
    # Alternative : utiliser l'API REST de Jenkins
    $scriptContent = Get-Content "infrastructure/jenkins/create-jobs.groovy" -Raw
    $encodedScript = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($scriptContent))
    
    $headers = @{
        "Authorization" = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$JenkinsUrl/scriptText" -Method Post -Headers $headers -Body @{script=$scriptContent}
        Write-ColorOutput Green "`n✅ Jobs créés avec succès via API REST !`n"
        Write-Output $response
    } catch {
        Write-ColorOutput Red "`n❌ Erreur lors de la création des jobs"
        Write-ColorOutput Yellow "Erreur: $_"
        Write-ColorOutput Yellow "`n💡 Vous pouvez créer les jobs manuellement en suivant la documentation"
        exit 1
    }
}

# Afficher les informations
Write-ColorOutput Cyan "`n📊 JOBS CRÉÉS"
Write-ColorOutput Cyan "============="
Write-ColorOutput White "• service_capteurs (Node.js)"
Write-ColorOutput White "• service_alertes (Node.js)"
Write-ColorOutput White "• service_api_sig (Next.js/TypeScript)"
Write-ColorOutput White "• service_satellite (Python)"
Write-ColorOutput White "• service_stmodel (Python)"
Write-ColorOutput White "• AquaWatch-MS-Global (Pipeline global)"

Write-ColorOutput Cyan "`n🎯 PROCHAINES ÉTAPES"
Write-ColorOutput Cyan "===================="
Write-ColorOutput White "1. Accédez à Jenkins: $JenkinsUrl"
Write-ColorOutput White "2. Vérifiez que tous les jobs sont créés"
Write-ColorOutput White "3. Lancez un build de test sur un service"
Write-ColorOutput White "4. Configurez SonarQube si nécessaire"
Write-ColorOutput White "5. Configurez les webhooks GitHub (optionnel)"

Write-ColorOutput Green "`n✨ Configuration terminée !`n"
