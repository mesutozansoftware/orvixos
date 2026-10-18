// OrvixOS kurulum slaytları (Calamares)
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function onActivate() { }
    function onLeave() { }

    Timer {
        interval: 15000
        repeat: true
        running: presentation.activatedInCalamares
        onTriggered: presentation.goToNextSlide()
    }

    Rectangle { anchors.fill: parent; color: "#0b1220"; z: -1 }

    Slide {
        Image {
            id: logo1
            source: "logo.png"
            width: 140; height: 140
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 30
        }
        Text {
            anchors.top: logo1.bottom; anchors.topMargin: 24
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "white"; font.pixelSize: 20
            text: "OrvixOS'a hoş geldin.<br/><span style='color:#9ba1b6;font-size:15px'>Kurulum birkaç dakika içinde tamamlanacak.</span>"
            textFormat: Text.RichText
        }
    }
    Slide {
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "white"; font.pixelSize: 20
            textFormat: Text.RichText
            text: "<b style='color:#2ee6d6'>vpx</b> ile uygulama kurmak çok kolay:<br/><br/><span style='font-family:monospace;color:#9ba1b6'>vpx install libreoffice<br/>vpx sync</span>"
        }
    }
    Slide {
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "white"; font.pixelSize: 20
            textFormat: Text.RichText
            text: "<b style='color:#2ee6d6'>TRLDE</b> masaüstü kısayolları:<br/><br/><span style='color:#9ba1b6'>Super + Boşluk: uygulama menüsü<br/>Super + Enter: terminal<br/>Super + B: tarayıcı</span>"
        }
    }
}
