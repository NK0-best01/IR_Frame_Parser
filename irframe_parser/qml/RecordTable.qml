import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Table Header
        Rectangle {
            Layout.fillWidth: true
            height: 38
            color: "#c9daf8"
            border.color: "#777777"
            border.width: 1
            radius: 4

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Label {
                    Layout.preferredWidth: 60
                    text: "ลำดับ"
                    font.bold: true
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
                Rectangle { width: 1; Layout.fillHeight: true; color: "#777777" }
                Label {
                    Layout.preferredWidth: 170
                    text: "สนง."
                    font.bold: true
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
                Rectangle { width: 1; Layout.fillHeight: true; color: "#777777" }
                Label {
                    Layout.preferredWidth: 120
                    text: "วันที่รับเคส"
                    font.bold: true
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
                Rectangle { width: 1; Layout.fillHeight: true; color: "#777777" }
                Label {
                    Layout.preferredWidth: 110
                    text: "สถานะแจ้งซ่อม"
                    font.bold: true
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
                Rectangle { width: 1; Layout.fillHeight: true; color: "#777777" }
                Label {
                    Layout.preferredWidth: 130
                    text: "Serial Number"
                    font.bold: true
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
                Rectangle { width: 1; Layout.fillHeight: true; color: "#777777" }
                Label {
                    Layout.fillWidth: true
                    text: "ประเภทครุภัณฑ์"
                    font.bold: true
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
                Rectangle { width: 1; Layout.fillHeight: true; color: "#777777" }
                Label {
                    Layout.preferredWidth: 70
                    text: "จัดการ"
                    font.bold: true
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Table Body
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: listView
                anchors.fill: parent
                model: backendModel
                spacing: 2

                delegate: Rectangle {
                    width: listView.width
                    height: 40
                    color: index % 2 === 0 ? "#ffffff" : "#f8fafc"
                    border.color: "#cbd5e1"
                    border.width: 1
                    radius: 3

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 6

                        Label {
                            Layout.preferredWidth: 50
                            text: model.no !== undefined ? model.no : (index + 1)
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }

                        TextField {
                            Layout.preferredWidth: 165
                            text: model.office !== undefined ? model.office : ""
                            font.pixelSize: 13
                            selectByMouse: true
                            onEditingFinished: {
                                backendModel.update_cell(index, "office", text)
                            }
                        }

                        TextField {
                            Layout.preferredWidth: 115
                            text: model.date !== undefined ? model.date : ""
                            placeholderText: "dd/mm/yyyy"
                            font.pixelSize: 13
                            selectByMouse: true
                            onEditingFinished: {
                                backendModel.update_cell(index, "date", text)
                            }
                        }

                        TextField {
                            Layout.preferredWidth: 105
                            text: model.status !== undefined ? model.status : ""
                            font.pixelSize: 13
                            selectByMouse: true
                            onEditingFinished: {
                                backendModel.update_cell(index, "status", text)
                            }
                        }

                        TextField {
                            Layout.preferredWidth: 125
                            text: model.sn !== undefined ? model.sn : ""
                            font.family: "Consolas"
                            font.pixelSize: 13
                            selectByMouse: true
                            color: text.trim() === "" ? "#dc2626" : "#111827"
                            placeholderText: "(ไม่มี SN)"
                            onEditingFinished: {
                                backendModel.update_cell(index, "sn", text)
                            }
                        }

                        TextField {
                            Layout.fillWidth: true
                            text: model.type !== undefined ? model.type : ""
                            font.pixelSize: 13
                            selectByMouse: true
                            onEditingFinished: {
                                backendModel.update_cell(index, "type", text)
                            }
                        }

                        Button {
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 30
                            text: "ลบ"
                            contentItem: Text {
                                text: "ลบ"
                                color: "white"
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.down ? "#b91c1c" : (parent.hovered ? "#ef4444" : "#dc2626")
                                radius: 4
                            }
                            onClicked: {
                                backendModel.delete_row(index)
                            }
                        }
                    }
                }
            }
        }
    }
}
