---
name: lifestudio
description: >
  Publish and manage social media posts through LifeStudio: list the
  workspace's connected channels (Facebook Pages, Instagram, Threads, TikTok,
  YouTube, LinkedIn, X), upload images or videos, create draft, scheduled or
  published posts, check per-channel publish results, and read channel
  analytics. Use when a task asks to post, schedule, cross-post or report on
  social media for a LifeStudio workspace. Don't use for other social tools,
  for connecting new channels or changing LifeStudio billing (those are done by
  a person in the LifeStudio app), or when no LifeStudio API key is available.
---

# LifeStudio

LifeStudio (https://lifestud.io) publishes one post to many social channels.
This skill drives a single LifeStudio **workspace** through its developer API.
The API key decides which workspace, and every call stays inside it.

## Setup (once, by a person)

1. In LifeStudio, open **Workspace settings → API keys & MCP** as the workspace
   owner and create a key. This needs a paid plan. Give the agent only the
   access it needs. For example, leave out **Publish & schedule** when the
   agent should only prepare drafts.
2. Give the key to the agent as `LIFESTUDIO_API_KEY`:
   - **Paperclip:** add a company secret, then bind it to the agent as
     `env.LIFESTUDIO_API_KEY`. An `access.LIFESTUDIO_API_KEY` binding also
     works: the script fetches it on demand.
   - **Elsewhere** (Claude Code, Codex, a shell): export `LIFESTUDIO_API_KEY`.
3. Optional: set `LIFESTUDIO_API_URL` for another deployment. The default is
   `https://api.lifestud.io/postify/developer`.

Requirements: `bash`, `curl`, `jq`.

**Never print, echo, log or paste the key** into comments, issues, files or
commit messages. If someone pastes a key into a task, do not repeat it. In
Paperclip, propose it as a secret instead (see the `paperclip` skill).

## How to call

Run every operation through `scripts/lifestudio.sh`, which lives in this
skill's folder:

```bash
S=<path-to-this-skill>/scripts/lifestudio.sh
$S tools                         # what this key may do
$S schema create_post            # input schema of a tool
$S call list_channels            # call a tool, prints JSON
$S call create_post '{"caption":"Hi","targetAccountIds":["<channel id>"]}'
$S upload ./photo.jpg            # any size, returns {"url": …}
```

The script talks to the LifeStudio MCP endpoint. If your client already has
the LifeStudio MCP server connected (`…/postify/developer/mcp`), you can call
the same tools directly instead. `references/tools.md` lists every tool with
its input schema. `references/examples.md` has complete flows.

## Workflow

1. **Look first.** Run `call get_workspace` and `call list_channels`. Pick
   channels by `platform` and `name`, and use their `id` in `targetAccountIds`.
   Only channels with `status: "connected"` can publish. For
   `reconnect_required`, tell a person to reconnect it in the app. Never guess
   ids.
2. **Media.** Upload a file with `upload <file>`, or with
   `call upload_media` for small base64 images. Pass the returned `url` in
   `mediaUrls`. Instagram, TikTok and YouTube need media. Check `capabilities`
   on the channel.
3. **Create.** `call create_post` saves a **draft** by default. Per-platform
   text, a YouTube title or Facebook/Instagram surfaces (`FEED`, `REEL`,
   `STORY`) go in `platformOverrides`.
4. **Publish or schedule only when the task clearly asks for it.** Use
   `publishNow: true` or `scheduledAt` (ISO 8601, in the future) on
   create_post, or `publish_post` / `schedule_post` on a draft. Publishing is
   public and cannot be undone from here. If the request is ambiguous, stop at
   the draft and ask for confirmation. In Paperclip, use a comment or an
   approval on the issue, and include the draft's id and a short preview.
5. **Verify.** `call get_post '{"postId":"…"}'` shows each channel's
   `status`, `permalink` and `errorMessage` / `errorHint`. Report the
   permalinks. For a failure, report the hint and do not retry blindly.
6. **Analytics.** `call sync_analytics '{"from":"YYYY-MM-DD","to":"YYYY-MM-DD"}'`,
   then poll `call get_analytics_sync_runs '{"ids":[…]}'` every few seconds
   until the runs finish, then `call get_analytics` with the same range.

## Errors

| Error | Meaning | Do |
|---|---|---|
| `401` | Key missing, wrong, revoked or expired | Ask a person for a valid key. Do not retry. |
| `403 … lacks the <scope> scope` | The key may not do this | Report it. A person can create a key with more access. |
| `403 FEATURE_NOT_IN_PLAN` | The workspace's plan has no API access | Report it. Do not retry. |
| `400` | Invalid input; the message names the field | Fix the input using `schema <tool>`. |
| `404` | The id is not in this workspace | Re-list. Do not guess. |
| `429` | 120 requests per minute per key | Wait about a minute, then continue. |

Quotas (posts per month, channels and video length per plan) are enforced by
LifeStudio. A quota error means a person has to act.

## Report back

Say what you did in plain words: the channels, the post id, draft, scheduled
(with the time) or published, and the permalinks or errors per channel. Do not
paste raw JSON unless asked.
