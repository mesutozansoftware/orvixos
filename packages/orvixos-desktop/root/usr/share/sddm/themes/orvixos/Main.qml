// OrvixOS giriş ekranı (SDDM teması, Qt 6)
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: root
    property bool turkish: Qt.locale().name.indexOf("tr") === 0
    function tr(t, e) { return turkish ? t : e }
    width: 1920
    height: 1080
    color: "#0b1220"

    readonly property color teal: "#2ee6d6"
    readonly property color violet: "#7c5cff"
    readonly property color muted: "#9ba1b6"
    readonly property color panel: Qt.rgba(1, 1, 1, 0.06)
    readonly property color line: Qt.rgba(1, 1, 1, 0.12)
    readonly property real unit: Math.max(1, Math.min(width / 1920, height / 1080) * 1.25)

    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string errorText: ""
    property var userNames: []
    property var realNames: []

    readonly property string userName: userNames[userIndex] || userModel.lastUser || ""
    readonly property string realName: realNames[userIndex] || userName

    // Model verileri rol adlarıyla okunur (SDDM sürümleri arasında rol
    // numaraları değişebilir).
    Repeater {
        model: userModel
        delegate: Item {
            Component.onCompleted: {
                var names = root.userNames.slice(); names[index] = model.name
                var reals = root.realNames.slice(); reals[index] = model.realName
                root.userNames = names; root.realNames = reals
            }
        }
    }
    Repeater {
        model: sessionModel
        delegate: Item {
            Component.onCompleted: {
                // Son kullanılan oturum yoksa TRLDE seçilir.
                if (sessionModel.lastIndex < 0 && String(model.name) === "TRLDE")
                    root.sessionIndex = index
            }
        }
    }

    function tryLogin() {
        errorText = ""
        sddm.login(userName, password.text, sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.errorText = root.tr("Parola yanlış. Yeniden dene.", "Wrong password. Try again.")
            password.text = ""
            password.forceActiveFocus()
            shake.start()
        }
    }

    // Arka plan: koyu lacivert üzerinde yumuşak turkuaz ve mor ışıklar.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0d1830" }
            GradientStop { position: 0.55; color: "#0b1220" }
            GradientStop { position: 1.0; color: "#120f2a" }
        }
    }
    Rectangle {
        width: root.width * 0.75; height: width; radius: width / 2
        x: -width * 0.35; y: -height * 0.45
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.18, 0.90, 0.84, 0.16) }
            GradientStop { position: 1.0; color: Qt.rgba(0.18, 0.90, 0.84, 0.0) }
        }
    }
    Rectangle {
        width: root.width * 0.7; height: width; radius: width / 2
        x: root.width - width * 0.55; y: root.height - height * 0.5
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.49, 0.36, 1.0, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0.49, 0.36, 1.0, 0.20) }
        }
    }
    // Büyük OrvixOS yörünge halkası (dekoratif).
    Rectangle {
        width: root.height * 0.95; height: width; radius: width / 2
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.height * 0.08
        color: "transparent"
        border.width: Math.max(2, 3 * root.unit)
        border.color: Qt.rgba(0.18, 0.90, 0.84, 0.07)
    }

    // Saat ve tarih
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.height * 0.12
        spacing: 4 * root.unit
        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            font.pixelSize: 92 * root.unit
            font.weight: Font.Light
            text: Qt.formatTime(new Date(), "HH:mm")
        }
        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.muted
            font.pixelSize: 20 * root.unit
            text: new Date().toLocaleDateString(Qt.locale(), "d MMMM yyyy, dddd")
        }
        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: {
                clock.text = Qt.formatTime(new Date(), "HH:mm")
                date.text = new Date().toLocaleDateString(Qt.locale(), "d MMMM yyyy, dddd")
            }
        }
    }

    // Giriş kartı
    Column {
        id: loginBox
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.height * 0.08
        spacing: 16 * root.unit
        width: 360 * root.unit

        // Avatar: kullanıcının baş harfi, gradyan halka
        Item {
            width: 112 * root.unit; height: width
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
                anchors.fill: parent; radius: width / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.teal }
                    GradientStop { position: 1.0; color: root.violet }
                }
            }
            Rectangle {
                anchors.fill: parent; anchors.margins: 4 * root.unit
                radius: width / 2; color: "#13203a"
                Text {
                    anchors.centerIn: parent
                    color: "white"
                    font.pixelSize: 46 * root.unit
                    font.weight: Font.DemiBold
                    text: root.realName.length > 0 ? root.realName.charAt(0).toUpperCase() : "?"
                }
            }
        }

        // Kullanıcı adı (birden çok kullanıcıda oklarla değişir)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14 * root.unit
            Text {
                visible: userModel.count > 1
                text: "‹"; color: root.muted; font.pixelSize: 30 * root.unit
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.userIndex = (root.userIndex - 1 + userModel.count) % userModel.count
                }
            }
            Text {
                text: root.realName
                color: "white"
                font.pixelSize: 26 * root.unit
                font.weight: Font.DemiBold
            }
            Text {
                visible: userModel.count > 1
                text: "›"; color: root.muted; font.pixelSize: 30 * root.unit
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.userIndex = (root.userIndex + 1) % userModel.count
                }
            }
        }

        // Parola alanı ve giriş düğmesi
        Item {
            id: passwordRow
            width: parent.width; height: 52 * root.unit
            SequentialAnimation {
                id: shake
                NumberAnimation { target: passwordRow; property: "x"; to: -12; duration: 50 }
                NumberAnimation { target: passwordRow; property: "x"; to: 12; duration: 50 }
                NumberAnimation { target: passwordRow; property: "x"; to: -6; duration: 50 }
                NumberAnimation { target: passwordRow; property: "x"; to: 0; duration: 50 }
            }
            TextField {
                id: password
                anchors.left: parent.left
                anchors.right: loginButton.left
                anchors.rightMargin: 10 * root.unit
                height: parent.height
                echoMode: TextInput.Password
                placeholderText: root.tr("Parola", "Password")
                placeholderTextColor: root.muted
                color: "white"
                font.pixelSize: 18 * root.unit
                leftPadding: 18 * root.unit
                focus: true
                background: Rectangle {
                    radius: height / 2
                    color: root.panel
                    border.width: password.activeFocus ? 2 : 1
                    border.color: password.activeFocus ? root.teal : root.line
                }
                Keys.onReturnPressed: root.tryLogin()
                Keys.onEnterPressed: root.tryLogin()
            }
            Rectangle {
                id: loginButton
                anchors.right: parent.right
                width: parent.height; height: parent.height; radius: height / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.teal }
                    GradientStop { position: 1.0; color: root.violet }
                }
                Text {
                    anchors.centerIn: parent
                    text: "→"; color: "#07101d"
                    font.pixelSize: 24 * root.unit; font.weight: Font.Bold
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.tryLogin()
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.errorText
            color: "#ff8a8a"
            font.pixelSize: 15 * root.unit
            height: 20 * root.unit
        }
    }

    // Sol alt: OrvixOS logosu
    Image {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 36 * root.unit
        source: config.logo || "file:///usr/share/pixmaps/orvixos-login.png"
        height: 40 * root.unit
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    // Sağ alt: oturum seçimi ve güç düğmeleri
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 30 * root.unit
        spacing: 12 * root.unit

        ComboBox {
            id: sessionBox
            width: 220 * root.unit
            height: 42 * root.unit
            model: sessionModel
            textRole: "name"
            currentIndex: root.sessionIndex
            onActivated: function(index) { root.sessionIndex = index }
            font.pixelSize: 15 * root.unit
            contentItem: Text {
                leftPadding: 16 * root.unit
                verticalAlignment: Text.AlignVCenter
                text: root.tr("Oturum: ", "Session: ") + sessionBox.displayText
                color: "white"
                font: sessionBox.font
                elide: Text.ElideRight
            }
            background: Rectangle {
                radius: height / 2
                color: root.panel
                border.color: root.line
            }
        }

        Repeater {
            model: [
                { label: root.tr("Uyku", "Sleep"), action: "suspend", enabled: sddm.canSuspend },
                { label: root.tr("Yeniden başlat", "Restart"), action: "reboot", enabled: sddm.canReboot },
                { label: root.tr("Kapat", "Shut down"), action: "poweroff", enabled: sddm.canPowerOff }
            ]
            delegate: Rectangle {
                required property var modelData
                visible: modelData.enabled
                height: 42 * root.unit
                width: label.implicitWidth + 32 * root.unit
                radius: height / 2
                color: hover.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : root.panel
                border.color: root.line
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: modelData.label
                    color: "white"
                    font.pixelSize: 15 * root.unit
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.action === "suspend") sddm.suspend()
                        else if (modelData.action === "reboot") sddm.reboot()
                        else sddm.powerOff()
                    }
                }
            }
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
