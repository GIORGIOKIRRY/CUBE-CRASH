extends Node
# Localizzazione minimale IT/EN in base alla lingua del DISPOSITIVO.
# L'italiano è la lingua sorgente: se il dispositivo non è in italiano si usa
# l'inglese; se una traduzione manca, si ricade sull'italiano (mai testo vuoto).

var _italian := true

func _ready() -> void:
	refresh()

func refresh() -> void:
	var l := OS.get_locale().to_lower()   # es. "it_it", "en_us"
	_italian = l.begins_with("it")

func is_italian() -> bool:
	return _italian

# Traduce una stringa italiana sorgente nella lingua del dispositivo.
func t(it: String) -> String:
	if _italian:
		return it
	return MAP.get(it, it)

# Traduce con parametri stile printf: L.tf("Nuove tra %dh", [ore])
func tf(it: String, args: Array) -> String:
	return t(it) % args

# --- Dizionario IT -> EN ---------------------------------------------------
const MAP := {
	# Deck
	"CUBE DECK": "CUBE DECK",
	"CUBO ROSSO": "RED CUBE",
	"CUBO BLU": "BLUE CUBE",
	"CUBO VERDE": "GREEN CUBE",
	"CUBO GIALLO": "YELLOW CUBE",
	"CUBO ARANCIO": "ORANGE CUBE",
	"CUBO VIOLA": "PURPLE CUBE",
	"CUBO ROSA": "PINK CUBE",
	"FRECCIA VERT.": "V. ARROW",
	"FRECCIA ORIZ.": "H. ARROW",
	"BOMBA": "BOMB",
	"BOMBA X": "X BOMB",
	"BOMBA ANGOLI": "CORNER BOMB",

	# Home / modalità
	"SCEGLI MODALITÀ": "SELECT MODE",
	"CLASSIC": "CLASSIC",
	"SPEEDRUN": "SPEEDRUN",
	"combo + bombe": "combos + bombs",
	"piu punti in 5 minuti": "most points in 5 minutes",
	"NOME GIOCATORE": "PLAYER NAME",
	"PLAYER": "PLAYER",
	"PROSSIMAMENTE": "COMING SOON",
	"IN ARRIVO": "COMING SOON",
	"TRA": "IN",
	"RISCOSSO": "CLAIMED",
	"BLOCCATO": "LOCKED",
	"IMMAGINE": "IMAGE",
	"EVENTI": "EVENTS",
	"GLOBAL RELEASE PACK": "GLOBAL RELEASE PACK",
	"FREE": "FREE",
	"Dimensioni griglia:": "Grid size:",
	"Il primo passo: rompi qualche cubo e prendici la mano!": "First step: smash some cubes and get the hang of it!",
	"Fai a pezzi tutti i cubi che puoi!": "Smash all the cubes you can!",
	"A caccia dei colori giusti!": "Hunt down the right colors!",
	"Corri, il tempo scappa via!": "Hurry, time is running out!",
	"Accumula più punti che riesci!": "Rack up as many points as you can!",
	"EDIT PROFILE": "EDIT PROFILE",
	"CONTROLLO...": "CHECKING...",
	"NOME GIA IN USO!": "NAME ALREADY TAKEN!",
	"TOP CRASHER": "TOP CRASHER",
	"È TUA!": "OWNED!",
	"IN USO": "IN USE",
	"USA": "USE",
	"CONTINUA?": "CONTINUE?",
	"Guarda una pubblicità\nper riprendere la partita": "Watch an ad\nto resume the game",
	"MORE": "MORE",

	# Nav / shop
	"SHOP": "SHOP",
	"NEGOZIO": "SHOP",
	"AVATAR": "AVATARS",
	"SKIN CUBI": "CUBE SKINS",
	"MONETE INSUFFICIENTI!": "NOT ENOUGH COINS!",
	"NUOVO SHOP TRA": "NEW SHOP IN",
	"ACQUISTO COMPLETATO!": "PURCHASE COMPLETE!",
	"ACQUISTO NON RIUSCITO": "PURCHASE FAILED",
	"monete insufficienti": "not enough coins",
	"MONETE": "COINS",

	# Missioni
	"MISSIONI": "MISSIONS",
	"SETTIMANALI": "WEEKLY",
	"GIORNALIERE": "DAILY",
	"RISCUOTI": "CLAIM",
	"FATTO": "DONE",
	"IN CORSO": "IN PROGRESS",
	"CHIUDI": "CLOSE",
	"Nuove tra %dh %dm": "New in %dh %dm",
	"Nuove missioni tra %dh %dm": "New missions in %dh %dm",

	# Settings
	"IMPOSTAZIONI": "SETTINGS",
	"SETTINGS": "SETTINGS",
	"MUSICA": "MUSIC",
	"SUONI": "SOUND",
	"VIBRAZIONE": "VIBRATION",
	"ALTRO": "MORE",
	"Contattaci": "Contact us",
	"Condividi il gioco": "Share the game",
	"Termini": "Terms",
	"Privacy": "Privacy",
	"Ringraziamenti": "Credits",
	"GRAZIE": "THANKS",
	"INDIETRO": "BACK",

	# Partita / game over
	"GAME OVER": "GAME OVER",
	"PUNTEGGIO": "SCORE",
	"RECORD": "RECORD",
	"NUOVO RECORD!": "NEW RECORD!",
	"BEST SCORE!": "BEST SCORE!",
	"GIOCA ANCORA": "PLAY AGAIN",
	"RIVIVI": "REVIVE",
	"NO SPACE": "NO SPACE",
	"NO MOVES": "NO MOVES",
	"MOSSE": "MOVES",
	"COMBO:": "COMBO:",
	"USCIRE DALLA PARTITA?": "QUIT THE GAME?",
	"Ci sono ancora mosse possibili!": "There are still moves left!",
	"RESTA": "STAY",
	"ESCI": "QUIT",

	# Loading
	"CARICAMENTO": "LOADING",
	"CARICAMENTO...": "LOADING...",

	# Popup info cubo
	"CUBE INFO": "CUBE INFO",
	"TIPO:": "TYPE:",
	"CLASSICO": "CLASSIC",
	"ABILITA": "ABILITY",
	"ESPLOSIVO": "EXPLOSIVE",
	"SKIN": "SKINS",
	"Rosso, quadrato e senza fronzoli. Nessun potere speciale: solo una gran voglia di essere abbinato.": "Red, square and no frills. No special powers: just a burning desire to be matched.",
	"Arancione come un tramonto, utile come... un altro cubo. Fa numero, e lo fa benissimo.": "Orange like a sunset, useful like... another cube. It makes up the numbers, and does it perfectly.",
	"Giallo acceso, personalita spenta. Non illumina la stanza, ma riempie la griglia.": "Bright yellow, dim personality. It won't light up the room, but it fills the grid.",
	"Verde speranza: spera sempre che tu lo abbini in tempo. Nessun superpotere, tanta pazienza.": "Hopeful green: always hoping you'll match it in time. No superpowers, lots of patience.",
	"Blu come il lunedi. Fa il suo dovere senza lamentarsi (troppo).": "Blue like a Monday. Does its job without complaining (too much).",
	"Viola misterioso... ma il mistero e che non fa niente di speciale. Elegante, pero.": "Mysterious purple... but the mystery is it does nothing special. Elegant, though.",
	"Rosa e fiero. Sembra tenero, ma sa il fatto suo quando si tratta di combo.": "Pink and proud. Looks cute, but knows its stuff when it comes to combos.",
	"Distrugge tutta la COLONNA in cui si trova. Verticale e senza pieta.": "Destroys the entire COLUMN it sits in. Vertical and merciless.",
	"Spazza via l'intera RIGA. Orizzontale e implacabile.": "Wipes out the entire ROW. Horizontal and relentless.",
	"Esplode e distrugge i cubi tutt'intorno (3x3). Boom!": "Explodes and destroys the cubes all around (3x3). Boom!",
	"Esplode lungo le due diagonali, a forma di X.": "Explodes along both diagonals, in an X shape.",
	"Colpisce i quattro angoli dell'area. Sorpresa!": "Hits the four corners of the area. Surprise!",
	"TEST": "TEST",
	"sperimentale, bombe swap": "experimental, swap bombs",
	"TEST 6": "TEST 6",
	"classica, 4 colori": "classic, 4 colors",
	"OK": "OK",

	# --- Ringraziamenti / OG / Creator (sottopagine More) ---
	"Un grazie speciale a tutti gli iscritti al canale che hanno supportato questo progetto fin dal primo giorno. Avete reso possibile Cube Crash. ❤️": "A special thank you to everyone subscribed to the channel who has supported this project since day one. You made Cube Crash possible. ❤️",
	"Vuoi il tuo nome qui? Premi il tasto e seguimi!": "Want your name here? Tap the button and follow me!",
	"Una volta aggiunto alla lista OG sblocchi il tag [OG] accanto al nome e l'icona profilo OG esclusiva! 👑": "Once you're added to the OG list you unlock the [OG] tag next to your name and the exclusive OG profile icon! 👑",
	"Per essere aggiunto devi seguirci: verificheremo l'iscrizione.\nInvia il tuo nome utente:": "To be added you must follow us: we'll verify it.\nSend your username:",
	"Il tuo nome (o @instagram)": "Your name (or @instagram)",
	"Nome inviato! ❤️": "Name sent! ❤️",
	"Scrivi il tuo nome.": "Type your name.",
	"Invio...": "Sending...",
	"Riprova più tardi.": "Try again later.",

	"Vuoi diventare un Content Creator ufficiale di Cube Crash?\nManda il modulo di verifica 🎬": "Want to become an official Cube Crash Content Creator?\nSend the verification form 🎬",
	"Nome + link del tuo canale": "Name + your channel link",
	"Per diventare Cube Crash Creator devi aver fatto almeno 3 video sul gioco. Ti accetteremo come CubeCrash Creator e otterrai un'ICONA PROFILO ESCLUSIVA! 🏆": "To become a Cube Crash Creator you must have made at least 3 videos about the game. We'll accept you as a CubeCrash Creator and you'll get an EXCLUSIVE PROFILE ICON! 🏆",
	"Scrivi nome e canale.": "Enter name and channel.",
	"Richiesta inviata! Ti ricontatteremo ❤️": "Request sent! We'll get back to you ❤️",

	"HighScore:": "High Score:",

	# --- More / sottopagine (titoli) ---
	"NOVITÀ": "WHAT'S NEW",
	"CREATOR": "CREATOR",
	"THANKS": "THANKS",
	"TERMS OF SERVICE": "TERMS OF SERVICE",
	"PRIVACY POLICY": "PRIVACY POLICY",

	# --- Modalità STORIA / campagna ---
	"STORIA": "STORY",
	"campagna a livelli": "level campaign",
	"LIVELLO": "LEVEL",
	"MISSIONE": "MISSION",
	"GIOCA": "PLAY",
	"MAPPA": "MAP",
	"LIVELLO BLOCCATO": "LEVEL LOCKED",
	"LIVELLO COMPLETATO!": "LEVEL COMPLETE!",
	"Griglia": "Grid",
	"colori": "colors",
	"Distruggi": "Destroy",
	"Raggiungi": "Reach",
	"cubi": "cubes",
	"punti": "points",
	"punti in": "points in",
	"max": "max",
	"Cubi": "Cubes",
	"rossi": "red",
	"verdi": "green",
	"gialli": "yellow",
	"Rossi": "Red",
	"Verdi": "Green",
	"Gialli": "Yellow",
	"NUOVA STAGIONE": "NEW SEASON",

	# --- Missioni (descrizioni) ---
	"Raggiungi %s punti in una partita": "Reach %s points in one game",
	"Rompi %s cubi %s": "Break %s %s cubes",
	"Rompi %s cubi in totale": "Break %s cubes in total",
	"Fai una COMBO %d": "Make a COMBO %d",
	"Gioca %d partite": "Play %d games",
	"Entra ogni giorno per %d giorni": "Log in every day for %d days",
	"Fai %s punti in CLASSIC": "Score %s points in CLASSIC",
	"Hai giocato alla versione BETA di Cube Crash!": "You played the BETA version of Cube Crash!",
	"BLU": "BLUE", "ROSSI": "RED", "GIALLI": "YELLOW", "VERDI": "GREEN",
	"VIOLA": "PURPLE", "ARANCIONI": "ORANGE", "ROSA": "PINK",

	# --- Tutorial ---
	"FRECCE\nDistruggono una colonna o una riga": "ARROWS\nDestroy a column or a row",
	"Freccia VERTICALE\ndistrugge tutta la colonna": "VERTICAL arrow\ndestroys the whole column",
	"Freccia ORIZZONTALE\ndistrugge tutta la riga": "HORIZONTAL arrow\ndestroys the whole row",
	"BOMBA\nDistrugge i cubi tutt'intorno": "BOMB\nDestroys the cubes all around",
	"BOMBA\nesplosione 3x3": "BOMB\n3x3 explosion",
	"BOMBA X\nDistrugge lungo le diagonali": "X BOMB\nDestroys along the diagonals",
	"BOMBA X\nesplode a forma di X": "X BOMB\nexplodes in an X shape",
	"BOMBA ANGOLI\nColpisce i quattro angoli": "CORNER BOMB\nHits the four corners",
	"BOMBA ANGOLI\ncolpisce i quattro angoli": "CORNER BOMB\nhits the four corners",
	"Trascina il cubo ROSSO in mezzo agli altri due": "Drag the RED cube between the other two",
	"Ora SCORRI col dito: scambia i 2 cubi al centro": "Now SWIPE with your finger: swap the 2 middle cubes",
	"Hai fatto una COMBO!\nPiu match di fila o insieme = tanti punti extra": "You made a COMBO!\nMore matches in a row or together = lots of extra points",
	"Sei pronto!  Buona partita!": "You're ready!  Have fun!",

	# --- Varie (contatori, timer, stats, popup) ---
	"monete": "coins",
	"mosse": "moves",
	"pose": "placed",
	"pt": "pts",
	"Nuova classifica tra: %dg %02dh": "New leaderboard in: %dd %02dh",
	"Nuove missioni disponibili tra: %dg %02dh": "New missions in: %dd %02dh",
	"Nuove missioni disponibili tra: %dh %02dm": "New missions in: %dh %02dm",
	"+%d  (%d mosse)": "+%d  (%d moves)",
	"Ciao team Cube Crash,": "Hi Cube Crash team,",
	"Tu": "You",
}
