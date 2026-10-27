import { useMemo, useState } from "react";
import Editor from "@monaco-editor/react";
import {
  ShieldCheck, ScanSearch, WandSparkles, Download, RotateCcw,
  FileCode2, CircleCheck, CircleAlert, LoaderCircle, Copy, TerminalSquare
} from "lucide-react";

const starterCode = `int main() {
    int a = 10;
    int b = 20;

    if (a < b) {
        printf("A is smaller");
    }

    return 0;
}`;

async function postJSON(endpoint, payload) {
  const response = await fetch(`http://127.0.0.1:5000/api/${endpoint}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error || `Request failed (${response.status})`);
  return data;
}

export default function App() {
  const [code, setCode] = useState(starterCode);
  const [correctedCode, setCorrectedCode] = useState("");
  const [analysis, setAnalysis] = useState(null);
  const [correctionLog, setCorrectionLog] = useState("");
  const [activeTab, setActiveTab] = useState("diagnostics");
  const [busy, setBusy] = useState("");
  const [message, setMessage] = useState("");
  const [showCorrected, setShowCorrected] = useState(false);

  const lineCount = useMemo(() => (code ? code.split("\n").length : 1), [code]);

  async function analyze() {
    setBusy("analyze");
    setMessage("");
    try {
      const result = await postJSON("analyze", { code });
      setAnalysis(result);
      setActiveTab("diagnostics");
      setMessage(result.valid ? "No syntax errors detected by the current grammar." : "Analysis complete. Review the parser output below.");
    } catch (err) {
      setMessage(err.message);
    } finally {
      setBusy("");
    }
  }

  async function correct() {
    setBusy("correct");
    setMessage("");
    try {
      const result = await postJSON("correct", { code });
      setCorrectedCode(result.corrected_code || "");
      setCorrectionLog(result.correction_log || "");
      setAnalysis(result.validation || null);
      setShowCorrected(true);
      setActiveTab("corrections");
      setMessage("A corrected copy was generated. Review it before using it.");
    } catch (err) {
      setMessage(err.message);
    } finally {
      setBusy("");
    }
  }

  function reset() {
    setCode(starterCode);
    setCorrectedCode("");
    setAnalysis(null);
    setCorrectionLog("");
    setMessage("");
    setShowCorrected(false);
    setActiveTab("diagnostics");
  }

  function downloadCorrected() {
    if (!correctedCode) return;
    const blob = new Blob([correctedCode], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = "syntaxguard_corrected.c";
    anchor.click();
    URL.revokeObjectURL(url);
  }

  async function copyCorrected() {
    if (!correctedCode) return;
    try {
      await navigator.clipboard.writeText(correctedCode);
      setMessage("Corrected code copied to clipboard.");
    } catch {
      setMessage("Clipboard access was blocked by the browser.");
    }
  }

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand">
          <div className="brand-mark"><ShieldCheck size={22} /></div>
          <div>
            <div className="brand-name">SyntaxGuard<span>.</span></div>
            <div className="brand-caption">C SYNTAX ANALYSIS WORKSPACE</div>
          </div>
        </div>
        <div className="topbar-right">
          <span className="engine-pill"><span className="status-dot" /> FLEX · BISON · PYTHON</span>
          <span className="version-label">LOCAL ENVIRONMENT</span>
        </div>
      </header>

      <main className="main-content">
        <section className="welcome-row">
          <div>
            <div className="eyebrow">CODE QUALITY / STATIC ANALYSIS</div>
            <h1>Catch errors before <span>they catch you.</span></h1>
            <p className="subtitle">Analyze supported C syntax, inspect diagnostics, and review suggested corrections in one workspace.</p>
          </div>
          <div className="workspace-chip"><FileCode2 size={16} /> Untitled.c <span className="chip-dot" /></div>
        </section>

        <section className="stats-row">
          <div className="stat-card"><div className="stat-icon blue"><FileCode2 size={18} /></div><div><span className="stat-label">SOURCE FILE</span><strong>C program</strong><small>{lineCount} lines · {code.length} characters</small></div></div>
          <div className="stat-card"><div className="stat-icon violet"><ScanSearch size={18} /></div><div><span className="stat-label">ANALYSIS ENGINE</span><strong>Flex + Bison</strong><small>Grammar-based parsing</small></div></div>
          <div className="stat-card"><div className="stat-icon green"><WandSparkles size={18} /></div><div><span className="stat-label">CORRECTION ENGINE</span><strong>Python rules</strong><small>Heuristic suggestions</small></div></div>
        </section>

        <section className="workbench">
          <div className="panel editor-panel">
            <div className="panel-heading">
              <div className="panel-title"><span className="file-icon">C</span><div><strong>Source Editor</strong><small>Write or paste your C-like code</small></div></div>
              <div className="panel-actions"><span className="language-badge">C</span><button className="icon-button" title="Reset code" onClick={reset}><RotateCcw size={16} /></button></div>
            </div>
            <div className="editor-wrap">
              <Editor
                height="440px"
                language="c"
                theme="vs-dark"
                value={code}
                onChange={(value) => setCode(value ?? "")}
                options={{
                  minimap: { enabled: false },
                  fontSize: 14,
                  lineNumbers: "on",
                  scrollBeyondLastLine: false,
                  automaticLayout: true,
                  tabSize: 4,
                  wordWrap: "on",
                  padding: { top: 16, bottom: 16 },
                  fontFamily: "'JetBrains Mono', Consolas, monospace"
                }}
              />
            </div>
            <div className="editor-footer"><span><span className="footer-dot" /> Ready for analysis</span><span>UTF-8&nbsp; · &nbsp;C</span></div>
            <div className="action-row">
              <button className="primary-button" onClick={analyze} disabled={!!busy}>
                {busy === "analyze" ? <LoaderCircle className="spin" size={17} /> : <ScanSearch size={17} />}
                {busy === "analyze" ? "Analyzing..." : "Detect Errors"}
              </button>
              <button className="secondary-button" onClick={correct} disabled={!!busy}>
                {busy === "correct" ? <LoaderCircle className="spin" size={17} /> : <WandSparkles size={17} />}
                {busy === "correct" ? "Correcting..." : "Auto-Correct"}
              </button>
              <span className="action-note">Corrections are heuristic. Review before accepting.</span>
            </div>
          </div>

          <div className="panel results-panel">
            <div className="panel-heading results-heading">
              <div className="panel-title"><div className="results-icon"><TerminalSquare size={19} /></div><div><strong>Analysis Results</strong><small>Diagnostics and correction output</small></div></div>
              {analysis && <span className={`result-badge ${analysis.valid ? "good" : "warn"}`}>{analysis.valid ? <CircleCheck size={13} /> : <CircleAlert size={13} />}{analysis.valid ? "VALID SYNTAX" : "ISSUES FOUND"}</span>}
            </div>
            <div className="tabs">
              <button className={activeTab === "diagnostics" ? "active" : ""} onClick={() => setActiveTab("diagnostics")}>Diagnostics</button>
              <button className={activeTab === "corrections" ? "active" : ""} onClick={() => setActiveTab("corrections")}>Corrections {correctedCode && <span className="tab-count">✓</span>}</button>
            </div>
            <div className="result-body">
              {message && <div className={`notice ${message.startsWith("Analysis failed") || message.startsWith("Correction failed") || message.includes("not found") || message.includes("Enter some") ? "notice-error" : ""}`}>{message}</div>}
              {activeTab === "diagnostics" ? (
                analysis ? (
                  <div className="output-card">
                    <div className="output-card-title"><span className={`mini-status ${analysis.valid ? "ok" : "bad"}`} />Parser output</div>
                    <pre className="terminal-output">{analysis.output || "The parser returned no output."}</pre>
                  </div>
                ) : (
                  <div className="empty-state"><div className="empty-icon"><ScanSearch size={24} /></div><strong>Ready to inspect your code</strong><p>Click <b>Detect Errors</b> to run the Flex/Bison parser and see its diagnostics here.</p><div className="empty-hint">OUTPUT WILL APPEAR HERE</div></div>
                )
              ) : (
                correctedCode ? (
                  <div className="correction-view">
                    <div className="output-card">
                      <div className="output-card-title"><span className="mini-status ok" />Corrector log</div>
                      <pre className="terminal-output log-output">{correctionLog || "Correction completed."}</pre>
                    </div>
                    <div className="corrected-actions"><span>Corrected source</span><div><button className="small-button" onClick={copyCorrected}><Copy size={14} /> Copy</button><button className="small-button download" onClick={downloadCorrected}><Download size={14} /> Download .c</button></div></div>
                    <div className="corrected-editor"><Editor height="250px" language="c" theme="vs-dark" value={correctedCode} options={{ readOnly: true, minimap: { enabled: false }, fontSize: 13, lineNumbers: "on", scrollBeyondLastLine: false, automaticLayout: true, wordWrap: "on" }} /></div>
                    {analysis && <div className={`validation-box ${analysis.valid ? "validation-good" : "validation-warn"}`}><div>{analysis.valid ? <CircleCheck size={17} /> : <CircleAlert size={17} />}<strong>{analysis.valid ? "Parser validation passed" : "Review parser diagnostics"}</strong></div><pre>{analysis.output}</pre></div>}
                  </div>
                ) : (
                  <div className="empty-state"><div className="empty-icon violet-empty"><WandSparkles size={24} /></div><strong>No corrected copy yet</strong><p>Click <b>Auto-Correct</b> to generate a separate corrected source file.</p><div className="empty-hint">REVIEW BEFORE ACCEPTING</div></div>
                )
              )}
            </div>
            <div className="results-footer"><span><span className="footer-dot" /> Local processing</span><span>SyntaxGuard workspace</span></div>
          </div>
        </section>

        <footer className="page-footer">
          <div><ShieldCheck size={16} /><span><strong>SyntaxGuard</strong> <span className="muted">· Syntax detection & correction</span></span></div>
          <p>Parser validation checks the grammar implemented in this project; it does not guarantee full C-language compatibility or program correctness.</p>
        </footer>
      </main>
    </div>
  );
}
