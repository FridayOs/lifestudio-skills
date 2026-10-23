# LifeStudio examples

`S` is `scripts/lifestudio.sh` in this skill's folder. Ids below are
placeholders. Always take real ids from `list_channels` and `create_post`.

## Cross-post a photo as a draft

```bash
$S call list_channels | jq -r '.data[] | select(.status=="connected") | "\(.id)  \(.platform)  \(.name)"'
URL=$($S upload ./launch.jpg | jq -r .url)
$S call create_post "$(jq -nc --arg url "$URL" '{
  caption: "We just launched 🎉",
  targetAccountIds: ["<facebook page id>", "<instagram id>", "<linkedin id>"],
  mediaUrls: [$url],
  platformOverrides: [{ platform: "LINKEDIN", caption: "We just launched. Here is what changes for teams…" }]
}')" | jq '{id: .data.id, status: .data.status}'
```

Report the draft id and ask whether to publish it.

## Publish an approved draft and report the links

```bash
$S call publish_post '{"postId":"<post id>"}' | jq '.data.status'
$S call get_post '{"postId":"<post id>"}' \
  | jq -r '.data.publishJobs[] | "\(.platform) \(.socialAccountName): \(.status) \(.permalink // .errorHint // .errorMessage // "")"'
```

The status can stay `PUBLISHING` for a short while on video platforms (TikTok,
YouTube, Instagram Reels). Check `get_post` again after about 30 seconds.

## Schedule for tomorrow 9:00 (Asia/Ho_Chi_Minh)

```bash
WHEN=$(TZ=Asia/Ho_Chi_Minh date -d 'tomorrow 09:00' --iso-8601=seconds)
$S call create_post "$(jq -nc --arg when "$WHEN" '{
  caption: "Morning tip: …",
  targetAccountIds: ["<threads id>", "<x id>"],
  scheduledAt: $when
}')" | jq '{id: .data.id, status: .data.status, scheduledAt: .data.scheduledAt}'
```

## Instagram Reel and Facebook Reel from one video

```bash
URL=$($S upload ./clip.mp4 | jq -r .url)
$S call create_post "$(jq -nc --arg url "$URL" '{
  caption: "Behind the scenes",
  targetAccountIds: ["<instagram id>", "<facebook page id>"],
  mediaUrls: [$url],
  platformOverrides: [
    { platform: "INSTAGRAM", contentSurfaces: ["REEL"] },
    { platform: "FACEBOOK",  contentSurfaces: ["REEL"] }
  ]
}')"
```

## YouTube video with a title

```bash
$S call create_post "$(jq -nc --arg url "$URL" '{
  caption: "Full walkthrough of the new dashboard.",
  targetAccountIds: ["<youtube id>"],
  mediaUrls: [$url],
  platformOverrides: [{ platform: "YOUTUBE", title: "New dashboard walkthrough", privacyLevel: "public" }]
}')"
```

## Weekly analytics report

```bash
FROM=$(date -d '7 days ago' +%F); TO=$(date +%F)
IDS=$($S call sync_analytics "{\"from\":\"$FROM\",\"to\":\"$TO\"}" | jq -c '[.data[] | .run.id // empty]')
for i in $(seq 1 20); do
  PENDING=$($S call get_analytics_sync_runs "{\"ids\":$IDS}" | jq '[.data[] | select(.status=="QUEUED" or .status=="RUNNING")] | length')
  [ "$PENDING" = 0 ] && break; sleep 5
done
$S call get_analytics "{\"from\":\"$FROM\",\"to\":\"$TO\"}" > report.json
```

Summarize per channel: followers change, reach or impressions, engagement, and
the top posts. Only use the fields present in the report. Some platforms do not
return every metric.
