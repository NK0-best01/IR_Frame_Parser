import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: window
    width: 1360
    height: 880
    minimumWidth: 1080
    minimumHeight: 680
    visible: true
    title: "IR Frame Requisition Manager — ระบบจัดการข้อมูลและออกใบเบิก"
    color: "#f8fafc"

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
        title: "เลือกโฟลเดอร์สำหรับบันทึกไฟล์ Excel (.xlsx)"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Excel Files (*.xlsx)"]
        currentFile: "file:///รายการเบิก_IR_Frame.xlsx"
        defaultSuffix: "xlsx"
        onAccepted: {
            var path = selectedFile.toString()
            backendModel.export_xlsx(path)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        // Top App Bar
        Rectangle {
            Layout.fillWidth: true
            height: 64
            color: "#ffffff"
            border.color: "#e2e8f0"
            border.width: 1
            radius: 12

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 14

                Rectangle {
                    width: 40
                    height: 40
                    radius: 10
                    color: "#0284c7"

                    Label {
                        anchors.centerIn: parent
                        text: "IR"
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 18
                        color: "#ffffff"
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Label {
                        text: "รายการเบิก IR Frame"
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 17
                        color: "#0f172a"
                    }
                    Label {
                        text: "ระบบคัดแยกข้อความแจ้งซ่อม • จัดการข้อมูลครุภัณฑ์ • Export แบบฟอร์ม Excel"
                        font.family: appFontFamily
                        font.pixelSize: 12
                        color: "#64748b"
                    }
                }

                Item { Layout.fillWidth: true }

                // Mode Indicator Badge
                Rectangle {
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 150
                    color: "#f1f5f9"
                    border.color: "#e2e8f0"
                    radius: 15

                    Label {
                        anchors.centerIn: parent
                        text: "● Desktop Edition V1.2"
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 11
                        color: "#0284c7"
                    }
                }
            }
        }

        // Main Split Workspace (Left: Input & Controls, Right: Table & Preview)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // LEFT DESK: Input & Controls (Width: 380px)
            Rectangle {
                Layout.preferredWidth: 380
                Layout.fillHeight: true
                color: "#ffffff"
                border.color: "#e2e8f0"
                border.width: 1
                radius: 12

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Card Title
                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "ข้อความต้นฉบับ (Raw Ticket)"
                            font.family: appFontFamily
                            font.bold: true
                            font.pixelSize: 14
                            color: "#1e293b"
                        }
                        Item { Layout.fillWidth: true }
                        Label {
                            text: "Ctrl+V เพื่อวาง"
                            font.family: appFontFamily
                            font.pixelSize: 11
                            color: "#94a3b8"
                        }
                    }

                    // Text Area Container
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        TextArea {
                            id: rawTextArea
                            placeholderText: "วางข้อความแจ้งซ่อมจากแชท/ไลน์ที่นี่...\nระบบจะดึงข้อมูล:\n- สนง. / สาขา\n- วันที่รับเคส\n- สถานะแจ้งซ่อม\n- Serial Number (หลาย SN ได้)\n- ประเภทครุภัณฑ์"
                            font.family: "Consolas"
                            font.pixelSize: 13
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            color: "#0f172a"
                            background: Rectangle {
                                color: "#f8fafc"
                                border.color: rawTextArea.activeFocus ? "#0284c7" : "#cbd5e1"
                                border.width: 1
                                radius: 8
                            }
                        }
                    }

                    // Action Buttons for Parsing
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            text: "⚡ คัดแยกข้อมูล (Parse Data)"
                            contentItem: Text {
                                text: "⚡ คัดแยกข้อมูล (Parse Data)"
                                font.family: appFontFamily
                                font.bold: true
                                font.pixelSize: 14
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.down ? "#0369a1" : (parent.hovered ? "#0284c7" : "#0ea5e9")
                                radius: 8
                            }
                            onClicked: {
                                if (rawTextArea.text.trim() === "") return;
                                backendModel.parse_raw(rawTextArea.text)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Button {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                text: "โหลดตัวอย่าง"
                                contentItem: Text {
                                    text: "โหลดตัวอย่าง 15 เคส"
                                    font.family: appFontFamily
                                    font.bold: true
                                    font.pixelSize: 12
                                    color: "#ffffff"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: parent.down ? "#0f172a" : (parent.hovered ? "#334155" : "#1e293b")
                                    radius: 6
                                }
                                onClicked: {
                                    backendModel.load_example()
                                }
                            }

                            Button {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                text: "ล้างข้อความ"
                                contentItem: Text {
                                    text: "ล้างกล่องข้อความ"
                                    font.family: appFontFamily
                                    font.bold: true
                                    font.pixelSize: 12
                                    color: "#475569"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: parent.down ? "#cbd5e1" : (parent.hovered ? "#e2e8f0" : "#f1f5f9")
                                    radius: 6
                                    border.color: "#cbd5e1"
                                    border.width: 1
                                }
                                onClicked: {
                                    rawTextArea.text = ""
                                    rawTextArea.forceActiveFocus()
                                }
                            }
                        }
                    }

                    // Summary Stats Card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        color: "#f8fafc"
                        border.color: "#e2e8f0"
                        border.width: 1
                        radius: 8

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            Label {
                                text: "สรุปรายการปัจจุบัน"
                                font.family: appFontFamily
                                font.bold: true
                                font.pixelSize: 12
                                color: "#475569"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Total Card
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 52
                                    color: "#ffffff"
                                    border.color: "#cbd5e1"
                                    radius: 6

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Label {
                                            text: window.totalCount.toString()
                                            font.family: appFontFamily
                                            font.bold: true
                                            font.pixelSize: 18
                                            color: "#0f172a"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                        Label {
                                            text: "ทั้งหมด (แถว)"
                                            font.family: appFontFamily
                                            font.pixelSize: 10
                                            color: "#64748b"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }

                                // With SN Card
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 52
                                    color: "#f0fdf4"
                                    border.color: "#bbf7d0"
                                    radius: 6

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Label {
                                            text: window.withSnCount.toString()
                                            font.family: appFontFamily
                                            font.bold: true
                                            font.pixelSize: 18
                                            color: "#166534"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                        Label {
                                            text: "มีเลข SN"
                                            font.family: appFontFamily
                                            font.pixelSize: 10
                                            color: "#15803d"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }

                                // Missing SN Card
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 52
                                    color: window.missingSnCount > 0 ? "#fff7ed" : "#ffffff"
                                    border.color: window.missingSnCount > 0 ? "#fed7aa" : "#cbd5e1"
                                    radius: 6

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Label {
                                            text: window.missingSnCount.toString()
                                            font.family: appFontFamily
                                            font.bold: true
                                            font.pixelSize: 18
                                            color: window.missingSnCount > 0 ? "#c2410c" : "#64748b"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                        Label {
                                            text: "ไม่มีเลข SN"
                                            font.family: appFontFamily
                                            font.pixelSize: 10
                                            color: window.missingSnCount > 0 ? "#ea580c" : "#64748b"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // RIGHT WORKSPACE: Table / Document Preview (Flex width)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#ffffff"
                border.color: "#e2e8f0"
                border.width: 1
                radius: 12

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Workspace Toolbar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Segmented View Switcher
                        Rectangle {
                            Layout.preferredWidth: 320
                            Layout.preferredHeight: 38
                            color: "#f1f5f9"
                            radius: 8

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 2

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: workspaceStack.currentIndex === 0 ? "#ffffff" : "transparent"
                                    radius: 6
                                    border.color: workspaceStack.currentIndex === 0 ? "#e2e8f0" : "transparent"

                                    Label {
                                        anchors.centerIn: parent
                                        text: "📋 ตารางจัดการข้อมูล"
                                        font.family: appFontFamily
                                        font.bold: workspaceStack.currentIndex === 0
                                        font.pixelSize: 12
                                        color: workspaceStack.currentIndex === 0 ? "#0f172a" : "#64748b"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: workspaceStack.currentIndex = 0
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: workspaceStack.currentIndex === 1 ? "#ffffff" : "transparent"
                                    radius: 6
                                    border.color: workspaceStack.currentIndex === 1 ? "#e2e8f0" : "transparent"

                                    Label {
                                        anchors.centerIn: parent
                                        text: "📄 พรีวิวใบเบิก (Print)"
                                        font.family: appFontFamily
                                        font.bold: workspaceStack.currentIndex === 1
                                        font.pixelSize: 12
                                        color: workspaceStack.currentIndex === 1 ? "#0f172a" : "#64748b"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: workspaceStack.currentIndex = 1
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Add Row Button
                        Button {
                            Layout.preferredHeight: 38
                            text: "＋ เพิ่มรายการ"
                            contentItem: Text {
                                text: "＋ เพิ่มรายการ"
                                font.family: appFontFamily
                                font.bold: true
                                font.pixelSize: 13
                                color: "#334155"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.down ? "#e2e8f0" : (parent.hovered ? "#f1f5f9" : "#ffffff")
                                radius: 8
                                border.color: "#cbd5e1"
                                border.width: 1
                            }
                            onClicked: {
                                backendModel.add_row()
                            }
                        }

                        // Export Excel Button
                        Button {
                            Layout.preferredHeight: 38
                            text: "⬇ Export Excel (.xlsx)"
                            contentItem: Text {
                                text: "⬇ Export Excel (.xlsx)"
                                font.family: appFontFamily
                                font.bold: true
                                font.pixelSize: 13
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.down ? "#047857" : (parent.hovered ? "#10b981" : "#059669")
                                radius: 8
                            }
                            onClicked: {
                                exportDialog.open()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#f1f5f9"
                    }

                    // Content Stack
                    StackLayout {
                        id: workspaceStack
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: 0

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
        }
    }
}
