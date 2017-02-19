# Copyright (C) 2013 - 2016 Intel Corporation
#
# Released under the MIT license (see COPYING.MIT)

# testsdk.bbclass enables testing for SDK and Extensible SDK
#
# To run SDK tests, run the commands:
# $ bitbake <image-name> -c populate_sdk
# $ bitbake <image-name> -c testsdk
#
# To run eSDK tests, run the commands:
# $ bitbake <image-name> -c populate_sdk_ext
# $ bitbake <image-name> -c testsdkext
#
# where "<image-name>" is an image like core-image-sato.

TEST_LOG_DIR ?= "${WORKDIR}/testimage"
TESTSDKLOCK = "${TMPDIR}/testsdk.lock"

def run_test_context(CTestContext, d, testdir, tcname, pn, *args):
    import glob
    import time

    targets = glob.glob(d.expand(testdir + "/tc/environment-setup-*"))
    for sdkenv in targets:
        bb.plain("Testing %s" % sdkenv)
        tc = CTestContext(d, testdir, sdkenv, tcname, args)

        # this is a dummy load of tests
        # we are doing that to find compile errors in the tests themselves
        # before booting the image
        try:
            tc.loadTests()
        except Exception as e:
            import traceback
            bb.fatal("Loading tests failed:\n%s" % traceback.format_exc())

        starttime = time.time()
        result = tc.runTests()
        stoptime = time.time()
        if result.wasSuccessful():
            bb.plain("%s SDK(%s):%s - Ran %d test%s in %.3fs" % (pn, os.path.basename(tcname), os.path.basename(sdkenv),result.testsRun, result.testsRun != 1 and "s" or "", stoptime - starttime))
            msg = "%s - OK - All required tests passed" % pn
            skipped = len(result.skipped)
            if skipped:
                msg += " (skipped=%d)" % skipped
            bb.plain(msg)
        else:
            bb.fatal("%s - FAILED - check the task log and the commands log" % pn)

def testsdk_main(d):
    import os
    import subprocess
    import json
    import logging

    from bb.utils import export_proxies
    from oeqa.core.runner import OEStreamLogger
    from oeqa.sdk.context import OESDKTestContext, OESDKTestContextExecutor
    from oeqa.utils import make_logger_bitbake_compatible

    pn = d.getVar("PN", True)
    logger = make_logger_bitbake_compatible(logging.getLogger("BitBake"))

    # sdk use network for download projects for build
    export_proxies(d)

    test_log_dir = d.getVar("TEST_LOG_DIR", True)

    bb.utils.mkdirhier(test_log_dir)

    tcname = d.expand("${SDK_DEPLOY}/${TOOLCHAIN_OUTPUTNAME}.sh")
    if not os.path.exists(tcname):
        bb.fatal("The toolchain %s is not built. Build it before running the tests: 'bitbake <image> -c populate_sdk' ." % tcname)

    tdname = d.expand("${SDK_DEPLOY}/${TOOLCHAIN_OUTPUTNAME}.testdata.json")
    test_data = json.load(open(tdname, "r"))
    test_data['TEST_LOG_DIR'] = test_log_dir

    target_pkg_manifest = OESDKTestContextExecutor._load_manifest(
        d.expand("${SDK_DEPLOY}/${TOOLCHAIN_OUTPUTNAME}.target.manifest"))
    host_pkg_manifest = OESDKTestContextExecutor._load_manifest(
        d.expand("${SDK_DEPLOY}/${TOOLCHAIN_OUTPUTNAME}.host.manifest"))

    sdk_dir = d.expand("${WORKDIR}/testimage-sdk/")
    bb.utils.remove(sdk_dir, True)
    bb.utils.mkdirhier(sdk_dir)
    try:
        subprocess.check_output("cd %s; %s <<EOF\n./\nY\nEOF" % (sdk_dir, tcname), shell=True)
    except subprocess.CalledProcessError as e:
        bb.fatal("Couldn't install the SDK:\n%s" % e.output.decode("utf-8"))

    fail = False
    sdk_envs = OESDKTestContextExecutor._get_sdk_environs(sdk_dir)
    for s in sdk_envs:
        sdk_env = sdk_envs[s]
        bb.plain("SDK testing environment: %s" % s)
        tc = OESDKTestContext(td=test_data, logger=logger, sdk_dir=sdk_dir,
            sdk_env=sdk_env, target_pkg_manifest=target_pkg_manifest,
            host_pkg_manifest=host_pkg_manifest)

        try:
            tc.loadTests(OESDKTestContextExecutor.default_cases)
        except Exception as e:
            import traceback
            bb.fatal("Loading tests failed:\n%s" % traceback.format_exc())

        result = tc.runTests()

        component = "%s %s" % (pn, OESDKTestContextExecutor.name)
        context_msg = "%s:%s" % (os.path.basename(tcname), os.path.basename(sdk_env))

        tc.logSummary(result, component, context_msg)
        tc.logDetails()

        if not result.wasSuccessful():
            fail = True

    if fail:
        bb.fatal("%s - FAILED - check the task log and the commands log" % pn)
  
