from fastapi import APIRouter
from fastapi.responses import HTMLResponse
from constants import (
    AUTH_VIEW_ROUTE,
    CHAT_VIEW_ROUTE,
    DOCUMENT_VIEW_ROUTE,
    VOICE_VIEW_ROUTE,
)

router = APIRouter()


@router.get(VOICE_VIEW_ROUTE, response_class=HTMLResponse)
async def voice_page():
    html = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Voice Chat</title>
  <style>
    :root {
      --bg: #eef2f7;
      --panel: #fff;
      --panel-2: #f7f9fc;
      --text: #0f172a;
      --muted: #526070;
      --border: #d7deea;
      --accent: #1f6feb;
      --danger: #a61b1b;
      --shadow: 0 10px 30px rgba(15, 23, 42, 0.08);
    }
    * { box-sizing: border-box; }
    body { margin: 0; font-family: Arial, sans-serif; background: var(--bg); color: var(--text); }
    main { max-width: 860px; margin: 28px auto; padding: 0 18px 28px; }
    header { display: flex; justify-content: space-between; gap: 16px; align-items: flex-start; margin-bottom: 18px; }
    h1 { margin: 0; font-size: 30px; line-height: 1.1; }
    .subtle { margin-top: 8px; color: var(--muted); font-size: 14px; line-height: 1.4; }
    nav { display: flex; gap: 14px; flex-wrap: wrap; padding-top: 8px; }
    a { color: var(--accent); text-decoration: none; }
    .card { background: var(--panel); border: 1px solid var(--border); border-radius: 10px; box-shadow: var(--shadow); padding: 16px; }
    label { display: block; margin: 0 0 6px; font-weight: 700; font-size: 14px; }
    input {
      width: 100%;
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 12px 14px;
      font: inherit;
      color: var(--text);
      background: #fff;
      margin-bottom: 12px;
    }
    .controls { display: flex; gap: 10px; flex-wrap: wrap; }
    button {
      border: 0;
      border-radius: 8px;
      padding: 11px 16px;
      background: var(--accent);
      color: white;
      cursor: pointer;
      font: inherit;
      font-weight: 700;
    }
    button.secondary { background: #5b6677; }
    button:disabled { background: #aeb8c8; cursor: not-allowed; }
    .statusbar { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 12px; }
    .chip {
      display: inline-flex;
      gap: 8px;
      align-items: center;
      padding: 8px 10px;
      border-radius: 999px;
      font-size: 13px;
      border: 1px solid var(--border);
      background: var(--panel-2);
      color: var(--muted);
    }
    .chip strong { color: var(--text); }
    .meter { height: 11px; background: #dfe6f1; border-radius: 999px; overflow: hidden; margin-top: 14px; }
    .meter-fill { height: 100%; width: 0%; background: linear-gradient(90deg, var(--accent), #4c8bf5); transition: width 70ms linear; }
    .hint { margin-top: 10px; color: var(--muted); font-size: 13px; line-height: 1.45; }
    .feed {
      margin-top: 18px;
      min-height: 220px;
      max-height: 55vh;
      overflow: auto;
      padding: 16px;
      border: 1px solid var(--border);
      border-radius: 10px;
      background: #fbfcfe;
    }
    .message { margin-bottom: 12px; }
    .role { font-size: 12px; font-weight: 700; color: var(--muted); text-transform: uppercase; margin-bottom: 4px; }
    .bubble {
      display: inline-block;
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 12px 14px;
      background: #fff;
      white-space: pre-wrap;
      line-height: 1.5;
      word-break: break-word;
    }
    .user { text-align: right; }
    .user .bubble { background: #eaf2ff; border-color: #c7d9fb; }
    @media (max-width: 700px) {
      header { flex-direction: column; }
    }
  </style>
</head>
<body>
  <main>
    <header>
      <div>
        <h1>Voice Chat</h1>
        <div class="subtle">Tap start, speak your question, stop on silence, hear the answer.</div>
      </div>
      <nav>
        <a href="AUTH_VIEW_PATH">Login</a>
        <a href="SIGNUP_VIEW_PATH">Signup</a>
        <a href="CHAT_VIEW_PATH">Text chat</a>
        <a href="DOCUMENT_VIEW_PATH">Upload documents</a>
      </nav>
    </header>

    <section class="card">
      <label for="session">Session ID</label>
      <input id="session" value="voice-user">
      <div class="controls">
        <button id="startButton" onclick="startVoiceLoop()">Start voice chat</button>
        <button id="stopButton" class="secondary" onclick="stopVoiceLoop()" disabled>Stop</button>
      </div>
      <div class="statusbar">
        <div class="chip"><strong>Status</strong> <span id="status">Idle</span></div>
      </div>
      <div class="meter"><div class="meter-fill" id="meterFill"></div></div>
      <div class="hint">Mic open hota hai, silence par audio send hoti hai, aur response directly play hota hai.</div>
      <div class="feed" id="feed"></div>
    </section>
  </main>

  <script src="https://cdn.socket.io/4.7.5/socket.io.min.js"></script>
  <script>
    const socket = io();
    const startButton = document.getElementById("startButton");
    const stopButton = document.getElementById("stopButton");
    const statusEl = document.getElementById("status");
    const feedEl = document.getElementById("feed");
    const meterFill = document.getElementById("meterFill");

    let audioContext = null;
    let analyser = null;
    let micStream = null;
    let mediaRecorder = null;
    let recorderChunks = [];
    let vadFrame = null;
    let silenceTimer = null;
    let captureTimeout = null;
    let lastVoiceAt = 0;
    let recordingStartedAt = 0;
    let hasVoice = false;
    let voiceLoopActive = false;
    let recording = false;
    let uploading = false;
    let phase = "stopped";
    let awaitingGreeting = false;

    function getAccessToken() {
      return localStorage.getItem("access_token") || "";
    }

    if (!getAccessToken()) {
      window.location.href = "/login";
    }

    socket.on("connect", () => {
      setStatus("Socket connected");
    });

    socket.on("assistant_error", (data) => {
      phase = "idle";
      setStatus((data && data.error) || "Socket error", true);
    });

    socket.on("audio_response", async (data) => {
      const audioBase64 = typeof data === "string" ? data : (data && (data.data || data.audio_base64 || data.audio)) || "";
      await playAudioResponse(audioBase64);
    });

    async function startVoiceLoop() {
      try {
        micStream = await navigator.mediaDevices.getUserMedia({
          audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true }
        });

        setupVad(micStream);
        setupRecorder(micStream);

        voiceLoopActive = true;
        awaitingGreeting = true;
        startButton.disabled = true;
        stopButton.disabled = false;
        phase = "greeting";
        setStatus("Starting session");
        socket.emit("start_stream", { session_id: getSessionId(), access_token: getAccessToken() });
      } catch (error) {
        setStatus("Mic permission failed: " + error.message, true);
      }
    }

    function stopVoiceLoop() {
      voiceLoopActive = false;
      phase = "stopped";
      awaitingGreeting = false;
      recording = false;
      uploading = false;
      hasVoice = false;
      startButton.disabled = false;
      stopButton.disabled = true;
      setStatus("Stopped");
      if (silenceTimer) clearTimeout(silenceTimer);
      if (captureTimeout) clearTimeout(captureTimeout);
      lastVoiceAt = 0;
      if (mediaRecorder && mediaRecorder.state !== "inactive") mediaRecorder.stop();
      if (vadFrame) cancelAnimationFrame(vadFrame);
      if (micStream) micStream.getTracks().forEach((track) => track.stop());
      if (audioContext) audioContext.close();
      meterFill.style.width = "0%";
    }

    function setupRecorder(stream) {
      mediaRecorder = new MediaRecorder(stream, { mimeType: "audio/webm" });
      recorderChunks = [];
      mediaRecorder.ondataavailable = (event) => {
        if (event.data && event.data.size > 0) recorderChunks.push(event.data);
      };
      mediaRecorder.onstop = async () => {
        recording = false;
        if (captureTimeout) {
          clearTimeout(captureTimeout);
          captureTimeout = null;
        }
        const audioBlob = new Blob(recorderChunks, { type: "audio/webm" });
        recorderChunks = [];
        if (!voiceLoopActive || audioBlob.size === 0) {
          phase = "idle";
          return;
        }
        try {
          uploading = true;
          setStatus("Sending question");
          const audioBase64 = await blobToDataUrl(audioBlob);
          socket.emit("voice_audio", {
            session_id: getSessionId(),
            access_token: getAccessToken(),
            audio_base64: audioBase64,
            mime_type: audioBlob.type || "audio/webm",
            audio_filename: "voice.webm"
          });
        } catch (error) {
          setStatus("Audio send failed: " + error.message, true);
        } finally {
          uploading = false;
        }
      };
    }

    function setupVad(stream) {
      audioContext = new AudioContext();
      analyser = audioContext.createAnalyser();
      analyser.fftSize = 1024;
      audioContext.createMediaStreamSource(stream).connect(analyser);
      const samples = new Uint8Array(analyser.fftSize);

      const render = () => {
        if (!analyser) return;
        analyser.getByteTimeDomainData(samples);
        let sum = 0;
        for (const sample of samples) {
          const value = (sample - 128) / 128;
          sum += value * value;
        }
        const rms = Math.sqrt(sum / samples.length);
        const level = Math.min(100, Math.round(rms * 420));
        meterFill.style.width = level + "%";

        if (voiceLoopActive && phase === "idle" && !recording && !uploading && level > 2) {
          startCapture();
        }

        if (phase === "recording") {
          if (level > 2) {
            lastVoiceAt = Date.now();
            hasVoice = true;
            setStatus("Voice detected");
          } else if (
            recording &&
            lastVoiceAt &&
            (Date.now() - lastVoiceAt) > 180 &&
            (Date.now() - recordingStartedAt) > 500
          ) {
            lastVoiceAt = 0;
            if (voiceLoopActive && phase === "recording" && recording) {
              setStatus("Silence detected");
              stopCapture();
            }
          }
        }
        vadFrame = requestAnimationFrame(render);
      };
      render();
    }

    function startCapture() {
      if (!voiceLoopActive || recording || uploading || !mediaRecorder) return;
      phase = "recording";
      try {
        recorderChunks = [];
        mediaRecorder.start();
        recording = true;
        hasVoice = false;
        lastVoiceAt = Date.now();
        recordingStartedAt = Date.now();
        if (captureTimeout) clearTimeout(captureTimeout);
        captureTimeout = window.setTimeout(() => {
          if (
            voiceLoopActive &&
            recording &&
            mediaRecorder &&
            mediaRecorder.state === "recording"
          ) {
            stopCapture();
          }
        }, 2000);
        setStatus("Recording question");
      } catch (error) {
        setStatus("Recording start failed", true);
      }
    }

    function stopCapture() {
      if (!mediaRecorder || mediaRecorder.state === "inactive") return;
      try {
        mediaRecorder.stop();
      } catch (error) {
        setStatus("Recording stop failed", true);
      }
    }

    async function playAudioResponse(audioBase64) {
      const clean = (audioBase64 || "").trim();
      if (!clean) {
        phase = "idle";
        setStatus("Empty audio response", true);
        return;
      }
      try {
        const response = await fetch(`data:audio/wav;base64,${clean}`);
        const blob = await response.blob();
        const url = URL.createObjectURL(blob);
        const audio = new Audio(url);
        setStatus("Assistant speaking");
        audio.onended = () => {
          URL.revokeObjectURL(url);
          phase = "idle";
          if (awaitingGreeting && voiceLoopActive) {
            awaitingGreeting = false;
            setStatus("Ready to listen");
            startCapture();
            return;
          }
          setStatus("Ready to listen");
        };
        audio.onerror = () => {
          URL.revokeObjectURL(url);
          phase = "idle";
          setStatus("Audio playback failed", true);
        };
        await audio.play();
        addMessage(awaitingGreeting ? "Assistant is speaking..." : "Assistant is speaking...");
      } catch (error) {
        phase = "idle";
        setStatus("Audio playback failed", true);
      }
    }

    function addMessage(text, role = "assistant") {
      const message = document.createElement("div");
      message.className = "message " + role;
      const bubble = document.createElement("div");
      bubble.className = "bubble";
      bubble.textContent = text;
      message.appendChild(bubble);
      feedEl.appendChild(message);
      feedEl.scrollTop = feedEl.scrollHeight;
    }

    function setStatus(text, isError = false) {
      statusEl.textContent = text;
      statusEl.style.color = isError ? "var(--danger)" : "var(--muted)";
    }

    function getSessionId() {
      return document.getElementById("session").value.trim() || "voice-user";
    }

    function blobToDataUrl(blob) {
      return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onloadend = () => resolve(String(reader.result || ""));
        reader.onerror = () => reject(new Error("Could not read audio"));
        reader.readAsDataURL(blob);
      });
    }
  </script>
</body>
</html>
"""
    return html.replace("AUTH_VIEW_PATH", AUTH_VIEW_ROUTE).replace("SIGNUP_VIEW_PATH", "/signup").replace("CHAT_VIEW_PATH", CHAT_VIEW_ROUTE).replace(
        "DOCUMENT_VIEW_PATH", DOCUMENT_VIEW_ROUTE
    )
