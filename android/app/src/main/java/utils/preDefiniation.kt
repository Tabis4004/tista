/**
 * FILE: preDefiniation.java
 */
package utils

class preDefiniation {
    /**
     * text align type
     * @author Administrator
     */
    enum class AlignType(val value: Int) {
        /**
         * align left
         */
        AT_LEFT(0),

        /**
         * align center
         */
        AT_CENTER(1),

        /**
         * align right
         */
        AT_RIGHT(2);

        companion object {
            fun getEnum(value: Int): AlignType? {
                var at: AlignType? = null
                when (value) {
                    0 -> at = AT_LEFT
                    1 -> at = AT_CENTER
                    2 -> at = AT_RIGHT
                }
                return at
            }
        }
    }

    /**
     * vertical align type
     */
    enum class ValignType(val value: Int) {
        /**
         * top align
         */
        VT_TOP(0),

        /**
         * middle align
         */
        VT_MIDDLE(1),

        /**
         * bottom align
         */
        VT_BOTTOM(2);

        companion object {
            fun getEnum(value: Int): ValignType? {
                var vt: ValignType? = null
                when (value) {
                    0 -> vt = VT_TOP
                    1 -> vt = VT_MIDDLE
                    2 -> vt = VT_BOTTOM
                }
                return vt
            }
        }
    }

    /**
     * barcode type, include 1d barcode and 2d barcode
     * @author Administrator
     */
    enum class BarcodeType(val value: Int) {
        /**
         * UPC-A barcode
         */
        BT_UPCA(65),

        /**
         * UPC-E barcode
         */
        BT_UPCE(66),

        /**
         * EAN13/JAN13 barcode
         */
        BT_EAN13(67),

        /**
         * EAN8/JAN8 barcode
         */
        BT_EAN8(68),

        /**
         * CODE39 barcode
         */
        BT_CODE39(69),

        /**
         * ITF barcode
         */
        BT_CODEITF(70),

        /**
         * codabar barcode
         */
        BT_CODEBAR(71),

        /**
         * code93 barcode
         */
        BT_CODE93(72),

        /**
         * code128 barcode
         */
        BT_CODE128(73),

        /**
         * 2D PDF417 barcode
         */
        BT_PDF417(0),

        /**
         * 2D QR barcode
         */
        BT_QRcode(2),

        /**
         * Data Matic barcode
         */
        BT_DATAMATIC(1);

        companion object {
            fun getEnum(value: Int): BarcodeType? {
                var bt: BarcodeType? = null
                when (value) {
                    65 -> bt = BT_UPCA
                    66 -> bt = BT_UPCE
                    67 -> bt = BT_EAN13
                    68 -> bt = BT_EAN8
                    69 -> bt = BT_CODE39
                    70 -> bt = BT_CODEITF
                    71 -> bt = BT_CODEBAR
                    72 -> bt = BT_CODE93
                    73 -> bt = BT_CODE128
                    0 -> bt = BT_PDF417
                    1 -> bt = BT_DATAMATIC
                    2 -> bt = BT_QRcode
                }
                return bt
            }
        }
    }

    /**
     * Graphic rotate rangles
     * @author Administrator
     */
    enum class RotatAngle(val value: Int) {
        /**
         * none
         */
        RA_0(0),

        /**
         * rotate 90 angle
         */
        RA_90(90),

        /**
         * rotate 180 angle
         */
        RA_180(180),

        /**
         * rotate 270 angle
         */
        RA_270(270);

        companion object {
            fun getEnum(value: Int): RotatAngle {
                var ra: RotatAngle? = null
                ra = when (value) {
                    0 -> RA_0
                    90 -> RA_90
                    180 -> RA_90
                    270 -> RA_90
                    else -> RA_90
                }
                return ra
            }
        }
    }

    /**
     * Printer status
     * @author Administrator
     */
    enum class PrinterStatus(val value: Int) {
        /**
         * unknow
         */
        PS_UNKNOW(0),

        /**
         * printer status error
         */
        PS_ERROR(1),

        /**
         * paper out
         */
        PS_PAPAEROUT(2),

        /**
         * printer ok
         */
        PS_OK(3);

    }

    /**
     * barcode HRI position
     * @author Administrator
     */
    enum class Barcode1DHRI(val value: Int) {
        /**
         * none string
         */
        BH_NO(0),

        /**
         * under barcode
         */
        BH_UNDER(1),

        /**
         * blew the barcode
         */
        BH_BLEW(2);

        companion object {
            fun getEnum(value: Int): Barcode1DHRI? {
                var bh: Barcode1DHRI? = null
                when (value) {
                    0 -> bh = BH_NO
                    1 -> bh = BH_UNDER
                    2 -> bh = BH_BLEW
                }
                return bh
            }
        }
    }

    /**
     * print mode type
     * @author Administrator
     */
    enum class TransferMode(val value: Int) {
        /**
         * standard mode print
         */
        TM_NONE(0),

        /**
         * RG-WP100 print protocol
         */
        TM_DT_V1(1),

        /**
         * RG-WP200 print protocol
         */
        TM_DT_V2(2);

        companion object {
            fun getEnum(value: Int): TransferMode? {
                var tm: TransferMode? = null
                when (value) {
                    0 -> tm = TM_NONE
                    1 -> tm = TM_DT_V1
                    2 -> tm = TM_DT_V2
                }
                return tm
            }
        }
    }
}