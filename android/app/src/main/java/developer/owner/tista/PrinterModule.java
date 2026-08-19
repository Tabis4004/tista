package developer.owner.tista;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;

import androidx.annotation.DrawableRes;

import com.google.zxing.BarcodeFormat;

import vpos.apipackage.ByteUtil;
import vpos.apipackage.PosApiHelper;
import vpos.apipackage.Print;
import vpos.apipackage.PrintInitException;

public class PrinterModule {

    private static String tag = PrinterModule.class.getSimpleName();
    private SynchronizedPrinter printer = new SynchronizedPrinter();

    public synchronized int logicPowerOn() {
        return printer.logicPowerOn();
    }

    public synchronized String logicCardDispatcher(boolean writing, String contenu) {
        return printer.logicCardDispatcher(writing, contenu);
    }

    public synchronized int PrintCheckStatus() {
        return printer.PrintCheckStatus();
    }

    public synchronized void printInit() {
        doInBackground(() -> printer.printInit());
    }

    public synchronized int sysSetPower(int mode) {
        return printer.sysSetPower(mode);
    }

    public synchronized void printSetGray(int level) {
        doInBackground(() -> printer.printSetGray(level));
    }

    public synchronized void printSetFontSize(int size, int zoom) {
        printer.printSetFontSize(size, zoom);
    }

    public synchronized void printSetDefaultFont() {
        doInBackground(() -> printer.printSetDefaultFont());
    }

    public synchronized void printSetAlign(int alignment) {
        printer.printSetAlign(alignment);
    }

    public synchronized void printString(String text) {
        doInBackground(() -> printer.printString(text));
    }

    public synchronized void printBarcode(String content, int width, int height, BarcodeFormat barcodeFormat) {
        doInBackground(() -> printer.printBarcode(content, width, height, barcodeFormat));
    }

    public synchronized void printQrCode_Cut(String content, int width, int height) {
        doInBackground(() -> printer.printQrCode_Cut(content, width, height));
    }

    public synchronized void printCutQrCode_Str(String qrContent, String printTxt, int distance, int width, int height) {
        doInBackground(() -> printer.printCutQrCode_Str(qrContent, printTxt, distance, width, height));
    }

    public synchronized void printBitmap(byte[] bytes, int width, int height) {
        printer.printBitmap(bytes, width, height);
    }

    public synchronized void printBitmapResource(Context context, @DrawableRes int drawableId) {
        doInBackground(() -> printer.printBitmapResource(context, drawableId));
    }

    public synchronized void printEndLine() {
        doInBackground(() -> printer.printEndLine());
    }

    public synchronized void printStart(/*Callback<Integer> callback*/) {
        doInBackground(() -> printer.printStart(/*callback*/));
    }

