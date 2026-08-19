package developer.owner.tista;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.RemoteException;
import android.util.Log;

import com.wiseasy.emvprocess.LibInit;
import com.wiseasy.emvprocess.SDKInstance;

import wangpos.sdk4.libbasebinder.Printer;

public class PrinterModuleBleu {

    private static String tag = "";
    private Object context;
    private Printer mPrinter;

    public PrinterModuleBleu(Context context) {
        try {
            new Thread() {
                @Override
                public void run() {
                    Log.e("PrinterModuleBleu", "INIT IT");
                    SDKInstance.initSDK(context);
                    LibInit.init(true);
                    mPrinter = new Printer(context);
                    Log.e("PrintCheckStatus", "END INIT IT");
                }
            }.start();
        } catch (Exception e) {
            Log.e("PrinterModuleBleu ERROR", e.getMessage());
        }
    }

    public int PrintCheckStatus(int[] status) throws RemoteException {
        Log.e("PrintCheckStatus", "TEST IT");
        return mPrinter.getPrinterStatus(status);
    }

    public int clearPrintDataCache() throws RemoteException {
        return mPrinter.clearPrintDataCache();
    }

    public int printInit() {
        try {
            return mPrinter.printInit();
        } catch (RemoteException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public void printString(String text, int fontSize, int alignment, boolean isBold, boolean isItalic) {
        try {
            Printer.Align al = Printer.Align.LEFT;
            if (alignment == 1) {
                al = Printer.Align.CENTER;
            } else if (alignment == 2) {
                al = Printer.Align.RIGHT;
            }
            mPrinter.printString(text, fontSize, al, isBold, isItalic);
        } catch (RemoteException e) {
            Log.e("printString ERROR", e.getMessage());
        }
    }

    public void printPaper() throws RemoteException {
        mPrinter.printPaper(10);
    }

    public void printFinish() throws RemoteException {
        mPrinter.printFinish();
    }

    public void printQRCode(String text, int width) throws RemoteException {
        mPrinter.printQRCode(text, width, Printer.Align.CENTER);
    }

    public void printImage(Bitmap image, int height, int alignment) throws RemoteException {
        Printer.Align al = Printer.Align.LEFT;
        if (alignment == 1) {
            al = Printer.Align.CENTER;
        } else if (alignment == 2) {
            al = Printer.Align.RIGHT;
        }
        mPrinter.printImage(image, height, al);
    }

    /*private void doInBackground(Runnable runnable) {
      Thread t = new Thread(runnable);
      bthreadrunning = true;
        t.start();
        try {
            t.run();
            result = mPrinter.printInit();
            //clear print cache
                    mPrinter.clearPrintDataCache();
        } catch (RemoteException e) {
            e.printStackTrace();
        }

    }*/

 /*public class PrintThread extends Thread {
        @Override
        public void run () {
            bthreadrunning = true;
            int datalen = 0;
            int result = 0;
            byte[] senddata = null;
            do {
                try {
                    result = mPrinter.printInit();
                    //clear print cache
                    mPrinter.clearPrintDataCache();
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                try {

                    testPrintImageBase("logo");
//                    // Print text
                    testPrintString(result);
//                    // print bar_Code
//                    result = mPrinter.printBarCodeBase("1234567890abcdefg", Printer.BarcodeType.CODE_128, Printer.BarcodeWidth.LARGE, 50, 20);
//                    //print QR_Code(text)
//                    result = mPrinter.printQRCode("http://www.wangpos.com/",400);
////                    testPrintImageBase("wiseasy");
                    //laguage print
                    testPrintLaguage(result);
                    Log.d("hank", "run: hank");
                    //print end reserve height
                    result = mPrinter.printPaper(20);
                    if(result == 138){
                        bloop = false;
                        return;
                    }else{
                        result = mPrinter.printFinish();
                    }

                } catch (Exception e) {
                    e.printStackTrace();
                }

            } while (bloop);
            bthreadrunning = false;
        }
    }*/

 /*public synchronized void Printer(){
        //Intent intentprincon = new Intent(this , PrinterManager.class);
        startActivity(intentprincon);
        txt_msg.setText("");
    }

    public synchronized void printString(String text) {
            mPrinter.printString(text, 25, center, true, false);
        }

    public synchronized void printPaper(String text) throws RemoteException {
            mPrinter.printPaper(20);
    }

    public synchronized void printFinish(String text) throws RemoteException {
            mPrinter.printFinish();
        }*/
}
