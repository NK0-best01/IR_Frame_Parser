import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: previewScroll
    clip: true

    Item {
        width: Math.max(previewScroll.width, 880)
        height: docContainer.height + 40

        Rectangle {
            id: docContainer
            width: 860
            anchors.horizontalCenter: parent.horizontalCenter
            y: 20
            color: "#ffffff"
            border.color: "#d1d5db"
            border.width: 1
            radius: 8
            implicitHeight: docLayout.implicitHeight + 36

            ColumnLayout {
                id: docLayout
                anchors.fill: parent
                anchors.margins: 18
                spacing: 0

                // Title
                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    text: "รายการเบิก IR Frame"
                    font.pixelSize: 22
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                // Subtitle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    color: "#00b0f0"
                    border.color: "#555555"
                    border.width: 2

                    Label {
                        anchors.centerIn: parent
                        text: "รายการเบิกเฉพาะ IR frame (…..........................................)"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#000000"
                    }
                }

                // Table Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    color: "#c9daf8"
                    border.color: "#777777"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Label { Layout.preferredWidth: 50; text: "ลำดับ"; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                        Rectangle { width: 1; Layout.fillHeight: true; color: "#777777" }
                        Label { Layout.preferredWidth: 170; text: "สนง."; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                        Rectangle { width: 1; Layout.fillHeight: true; color: "#777777" }
                        Label { Layout.preferredWidth: 110; text: "วันที่รับเคส"; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                        Rectangle { width: 1; Layout.fillHeight: true; color: "#777777" }
                        Label { Layout.preferredWidth: 110; text: "สถานะแจ้งซ่อม"; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                        Rectangle { width: 1; Layout.fillHeight: true; color: "#777777" }
                        Label { Layout.preferredWidth: 130; text: "Serial Number"; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                        Rectangle { width: 1; Layout.fillHeight: true; color: "#777777" }
                        Label { Layout.fillWidth: true; text: "ประเภทครุภัณฑ์"; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                    }
                }

                // Table Rows
                Repeater {
                    model: backendModel

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: "#ffffff"
                        border.color: "#999999"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Label {
                                Layout.preferredWidth: 50
                                text: model.no !== undefined ? model.no : (index + 1)
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Rectangle { width: 1; Layout.fillHeight: true; color: "#999999" }
                            Label {
                                Layout.preferredWidth: 170
                                text: model.office !== undefined ? model.office : ""
                                font.pixelSize: 12
                                leftPadding: 6
                                elide: Text.ElideRight
                            }
                            Rectangle { width: 1; Layout.fillHeight: true; color: "#999999" }
                            Label {
                                Layout.preferredWidth: 110
                                text: model.date !== undefined ? model.date : ""
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Rectangle { width: 1; Layout.fillHeight: true; color: "#999999" }
                            Label {
                                Layout.preferredWidth: 110
                                text: model.status !== undefined ? model.status : ""
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Rectangle { width: 1; Layout.fillHeight: true; color: "#999999" }
                            Label {
                                Layout.preferredWidth: 130
                                text: model.sn !== undefined ? model.sn : ""
                                font.pixelSize: 12
                                font.family: "Consolas"
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Rectangle { width: 1; Layout.fillHeight: true; color: "#999999" }
                            Label {
                                Layout.fillWidth: true
                                text: model.type !== undefined ? model.type : ""
                                font.pixelSize: 12
                                leftPadding: 6
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // Missing SN Note
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    visible: hasMissingSn

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "***IR Frame ไม่มีเลข SN"
                        color: "#dc2626"
                        font.bold: true
                        font.pixelSize: 12
                    }
                }

                // Signature Box
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.bottom: parent.bottom
                        width: 250
                        height: 120
                        color: "transparent"
                        border.color: "#555555"
                        border.width: 2

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 4

                            Label {
                                Layout.fillWidth: true
                                text: "ผู้ขอเบิกอุปกรณ์"
                                font.bold: true
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                Layout.topMargin: 6
                            }

                            Label {
                                Layout.fillWidth: true
                                text: "__________________"
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Item { Layout.fillHeight: true }

                            Label {
                                Layout.fillWidth: true
                                text: "_____/______/______"
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                Layout.bottomMargin: 6
                            }
                        }
                    }
                }
            }
        }
    }
}
