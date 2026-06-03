import os
import json
import re
import anthropic
from dotenv import load_dotenv

load_dotenv()

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

SYSTEM_HISTORIQUE = """Tu es un expert en analyse de véhicules d'occasion français. Pour le véhicule donné, génère un rapport historique complet.

Réponds UNIQUEMENT en JSON valide, sans markdown ni texte avant/après. Structure exacte :
{
  "score": {
    "valeur": 78,
    "label": "BON",
    "resume": "Phrase de synthèse sur l'état général du véhicule (1-2 phrases)."
  },
  "indicateurs": {
    "km_coherence": "NORMAL",
    "km_attendu": "80000-120000",
    "km_analyse": "Analyse courte de la cohérence kilométrique.",
    "proprietaires_estimes": "2-3",
    "proprietaires_analyse": "Explication courte.",
    "fiabilite_modele": "BONNE",
    "fiabilite_detail": "Explication courte sur la fiabilité générale de ce modèle."
  },
  "valeur_marche": {
    "fourchette": "12000-16000",
    "tendance": "STABLE",
    "detail": "Explication de la valorisation (1-2 phrases)."
  },
  "points_attention": [
    {
      "niveau": "eleve",
      "titre": "Titre court du point",
      "detail": "Explication en 1-2 phrases."
    }
  ],
  "historique_administratif": {
    "statut": "RAS",
    "detail": "Ce que l'on peut déduire des informations disponibles."
  },
  "verifications_physiques": [
    "Point à vérifier lors de l'inspection physique"
  ],
  "recommandations": [
    "Recommandation concrète pour l'acheteur"
  ]
}

Règles :
- score.valeur : entier entre 0 et 100
- score.label : EXCELLENT (85-100), BON (65-84), MOYEN (40-64), RISQUÉ (0-39)
- km_coherence : FAIBLE / NORMAL / ELEVE (par rapport à l'âge)
- fiabilite_modele : EXCELLENTE / BONNE / MOYENNE / MAUVAISE
- tendance valeur : HAUSSE / STABLE / BAISSE
- 3 à 5 points_attention avec niveaux "eleve", "moyen", "faible"
- 3 à 5 verifications_physiques
- 3 à 5 recommandations
- Toutes les analyses basées sur les données réelles du modèle, son âge, son kilométrage
- Sois précis et factuel — mentionne des défauts connus de ce modèle exact"""


def _appel_claude(user_message: str, max_tokens: int) -> str:
    message = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=max_tokens,
        system=SYSTEM_HISTORIQUE,
        messages=[{"role": "user", "content": user_message}]
    )
    return next(block.text for block in message.content if block.type == "text")


def _extraire_json(raw: str) -> dict:
    json_match = re.search(r'\{[\s\S]*\}', raw)
    if not json_match:
        raise ValueError("Aucun JSON trouvé dans la réponse")
    return json.loads(json_match.group())


def analyser_historique(vehicule: dict, kilometrage: str = "") -> dict:
    label = vehicule.get("label") or f"{vehicule.get('marque', '')} {vehicule.get('modele', '')} {vehicule.get('version', '')}".strip()
    energie = vehicule.get("energie", "—")
    puissance = vehicule.get("puissance_cv", "—")
    date_mec = vehicule.get("date_mec", "—")
    cylindree = vehicule.get("cylindree", "—")
    boite = vehicule.get("boite", "—")
    carrosserie = vehicule.get("carrosserie", "—")

    user_message = f"""Véhicule : {label}
Énergie : {energie} | Puissance : {puissance} ch | Boîte : {boite}
Cylindrée : {cylindree} cm³ | Carrosserie : {carrosserie}
Première mise en circulation : {date_mec}
Kilométrage déclaré : {kilometrage if kilometrage else 'non renseigné'}

Génère le rapport historique JSON complet pour ce véhicule."""

    try:
        raw = _appel_claude(user_message, max_tokens=2800)
        return _extraire_json(raw)
    except (json.JSONDecodeError, ValueError):
        raw = _appel_claude(user_message + "\n\nSois concis.", max_tokens=2000)
        return _extraire_json(raw)
