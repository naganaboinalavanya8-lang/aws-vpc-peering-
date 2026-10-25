# 10. How to Upload This Project to GitHub

Do this on your own computer. Total time: about 15 minutes. Each of your three projects gets **its own repository**.

## Step 0. Before you upload: safety check

- [ ] No AWS access keys, passwords, `.pem` files or `.tfstate` files in the folder. (The `.gitignore` blocks the usual ones.)
- [ ] No AWS **account ID** in any text file. Search for 12-digit numbers: on Windows use the VS Code search box; on macOS/Linux run `grep -rE "[0-9]{12}" .`
- [ ] Screenshots have account IDs and email addresses blurred.
- [ ] You replaced placeholders only in files that are git-ignored (such as `terraform.tfvars`), not in the example file.

## Step 1. Install the tools (once)

1. **Git:** download from https://git-scm.com/downloads and install with the default options.
2. **A GitHub account:** https://github.com/signup
3. Tell Git who you are (open a terminal; on Windows use *Git Bash*):

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Use the email you added to GitHub, or GitHub's private "noreply" email shown in GitHub → Settings → Emails.

## Step 2. Unzip the project

Unzip the file you downloaded. You will see `ewb-aws-projects/aws-vpc-peering/`. **The repository is the `aws-vpc-peering` folder itself** (not the parent folder).

## Step 3. Create an empty repository on GitHub

1. On github.com click **+** (top right) → **New repository**.
2. **Repository name:** `aws-vpc-peering`.
3. **Description:** "AWS VPC peering with secure access to private instances (design, Terraform, docs)".
4. Choose **Public** (so evaluators can see it) or **Private** (you can share access later).
5. **Do not** tick "Add a README", ".gitignore" or "license". The repo must be empty.
6. Click **Create repository**. Keep the page open; it shows the repository address (like `https://github.com/YOUR-USERNAME/aws-vpc-peering.git`).

## Step 4. Push your files (command line)

Open a terminal **inside the `aws-vpc-peering` folder** (`cd path/to/aws-vpc-peering`), then:

```bash
git init
git add .
git status
```

Read the `git status` list. It must **not** show `*.tfstate`, `*.pem`, `terraform.tfvars` or a `.terraform/` folder. If it does, stop and fix `.gitignore` first.

```bash
git commit -m "Initial commit: VPC peering project"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/aws-vpc-peering.git
git push -u origin main
```

Replace `YOUR-USERNAME`.

**Signing in:** GitHub no longer accepts your account password for `git push`. When asked, either:
- Use **GitHub CLI**: install it from https://cli.github.com, run `gh auth login` and follow the prompts (easiest), **or**
- Create a **Personal Access Token**: GitHub → Settings → Developer settings → Personal access tokens. Give it only the `repo` scope and a short expiry. Paste the token when Git asks for a password. Treat it like a password and never commit it.

## Step 5. Alternative: upload in the browser (no Git)

1. Open your new empty repository.
2. Click **uploading an existing file**.
3. Drag the **contents** of the `aws-vpc-peering` folder into the page (the folders `docs`, `terraform`, etc. and the files).
4. Write a commit message, click **Commit changes**.

Limits: about 100 files per upload, and hidden files such as `.gitignore` may be skipped by the browser. The command line is more reliable.

## Step 6. Add your screenshots later

After you deploy and capture screenshots:

1. Save them in the `screenshots/` folder with the names in `screenshots/CHECKLIST.md`.
2. Run:

```bash
git add screenshots/
git commit -m "Add deployment evidence screenshots"
git push
```

3. In the README's *Screenshots* section, replace the "NOT YET CAPTURED" notes with image links such as `![Peering active](screenshots/05-peering-active.png)`.

## Step 7. Check the result

Open the repository page. Confirm:
- README displays, and the Mermaid diagram renders as a picture. (If it shows an error, copy the diagram text from `diagrams/architecture.mmd` into https://mermaid.live to find the problem.)
- No secrets are visible.
- The folder structure looks as expected.

## Step 8. Submit

Send the repository link to your trainer in the format they request. If you set the repo to private, add them as a collaborator (Settings → Collaborators) or ask them how they want to receive it.

## Common problems

| Problem | Fix |
|---|---|
| `fatal: not a git repository` | You are not inside the project folder. `cd` into `aws-vpc-peering` |
| `remote origin already exists` | `git remote set-url origin https://github.com/YOUR-USERNAME/aws-vpc-peering.git` |
| `Authentication failed` | Use `gh auth login` or a Personal Access Token, not your password |
| `rejected ... fetch first` | You ticked "Add a README" when creating the repo. Run `git pull --rebase origin main`, then `git push` |
| You committed a secret by accident | **Revoke or rotate the secret immediately.** Deleting the file in a later commit does not remove it from history |
