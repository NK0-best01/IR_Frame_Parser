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
    property int waitingCount: 0
    property int completedCount: 0
    property int currentRowLimit: 10 // Default 10 rows

    Connections {
        target: backendModel
        function onSummaryStatsChanged(total, waiting, completed) {
            window.totalCount = total
            window.waitingCount = waiting
            window.completedCount = completed
        }
        function onStatsChanged(total, withSn, missingSn) {
            window.totalCount = total
        }
    }

    Component.onCompleted: {
        startupCheckTimer.start()
    }

    Timer {
        id: startupCheckTimer
        interval: 450
        repeat: false
        onTriggered: {
            var count = backendModel.check_expired_completed_count(30)
            if (count > 0) {
                expiredCleanupDialog.expiredCount = count
                expiredCleanupDialog.open()
            }
        }
    }

    Dialog {
        id: expiredCleanupDialog
        property int expiredCount: 0
        modal: true
        anchors.centerIn: Overlay.overlay
        width: 480
        padding: 24
        dim: true
        closePolicy: Popup.CloseOnEscape
        background: Rectangle {
            color: "#ffffff"
            radius: 14
            border.color: "#cbd5e1"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 16

            RowLayout {
                spacing: 12
                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: "#fef2f2"
                    border.color: "#fecaca"
                    Label {
                        anchors.centerIn: parent
                        text: "🗑️"
                        font.pixelSize: 22
                    }
                }
                ColumnLayout {
                    spacing: 2
                    Label {
                        text: "แจ้งเตือนการล้างรายการซ่อมเสร็จ"
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 16
                        color: "#0f172a"
                    }
                    Label {
                        text: "เงื่อนไข: สถานะ 'เสร็จแล้ว' ครบกำหนด 30 วัน"
                        font.family: appFontFamily
                        font.pixelSize: 12
                        color: "#64748b"
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#f1f5f9"
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Label.WordWrap
                text: "พบรายการที่มีสถานะ <b>เสร็จแล้ว</b> และครบกำหนด 30 วัน จำนวน <b><font color='#dc2626'>" + expiredCleanupDialog.expiredCount + "</font></b> รายการ\n\nต้องการลบรายการเหล่านี้ออกจากระบบเพื่อลดความซ้ำซ้อนของข้อมูลหรือไม่?"
                font.family: appFontFamily
                font.pixelSize: 13
                color: "#334155"
                lineHeight: 1.3
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 10

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 38
                    radius: 8
                    color: cancelMouse.pressed ? "#cbd5e1" : (cancelMouse.containsMouse ? "#e2e8f0" : "#f1f5f9")
                    border.color: "#cbd5e1"

                    Label {
                        anchors.centerIn: parent
                        text: "เก็บไว้ก่อน"
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 13
                        color: "#475569"
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: expiredCleanupDialog.close()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 160
                    Layout.preferredHeight: 38
                    radius: 8
                    color: deleteConfirmMouse.pressed ? "#991b1b" : (deleteConfirmMouse.containsMouse ? "#dc2626" : "#ef4444")

                    Label {
                        anchors.centerIn: parent
                        text: "ยืนยันลบรายการ (" + expiredCleanupDialog.expiredCount + ")"
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 13
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: deleteConfirmMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            backendModel.confirm_delete_expired(30)
                            expiredCleanupDialog.close()
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: exportDialog
        title: "เลือกโฟลเดอร์สำหรับบันทึกไฟล์ Excel (.xlsx)"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Excel Files (*.xlsx)"]
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

        // Main Split Workspace
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
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#f8fafc"
                        border.color: rawTextArea.activeFocus ? "#0284c7" : "#cbd5e1"
                        border.width: 1
                        radius: 8

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 6
                            clip: true

                            TextArea {
                                id: rawTextArea
                                placeholderText: "วางข้อความแจ้งซ่อมจากแชท/ไลน์ที่นี่...\nระบบจะดึงข้อมูล:\n- สนง. / สาขา\n- วันที่รับเคส\n- สถานะแจ้งซ่อม\n- Serial Number (หลาย SN ได้)\n- ประเภทครุภัณฑ์"
                                font.family: "Consolas"
                                font.pixelSize: 13
                                wrapMode: TextArea.Wrap
                                selectByMouse: true
                                color: "#0f172a"
                                background: null
                            }
                        }
                    }

                    // Action Buttons for Parsing
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: 8
                            color: parseMouse.pressed ? "#0369a1" : (parseMouse.containsMouse ? "#0284c7" : "#0ea5e9")

                            Label {
                                anchors.centerIn: parent
                                text: "⚡ คัดแยกข้อมูล (Parse Data)"
                                font.family: appFontFamily
                                font.bold: true
                                font.pixelSize: 14
                                color: "#ffffff"
                            }

                            MouseArea {
                                id: parseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (rawTextArea.text.trim() === "") return;
                                    backendModel.parse_raw(rawTextArea.text)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 6
                                color: exampleMouse.pressed ? "#0f172a" : (exampleMouse.containsMouse ? "#334155" : "#1e293b")

                                Label {
                                    anchors.centerIn: parent
                                    text: "โหลดตัวอย่าง 15 เคส"
                                    font.family: appFontFamily
                                    font.bold: true
                                    font.pixelSize: 12
                                    color: "#ffffff"
                                }

                                MouseArea {
                                    id: exampleMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        backendModel.load_example()
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 6
                                color: clearMouse.pressed ? "#cbd5e1" : (clearMouse.containsMouse ? "#e2e8f0" : "#f1f5f9")
                                border.color: "#cbd5e1"
                                border.width: 1

                                Label {
                                    anchors.centerIn: parent
                                    text: "ล้างกล่องข้อความ"
                                    font.family: appFontFamily
                                    font.bold: true
                                    font.pixelSize: 12
                                    color: "#475569"
                                }

                                MouseArea {
                                    id: clearMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        rawTextArea.text = ""
                                        rawTextArea.forceActiveFocus()
                                    }
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

                                // 1. Total Card ("ทั้งหมด")
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
                                            text: "ทั้งหมด"
                                            font.family: appFontFamily
                                            font.pixelSize: 10
                                            color: "#64748b"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }

                                // 2. Waiting Parts Card ("รออะไหล่")
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 52
                                    color: window.waitingCount > 0 ? "#fffbeb" : "#ffffff"
                                    border.color: window.waitingCount > 0 ? "#fde68a" : "#cbd5e1"
                                    radius: 6

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Label {
                                            text: window.waitingCount.toString()
                                            font.family: appFontFamily
                                            font.bold: true
                                            font.pixelSize: 18
                                            color: window.waitingCount > 0 ? "#b45309" : "#64748b"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                        Label {
                                            text: "รออะไหล่"
                                            font.family: appFontFamily
                                            font.pixelSize: 10
                                            color: window.waitingCount > 0 ? "#92400e" : "#64748b"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }

                                // 3. Completed Card ("เสร็จแล้ว")
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 52
                                    color: window.completedCount > 0 ? "#f0fdf4" : "#ffffff"
                                    border.color: window.completedCount > 0 ? "#bbf7d0" : "#cbd5e1"
                                    radius: 6

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Label {
                                            text: window.completedCount.toString()
                                            font.family: appFontFamily
                                            font.bold: true
                                            font.pixelSize: 18
                                            color: window.completedCount > 0 ? "#15803d" : "#64748b"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                        Label {
                                            text: "เสร็จแล้ว"
                                            font.family: appFontFamily
                                            font.pixelSize: 10
                                            color: window.completedCount > 0 ? "#166534" : "#64748b"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // RIGHT WORKSPACE: Data Grid Workspace
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

                    // Workspace Toolbar with Search, Filter Row (10, 25, 50, All) & Export
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // 1. Text Search Input
                        Rectangle {
                            Layout.preferredWidth: 260
                            Layout.preferredHeight: 38
                            color: "#f8fafc"
                            border.color: searchInput.activeFocus ? "#0284c7" : "#cbd5e1"
                            border.width: 1
                            radius: 8

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 6

                                Label {
                                    text: "🔍"
                                    font.pixelSize: 13
                                }

                                TextField {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    placeholderText: "ค้นหา สนง., SN, รุ่น, วันที่..."
                                    font.family: appFontFamily
                                    font.pixelSize: 13
                                    color: "#0f172a"
                                    selectByMouse: true
                                    background: null
                                    onTextChanged: {
                                        backendModel.set_search_text(text)
                                    }
                                }

                                ToolButton {
                                    visible: searchInput.text.length > 0
                                    text: "✕"
                                    font.pixelSize: 11
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    onClicked: {
                                        searchInput.text = ""
                                    }
                                }
                            }
                        }

                        // 2. Row Limit Filter Segmented Buttons (10, 25, 50, All)
                        RowLayout {
                            spacing: 6

                            Label {
                                text: "แสดง:"
                                font.family: appFontFamily
                                font.bold: true
                                font.pixelSize: 12
                                color: "#64748b"
                            }

                            Rectangle {
                                Layout.preferredWidth: 220
                                Layout.preferredHeight: 38
                                color: "#f1f5f9"
                                radius: 8

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 2

                                    // Button 1: 10
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: window.currentRowLimit === 10 ? "#ffffff" : "transparent"
                                        radius: 6
                                        border.color: window.currentRowLimit === 10 ? "#cbd5e1" : "transparent"

                                        Label {
                                            anchors.centerIn: parent
                                            text: "10"
                                            font.family: appFontFamily
                                            font.bold: window.currentRowLimit === 10
                                            font.pixelSize: 12
                                            color: window.currentRowLimit === 10 ? "#0284c7" : "#64748b"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                window.currentRowLimit = 10
                                                backendModel.set_row_limit(10)
                                            }
                                        }
                                    }

                                    // Button 2: 25
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: window.currentRowLimit === 25 ? "#ffffff" : "transparent"
                                        radius: 6
                                        border.color: window.currentRowLimit === 25 ? "#cbd5e1" : "transparent"

                                        Label {
                                            anchors.centerIn: parent
                                            text: "25"
                                            font.family: appFontFamily
                                            font.bold: window.currentRowLimit === 25
                                            font.pixelSize: 12
                                            color: window.currentRowLimit === 25 ? "#0284c7" : "#64748b"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                window.currentRowLimit = 25
                                                backendModel.set_row_limit(25)
                                            }
                                        }
                                    }

                                    // Button 3: 50
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: window.currentRowLimit === 50 ? "#ffffff" : "transparent"
                                        radius: 6
                                        border.color: window.currentRowLimit === 50 ? "#cbd5e1" : "transparent"

                                        Label {
                                            anchors.centerIn: parent
                                            text: "50"
                                            font.family: appFontFamily
                                            font.bold: window.currentRowLimit === 50
                                            font.pixelSize: 12
                                            color: window.currentRowLimit === 50 ? "#0284c7" : "#64748b"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                window.currentRowLimit = 50
                                                backendModel.set_row_limit(50)
                                            }
                                        }
                                    }

                                    // Button 4: All (Last one is All)
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: window.currentRowLimit === 0 ? "#ffffff" : "transparent"
                                        radius: 6
                                        border.color: window.currentRowLimit === 0 ? "#cbd5e1" : "transparent"

                                        Label {
                                            anchors.centerIn: parent
                                            text: "All"
                                            font.family: appFontFamily
                                            font.bold: window.currentRowLimit === 0
                                            font.pixelSize: 12
                                            color: window.currentRowLimit === 0 ? "#0284c7" : "#64748b"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                window.currentRowLimit = 0
                                                backendModel.set_row_limit(0)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }


                        // 4. Export Excel Button
                        Rectangle {
                            Layout.preferredWidth: 170
                            Layout.preferredHeight: 38
                            radius: 8
                            color: exportMouse.pressed ? "#047857" : (exportMouse.containsMouse ? "#10b981" : "#059669")

                            Label {
                                anchors.centerIn: parent
                                text: "⬇ Export Excel (.xlsx)"
                                font.family: appFontFamily
                                font.bold: true
                                font.pixelSize: 13
                                color: "#ffffff"
                            }

                            MouseArea {
                                id: exportMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    exportDialog.open()
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#f1f5f9"
                    }

                    // Record Table View
                    RecordTable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
