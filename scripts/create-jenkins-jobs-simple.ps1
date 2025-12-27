# Script PowerShell simplifié pour créer les jobs Jenkins
# Usage: .\scripts\create-jenkins-jobs-simple.ps1

Write-Host "`n🚀 Création des jobs Jenkins pour AquaWatch-MS`n" -ForegroundColor Cyan

# Copier le script Groovy dans Jenkins
Write-Host "📋 Copie du script de création des jobs..." -ForegroundColor Yellow
docker cp infrastructure/jenkins/create-jobs.groovy aquawatch-ms-jenkins-1:/tmp/create-jobs.groovy

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de la copie du script" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Script copié avec succès`n" -ForegroundColor Green

# Exécuter le script Groovy
Write-Host "⚙️  Exécution du script de création des jobs...`n" -ForegroundColor Yellow

docker exec aquawatch-ms-jenkins-1 bash -c "cat /tmp/create-jobs.groovy | java -jar /opt/java/openjdk/lib/jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin123 groovy ="

Write-Host "`n✨ Terminé !`n" -ForegroundColor Green
Write-Host "🌐 Accédez à Jenkins: http://localhost:8080" -ForegroundColor Cyan
Write-Host "📋 Vérifiez que les jobs ont été créés`n" -ForegroundColor White
