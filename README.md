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
├── docker/          # docker root
├── apps/            # docker compose services
└── backups/
    ├── pihole/      # teleporter exports
    └── mealie/      # full data snapshots
```

### Services

LAN-only: nothing is exposed to the internet.

| Service   | Ports  | Purpose                        |
| --------- | ------ | ------------------------------ |
| Pi-hole   | 53, 80 | network-wide DNS ad blocking   |
| Mealie    | 9925   | recipe manager                 |
| easyoffer | 8080   | static site pulled from GitHub |

**Scheduled jobs**:

- **hourly** — easyoffer site refresh
- **daily** — backups: Pi-hole Teleporter, Mealie data snapshot (7-day retention), encrypted sync to Google Drive
- **weekly** — Docker image prune

## Fresh start

1. Flash an SD card with Raspberry Pi Imager. In OS customization: enable SSH, set user `kotoyama`, add your public key (`rpi4.pub`), set hostname `rpi4`.
2. On your router, bind a fixed IP to the Pi's `eth0` MAC address via DHCP.
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

5. On the host: `brew install ansible ansible-lint && ansible-galaxy collection install -r requirements.yml`
6. Fill in secrets: `EDITOR=nano ansible-vault edit inventory/group_vars/all/vault.yml`
7. Deploy: `ansible-playbook playbooks/site.yml`

## Example commands

```sh
ansible-playbook playbooks/site.yml                    # apply everything
ansible-playbook playbooks/system.yml                  # base system only
ansible-playbook playbooks/services.yml                # services only
ansible-playbook playbooks/services.yml --tags pihole  # single service
ansible-playbook playbooks/site.yml --check --diff     # dry run with diffs
```
