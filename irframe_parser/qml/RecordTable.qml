import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Table Header
        Rectangle {
            Layout.fillWidth: true
            height: 42
            color: "#f1f5f9"
            border.color: "#e2e8f0"
            border.width: 1
            radius: 8

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Label {
                    Layout.preferredWidth: 55
                    text: "#"
                    font.family: appFontFamily
                    font.bold: true
                    font.pixelSize: 13
                    color: "#475569"
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle { width: 1; height: 18; color: "#cbd5e1" }

                Label {
                    Layout.preferredWidth: 175
                    text: "สำนักงาน / สาขา"
                    font.family: appFontFamily
                    font.bold: true
                    font.pixelSize: 13
                    color: "#475569"
                    leftPadding: 6
                }

                Rectangle { width: 1; height: 18; color: "#cbd5e1" }

                Label {
                    Layout.preferredWidth: 110
                    text: "วันที่รับเคส"
                    font.family: appFontFamily
                    font.bold: true
                    font.pixelSize: 13
                    color: "#475569"
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle { width: 1; height: 18; color: "#cbd5e1" }

                Label {
                    Layout.preferredWidth: 110
                    text: "สถานะแจ้งซ่อม"
                    font.family: appFontFamily
                    font.bold: true
                    font.pixelSize: 13
                    color: "#475569"
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle { width: 1; height: 18; color: "#cbd5e1" }

                Label {
                    Layout.preferredWidth: 135
                    text: "Serial Number"
                    font.family: appFontFamily
                    font.bold: true
                    font.pixelSize: 13
                    color: "#475569"
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle { width: 1; height: 18; color: "#cbd5e1" }

                Label {
                    Layout.fillWidth: true
                    text: "ประเภทครุภัณฑ์ / รุ่น"
                    font.family: appFontFamily
                    font.bold: true
                    font.pixelSize: 13
                    color: "#475569"
                    leftPadding: 6
                }

                Rectangle { width: 1; height: 18; color: "#cbd5e1" }

                Label {
                    Layout.preferredWidth: 65
                    text: "จัดการ"
                    font.family: appFontFamily
                    font.bold: true
                    font.pixelSize: 13
                    color: "#475569"
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Table Rows or Empty State
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Item {
                width: parent.width
                height: Math.max(listView.contentHeight, 350)

                // Empty State
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: listView.count === 0

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 64
                        height: 64
                        radius: 32
                        color: "#f1f5f9"

                        Label {
                            anchors.centerIn: parent
                            text: "📋"
                            font.pixelSize: 28
                        }
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "ยังไม่มีรายการในตาราง"
                        font.family: appFontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: "#334155"
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "วางข้อความแจ้งซ่อมที่แผงด้านซ้ายแล้วกด 'คัดแยกข้อมูล'\nหรือกดปุ่ม 'โหลดตัวอย่าง' เพื่อทดสอบ"
                        font.family: appFontFamily
                        font.pixelSize: 13
                        color: "#64748b"
                        horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.3
                    }
                }

                ListView {
                    id: listView
                    anchors.fill: parent
                    model: backendModel
                    spacing: 6
                    visible: count > 0

                    delegate: Rectangle {
                        id: rowDelegate
                        width: listView.width
                        height: 48
                        color: rowHoverHandler.hovered ? "#f8fafc" : "#ffffff"
                        border.color: rowHoverHandler.hovered ? "#93c5fd" : "#e2e8f0"
                        border.width: 1
                        radius: 8

                        HoverHandler {
                            id: rowHoverHandler
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            // Number Badge
                            Rectangle {
                                Layout.preferredWidth: 55
                                Layout.preferredHeight: 28
                                color: "#f1f5f9"
                                radius: 6

                                Label {
                                    anchors.centerIn: parent
                                    text: model.no !== undefined ? model.no : (index + 1)
                                    font.family: appFontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#475569"
                                }
                            }

                            // Office Field
                            TextField {
                                id: officeField
                                Layout.preferredWidth: 175
                                text: model.office !== undefined ? model.office : ""
                                font.family: appFontFamily
                                font.pixelSize: 13
                                color: "#0f172a"
                                selectByMouse: true
                                placeholderText: "สนง. / สาขา"
                                background: Rectangle {
                                    color: officeField.activeFocus ? "#f0f9ff" : "transparent"
                                    border.color: officeField.activeFocus ? "#0284c7" : "transparent"
                                    border.width: 1
                                    radius: 6
                                }
                                onEditingFinished: {
                                    if (text !== (model.office || "")) {
                                        backendModel.update_cell(index, "office", text)
                                    }
                                }
                            }

                            // Date Field
                            TextField {
                                id: dateField
                                Layout.preferredWidth: 110
                                text: model.date !== undefined ? model.date : ""
                                font.family: appFontFamily
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                color: "#334155"
                                selectByMouse: true
                                placeholderText: "วว/ดด/ปปปป"
                                background: Rectangle {
                                    color: dateField.activeFocus ? "#f0f9ff" : "#f8fafc"
                                    border.color: dateField.activeFocus ? "#0284c7" : "#e2e8f0"
                                    border.width: 1
                                    radius: 6
                                }
                                onEditingFinished: {
                                    if (text !== (model.date || "")) {
                                        backendModel.update_cell(index, "date", text)
                                    }
                                }
                            }

                            // Status Field with Amber Badge
                            TextField {
                                id: statusField
                                Layout.preferredWidth: 110
                                text: model.status !== undefined ? model.status : ""
                                font.family: appFontFamily
                                font.pixelSize: 12
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                color: "#92400e"
                                selectByMouse: true
                                background: Rectangle {
                                    color: statusField.activeFocus ? "#fef3c7" : "#fffbeb"
                                    border.color: statusField.activeFocus ? "#d97706" : "#fde68a"
                                    border.width: 1
                                    radius: 6
                                }
                                onEditingFinished: {
                                    if (text !== (model.status || "")) {
                                        backendModel.update_cell(index, "status", text)
                                    }
                                }
                            }

                            // Serial Number with Monospace Box
                            TextField {
                                id: snField
                                Layout.preferredWidth: 135
                                text: model.sn !== undefined ? model.sn : ""
                                font.family: "Consolas"
                                font.pixelSize: 13
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                color: snField.text.trim() === "" ? "#dc2626" : "#0369a1"
                                selectByMouse: true
                                placeholderText: "— ไม่มี SN —"
                                background: Rectangle {
                                    color: snField.text.trim() === "" ? "#fef2f2" : "#f0f9ff"
                                    border.color: snField.activeFocus ? "#0284c7" : (snField.text.trim() === "" ? "#fca5a5" : "#bae6fd")
                                    border.width: 1
                                    radius: 6
                                }
                                onEditingFinished: {
                                    if (text !== (model.sn || "")) {
                                        backendModel.update_cell(index, "sn", text)
                                    }
                                }
                            }

                            // Equipment Type
                            TextField {
                                id: typeField
                                Layout.fillWidth: true
                                text: model.type !== undefined ? model.type : ""
                                font.family: appFontFamily
                                font.pixelSize: 13
                                color: "#334155"
                                selectByMouse: true
                                placeholderText: "ประเภทครุภัณฑ์"
                                background: Rectangle {
                                    color: typeField.activeFocus ? "#f0f9ff" : "transparent"
                                    border.color: typeField.activeFocus ? "#0284c7" : "transparent"
                                    border.width: 1
                                    radius: 6
                                }
                                onEditingFinished: {
                                    if (text !== (model.type || "")) {
                                        backendModel.update_cell(index, "type", text)
                                    }
                                }
                            }

                            // Delete Action Button
                            Button {
                                id: deleteButton
                                Layout.preferredWidth: 55
                                Layout.preferredHeight: 32
                                text: "ลบ"
                                contentItem: Text {
                                    text: "ลบ"
                                    font.family: appFontFamily
                                    font.bold: true
                                    font.pixelSize: 12
                                    color: deleteButton.hovered ? "#ffffff" : "#ef4444"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: deleteButton.down ? "#b91c1c" : (deleteButton.hovered ? "#ef4444" : "#fee2e2")
                                    radius: 6
                                    border.color: deleteButton.hovered ? "transparent" : "#fca5a5"
                                    border.width: 1
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
}
