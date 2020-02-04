#!/usr/bin/env python3

'''apport package hook for Ásbrú Connection Manager

Copyright (C) 2020, Ásbrú Project Team <contact@asbru-cm.net>.
Author: Peter J. Mello <admin@petermello.net>
Last-Updated: 2020-02-03
'''

import os
import apport.hookutils

msg = """

The contents of the Ásbrú Connection Manager session log may
help developers diagnose your bug more quickly. However, it
may also contain sensitive information.

Do you want to include the file in your bug report?
(you will be able to review the data before it is sent)

"""


def all_files_under(path):
    """Iterates through all files that are under the given path."""
    for cur_path, dirnames, filenames in os.walk(path):
        for filename in filenames:
            yield os.path.join(cur_path, filename)


def add_info(report, ui):
    session_logs = os.path.join(
        os.environ['XDG_CONFIG_HOME'], 'pac', 'session_logs'
    )
    most_recent_log = max(all_files_under(session_logs), key=os.path.getmtime)

    problem_type = report.get('ProblemType', '')
    attach_files = False
    if problem_type == 'Bug' and ui:
        # Ask for permission to attach the crashed connection's session log
        if apport.hookutils.ui.yesno(msg) is None:
            # User declined to attach the session log
            raise StopIteration
        # User consents to attaching session log.
        attach_files = True

    elif problem_type == 'Crash':
        # crash bugs are private by default
        attach_files = True

    if not attach_files:
        return

    report['CrashDB'] = '{"impl": "launchpad", "project": "asbru-cm"}'
    report['SessionLog'] = apport.hookutils.attach_file_if_exists(
        most_recent_log, overwrite=True
        )
    report['MAC_Events'] = apport.hookutils.attach_mac_events(profiles=None)
    report['Network'] = apport.hookutils.attach_network()
