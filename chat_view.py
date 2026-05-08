from fastapi import APIRouter
from fastapi.responses import HTMLResponse
from constants import CHAT_ROUTE, DOCUMENT_VIEW_ROUTE, CHAT_VIEW_ROUTE, VOICE_VIEW_ROUTE

router = APIRouter()


@router.get(CHAT_VIEW_ROUTE, response_class=HTMLResponse)
async def chat_page():
    html = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>RAG Car Chat</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #f5f7fb; color: #172033; }
    main { max-width: 900px; margin: 32px auto; padding: 0 20px; }
    header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
    a { color: #0f62fe; text-decoration: none; }
    .panel { background: white; border: 1px solid #d8dee9; border-radius: 8px; padding: 18px; }
    textarea, input { width: 100%; box-sizing: border-box; border: 1px solid #c8d0dd; border-radius: 6px; padding: 10px; font: inherit; }
    textarea { min-height: 110px; resize: vertical; }
    button { margin-top: 12px; border: 0; border-radius: 6px; padding: 10px 14px; background: #1f6feb; color: white; cursor: pointer; }
    pre { white-space: pre-wrap; background: #101828; color: #e6edf3; border-radius: 8px; padding: 14px; min-height: 120px; }
    label { display: block; margin: 12px 0 6px; font-weight: 600; }
    .row { display: flex; gap: 10px; align-items: center; }
    .row button { flex: 0 0 auto; }
    .status { color: #526070; font-size: 14px; margin-top: 10px; min-height: 20px; }
  </style>
</head>
<body>
  <main>
    <header>
      <h1>Chat</h1>
      <nav>
        <a href="VOICE_VIEW_PATH">Voice chat</a>
        <a href="DOCUMENT_VIEW_PATH">Upload documents</a>
      </nav>
    </header>
    <section class="panel">
      <label for="session">Session ID</label>
      <input id="session" value="web-user">
      <label for="question">Question</label>
      <textarea id="question" placeholder="Ask about your uploaded car documents or car selling..."></textarea>
      <div class="row">
        <button onclick="sendQuestion()">Ask with API</button>
        <button onclick="sendSocketQuestion()">Ask with Socket Stream</button>
      </div>
      <div class="status" id="status"></div>
      <h2>Answer</h2>
      <pre id="answer"></pre>
    </section>
  </main>
  <script src="https://cdn.socket.io/4.7.5/socket.io.min.js"></script>
  <script>
    const socket = io();
    const answer = document.getElementById("answer");
    const status = document.getElementById("status");

    socket.on("connect", () => {
      status.textContent = "Socket connected";
      socket.emit("join_session", {
        session_id: document.getElementById("session").value
      });
    });

    socket.on("message_ack", () => {
      status.textContent = "Message received";
    });

    socket.on("assistant_typing", () => {
      status.textContent = "Assistant is responding...";
    });

    socket.on("assistant_chunk", (data) => {
      answer.textContent += data.chunk;
    });

    socket.on("assistant_done", () => {
      status.textContent = "Done";
    });

    socket.on("assistant_error", (data) => {
      status.textContent = data.error || "Socket error";
    });

    async function sendQuestion() {
      answer.textContent = "Loading...";
      status.textContent = "";
      const response = await fetch("CHAT_API_PATH", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          question: document.getElementById("question").value,
          session_id: document.getElementById("session").value
        })
      });
      const data = await response.json();
      if (!response.ok) {
        status.textContent = "API request failed";
        answer.textContent = JSON.stringify(data, null, 2);
        return;
      }

      answer.textContent = JSON.stringify(data, null, 2);
    }

    function sendSocketQuestion() {
      const question = document.getElementById("question").value.trim();
      if (!question) {
        status.textContent = "Question is required";
        return;
      }

      answer.textContent = "";
      status.textContent = "Sending...";
      socket.emit("send_message", {
        question,
        session_id: document.getElementById("session").value
      });
    }
  </script>
</body>
</html>
"""
    return (
        html.replace("VOICE_VIEW_PATH", VOICE_VIEW_ROUTE)
        .replace(
            "DOCUMENT_VIEW_PATH",
            DOCUMENT_VIEW_ROUTE,
        )
        .replace(
            "CHAT_API_PATH",
            CHAT_ROUTE,
        )
    )
