"""
Series of data are loaded from a .csv file, and their names are
displayed in a checkable list view. The user can select the series
it wants from the list and plot them on a matplotlib canvas.
Use the sample .csv file that comes with the script for an example
of data series.

[2016-11-06] Convert to QtQuick 2.0 - Qt.labs.controls 1.0
[2016-11-05] Convert to QtQuick 2.0 - QtQuick Controls 1.0
[2016-11-01] Update to PyQt5.6 and python 3.5

Frederic Collonval (fcollonval@gmail.com)

Inspired from the work of Eli Bendersky (eliben@gmail.com):
https://github.com/eliben/code-for-blog/tree/master/2009/pyqt_dataplot_demo

License: MIT License
Last modified: 2016-11-06
"""
import sys, os, csv
from PySide2.QtCore import Qt, QObject, QUrl
from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import qmlRegisterType
from PySide2.QtQuick import QQuickView

from backend.backend_qquick5agg import FigureCanvasQTAggToolbar, MatplotlibIconProvider

import matplotlib
# matplotlib.use('module://backend_qtquick5')
# from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
# from matplotlib.backends.backend_qt5agg import NavigationToolbar2QT as NavigationToolbar
# from matplotlib.figure import Figure
import matplotlib.pyplot as plt

import numpy as np       
        
def main():
    argv = sys.argv
    
    app = QGuiApplication(argv)
    
    qmlRegisterType(FigureCanvasQTAggToolbar, "Backend", 1, 0, "FigureToolbarByPython")
    
    imgProvider = MatplotlibIconProvider()
    view = QQuickView()
    view.engine().addImageProvider("mplIcons", imgProvider)
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.setSource(QUrl('backend/FigureToolbar.qml'))
    
    win = view.rootObject()
    fig = win.findChild(QObject, "figure").getFigure()
    ax = fig.add_subplot(111)
    x = np.linspace(-5, 5)
    ax.plot(x, np.sin(x))
    
    view.show()
    
    rc = app.exec_()
    # There is some trouble arising when deleting all the objects here
    # but I have not figure out how to solve the error message.
    # It looks like 'app' is destroyed before some QObject
    sys.exit(rc)


if __name__ == "__main__":
    main()