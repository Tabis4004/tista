#!/usr/bin/env python3
"""Route la lecture de carte vers le bon terminal (Wiseasy ou CS10).

Avant : `LogicPowerOn` et `LogicCardDispatcher` appelaient toujours le SDK
Vanstone (CS10), donc la vente par carte échouait sur tout autre matériel —
d'où le « Erreur de lecture » observé sur un téléphone ordinaire.

Après : on tente d'abord Wiseasy, et on retombe sur le CS10 si le SDK Wiseasy
n'est pas présent. La détection est faite par capacité, pas par nom de modèle :
on ne dépend d'aucune chaîne `Build.MODEL` qu'on ne connaît pas.

Chaque remplacement est ancré sur un extrait exact ; le script échoue
bruyamment si le fichier a changé entre-temps.
"""
import sys
import pathlib

SRC = pathlib.Path(sys.argv[1])
DST = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else SRC

code = SRC.read_text(encoding="utf-8")
applied = []


def sub(label, old, new):
    global code
    if old not in code:
        raise SystemExit(f"ANCRAGE INTROUVABLE : {label}\n---\n{old[:400]}\n---")
    if code.count(old) != 1:
        raise SystemExit(f"ANCRAGE AMBIGU : {label} ({code.count(old)} occurrences)")
    code = code.replace(old, new, 1)
    applied.append(label)


# ---------------------------------------------------------------------------
# 1. Déclaration du module Wiseasy
# ---------------------------------------------------------------------------
sub(
    "champ cardWiseasy",
    """    private static PrinterModuleRego printerModuleRego;
    private static PrinterModuleBleu printerModuleBleu;""",
    """    private static PrinterModuleRego printerModuleRego;
    private static PrinterModuleBleu printerModuleBleu;
    /** Lecteur de carte des terminaux Wiseasy (P3, WPOS). Null hors Wiseasy. */
    private static CardModuleWiseasy cardWiseasy;""",
)

# ---------------------------------------------------------------------------
# 2. Instanciation
# ---------------------------------------------------------------------------
sub(
    "instanciation",
    """        printerModuleBleu = new PrinterModuleBleu(getApplicationContext());
    }""",
    """        printerModuleBleu = new PrinterModuleBleu(getApplicationContext());
        cardWiseasy = new CardModuleWiseasy(getApplicationContext());
        Log.i("Terminal", "Lecteur Wiseasy disponible : " + cardWiseasy.isAvailable());
    }""",
)

# ---------------------------------------------------------------------------
# 3. Routage de la mise sous tension
# ---------------------------------------------------------------------------
sub(
    "LogicPowerOn",
    """                else if (call.method.equals("LogicPowerOn")) {
                    final int i = printerModule.logicPowerOn();
                    result.success(i);
                } else if (call.method.equals("LogicCardDispatcher")) {
                    String contenu = call.argument("contenu");
                    boolean writing = call.argument("writing");
                    final String str = printerModule.logicCardDispatcher(writing, contenu);
                    result.success(str);
                }""",
    """                else if (call.method.equals("LogicPowerOn")) {
                    // Wiseasy d'abord ; si son SDK est absent, on retombe sur
                    // le CS10. Aucune dépendance à un nom de modèle.
                    int i;
                    if (cardWiseasy != null && cardWiseasy.isAvailable()) {
                        i = cardWiseasy.powerOn();
                        if (i == CardModuleWiseasy.UNAVAILABLE) {
                            i = printerModule.logicPowerOn();
                        }
                    } else {
                        i = printerModule.logicPowerOn();
                    }
                    result.success(i);
                } else if (call.method.equals("LogicCardDispatcher")) {
                    String contenu = call.argument("contenu");
                    boolean writing = call.argument("writing");
                    final String str;
                    if (cardWiseasy != null && cardWiseasy.isAvailable()) {
                        str = writing ? cardWiseasy.write(contenu) : cardWiseasy.read();
                        cardWiseasy.powerOff();
                    } else {
                        str = printerModule.logicCardDispatcher(writing, contenu);
                    }
                    result.success(str);
                } else if (call.method.equals("terminalInfo")) {
                    // Diagnostic : quel matériel l'app croit-elle avoir sous la main ?
                    java.util.Map<String, Object> info = new java.util.HashMap<>();
                    info.put("manufacturer", android.os.Build.MANUFACTURER);
                    info.put("brand", android.os.Build.BRAND);
                    info.put("model", android.os.Build.MODEL);
                    info.put("device", android.os.Build.DEVICE);
                    info.put("wiseasy", cardWiseasy != null && cardWiseasy.isAvailable());
                    result.success(info);
                }""",
)

DST.parent.mkdir(parents=True, exist_ok=True)
DST.write_text(code, encoding="utf-8")
print(f"{len(applied)} remplacements appliqués :")
for a in applied:
    print(f"  - {a}")
print(f"\nÉcrit dans {DST}")
