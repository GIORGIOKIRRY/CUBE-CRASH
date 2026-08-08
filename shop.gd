extends Node

# ============================================================
# Autoload "shop" — negozio di Cube Crash (DRAFT/placeholder).
# Si comprano con le MONETE (missions.coins): AVATAR (placeholder colorati) e
# SKIN dei cubi. Possesso + equipaggiati persistiti in user://shop.dat.
# NB: per ora avatar/skin sono colori placeholder; l'applicazione visiva
# (avatar sul profilo, skin sui cubi in partita) verrà agganciata dopo.
# ============================================================

const SAVE := "user://shop.dat"

# Avatar placeholder: id, colore, prezzo (0 = di base, gratis)
const AVATARS := [
	{"id": "av_default", "color": Color(0.36, 0.75, 1.00), "price": 0},
	{"id": "av_red",     "color": Color(0.95, 0.35, 0.35), "price": 150},
	{"id": "av_green",   "color": Color(0.40, 0.85, 0.45), "price": 150},
	{"id": "av_purple",  "color": Color(0.70, 0.45, 0.95), "price": 250},
	{"id": "av_orange",  "color": Color(1.00, 0.60, 0.20), "price": 250},
	{"id": "av_pink",    "color": Color(1.00, 0.50, 0.80), "price": 400},
]

# Skin cubi placeholder: id, colore, prezzo
const SKINS := [
	{"id": "sk_classic", "color": Color(0.36, 0.75, 1.00), "price": 0},
	{"id": "sk_neon",    "color": Color(0.10, 1.00, 0.60), "price": 300},
	{"id": "sk_lava",    "color": Color(1.00, 0.35, 0.10), "price": 300},
	{"id": "sk_gold",    "color": Color(1.00, 0.82, 0.20), "price": 600},
	{"id": "sk_ice",     "color": Color(0.60, 0.90, 1.00), "price": 600},
]

var owned_avatars: Dictionary = {"av_default": true}
var owned_skins: Dictionary = {"sk_classic": true}
var equipped_avatar: String = "av_default"
var equipped_skin: String = "sk_classic"

func _ready() -> void:
	_load()

func owns_avatar(id: String) -> bool:
	return bool(owned_avatars.get(id, false))

func owns_skin(id: String) -> bool:
	return bool(owned_skins.get(id, false))

func _price(list: Array, id: String) -> int:
	for it in list:
		if str(it["id"]) == id:
			return int(it["price"])
	return 0

func color_of_avatar(id: String) -> Color:
	for it in AVATARS:
		if str(it["id"]) == id:
			return it["color"]
	return Color(0.5, 0.5, 0.5)

func color_of_skin(id: String) -> Color:
	for it in SKINS:
		if str(it["id"]) == id:
			return it["color"]
	return Color(0.5, 0.5, 0.5)

# Compra un avatar: scala le monete e lo sblocca. Ritorna true se comprato.
func buy_avatar(id: String) -> bool:
	if owns_avatar(id):
		return false
	if not missions.spend_coins(_price(AVATARS, id)):
		return false
	owned_avatars[id] = true
	_save()
	return true

func buy_skin(id: String) -> bool:
	if owns_skin(id):
		return false
	if not missions.spend_coins(_price(SKINS, id)):
		return false
	owned_skins[id] = true
	_save()
	return true

func equip_avatar(id: String) -> void:
	if owns_avatar(id):
		equipped_avatar = id
		_save()

func equip_skin(id: String) -> void:
	if owns_skin(id):
		equipped_skin = id
		_save()

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("shop", "owned_avatars", owned_avatars)
	cfg.set_value("shop", "owned_skins", owned_skins)
	cfg.set_value("shop", "equipped_avatar", equipped_avatar)
	cfg.set_value("shop", "equipped_skin", equipped_skin)
	cfg.save(SAVE)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) != OK:
		return
	owned_avatars = cfg.get_value("shop", "owned_avatars", owned_avatars)
	owned_skins = cfg.get_value("shop", "owned_skins", owned_skins)
	equipped_avatar = str(cfg.get_value("shop", "equipped_avatar", equipped_avatar))
	equipped_skin = str(cfg.get_value("shop", "equipped_skin", equipped_skin))
	# garantisci sempre il possesso dei default
	owned_avatars["av_default"] = true
	owned_skins["sk_classic"] = true
