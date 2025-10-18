# Reconstruct age configuration

1. Retrieve the secured private key

2. Paste the content in `~/.config/chezmoi/age/key.txt`

3. Generate the public key with : `age-keygen -y ~/.config/chezmoi/age/key.txt`

4. Edit `~/.config/chezmoi/chezmoi.toml` :

```toml
encryption = "age"
[age]
    identity = "<YOUR_HOME>/.config/chezmoi/age/key.txt"
    recipient = "<YOUR_PUBLIC_KEY>"
```
