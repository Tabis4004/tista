package developer.owner.tista;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.DrawableRes;

import com.google.zxing.BarcodeFormat;

import java.util.ArrayList;

import demo.printlib.export.demoPrinter;
import demo.printlib.export.preDefiniation;

public class PrinterModuleRego {

    private static String tag = "";
    private SynchronizedPrinter printer;

    public PrinterModuleRego(Context context) {
        printer = new SynchronizedPrinter(context);
    }

    public synchronized ArrayList<String> getSupportPrinters() {
        return printer.getSupportPrinters();
    }

    public synchronized String[] getSupportPageMode() {
        return printer.getSupportPageMode();
    }

    public synchronized int printInit() {
        return printer.printInit();
    }

    public synchronized int closeDevices() {
        return printer.closeDevices();
    }

    public synchronized int PrintCheckStatus() {
        return printer.PrintCheckStatus();
    }

    public synchronized void printSetGray(int level) {
        printer.printSetGray(level);
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
        printer.printString(text);
    }

    public synchronized void printBarcode(String content, int width, int height) {
        printer.printBarcode(content, width, height);
    }

    public synchronized void printQrCode_Cut(String content, int width, int height) {
        doInBackground(() -> printer.printQrCode_Cut(content, width, height));
    }

    public synchronized void printCutQrCode_Str(String qrContent, String printTxt, int distance, int width, int height) {
        doInBackground(() -> printer.printCutQrCode_Str(qrContent, printTxt, distance, width, height));
    }

    public synchronized void printBitmap(byte[] bytes, int width, int height) {
        doInBackground(() -> printer.printBitmap(bytes, width, height));
    }

    public synchronized void printBitmapResource(Context context, @DrawableRes int drawableId) {
        doInBackground(() -> printer.printBitmapResource(context, drawableId));
    }

    public synchronized void printEndLine() {
        doInBackground(() -> printer.printEndLine());
    }

    public synchronized void printStart(/*Callback<Integer> callback*/) {
        printer.printStart(/*callback*/);
    }

    public synchronized void printEnd(/*Callback<Integer> callback*/) {
        printer.printEnd(/*callback*/);
    }

