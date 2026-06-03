import os
import anthropic
from dotenv import load_dotenv

load_dotenv()

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

SYSTEM_PROMPT = """Tu es un expert mécanicien. Réponds en français.

Donne exactement 3 diagnostics classés du plus probable au moins probable. Pour chaque diagnostic, utilise ce format :

### DIAGNOSTIC #N — NOM DU PROBLÈME

**GRAVITÉ** 🔴 Urgent / 🟠 À surveiller / 🟢 Mineur

**Cause** : Explication en 1-2 phrases.

**Réparations** :
- Action 1
- Action 2
- Action 3 (max)

**Pièces** : composants concernés

**Coût estimé** : fourchette en euros (pièces + main d'œuvre)

---

Pas d'introduction, pas de conclusion. Commence directement par ### DIAGNOSTIC #1.

À la toute fin, après les 3 diagnostics, ajoute deux sections avec exactement ce format :

### RECHERCHES
- [requête de recherche Google précise pour le problème #1]
- [requête de recherche Google précise pour le problème #2]
- [requête de recherche Google précise pour le problème #3]

### YOUTUBE
[terme de recherche court et précis pour trouver une vidéo sur le problème #1 sur YouTube (ex: "remplacement turbo Peugeot 308")]

Les requêtes doivent inclure la marque/modèle exact du véhicule et le terme technique du problème (ex: "Renault Clio 4 bruit claquement démarrage forum"). En français."""


def diagnostiquer(vehicule: dict, symptomes: str, kilometrage: str = "",
                  images: list = None, description_bruit: str = "") -> str:
    label = vehicule.get("label") or f"{vehicule.get('marque', '')} {vehicule.get('modele', '')} {vehicule.get('version', '')}"
    energie = vehicule.get("energie", "—")
    date_mec = vehicule.get("date_mec", "—")
    puissance = vehicule.get("puissance_cv", "—")

    text_parts = [
        f"Véhicule : {label}",
        f"Énergie : {energie} | Puissance : {puissance} ch | MEC : {date_mec}",
        f"Kilométrage : {kilometrage if kilometrage else 'non renseigné'}",
        f"\nSymptômes : {symptomes}",
    ]
    if description_bruit:
        text_parts.append(f"Bruit décrit : {description_bruit}")
    if images:
        text_parts.append(f"({len(images)} photo(s) jointe(s) — analyse visuelle incluse)")

    user_text = "\n".join(text_parts)

    content = []
    for img in (images or []):
        content.append({
            "type": "image",
            "source": {
                "type": "base64",
                "media_type": img.get("type", "image/jpeg"),
                "data": img["data"],
            }
        })
    content.append({"type": "text", "text": user_text})

    message = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=1600,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": content}]
    )

    return next(block.text for block in message.content if block.type == "text")


PROMPT_PANNES = """Tu es un expert mécanicien. Réponds en français, de façon concise.

En fonction du modèle exact du véhicule et du kilométrage, liste les 4 pannes ou points de vigilance les plus fréquents et connus pour ce modèle à ce stade de vie.

Format obligatoire pour chaque point :

ICONE **NOM DU PROBLÈME**
Explication courte (1 phrase). Kilométrage critique si connu.

Utilise : 🔴 pour urgent/dangereux, 🟠 pour à surveiller, 🟢 pour entretien courant.

Pas d'introduction. Pas de numérotation. Commence directement par le premier point."""


def pannes_frequentes(vehicule: dict, kilometrage: str) -> str:
    label = vehicule.get("label") or f"{vehicule.get('marque', '')} {vehicule.get('modele', '')} {vehicule.get('version', '')}"
    energie = vehicule.get("energie", "—")
    date_mec = vehicule.get("date_mec", "—")

    user_message = f"""Véhicule : {label}
Énergie : {energie} | MEC : {date_mec}
Kilométrage actuel : {kilometrage}

Quelles sont les pannes fréquentes et points de vigilance connus pour ce modèle à ce kilométrage ?"""

    message = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=700,
        system=PROMPT_PANNES,
        messages=[{"role": "user", "content": user_message}]
    )

    return next(block.text for block in message.content if block.type == "text")
