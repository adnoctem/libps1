<p align="center">
    <!-- PowerShell -->
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/Powershell_256.png">
      <img src="https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/Powershell_256.png" width="225">
    </picture>
    <h1 align="center">libps1</h1>
</p>

A library of open-source [MIT][license]-licensed [PowerShell][powershell] scripts written and maintained by `Ad Noctem Collective` for use with [PowerShell][powershell] Version 6 and above. Refer to Microsoft's in-depth [PowerShell Documentation][powershell_docs] for more information on how these scripts work. Scripts meant for direct execution by the user, an init system or other means of automation are located in the [`scripts`](scripts) directory. The [`lib`](lib) directory contains library scripts meant to be re-used across files or even different repositories with things like [Git Submodules][git_submodules] or _contrib_ scripts like [git_subtree]. You may of course take a look at other repositories of ours for tips on how to achieve re-use.

## ✨ TL;DR

```pwsh
help .\scripts\move-regex.ps1 # Outputs the script documentation
```

### 🔃 Contributing

Contributions are welcome via GitHub's Pull Requests. Fork the repository and implement your changes within the forked
repository, after that you may submit a [Pull Request][gh_pr_fork_docs].

### 📥 Maintainers

This project is owned and maintained by [Ad Noctem Collective](https://github.com/adnoctem) refer to
the [`AUTHORS`](.github/AUTHORS) or [`CODEOWNERS`](.github/CODEOWNERS) for more information. You may also use the linked
contact details to reach out directly.

### ©️ Copyright

_Assets provided by:_ **[Microsoft Corporation][microsoft]**

<!-- File references -->

[license]: LICENSE

<!-- General links -->

[microsoft]: https://www.microsoft.com/

[powershell]: https://github.com/PowerShell/PowerShell

[powershell_docs]: https://learn.microsoft.com/de-de/powershell/

[git_submodules]: https://git-scm.com/book/en/v2/Git-Tools-Submodules

[git_subtree]: https://www.atlassian.com/git/tutorials/git-subtree

[gh_pr_fork_docs]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork
