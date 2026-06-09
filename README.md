# Boli Mobile App (Flutter Client)

Cette application est le client multiplateforme de la Super-App **Boli** (VTC & Livraison).

## Configuration

### 1. Variables d'environnement (.env)
L'application charge ses variables d'environnement depuis un fichier `.env` à la racine de ce répertoire. Assurez-vous d'avoir un fichier `.env` configuré comme suit :

```env
API_BASE_URL_WEB=http://127.0.0.1:8000/api/v1
API_BASE_URL_MOBILE=http://10.0.2.2:8000/api/v1
WS_URL_WEB=ws://127.0.0.1:8000/ws/notifications
WS_URL_MOBILE=ws://10.0.2.2:8000/ws/notifications

# Firebase Secrets
APIKEY=votre_api_key
APPID=votre_app_id
MESSAGINGSENDERID=votre_messaging_sender_id
PROJECTID=votre_project_id
STORAGEBUCKET=votre_storage_bucket
```

### 2. Dépendances & Lancement
Installez les dépendances et lancez l'application :
```bash
flutter pub get
flutter run
```

---

## 🧪 Tests de l'application
Pour lancer les tests de widgets et d'intégration de l'application :
```bash
flutter test
```

---

## 📄 Licence
Ce projet est sous licence **MIT**. Voir le fichier [LICENSE](../LICENSE) principal pour plus de détails.
