# Configuration SonarCloud pour GitHub Actions

## ✅ Fichier créé

Le workflow GitHub Actions a été créé : `.github/workflows/sonarcloud.yml`

## 🔧 Configuration requise

### Étape 1 : Ajouter le token SonarCloud dans GitHub

1. Allez dans votre repo GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Cliquez sur **New repository secret**
4. Nom : `SONAR_TOKEN`
5. Valeur : `71d6f23ee97c483d3384f650f2cb357368e480c7`
6. Cliquez sur **Add secret**

### Étape 2 : Pousser le code sur GitHub

```bash
git add .github/workflows/sonarcloud.yml
git commit -m "Add SonarCloud GitHub Actions workflow"
git push
```

## 🚀 Fonctionnement

Le workflow s'exécutera automatiquement :
- ✅ À chaque **push** sur `main`, `master` ou `develop`
- ✅ À chaque **pull request**

Il analysera **tous les 5 services** en parallèle :
- service_capteurs
- service_alertes  
- service_api_sig
- service_satellite
- service_stmodel

## 📊 Voir les résultats

1. **GitHub** : Onglet **Actions** de votre repo
2. **SonarCloud** : https://sonarcloud.io/organizations/aquawatch/projects

## 🎯 Avantages

✅ **Automatique** - Analyse à chaque commit  
✅ **Parallèle** - Tous les services en même temps  
✅ **Intégré** - Résultats dans les PRs  
✅ **Gratuit** - Pour les projets publics
