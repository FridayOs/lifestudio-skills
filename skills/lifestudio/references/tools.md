# LifeStudio tools

<!-- Generated from Sources/api/src/modules/postify/developer-api/developer-tools.ts. Do not edit by hand. -->

Call any tool with `scripts/lifestudio.sh call <tool> '<json arguments>'`. `scripts/lifestudio.sh tools` lists the tools the
current key may call (a key without a scope does not see its tools).

Scopes: `workspace:read`, `channels:read`, `media:write`, `posts:read`, `posts:write`, `posts:publish`, `analytics:read`.

## `get_workspace`

The workspace this API key belongs to: id and name. Every other tool works inside this workspace.

- Scope: `workspace:read` (read-only)
- REST: `GET /v1/workspace`

```json
{
  "type": "object",
  "properties": {},
  "required": [],
  "additionalProperties": false
}
```

## `list_channels`

Social channels connected to the workspace (Facebook Pages, Instagram, Threads, TikTok, YouTube, LinkedIn, X…). Use a channel `id` in create_post.targetAccountIds. Only channels with status "connected" can publish.

- Scope: `channels:read` (read-only)
- REST: `GET /v1/channels`

```json
{
  "type": "object",
  "properties": {},
  "required": [],
  "additionalProperties": false
}
```

## `upload_media`

Upload an image or video (base64, up to about 700 KB through MCP; use the REST multipart endpoint for bigger files). Returns a `url` to pass in create_post.mediaUrls.

- Scope: `media:write`
- REST: none (use `POST /v1/media` multipart for files)

```json
{
  "type": "object",
  "properties": {
    "mimeType": {
      "type": "string",
      "enum": [
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/webp",
        "video/mp4",
        "video/quicktime"
      ]
    },
    "dataBase64": {
      "type": "string",
      "contentEncoding": "base64"
    }
  },
  "required": [
    "mimeType",
    "dataBase64"
  ],
  "additionalProperties": false
}
```

## `list_posts`

Posts of the workspace, newest first, with their per-channel publish jobs.

- Scope: `posts:read` (read-only)
- REST: `GET /v1/posts`

```json
{
  "type": "object",
  "properties": {
    "status": {
      "type": "string",
      "enum": [
        "DRAFT",
        "SCHEDULED",
        "PUBLISHING",
        "PUBLISHED",
        "PARTIALLY_FAILED",
        "FAILED",
        "ARCHIVED"
      ]
    },
    "page": {
      "type": "integer",
      "minimum": 1,
      "default": 1
    },
    "limit": {
      "type": "integer",
      "minimum": 1,
      "maximum": 100,
      "default": 20
    }
  },
  "required": [],
  "additionalProperties": false
}
```

## `get_post`

One post with its publish jobs: status, permalink and error per channel.

- Scope: `posts:read` (read-only)
- REST: `GET /v1/posts/{postId}`

```json
{
  "type": "object",
  "properties": {
    "postId": {
      "type": "string",
      "format": "uuid"
    }
  },
  "required": [
    "postId"
  ],
  "additionalProperties": false
}
```

## `create_post`

Create a post for one or more channels. Saved as a draft unless `publishNow` (publish right away, needs the posts:publish scope) or `scheduledAt` (ISO time in the future) is given; not both. `platformOverrides` sets a per-platform caption, title or surfaces.

- Scope: `posts:write`
- REST: `POST /v1/posts`

