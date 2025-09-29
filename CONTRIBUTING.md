# Contributing

[fork]: https://github.com/ppc64le/gaplib/fork
[pr]: https://github.com/ppc64le/gaplib/compare
[released]: https://help.github.com/articles/github-terms-of-service/#6-contributions-under-repository-license

Hi there! We are thrilled that you would like to contribute to GAPLIB.
Contributions are always welcome, both reporting issues and submitting pull requests!

## Reporting issues

Please make sure to include any potentially useful information in the issue, so we can pinpoint the issue faster without going back and forth.
If you can attach build logs or a minimal reproducible example, that makes things much easier to debug. 

Also, please include the following information about your environment, so we can help you faster:

- What branch/release tag of GAPLIB are you using?
- What environment are you trying to build it in? LXD? VM? Docker?


## Contributing a change

Contributions to this project are [released][released] to the public under the project's [opensource license](LICENSE).
By contributing to this project you agree to the [Developer Certificate of Origin](https://developercertificate.org/) (DCO).
The DCO was created by the Linux Kernel community and is a simple statement that you, as a contributor, wrote or otherwise have the legal right to contribute those changes.

Contributors must _sign-off_ that they adhere to these requirements by adding a `Signed-off-by` line to all commit messages with an email address that matches the commit author:

```
feat: this is my commit message

Signed-off-by: Random J Developer <random@developer.example.org>
```

Git even has a `-s` command line option to append this automatically to your
commit message:

```
$ git commit -s -m 'This is my commit message'
```

## Submitting a pull request

0. [Fork][fork] and clone the repository
1. Create a new branch: `git checkout -b my-branch-name`
2. Make your change, push to your fork and [submit a pull request][pr]
3. Wait for your pull request to be reviewed and merged.

Here are a few things you can do that will increase the likelihood of your pull request being accepted:

- Keep your change as focused as possible. If there are multiple changes you would like to make that are not dependent upon each other, consider submitting them as separate pull requests.
- Write a [good commit message](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

## Further Reading

- [Developer Certificate of Origin versus Contributor License Agreements](https://julien.ponge.org/blog/developer-certificate-of-origin-versus-contributor-license-agreements/)
- [The most powerful contributor agreement](https://lwn.net/Articles/592503/)
- [How to Contribute to Open Source](https://opensource.guide/how-to-contribute/)
- [Using Pull Requests](https://help.github.com/articles/about-pull-requests/)
- [GitHub Help](https://help.github.com)
