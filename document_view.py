from fastapi import APIRouter
from fastapi.responses import HTMLResponse
from constants import (
    AUTH_VIEW_ROUTE,
    CHAT_VIEW_ROUTE,
    DOCUMENT_LIST_ROUTE,
    DOCUMENT_UPLOAD_ROUTE,
    DOCUMENT_VIEW_ROUTE,
    VOICE_VIEW_ROUTE,
)

router = APIRouter()


@router.get(DOCUMENT_VIEW_ROUTE, response_class=HTMLResponse)
async def document_page():
    html = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Upload Documents</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #f5f7fb; color: #172033; }
    main { max-width: 900px; margin: 32px auto; padding: 0 20px; }
    header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
    nav { display: flex; gap: 14px; flex-wrap: wrap; }
    a { color: #0f62fe; text-decoration: none; }
    .panel { background: white; border: 1px solid #d8dee9; border-radius: 8px; padding: 18px; }
    input { display: block; margin: 14px 0; }
    button { border: 0; border-radius: 6px; padding: 10px 14px; background: #1f6feb; color: white; cursor: pointer; }
    pre { white-space: pre-wrap; background: #101828; color: #e6edf3; border-radius: 8px; padding: 14px; min-height: 120px; }
  </style>
</head>
<body>
  <main>
    <header>
      <h1>Documents</h1>
      <nav>
        <a href="AUTH_VIEW_PATH">Login</a>
        <a href="SIGNUP_VIEW_PATH">Signup</a>
        <a href="CHAT_VIEW_PATH">Chat</a>
        <a href="VOICE_VIEW_PATH">Voice chat</a>
      </nav>
    </header>
    <section class="panel">
      <input id="files" type="file" multiple accept=".txt,.md,.pdf">
      <button onclick="uploadDocuments()">Upload</button>
      <button onclick="loadDocuments()">Refresh List</button>
      <h2>Result</h2>
      <pre id="result"></pre>
    </section>
  </main>
  <script>
    function getAccessToken() {
      return localStorage.getItem("access_token") || "";
    }

    if (!getAccessToken()) {
      window.location.href = "/login";
    }

    async function uploadDocuments() {
      const result = document.getElementById("result");
      const selectedFiles = document.getElementById("files").files;
      if (!selectedFiles.length) {
        result.textContent = "Please select at least one document.";
        return;
      }

      const formData = new FormData();
      for (const file of selectedFiles) {
        formData.append("files", file);
      }
      result.textContent = "Uploading...";
      const response = await fetch("DOCUMENT_UPLOAD_PATH", {
        method: "POST",
        headers: {
          Authorization: "Bearer " + getAccessToken()
        },
        body: formData
      });
      const data = await response.json();
      if (!response.ok) {
        result.textContent = JSON.stringify(data, null, 2);
        return;
      }

      result.textContent = JSON.stringify(data, null, 2);
    }

    async function loadDocuments() {
      const response = await fetch("DOCUMENT_LIST_PATH", {
        headers: {
          Authorization: "Bearer " + getAccessToken()
        }
      });
      const data = await response.json();
      document.getElementById("result").textContent = JSON.stringify(data, null, 2);
    }
  </script>
</body>
</html>
"""
    return html.replace("AUTH_VIEW_PATH", AUTH_VIEW_ROUTE).replace(
        "SIGNUP_VIEW_PATH",
        "/signup",
    ).replace(
        "CHAT_VIEW_PATH", CHAT_VIEW_ROUTE
    ).replace(
        "VOICE_VIEW_PATH", VOICE_VIEW_ROUTE
    ).replace(
        "DOCUMENT_UPLOAD_PATH", DOCUMENT_UPLOAD_ROUTE
    ).replace(
        "DOCUMENT_LIST_PATH", DOCUMENT_LIST_ROUTE
    )