testsdk_main[vardepsexclude] =+ "BB_ORIGENV"

python do_testsdk() {
    testsdk_main(d)
}
addtask testsdk
do_testsdk[nostamp] = "1"
do_testsdk[lockfiles] += "${TESTSDKLOCK}"

TEST_LOG_SDKEXT_DIR ?= "${WORKDIR}/testsdkext"
TESTSDKEXTLOCK = "${TMPDIR}/testsdkext.lock"

def testsdkext_main(d):
    import os
    import json
    import subprocess
    import logging

    from bb.utils import export_proxies
    from oeqa.utils import avoid_paths_in_environ

    # extensible sdk use network
    export_proxies(d)

    # extensible sdk can be contaminated if native programs are
    # in PATH, i.e. use perl-native instead of eSDK one.
    paths_to_avoid = [d.getVar('STAGING_DIR'),
                      d.getVar('BASE_WORKDIR')]
    os.environ['PATH'] = avoid_paths_in_environ(paths_to_avoid)

    pn = d.getVar("PN")
    bb.utils.mkdirhier(d.getVar("TEST_LOG_SDKEXT_DIR"))

    tcname = d.expand("${SDK_DEPLOY}/${TOOLCHAINEXT_OUTPUTNAME}.sh")
    if not os.path.exists(tcname):
        bb.fatal("The toolchain ext %s is not built. Build it before running the" \
                 " tests: 'bitbake <image> -c populate_sdk_ext' ." % tcname)

    testdir = d.expand("${WORKDIR}/testsdkext/")
    bb.utils.remove(testdir, True)
    bb.utils.mkdirhier(testdir)
    sdkdir = os.path.join(testdir, 'tc')
    try:
        subprocess.check_output("%s -y -d %s" % (tcname, sdkdir), shell=True)
    except subprocess.CalledProcessError as e:
        msg = "Couldn't install the extensible SDK:\n%s" % e.output.decode("utf-8")
        logfn = os.path.join(sdkdir, 'preparing_build_system.log')
        if os.path.exists(logfn):
            msg += '\n\nContents of preparing_build_system.log:\n'
            with open(logfn, 'r') as f:
                for line in f:
                    msg += line
        bb.fatal(msg)

    try:
        bb.plain("Running SDK Compatibility tests ...")
        run_test_context(SDKExtTestContext, d, testdir, tcname, pn, True)
    finally:
        pass

    try:
        bb.plain("Running Extensible SDK tests ...")
        run_test_context(SDKExtTestContext, d, testdir, tcname, pn)
    finally:
        pass

    bb.utils.remove(testdir, True)

testsdkext_main[vardepsexclude] =+ "BB_ORIGENV"

python do_testsdkext() {
    testsdkext_main(d)
}
addtask testsdkext
do_testsdkext[nostamp] = "1"
do_testsdkext[lockfiles] += "${TESTSDKEXTLOCK}"
