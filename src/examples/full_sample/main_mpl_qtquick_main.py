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
import pathlib

import faulthandler

from backend.backend_qquick5agg import FigureCanvasQTAgg

faulthandler.enable()

import PySide2
from PySide2 import QtCore
from PySide2.QtCore import QAbstractListModel, QModelIndex, QObject, QSize, Qt, QUrl
from PySide2.QtCore import QObject, Signal, Slot, Property
from PySide2.QtGui import QGuiApplication, QColor, QImage, QPixmap
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType

from PySide2.QtCore import qInstallMessageHandler
from PySide2.QtWidgets import QApplication

pyqtSignal=Signal
pyqtProperty=Property
pyqtSlot=Slot

from backend import FigureCanvasQTAggToolbar, MatplotlibIconProvider

class DataSerie(object):

    def __init__(self, name, data, selected=False):
        self._name = name
        self._data = data
        self._selected = selected
    
    def name(self):
        return self._name
    
    def selected(self):
        return self._selected
        
    def data(self):
        return self._data

class DataSeriesModel(QAbstractListModel):

    # Define role enum
    SelectedRole = Qt.UserRole
    NameRole = Qt.UserRole + 1
    DataRole = Qt.UserRole + 2

    _roles = {
        SelectedRole : b"selected",
        NameRole : b"name",
        DataRole : b"data"
    }
    
    lengthDataChanged = QtCore.Signal()
    
    def __init__(self, parent=None):
        QAbstractListModel.__init__(self, parent)
        
        self._data_series = list()
        self._length_data = 0

    def get_lengthData(self):
        return self._length_data

    def set_lengthData(self, length):
        if self._length_data != length:
            self._length_data = length
            self.lengthDataChanged.emit()

    lengthData=QtCore.Property(int, get_lengthData, set_lengthData, notify=lengthDataChanged)

    def roleNames(self):
        return self._roles
    
    def load_from_file(self, filename=None):
        self._data_series.clear()
        self._length_data = 0

        if filename:
            with open(filename, 'r') as f:
                for line in csv.reader(f):
                    series = DataSerie(line[0], 
                                       [i for i in map(int, line[1:])])
                    self.add_data(series)
                    
    def add_data(self, data_series):
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())
        self._data_series.append(data_series)
        self.lengthData = max(self.lengthData, len(data_series.data()))
        self.endInsertRows()
    
    def rowCount(self, parent=QModelIndex()):
        return len(self._data_series)
        
    def data(self, index, role=Qt.DisplayRole):
        if(index.row() < 0 or index.row() >= len(self._data_series)):
            #return QVariant()
            return None
        
        series = self._data_series[index.row()]
        
        if role == self.SelectedRole:
            return series.selected()
        elif role == self.NameRole:
            return series.name()
        elif role == self.DataRole:
            return series.data()
        
        return None
    
    def setData(self, index, value, role=Qt.EditRole):
        if(index.row() < 0 or index.row() >= len(self._data_series)):
            return False
        
        series = self._data_series[index.row()]
        
        if role == self.SelectedRole:
            series._selected = value
            self.dataChanged.emit(index, index, [role,])
            return True
                
        return False
                    