    public synchronized void setBold(boolean bold) {
        printer.setBold(bold);
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

        private demoPrinter printer;
        private int objCode;
        private String printName = "POS58D";
        private Context cxt;

        public SynchronizedPrinter(Context context) {
            cxt = context;
            printer = new demoPrinter(context);
        }

        public synchronized ArrayList<String> getSupportPrinters() {
            ArrayList<String> printers = printer.CON_GetSupportPrinters();
            printName = "POS58D";//printers.get(0);
            return printers;
        }

        public synchronized String[] getSupportPageMode() {
            final String[] modes = printer.CON_GetSupportPageMode();
            return modes;
        }

        public synchronized int printInit() {
            String port = "usb";//"/dev/ttyS0:1200:1:0";
            objCode = printer.CON_ConnectDevices(printName, port, 200);

            //Toast.makeText( cxt,"printInit, " + String.valueOf(objCode) + " *** "+String.valueOf(demoPrinter.verify), Toast.LENGTH_SHORT).show();
            return objCode;
        }

        public synchronized int PrintCheckStatus() {
            try {
                int i = printer.CON_QueryStatus(objCode);
                //Toast.makeText(cxt, "PrintCheckStatus, result: " +  String.valueOf(i), Toast.LENGTH_SHORT).show();

                return i;
            } catch (Exception e) {
                //Toast.makeText( cxt,"PrintCheckStatus, error: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                return -1;
            }
        }

        public synchronized int closeDevices() {
            int i = printer.CON_CloseDevices(objCode);
            //Toast.makeText( cxt,"closeDevices, result: " +  String.valueOf(i), Toast.LENGTH_SHORT).show();
            return i;
        }

        /**
         * Print density. Normal is 2
         *
         * @param level ex : between 1 and 5
         */
        public synchronized void printSetGray(int level) {
            printer.CON_SetDensity(objCode, level);
        }

        /**
         *
         * @param size default is 24
         */
        public synchronized void printSetFontSize(int size, int zoom) {
            //posApiHelper.PrintSetFont((byte) size, (byte) size, (byte) zoom);
        }

        public synchronized void printSetDefaultFont() {
            //printer.PrintSetFont((byte) 24, (byte) 24, (byte) 0x00);
        }

        /**
         * Useful for QR_code
         *
         * @param alignment 0 Left ,1 Middle ,2 Right
         */
        public synchronized void printSetAlign(int alignment) {
            //utils.preDefiniation.AlignType.getEnum(alignment).getValue()
            printer.ASCII_CtrlAlignType(objCode, alignment);
            //Toast.makeText( cxt,"printSetAlign, " + String.valueOf(ret) + " *** "+ String.valueOf(objCode) , Toast.LENGTH_SHORT).show();
        }

        public synchronized void printString(String text) {
            //int ret = printer.ASCII_PrintString(objCode,1, 1, 0, 0, 0, text, "gb2312");
            printer.ASCII_PrintString(objCode, text, "gb2312");
            //Toast.makeText( cxt,"printString, " + String.valueOf(ret) + " *** "+ String.valueOf(objCode) , Toast.LENGTH_SHORT).show();
            //int reset = printer.ASCII_CtrlReset(objCode);
            //Toast.makeText( cxt,"reset, " + String.valueOf(reset) + " ### "+ String.valueOf(objCode) , Toast.LENGTH_SHORT).show();
        }

        /**
         * Test {@link BarcodeFormat#CODE_128} with 360x120. And also test
         * {@link BarcodeFormat#QR_CODE} with 240*240
         *
         * @param content ex : "1234567890"
         * @param width ex : 360
         * @param height ex : 360
         */
        public synchronized void printBarcode(String content, int width, int height) {
            Toast.makeText(cxt, "printBarcode, result: " + content, Toast.LENGTH_SHORT).show();
            int ret = printer.ASCII_Print2DBarcode(objCode, utils.preDefiniation.BarcodeType.BT_QRcode.getValue(), content, 8, 76, 2);
            Toast.makeText(cxt, "printBarcode2, result: " + String.valueOf(ret), Toast.LENGTH_SHORT).show();
        }

        /**
         *
         * @param content ex : "123456789"
         * @param width ex : 360
         * @param height ex : 360
         */
        public synchronized void printQrCode_Cut(String content, int width, int height) {
            //ASCII_Print2DBarcode(context.getState(), utils.preDefiniation.BarcodeType.BT_QRcode.getValue(), param,
            //      "gb2312");
            printer.ASCII_Print2DBarcode(objCode, utils.preDefiniation.BarcodeType.BT_QRcode.getValue(), content, 8, 76, 2);
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
            Bitmap bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
            Bitmap bmp1 = bmp.copy(Bitmap.Config.ALPHA_8, true);
            Log.e("WIDTH", String.valueOf(bmp1.getWidth()));
            Log.e("HEIGHT", String.valueOf(bmp1.getHeight()));
            bmp1.setWidth(width);
            bmp1.setHeight(height);
            printer.DRAW_PrintPicture(objCode, bmp1, 0, 0, width, height);
        }

        /**
         *
         * @param context
         * @param drawableId android resource drawable id
         */
        public synchronized void printBitmapResource(Context context, @DrawableRes int drawableId) {
            Bitmap bmp1 = BitmapFactory.decodeResource(context.getResources(), drawableId);
            printer.DRAW_PrintPicture(objCode, bmp1, 0, 0, 150, 150);
        }

        // 40 characters vs 31
        public synchronized void printEndLine() {
            int ret = printer.ASCII_PrintString(objCode, "\n\n", "gb2312");
        }

        /**
         * start printing
         */
        public synchronized void printStart(/*Callback<Integer> callback*/) {
            try {
                //Log.i("CON_PageStart", " result: ");
                //Toast.makeText( cxt,"CON_PageStart, result: ", Toast.LENGTH_SHORT).show();

                printer.CON_PageStart(objCode, false, 0, 0);
                //Toast.makeText( cxt,"printStart, result: " + String.valueOf(ret), Toast.LENGTH_SHORT).show();
            } catch (Exception e) {
                //Log.i("CON_PageStart", " error: "+ e.getMessage());
                //Toast.makeText( cxt,"printStart, error: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            }
        }

        public synchronized void printEnd() {
            printer.CON_PageEnd(objCode, preDefiniation.TransferMode.TM_NONE.getValue());
            //Log.i("printEnd",String.valueOf(ret));
            //Toast.makeText( cxt,"printEnd, result: " + String.valueOf(ret), Toast.LENGTH_SHORT).show();
            //if(callback != null) callback.onCallback(ret);
        }

        public synchronized void setBold(boolean bold) {
            printer.ASCII_SetBold(objCode, bold);
        }

    }

}
