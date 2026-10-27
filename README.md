\# SyntaxGuard

\### Syntax Error Detection and Automatic Correction Tool for C Programs



SyntaxGuard is a web-based compiler construction project designed to detect and correct common syntax errors in a supported subset of the C programming language.



The system combines lexical analysis, syntax parsing, error recovery, and rule-based automatic correction through an interactive web interface.



\## Features



\- Detects syntax errors with line and column information

\- Provides descriptive error messages and suggestions

\- Supports multiple-error detection through parser recovery

\- Automatically corrects common syntax mistakes

\- Supports basic C declarations, expressions, functions, arrays, conditional statements, and loops

\- Provides an interactive web interface for code analysis and correction



\## Supported Error Detection



\- Missing and unexpected semicolons

\- Missing or extra parentheses

\- Missing closing brackets and braces

\- Missing expressions and operands

\- Invalid declarations and statements

\- Unexpected tokens

\- Malformed conditional statements and loops



\## Automatic Correction



The Python-based correction module supports common patterns including:



\- Inserting missing semicolons

\- Removing duplicate semicolons

\- Fixing missing or extra closing parentheses

\- Inserting missing closing array brackets

\- Correcting selected `printf()` formatting mistakes

\- Repairing certain malformed `if-else` blocks

\- Inserting missing closing braces in simple cases



Ambiguous errors are reported without automatically guessing the programmer's intention.



\## Technology Stack



| Component | Technology |

|---|---|

| Frontend | React.js, JavaScript, HTML, CSS, Vite |

| Backend API | Python, Flask |

| Lexical Analysis | Flex |

| Syntax Analysis | Bison |

| Automatic Correction | Python, Regular Expressions |

| Compilation | GCC |

| Development Environment | VS Code, MSYS2 UCRT64 |



\## System Architecture



```text

User

&#x20; |

React Frontend

&#x20; |

Flask REST API

&#x20; |

&#x20; +---- Analyze ----> Flex Lexer

&#x20; |                       |

&#x20; |                   Bison Parser

&#x20; |                       |

&#x20; |                   Error Report

&#x20; |

&#x20; +---- Correct ----> Python Rule-Based Corrector

&#x20;                         |

&#x20;                     Corrected Code

&#x20; |

Results displayed in React

```



\## Project Structure



```text

SyntaxGuard/

├── api/

│   ├── app.py

│   └── requirements.txt

├── backend/

│   ├── lexer.l

│   └── parser.y

├── frontend/

│   ├── src/

│   ├── package.json

│   └── vite.config.js

├── corrector.py

├── .gitignore

└── README.md

```



\## Installation and Execution



\### Prerequisites



\- Python 3

\- Node.js and npm

\- Flex

\- Bison

\- GCC

\- MSYS2 UCRT64 (recommended on Windows)



\### 1. Clone the Repository



```bash

git clone https://github.com/Bhumi-Makde/SyntaxGuard.git

cd SyntaxGuard

```



\### 2. Compile the Syntax Analyzer



From the `backend` directory:



```bash

bison -d parser.y

flex lexer.l

gcc parser.tab.c lex.yy.c -o syntaxguard.exe

```



\### 3. Install Python Dependencies



From the project root:



```bash

python -m pip install -r api/requirements.txt

```



\### 4. Start the Flask Backend



```bash

python api/app.py

```



The backend runs at `http://127.0.0.1:5000`.



\### 5. Start the React Frontend



Open a separate terminal:



```bash

cd frontend

npm install

npm run dev

```



Open `http://localhost:5173/` in your browser.



\## How It Works



1\. The user enters C-like source code into the web editor.

2\. Clicking \*\*Analyze\*\* sends the code to the Flask backend.

3\. Flex tokenizes the source code.

4\. Bison validates the token sequence against the defined grammar.

5\. The system displays syntax errors, locations, and suggestions.

6\. Clicking \*\*Correct\*\* invokes the Python correction module.

7\. The user can copy the corrected code into the editor and analyze it again.



\## Limitations



\- Supports a defined subset of C, not the complete C language.

\- Focuses on syntax errors rather than semantic or logical errors.

\- Automatic correction is rule-based and may not handle every malformed program.

\- A valid syntax result does not guarantee successful compilation by a full C compiler.



\## Project Category



\*\*Compiler Construction | Lexical Analysis | Syntax Analysis | Error Recovery | Automatic Code Correction\*\*



\---



Developed as an academic Compiler Construction project.

