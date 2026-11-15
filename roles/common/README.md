# Common

## SSH client setup

Requires [Tailscale](https://tailscale.com/download) on the client: ssh is reachable only via the tailnet, `rpi4` resolves via MagicDNS.

### macOS

```sh
ssh-keygen -f ~/.ssh/rpi4
```

`~/.ssh/config`:

```
Host rpi4
  User kotoyama
  IdentityFile ~/.ssh/rpi4
```

### Windows

```powershell
mkdir -Force $env:USERPROFILE\.ssh
ssh-keygen -f $env:USERPROFILE\.ssh\rpi4
```

`C:\Users\<user>\.ssh\config`:

```
Host rpi4
  User kotoyama
  IdentityFile ~/.ssh/rpi4
```

Then add the public key to `roles/common/files/authorized_keys` and run `ansible-playbook playbooks/site.yml --tags common`.