```json
{
  "type": "object",
  "properties": {
    "caption": {
      "type": "string",
      "maxLength": 5000
    },
    "targetAccountIds": {
      "type": "array",
      "items": {
        "type": "string",
        "format": "uuid"
      },
      "minItems": 1,
      "description": "Channel ids from list_channels"
    },
    "mediaUrls": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "URLs returned by upload_media"
    },
    "platformOverrides": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "platform": {
            "type": "string",
            "enum": [
              "FACEBOOK",
              "INSTAGRAM",
              "THREADS",
              "X",
              "YOUTUBE",
              "TIKTOK",
              "LINKEDIN"
            ]
          },
          "caption": {
            "type": "string",
            "maxLength": 5000
          },
          "title": {
            "type": "string",
            "maxLength": 200,
            "description": "YouTube title"
          },
          "privacyLevel": {
            "type": "string"
          },
          "mediaUrls": {
            "type": "array",
            "items": {
              "type": "string"
            }
          },
          "contentSurfaces": {
            "type": "array",
            "items": {
              "type": "string",
              "enum": [
                "FEED",
                "REEL",
                "STORY",
                "TEXT",
                "IMAGE",
                "VIDEO",
                "SHORT",
                "MULTI_IMAGE"
              ]
            }
          }
        },
        "required": [
          "platform"
        ]
      }
    },
    "scheduledAt": {
      "type": "string",
      "format": "date-time"
    },
    "publishNow": {
      "type": "boolean"
    }
  },
  "required": [
    "targetAccountIds"
  ],
  "additionalProperties": false
}
```

## `publish_post`

Publish a draft post now to all its channels. Returns the per-channel outcome.

- Scope: `posts:publish`
- REST: `POST /v1/posts/{postId}/publish`

```json
{
  "type": "object",
  "properties": {
    "postId": {
      "type": "string",
      "format": "uuid"
    }
  },
  "required": [
    "postId"
  ],
  "additionalProperties": false
}
```

## `schedule_post`

Schedule a draft post for a future time (ISO 8601).

- Scope: `posts:publish`
- REST: `POST /v1/posts/{postId}/schedule`

```json
{
  "type": "object",
  "properties": {
    "postId": {
      "type": "string",
      "format": "uuid"
    },
    "scheduledAt": {
      "type": "string",
      "format": "date-time"
    }
  },
  "required": [
    "postId",
    "scheduledAt"
  ],
  "additionalProperties": false
}
```

## `get_analytics`

Channel and post metrics for a date range, from the last analytics sync. Call sync_analytics first for fresh numbers.

- Scope: `analytics:read` (read-only)
- REST: `GET /v1/analytics`

```json
{
  "type": "object",
  "properties": {
    "accountId": {
      "type": "string",
      "format": "uuid",
      "description": "One channel; empty = all"
    },
    "from": {
      "type": "string",
      "pattern": "^\\d{4}-\\d{2}-\\d{2}$",
      "description": "YYYY-MM-DD"
    },
    "to": {
      "type": "string",
      "pattern": "^\\d{4}-\\d{2}-\\d{2}$",
      "description": "YYYY-MM-DD"
    }
  },
  "required": [
    "from",
    "to"
  ],
  "additionalProperties": false
}
```

## `sync_analytics`

Ask the platforms for fresh metrics. Returns sync runs; poll get_analytics_sync_runs until they finish.

- Scope: `analytics:read`
- REST: `POST /v1/analytics/sync`

```json
{
  "type": "object",
  "properties": {
    "accountId": {
      "type": "string",
      "format": "uuid"
    },
    "from": {
      "type": "string",
      "pattern": "^\\d{4}-\\d{2}-\\d{2}$",
      "description": "YYYY-MM-DD"
    },
    "to": {
      "type": "string",
      "pattern": "^\\d{4}-\\d{2}-\\d{2}$",
      "description": "YYYY-MM-DD"
    }
  },
  "required": [
    "from",
    "to"
  ],
  "additionalProperties": false
}
```

## `get_analytics_sync_runs`

Status of analytics sync runs started by sync_analytics.

- Scope: `analytics:read` (read-only)
- REST: `GET /v1/analytics/sync-runs`

```json
{
  "type": "object",
  "properties": {
    "ids": {
      "type": "array",
      "items": {
        "type": "string",
        "format": "uuid"
      },
      "minItems": 1,
      "maxItems": 50
    }
  },
  "required": [
    "ids"
  ],
  "additionalProperties": false
}
```
