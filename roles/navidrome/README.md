# Navidrome setup

## First run

1. Open `http://rpi4:4533` → **Create Admin** (one-time, stored in the DB).
2. Log in from a client: server `http://rpi4:4533`, same credentials.

## Adding music

Drop music into the inbox:

```sh
rsync -av <music folder>/ rpi4:/mnt/data/apps/beets/inbox/
```
