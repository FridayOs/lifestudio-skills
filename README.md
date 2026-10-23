# LifeStudio skills

Agent Skills for [LifeStudio](https://lifestud.io): let an AI agent publish
and manage social media posts for a LifeStudio workspace. The agent can list
connected channels, upload media, create draft, scheduled or published posts,
check the result per channel, and read analytics.

| Skill | What it does |
|---|---|
| [`lifestudio`](skills/lifestudio/SKILL.md) | Social publishing and analytics through the LifeStudio developer API |

The skills use the standard `SKILL.md` format, so they work in Paperclip,
Claude Code, Codex and other Agent Skills clients.

## Install

**Paperclip:** Skills → **+ New** → **Import from GitHub** (or **Import from
path or URL**), then paste:

```
https://github.com/FridayOs/lifestudio-skills
```

Then add the `lifestudio` skill to an agent (agent → Skills tab).

**skills CLI** (Claude Code, Codex, …):

```bash
npx skills add https://github.com/FridayOs/lifestudio-skills --skill lifestudio
```

**Manual:** copy `skills/lifestudio/` into your agent's skills folder, for
example `~/.claude/skills/lifestudio`.

## API key

1. In LifeStudio, open **Workspace settings → API keys & MCP** as the
   workspace owner (paid plan) and create a key. Grant only the access the
   agent needs.
2. Give the key to the agent as `LIFESTUDIO_API_KEY`:
   - **Paperclip:** create a company secret and bind it to the agent as
     `env.LIFESTUDIO_API_KEY`.
   - **Elsewhere:** `export LIFESTUDIO_API_KEY=lsk_…`
3. Optional: `LIFESTUDIO_API_URL` (default
   `https://api.lifestud.io/postify/developer`).

The skill needs `bash`, `curl` and `jq`.

## MCP instead

Clients with MCP support can also connect directly:

```json
{
  "mcpServers": {
    "lifestudio": {
      "type": "http",
      "url": "https://api.lifestud.io/postify/developer/mcp",
      "headers": { "Authorization": "Bearer lsk_…" }
    }
  }
}
```

## Source

These skills are generated from the LifeStudio codebase. The tool reference is
built from the same definitions that serve the API. Please report issues to
the LifeStudio team rather than editing generated files.
