import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: window
    width: 1280
    height: 850
    minimumWidth: 1000
    minimumHeight: 650
    visible: true
    title: "รายการเบิก IR Frame — Data Parser (Desktop App)"
    color: "#f4f7fb"

    property int totalCount: 0
    property int withSnCount: 0
    property int missingSnCount: 0
    property bool hasMissingSn: false

    Connections {
        target: backendModel
        function onStatsChanged(total, withSn, missingSn) {
            window.totalCount = total
            window.withSnCount = withSn
            window.missingSnCount = missingSn
            window.hasMissingSn = missingSn > 0
        }
    }

    FileDialog {
        id: exportDialog
        title: "บันทึกไฟล์ Excel (.xlsx)"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Excel Files (*.xlsx)"]
        currentFile: "file:///รายการเบิก IR Frame.xlsx"
        onAccepted: {
            var path = selectedFile.toString()
            backendModel.export_xlsx(path)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Top Header
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 2
                Label {
                    text: "รายการเบิก IR Frame"
                    font.pixelSize: 22
                    font.bold: true
                    color: "#172033"
                }
                Label {
                    text: "วางข้อมูล → คัดแยก → ตรวจสอบ/แก้ไข → Export .xlsx"
                    font.pixelSize: 13
                    color: "#667085"
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 160
                color: "#eef2ff"
                radius: 16
                Label {
                    anchors.centerIn: parent
                    text: "IR Frame Parser V1.1.4"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#4338ca"
                }
            }
        }

        // Card 1: Raw Text Input
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            color: "#ffffff"
            border.color: "#dce3ed"
            border.width: 1
            radius: 10

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Label {
                    text: "วางข้อมูลต้นฉบับที่นี่"
                    font.bold: true
                    font.pixelSize: 13
                    color: "#172033"
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextArea {
                        id: rawTextArea
                        placeholderText: "Copy ข้อมูลแจ้งซ่อมแล้ววางได้เลย ระบบจะพยายามแยก สนง. / วันที่ / สถานะ / Serial Number / ประเภทครุภัณฑ์ ให้"
                        font.family: "Consolas"
                        font.pixelSize: 13
                        wrapMode: TextArea.Wrap
                        selectByMouse: true
                        background: Rectangle {
                            color: "#ffffff"
                            border.color: "#cbd5e1"
                            radius: 6
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        text: "⚙ คัดแยกข้อมูล"
                        contentItem: Text {
                            text: "⚙ คัดแยกข้อมูล"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.down ? "#0284c7" : (parent.hovered ? "#38bdf8" : "#0ea5e9")
                            radius: 6
                        }
                        onClicked: {
                            if (rawTextArea.text.trim() === "") return;
                            backendModel.parse_raw(rawTextArea.text)
                        }
                    }

                    Button {
                        text: "ล้างข้อความ"
                        contentItem: Text {
                            text: "ล้างข้อความ"
                            color: "#111827"
                            font.bold: true
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.down ? "#d1d5db" : (parent.hovered ? "#f3f4f6" : "#e5e7eb")
                            radius: 6
                        }
                        onClicked: {
                            rawTextArea.text = ""
                        }
                    }

                    Button {
                        text: "โหลดตัวอย่างจากไฟล์ต้นฉบับ"
                        contentItem: Text {
                            text: "โหลดตัวอย่างจากไฟล์ต้นฉบับ"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.down ? "#111827" : (parent.hovered ? "#374151" : "#1f2937")
                            radius: 6
                        }
                        onClicked: {
                            backendModel.load_example()
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }

        // Stats & Action Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredHeight: 30
                Layout.preferredWidth: 120
                color: "#eef2ff"
                radius: 15
                Label {
                    anchors.centerIn: parent
                    text: "ทั้งหมด " + window.totalCount + " รายการ"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#3730a3"
                }
            }

            Rectangle {
                Layout.preferredHeight: 30
                Layout.preferredWidth: 100
                color: "#dcfce7"
                radius: 15
                Label {
                    anchors.centerIn: parent
                    text: "มี SN " + window.withSnCount
                    font.pixelSize: 12
                    font.bold: true
                    color: "#166534"
                }
            }

            Rectangle {
                Layout.preferredHeight: 30
                Layout.preferredWidth: 120
                color: window.missingSnCount > 0 ? "#ffedd5" : "#dcfce7"
                radius: 15
                Label {
                    anchors.centerIn: parent
                    text: window.missingSnCount > 0 ? ("ไม่มี SN " + window.missingSnCount) : "ข้อมูล SN ครบ"
                    font.pixelSize: 12
                    font.bold: true
                    color: window.missingSnCount > 0 ? "#9a3412" : "#166534"
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "＋ เพิ่มรายการ"
                contentItem: Text {
                    text: "＋ เพิ่มรายการ"
                    color: "#111827"
                    font.bold: true
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.down ? "#d1d5db" : (parent.hovered ? "#f3f4f6" : "#e5e7eb")
                    radius: 6
                }
                onClicked: {
                    backendModel.add_row()
                }
            }

            Button {
                text: "⬇ Export Excel (.xlsx)"
                contentItem: Text {
                    text: "⬇ Export Excel (.xlsx)"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.down ? "#15803d" : (parent.hovered ? "#22c55e" : "#16a34a")
                    radius: 6
                }
                onClicked: {
                    exportDialog.open()
                }
            }
        }

        // View Tabs: Table vs Document Preview
        TabBar {
            id: viewTabBar
            Layout.fillWidth: true

            TabButton {
                text: "📋 ตารางแก้ไขข้อมูล (Edit Table)"
                font.pixelSize: 13
                font.bold: true
            }
            TabButton {
                text: "📄 ตัวอย่างเอกสารก่อน Export (Preview)"
                font.pixelSize: 13
                font.bold: true
            }
        }

        // Tab Content
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: viewTabBar.currentIndex

            RecordTable {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Preview {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
