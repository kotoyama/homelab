# homelab

Ansible-managed Raspberry Pi 4 homelab.

## Hardware

- Raspberry Pi 4
- microSD Card
- USB SSD

## Configuration

- **OS**: Raspberry Pi OS Desktop (Legacy)
- **Debian version**: 12 (bookworm)
- **System**: 64-bit

### Disk layout

SSD mounted at `/mnt/data`:

```
/mnt/data/
├── docker/     # docker root
├── apps/       # docker compose services
└── backups/    # snapshots → Google Drive + Koofr
```

### Services

Firewall: the LAN reaches no published service except Pi-hole DNS (port 53). Everything else is Tailscale-only: `http://rpi4:<port>`.

| Service   | Ports     | Visible to | Purpose                        |
| --------- | --------- | ---------- | ------------------------------ |
| SSH       | 22        | tailscale  | host shell                     |
| Pi-hole   | 53        | LAN        | network-wide DNS ad blocking   |
| Pi-hole   | 80        | tailscale  | admin UI                       |
| Forgejo   | 3000, 222 | tailscale  | git hosting + GitHub mirrors   |
| easyoffer | 8080      | tailscale  | static site pulled from GitHub |
| Beszel    | 8090      | tailscale  | monitoring dashboard           |
| Mealie    | 9925      | tailscale  | recipe manager                 |
| kopeika   | loopback  | bot only   | personal finance Telegram bot  |

**Scheduled jobs**:

- **hourly**: easyoffer site refresh, kopeika auto-update
- **daily**: backups (7-day retention), encrypted sync to Google Drive and Koofr
- **weekly**: Docker image prune, Forgejo mirror seeding

**Alerts**: if any systemd service fails, a Telegram message is sent.

## Fresh start

1. Flash an SD card with Raspberry Pi Imager. In OS customization: enable SSH, set user `kotoyama`, add your public key (`rpi4.pub`), set hostname `rpi4`, configure Wi-Fi.
2. On your router, bind a fixed IP to the Pi's `wlan0` MAC address via DHCP.
3. Make sure your host has vault password (`~/.config/rpi/vault-password`) and the SSH private key (`rpi4`).
4. On your Pi, attach the SSD and format it:

   ```sh
   # confirm the SSD shows up as /dev/sda
   lsblk

   # format the disk
   sudo parted -s /dev/sda mklabel gpt

   # create a partition
   sudo parted -s /dev/sda mkpart primary ext4 0% 100%

   # ext4 filesystem
   sudo mkfs.ext4 -L data /dev/sda1
   ```

5. On the host: `brew install ansible ansible-lint && ansible-galaxy collection install -r requirements.yml`.
6. Fill in secrets: `EDITOR=nano ansible-vault edit inventory/group_vars/all/vault.yml`.
7. Deploy over the LAN: `ansible-playbook playbooks/site.yml -e ansible_host=rpi4.local -e ansible_ssh_private_key_file=~/.ssh/rpi4` (a wiped SD does not resolve `rpi4` yet).
8. Log the Pi into Tailscale: `sudo tailscale up`, then disable key expiry for it in the admin console.
9. Deploy over the tailnet: `ansible-playbook playbooks/site.yml`.

## Example commands

```sh
ansible-playbook playbooks/site.yml                    # apply everything
ansible-playbook playbooks/system.yml                  # base system only
ansible-playbook playbooks/services.yml                # services only
ansible-playbook playbooks/services.yml --tags pihole  # single service
ansible-playbook playbooks/site.yml --check --diff     # dry run with diffs
```
