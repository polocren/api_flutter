# Quiz Flutter

Application mobile Flutter connectée à une API Laravel. Elle permet de se connecter, lancer un quiz par thème ou aléatoire, consulter son score, le classement et l'historique des quiz terminés.

## Fonctionnalités

- Connexion et inscription utilisateur
- Tableau de bord avec score personnel, meilleur score, moyenne et classement
- Lancement d'un quiz aléatoire ou par thème
- Choix du nombre de questions
- Correction détaillée après validation
- Historique des anciens quiz
- Images personnalisées pour les thèmes

## Prérequis

- Flutter installé sur la machine
- Un simulateur, un appareil mobile ou la cible macOS activée
- L'API Laravel accessible depuis l'application

## Installation

```bash
flutter pub get
```

## Configuration de l'API

L'URL de l'API se trouve dans le fichier `.env` :

```env
API_BASE_URL=https://exemple.ngrok-free.app/api
```

Le fichier est chargé au démarrage avec `flutter_dotenv`, puis transmis au client HTTP de l'application.

## Lancer l'application

Sur macOS :

```bash
flutter run -d macos
```

Pour voir les appareils disponibles :

```bash
flutter devices
```

## Tests et analyse

```bash
flutter analyze
flutter test
```

## Organisation du code

- `lib/screens/` : les écrans de l'application
- `lib/services/` : appels API et logique d'authentification
- `lib/models/` : objets utilisés par les écrans et services
- `lib/widgets/` : composants réutilisables
- `assets/themes/` : images affichées sur les cartes de thèmes

## Images des thèmes

Les images sont placées dans `assets/themes/`. Le fichier `theme_selection_screen.dart` associe les labels renvoyés par l'API aux images disponibles, avec une icône de secours si aucune image ne correspond.
