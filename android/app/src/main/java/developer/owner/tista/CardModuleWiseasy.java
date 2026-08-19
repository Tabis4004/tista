package developer.owner.tista;

import android.content.Context;
import android.util.Log;

import wangpos.sdk4.libbasebinder.BankCard;

/**
 * Lecture / écriture des cartes carburant sur terminal Wiseasy (P3, WPOS...).
 *
 * <p>Équivalent fonctionnel de {@code PrinterModule.logicCardDispatcher()}, qui
 * pilote le lecteur des terminaux CS10 (SDK Vanstone {@code vpos.apipackage}).
 *
 * <p><b>Format de carte identique</b> — c'est le point important. Le CS10
 * construit lui-même les APDU ISO 7816 vers une carte à mémoire SLE4442 :
 *
 * <pre>
 *   SELECT  FF A4 00 00 01 06        -> 90 00
 *   VERIFY  FF 20 00 00 03 FF FF FF  -> 90 07
 *   READ    FF B0 00 00 64           -> 100 octets depuis l'adresse 0
 *   WRITE   FF D0 00 00 len data
 * </pre>
 *
 * Le SDK Wiseasy expose ces mêmes opérations à un niveau plus haut
 * ({@code VerifyLogicCardPwd}, {@code ReadLogicCardData},
 * {@code WriteLogicCardData}), donc pas d'APDU à assembler. Adresse, longueur
 * et mot de passe sont repris à l'identique : <b>une carte gravée sur un CS10
 * reste lisible sur un P3, et réciproquement.</b>
 *
 * <p>La valeur renvoyée par {@link #read()} est une chaîne hexadécimale, comme
 * côté CS10. C'est ce qui permet au Dart de découper sur « AAA » sans rien
 * changer : les identifiants sont numériques et « A » est un chiffre
 * hexadécimal, donc le séparateur survit à l'encodage.
 */
public class CardModuleWiseasy {

    private static final String TAG = "CardWiseasy";

    /** Mot de passe (PSC) de la carte à mémoire — identique au CS10. */
    private static final byte[] PSC = new byte[]{(byte) 0xFF, (byte) 0xFF, (byte) 0xFF};

    /** Adresse et longueur de lecture — identiques au CS10 (0x64 = 100 octets). */
    private static final int READ_ADDRESS = 0;
    private static final int READ_LENGTH = 0x64;

    /** Codes de retour alignés sur ceux que le Dart teste déjà. */
    public static final int OK = 0;
    public static final int NO_CARD = -2043;
    public static final int UNAVAILABLE = -1;

    private final BankCard bankCard;
    private volatile boolean available = true;

    public CardModuleWiseasy(Context context) {
        BankCard bc = null;
        try {
            bc = new BankCard(context);
        } catch (Throwable t) {
            // Le service Wiseasy n'existe pas sur cet appareil : ce n'est pas
            // un terminal Wiseasy. On le note et on laisse la main au CS10.
            Log.w(TAG, "SDK Wiseasy indisponible : " + t);
            available = false;
        }
        this.bankCard = bc;
    }

    /** {@code true} tant que le SDK Wiseasy répond sur cet appareil. */
    public boolean isAvailable() {
        return available && bankCard != null;
    }

    /**
     * Met le lecteur sous tension et vérifie qu'une carte est présente.
     *
     * @return {@link #OK}, {@link #NO_CARD} si le connecteur est vide,
     *         {@link #UNAVAILABLE} si le SDK ne répond pas.
     */
    public synchronized int powerOn() {
        if (!isAvailable()) {
            return UNAVAILABLE;
        }
        try {
            int ret = bankCard.openCloseCardReader(
                    BankCard.CARD_MODE_ICC, BankCard.CARD_READ_OPEN);
            Log.i(TAG, "openCloseCardReader -> " + ret);
            if (ret != 0) {
                return ret;
            }

            // CardActivation renvoie l'ATR ; un échec ici = pas de carte insérée.
            byte[] atr = new byte[64];
            int[] atrLen = new int[1];
            ret = bankCard.CardActivation(atr, atrLen);
            Log.i(TAG, "CardActivation -> " + ret + " atrLen=" + atrLen[0]);
            if (ret != 0) {
                return NO_CARD;
            }
            return OK;
        } catch (Throwable t) {
            Log.e(TAG, "powerOn", t);
            available = false;
            return UNAVAILABLE;
        }
    }

