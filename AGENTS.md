# Spécifications de l'Agent Mobile (Front-End) - Boli

Cet agent (développé en **Flutter**) s'exécute sur le terminal de l'utilisateur (Client ou Chauffeur/Livreur). Il est conçu avec une approche **Offline-First**, asynchrone et hautement optimisée pour économiser la batterie et la bande passante 4G locale.

## 1. Responsabilités de l'Agent

### Mode Client
* **Gestion du Cycle de Vie des Commandes :** Prise de commande (Food/Marketplace) synchronisée avec SuguJate, requêtes de courses VTC.
* **Rendu Cartographique Économe :** Affichage des cartes via `MapLibre GL` en utilisant le serveur de tuiles auto-hébergé (0$ API Google).
* **Gestion du Wallet :** Consultation du solde, recharges Mobile Money et exécution des paiements locaux via l'API Gateway.

### Mode Chauffeur / Livreur (L'Agent Critique)
* **Télémétrie GPS Continue :** Collecte des coordonnées de l'appareil en arrière-plan et transmission brute.
* **Edge Routing :** Calcul local des itinéraires via l'instance OSRM/Valhalla locale pour décharger le serveur central.

---

## 2. Protocoles et Flux Techniques

### Flux de Télémétrie GPS (Chauffeur -> Back)
L'agent n'utilise pas de requêtes HTTP pour le tracking. Il maintient une connexion persistante.
1. Ouverture d'une connexion **WebSocket / MQTT** vers `ws://api.infrastructure.local/v1/telemetry/stream`.
2. Capture de la position GPS toutes les **3 secondes** (uniquement si déplacement > 5 mètres pour économiser la batterie).
3. Envoi du payload brut compressé :
```json
{
  "agent_id": "CH-9982",
  "lat": 12.6392,
  "lon": -8.0029,
  "bearing": 180.5,
  "status": "AVAILABLE"
}

Mécanisme de Résilience Réseau (Offline-First)
Cache Local : Utilisation de SQLite / Hive pour stocker l'état de la commande en cours.

File d'attente interne : Si la connexion 4G coupe pendant une livraison, l'agent stocke les coordonnées GPS et les changements de statut localement. Dès que le signal revient, l'agent flush sa pile vers le backend avec un mécanisme de retry exponentiel.

3. Sécurité de l'Agent (SecOps Mobile)
Chiffrement au repos : Le token d'authentification JWT et les clés du Wallet sont stockés dans le stockage sécurisé natif du téléphone (Keystore / Keychain).

SSL Pinning : L'agent refuse de communiquer si le certificat TLS de l'API Gateway ne correspond pas strictement au certificat embarqué, bloquant les attaques de type Man-In-The-Middle (MITM) sur les réseaux Wi-Fi/4G publics.