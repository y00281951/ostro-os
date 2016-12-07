# Copyright (C) 2016 Intel Corporation
# Released under the MIT license (see COPYING.MIT)

from oeqa.utils.buildproject import BuildProject

class TargetBuildProject(BuildProject):

    def __init__(self, target, uri, foldername=None, dl_dir=None):
        self.target = target
        self.targetdir = "~/"
        BuildProject.__init__(self, uri, foldername, tmpdir="/tmp",
                dl_dir=dl_dir)

    def download_archive(self):
        self._download_archive()

        status, output = self.target.copyTo(self.localarchive, self.targetdir)
        if status:
            raise Exception('Failed to copy archive to target, '
                            'output: %s' % output)

        cmd = 'tar xf %s%s -C %s' % (self.targetdir,
                                     self.archive,
                                     self.targetdir)
        status, output = self.target.run(cmd)
        if status:
            raise Exception('Failed to extract archive, '
                            'output: %s' % output)

        # Change targetdir to project folder
        self.targetdir = self.targetdir + self.fname

    # The timeout parameter of target.run is set to 0
    # to make the ssh command run with no timeout.
    def _run(self, cmd):
        return self.target.run(cmd, 0)[0]
