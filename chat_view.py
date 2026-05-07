from fastapi import APIRouter
from fastapi.responses import HTMLResponse
from constants import CHAT_ROUTE, DOCUMENT_VIEW_ROUTE, CHAT_VIEW_ROUTE

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
  </style>
</head>
<body>
  <main>
    <header>
      <h1>Chat</h1>
      <a href="DOCUMENT_VIEW_PATH">Upload documents</a>
    </header>
    <section class="panel">
      <label for="session">Session ID</label>
      <input id="session" value="web-user">
      <label for="question">Question</label>
      <textarea id="question" placeholder="Ask about your uploaded car documents or car selling..."></textarea>
      <button onclick="sendQuestion()">Ask</button>
      <h2>Answer</h2>
      <pre id="answer"></pre>
    </section>
  </main>
  <script>
    async function sendQuestion() {
      const answer = document.getElementById("answer");
      answer.textContent = "Loading...";
      const response = await fetch("CHAT_API_PATH", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          question: document.getElementById("question").value,
          session_id: document.getElementById("session").value
        })
      });
      const data = await response.json();
      answer.textContent = JSON.stringify(data, null, 2);
    }
  </script>
</body>
</html>
"""
    return html.replace("DOCUMENT_VIEW_PATH", DOCUMENT_VIEW_ROUTE).replace(
        "CHAT_API_PATH",
        CHAT_ROUTE,
    )
