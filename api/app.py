from pathlib import Path
import os
import subprocess
import tempfile
import uuid

from flask import Flask, jsonify, request
from flask_cors import CORS

PROJECT_ROOT = Path(__file__).resolve().parent.parent
PARSER_EXE = PROJECT_ROOT / "backend" / "syntaxguard.exe"
CORRECTOR = PROJECT_ROOT / "corrector.py"
TEST_DIR = PROJECT_ROOT / "test"

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": [
    "http://localhost:5173",
    "http://127.0.0.1:5173"
]}})
def ensure_setup():
    missing = [str(p) for p in (PARSER_EXE, CORRECTOR) if not p.exists()]
    if missing:
        raise FileNotFoundError(
            "Required SyntaxGuard files not found: " + ", ".join(missing)
        )
    TEST_DIR.mkdir(parents=True, exist_ok=True)

def run_parser(source_path: Path):
    result = subprocess.run(
        [str(PARSER_EXE), str(source_path)],
        cwd=str(PARSER_EXE.parent),
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=15,
    )
    output = (result.stdout or "") + (result.stderr or "")
    return {
        "output": output.strip(),
        "valid": "RESULT: VALID SYNTAX" in output,
        "return_code": result.returncode,
    }

def create_temp_source(code: str):
    TEST_DIR.mkdir(parents=True, exist_ok=True)
    path = TEST_DIR / f"web_input_{uuid.uuid4().hex}.c"
    path.write_text(code, encoding="utf-8")
    return path

@app.get("/api/health")
def health():
    return jsonify({"ok": True, "service": "SyntaxGuard API"})

@app.post("/api/analyze")
def analyze():
    data = request.get_json(silent=True) or {}
    code = data.get("code", "")
    if not isinstance(code, str) or not code.strip():
        return jsonify({"error": "Enter some C code before analyzing."}), 400

    source = None
    try:
        ensure_setup()
        source = create_temp_source(code)
        return jsonify(run_parser(source))
    except subprocess.TimeoutExpired:
        return jsonify({"error": "Analysis took too long and was stopped."}), 504
    except FileNotFoundError as exc:
        return jsonify({"error": str(exc)}), 500
    except Exception as exc:
        app.logger.exception("Analysis failed")
        return jsonify({"error": f"Analysis failed: {exc}"}), 500
    finally:
        if source:
            source.unlink(missing_ok=True)

@app.post("/api/correct")
def correct():
    data = request.get_json(silent=True) or {}
    code = data.get("code", "")
    if not isinstance(code, str) or not code.strip():
        return jsonify({"error": "Enter some C code before correction."}), 400

    source = corrected = None
    try:
        ensure_setup()
        source = create_temp_source(code)
        corrected = source.with_name(source.stem + "_corrected.c")
        result = subprocess.run(
            [os.environ.get("SYNTAXGUARD_PYTHON", os.sys.executable),
             str(CORRECTOR), str(source)],
            cwd=str(PROJECT_ROOT),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=15,
        )
        log = ((result.stdout or "") + (result.stderr or "")).strip()
        if not corrected.exists():
            return jsonify({
                "error": "The corrector did not produce an output file.",
                "log": log,
            }), 500

        corrected_code = corrected.read_text(encoding="utf-8", errors="replace")
        validation = run_parser(corrected)
        return jsonify({
            "corrected_code": corrected_code,
            "correction_log": log,
            "validation": validation,
        })
    except subprocess.TimeoutExpired:
        return jsonify({"error": "Correction took too long and was stopped."}), 504
    except FileNotFoundError as exc:
        return jsonify({"error": str(exc)}), 500
    except Exception as exc:
        app.logger.exception("Correction failed")
        return jsonify({"error": f"Correction failed: {exc}"}), 500
    finally:
        if source:
            source.unlink(missing_ok=True)
        if corrected:
            corrected.unlink(missing_ok=True)

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=False)
