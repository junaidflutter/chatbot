from fastapi import APIRouter
from fastapi.responses import HTMLResponse
from constants import (
    AUTH_VIEW_ROUTE,
    CHAT_VIEW_ROUTE,
    DOCUMENT_VIEW_ROUTE,
    SOCKET_AUDIO_BASE64_KEY,
    SOCKET_AUDIO_FILENAME_KEY,
    SOCKET_AUDIO_MIME_TYPE_KEY,
    SOCKET_SESSION_ID_KEY,
    SOCKET_VOICE_AUDIO_EVENT,
    SOCKET_VOICE_TRANSCRIPT_EVENT,
    SOCKET_VOICE_TRANSCRIBING_EVENT,
    SOCKET_ERROR_KEY,
    SOCKET_QUESTION_KEY,
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
  <title>Voice Car Chat</title>
  <style>
    :root {
      --bg: #eef2f7;
      --panel: #ffffff;
      --panel-2: #f7f9fc;
      --text: #0f172a;
      --muted: #526070;
      --border: #d7deea;
      --accent: #1f6feb;
      --danger: #a61b1b;
      --shadow: 0 10px 30px rgba(15, 23, 42, 0.08);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: Arial, sans-serif;
      background:
        radial-gradient(circle at top left, rgba(31, 111, 235, 0.08), transparent 34%),
        radial-gradient(circle at top right, rgba(22, 163, 74, 0.08), transparent 30%),
        var(--bg);
      color: var(--text);
    }
    main { max-width: 1120px; margin: 28px auto; padding: 0 18px 28px; }
    header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 16px;
      margin-bottom: 18px;
    }
    h1 { margin: 0; font-size: 30px; line-height: 1.1; letter-spacing: 0; }
    .subtle { margin-top: 8px; color: var(--muted); font-size: 14px; line-height: 1.4; }
    nav { display: flex; gap: 14px; flex-wrap: wrap; justify-content: flex-end; padding-top: 8px; }
    a { color: var(--accent); text-decoration: none; }
    .shell { display: grid; grid-template-columns: 360px minmax(0, 1fr); gap: 16px; align-items: start; }
    .card { background: var(--panel); border: 1px solid var(--border); border-radius: 10px; box-shadow: var(--shadow); }
    .card-head { padding: 16px 16px 0; }
    .card-body { padding: 16px; }
    label { display: block; margin: 0 0 6px; font-weight: 700; font-size: 14px; }
    input {
      width: 100%;
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 12px 14px;
      font: inherit;
      color: var(--text);
      background: #fff;
    }
    .controls { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; margin-top: 6px; }
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
    button.ghost { background: #e9eef7; color: var(--text); border: 1px solid var(--border); }
    button:disabled { background: #aeb8c8; cursor: not-allowed; }
    .statusbar { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
    .chip {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 10px;
      border-radius: 999px;
      font-size: 13px;
      background: var(--panel-2);
      border: 1px solid var(--border);
      color: var(--muted);
    }
    .chip strong { color: var(--text); font-weight: 700; }
    .meter {
      height: 11px;
      background: #dfe6f1;
      border-radius: 999px;
      overflow: hidden;
      margin-top: 14px;
    }
    .meter-fill {
      height: 100%;
      width: 0%;
      background: linear-gradient(90deg, var(--accent), #4c8bf5);
      transition: width 70ms linear;
    }
    .hint { margin-top: 10px; color: var(--muted); font-size: 13px; line-height: 1.45; }
    .feed {
      display: flex;
      flex-direction: column;
      gap: 12px;
      padding: 16px;
      min-height: 420px;
      max-height: 74vh;
      overflow: auto;
      background: linear-gradient(180deg, #fbfcfe 0%, #f7f9fd 100%);
      border-radius: 10px;
    }
    .message {
      display: flex;
      flex-direction: column;
      gap: 4px;
      width: fit-content;
      max-width: min(78%, 620px);
    }
    .message .role {
      font-size: 12px;
      font-weight: 700;
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }
    .bubble {
      display: inline-block;
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 14px 15px;
      white-space: pre-wrap;
      line-height: 1.55;
      word-break: break-word;
      background: white;
      width: fit-content;
      min-width: 0;
    }
    .user { margin-left: auto; align-items: flex-end; }
    .user .bubble { background: #eaf2ff; border-color: #c7d9fb; }
    .assistant .bubble { background: white; }
    .meta {
      display: flex;
      gap: 8px;
      align-items: center;
      font-size: 12px;
      color: var(--muted);
      line-height: 1.2;
      padding: 0 2px;
    }
    .meta time { font-variant-numeric: tabular-nums; }
    .draft {
      margin-top: 12px;
      padding: 14px 15px;
      border-radius: 12px;
      border: 1px dashed var(--border);
      background: #fbfcfe;
      color: var(--text);
      white-space: pre-wrap;
      min-height: 56px;
    }
    .section-title { margin: 0 0 10px; font-size: 15px; }
    @media (max-width: 900px) {
      .shell { grid-template-columns: 1fr; }
      .feed { max-height: none; min-height: 420px; }
      header { flex-direction: column; }
      nav { justify-content: flex-start; }
    }
  </style>
</head>
<body>
  <main>
    <header>
      <div>
        <h1>Voice Chat</h1>
        <div class="subtle">Speak a question, let the assistant answer it, then continue with the next one.</div>
      </div>
      <nav>
        <a href="AUTH_VIEW_PATH">Login</a>
        <a href="SIGNUP_VIEW_PATH">Signup</a>
        <a href="CHAT_VIEW_PATH">Text chat</a>
        <a href="DOCUMENT_VIEW_PATH">Upload documents</a>
      </nav>
    </header>

    <div class="shell">
      <section class="card">
        <div class="card-head">
          <label for="session">Session ID</label>
          <input id="session" value="voice-user">

          <div class="controls">
            <button id="startButton" onclick="startVoiceLoop()">Start voice chat</button>
            <button id="talkButton" class="secondary" style="display:none">Hold to talk</button>
            <button id="modeButton" class="ghost" type="button">Mode: Hands-free</button>
            <button id="stopButton" class="secondary" onclick="stopVoiceLoop()" disabled>Stop</button>
          </div>

          <div class="statusbar">
            <div class="chip"><strong>Status</strong> <span id="status">Idle</span></div>
            <div class="chip"><strong>Mode</strong> <span id="modeLabel">Stopped</span></div>
          </div>

          <div class="meter"><div class="meter-fill" id="meterFill"></div></div>
          <div class="hint">The app records only while you speak, transcribes on the server, and then plays the answer back faster.</div>
        </div>

        <div class="card-body">
          <div class="section-title">Live transcript</div>
          <div class="draft" id="draft"></div>
        </div>
      </section>

      <section class="card">
        <div class="card-head">
          <div class="section-title">Conversation</div>
        </div>
        <div class="feed" id="feed"></div>
      </section>
    </div>
  </main>

  <script src="https://cdn.socket.io/4.7.5/socket.io.min.js"></script>
  <script>
    const socket = io();
    const startButton = document.getElementById("startButton");
    const talkButton = document.getElementById("talkButton");
    const modeButton = document.getElementById("modeButton");
    const stopButton = document.getElementById("stopButton");
    const statusEl = document.getElementById("status");
    const modeLabel = document.getElementById("modeLabel");
    const draftEl = document.getElementById("draft");
    const feedEl = document.getElementById("feed");
    const meterFill = document.getElementById("meterFill");

    function getAccessToken() {
      return localStorage.getItem("access_token") || "";
    }

    if (!getAccessToken()) {
      window.location.href = "/login";
    }

    let audioContext = null;
    let analyser = null;
    let micStream = null;
    let mediaRecorder = null;
    let browserRecognition = null;
    let speechVoices = [];
    let selectedVoice = null;
    let recorderChunks = [];
    let vadFrame = null;
    let silenceTimer = null;
    let captureTimeout = null;
    let resumeListenAt = 0;
    let voiceLoopActive = false;
    let recordingMode = "handsfree";
    let recording = false;
    let uploading = false;
    let phase = "stopped";
    let currentAssistantBubble = null;
    let currentAssistantText = "";
    let pendingTranscript = "";

    socket.on("connect", () => {
      socket.emit("join_session", { session_id: getSessionId(), access_token: getAccessToken() });
      setStatus("Socket connected", "stopped");
    });

    socket.on("message_ack", () => {
      setStatus("Question sent", phase);
    });

    socket.on("assistant_typing", () => {
      phase = "thinking";
      currentAssistantText = "";
      currentAssistantBubble = addMessage("assistant", "");
      setStatus("Assistant is answering", phase);
    });

    socket.on("assistant_chunk", (data) => {
      currentAssistantText += data.chunk || "";
      if (!currentAssistantBubble) {
        currentAssistantBubble = addMessage("assistant", "");
      }
      currentAssistantBubble.querySelector(".bubble").textContent = currentAssistantText;
      scrollFeed();
    });

    socket.on("assistant_done", () => {
      phase = "speaking";
      setStatus("Speaking answer", phase);
      speakAnswer(currentAssistantText);
    });

    socket.on("assistant_error", (data) => {
      phase = "idle";
      setStatus(data.error || "Socket error", phase, true);
      if (voiceLoopActive && recordingMode === "handsfree") {
        scheduleResumeListening(1200);
      }
    });

    socket.on("voice_transcribing", () => {
      phase = "transcribing";
      setStatus("Transcribing audio", phase);
    });

    socket.on("voice_transcript", (data) => {
      const transcript = (data && data.question) ? String(data.question) : "";
      pendingTranscript = transcript.trim();
      if (!pendingTranscript) {
        phase = "idle";
        setStatus("Empty transcript", phase, true);
        if (voiceLoopActive && recordingMode === "handsfree") {
          scheduleResumeListening(900);
        }
        return;
      }

      draftEl.textContent = pendingTranscript;
      addMessage("user", pendingTranscript);
      phase = "sending";
      setStatus("Sending question", phase);
      socket.emit("send_message", {
        question: pendingTranscript,
        session_id: getSessionId(),
        access_token: getAccessToken()
      });
    });

    modeButton.addEventListener("click", () => {
      recordingMode = recordingMode === "handsfree" ? "push-to-talk" : "handsfree";
      updateModeUI();
    });

    talkButton.addEventListener("pointerdown", () => {
      if (recordingMode === "push-to-talk") {
        startCapture();
      }
    });

    talkButton.addEventListener("pointerup", () => {
      if (recordingMode === "push-to-talk") {
        stopCapture();
      }
    });

    talkButton.addEventListener("pointercancel", () => {
      if (recordingMode === "push-to-talk") {
        stopCapture();
      }
    });

    talkButton.addEventListener("pointerleave", () => {
      if (recordingMode === "push-to-talk" && recording) {
        stopCapture();
      }
    });

    async function startVoiceLoop() {
      try {
        micStream = await navigator.mediaDevices.getUserMedia({
          audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true
          }
        });

        setupVad(micStream);
        setupRecorder(micStream);
        setupBrowserRecognition();
        loadSpeechVoices();

        voiceLoopActive = true;
        phase = "idle";
        startButton.disabled = true;
        stopButton.disabled = false;
        updateModeUI();
        setStatus("Ready to listen", phase);
        if (recordingMode === "handsfree") {
          startCapture();
        }
      } catch (error) {
        setStatus("Mic permission failed: " + error.message, "stopped", true);
      }
    }

    function stopVoiceLoop() {
      voiceLoopActive = false;
      phase = "stopped";
      recording = false;
      uploading = false;
      startButton.disabled = false;
      talkButton.style.display = "none";
      stopButton.disabled = true;
      modeLabel.textContent = "Stopped";
      setStatus("Stopped", phase);
      draftEl.textContent = "";
      window.speechSynthesis.cancel();
      stopBrowserRecognition();

      if (silenceTimer) {
        clearTimeout(silenceTimer);
        silenceTimer = null;
      }
      if (captureTimeout) {
        clearTimeout(captureTimeout);
        captureTimeout = null;
      }
      if (mediaRecorder && mediaRecorder.state !== "inactive") {
        mediaRecorder.stop();
      }
      if (vadFrame) {
        cancelAnimationFrame(vadFrame);
        vadFrame = null;
      }
      if (micStream) {
        micStream.getTracks().forEach((track) => track.stop());
        micStream = null;
      }
      if (audioContext) {
        audioContext.close();
        audioContext = null;
      }

      meterFill.style.width = "0%";
    }

    function updateModeUI() {
      modeButton.textContent = recordingMode === "handsfree" ? "Mode: Hands-free" : "Mode: Push-to-talk";
      talkButton.style.display = voiceLoopActive && recordingMode === "push-to-talk" ? "inline-flex" : "none";
      startButton.textContent = recordingMode === "handsfree" ? "Start voice chat" : "Enable mic";
    }

    function setupRecorder(stream) {
      mediaRecorder = new MediaRecorder(stream, { mimeType: "audio/webm" });
      recorderChunks = [];

      mediaRecorder.ondataavailable = (event) => {
        if (event.data && event.data.size > 0) {
          recorderChunks.push(event.data);
        }
      };

      mediaRecorder.onstop = async () => {
        recording = false;
        stopBrowserRecognition();
        if (captureTimeout) {
          clearTimeout(captureTimeout);
          captureTimeout = null;
        }
        const audioBlob = new Blob(recorderChunks, { type: "audio/webm" });
        recorderChunks = [];

        if (!voiceLoopActive || audioBlob.size === 0) {
          if (voiceLoopActive && phase !== "speaking") {
            phase = "idle";
            if (recordingMode === "handsfree") {
              scheduleResumeListening(500);
            }
          }
          return;
        }

        try {
          uploading = true;
          phase = "uploading";
          setStatus("Transcribing audio", phase);
          const audioBase64 = await blobToDataUrl(audioBlob);
          uploading = false;
          phase = "transcribing";
          setStatus("Uploading audio over socket", phase);
          socket.emit("voice_audio", {
            session_id: getSessionId(),
            access_token: getAccessToken(),
            audio_base64: audioBase64,
            mime_type: audioBlob.type || "audio/webm",
            audio_filename: "voice.webm"
          });
        } catch (error) {
          uploading = false;
          phase = "idle";
          setStatus("Transcription failed: " + error.message, phase, true);
          if (voiceLoopActive && recordingMode === "handsfree") {
            scheduleResumeListening(1200);
          }
        }
      };
    }

    function setupVad(stream) {
      audioContext = new AudioContext();
      analyser = audioContext.createAnalyser();
      analyser.fftSize = 1024;

      const source = audioContext.createMediaStreamSource(stream);
      source.connect(analyser);

      const samples = new Uint8Array(analyser.fftSize);
      const renderMeter = () => {
        if (!analyser) {
          return;
        }

        analyser.getByteTimeDomainData(samples);
        let sum = 0;
        for (const sample of samples) {
          const value = (sample - 128) / 128;
          sum += value * value;
        }

        const rms = Math.sqrt(sum / samples.length);
        const level = Math.min(100, Math.round(rms * 420));
        meterFill.style.width = level + "%";

        if (voiceLoopActive && phase === "idle" && Date.now() >= resumeListenAt && level > 8 && !recording && !uploading) {
          startCapture();
        }

        if (phase === "recording") {
          if (level > 8) {
            if (silenceTimer) {
              clearTimeout(silenceTimer);
              silenceTimer = null;
            }
            setStatus("Voice detected", "recording");
          } else if (!silenceTimer && recording) {
            silenceTimer = window.setTimeout(() => {
              silenceTimer = null;
              if (voiceLoopActive && phase === "recording" && recording) {
                setStatus("Silence detected", "recording");
                stopCapture();
              }
            }, 1300);
          }
        } else if (phase === "speaking" && level > 12) {
          interruptAssistant();
        }

        vadFrame = requestAnimationFrame(renderMeter);
      };

      renderMeter();
    }

    function setupBrowserRecognition() {
      const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (!SpeechRecognition) {
        browserRecognition = null;
        return;
      }

      browserRecognition = new SpeechRecognition();
      browserRecognition.lang = "en-US";
      browserRecognition.continuous = true;
      browserRecognition.interimResults = true;

      browserRecognition.onresult = (event) => {
        if (phase !== "recording") {
          return;
        }

        let liveText = "";
        for (let i = event.resultIndex; i < event.results.length; i += 1) {
          liveText += event.results[i][0].transcript;
        }

        const clean = liveText.trim();
        if (clean) {
          draftEl.textContent = clean;
        }
      };

      browserRecognition.onerror = () => {};
      window.speechSynthesis.onvoiceschanged = () => {
        loadSpeechVoices();
      };
    }

    function startBrowserRecognition() {
      if (!browserRecognition) {
        return;
      }

      try {
        browserRecognition.start();
      } catch (error) {
      }
    }

    function stopBrowserRecognition() {
      if (!browserRecognition) {
        return;
      }

      try {
        browserRecognition.abort();
      } catch (error) {
      }
    }

    function loadSpeechVoices() {
      const voices = window.speechSynthesis.getVoices();
      if (!voices || !voices.length) {
        return;
      }

      speechVoices = voices;
      selectedVoice = pickBestVoice(voices);
    }

    function pickBestVoice(voices) {
      const preferred = voices.find((voice) => {
        const name = (voice.name || "").toLowerCase();
        return name.includes("natural") || name.includes("google") || name.includes("microsoft") || name.includes("samantha") || name.includes("aria") || name.includes("zira");
      });

      return preferred || voices[0] || null;
    }

    function interruptAssistant() {
      if (phase !== "speaking") {
        return;
      }

      window.speechSynthesis.cancel();
      phase = "idle";
      modeLabel.textContent = "Ready";
      setStatus("Interrupted", phase);
      if (voiceLoopActive && recordingMode === "handsfree") {
        scheduleResumeListening(900);
      }
    }

    function startCapture() {
      if (!voiceLoopActive || recording || uploading || !mediaRecorder) {
        return;
      }

      if (phase === "speaking") {
        interruptAssistant();
      }

      phase = "recording";
      draftEl.textContent = "Listening...";
      try {
        recorderChunks = [];
        mediaRecorder.start();
        recording = true;
        startBrowserRecognition();
        if (captureTimeout) {
          clearTimeout(captureTimeout);
        }
        captureTimeout = window.setTimeout(() => {
          if (voiceLoopActive && recording && mediaRecorder && mediaRecorder.state === "recording") {
            setStatus("Max capture reached, processing", "recording");
            stopCapture();
          }
        }, 8500);
        setStatus("Recording your question", phase);
      } catch (error) {
        setStatus("Recording start failed", phase, true);
      }
    }

    function stopCapture() {
      if (!mediaRecorder || mediaRecorder.state === "inactive") {
        stopBrowserRecognition();
        return;
      }

      stopBrowserRecognition();
      try {
        mediaRecorder.stop();
      } catch (error) {
        setStatus("Recording stop failed", phase, true);
      }
    }

    function speakAnswer(text) {
      const answer = (text || "").trim();
      if (!answer) {
        phase = "idle";
        setStatus("Ready for next question", phase);
        if (voiceLoopActive && recordingMode === "handsfree") {
          scheduleResumeListening(1600);
        }
        return;
      }

      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(answer);
      utterance.lang = "en-US";
      utterance.rate = 1.08;
      utterance.pitch = 1;
      utterance.voice = selectedVoice;
      utterance.onstart = () => {
        modeLabel.textContent = "Speaking";
      };
      utterance.onend = () => {
        phase = "idle";
        modeLabel.textContent = "Ready";
        setStatus("Ready for next question", phase);
        if (voiceLoopActive && recordingMode === "handsfree") {
          scheduleResumeListening(1800);
        }
      };
      utterance.onerror = () => {
        phase = "idle";
        modeLabel.textContent = "Ready";
        setStatus("Speech playback failed", phase, true);
        if (voiceLoopActive && recordingMode === "handsfree") {
          scheduleResumeListening(1800);
        }
      };
      window.speechSynthesis.speak(utterance);
    }

    function addMessage(role, text) {
      const message = document.createElement("div");
      message.className = "message " + role;

      const label = document.createElement("div");
      label.className = "role";
      label.textContent = role === "user" ? "You" : "Assistant";

      const bubble = document.createElement("div");
      bubble.className = "bubble";
      bubble.textContent = text || "";

      const meta = document.createElement("div");
      meta.className = "meta";

      const time = document.createElement("time");
      const now = new Date();
      time.dateTime = now.toISOString();
      time.textContent = formatTimestamp(now);
      meta.appendChild(time);

      message.appendChild(label);
      message.appendChild(bubble);
      message.appendChild(meta);
      feedEl.appendChild(message);
      scrollFeed();
      return message;
    }

    function scrollFeed() {
      feedEl.scrollTop = feedEl.scrollHeight;
    }

    function setStatus(text, mode, isError = false) {
      statusEl.textContent = text;
      modeLabel.textContent =
        mode === "stopped" ? "Stopped" :
        mode === "speaking" ? "Speaking" :
        mode === "thinking" ? "Thinking" :
        mode === "uploading" ? "Uploading" :
        mode === "sending" ? "Sending" :
        mode === "recording" ? "Recording" :
        mode === "idle" ? "Ready" : "Ready";
      statusEl.style.color = isError ? "var(--danger)" : "var(--muted)";
    }

    function formatTimestamp(date) {
      return new Intl.DateTimeFormat("en-US", {
        month: "short",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit"
      }).format(date);
    }

    function getSessionId() {
      return document.getElementById("session").value.trim() || "voice-user";
    }

    function scheduleResumeListening(delayMs) {
      resumeListenAt = Date.now() + delayMs;
      if (voiceLoopActive) {
        window.setTimeout(() => {
          if (voiceLoopActive && phase === "idle" && Date.now() >= resumeListenAt) {
            startCapture();
          }
        }, delayMs);
      }
    }

    function blobToDataUrl(blob) {
      return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onloadend = () => {
          resolve(String(reader.result || ""));
        };
        reader.onerror = () => {
          reject(new Error("Could not read audio"));
        };
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
