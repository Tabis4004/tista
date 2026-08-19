package utils

import android.app.Application
import demo.printlib.export.demoPrinter

class ApplicationContext : Application() {
    var `object`: demoPrinter? = null
        private set
    var state = 0
    var name = "RG-MTP58B"
    private var printmode = preDefiniation.TransferMode.TM_NONE
    private var labelmark = true
    fun setObject() {
        `object` = demoPrinter(this)
    }

    var printway: Int
        get() = printmode.value
        set(printway) {
            printmode = when (printway) {
                0 -> preDefiniation.TransferMode.TM_NONE
                1 -> preDefiniation.TransferMode.TM_DT_V1
                else -> preDefiniation.TransferMode.TM_DT_V2
            }
        }

    fun getlabel(): Boolean {
        return labelmark
    }

    fun setlabel(labelprint: Boolean) {
        labelmark = labelprint
    }
}