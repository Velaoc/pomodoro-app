import { Controller } from "@hotwired/stimulus"

// Pomodoro countdown. Runs entirely client-side so guests can use it with no
// account; when signed in, completed sessions are posted to /timer/record for
// history. The active state survives a refresh via localStorage so a reload
// mid-focus keeps counting from the real elapsed time.

const MODES = {
  focus:       { label: "Focus",        minutes: 25, longEvery: 4 },
  short_break: { label: "Short break",  minutes: 5 },
  long_break:  { label: "Long break",   minutes: 15 }
}

const STORAGE_KEY = "pomodoro.state.v1"

export default class extends Controller {
  static targets = ["time", "progress", "progressFill", "modeName", "startPause", "reset", "status", "cycleDot"]
  static values = { signedIn: Boolean, recordUrl: String }

  connect() {
    this.loadState()
    this.remaining = this.remaining ?? this.modeMinutes() * 60
    this.running = this.running ?? false
    this.completedInCycle = this.completedInCycle ?? 0
    this.render()
    this.startTick()
  }

  disconnect() {
    this.stopTick()
  }

  selectMode(event) {
    if (this.running) return
    this.mode = event.currentTarget.dataset.mode
    this.remaining = this.modeMinutes() * 60
    this.render()
  }

  startPause() {
    if (!this.running) {
      this.startedAt = Date.now()
      this.running = true
      this.startTick()
    } else {
      this.freezeRemaining()
      this.running = false
      this.stopTick()
    }
    this.saveState()
    this.render()
  }

  reset() {
    this.running = false
    this.startedAt = null
    this.remaining = this.modeMinutes() * 60
    this.saveState()
    this.render()
  }

  freezeRemaining() {
    if (!this.startedAt) return
    this.remaining = Math.max(0, this.modeMinutes() * 60 - Math.floor((Date.now() - this.startedAt) / 1000))
    this.startedAt = null
  }

  startTick() {
    if (this.tickId) return
    this.tickId = window.setInterval(() => this.tick(), 250)
  }

  stopTick() {
    if (this.tickId) {
      window.clearInterval(this.tickId)
      this.tickId = null
    }
  }

  tick() {
    if (!this.running || !this.startedAt) return
    const elapsed = Math.floor((Date.now() - this.startedAt) / 1000)
    this.remaining = Math.max(0, this.modeMinutes() * 60 - elapsed)
    if (this.remaining <= 0) {
      this.complete()
    }
    this.render()
  }

  complete() {
    this.running = false
    this.startedAt = null
    this.finishSession()
    this.beep()
    this.advanceMode()
    this.render()
  }

  finishSession() {
    const kind = this.mode
    const minutes = this.modeMinutes()

    if (kind === "focus") {
      this.completedInCycle = (this.completedInCycle % 4) + 1
    }
    if (this.signedInValue) {
      this.recordSession(kind, minutes)
    }
    this.setStatus(kind === "focus" ? "Focus complete — take a break." : "Break over — back to it.")
  }

  advanceMode() {
    if (this.mode === "focus") {
      this.mode = this.completedInCycle % 4 === 0 ? "long_break" : "short_break"
    } else {
      this.mode = "focus"
    }
    this.remaining = this.modeMinutes() * 60
    this.saveState()
  }

  recordSession(kind, minutes) {
    const body = new URLSearchParams({ kind: kind, duration_minutes: String(minutes) })
    fetch(this.recordUrlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content || "" },
      body: body,
      credentials: "same-origin"
    }).catch(() => {})
  }

  beep() {
    try {
      const ctx = new AudioContext()
      const play = () => {
        const osc = ctx.createOscillator()
        const gain = ctx.createGain()
        osc.connect(gain)
        gain.connect(ctx.destination)
        osc.frequency.value = 880
        osc.type = "sine"
        gain.gain.setValueAtTime(0.001, ctx.currentTime)
        gain.gain.exponentialRampToValueAtTime(0.3, ctx.currentTime + 0.02)
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.6)
        osc.start()
        osc.stop(ctx.currentTime + 0.65)
      }
      if (ctx.state === "suspended") {
        ctx.resume().then(play)
      } else {
        play()
      }
      window.setTimeout(() => ctx.close(), 1500)
    } catch (e) {
      // No Web Audio available — the visual state still advances.
    }
  }

  setStatus(message) {
    this.statusTarget.textContent = message
  }

  modeMinutes() {
    return MODES[this.mode].minutes
  }

  render() {
    const mode = MODES[this.mode]
    this.modeNameTarget.textContent = mode.label

    const total = mode.minutes * 60
    const seconds = Math.max(0, Math.ceil(this.remaining))
    const mm = String(Math.floor(seconds / 60)).padStart(2, "0")
    const ss = String(seconds % 60).padStart(2, "0")
    this.timeTarget.textContent = `${mm}:${ss}`

    const pct = Math.max(0, Math.min(100, (this.remaining / total) * 100))
    this.progressTarget.setAttribute("aria-valuenow", String(Math.round(pct)))
    this.progressFillTarget.style.width = `${pct}%`

    this.startPauseTarget.textContent = this.running ? "Pause" : "Start"
    this.startPauseTarget.setAttribute("aria-pressed", String(this.running))

    this.cycleDotTargets.forEach((dot, i) => {
      dot.classList.toggle("timer-card__dot--done", i < this.completedInCycle)
    })

    document.querySelectorAll("[data-mode]").forEach((btn) => {
      btn.classList.toggle("md-button--selected", btn.dataset.mode === this.mode)
      btn.setAttribute("aria-selected", String(btn.dataset.mode === this.mode))
    })
  }

  loadState() {
    try {
      const raw = window.localStorage.getItem(STORAGE_KEY)
      if (!raw) return
      const state = JSON.parse(raw)
      this.mode = MODES[state.mode] ? state.mode : "focus"
      this.running = Boolean(state.running)
      this.completedInCycle = Number(state.completedInCycle) || 0
      this.startedAt = state.running ? Number(state.startedAt) : null
    } catch (e) {
      this.mode = "focus"
    }
  }

  saveState() {
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify({
        mode: this.mode,
        running: this.running,
        startedAt: this.running ? this.startedAt : null,
        completedInCycle: this.completedInCycle
      }))
    } catch (e) {
      // Private mode or storage full — the timer still runs for this visit.
    }
  }
}
