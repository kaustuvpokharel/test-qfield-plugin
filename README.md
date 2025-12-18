## How to run and check -> Simplified walkthrough

1. Open panel -> click **Reset XHR**

* Expect log: `XmlHttpRequest created` then `Reset complete`
* This confirms: QML object creation and callback wiring is alive.

---

## Basic GET workflow (open -> headers -> loading -> done)

**Set**

* Method: `GET`
* URL: `https://httpbin.org/get`
* Timeout: `0`
* Headers: empty

**Click**: `GET /get`

**Expect**

* Logs show readyState moving: `Opened -> HeadersReceived -> Loading -> Done`
* Status becomes `200`
* `responseUrl` is `https://httpbin.org/get`
* `responseText` shows JSON

**This validates in C++**

* `open()`
* `startRequest()` GET branch (`NetworkManager::get`)
* `hookReply()` + `hookRawReply()` readyState transitions 
* `finalizeFromRawReply()` status/headers/body reading

---

## Request headers actually applied

**Set**

* Same as 1
* Headers:

  ```
  X-Test: hello
  ```

**Click**: `GET /get`

**Expect**

* `responseText` JSON contains header `X-Test` (httpbin echoes received headers)

**Validates**

* `setRequestHeader()`  (and “headers only before send” behavior)

---

## Redirect signal and final responseUrl

**Set**

* Method: GET
* URL: `https://httpbin.org/redirect/1`
* Timeout: 0

**Click**: `Redirect`

**Expect**

* Log line: `onredirected: ...`
* Final `status: 200`
* Final `responseUrl` is **not** `/redirect/1` (it should be the resolved target, usually `/get`)

**Validates**

* `hookReply(): redirected` connection
* Reply swap handling (`currentRawReplyChanged`)
* `finalizeFromRawReply()` uses final raw reply

---

## Timeout path

**Set**

* Method: GET
* URL: `https://httpbin.org/delay/5`
* Timeout: `1000`

**Click**: `Timeout`

**Expect**

* Log: `ontimeout`
* `responseText` becomes: `{"detail":"Operation timed out"}`
* readyState ends at `Done`
* status will likely stay `0` (because you finalize as error)

**Validates**

* `setTimeout()` / `mTimeoutMs` behavior
* `QTimer::singleShot` timeout abort path
* `finalizeAsError("Operation timed out")`

---

## Abort path

**Set**

* Method: GET
* URL: `https://httpbin.org/delay/5`
* Timeout: `0`

**Click**

1. `Send (text/json)`
2. quickly press `Abort`

**Expect**

* Log: `onaborted`
* `responseText`: `{"detail":"Operation aborted"}`
* readyState `Done`

**Validates**

* `abort()`
* `finalizeAsError("Operation aborted")`

---

## POST JSON/text (bodyToBytes(QString) path)

**Set**

* Method: `POST`
* URL: `https://httpbin.org/post`
* Body: keep your JSON string
* Headers empty (your QML auto-adds `Content-Type: application/json`)

**Click**: `Send (text/json)`

**Expect**

* Status `200`
* `responseType` contains `application/json`
* Response JSON includes your payload (httpbin usually shows it in `data` and/or `json`)

**Validates**

* POST non-multipart path
* `bodyToBytes(QString)`
* `finalizeFromRawReply()` JSON detection/parsing decision

---

## DELETE workflow

**Set**

* Method: `DELETE`
* URL: `https://httpbin.org/delete`
* Timeout: 0

**Click**: `Send (text/json)`

**Expect**

* Status `200`
* JSON response

**Validates**

* `startRequest()` DELETE branch (`NetworkManager::deleteResource`)

---

## Network error -> onerror callback

**Set**

* Method: GET
* URL: `https://example.invalid` (or some guaranteed-bad host)
* Timeout: 0

**Click**: `Send (text/json)`

**Expect**

* Log: `onerror: code=... message=...`
* Eventually `Done`

**Validates**

* `hookReply(): errorOccurred → call(mOnError, ...)`

---

## Multipart upload (allowed-path success case)

**Do this**

1. In plugin → `Pick…` and select that file.
2. Click `Upload to httpbin.org/post`

**Expect**

* Log: `onuploadprogress ...` (often)
* Status `200`
* In response JSON, the file shows under `"files"` (not only `"form"`)

**Validates**

* `bodyContainsFileUrls()`
* `buildMultipart()` 
* `isAllowedLocalUploadPath()` 
* `appendFilePart()`

### How to detect “upload blocked”

If the path is blocked, the `buildMultipart()` will **fallback** and send the `file:///...` value as a **text form field**, so httpbin response will show it under `"form"` instead of `"files"`.

---

## Force-multipart + invalid body (negative test)

Error handling for `forceMultipart` and non-map body.

**Set**

* Add header: `Content-Type: multipart/form-data`
* Method: POST
* URL: `https://httpbin.org/post`
* Body: keep it as text (string)

**Click**: `Send (text/json)`

**Expect**

* `responseText`: `{"detail":"Invalid multipart body"}`

**Validates**

* `forceMultipart` detection
* `buildMultipart()` returning null -> error path