    private void doInBackground(Runnable runnable) {
        Thread t = new Thread(runnable);
        t.start();
        try {
            t.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

    }

    private static class SynchronizedPrinter {

        PosApiHelper posApiHelper = PosApiHelper.getInstance();

        private static final byte RSP_SELECT_0 = (byte) 0x90;
        private static final byte RSP_SELECT_1 = (byte) 0x00;
        private static final byte RSP_VERIFICTION_4428_0 = (byte) 0x90;
        private static final byte RSP_VERIFICTION_4428_1 = (byte) 0xFF;
        private static final byte RSP_VERIFICTION_4442_0 = (byte) 0x90;
        private static final byte RSP_VERIFICTION_4442_1 = (byte) 0x07;

        public synchronized int logicPowerOn() {
            try {
                int i = posApiHelper.LogicPowerOn();
                Log.e("logicPowerOn", "result: " + i);
                return i;
            } catch (Exception e) {
                Log.e("logicPowerOn", "error: " + e);
                return -1;
            }
        }

        public synchronized String logicCardDispatcher(boolean writing, String contenu) {
            try {
                byte data[] = new byte[512];
                byte outLen[] = new byte[2];
                int length = 6;
                int ret = -1;
                String error = "";
                int nbType = 1; //[4442, 4428]

                //select card CMD
                for (int i = 0; i < nbType; i++) {
                    data = new byte[512];
                    if (i == 0) {
                        data[0] = (byte) 0xFF;
                        data[1] = (byte) 0xA4;
                        data[2] = (byte) 0x00;
                        data[3] = (byte) 0x00;
                        data[4] = (byte) 0x01;
                        data[5] = (byte) 0x06;
                    } else {
                        data[0] = (byte) 0xFF;
                        data[1] = (byte) 0xA4;
                        data[2] = (byte) 0x00;
                        data[3] = (byte) 0x00;
                        data[4] = (byte) 0x01;
                        data[5] = (byte) 0x05;
                    }
                    ret = posApiHelper.LogicCardDispatcher(data, length, data, outLen);
                    Log.e("logicCardDispatcher", "result: " + ret + " INDEX: " + i);
                    if (ret != 0) {
                        Log.e("logicCardDispatcher", "uart comm failed");
                        error = "UART_CMD_FAILED";
                        //return -20;
                        continue;
                    } else {
                        if (!(data[0] == RSP_SELECT_0 && data[1] == RSP_SELECT_1)) {
                            Log.e("logicCardDispatcher", " select rsp failed !!!~~");
                            error = "RSP_FAILED";
                            ret = -1;
                            continue;
                        }
                    }
                    if (ret == 0) {
                        break;
                    }
                }

                if (ret != 0) {
                    if (error.isEmpty()) {
                        return "" + ret;
                    }
                    return error;
                }

                if (writing) {
                    //verifiction card CMD
                    for (int i = 0; i < nbType; i++) {
                        if (i == 0) {
                            data[0] = (byte) 0xFF;
                            data[1] = (byte) 0x20;
                            data[2] = (byte) 0x00;
                            data[3] = (byte) 0x00;
                            data[4] = (byte) 0x03;
                        } else {
                            data[0] = (byte) 0xFF;
                            data[1] = (byte) 0x20;
                            data[2] = (byte) 0x00;
                            data[3] = (byte) 0x00;
                            data[4] = (byte) 0x02;
                        }

                        String inputPwd = "FFFFFF";
                        byte[] dataTmp = ByteUtil.StringToHexBytes(inputPwd);
                        for (int j = 0; j < dataTmp.length; j++) {
                            data[4 + 1 + j] = dataTmp[j];
                        }
                        length = 4 + 1 + dataTmp.length;
                        ret = posApiHelper.LogicCardDispatcher(data, length, data, outLen);
                        Log.e("logicCardDispatcher 2", "result: " + ret + " INDEX: " + i);
                        if (ret != 0) {
                            Log.e("logicCardDispatcher", "uart comm failed");
                            error = "UART_CMD_FAILED";
                            //return -20;
                            continue;
                        } else {
                            byte verif_0 = i == 0 ? RSP_VERIFICTION_4442_0 : RSP_VERIFICTION_4428_0;
                            byte verif_1 = i == 0 ? RSP_VERIFICTION_4442_1 : RSP_VERIFICTION_4428_1;
                            Log.e("BYTECHECKING", "VERIF_0: " + verif_0 + " DATA0: " + data[0] + " VERIF_1: " + verif_1 + " DATA1: " + data[1]);
                            if (!(data[0] == verif_0 && data[1] == verif_1)) {
                                Log.e("logicCardDispatcher", " select rsp failed !!!~~");
                                error = "RSP_FAILED";
                                ret = -1;
                                continue;
                            }
                        }
                        if (ret == 0) {
                            break;
                        }
                    }
                    if (ret != 0) {
                        if (error.isEmpty()) {
                            return "" + ret;
                        }
                        return error;
                    }

                    //write content
                    data[0] = (byte) 0xFF;
                    data[1] = (byte) 0xD0;
                    data[2] = (byte) 0x00;
                    data[3] = (byte) 0x00;

                    //write data
                    byte[] dataTmp = ByteUtil.StringToHexBytes(contenu);
                    Log.e("CONTENU", contenu + " DATATEMP: " + dataTmp.length);
                    //data len
                    data[4] = (byte) dataTmp.length;
                    for (int i = 0; i < dataTmp.length; i++) {
                        data[4 + 1 + i] = dataTmp[i];
                    }

                    length = 4 + 1 + dataTmp.length;
                    Log.e("liuhao", "data write: " + ByteUtil.byte2String(data));
                    ret = posApiHelper.LogicCardDispatcher(data, length, data, outLen);
                    if (ret != 0) {
                        Log.e("logicCardDispatcher", "memory card Failed...");
                        return "CARD_CHECK_FAILED";
                    } else {
                        Log.e("logicCardDispatcher", "memory card Write success!!\n\n ");
                        return "0";
                    }
                    //return "CARD_CHECK_FAILED";
                }

                data[0] = (byte) 0xFF;
                data[1] = (byte) 0xB0;
                data[2] = (byte) 0x00;
                data[3] = (byte) 0x00;
                data[4] = (byte) 0x64;
                length = 5;
                ret = posApiHelper.LogicCardDispatcher(data, length, data, outLen);

                if (ret != 0) {
                    Log.e("logicCardDispatcher", "memory card 4428 check Failed...");
                    return "CARD_CHECK_FAILED";
                } else {
                    int len = ByteUtil.bytesToInt(outLen);
                    Log.e("logicCardDispatcher", "Read memory card success!!\n\n outLen : " + len + "\ndata : " + ByteUtil.bytearrayToHexString(data, len));
                    return ByteUtil.bytearrayToHexString(data, len); //
                    //return ByteUtil.byte2String(data);
                }

                //return ret;
            } catch (Exception e) {
                Log.e("logicCardDispatcher", "error: " + e);
                return "ERROR";
            }
        }

        public synchronized void printInit() {
            try {
                posApiHelper.PrintInit();
            } catch (PrintInitException e) {
                e.printStackTrace();
                int initRet = e.getExceptionCode();
                Log.e(tag, "initRer : " + initRet);
            }
        }

        public synchronized int PrintCheckStatus() {
            try {
                int i = posApiHelper.PrintCheckStatus();
                Log.e("PrintCheckStatus", "result: " + i);
                return i;
            } catch (Exception e) {
                Log.e("PrintCheckStatus", "error: " + e);
                return -1;
            }
        }

        //Sys.Lib_Setpower(1);
        public synchronized int sysSetPower(int mode) {
            Log.e("sysSetPower", "mode: " + mode);
            int i = posApiHelper.SysSetPower(mode);
            Log.e("sysSetPower", "result: " + i);
            return i;
        }

        /**
         * Print density. Normal is 2
         *
         * @param level ex : between 1 and 5
         */
        public synchronized void printSetGray(int level) {
            posApiHelper.PrintSetGray(level);
        }

        /**
         *
         * @param size default is 24
         */
        public synchronized void printSetFontSize(int size, int zoom) {
            posApiHelper.PrintSetFont((byte) size, (byte) size, (byte) zoom);
        }

        public synchronized void printSetDefaultFont() {
            posApiHelper.PrintSetFont((byte) 24, (byte) 24, (byte) 0x00);
        }

        /**
         * Useful for QR_code
         *
         * @param alignment 0 Left ,1 Middle ,2 Right
         */
        public synchronized void printSetAlign(int alignment) {
            Print.Lib_PrnSetAlign(alignment);
        }

        public synchronized void printString(String text) {
            posApiHelper.PrintStr(text);
        }

        /**
         * Test {@link BarcodeFormat#CODE_128} with 360x120. And also test
         * {@link BarcodeFormat#QR_CODE} with 240*240
         *
         * @param content ex : "1234567890"
         * @param width ex : 360
         * @param height ex : 360
         * @param barcodeFormat ex : {@link BarcodeFormat#QR_CODE}
         */
        public synchronized void printBarcode(String content, int width, int height,
                BarcodeFormat barcodeFormat) {
            posApiHelper.PrintBarcode(content, width, height, barcodeFormat);
        }

        /**
         *
         * @param content ex : "123456789"
         * @param width ex : 360
         * @param height ex : 360
         */
        public synchronized void printQrCode_Cut(String content, int width, int height) {
            //posApiHelper.PrintQrCode_Cut(content, width, height, BarcodeFormat.QR_CODE);
        }

        /**
         *
         * @param qrContent ex : "1234567890"
         * @param printTxt ex : "PK TXT adsad adasd sda"
         * @param distance ex : 5
         * @param width ex : 300
         * @param height ex : 300
         */
        public synchronized void printCutQrCode_Str(String qrContent, String printTxt, int distance,
                int width, int height) {
            /* posApiHelper.PrintCutQrCode_Str(qrContent, printTxt, distance, width, height,
                    BarcodeFormat.QR_CODE); */
        }

        public synchronized void printBitmap(byte[] bytes, int width, int height) {
            Bitmap bmp1 = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
            //Bitmap bmp1 = bmp.copy(Bitmap.Config.,true);
            Log.e("WIDTH", String.valueOf(bmp1.getWidth()));
            Log.e("HEIGHT", String.valueOf(bmp1.getHeight()));
            //bmp1.setWidth(width);
            //bmp1.setHeight(height);
            posApiHelper.PrintBmp(bmp1);
        }

        /**
         *
         * @param context
         * @param drawableId android resource drawable id
         */
        public synchronized void printBitmapResource(Context context, @DrawableRes int drawableId) {
            Bitmap bmp1 = BitmapFactory.decodeResource(context.getResources(), drawableId);
            posApiHelper.PrintBmp(bmp1);
            //posApiHelper.PrintStr("                                         \n");
        }

        // 40 characters vs 31
        public synchronized void printEndLine() {
            posApiHelper.PrintStr("\n\n");
            //posApiHelper.PrintStr("                                        \n");
            //posApiHelper.PrintStr("                                        \n");
        }

        /**
         * start printing
         */
        public synchronized void printStart(/*Callback<Integer> callback*/) {
            int ret = posApiHelper.PrintStart();
            //if(callback != null) callback.onCallback(ret);
        }

    }

    public interface Callback<T> {

        void onCallback(T t);
    }
}