    /** Coupe l'alimentation du lecteur. À appeler après chaque opération. */
    public synchronized void powerOff() {
        if (!isAvailable()) {
            return;
        }
        try {
            bankCard.openCloseCardReader(
                    BankCard.CARD_MODE_ICC, BankCard.CARD_READ_CLOSE);
        } catch (Throwable t) {
            Log.w(TAG, "powerOff", t);
        }
    }

    /**
     * Lit la carte et renvoie son contenu en hexadécimal.
     *
     * @return le contenu, ou un code d'erreur textuel déjà géré par le Dart
     *         ({@code CARD_CHECK_FAILED}, {@code ERROR}...).
     */
    public synchronized String read() {
        if (!isAvailable()) {
            return "ERROR";
        }
        try {
            byte[] data = new byte[512];
            int[] outLen = new int[1];

            int ret = bankCard.ReadLogicCardData(READ_ADDRESS, READ_LENGTH, data, outLen);
            Log.i(TAG, "ReadLogicCardData -> " + ret + " len=" + outLen[0]);
            if (ret != 0) {
                return "CARD_CHECK_FAILED";
            }
            return toHex(data, outLen[0]);
        } catch (Throwable t) {
            Log.e(TAG, "read", t);
            return "ERROR";
        }
    }

    /**
     * Grave le contenu sur la carte.
     *
     * @param contenuHex chaîne hexadécimale, au format écrit par le CS10
     *                   (« AAA&lt;idClient&gt;AAA&lt;idCarte&gt;AAA »).
     * @return {@code "0"} si l'écriture a réussi, sinon un code d'erreur.
     */
    public synchronized String write(String contenuHex) {
        if (!isAvailable()) {
            return "ERROR";
        }
        try {
            // Le mot de passe n'est exigé que pour l'écriture, comme sur CS10.
            int ret = bankCard.VerifyLogicCardPwd(PSC);
            Log.i(TAG, "VerifyLogicCardPwd -> " + ret);
            if (ret != 0) {
                return "RSP_FAILED";
            }

            byte[] data = hexToBytes(contenuHex);
            if (data.length == 0) {
                return "ERROR";
            }

            byte[] status = new byte[4];
            ret = bankCard.WriteLogicCardData(data, READ_ADDRESS, data.length, status);
            Log.i(TAG, "WriteLogicCardData -> " + ret + " len=" + data.length);
            return ret == 0 ? "0" : "CARD_CHECK_FAILED";
        } catch (Throwable t) {
            Log.e(TAG, "write", t);
            return "ERROR";
        }
    }

    // ------------------------------------------------------------------
    // Conversions hexadécimales (mêmes règles que ByteUtil côté Vanstone)
    // ------------------------------------------------------------------

    private static String toHex(byte[] data, int length) {
        if (length <= 0 || length > data.length) {
            length = data.length;
        }
        StringBuilder sb = new StringBuilder(length * 2);
        for (int i = 0; i < length; i++) {
            sb.append(String.format("%02X", data[i]));
        }
        return sb.toString();
    }

    private static byte[] hexToBytes(String hex) {
        if (hex == null) {
            return new byte[0];
        }
        String clean = hex.trim().replaceAll("[^0-9A-Fa-f]", "");
        if (clean.length() % 2 != 0) {
            // Longueur impaire : on complète pour ne pas tronquer le dernier
            // demi-octet, le CS10 se comporte de la même façon.
            clean = clean + "0";
        }
        byte[] out = new byte[clean.length() / 2];
        for (int i = 0; i < out.length; i++) {
            out[i] = (byte) Integer.parseInt(clean.substring(i * 2, i * 2 + 2), 16);
        }
        return out;
    }
}
