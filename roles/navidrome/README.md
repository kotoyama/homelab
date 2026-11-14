# Navidrome setup

## First run

1. Open `http://rpi4:4533` → **Create Admin** (one-time, stored in the DB).
2. Log in from a client: server `http://rpi4:4533`, same credentials.

## Adding music

Drop the music into the inbox:

```sh
rsync -av <music folder>/ rpi4:/mnt/data/apps/beets/inbox/
```

Adding tracks to an album that's already imported? Also run this (beets skips re-dropped folders, so the catalog entry must be cleared):

```sh
ssh rpi4 "reimport-beets '<Artist>' '<Album>'"
```

> Use artist/album exactly as stored: case matters for Cyrillic (`"макулатура"` ≠ `"Макулатура"`).