class Form(QObject):

    xFromChanged = pyqtSignal()
    xToChanged = pyqtSignal()
    legendChanged = pyqtSignal()
    statusTextChanged = pyqtSignal()
    stateChanged = pyqtSignal()

    def __init__(self, parent=None, data=None):
        QObject.__init__(self, parent)
        
        self._status_text = "Please load a data file"
        
        self._filename = ""
        self._x_from = 0
        self._x_to = 1
        self._legend = False
        
        # default dpi=80, so size = (480, 320)
        self._figure = None
        self.axes = None
        
        self._data = data

    def get_figure(self):
        return self._figure

    def set_figure(self, fig):
        self._figure = fig
        self._figure.set_facecolor('white')
        self.axes = self.figure.add_subplot(111)    
        
        # Signal connection
        self.xFromChanged.connect(self._figure.canvas.draw_idle)
        self.xToChanged.connect(self._figure.canvas.draw_idle)
        self.legendChanged.connect(self._figure.canvas.draw_idle)
        self.stateChanged.connect(self._figure.canvas.draw_idle)

    figure=QtCore.Property(QtCore.QObject, get_figure, set_figure)

    def get_statusText(self):
        return self._status_text

    def set_statusText(self, text):
        if self._status_text != text:
            self._status_text = text
            self.statusTextChanged.emit()

    statusText=QtCore.Property(str, get_statusText, set_statusText, notify=statusTextChanged)

    def get_filename(self):
        return self._filename

    def set_filename(self, filename):
        if filename:
            filename = QUrl(filename).toLocalFile()
            if filename != self._filename:
                self._filename = filename
                self._data.load_from_file(filename)
                self.statusText = "Loaded " + filename
                self.xTo = self._data.lengthData
                self.update_figure()

    filename=QtCore.Property(str, get_filename, set_filename)


    def get_xFrom(self):
        return self._x_from

    def set_xFrom(self, x_from):
        if self.figure is None:
            return
            
        x_from = int(x_from)
        if self._x_from != x_from:
            self._x_from = x_from
            self.axes.set_xlim(left=self._x_from)
            self.xFromChanged.emit()

    xFrom=Property(int, get_xFrom, set_xFrom, notify=xFromChanged)

    def get_xTo(self):
        return self._x_to

    def set_xTo(self, x_to):
        if self.figure is None:
            return
            
        x_to = int(x_to)
        if self._x_to != x_to:
            self._x_to = x_to
            self.axes.set_xlim(right=self._x_to)
            self.xToChanged.emit()

    xTo=Property(int, get_xTo, set_xTo, notify=xToChanged)

    def get_legend(self):
        return self._legend

    def set_legend(self, legend):
        if self.figure is None:
            return
            
        if self._legend != legend:
            self._legend = legend
            if self._legend:
                self.axes.legend()
            else:
                leg = self.axes.get_legend()
                if leg is not None:
                    leg.remove()
            self.legendChanged.emit()

    legend=QtCore.Property(bool, get_legend, set_legend, notify=legendChanged)

    def get_about(self):
        msg = __doc__
        return msg.strip()

    about=QtCore.Property(str, get_about)
    
    @QtCore.Slot()
    def update_figure(self):
        if self.figure is None:
            return
    
        self.axes.clear()
        self.axes.grid(True)
        
        has_series = False

        for row in range(self._data.rowCount()):
            model_index = self._data.index(row, 0)
            checked = self._data.data(model_index, DataSeriesModel.SelectedRole)
            
            if checked:
                has_series = True
                name = self._data.data(model_index, DataSeriesModel.NameRole)                
                values = self._data.data(model_index, DataSeriesModel.DataRole)
                
                self.axes.plot(range(len(values)), values, 'o-', label=name)

        self.axes.set_xlim((self.xFrom, self.xTo))
        if has_series and self.legend:
            self.axes.legend()
        
        self.stateChanged.emit()
        
def main():
    qInstallMessageHandler(lambda x, y, msg: print(msg))

    argv = sys.argv
    
    # Trick to set the style / not found how to do it in pythonic way
    #argv.extend(["-style", "universal"])

    app = QApplication(argv)

    qmlRegisterType(FigureCanvasQTAgg, "Backend", 1, 0, "FigureCanvasByPython")
    qmlRegisterType(FigureCanvasQTAggToolbar, "Backend", 1, 0, "FigureToolbarByPython")

    # this should work in the future
    # qmlRegisterType(
    #     QUrl.fromLocalFile( str(pathlib.Path(backend_qquick5agg.__file__)/'SubplotTool.qml')),
    #     "Backend", 1, 0, "SubplotTool")

    imgProvider = MatplotlibIconProvider()
    
    # !! You must specified the QApplication as parent of QQmlApplicationEngine
    # otherwise a segmentation fault is raised when exiting the app
    engine = QQmlApplicationEngine(parent=app)
    engine.addImageProvider("mplIcons", imgProvider)
    
    context = engine.rootContext()
    data_model = DataSeriesModel()
    context.setContextProperty("dataModel", data_model)
    mainApp = Form(data=data_model)
    context.setContextProperty("draw_mpl", mainApp)
    
    engine.load(QUrl(str(pathlib.Path(__file__).parent/'main_mpl_qtquick_main.qml')))
    
    win = engine.rootObjects()[0]

    figure=win.findChild(QObject, "figure")
    mainApp.figure = figure.getFigure()
    
    rc = app.exec_()
    # There is some trouble arising when deleting all the objects here
    # but I have not figure out how to solve the error message.
    # It looks like 'app' is destroyed before some QObject
    sys.exit(rc)

if __name__ == "__main__":
    # os.environ['QT_PLUGIN_PATH']=str(pathlib.Path(PySide2.__file__).parent/'Qt'/'plugins')
    # os.environ['QML2_IMPORT_PATH']=str(pathlib.Path(PySide2.__file__).parent/'Qt'/'qml')
    #os.environ['QT_QUICK_CONTROLS_STYLE']="Material"
    main()