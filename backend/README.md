# README pour l'installation et l'exécution des frontends de Citizen Act

Ce document décrit les étapes pour installer et exécuter les frontends de l'application **Citizen Act** pour les utilisateurs **Citoyen** (Flutter), **Agent** (React) et **Administrateur** (React). Le backend est déployé à `https://ueprojet.onrender.com`.

---

## Sommaire
1. [Prérequis](#prérequis)
2. [Structure du dépôt](#structure-du-dépôt)
3. [Frontend Citoyen (Flutter)](#frontend-citoyen-flutter)
   - [Installation](#installation-flutter)
   - [Configuration](#configuration-flutter)
   - [Exécution](#exécution-flutter)
4. [Frontend Agent (React)](#frontend-agent-react)
   - [Installation](#installation-react-agent)
   - [Configuration](#configuration-react-agent)
   - [Exécution](#exécution-react-agent)
5. [Frontend Administrateur (React)](#frontend-administrateur-react)
   - [Installation](#installation-react-admin)
   - [Configuration](#configuration-react-admin)
   - [Exécution](#exécution-react-admin)

---

## Prérequis

- **Git** : Pour cloner le dépôt (`https://gitup.com/LISINA-10/UeProjet`).
- **Flutter** (pour Citoyen) : Version 3.x.x ou supérieure.
- **Node.js** (pour Agent et Administrateur) : Version 16.x ou supérieure.
- **npm** ou **yarn** : Gestionnaire de paquets pour React.
- **Éditeur de code** : VS Code, Android Studio, ou IntelliJ IDEA.
- **Appareil/émulateur** : Pour Flutter (Android/iOS) ou un navigateur pour React.

---

## Structure du dépôt

Le dépôt est accessible à `https://gitup.com/LISINA-10/UeProjet`. Les frontends sont dans `uePROJET/FRONTEND` :
- `citizen_act` : Flutter (Citoyen).
- `citizen_act_agent1` : React (Agent).
- `citizen_act_admin` : React (Administrateur).

Clonez le dépôt :
```bash
git clone https://gitup.com/LISINA-10/UeProjet
cd uePROJET/FRONTEND
```

---

## Frontend Citoyen (Flutter)

### Installation (Flutter)

1. **Naviguer vers le dossier** :
   ```bash
   cd citizen_act
   ```

2. **Installer les dépendances** :
   ```bash
   flutter pub get
   ```

3. **Vérifier Flutter** :
   ```bash
   flutter doctor
   ```

### Configuration (Flutter)

1. **Configurer l'URL du backend** :
   Modifiez `lib/services/api.dart` :
   ```dart
   const String baseUrl = 'https://ueprojet.onrender.com/api';
   ```

2. **Configurer les permissions** :
   - Android (`android/app/src/main/AndroidManifest.xml`) :
     ```xml
     <uses-permission android:name="android.permission.INTERNET"/>
     <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
     <uses-permission android:name="android.permission.CAMERA"/>
     ```
   - iOS (`ios/Runner/Info.plist`) :
     ```xml
     <key>NSLocationWhenInUseUsageDescription</key>
     <string>Utilisé pour localiser les signalements</string>
     <key>NSCameraUsageDescription</key>
     <string>Utilisé pour capturer des images de signalements</string>
     ```

3. **Types de signalements** :
   Vérifiez dans `main_page.dart` :
   ```dart
   const List<String> signalementTypes = [
     'Route endommagée', 'Déchets accumulés', 'Éclairage défectueux',
     'Pont instable', 'Trottoir fissuré', 'Égout bouché',
     'Panneau endommagé', 'Eau stagnante', 'Route inondée', 'Poubelle débordante'
   ];
   ```

### Exécution (Flutter)

1. **Lancer un émulateur/appareil** :
   - Android : Via Android Studio.
   - iOS : Via Xcode.

2. **Exécuter** :
   ```bash
   flutter run
   ```

---

## Frontend Agent (React)

### Installation (React Agent)

1. **Naviguer vers le dossier** :
   ```bash
   cd citizen_act_agent1
   ```

2. **Installer les dépendances** :
   ```bash
   npm install
   ```

### Configuration (React Agent)

1. **Configurer l'URL du backend** :
   Modifiez `src/services/api.js` :
   ```javascript
   const BASE_URL = 'https://ueprojet.onrender.com/api';
   ```

2. **Configurer les icônes Leaflet** :
   Si les icônes ne chargent pas, copiez `marker-icon.png`, `marker-icon-2x.png`, `marker-shadow.png` de `node_modules/leaflet/dist/images/` dans `public/` et mettez à jour `src/MainPage.js` :
   ```javascript
   L.Icon.Default.mergeOptions({
     iconRetinaUrl: '/marker-icon-2x.png',
     iconUrl: '/marker-icon.png',
     shadowUrl: '/marker-shadow.png'
   });
   ```

3. **Types de signalements** :
   Vérifiez dans `src/MainPage.js` :
   ```javascript
   const signalementTypes = [
     'Route endommagée', 'Déchets accumulés', 'Éclairage défectueux',
     'Pont instable', 'Trottoir fissuré', 'Égout bouché',
     'Panneau endommagé', 'Eau stagnante', 'Route inondée', 'Poubelle débordante'
   ];
   ```

### Exécution (React Agent)

1. **Lancer l'application** :
   ```bash
   npm start
   ```
   Ouvre `http://localhost:3000`.

2. **Tester** :
   Connectez-vous avec :
   - `agent1` / `agentpass1` (Douala I).
   - `agent2` / `agentpass2` (Yaoundé I).

---

## Frontend Administrateur (React)

### Installation (React Admin)

1. **Naviguer vers le dossier** :
   ```bash
   cd citizen_act_admin
   ```

2. **Installer les dépendances** :
   ```bash
   npm install
   ```

### Configuration (React Admin)

1. **Configurer l'URL du backend** :
   Modifiez `src/services/api.js` :
   ```javascript
   const BASE_URL = 'https://ueprojet.onrender.com/api';
   ```

2. **Configurer les icônes Leaflet** :
   Comme pour le frontend Agent, copiez les icônes dans `public/` si nécessaire et mettez à jour `src/MainPage.js`.

### Exécution (React Admin)

1. **Lancer l'application** :
   ```bash
   npm start
   ```
   Ouvre `http://localhost:3000`.

2. **Tester** :
   Connectez-vous avec :
   - `admin1` / `adminpass1`.