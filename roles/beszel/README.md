# Beszel setup

After first deploy, complete setup in the hub UI:

1. Create the admin account.
2. **Add System**: name `rpi4`, host `host.docker.internal`, port `45876`. Copy the shown `KEY=ssh-ed25519 ...` into `beszel_agent_key` and redeploy.
3. Telegram notifications: send `/start` to your bot, then in the hub go to **Settings → Notifications** and add:

   ```sh
   telegram://<BOT_TOKEN>@telegram?chats=<CHAT_ID>
   ```

   Token: `@BotFather` → `/mybots` → API Token. Chat ID: your user id (`@userinfobot`).
   Press **Test** to verify delivery.
