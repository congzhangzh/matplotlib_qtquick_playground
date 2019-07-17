import Backend 1.0
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.13
import "../../backend"

Item{           
    width: 640
    height: 480

    ColumnLayout {
        spacing : 0
        anchors.fill: parent

        FigureToolbarByPython {
            id: mplView
            objectName : "figure"
                        
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Layout.minimumWidth: 10
            Layout.minimumHeight: 10
        }

        MessageDialog {
            id: messageDialog
        }
        
        FileDialog {
            id: saveFileDialog
            title: "Choose a filename to save to"
            folder: mplView.defaultDirectory
            nameFilters: mplView.fileFilters
            selectedNameFilter: mplView.defaultFileFilter
            selectExisting: false
            
            onAccepted: {
                try{
                    mplView.print_figure(fileUrl)
                }
                catch (error){
                    messageDialog.title = "Error saving file"
                    messageDialog.text = error
                    messageDialog.icon = StandardIcon.Critical
                    messageDialog.open()
                }
            }
        } 
        
        SubplotTool {
            id: setMargin
            
            left.value: mplView.left_impl
            right.value: mplView.right_impl
            top.value: mplView.top_impl
            bottom.value: mplView.bottom_impl
            
            hspace.value: mplView.hspace_impl
            wspace.value: mplView.wspace_impl
            
            function initMargin() {
                // Init slider value

                setMargin.left.value = mplView.left_impl
                setMargin.right.value = mplView.right_impl
                setMargin.top.value = mplView.top_impl
                setMargin.bottom.value = mplView.bottom_impl
                
                setMargin.hspace.value = mplView.hspace_impl
                setMargin.wspace.value = mplView.wspace_impl


                // Invert parameter bindings
                mplView.left_impl = Qt.binding(function() { return setMargin.left.value })
                mplView.right_impl = Qt.binding(function() { return setMargin.right.value })
                mplView.top_impl = Qt.binding(function() { return setMargin.top.value })
                mplView.bottom_impl = Qt.binding(function() { return setMargin.bottom.value })
                
                mplView.hspace_impl = Qt.binding(function() { return setMargin.hspace.value })
                mplView.wspace_impl = Qt.binding(function() { return setMargin.wspace.value })
            }
            
            onReset: {
                mplView.reset_margin()
                setMargin.initMargin()
            }
            
            onTightLayout: {
                mplView.tight_layout()
                setMargin.initMargin()
            }
        }
        

        ToolBar {
            id: toolbar
            
            Layout.alignment: Qt.AlignLeft | Qt.Bottom
            Layout.fillWidth: true
        
            RowLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                anchors.fill: parent
                spacing: 0
                
                ToolButton {
                    id : home
                    contentItem: Image{
                        fillMode: Image.PreserveAspectFit
                        source: "image://mplIcons/home"
                    }
                    onClicked: {
                        mplView.home()
                    }
                }     
                
                ToolButton {
                    id : back
                    contentItem: Image{
                        fillMode: Image.PreserveAspectFit
                        source: "image://mplIcons/back"
                    }
                    onClicked: {
                        mplView.back()
                    }
                }     
                
                ToolButton {
                    id : forward
                    
                    contentItem: Image{
                        fillMode: Image.PreserveAspectFit
                        source: "image://mplIcons/forward"
                    }
                    onClicked: {
                        mplView.forward()
                    }
                }     

                // Fake separator
                Label {
                    text : "|"
                }
                
                ButtonGroup {
                // Gather pan and zoom tools to make them auto-exclusive
                    id: pan_zoom
                }
                
                ToolButton {
                    id : pan
                    
                    contentItem: Image{
                        fillMode: Image.PreserveAspectFit
                        source: "image://mplIcons/move"
                    }
                    
                    ButtonGroup.group: pan_zoom
                    checkable: true
                    
                    onClicked: {
                        mplView.pan()
                    }
                }     
                
                ToolButton {
                    id : zoom
                    
                    contentItem: Image{
                        fillMode: Image.PreserveAspectFit
                        source: "image://mplIcons/zoom_to_rect"
                    }
                    
                    ButtonGroup.group: pan_zoom
                    checkable: true
                    
                    onClicked: {
                        mplView.zoom()
                    }
                }   

                Label {
                    text : "|"
                }
                
                ToolButton {
                    id : subplots
                    contentItem: Image{
                        fillMode: Image.PreserveAspectFit
                        source: "image://mplIcons/subplots"
                    }
                    onClicked: {
                        setMargin.initMargin()
                        setMargin.open()
                    }
                }
                
                ToolButton {
                    id : save
                    contentItem: Image{
                        fillMode: Image.PreserveAspectFit
                        source: "image://mplIcons/filesave"
                    }
                    onClicked: {
                        saveFileDialog.open()
                    }
                }      
                
                Item {
                    Layout.fillWidth: true
                }
                
                Label{
                    id: locLabel
                    
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    
                    text: mplView.message
                }
            }
        }
    }
}    
