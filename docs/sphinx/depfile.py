# coding=utf-8
#
# QEMU depfile generation extension
#
# Copyright (c) 2020 Red Hat, Inc.
#
# This work is licensed under the terms of the GNU GPLv2 or later.
# See the COPYING file in the top-level directory.

"""depfile is a Sphinx extension that writes a dependency file for
   an external build system"""

import os
import sphinx

__version__ = '1.0'

def get_infiles(env):
    for x in env.found_docs:
        yield env.doc2path(x)
        yield from ((os.path.join(env.srcdir, dep)
                    for dep in env.dependencies[x]))

def write_depfile(app, env):
    if not env.config.depfile:
        return

    with open(env.config.depfile, 'w') as f:
        print(app.outdir + ": \\", file=f)
        print(*get_infiles(env), file=f)
        for x in get_infiles(env):
            print(x + ":", file=f)


def setup(app):
    app.add_config_value('depfile', None, 'env')
    app.connect('env-updated', write_depfile)

    return dict(
        version = __version__,
        parallel_read_safe = True,
        parallel_write_safe = True
    )
