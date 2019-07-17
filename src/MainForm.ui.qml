import Backend 1.0
import QtQuick.Dialogs 1.2
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.13
import "backend"

Item {
    anchors.fill: parent

    RowLayout {
        id: hbox
        spacing: 5
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.fill: parent

        ColumnLayout {
            spacing: 0
            width: 640
            height: 480

            Layout.fillWidth: true

            FigureToolbarByPython {
                id: mplView
                objectName: "figure"

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
                    try {
                        mplView.print_figure(fileUrl)
                    } catch (error) {
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
                    mplView.left_impl = Qt.binding(function () {
                        return setMargin.left.value
                    })
                    mplView.right_impl = Qt.binding(function () {
                        return setMargin.right.value
                    })
                    mplView.top_impl = Qt.binding(function () {
                        return setMargin.top.value
                    })
                    mplView.bottom_impl = Qt.binding(function () {
                        return setMargin.bottom.value
                    })

                    mplView.hspace_impl = Qt.binding(function () {
                        return setMargin.hspace.value
                    })
                    mplView.wspace_impl = Qt.binding(function () {
                        return setMargin.wspace.value
                    })
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
                height: 48

                Layout.maximumHeight: height
                Layout.minimumHeight: height
                Layout.alignment: Qt.AlignLeft | Qt.Bottom
                Layout.fillWidth: true

                RowLayout {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    anchors.fill: parent
                    spacing: 0

                    ToolButton {
                        id: home

                        contentItem: Image {
                            fillMode: Image.PreserveAspectFit
                            source: "image://mplIcons/home"
                        }
                        onClicked: {
                            mplView.home()
                        }
                    }

                    ToolButton {
                        id: back
                        contentItem: Image {
                            fillMode: Image.PreserveAspectFit
                            source: "image://mplIcons/back"
                        }
                        onClicked: {
                            mplView.back()
                        }
                    }

                    ToolButton {
                        id: forward

                        contentItem: Image {
                            fillMode: Image.PreserveAspectFit
                            source: "image://mplIcons/forward"
                        }
                        onClicked: {
                            mplView.forward()
                        }
                    }

                    // Fake separator
                    Label {
                        text: "|"
                    }

                    ButtonGroup {
                        // Gather pan and zoom tools to make them auto-exclusive
                        id: pan_zoom
                    }

                    ToolButton {
                        id: pan

                        contentItem: Image {
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
                        id: zoom

                        contentItem: Image {
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
                        text: "|"
                    }

                    ToolButton {
                        id: subplots
                        contentItem: Image {
                            fillMode: Image.PreserveAspectFit
                            source: "image://mplIcons/subplots"
                        }
                        onClicked: {
                            setMargin.initMargin()
                            setMargin.open()
                        }
                    }

                    ToolButton {
                        id: save
                        contentItem: Image {
                            fillMode: Image.PreserveAspectFit
                            source: "image://mplIcons/filesave"
                        }
                        onClicked: {
                            saveFileDialog.open()
                        }
                    }

/*
                    ToolButton {
                        id: figureOptions

                        contentItem: Image {
                            fillMode: Image.PreserveAspectFit
                            source: "image://mplIcons/qt4_editor_options"
                        }

                        visible: mplView.figureOptions

                        onClicked: {

                        }
                    }
*/
                    Item {
                        Layout.fillWidth: true
                    }

                    Label {
                        id: locLabel

                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                        text: mplView.message
                    }
                }
            }
        }

        Connections {
            target: dataModel
            onDataChanged: {
                console.warn("--begin-- update_figure from js")
                draw_mpl.update_figure()
                console.warn("--begin-- update_figure from js")
            }
        }

        Pane {
            id: right
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.fillHeight: true

            ColumnLayout {
                id: right_vbox

                spacing: 2

                Label {
                    id: log_label
                    text: qsTr("Data series:")
                }

                ListView {
                    id: series_list_view
                    height: 180
                    Layout.fillWidth: true

                    clip: true

                    model: dataModel
                    delegate: CheckBox {
                        checked: false
                        text: name
                        onClicked: {
                            selected = checked
                        }
                    }
                }

                RowLayout {
                    id: rowLayout1
                    Layout.fillWidth: true

                    Label {
                        id: spin_label1
                        text: qsTr("X")
                    }

                    RangeSlider {
                        id: xSlider
                        first.value: draw_mpl.xFrom
                        second.value: draw_mpl.xTo
                        from: 0
                        to: dataModel.lengthData - 1
                        enabled: series_list_view.count > 0
                    }

                    Binding {
                        target: draw_mpl
                        property: "xFrom"
                        value: xSlider.first.value
                    }

                    Binding {
                        target: draw_mpl
                        property: "xTo"
                        value: xSlider.second.value
                    }
                }

                Switch {
                    id: legend_cb
                    text: qsTr("Show Legend")
                    checked: draw_mpl.legend
                }

                Binding {
                    target: draw_mpl
                    property: "legend"
                    value: legend_cb.checked
                }
            }
        }
    }
}
