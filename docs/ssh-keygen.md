# SSH Key Generation and Info

Secure Shell Protocol (SSH) allows you to authenticate yourself to a remote repository (let's say GitHub) so you may access and write data when permissions are required.

---

## New Key

The typical procedure is to generate a public/private key pair and save them on the local machine.  Then, add the public key to your account on GitHub, so that when you add your private key (which can be password-protected) to the ssh-agent in a later session, that session gains the permissions associated with your Git account.

### Generate a new SSH key

```bash
> ssh-keygen -t ed25519 -C "email@address.edu"
```

Note that some legacy systems use a 4096-bit RSA token, but the Ed25519 algorithm should be sufficient for most.

### Set SSH key pair 

You can re-locate and rename the file by entering anotherr path, or you can hit `ENTER` to default.

```bash
> Enter file in which to save the key (/home/kwu/.ssh/id_ed25519):
```

By default, this generates files `id_ed25519` (the private key) and `id_ed25519.pub` (the public key) in the hidden folder `/home/kwu/.ssh/`.  To change these, type a new path while replacing `id_ed25519` with the desired key name.

For example, entering `~/.ssh/id_kwu` will generate `id_kwu` and `id_kwu.pub` inside the `.ssh` folder.

### Set a password for the key

```bash
> Enter passphrase (empty for no passphrase): [Type a passphrase]
> Enter same passphrase again: [Type passphrase again]
```

Setting a passphrase requires you to enter that passphrase to add your private key to the ssh-agent for a terminal session.  You can do this with:

```bash
ssh-add /home/kwu/dev/config/.ssh/id_kwu
```

Now, assuming that your Git account has also added the public key, when you interface with a remote repository, the ssh-agent identifies you as your Git account.

### Add public key

To add your public key on GitHub, follow these steps:
1. Login to github.
2. Click on your avatar in the top-right > Settings.
3. Navigate the leftside bar to Access > SSH and GPG keys.
4. Hit 'New SSH key' near the top-right of the new screen.
5. Enter your desired title, which may the same name as the key.
6. Leave 'Key type' to 'Authentication Key'.
7. Enter the contents of your public key (e.g., `id_kwu.pub`) under 'Key'.
8. Hit 'Add SSH key'.

You can copy the contents of your public key by executing `xclip` in a terminal.  For example:

```bash
xclip -sel c < /home/kwu/dev/config/.ssh/id_kwu.pub
```

You can also use `cat` to display the contents and manually copy them.

See more information at https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent.

---

## Using SSH Key

Reoccuring use of an SSH key on new terminals is just a simple matter of adding the private key to the ssh-agent and entering the password, if password-protected.  These steps can also be added to a shell script for easier execution.

Refer to https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=linux#adding-your-ssh-key-to-the-ssh-agent.

### Start ssh-agent

```bash
$ eval "$(ssh-agent -s)"
> Agent pid 59566
```

You should be on Ubuntu or using Git Bash.

### Add private key to ssh-agent

```bash
ssh-add /home/kwu/dev/config/.ssh/id_kwu
```

You may be prompted for the passphrase, after which you should see an "Identity added: ..." response.

### View active keys

```bash
ssh-add -L
```

### Deactive key

```bash
ssh-agent -k
```

Note that there is a manual way to remove a private key, the inverse of adding it, but it can encounter issues.  It is better to just kill the current agent (or exit the terminal) and start a new agent for another private key.