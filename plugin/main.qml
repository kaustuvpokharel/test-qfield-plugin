import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.qfield

Item {
  id: root
  readonly property color bg: "#121212"
  readonly property color panelBg: "#181818"
  readonly property color cardBg: "#1f1f1f"
  readonly property color border: "#343434"
  readonly property color fg: "#f2f2f2"
  readonly property color muted: "#b7b7b7"
  readonly property color accent: "#7CFC00"

  readonly property int cardPad: 14

  readonly property bool narrow: (panel.visible ? panel.width : 0) < 720

  ListModel { id: logModel }

  function ts() {
    const d = new Date()
    const pad = (n) => (n < 10 ? "0" : "") + n
    return pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
  }

  function log(msg) {
    logModel.append({ t: ts(), m: String(msg) })
    console.log("[XHR Tester]", msg)
  }

  function readyStateName(st) {
    switch (st) {
      case 0: return "Unsent"
      case 1: return "Opened"
      case 2: return "HeadersReceived"
      case 3: return "Loading"
      case 4: return "Done"
      default: return "?"
    }
  }

  property var xhr: null

  Component {
    id: xhrComponent
    XmlHttpRequest {
      onreadystatechange: function() {
        root.log("onreadystatechange: " + root.readyStateName(readyState) + " (" + readyState + "), status=" + status)
      }
      ondownloadprogress: function(received, total) {
        root.log("ondownloadprogress: " + received + " / " + total)
      }
      onuploadprogress: function(sent, total) {
        root.log("onuploadprogress: " + sent + " / " + total)
      }
      onredirected: function(url) {
        root.log("onredirected: " + url)
      }
      ontimeout: function() {
        root.log("ontimeout")
      }
      onaborted: function() {
        root.log("onaborted")
      }
      onerror: function(code, message) {
        root.log("onerror: code=" + code + " message=" + message)
      }
    }
  }

  function ensureXhr() {
    if (xhr) return
    xhr = xhrComponent.createObject(root)
    root.log("XmlHttpRequest created")
  }

  function resetXhr() {
    if (xhr) {
      try { xhr.abort() } catch(e) {}
      xhr.destroy()
      xhr = null
    }
    ensureXhr()
    logModel.clear()
    root.log("Reset complete")
  }

  //UI ocmponents
  component Card: Rectangle {
    radius: 12
    color: root.cardBg
    border.color: root.border
    border.width: 1
  }

  component H1: Text {
    color: root.fg
    font.pixelSize: 22
    font.bold: true
    wrapMode: Text.Wrap
    elide: Text.ElideRight
    Layout.fillWidth: true
  }

  component H2: Text {
    color: root.fg
    font.pixelSize: 16
    font.bold: true
    wrapMode: Text.Wrap
    Layout.fillWidth: true
  }

  component BodyText: Text {
    color: root.muted
    font.pixelSize: 12
    wrapMode: Text.Wrap
    Layout.fillWidth: true
  }

  component FieldText: TextField {
    id: tf
    color: root.fg
    placeholderTextColor: root.muted
    selectionColor: "#355f1a"
    selectedTextColor: root.fg

    clip: true
    verticalAlignment: TextInput.AlignVCenter

    leftPadding: 12
    rightPadding: 12
    topPadding: 10
    bottomPadding: 10

    implicitHeight: Math.max(44, contentHeight + topPadding + bottomPadding)

    background: Rectangle {
      radius: 10
      color: "#141414"
      border.color: tf.activeFocus ? root.accent : root.border
      border.width: 1
    }
  }

  component FieldArea: TextArea {
    id: ta
    color: root.fg
    placeholderTextColor: root.muted
    selectionColor: "#355f1a"
    selectedTextColor: root.fg
    wrapMode: TextArea.Wrap

    clip: true

    leftPadding: 12
    rightPadding: 12
    topPadding: 10
    bottomPadding: 10

    background: Rectangle {
      radius: 10
      color: "#141414"
      border.color: ta.activeFocus ? root.accent : root.border
      border.width: 1
    }
  }

  component PillButton: Button {
    font.pixelSize: 13
    implicitHeight: 38
    background: Rectangle {
      radius: 999
      color: parent.down ? "#2a2a2a" : "#222"
      border.color: parent.hovered || parent.activeFocus ? root.accent : root.border
      border.width: 1
    }
    contentItem: Text {
      text: parent.text
      color: root.fg
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      width: parent.width
    }
  }

  component NiceCombo: ComboBox {
    id: cb
    padding: 10

    background: Rectangle {
      radius: 10
      color: "#141414"
      border.color: cb.activeFocus ? root.accent : root.border
      border.width: 1
    }

    contentItem: Text {
      text: cb.displayText
      color: root.fg
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      leftPadding: 8
      rightPadding: 28
    }

    indicator: Canvas {
      width: 14; height: 14
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        ctx.beginPath()
        ctx.moveTo(2, 4); ctx.lineTo(12, 4); ctx.lineTo(7, 10); ctx.closePath()
        ctx.fillStyle = root.fg
        ctx.fill()
      }
    }

    popup: Popup {
      id: pop
      y: cb.height + 6
      width: cb.width
      implicitHeight: Math.min(list.contentHeight, 280)

      background: Rectangle {
        radius: 10
        color: "#1a1a1a"
        border.color: root.border
        border.width: 1
      }

      contentItem: ListView {
        id: list
        clip: true
        model: cb.delegateModel
        currentIndex: cb.highlightedIndex

        delegate: ItemDelegate {
          width: ListView.view.width
          text: modelData
          highlighted: index === cb.highlightedIndex
        }
      }
    }
  }

  // toolbar button
  Rectangle {
    id: toolbarButton
    width: 40
    height: 40
    radius: 10
    color: "#2b2b2b"
    border.color: root.border
    border.width: 1

    Text {
      anchors.centerIn: parent
      text: "XHR"
      color: root.fg
      font.bold: true
      font.pixelSize: 12
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {
        ensureXhr()
        panel.open()
      }
    }
  }

  Popup {
    id: panel
    parent: iface.mainWindow().contentItem
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    width: Math.min(parent.width - 16, 920)
    height: Math.min(parent.height - 16, 920)
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    padding: 0

    background: Rectangle {
      color: root.panelBg
      radius: 14
      border.color: root.border
      border.width: 1
    }

    contentItem: Item {
      anchors.fill: parent

      Item {
        id: scrollHost
        anchors.fill: parent
        anchors.margins: 14

        Flickable {
          id: flick
          anchors.fill: parent
          anchors.rightMargin: vbar.width + 8
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          contentWidth: width
          contentHeight: contentCol.implicitHeight

          ScrollBar.vertical: ScrollBar {
            id: vbar
            parent: scrollHost
            anchors.top: scrollHost.top
            anchors.bottom: scrollHost.bottom
            anchors.right: scrollHost.right
            policy: ScrollBar.AlwaysOn
          }

          Column {
            id: contentCol
            width: flick.width
            spacing: 12

            // Header
            Row {
              width: parent.width
              spacing: 10

              Column {
                width: Math.max(200, parent.width - 240)
                spacing: 6

                H1 { text: "XmlHttpRequest Tester" }

                BodyText {
                  text: "Goal: validate core XmlHttpRequest behavior (readyState, headers, JSON/text, redirect, timeout, abort, multipart)."
                }
              }

              Item { width: 1; height: 1; Layout.fillWidth: true } // harmless spacer

              PillButton {
                text: "Reset XHR"
                onClicked: resetXhr()
              }

              PillButton {
                text: "Close"
                onClicked: panel.close()
              }
            }

            // Request card
            Card {
              width: parent.width
              implicitHeight: reqCol.implicitHeight + 20

              Column {
                id: reqCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.cardPad
                spacing: 10

                H2 { text: "Request" }

                GridLayout {
                  id: reqGrid
                  width: parent.width
                  columns: root.narrow ? 1 : 3
                  columnSpacing: 10
                  rowSpacing: 10

                  // Method
                  Item {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    NiceCombo {
                      id: methodBox
                      anchors.fill: parent
                      model: ["GET","POST","PUT","PATCH","DELETE","HEAD"]
                      currentIndex: 0
                    }
                  }

                  // URL
                  FieldText {
                    id: urlField
                    placeholderText: "https://httpbin.org/anything"
                    text: "https://httpbin.org/anything"
                    Layout.fillWidth: true
                  }

                  // Timeout
                  FieldText {
                    id: timeoutField
                    inputMethodHints: Qt.ImhDigitsOnly
                    placeholderText: "timeout ms (0 disables)"
                    text: "0"
                    Layout.fillWidth: true
                  }

                  // Headers (full row)
                  Item {
                    Layout.columnSpan: root.narrow ? 1 : 3
                    Layout.fillWidth: true
                    implicitHeight: 110

                    Column {
                      Layout.columnSpan: root.narrow ? 1 : 3
                      Layout.fillWidth: true
                      spacing: 6

                      BodyText {
                        text: "Headers (one per line). Example:\nContent-Type: application/json\nAuthorization: Bearer <token>"
                      }

                      FieldArea {
                        id: headersArea
                        Layout.fillWidth: true
                        Layout.preferredHeight: 90
                        text: ""
                      }
                    }
                  }
                }

                Flow {
                  width: parent.width
                  spacing: 10

                  PillButton {
                    text: "Send (text/json)"
                    onClicked: {
                      ensureXhr()
                      sendTextOrJson()
                    }
                  }

                  PillButton {
                    text: "GET /get"
                    onClicked: {
                      urlField.text = "https://httpbin.org/get"
                      methodBox.currentIndex = 0
                      timeoutField.text = "0"
                      headersArea.text = ""
                      bodyArea.text = ""
                      sendTextOrJson()
                    }
                  }

                  PillButton {
                    text: "Redirect"
                    onClicked: {
                      urlField.text = "https://httpbin.org/redirect/1"
                      methodBox.currentIndex = 0
                      timeoutField.text = "0"
                      headersArea.text = ""
                      bodyArea.text = ""
                      sendTextOrJson()
                    }
                  }

                  PillButton {
                    text: "Timeout"
                    onClicked: {
                      urlField.text = "https://httpbin.org/delay/5"
                      methodBox.currentIndex = 0
                      timeoutField.text = "1000"
                      headersArea.text = ""
                      bodyArea.text = ""
                      sendTextOrJson()
                    }
                  }

                  PillButton {
                    text: "Abort"
                    onClicked: {
                      if (xhr) xhr.abort()
                    }
                  }
                }
              }
            }

            GridLayout {
              width: parent.width
              columns: root.narrow ? 1 : 2
              columnSpacing: 12
              rowSpacing: 12

              Card {
                Layout.fillWidth: true
                implicitHeight: bodyCol.implicitHeight + root.cardPad * 2

                Column {
                  id: bodyCol
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.margins: root.cardPad
                  spacing: 10

                  H2 { text: "Body (Text / JSON)" }

                  BodyText { text: "For POST/PUT/PATCH: paste JSON or text here. This tester sends it as a *raw string*." }

                  FieldArea {
                    id: bodyArea
                    Layout.fillWidth: true
                    height: root.narrow ? 160 : 200
                    text: "{\n  \"hello\": \"qfield\",\n  \"when\": \"" + (new Date()).toISOString() + "\"\n}"
                  }

                  BodyText {
                    text: "If you want C++ to parse JSON, set header Content-Type: application/json and parse responseType/responseText as needed."
                  }
                }
              }

              // Multipart
              Card {
                Layout.fillWidth: true
                implicitHeight: mpCol.implicitHeight + root.cardPad * 2

                Column {
                  id: mpCol
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.margins: root.cardPad
                  spacing: 10

                  H2 { text: "Multipart upload" }

                  BodyText {
                    text: "Important: core XmlHttpRequest may block arbitrary local uploads. To test: copy the file INTO the current QField project folder (or cloud project folder), then pick it."
                  }

                  Row {
                    width: parent.width
                    spacing: 10

                    FieldText {
                      id: fileField
                      width: Math.max(120, parent.width - pickBtn.implicitWidth - 10)
                      placeholderText: "Picked file URL (file:///...)"
                      readOnly: true
                    }

                    PillButton {
                      id: pickBtn
                      text: "Pick…"
                      onClicked: fileDialog.open()
                    }
                  }

                  Row {
                    width: parent.width
                    spacing: 10

                    Column {
                      width: parent.width * 0.55
                      spacing: 6
                      BodyText { text: "file field name" }
                      FieldText { id: uploadNameField; width: parent.width; text: "file" }
                    }

                    Column {
                      width: parent.width * 0.45 - 10
                      spacing: 6
                      BodyText { text: "note" }
                      FieldText { id: uploadNoteField; width: parent.width; text: "Hello from QField plugin" }
                    }
                  }

                  Flow {
                    width: parent.width
                    spacing: 10

                    PillButton {
                      text: "Upload to httpbin.org/post"
                      onClicked: {
                        ensureXhr()
                        urlField.text = "https://httpbin.org/post"
                        methodBox.currentIndex = 1 // POST
                        sendMultipart()
                      }
                    }

                    PillButton {
                      text: "Quick: set Content-Type multipart"
                      onClicked: {
                        // add a Content-Type header line if missing
                        const lower = headersArea.text.toLowerCase()
                        if (lower.indexOf("content-type:") === -1) {
                          headersArea.text = (headersArea.text.trim().length ? headersArea.text.trim() + "\n" : "") + "Content-Type: multipart/form-data"
                        }
                      }
                    }
                  }
                }
              }
            }

            // Response
            Card {
              width: parent.width
              implicitHeight: respCol.implicitHeight + root.cardPad * 2

              Column {
                id: respCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.cardPad
                spacing: 10

                H2 { text: "Response" }

                Row {
                  width: parent.width
                  spacing: 10
                  Text {
                    width: parent.width * 0.6
                    color: root.fg
                    elide: Text.ElideRight
                    text: xhr ? ("status: " + xhr.status + " " + xhr.statusText) : "status: (no xhr)"
                  }
                  Text {
                    width: parent.width * 0.4 - 10
                    color: root.muted
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: xhr ? ("type: " + xhr.responseType) : ""
                  }
                }

                Text {
                  width: parent.width
                  color: root.muted
                  elide: Text.ElideRight
                  text: xhr ? ("url: " + xhr.responseUrl) : ""
                }

                FieldArea {
                  width: parent.width
                  height: root.narrow ? 170 : 220
                  readOnly: true
                  text: xhr ? xhr.responseText : ""
                }
              }
            }

            // Log
            Card {
              width: parent.width
              implicitHeight: logCol.implicitHeight + root.cardPad * 2

              Column {
                id: logCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.cardPad
                spacing: 10

                Row {
                  width: parent.width
                  spacing: 10
                  H2 { text: "Event log" }
                  Item { width: 1; height: 1 } // spacer
                }

                Row {
                  width: parent.width
                  spacing: 10
                  PillButton {
                    text: "Clear"
                    onClicked: logModel.clear()
                  }
                  PillButton {
                    text: "Self-test (GET/redirect/timeout)"
                    onClicked: runSelfTest()
                  }
                  Text {
                    width: parent.width - 320
                    color: root.muted
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    text: xhr ? ("readyState: " + root.readyStateName(xhr.readyState)) : ""
                  }
                }

                Rectangle {
                  width: parent.width
                  height: root.narrow ? 220 : 260
                  radius: 10
                  color: "#141414"
                  border.color: root.border
                  border.width: 1
                  clip: true

                  ListView {
                    anchors.fill: parent
                    anchors.margins: 8
                    model: logModel
                    clip: true
                    delegate: Text {
                      width: ListView.view.width
                      color: root.fg
                      font.pixelSize: 12
                      wrapMode: Text.Wrap
                      text: "[" + t + "] " + m
                    }
                  }
                }
              }
            }

            Item { width: 1; height: 12 } // bottom breathing room
          }
        }
      }
    }
    onOpened: root.log("Panel opened (" + width + "x" + height + "), narrow=" + root.narrow)
    onClosed: root.log("Panel closed")

    FileDialog {
      id: fileDialog
      title: "Pick a file to upload"
      onAccepted: {
        fileField.text = selectedFile.toString()
        root.log("Picked file: " + fileField.text)
      }
    }

    // request helpers
    function applyHeaders() {
      const lines = headersArea.text.split("\n")
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim()
        if (!line) continue
        const idx = line.indexOf(":")
        if (idx <= 0) {
          root.log("Header parse skipped: " + line)
          continue
        }
        const k = line.slice(0, idx).trim()
        const v = line.slice(idx + 1).trim()
        xhr.setRequestHeader(k, v)
      }
    }

    function sendTextOrJson() {
      if (!xhr) return

      const method = methodBox.currentText
      const url = urlField.text.trim()
      const ms = parseInt(timeoutField.text || "0")

      root.log("open(" + method + ", " + url + "), timeout=" + ms + "ms")
      xhr.open(method, url)
      xhr.timeout = isNaN(ms) ? 0 : ms

      applyHeaders()

      const hasCT = headersArea.text.toLowerCase().indexOf("content-type:") !== -1
      const body = bodyArea.text

      if (!hasCT && body && body.trim().length > 0 && method !== "GET" && method !== "HEAD") {
        xhr.setRequestHeader("Content-Type", "application/json")
      }

      xhr.send(body)
    }

    function sendMultipart() {
      if (!xhr) return

      const fileUrl = fileField.text.trim()
      if (!fileUrl) {
        root.log("No file selected; pick a local file first.")
        iface.mainWindow().displayToast("Pick a local file first (file:///...)")
        return
      }

      const method = methodBox.currentText
      const url = urlField.text.trim()
      const ms = parseInt(timeoutField.text || "0")

      root.log("open(" + method + ", " + url + ") multipart, timeout=" + ms + "ms")
      xhr.open(method, url)
      xhr.timeout = isNaN(ms) ? 0 : ms

      applyHeaders()

      xhr.setRequestHeader("Content-Type", "multipart/form-data")

      const body = {}
      body[uploadNameField.text.trim() || "file"] = fileUrl
      body["note"] = uploadNoteField.text
      body["ts"] = (new Date()).toISOString()

      xhr.send(body)
    }

    // self-test
    property int selfTestStep: 0

    Timer {
      id: selfTestTimer
      interval: 250
      repeat: false
      onTriggered: root.nextSelfTestStep()
    }

    function runSelfTest() {
      ensureXhr()
      selfTestStep = 0
      logModel.clear()
      log("=== self-test start ===")
      nextSelfTestStep()
    }

    function nextSelfTestStep() {
      if (!xhr) return
      selfTestStep += 1

      if (selfTestStep === 1) {
        urlField.text = "https://httpbin.org/get"
        methodBox.currentIndex = 0
        timeoutField.text = "0"
        headersArea.text = ""
        bodyArea.text = ""
        sendTextOrJson()
        selfTestTimer.start()
        return
      }

      if (selfTestStep === 2) {
        urlField.text = "https://httpbin.org/redirect/1"
        methodBox.currentIndex = 0
        timeoutField.text = "0"
        headersArea.text = ""
        bodyArea.text = ""
        sendTextOrJson()
        selfTestTimer.start()
        return
      }

      if (selfTestStep === 3) {
        urlField.text = "https://httpbin.org/delay/5"
        methodBox.currentIndex = 0
        timeoutField.text = "1000"
        headersArea.text = ""
        bodyArea.text = ""
        sendTextOrJson()
        selfTestTimer.start()
        return
      }

      log("=== self-test queued (watch callbacks) ===")
    }

    // also listen to C++ signals
    Connections {
      target: xhr
      function onReadyStateChanged() {
        root.log("signal readyStateChanged: " + (xhr ? root.readyStateName(xhr.readyState) : "?"))
      }
      function onResponseChanged() {
        if (!xhr) return
        root.log("signal responseChanged: status=" + xhr.status + " bytes=" + (xhr.responseText ? xhr.responseText.length : 0))
      }
    }

    Component.onCompleted: {
      iface.mainWindow().displayToast("XHR Tester plugin loaded")
      iface.addItemToPluginsToolbar(toolbarButton)
      ensureXhr()
      root.log("Plugin loaded; toolbar button added")
    }
  }
}
