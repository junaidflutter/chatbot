from fastapi import APIRouter
from fastapi.responses import HTMLResponse
from constants import AUTH_VIEW_ROUTE, CHAT_VIEW_ROUTE, SIGNUP_VIEW_ROUTE

router = APIRouter()


@router.get(AUTH_VIEW_ROUTE, response_class=HTMLResponse)
async def login_page():
    html = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Login</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #f5f7fb; color: #172033; }
    main { max-width: 760px; margin: 40px auto; padding: 0 20px; }
    .card { background: white; border: 1px solid #d8dee9; border-radius: 8px; padding: 22px; }
    label { display: block; margin: 12px 0 6px; font-weight: 600; }
    input { width: 100%; box-sizing: border-box; border: 1px solid #c8d0dd; border-radius: 6px; padding: 10px; font: inherit; }
    button { margin-top: 12px; border: 0; border-radius: 6px; padding: 10px 14px; background: #1f6feb; color: white; cursor: pointer; }
    a { color: #0f62fe; text-decoration: none; }
    .top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px; }
    .hint { margin-top: 10px; color: #526070; }
    .status { margin-top: 10px; min-height: 22px; color: #526070; }
    .status.error { color: #b42318; }
    .status.success { color: #067647; }
    button[disabled] { opacity: 0.7; cursor: not-allowed; }
    pre { white-space: pre-wrap; background: #101828; color: #e6edf3; border-radius: 8px; padding: 14px; min-height: 110px; margin-top: 14px; }
  </style>
</head>
<body>
  <main>
    <div class="top">
      <h1>Login</h1>
      <a href="SIGNUP_VIEW_PATH">Create account</a>
    </div>
    <section class="card">
      <label>Email</label>
      <input id="email" type="email">
      <label>Password</label>
      <input id="password" type="password">
      <button id="loginButton" onclick="loginUser()">Login</button>
      <button onclick="goToChat()" style="background:#5b6677;">Go to chat</button>
      <div class="hint">After login, you will be redirected to chat.</div>
      <div class="status" id="status"></div>
      <pre id="result"></pre>
    </section>
  </main>
  <script>
    const result = document.getElementById("result");
    const status = document.getElementById("status");
    const loginButton = document.getElementById("loginButton");

    function getToken() {
      return localStorage.getItem("access_token") || "";
    }

    function setToken(token) {
      localStorage.setItem("access_token", token);
    }

    function setStatus(message, kind) {
      status.className = "status" + (kind ? " " + kind : "");
      status.textContent = message;
    }

    function goToChat() {
      window.location.href = "CHAT_VIEW_PATH";
    }

    if (getToken()) {
      window.location.href = "CHAT_VIEW_PATH";
    }

    async function loginUser() {
      loginButton.disabled = true;
      setStatus("Logging in...", "");
      try {
        const response = await fetch("/auth/login", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            email: document.getElementById("email").value,
            password: document.getElementById("password").value
          })
        });
        const data = await response.json();
        result.textContent = JSON.stringify(data, null, 2);
        if (!response.ok) {
          setStatus(data.detail || "Login failed.", "error");
          return;
        }
        if (data.access_token) {
          setToken(data.access_token);
        }
        setStatus("Login successful. Redirecting...", "success");
        window.setTimeout(() => {
          window.location.href = "CHAT_VIEW_PATH";
        }, 350);
      } catch (error) {
        setStatus(error.message || "Login failed.", "error");
      } finally {
        loginButton.disabled = false;
      }
    }
  </script>
</body>
</html>
"""
    return html.replace("SIGNUP_VIEW_PATH", SIGNUP_VIEW_ROUTE).replace("CHAT_VIEW_PATH", CHAT_VIEW_ROUTE)


@router.get(SIGNUP_VIEW_ROUTE, response_class=HTMLResponse)
async def signup_page():
    html = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #f5f7fb; color: #172033; }
    main { max-width: 760px; margin: 40px auto; padding: 0 20px; }
    .card { background: white; border: 1px solid #d8dee9; border-radius: 8px; padding: 22px; }
    label { display: block; margin: 12px 0 6px; font-weight: 600; }
    input { width: 100%; box-sizing: border-box; border: 1px solid #c8d0dd; border-radius: 6px; padding: 10px; font: inherit; }
    button { margin-top: 12px; border: 0; border-radius: 6px; padding: 10px 14px; background: #1f6feb; color: white; cursor: pointer; }
    a { color: #0f62fe; text-decoration: none; }
    .top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px; }
    .status { margin-top: 10px; min-height: 22px; color: #526070; }
    .status.error { color: #b42318; }
    .status.success { color: #067647; }
    button[disabled] { opacity: 0.7; cursor: not-allowed; }
    pre { white-space: pre-wrap; background: #101828; color: #e6edf3; border-radius: 8px; padding: 14px; min-height: 110px; margin-top: 14px; }
  </style>
</head>
<body>
  <main>
    <div class="top">
      <h1>Sign up</h1>
      <a href="AUTH_VIEW_PATH">Login</a>
    </div>
    <section class="card">
      <label>Email</label>
      <input id="email" type="email">
      <label>Name</label>
      <input id="name">
      <label>Password</label>
      <input id="password" type="password">
      <button id="signupButton" onclick="registerUser()">Create account</button>
      <div class="status" id="status"></div>
      <pre id="result"></pre>
    </section>
  </main>
  <script>
    const result = document.getElementById("result");
    const status = document.getElementById("status");
    const signupButton = document.getElementById("signupButton");

    if (localStorage.getItem("access_token")) {
      window.location.href = "CHAT_VIEW_PATH";
    }

    function setStatus(message, kind) {
      status.className = "status" + (kind ? " " + kind : "");
      status.textContent = message;
    }

    async function registerUser() {
      signupButton.disabled = true;
      setStatus("Creating account...", "");
      try {
        const response = await fetch("/auth/register", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            email: document.getElementById("email").value,
            name: document.getElementById("name").value,
            password: document.getElementById("password").value
          })
        });
        const data = await response.json();
        result.textContent = JSON.stringify(data, null, 2);
        if (!response.ok) {
          setStatus(data.detail || "Sign up failed.", "error");
          return;
        }
        if (data.access_token) {
          localStorage.setItem("access_token", data.access_token);
        }
        setStatus("Account created successfully. Redirecting...", "success");
        window.setTimeout(() => {
          window.location.href = "CHAT_VIEW_PATH";
        }, 450);
      } catch (error) {
        setStatus(error.message || "Sign up failed.", "error");
      } finally {
        signupButton.disabled = false;
      }
    }
  </script>
</body>
</html>
"""
    return html.replace("AUTH_VIEW_PATH", AUTH_VIEW_ROUTE).replace("CHAT_VIEW_PATH", CHAT_VIEW_ROUTE)
