---
name: intelligence-janitor
description: "Localized protocol for distilling raw workspace data into personal DNA and intelligence updates."
triggers: ["run janitor", "summarize workspace", "update dna"]
phase: 1-analysis
model_hint: gemini-3-flash
version: 1.0
status: active
---

# 🧹 INTELLIGENCE JANITOR PROTOCOL (V1.0)

This protocol governs the **Recursive Intelligence Loop** within the Sovereign Workspace.

## 📋 PHASE 1: DATA HARVEST
- Target folder: `C:\Users\user\Desktop\workspace\raw/`
- Scan for: Chat logs (.txt, .md), legacy documents, task outputs, and "Thinking Fragment" logs.

## 📋 PHASE 2: SEMANTIC DISTILLATION
1. **Pattern Extraction**: Identify recurring logic, strategic preferences (e.g., "Velocity vs. Perfection"), and tactical jargon.
2. **Preference Mapping**: Capture explicit "USER likes X" or "USER hates Y" signals.
3. **Wisdom Cleanup**: Deduplicate information and remove noise from raw logs.

## 📋 PHASE 3: DNA SYNCHRONIZATION
1. Update `skills_bridge/user_lexicon.yaml` with new vocabulary.
2. Update `skills_bridge/prompt_dna_v2.yaml` with refined behavioral alignment.
3. Log the update in the global `evolving_knowledge.md` under **Recursive Intelligence**.

---
*Command Trigger: "ai run local janitor" or "ai summarize raw workspace"*
