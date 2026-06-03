import os
import json
import re
import anthropic
from dotenv import load_dotenv

load_dotenv()

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

SYSTEM_TUNING = """Tu es un expert tuning automobile. Pour le véhicule donné, génère des recommandations de tuning personnalisées.

Réponds UNIQUEMENT en JSON valide, sans markdown ni texte avant/après. Structure exacte :
{
  "pieces": [
    {
      "categorie": "echappement",
      "nom": "nom court du produit",
      "marques": ["Marque1", "Marque2"],
      "description": "description 1 phrase précise adaptée au moteur exact",
      "recherche": "termes Google précis incluant marque+modèle+motorisation exacts"
    }
  ],
  "reprog": {
    "puissance_origine": 150,
    "couple_origine": 240,
    "note": "",
    "stages": [
      {
        "numero": 1,
        "puissance_apres": "175-185",
        "couple_apres": "280-300",
        "description": "description technique courte (1 phrase)",
        "prix": "350-450",
        "mods_requises": "Aucune"
      },
      {
        "numero": 2,
        "puissance_apres": "...",
        "couple_apres": "...",
        "description": "...",
        "prix": "...",
        "mods_requises": "..."
      },
      {
        "numero": 3,
        "puissance_apres": "...",
        "couple_apres": "...",
        "description": "...",
        "prix": "...",
        "mods_requises": "..."
      }
    ]
  }
}

Règles :
- Catégories possibles : echappement, admission, suspension, freins, jantes, moteur
- 2 pièces par catégorie, 5 catégories minimum
- "recherche" doit inclure la marque, modèle et motorisation EXACTE du véhicule (ex: "Milltek échappement Peugeot 308 GTI 270ch THP")
- Toujours 3 stages (1, 2, 3)
- Puissances et couples basés sur les valeurs réelles du moteur
- Si moteur atmosphérique (non turbo) : gains Stage 1 limités (+5-10%), note-le dans "note"
- Si diesel : adapte les recommandations pièces (pas de kit admission carb, mais filtre à particules, etc.)"""


def _appel_claude(user_message: str, max_tokens: int) -> str:
    message = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=max_tokens,
        system=SYSTEM_TUNING,
        messages=[{"role": "user", "content": user_message}]
    )
    return next(block.text for block in message.content if block.type == "text")


def _extraire_json(raw: str) -> dict:
    json_match = re.search(r'\{[\s\S]*\}', raw)
    if not json_match:
        raise ValueError("Aucun JSON trouvé dans la réponse")
    return json.loads(json_match.group())


def analyser_tuning(vehicule: dict) -> dict:
    label = vehicule.get("label") or f"{vehicule.get('marque', '')} {vehicule.get('modele', '')} {vehicule.get('version', '')}".strip()
    energie = vehicule.get("energie", "—")
    puissance = vehicule.get("puissance_cv", "—")
    date_mec = vehicule.get("date_mec", "—")
    cylindree = vehicule.get("cylindree", "—")

    user_message = f"""Véhicule : {label}
Énergie : {energie} | Puissance : {puissance} ch | Cylindrée : {cylindree} cm³ | MEC : {date_mec}

Génère exactement 10 pièces (2 par catégorie, 5 catégories) et 3 stages. JSON valide uniquement."""

    # Premier essai avec tokens suffisants
    try:
        raw = _appel_claude(user_message, max_tokens=3200)
        return _extraire_json(raw)
    except (json.JSONDecodeError, ValueError):
        pass

    # Retry avec prompt plus court (moins de pièces)
    user_message_court = f"""Véhicule : {label}
Énergie : {energie} | Puissance : {puissance} ch | MEC : {date_mec}

Génère exactement 6 pièces (1 par catégorie) et 3 stages. JSON court et valide uniquement."""

    raw = _appel_claude(user_message_court, max_tokens=2000)
    return _extraire_json(raw)
