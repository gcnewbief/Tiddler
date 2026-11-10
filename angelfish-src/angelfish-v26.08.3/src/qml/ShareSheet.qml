// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQuick.Window

import org.kde.kirigami as Kirigami

// UT replacement for the KF6 Purpose-based sheet: no Purpose plugins exist on
// the platform, so the original view would always be empty. Offers a plain
// copy-URL dialog instead. Proper Content Hub integration is future work.
Kirigami.Dialog {
    id: inputSheet
    property url url
    property string inputTitle

    title: i18nc("@title:window", "Share Page")
    preferredWidth: Kirigami.Units.gridUnit * 16
    standardButtons: Kirigami.Dialog.NoButton

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: inputSheet.inputTitle
            elide: Text.ElideRight
            maximumLineCount: 2
        }

        Controls.TextField {
            id: urlField
            Layout.fillWidth: true
            readOnly: true
            text: inputSheet.url
            onPressed: {
                forceActiveFocus()
                selectAll()
            }
        }

        Controls.Button {
            Layout.alignment: Qt.AlignHCenter
            icon.name: "edit-copy"
            text: i18nc("@action:button", "Copy URL")
            onClicked: {
                urlField.selectAll()
                urlField.copy()
                inputSheet.close()
            }
        }
    }
}
