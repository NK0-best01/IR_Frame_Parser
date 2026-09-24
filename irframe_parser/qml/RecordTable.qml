import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    function getSortIndicator(colName) {
        if (backendModel.sortColumn === colName) {
            return backendModel.sortAscending ? " ▲" : " ▼";
        }
        return " ⇅";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Table Header with Clickable Column Sorting
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
                anchors.rightMargin: 16
                spacing: 8

                // Column: Checkbox Select All (Width: 36)
                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.fillHeight: true
                    color: "transparent"

                    CheckBox {
                        id: headerCheckBox
                        anchors.centerIn: parent
                        checked: backendModel.allSelected
                        indicator: Rectangle {
                            implicitWidth: 18
                            implicitHeight: 18
                            anchors.centerIn: parent
                            radius: 4
                            border.color: headerCheckBox.checked ? "#0284c7" : "#94a3b8"
                            border.width: 1.5
                            color: headerCheckBox.checked ? "#0284c7" : "#ffffff"

                            Label {
                                anchors.centerIn: parent
                                text: "✓"
                                font.bold: true
                                font.pixelSize: 12
                                color: "#ffffff"
                                visible: headerCheckBox.checked
                            }
                        }
                        onToggled: {
                            backendModel.toggle_select_all(checked)
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 18
                        color: "#cbd5e1"
                    }
                }

                // Column: # No (Width: 50)
                Rectangle {
                    Layout.preferredWidth: 50
                    Layout.fillHeight: true
                    color: headerNoMouse.hovered ? "#e2e8f0" : "transparent"
                    radius: 4

                    Label {
                        anchors.centerIn: parent
                        text: "#" + root.getSortIndicator("no")
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 13
                        color: backendModel.sortColumn === "no" ? "#0284c7" : "#475569"
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 18
                        color: "#cbd5e1"
                    }

                    HoverHandler { id: headerNoMouse }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backendModel.sort_by_col("no")
                    }
                }

                // Column: Office (Width: 175)
                Rectangle {
                    Layout.preferredWidth: 175
                    Layout.fillHeight: true
                    color: headerOfficeMouse.hovered ? "#e2e8f0" : "transparent"
                    radius: 4

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "สำนักงาน / สาขา" + root.getSortIndicator("office")
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 13
                        color: backendModel.sortColumn === "office" ? "#0284c7" : "#475569"
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 18
                        color: "#cbd5e1"
                    }

                    HoverHandler { id: headerOfficeMouse }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backendModel.sort_by_col("office")
                    }
                }

                // Column: Date (Width: 115)
                Rectangle {
                    Layout.preferredWidth: 115
                    Layout.fillHeight: true
                    color: headerDateMouse.hovered ? "#e2e8f0" : "transparent"
                    radius: 4

                    Label {
                        anchors.centerIn: parent
                        text: "วันที่รับเคส" + root.getSortIndicator("date")
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 13
                        color: backendModel.sortColumn === "date" ? "#0284c7" : "#475569"
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 18
                        color: "#cbd5e1"
                    }

                    HoverHandler { id: headerDateMouse }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backendModel.sort_by_col("date")
                    }
                }

                // Column: Status (Width: 150)
                Rectangle {
                    Layout.preferredWidth: 150
                    Layout.fillHeight: true
                    color: headerStatusMouse.hovered ? "#e2e8f0" : "transparent"
                    radius: 4

                    Label {
                        anchors.centerIn: parent
                        text: "สถานะแจ้งซ่อม" + root.getSortIndicator("status")
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 13
                        color: backendModel.sortColumn === "status" ? "#0284c7" : "#475569"
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 18
                        color: "#cbd5e1"
                    }

                    HoverHandler { id: headerStatusMouse }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backendModel.sort_by_col("status")
                    }
                }

                // Column: SN (Width: 135)
                Rectangle {
                    Layout.preferredWidth: 135
                    Layout.fillHeight: true
                    color: headerSnMouse.hovered ? "#e2e8f0" : "transparent"
                    radius: 4

                    Label {
                        anchors.centerIn: parent
                        text: "Serial Number" + root.getSortIndicator("sn")
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 13
                        color: backendModel.sortColumn === "sn" ? "#0284c7" : "#475569"
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 18
                        color: "#cbd5e1"
                    }

                    HoverHandler { id: headerSnMouse }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backendModel.sort_by_col("sn")
                    }
                }

                // Column: Type (Fill Width)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: headerTypeMouse.hovered ? "#e2e8f0" : "transparent"
                    radius: 4

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "เครื่อง/อุปกรณ์" + root.getSortIndicator("type")
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 13
                        color: backendModel.sortColumn === "type" ? "#0284c7" : "#475569"
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 18
                        color: "#cbd5e1"
                    }

                    HoverHandler { id: headerTypeMouse }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backendModel.sort_by_col("type")
                    }
                }

                // Column: Action (Width: 60)
                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.fillHeight: true
                    color: "transparent"

                    Label {
                        anchors.centerIn: parent
                        text: "จัดการ"
                        font.family: appFontFamily
                        font.bold: true
                        font.pixelSize: 13
                        color: "#475569"
                    }
                }
            }
        }

        // Table Rows with Visible ScrollBar
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

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
                    text: "ไม่พบรายการที่ตรงกับเงื่อนไข"
                    font.family: appFontFamily
                    font.pixelSize: 16
                    font.bold: true
                    color: "#334155"
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "ลองตรวจสอบคำค้นหา หรือวางข้อความแจ้งซ่อมแล้วกด 'คัดแยกข้อมูล'"
                    font.family: appFontFamily
                    font.pixelSize: 13
                    color: "#64748b"
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            ListView {
                id: listView
                anchors.fill: parent
                model: backendModel
                spacing: 6
                clip: true
                visible: count > 0

                // ScrollBar
                ScrollBar.vertical: ScrollBar {
                    id: vScrollBar
                    active: true
                    policy: ScrollBar.AsNeeded
                    width: 8

                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: vScrollBar.pressed ? "#334155" : (vScrollBar.hovered ? "#64748b" : "#94a3b8")
                    }

                    background: Rectangle {
                        implicitWidth: 8
                        color: "transparent"
                    }
                }

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
                        anchors.rightMargin: 16
                        spacing: 8

                        // Column: Row Checkbox (Width: 36)
                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.fillHeight: true
                            color: "transparent"

                            CheckBox {
                                id: rowCheckBox
                                anchors.centerIn: parent
                                Binding on checked {
                                    value: model.selected !== undefined ? model.selected : false
                                }
                                indicator: Rectangle {
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    anchors.centerIn: parent
                                    radius: 4
                                    border.color: rowCheckBox.checked ? "#0284c7" : "#94a3b8"
                                    border.width: 1.5
                                    color: rowCheckBox.checked ? "#0284c7" : "#ffffff"

                                    Label {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        font.bold: true
                                        font.pixelSize: 12
                                        color: "#ffffff"
                                        visible: rowCheckBox.checked
                                    }
                                }
                                onToggled: {
                                    backendModel.set_row_selected(index, checked)
                                }
                            }
                        }

                        // Number Badge
                        Rectangle {
                            Layout.preferredWidth: 50
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
                            leftPadding: 8
                            rightPadding: 8
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
                            Layout.preferredWidth: 115
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

                        // Status Dropdown (เคสทัสสกรีนเสีย / เคสทำเครื่องทดแทน)
                        ComboBox {
                            id: statusCombo
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 32
                            model: ["เคสทัสสกรีนเสีย", "เคสทำเครื่องทดแทน"]
                            Binding on currentIndex {
                                value: (model.status && model.status.indexOf("ทดแทน") !== -1) ? 1 : 0
                            }

                            contentItem: Label {
                                leftPadding: 8
                                rightPadding: 22
                                text: statusCombo.currentText
                                font.family: appFontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: statusCombo.currentIndex === 1 ? "#4338ca" : "#c2410c"
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            background: Rectangle {
                                color: statusCombo.currentIndex === 1 ? "#eef2ff" : "#fff7ed"
                                border.color: statusCombo.currentIndex === 1 ? "#c7d2fe" : "#fed7aa"
                                border.width: 1
                                radius: 6
                            }

                            indicator: Label {
                                anchors.right: statusCombo.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: statusCombo.verticalCenter
                                text: "▾"
                                font.pixelSize: 12
                                color: statusCombo.currentIndex === 1 ? "#4338ca" : "#c2410c"
                            }

                            popup: Popup {
                                y: statusCombo.height + 2
                                width: statusCombo.width
                                padding: 4
                                background: Rectangle {
                                    color: "#ffffff"
                                    border.color: "#cbd5e1"
                                    radius: 6
                                    border.width: 1
                                }
                                contentItem: ListView {
                                    clip: true
                                    implicitHeight: contentHeight
                                    model: statusCombo.popup.visible ? statusCombo.delegateModel : null
                                    currentIndex: statusCombo.highlightedIndex
                                }
                            }

                            delegate: ItemDelegate {
                                width: statusCombo.width - 8
                                height: 30
                                contentItem: Label {
                                    text: modelData
                                    font.family: appFontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: modelData === "เคสทำเครื่องทดแทน" ? "#4338ca" : "#c2410c"
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 6
                                }
                                background: Rectangle {
                                    color: highlighted ? "#f1f5f9" : "transparent"
                                    radius: 4
                                }
                            }

                            onActivated: function(idx) {
                                var selectedStatus = statusCombo.textAt(idx);
                                backendModel.update_cell(index, "status", selectedStatus);
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
                            leftPadding: 8
                            rightPadding: 8
                            color: "#334155"
                            selectByMouse: true
                            placeholderText: "เครื่อง/อุปกรณ์"
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
                        Rectangle {
                            id: deleteBox
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 30
                            radius: 6
                            color: delMouse.pressed ? "#b91c1c" : (delMouse.containsMouse ? "#ef4444" : "#fee2e2")
                            border.color: delMouse.containsMouse ? "transparent" : "#fca5a5"
                            border.width: 1

                            Label {
                                anchors.centerIn: parent
                                text: "ลบ"
                                font.family: appFontFamily
                                font.bold: true
                                font.pixelSize: 12
                                color: delMouse.containsMouse ? "#ffffff" : "#ef4444"
                            }

                            MouseArea {
                                id: delMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
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
