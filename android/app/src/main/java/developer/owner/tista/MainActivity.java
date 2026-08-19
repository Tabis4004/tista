package developer.owner.tista;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.os.Bundle;
import android.os.RemoteException;
import android.util.Log;
import android.app.Service;
import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import com.google.zxing.BarcodeFormat;

import java.util.ArrayList;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugins.GeneratedPluginRegistrant;
import utils.ApplicationContext;
//import recieptservice.com.recieptservice.PrinterInterface;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "own.channel/tista";
    private static final PrinterModule printerModule = new PrinterModule();
    private static PrinterModuleRego printerModuleRego;
    private static PrinterModuleBleu printerModuleBleu;
    /** Lecteur de carte des terminaux Wiseasy (P3, WPOS). Null hors Wiseasy. */
    private static CardModuleWiseasy cardWiseasy;

    @Override
    protected void onCreate(@NonNull Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ApplicationContext cxt = (ApplicationContext) getApplicationContext();
        printerModuleRego = new PrinterModuleRego(cxt);
        printerModuleBleu = new PrinterModuleBleu(getApplicationContext());
        cardWiseasy = new CardModuleWiseasy(getApplicationContext());
        Log.i("Terminal", "Lecteur Wiseasy disponible : " + cardWiseasy.isAvailable());
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        setMethod(flutterEngine); // A commenter quand on compile sur R330 (TPE Noir)

        // R330
        /*  Intent intent = new Intent();
        intent.setClassName("recieptservice.com.recieptservice", "recieptservice.com.recieptservice.service.PrinterService");
        bindService(intent, new ServiceConnection() {
            @Override
            public void onServiceConnected(ComponentName name, final IBinder service) {
                PrinterInterface mAidl = PrinterInterface.Stub.asInterface(service);
                setMethod(mAidl, flutterEngine);
            }

            @Override
            public void onServiceDisconnected(ComponentName name) {

            }
        }, Service.BIND_AUTO_CREATE);
         */
    }

    void setMethod(@NonNull FlutterEngine flutterEngine
    ) { //@Nullable PrinterInterface mAidl, 
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler(new MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall call, Result result) {
                Log.i("call.method", call.method);
                if (call.method.equals("moveTaskToBack")) {
                    result.success(moveTaskToBack(true));
                } else if (call.method.equals("printBitmap")) {
                    byte[] bytes = call.argument("p1");
                    int width = call.argument("width");
                    int height = call.argument("height");
                    printerModule.printBitmap(bytes, width, height);
                    result.success(1);
                } else if (call.method.equals("printers")) {
                    final ArrayList<String> i = printerModuleRego.getSupportPrinters();
                    result.success(i);
                } else if (call.method.equals("printInitRego")) {
                    final int i = printerModuleRego.printInit();
                    result.success(i);
                } else if (call.method.equals("PrintCheckStatusRego")) {
                    final int i = printerModuleRego.PrintCheckStatus();
                    result.success(i);
                } else if (call.method.equals("closeDevices")) {
                    final int i = printerModuleRego.closeDevices();
                    result.success(i);
                } else if (call.method.equals("printStringRego")) {
                    String text = call.argument("text");
                    printerModuleRego.printString(text);
                    result.success(1);
                } else if (call.method.equals("PrintCheckStatus")) {
                    final int i = printerModule.PrintCheckStatus();
                    result.success(i);
                } else if (call.method.equals("printInit")) {
                    printerModule.printInit();
                    result.success(1);
                } else if (call.method.equals("printSetGray")) {
                    int level = call.argument("level");
                    printerModule.printSetGray(level);
                    result.success(1);
                } else if (call.method.equals("sysSetPower")) {
                    int mode = call.argument("mode");
                    final int i = printerModule.sysSetPower(mode);
                    result.success(i);
                } else if (call.method.equals("printSetFontSize")) {
                    int size = call.argument("size");
                    int zoom = call.argument("zoom");
                    printerModule.printSetFontSize(size, zoom);
                    result.success(1);
                } else if (call.method.equals("printSetDefaultFont")) {
                    printerModule.printSetDefaultFont();
                    result.success(1);
                } else if (call.method.equals("printSetAlign")) {
                    int alignment = call.argument("alignment");
                    printerModule.printSetAlign(alignment);
                    result.success(1);
                } else if (call.method.equals("printString")) {
                    String text = call.argument("text");
                    printerModule.printString(text);
                    result.success(1);
                } else if (call.method.equals("printBarcode")) {
                    String text = call.argument("text");
                    int width = call.argument("width");
                    int height = call.argument("height");
                    String type = call.argument("type");
                    printerModule.printBarcode(text, width, height, BarcodeFormat.valueOf(type));
                    result.success(1);
                } else if (call.method.equals("printEndLine")) {
                    printerModule.printEndLine();
                    result.success(1);
                } else if (call.method.equals("printStart")) {
                    printerModule.printStart();
                    result.success(1);
                } else if (call.method.equals("printSetAlignRego")) {
                    int alignment = call.argument("alignment");
                    printerModuleRego.printSetAlign(alignment);
                    result.success(1);
                } else if (call.method.equals("printStartRego")) {
                    printerModuleRego.printStart();
                    result.success(1);
                } else if (call.method.equals("printEndRego")) {
                    printerModuleRego.printEnd();
                    result.success(1);
                } else if (call.method.equals("setBoldRego")) {
                    boolean bold = call.argument("bold");
                    printerModuleRego.setBold(bold);
                    result.success(1);
                } else if (call.method.equals("printSetGrayRego")) {
                    int level = call.argument("level");
                    printerModuleRego.printSetGray(level);
                    result.success(1);
                } else if (call.method.equals("printQRCodeRego")) {
                    String text = call.argument("text");
                    int width = call.argument("width");
                    int height = call.argument("height");
                    printerModuleRego.printBarcode(text, width, height);
                    result.success(1);
                } else if (call.method.equals("getSupportPageMode")) {
                    String[] modes = printerModuleRego.getSupportPageMode();
                    ArrayList<String> tabs = new ArrayList();

                    for (int i = 0; i < modes.length; i++) {
                        tabs.add(modes[i]);
                    }
                    result.success(tabs);
                } // Logic CARD
                else if (call.method.equals("LogicPowerOn")) {
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
                } //tpe bleu
                else if (call.method.equals("PrintCheckStatusBleu")) {
                    int i = 0;
                    int[] status = new int[1];
                    try {
                        i = printerModuleBleu.PrintCheckStatus(status);
                    } catch (RemoteException e) {
                        e.printStackTrace();
                    }
                    result.success(i);
                } else if (call.method.equals("clearPrintDataCache")) {
                    int i = 0;
                    try {
                        i = printerModuleBleu.clearPrintDataCache();
                    } catch (RemoteException e) {
                        e.printStackTrace();
                    }
                    result.success(i);
                } else if (call.method.equals("printInitBleu")) {
                    final int i = printerModuleBleu.printInit();
                    result.success(i);
                } else if (call.method.equals("printStringBleu")) {
                    String text = call.argument("text");
                    int fontSize = call.argument("fontSize");
                    int alignment = call.argument("alignment");
                    boolean isBold = call.argument("isBold");
                    boolean isItalic = call.argument("isItalic");
                    printerModuleBleu.printString(text, fontSize, alignment, isBold, isItalic);
                    result.success(1);
                } else if (call.method.equals("printPaper")) {
                    try {
                        printerModuleBleu.printPaper();
                    } catch (RemoteException e) {
                        e.printStackTrace();
                    }
                    result.success(1);
                } else if (call.method.equals("printQRCode")) {
                    String text = call.argument("text");
                    int width = call.argument("width");
                    try {
                        printerModuleBleu.printQRCode(text, width);
                    } catch (RemoteException e) {
                        e.printStackTrace();
                    }
                    result.success(1);
                } else if (call.method.equals("printImage")) {
                    byte[] bytes = call.argument("image");
                    int height = call.argument("height");
                    int alignment = call.argument("alignment");
                    try {
                        Bitmap bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                        Bitmap bmp1 = bmp.copy(Bitmap.Config.ARGB_8888, true);
                        Log.e("WIDTH", String.valueOf(bmp1.getWidth()));
                        Log.e("HEIGHT", String.valueOf(bmp1.getHeight()));
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                            bmp1.setWidth(height);
                            bmp1.setHeight(height);
                        }
                        printerModuleBleu.printImage(bmp1, height, alignment);
                    } catch (RemoteException e) {
                        e.printStackTrace();
                    }
                    result.success(1);
                } else if (call.method.equals("printFinish")) {
                    try {
                        printerModuleBleu.printFinish();
                    } catch (RemoteException e) {
                        e.printStackTrace();
                    }
                    result.success(1);
                } else if (call.method.equals("printEndLineBleu")) {
                    //printerModule.printEndLine();
                    result.success(1);
                } else if (call.method.equals("printStartBleu")) {
                    //printerModule.printStart();
                    result.success(1);
                } else if (call.method.equals("getSupportPageMode")) {
                    String[] modes = printerModuleRego.getSupportPageMode();
                    ArrayList<String> tabs = new ArrayList();

                    for (int i = 0; i < modes.length; i++) {
                        tabs.add(modes[i]);
                    }
                    result.success(tabs);
                } /*  else if (mAidl != null) {
                    // R3330
                    Log.e("IMPRESSION", "mAidl = " + String.valueOf(mAidl != null) + " " + call.method);
                    if (call.method.equals("printStringR330")) {
                        try {
                            String text = call.argument("text");
                            mAidl.printText(text);
                            result.success(1);
                        } catch (Exception e) {
                            Log.e("IMPRESSION printStrR330", e.getMessage());
                            result.error("404", e.getMessage(), e.getMessage());
                        }
                    } else if (call.method.equals("printQRCodeR330")) {
                        try {
                            String text = call.argument("text");
                            mAidl.printQRCode(text, 4, 1);
                            result.success(1);
                        } catch (Exception e) {
                            result.error("404", e.getMessage(), e.getMessage());
                        }
                    } else if (call.method.equals("printSetAlignR330")) {
                        try {
                            int alignment = call.argument("alignment");
                            mAidl.setAlignment(alignment);
                            result.success(1);
                        } catch (Exception e) {
                            result.error("404", e.getMessage(), e.getMessage());
                        }
                    } else if (call.method.equals("setTextSizeR330")) {
                        try {
                            double textSize = call.argument("size");
                            mAidl.setTextSize((float) textSize);
                            result.success(1);
                        } catch (Exception e) {
                            result.error("404", e.getMessage(), e.getMessage());
                        }
                    } else if (call.method.equals("nextLineR330")) {
                        try {
                            int line = call.argument("line");
                            mAidl.nextLine(line);
                            result.success(1);
                        } catch (Exception e) {
                            result.error("404", e.getMessage(), e.getMessage());
                        }
                    } else if (call.method.equals("setTextBoldR330")) {
                        try {
                            boolean bold = call.argument("bold");
                            mAidl.setTextBold(bold);
                            result.success(1);
                        } catch (Exception e) {
                            result.error("404", e.getMessage(), e.getMessage());
                        }
                    } else if (call.method.equals("beginWorkR330")) {
                        try {
                            mAidl.beginWork();
                            result.success(1);
                        } catch (Exception e) {
                            result.error("404", e.getMessage(), e.getMessage());
                        }
                    } else if (call.method.equals("endWorkR330")) {
                        try {
                            mAidl.endWork();
                            result.success(1);
                        } catch (Exception e) {
                            result.error("404", e.getMessage(), e.getMessage());
                        }
                    } else if (call.method.equals("getServiceVersionR330")) {
                        try {
                            String version = mAidl.getServiceVersion();
                            result.success(version);
                        } catch (Exception e) {
                            result.error("404", e.getMessage(), e.getMessage());
                        }
                    } else if (call.method.equals("printBitmapR330")) {
                        try {
                            byte[] bytes = call.argument("p1");
                            int width = call.argument("width");
                            int height = call.argument("height");

                            Bitmap bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                            Bitmap bmp1 = bmp.copy(Bitmap.Config.ARGB_8888, true);
                            Log.e("WIDTH", String.valueOf(bmp1.getWidth()));
                            Log.e("HEIGHT", String.valueOf(bmp1.getHeight()));
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                                bmp1.setWidth(width);
                                bmp1.setHeight(height);
                            }

                            mAidl.printBitmap(bmp1);
                            result.success(1);
                        } catch (Exception e) {
                            result.error("404", e.getMessage(), e.getMessage());
                        }
                    }
                } */ else {
                    result.notImplemented();
                }
            }
        });

    }
}
