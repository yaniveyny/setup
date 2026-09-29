setup.git
=========
Clone and run this on a new EC2 instance running Ubuntu 12.04.2 LTS to
configure both the machine and your individual development environment as
follows:

```sh
cd $HOME
sudo apt-get install -y git-core
git clone https://github.com/startup-class/setup.git
./setup/setup.sh   
```

See also http://github.com/startup-class/dotfiles and
[Startup Engineering Video Lectures 4a/4b](https://class.coursera.org/startup-001/lecture/index)
for more details.

Creating a new Novelution repository
------------------------------------
`novelution-new-repo.sh` scaffolds a new repository with Novelution's
standard starter files (README, CHANGELOG, .gitignore, .editorconfig, and a
pull request template with a no-client-data checklist) and makes the first
commit on `main`.

```sh
# Preview first; nothing is written
./setup/novelution-new-repo.sh irb-reports-wrapper -m irb -d "IRB reporting wrapper" --dry-run

# Create it locally
./setup/novelution-new-repo.sh irb-reports-wrapper -m irb -d "IRB reporting wrapper"

# Create it locally, then create a private GitHub repo in the org and push
./setup/novelution-new-repo.sh coi-disclosure-api -m coi -o novelution --remote
```

`-m` sets the product area: `proposals`, `awards`, `coi`, `irb`, `iacuc`,
`ibc`, `research-security`, `animal-care`, or `platform` (the default).
`--remote` uses the `gh` CLI when it is installed, otherwise the GitHub API
with a `GITHUB_TOKEN`. Set `NOVELUTION_GITHUB_ORG` to skip passing `-o`
every time. Run with `--help` for all options.





