import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import org.qfield

Item {
  id: root

  // --- simple log model for "track errors / mismatches"
  ListModel { id: logModel }

  function ts() {
    // ISO-ish time, local
    const d = new Date()
    function pad(n){ return (n<10 ? "0" : "") + n }
    return pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
  }

  function log(msg) {
    logModel.append({ t: ts(), m: String(msg) })
    // also log to console to catch plugin/runtime issues
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

  // --- Create the XHR object dynamically so we can "Reset" it completely
  property var xhr: null

  Component {
    id: xhrComponent

    XmlHttpRequest {
      // NOTE: these are *properties* backed by QJSValue in C++
      onreadystatechange: function() {
        root.log("onreadystatechange: readyState=" + root.readyStateName(readyState) + " (" + readyState + "), status=" + status)
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
  }

  // --- UI: attach to toolbar, open a popup panel
  Rectangle {
    id: toolbarButton
    width: 40
    height: 40
    radius: 6
    color: "#2b2b2b"
    border.color: "#d0d0d0"
    border.width: 1

    Text {
      anchors.centerIn: parent
      text: "XHR"
      color: "white"
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
    modal: false
    focus: true

    // keep it usable on both phone + desktop
    width: Math.min(parent.width * 0.95, 740)
    height: Math.min(parent.height * 0.95, 820)
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
      color: "#151515"
      radius: 10
      border.color: "#404040"
      border.width: 1
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 10

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Label {
          Layout.fillWidth: true
          text: "QField XmlHttpRequest — Test Panel"
          color: "white"
          font.pixelSize: 18
          font.bold: true
          elide: Label.ElideRight
        }

        Button {
          text: "Reset XHR"
          onClicked: resetXhr()
        }
        Button {
          text: "Close"
          onClicked: panel.close()
        }
      }

      // Request settings
      GroupBox {
        Layout.fillWidth: true
        title: "Request"
        label: Label { text: parent.title; color: "white"; font.bold: true }

        ColumnLayout {
          anchors.fill: parent
          spacing: 8

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ComboBox {
              id: methodBox
              model: ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]
              Layout.preferredWidth: 140
            }

            TextField {
              id: urlField
              Layout.fillWidth: true
              placeholderText: "URL (e.g. https://httpbin.org/anything)"
              text: "https://httpbin.org/anything"
            }

            TextField {
              id: timeoutField
              Layout.preferredWidth: 140
              inputMethodHints: Qt.ImhDigitsOnly
              placeholderText: "timeout ms"
              text: "0"
              ToolTip.visible: hovered
              ToolTip.text: "Set XmlHttpRequest.timeout (0 disables)."
            }
          }

          TextArea {
            id: headersArea
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            wrapMode: TextArea.Wrap
            placeholderText: "Headers (one per line):\nAuthorization: Bearer ...\nContent-Type: application/json"
            text: ""
          }
        }
      }

      // Body + Upload
      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        GroupBox {
          Layout.fillWidth: true
          Layout.preferredWidth: 420
          title: "Body (JSON/Text)"
          label: Label { text: parent.title; color: "white"; font.bold: true }

          ColumnLayout {
            anchors.fill: parent
            spacing: 8

            TextArea {
              id: bodyArea
              Layout.fillWidth: true
              Layout.preferredHeight: 150
              wrapMode: TextArea.Wrap
              placeholderText: "Body as raw text.\nTip: for JSON, paste JSON text."
              text: "{\n  \"hello\": \"qfield\",\n  \"when\": \"" + (new Date()).toISOString() + "\"\n}"
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Button {
                text: "Send (text/json)"
                onClicked: {
                  ensureXhr()
                  root.sendTextOrJson()
                }
              }

              Button {
                text: "Test redirect"
                onClicked: {
                  ensureXhr()
                  urlField.text = "https://httpbin.org/redirect/1"
                  methodBox.currentIndex = 0 // GET
                  bodyArea.text = ""
                  root.sendTextOrJson()
                }
              }

              Button {
                text: "Test timeout"
                onClicked: {
                  ensureXhr()
                  urlField.text = "https://httpbin.org/delay/5"
                  methodBox.currentIndex = 0 // GET
                  timeoutField.text = "1000"
                  bodyArea.text = ""
                  root.sendTextOrJson()
                }
              }
            }
          }
        }

        GroupBox {
          Layout.fillWidth: true
          title: "Multipart upload"
          label: Label { text: parent.title; color: "white"; font.bold: true }

          ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              TextField {
                id: fileField
                Layout.fillWidth: true
                placeholderText: "File URL (file:///...)"
                text: ""
              }

              Button {
                text: "Pick…"
                onClicked: fileDialog.open()
              }
            }

            TextField {
              id: uploadNameField
              Layout.fillWidth: true
              placeholderText: "form field name for file (default: file)"
              text: "file"
            }

            TextField {
              id: uploadNoteField
              Layout.fillWidth: true
              placeholderText: "extra field (note)"
              text: "Hello from QField plugin"
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Button {
                text: "Upload to httpbin.org/post"
                onClicked: {
                  ensureXhr()
                  urlField.text = "https://httpbin.org/post"
                  methodBox.currentIndex = 1 // POST
                  root.sendMultipart()
                }
              }

              Button {
                text: "Abort"
                onClicked: {
                  if (xhr) xhr.abort()
                }
              }
            }

            Label {
              Layout.fillWidth: true
              wrapMode: Label.Wrap
              color: "#b0b0b0"
              text: "Note: multipart upload expects your C++ XmlHttpRequest to treat local file URLs (file:///...) as file parts."
            }
          }
        }
      }

      // Response
      GroupBox {
        Layout.fillWidth: true
        title: "Response"
        label: Label { text: parent.title; color: "white"; font.bold: true }

        ColumnLayout {
          anchors.fill: parent
          spacing: 6

          RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
              Layout.fillWidth: true
              color: "white"
              text: xhr ? ("status: " + xhr.status + " " + xhr.statusText) : "status: (no xhr)"
              elide: Label.ElideRight
            }

            Label {
              Layout.fillWidth: true
              color: "#c0c0c0"
              text: xhr ? ("type: " + xhr.responseType) : ""
              elide: Label.ElideRight
              horizontalAlignment: Text.AlignRight
            }
          }

          Label {
            Layout.fillWidth: true
            color: "#c0c0c0"
            text: xhr ? ("url: " + xhr.responseUrl) : ""
            elide: Label.ElideRight
          }

          ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 160

            TextArea {
              readOnly: true
              wrapMode: TextArea.Wrap
              text: xhr ? xhr.responseText : ""
            }
          }
        }
      }

      // Log
      GroupBox {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "Event log"
        label: Label { text: parent.title; color: "white"; font.bold: true }

        ColumnLayout {
          anchors.fill: parent
          spacing: 8

          RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Button {
              text: "Clear log"
              onClicked: logModel.clear()
            }
            Button {
              text: "Run mini self-test"
              onClicked: root.runSelfTest()
            }
            Item { Layout.fillWidth: true }
            Label {
              color: "#b0b0b0"
              text: xhr ? ("readyState: " + root.readyStateName(xhr.readyState)) : ""
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 6
            color: "#0f0f0f"
            border.color: "#303030"
            border.width: 1

            ListView {
              anchors.fill: parent
              anchors.margins: 6
              model: logModel
              clip: true
              delegate: Text {
                width: ListView.view.width
                color: "white"
                font.pixelSize: 12
                text: "[" + t + "] " + m
                wrapMode: Text.Wrap
              }
            }
          }
        }
      }
    }

    onOpened: root.log("Panel opened")
    onClosed: root.log("Panel closed")
  }

  FileDialog {
    id: fileDialog
    title: "Pick a file to upload"
    onAccepted: {
      // QtQuick.Dialogs FileDialog (Qt6) gives selectedFile as url
      fileField.text = selectedFile.toString()
      root.log("Picked file: " + fileField.text)
    }
  }

  // --- Helpers to send requests
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

    // If user did not specify Content-Type, default to application/json for non-empty bodies
    const hasCT = headersArea.text.toLowerCase().indexOf("content-type:") !== -1
    const body = bodyArea.text

    if (!hasCT && body && body.trim().length > 0 && method !== "GET" && method !== "HEAD") {
      xhr.setRequestHeader("Content-Type", "application/json")
    }

    // NOTE: send as raw string; this avoids QVariantMap conversion ambiguities in C++.
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

    // Force multipart (your C++ checks for multipart/form-data)
    xhr.setRequestHeader("Content-Type", "multipart/form-data")

    // Body is a JS object -> QVariantMap in C++
    const body = {}
    body[uploadNameField.text.trim() || "file"] = fileUrl
    body["note"] = uploadNoteField.text
    body["ts"] = (new Date()).toISOString()

    xhr.send(body)
  }

  // Small guided self-test that hits 3 endpoints
  property int selfTestStep: 0
  Timer {
    id: selfTestTimer
    interval: 200
    repeat: false
    onTriggered: root.nextSelfTestStep()
  }

  function runSelfTest() {
    ensureXhr()
    selfTestStep = 0
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
      // redirect test
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
      // timeout test (delay 5s, timeout 1s)
      urlField.text = "https://httpbin.org/delay/5"
      methodBox.currentIndex = 0
      timeoutField.text = "1000"
      headersArea.text = ""
      bodyArea.text = ""
      sendTextOrJson()
      selfTestTimer.start()
      return
    }

    log("=== self-test queued requests done (watch log for callbacks) ===")
  }

  // Bind to C++ signals too (this catches cases where QJSValue properties don't fire)
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
    // plugin entrypoint
    iface.mainWindow().displayToast("XHR Tester plugin loaded")
    // add toolbar entry
    iface.addItemToPluginsToolbar(toolbarButton)
    ensureXhr()
    log("Plugin loaded; toolbar button added")
  }
}
