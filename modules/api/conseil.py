import os
import anthropic
from dotenv import load_dotenv

load_dotenv()

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

SYSTEM_CONSEIL = """Tu es un expert mécanicien automobile de confiance. Réponds en français, de façon claire et accessible.

Tu réponds aux questions de suivi d'un client qui vient de recevoir un diagnostic sur son véhicule.
Aide-le à comprendre le problème, prioriser les réparations, estimer les coûts, ou répondre à toute autre question liée à son véhicule.

Sois direct, précis et bienveillant. Réponds de façon concise (3-6 phrases max sauf si plus de détails sont nécessaires)."""


def conseiller(vehicule: dict, diagnostic: str, historique: list, question: str) -> str:
    label = vehicule.get("label") or f"{vehicule.get('marque', '')} {vehicule.get('modele', '')} {vehicule.get('version', '')}"
    energie = vehicule.get("energie", "—")

    system = f"""{SYSTEM_CONSEIL}

Véhicule du client : {label} ({energie})

Diagnostic déjà fourni au client :
{diagnostic}"""

    messages = list(historique) + [{"role": "user", "content": question}]

    message = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=800,
        system=system,
        messages=messages
    )

    return next(block.text for block in message.content if block.type == "text")
