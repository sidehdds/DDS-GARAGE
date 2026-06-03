import requests

API_KEY = "19a4798f63msh47ce76b4e9c68c9p12b521jsnfdc2f720327a"
URL = "https://api-de-plaque-d-immatriculation-france.p.rapidapi.com/"


def rechercher_plaque(plaque: str) -> dict:
    headers = {
        "x-rapidapi-key": API_KEY,
        "x-rapidapi-host": "api-de-plaque-d-immatriculation-france.p.rapidapi.com",
        "Content-Type": "application/json"
    }
    try:
        response = requests.get(URL, headers=headers, params={"plaque": plaque}, timeout=10)
        response.raise_for_status()
        body = response.json()

        if body.get("error") or body.get("code") != 200:
            return {"error": body.get("message", "Plaque introuvable")}

        data = body.get("data", {})
        return normaliser_donnees(data)

    except requests.exceptions.Timeout:
        return {"error": "Timeout API"}
    except requests.exceptions.HTTPError as e:
        return {"error": f"Erreur HTTP {e.response.status_code}"}
    except Exception as e:
        return {"error": str(e)}


def normaliser_donnees(data: dict) -> dict:
    if not data or not isinstance(data, dict):
        return {}

    def val(v):
        if v in (None, "", "0", 0, "INCONNU"):
            return "—"
        return str(v)

    cylindree = data.get("AWN_cylindre_capacite")
    co2 = data.get("AWN_emission_co_2")

    return {
        "label":        val(data.get("AWN_label")),
        "marque":       val(data.get("AWN_marque")),
        "modele":       val(data.get("AWN_modele")),
        "version":      val(data.get("AWN_version")),
        "energie":      val(data.get("AWN_energie")),
        "date_mec":     val(data.get("AWN_date_mise_en_circulation")),
        "puissance_cv": val(data.get("AWN_puissance_chevaux")),
        "puissance_kw": val(data.get("AWN_puissance_KW")),
        "cylindree":    val(cylindree),
        "boite":        val(data.get("AWN_type_boite_vites")),
        "carrosserie":  val(data.get("AWN_style_carrosserie") or data.get("AWN_carrosserie")),
        "couleur":      val(data.get("AWN_couleur")),
        "nb_places":    val(data.get("AWN_nbr_de_places")),
        "nb_portes":    val(data.get("AWN_nbr_portes")),
        "co2":          val(co2),
        "raw":          data
    }
