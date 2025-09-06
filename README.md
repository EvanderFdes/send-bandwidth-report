# 📶 OpenWRT Bandwidth Report

A shell script that collects daily per-device bandwidth usage from OpenWRT using `nlbwmon`, maps IPs to static hostnames (if configured), and sends the results to Telegram via a bot.

---

## ✨ Features

- Uses built-in `nlbwmon` data from OpenWRT.
- Matches IPs to static DHCP hostnames.
- Outputs clean device-wise summary.
- Sends the report via Telegram.
- Designed to be run automatically at the end of each day.

---

## 📦 Requirements

Ensure the following packages are installed on your OpenWRT router:

```sh
opkg update
opkg install nlbwmon curl
opkg install jq
```

---

## 🔧 Script Setup

1. **Log in to your OpenWRT router via SSH:**

```sh
ssh root@192.168.1.1
```

2. **Open **``** to create the script:**

```sh
vi /root/send_bandwidth_report.sh
```

3. **In **``**:**

   - Press `i` to enter **insert mode**.
   - Paste the full script (from this repo).
   - Press `Esc`, then type `:wq` and press `Enter` to **save and exit**.

4. **Make the script executable:**

```sh
chmod +x /root/send_bandwidth_report.sh
```

---

## 🕐 Automate with Cron

To run the script automatically at 11:59 PM **daily** :

1. Open the cron config:

```sh
crontab -e
```

2. Add this line:

```cron
59 23 * * * /root/send_bandwidth_telegram.sh
```

> ✅ This clever trick ensures it only runs on the last day of any month.

---

## 💬 Telegram Bot Setup

1. **Create a Telegram bot:**

   - Open Telegram and search for `@BotFather`.
   - Use `/newbot` to create one.
   - Save the token it gives you (e.g., `123456:ABC-DEF1234ghIklzyx57W2v1u123ew11`).

2. **Get your Chat ID:**

   - Start a chat with your bot.
   - Visit: `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates`
   - Look for `"chat":{"id":...}` in the JSON response.

3. **Update your script with:**

   - `TELEGRAM_BOT_TOKEN="<your-bot-token>"`
   - `TELEGRAM_CHAT_ID="<your-chat-id>"`

---

## 📝 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🙌 Contributing

Feel free to fork, modify, and submit PRs! If you improve the sorting logic or add support for dynamic leases, we'd love to hear from you.

---

## 💡 Sample Output

```
📶 Bandwidth Usage - September 06 2025

Device: MSI-Laptop-5Ghz
Download: 82.30 MB
Upload: 95.76 KB
IP: 192.168.1.100

Device: Samsung-phone
Download: 7.01 MB
Upload: 11.11 KB
IP: 192.168.1.101

Device: TPLink-Camera-Indoor
Download: 92.59 KB
Upload: 1.38 KB
IP: 192.168.1.103
...
```

---

## 🔐 Security Note

Your Telegram bot token gives access to send messages. Keep it private. Do **not** share logs or screenshots containing the token.
