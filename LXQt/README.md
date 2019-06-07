Builds LXQt components. Put each tarball here and use the SlackBuild to build it.

See the announcement thread:

https://www.linuxquestions.org/questions/slackware-14/one-slackbuild-for-any-lxqt-component-4175625815/

There's also this follow-up thread:

https://www.linuxquestions.org/questions/slackware-14/building-latest-lxqt-0-14-in-slackware64-current-4175647708/

After it's all installed, do the following before logging into it for the first time.

	mkdir -p ~/.config/lxqt
	cp /usr/share/lxqt/*.conf ~/.config/lxqt

You won't have a panel otherwise.
