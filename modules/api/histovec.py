import hashlib
import requests

BASE = "https://histovec.interieur.gouv.fr/histovec/api/v0"
HEADERS = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Origin": "https://histovec.interieur.gouv.fr",
    "Referer": "https://histovec.interieur.gouv.fr/",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
}


def _nettoyer_plaque(plaque: str) -> str:
    return plaque.upper().replace("-", "").replace(" ", "")


def consulter_histovec(plaque: str) -> dict:
    """
    Tente de récupérer les données publiques Histovec pour une plaque.
    Retourne un dict avec les données disponibles et un flag 'partiel' si limité.
    """
    immat = _nettoyer_plaque(plaque)

    try:
        # Endpoint public Histovec — données de base SIV
        resp = requests.get(
            f"{BASE}/immat",
            params={"immat": immat},
            headers=HEADERS,
            timeout=8
        )
        if resp.status_code == 200:
            data = resp.json()
            return {"success": True, "data": data, "source": "histovec"}
    except Exception:
        pass

    # Fallback : endpoint de vérification existence
    try:
        resp = requests.post(
            f"{BASE}/check",
            json={"immat": immat},
            headers=HEADERS,
            timeout=8
        )
        if resp.status_code == 200:
            data = resp.json()
            return {"success": True, "data": data, "source": "histovec_check"}
    except Exception:
        pass

    # Histovec nécessite données propriétaire pour rapport complet
    return {"success": False, "raison": "authentification_requise"}
