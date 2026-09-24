import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: previewScroll
    clip: true

    Item {
        width: Math.max(previewScroll.width, 920)
        height: docContainer.height + 60

        Rectangle {
            id: docContainer
            width: 860
            anchors.horizontalCenter: parent.horizontalCenter
            y: 30
            color: "#ffffff"
            border.color: "#cbd5e1"
            border.width: 1
            radius: 8
            implicitHeight: docLayout.implicitHeight + 40

            // Paper subtle elevation shadow
            Rectangle {
                anchors.fill: parent
                z: -1
                color: "#000000"
                opacity: 0.04
                radius: 10
                anchors.bottomMargin: -6
                anchors.rightMargin: -6
            }

            ColumnLayout {
                id: docLayout
                anchors.fill: parent
                anchors.margins: 24
                spacing: 0

                // Header Document Title
                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 55
                    text: "รายการเบิก IR Frame"
                    font.family: appFontFamily
                    font.pixelSize: 22
                    font.bold: true
                    color: "#0f172a"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                // Subtitle Blue Box
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: "#00b0f0"
                    border.color: "#475569"
                    border.width: 2

                    Label {
                        anchors.centerIn: parent
                        text: "รายการเบิกเฉพาะ IR frame (…..........................................)"
                        font.family: appFontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: "#000000"
                    }
                }

                // Table Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    color: "#c9daf8"
                    border.color: "#64748b"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Label { Layout.preferredWidth: 50; text: "ลำดับ"; font.family: appFontFamily; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                        Rectangle { width: 1; Layout.fillHeight: true; color: "#64748b" }
                        Label { Layout.preferredWidth: 170; text: "สนง."; font.family: appFontFamily; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                        Rectangle { width: 1; Layout.fillHeight: true; color: "#64748b" }
                        Label { Layout.preferredWidth: 110; text: "วันที่รับเคส"; font.family: appFontFamily; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                        Rectangle { width: 1; Layout.fillHeight: true; color: "#64748b" }
                        Label { Layout.preferredWidth: 110; text: "สถานะแจ้งซ่อม"; font.family: appFontFamily; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                        Rectangle { width: 1; Layout.fillHeight: true; color: "#64748b" }
                        Label { Layout.preferredWidth: 130; text: "Serial Number"; font.family: appFontFamily; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                        Rectangle { width: 1; Layout.fillHeight: true; color: "#64748b" }
                        Label { Layout.fillWidth: true; text: "เครื่อง/อุปกรณ์"; font.family: appFontFamily; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                    }
                }

                // Table Rows
                Repeater {
                    model: backendModel

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        color: "#ffffff"
                        border.color: "#94a3b8"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Label {
                                Layout.preferredWidth: 50
                                text: model.no !== undefined ? model.no : (index + 1)
                                font.family: appFontFamily
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Rectangle { width: 1; Layout.fillHeight: true; color: "#94a3b8" }
                            Label {
                                Layout.preferredWidth: 170
                                text: model.office !== undefined ? model.office : ""
                                font.family: appFontFamily
                                font.pixelSize: 12
                                leftPadding: 8
                                elide: Text.ElideRight
                            }
                            Rectangle { width: 1; Layout.fillHeight: true; color: "#94a3b8" }
                            Label {
                                Layout.preferredWidth: 110
                                text: model.date !== undefined ? model.date : ""
                                font.family: appFontFamily
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Rectangle { width: 1; Layout.fillHeight: true; color: "#94a3b8" }
                            Label {
                                Layout.preferredWidth: 110
                                text: model.status !== undefined ? model.status : ""
                                font.family: appFontFamily
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Rectangle { width: 1; Layout.fillHeight: true; color: "#94a3b8" }
                            Label {
                                Layout.preferredWidth: 130
                                text: model.sn !== undefined ? model.sn : ""
                                font.family: "Consolas"
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Rectangle { width: 1; Layout.fillHeight: true; color: "#94a3b8" }
                            Label {
                                Layout.fillWidth: true
                                text: model.type !== undefined ? model.type : ""
                                font.family: appFontFamily
                                font.pixelSize: 12
                                leftPadding: 8
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // Missing SN Note
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    visible: hasMissingSn

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "***IR Frame ไม่มีเลข SN"
                        font.family: appFontFamily
                        color: "#dc2626"
                        font.bold: true
                        font.pixelSize: 12
                    }
                }

                // Signature Box
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        anchors.bottom: parent.bottom
                        width: 250
                        height: 120
                        color: "transparent"
                        border.color: "#475569"
                        border.width: 2

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 4

                            Label {
                                Layout.fillWidth: true
                                text: "ผู้ขอเบิกอุปกรณ์"
                                font.family: appFontFamily
                                font.bold: true
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                Layout.topMargin: 8
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
                                font.family: appFontFamily
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                Layout.bottomMargin: 8
                            }
                        }
                    }
                }
            }
        }
    }
}
