"use client";

import { useMemo, useRef, useState } from "react";

type LinkState =
  | { kind: "empty" }
  | { kind: "invalid"; message: string }
  | { kind: "ready"; url: string; host: string; removed: number };

function cleanLink(input: string): LinkState {
  const value = input.trim();
  if (!value) return { kind: "empty" };

  const decoded = value.replaceAll("&amp;", "&").replaceAll("&#38;", "&");
  const markdownTarget = decoded.match(/\]\(\s*(https?:\/\/[\s\S]*?)\s*\)(?:\s|$)/i)?.[1];
  let candidate = markdownTarget ?? decoded;

  const start = candidate.search(/https?:\/\//i);
  if (start < 0) {
    return { kind: "invalid", message: "I can’t find an http or https link in that text." };
  }

  candidate = candidate.slice(start);

  if (!markdownTarget) {
    const hardStop = candidate.search(/[<>"'`]/);
    if (hardStop >= 0) candidate = candidate.slice(0, hardStop);
    candidate = candidate.replace(/[\])},.;:]+\s*$/, "");
  }

  const removed = (candidate.match(/\s/g) ?? []).length;
  candidate = candidate.replace(/\s+/g, "");

  try {
    const parsed = new URL(candidate);
    if (parsed.protocol !== "https:" && parsed.protocol !== "http:") throw new Error();
    return { kind: "ready", url: parsed.toString(), host: parsed.hostname, removed };
  } catch {
    return { kind: "invalid", message: "That still doesn’t look like a complete web link." };
  }
}

export default function Home() {
  const [raw, setRaw] = useState("");
  const [notice, setNotice] = useState("");
  const [dragging, setDragging] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const result = useMemo(() => cleanLink(raw), [raw]);

  function openLink(url: string) {
    window.open(url, "_blank", "noopener,noreferrer");
    setNotice("Opened in a new tab");
  }

  async function pasteAndOpen() {
    setNotice("");
    try {
      const clipboard = await navigator.clipboard.readText();
      setRaw(clipboard);
      const cleaned = cleanLink(clipboard);
      if (cleaned.kind === "ready") openLink(cleaned.url);
      else setNotice(cleaned.kind === "invalid" ? cleaned.message : "Your clipboard is empty.");
    } catch {
      setNotice("Clipboard access was blocked — paste the link into the box instead.");
      textareaRef.current?.focus();
    }
  }

  async function copyFixed() {
    if (result.kind !== "ready") return;
    await navigator.clipboard.writeText(result.url);
    setNotice("Clean link copied");
  }

  function receiveDrop(event: React.DragEvent<HTMLDivElement>) {
    event.preventDefault();
    setDragging(false);
    const text = event.dataTransfer.getData("text/plain") || event.dataTransfer.getData("text/uri-list");
    if (text) setRaw(text);
  }

  return (
    <main>
      <div className="ambient ambient-one" />
      <div className="ambient ambient-two" />

      <section className="shell" aria-labelledby="page-title">
        <header className="intro">
          <div className="eyebrow"><span aria-hidden="true">↗</span> Link first aid</div>
          <h1 id="page-title">Unbreak that<br /><em>login link.</em></h1>
          <p>Claude added line breaks? Copy the whole mess, then let this little tool stitch it back together.</p>
        </header>

        <div className="tool-card">
          <button className="instant-button" onClick={pasteAndOpen} type="button">
            <span className="button-icon" aria-hidden="true">⌘</span>
            <span><strong>Paste &amp; open</strong><small>One click from your clipboard</small></span>
            <span className="arrow" aria-hidden="true">↗</span>
          </button>

          <div className="divider"><span>or paste it here</span></div>

          <div
            className={`drop-zone ${dragging ? "is-dragging" : ""}`}
            onDragEnter={(event) => { event.preventDefault(); setDragging(true); }}
            onDragOver={(event) => event.preventDefault()}
            onDragLeave={() => setDragging(false)}
            onDrop={receiveDrop}
          >
            <label htmlFor="broken-link">Broken link</label>
            <textarea
              ref={textareaRef}
              id="broken-link"
              value={raw}
              onChange={(event) => { setRaw(event.target.value); setNotice(""); }}
              onKeyDown={(event) => {
                if ((event.metaKey || event.ctrlKey) && event.key === "Enter" && result.kind === "ready") {
                  openLink(result.url);
                }
              }}
              placeholder={'Paste the URL — or the whole [Markdown](link)'}
              rows={5}
              spellCheck={false}
              autoCapitalize="off"
              autoCorrect="off"
            />
            {raw && (
              <button className="clear-button" onClick={() => { setRaw(""); setNotice(""); }} type="button" aria-label="Clear link">×</button>
            )}
          </div>

          <div className={`result ${result.kind}`} aria-live="polite">
            {result.kind === "empty" && (
              <><span className="status-dot" /><span>Waiting for a wonderfully broken link…</span></>
            )}
            {result.kind === "invalid" && (
              <><span className="status-mark">!</span><span>{result.message}</span></>
            )}
            {result.kind === "ready" && (
              <>
                <span className="status-mark">✓</span>
                <span className="result-copy"><strong>Ready to open</strong><small>{result.host}{result.removed ? ` · removed ${result.removed} line break${result.removed === 1 ? "" : "s"}/space${result.removed === 1 ? "" : "s"}` : " · link was already clean"}</small></span>
              </>
            )}
          </div>

          <div className="actions">
            <button className="copy-button" onClick={copyFixed} disabled={result.kind !== "ready"} type="button">Copy clean link</button>
            <button className="open-button" onClick={() => result.kind === "ready" && openLink(result.url)} disabled={result.kind !== "ready"} type="button">Fix &amp; open <span aria-hidden="true">↗</span></button>
          </div>

          {notice && <p className="notice" role="status">{notice}</p>}
          <p className="shortcut"><kbd>⌘</kbd><span>+</span><kbd>Enter</kbd> to fix &amp; open</p>
        </div>

        <footer>
          <span className="privacy-icon" aria-hidden="true">◉</span>
          <p><strong>Private by design.</strong> Everything happens in this browser. Nothing is uploaded or stored.</p>
        </footer>
      </section>
    </main>
  );
}
