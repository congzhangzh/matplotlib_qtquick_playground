import Backend 1.0
import QtQuick 2.6

Item {
    width: 480
    height: 320 

    FigureCanvasByPython {
        id: mplView
        objectName : "figure"
        anchors.fill: parent        
    }
}
