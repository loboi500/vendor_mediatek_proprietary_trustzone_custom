#!/usr/bin/python
#
# Copyright (c) 2022 MediaTek Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

import argparse
import json
import os
import sys
import shutil

reload(sys)
sys.setdefaultencoding('utf8')

# Global variables
PROJECT="k6853v1_64"
FEATURE_OPTIONS_JSON="foc_trustonic_enable.json"
COMPANY="mediateksample"
PLATFORM="mt6853"
ARCH="arm64"
KERNEL="kernel-4.14"
LK=""
TFA=""
VENDOR_PROJECT=""
KERNEL_PROJECT=""
ANDROID_BUILD_TOP="./../../../../../../../.."
DUMP_CFG_FILE=False

HEADER = '\033[95m'
OKBLUE = '\033[94m'
OKGREEN = '\033[92m'
WARNING = '\033[93m'
FAIL = '\033[91m'
ENDC = '\033[0m'
BOLD = "\033[1m"

def infog(msg):
    print OKGREEN + msg + ENDC

def info(msg):
    print OKBLUE + msg + ENDC

def warn(msg):
    print WARNING + msg + ENDC

def err(msg):
    print FAIL + msg + ENDC

def check_export(ConfigFile, Symbols):
	with open(ConfigFile, 'r') as cfgfile:
		for line in cfgfile:
			lineX = line.strip()
			if lineX.startswith("export"):
				print "%s" % line
				for symbol in Symbols:
					if lineX.find(symbol) == -1:
						warn("\tWarning: %s Not Found" % symbol)

def check_options(ConfigFile, Options):
	print ConfigFile
	opts_dict = dict(Options)
	with open(ConfigFile, 'r') as cfgfile:
		for line in cfgfile:
			lineX = line.strip()
			for opt in Options:
				if lineX.startswith(opt) and not lineX.startswith(opt+"_"):
					punctuation = "="
					if lineX.find(":=") != -1:
						punctuation = ":="
					elif lineX.find("?=") != -1:
						punctuation = "?="
					else:
						punctuation = "="
					if Options[opt] == "is not set":
						expected = "#" + opt + " " + Options[opt]
						warn("\tWarning: %s, EXPECTED(%s)" % (line.strip(), expected))
					else:
						actual = lineX[lineX.index('=')+1:].strip()
						expected = Options[opt]
						if actual == expected:
							info("\t%s" % line.strip())
						else:
							warn("\tWarning: %s, EXPECTED(%s)" % (line.strip(), expected))
					try:
						is_opt_found = opts_dict[opt]
					except KeyError:
						pass
					else:
						del opts_dict[opt]
				elif lineX.startswith("#") and lineX.find(opt) != -1 and lineX.find(opt+"_") == -1:
					punctuation = "="
					if lineX.find(":=") != -1:
						punctuation = ":="
					elif lineX.find("?=") != -1:
						punctuation = "?="
					else:
						punctuation = "="
					if Options[opt] == "is not set":
						expected = "#" + opt + " " + Options[opt]
						if lineX.find(Options[opt]) == -1:
							warn("\tWarning: %s, EXPECTED(%s)" % (line.strip(), expected))
						else:
							info("\t%s" % line.strip())
					else:
						expected = opt + punctuation + Options[opt]
						warn("\tWarning: %s, EXPECTED(%s)" % (line.strip(), expected))
					try:
						is_opt_found = opts_dict[opt]
					except KeyError:
						pass
					else:
						del opts_dict[opt]
	if opts_dict:
		for opt in opts_dict:
			warn("\tWarning: %s not set" % opt)

def main():
	with open(FEATURE_OPTIONS_JSON, 'r') as jsonfile:
		fos = json.load(jsonfile)
		if KERNEL.startswith('kernel-4.'):
#			ProjectConfig
			fos["Kernel_4_xx"]["ProjectConfig"]["CONFIG"] = fos["Kernel_4_xx"]["ProjectConfig"]["CONFIG"].replace("${COMPANY}", COMPANY)
			fos["Kernel_4_xx"]["ProjectConfig"]["CONFIG"] = fos["Kernel_4_xx"]["ProjectConfig"]["CONFIG"].replace("${PROJECT}", PROJECT)
#			preloader
			fos["Kernel_4_xx"]["preloader"]["CONFIG"] = fos["Kernel_4_xx"]["preloader"]["CONFIG"].replace("${PROJECT}", PROJECT)
#			trustzone
			fos["Kernel_4_xx"]["trustzone"]["CONFIG"] = fos["Kernel_4_xx"]["trustzone"]["CONFIG"].replace("${PROJECT}", PROJECT)
#			kernel & kernel-debug
			fos["Kernel_4_xx"]["kernel"]["CONFIG"] = fos["Kernel_4_xx"]["kernel"]["CONFIG"].replace("${KERNEL}", KERNEL)
			fos["Kernel_4_xx"]["kernel-debug"]["CONFIG"] = fos["Kernel_4_xx"]["kernel-debug"]["CONFIG"].replace("${KERNEL}", KERNEL)
			fos["Kernel_4_xx"]["kernel"]["CONFIG"] = fos["Kernel_4_xx"]["kernel"]["CONFIG"].replace("${ARCH}", ARCH)
			fos["Kernel_4_xx"]["kernel-debug"]["CONFIG"] = fos["Kernel_4_xx"]["kernel-debug"]["CONFIG"].replace("${ARCH}", ARCH)
			fos["Kernel_4_xx"]["kernel"]["CONFIG"] = fos["Kernel_4_xx"]["kernel"]["CONFIG"].replace("${PROJECT}", PROJECT)
			fos["Kernel_4_xx"]["kernel-debug"]["CONFIG"] = fos["Kernel_4_xx"]["kernel-debug"]["CONFIG"].replace("${PROJECT}", PROJECT)	
#			Just Do It
			MTK_TEE_SUPPORT=fos["Kernel_4_xx"]["ProjectConfig"]["OPTIONS"]["MTK_TEE_SUPPORT"]
			for m in sorted(fos["Kernel_4_xx"]):
				fos["Kernel_4_xx"][m]["CONFIG"] = ANDROID_BUILD_TOP + '/' + fos["Kernel_4_xx"][m]["CONFIG"]
				if os.path.isfile(fos["Kernel_4_xx"][m]["CONFIG"]):
					if DUMP_CFG_FILE == True:
						fpath, fname = os.path.split(fos["Kernel_4_xx"][m]["CONFIG"])
						dstdir = "./dumpcfg_" + PROJECT + "/" + m + "/"
						if m == "kernel-debug" or m == "kernel":
							dstdir = "./dumpcfg_" + PROJECT + "/" + KERNEL + "/"
						if not os.path.exists(dstdir):
							os.makedirs(dstdir)
						shutil.copy(fos["Kernel_4_xx"][m]["CONFIG"], dstdir + fname)
					check_options(fos["Kernel_4_xx"][m]["CONFIG"], fos["Kernel_4_xx"][m]["OPTIONS"])
#					Do something extra and special check
					if m == "preloader" and MTK_TEE_SUPPORT == "yes":
						check_export(fos["Kernel_4_xx"][m]["CONFIG"], fos["Kernel_4_xx"][m]["EXPORT"])
					elif m == "trustzone" and MTK_TEE_SUPPORT == "yes":
						check_options(fos["Kernel_4_xx"][m]["CONFIG"], fos["Kernel_4_xx"][m]["DRAMSIZEOPTIONS"])
				else:
					err("Error: [%s] not exist!" % fos["Kernel_4_xx"][m]["CONFIG"])
		elif KERNEL.startswith('kernel-5.'):
#			ProjectConfig
			fos["Kernel_5_xx"]["ProjectConfig"]["CONFIG"] = fos["Kernel_5_xx"]["ProjectConfig"]["CONFIG"].replace("${COMPANY}", COMPANY)
			fos["Kernel_5_xx"]["ProjectConfig"]["CONFIG"] = fos["Kernel_5_xx"]["ProjectConfig"]["CONFIG"].replace("${PROJECT}", PROJECT)
#			Device-vext
			fos["Kernel_5_xx"]["Device-vext"]["CONFIG"] = fos["Kernel_5_xx"]["Device-vext"]["CONFIG"].replace("${COMPANY}", COMPANY)
			fos["Kernel_5_xx"]["Device-vext"]["CONFIG"] = fos["Kernel_5_xx"]["Device-vext"]["CONFIG"].replace("${PROJECT}", PROJECT)
#			Device
			fos["Kernel_5_xx"]["Device"]["CONFIG"] = fos["Kernel_5_xx"]["Device"]["CONFIG"].replace("${VENDOR_PROJECT}", VENDOR_PROJECT)
#			VendorConfig
			fos["Kernel_5_xx"]["VendorConfig"]["CONFIG"] = fos["Kernel_5_xx"]["VendorConfig"]["CONFIG"].replace("${VENDOR_PROJECT}", VENDOR_PROJECT)
#			kernel
			fos["Kernel_5_xx"]["kernel"]["CONFIG"] = fos["Kernel_5_xx"]["kernel"]["CONFIG"].replace("${KERNEL}", KERNEL)
			fos["Kernel_5_xx"]["kernel"]["CONFIG"] = fos["Kernel_5_xx"]["kernel"]["CONFIG"].replace("${ARCH}", ARCH)
			fos["Kernel_5_xx"]["kernel"]["CONFIG"] = fos["Kernel_5_xx"]["kernel"]["CONFIG"].replace("${KERNEL_PROJECT}", KERNEL_PROJECT)
#			dts
			fos["Kernel_5_xx"]["dts"]["CONFIG"] = fos["Kernel_5_xx"]["dts"]["CONFIG"].replace("${KERNEL}", KERNEL)
			fos["Kernel_5_xx"]["dts"]["CONFIG"] = fos["Kernel_5_xx"]["dts"]["CONFIG"].replace("${ARCH}", ARCH)
			fos["Kernel_5_xx"]["dts"]["CONFIG"] = fos["Kernel_5_xx"]["dts"]["CONFIG"].replace("${PROJECT}", PROJECT)
#			tfa
			fos["Kernel_5_xx"]["tfa"]["CONFIG"] = fos["Kernel_5_xx"]["tfa"]["CONFIG"].replace("${TFA}", TFA)
			fos["Kernel_5_xx"]["tfa"]["CONFIG"] = fos["Kernel_5_xx"]["tfa"]["CONFIG"].replace("${PROJECT}", PROJECT)
#			lk
			fos["Kernel_5_xx"]["lk"]["CONFIG"] = fos["Kernel_5_xx"]["lk"]["CONFIG"].replace("${LK}", LK)
			fos["Kernel_5_xx"]["lk"]["CONFIG"] = fos["Kernel_5_xx"]["lk"]["CONFIG"].replace("${PROJECT}", PROJECT)
#			Just Do It
			MTK_TEE_SUPPORT=fos["Kernel_5_xx"]["ProjectConfig"]["OPTIONS"]["MTK_TEE_SUPPORT"]
			for m in sorted(fos["Kernel_5_xx"]):
				fos["Kernel_5_xx"][m]["CONFIG"] = ANDROID_BUILD_TOP + '/' + fos["Kernel_5_xx"][m]["CONFIG"]
				if os.path.isfile(fos["Kernel_5_xx"][m]["CONFIG"]):
					if m == "tfa" and MTK_TEE_SUPPORT == "no":
						filepath=fos["Kernel_5_xx"][m]["CONFIG"]
						err("Error: MTK_TEE_SUPPORT is [%s], and [%s] should NOT be exist!" %(MTK_TEE_SUPPORT, filepath))
					else:
						if DUMP_CFG_FILE == True:
							fpath, fname = os.path.split(fos["Kernel_5_xx"][m]["CONFIG"])
							dstdir = "./dumpcfg_" + PROJECT + "/" + m + "/"
							if m == "kernel":
								dstdir = "./dumpcfg_" + PROJECT + "/" + KERNEL + "/"
							if not os.path.exists(dstdir):
								os.makedirs(dstdir)
							shutil.copy(fos["Kernel_5_xx"][m]["CONFIG"], dstdir + fname)
						check_options(fos["Kernel_5_xx"][m]["CONFIG"], fos["Kernel_5_xx"][m]["OPTIONS"])
				else:
					if m == "tfa" and MTK_TEE_SUPPORT == "no":
						filepath=fos["Kernel_5_xx"][m]["CONFIG"]
						info("Info: MTK_TEE_SUPPORT is [%s], and it is ok: [%s] not exist." %(MTK_TEE_SUPPORT, filepath))
					else:
						err("Error: [%s] not exist!" % fos["Kernel_5_xx"][m]["CONFIG"])

if __name__ == "__main__":

	parser = argparse.ArgumentParser()
	parser.add_argument("--project", help="MTK Project Name")
	parser.add_argument("--dump", action='store_true', default=False, help="Dump Cfg Files")
	parser.add_argument("feature_options_json", help="MTK Feature Options JSON")
	args = parser.parse_args()
	DUMP_CFG_FILE = args.dump

	devicedir = ANDROID_BUILD_TOP + '/device/'
	vendordir = ANDROID_BUILD_TOP + '/vendor/'
	if (not os.path.isdir(devicedir)) or (not os.path.isdir(vendordir)):
		print "Error: %s only runs in this path: vendor/mediatek/proprietary/trustzone/custom/build/tools/new-tee-feature-scripts/" % sys.argv[0]
	elif args.project and args.feature_options_json:
		PROJECT=args.project
		FEATURE_OPTIONS_JSON = args.feature_options_json
#		Step 1: find out what COMPANY (mediateksample,mediatekprojects...) this project belongs to;
		ProjectPath = os.popen('find '+ANDROID_BUILD_TOP+'/device -maxdepth 3 -type d -name '+PROJECT).readline()
		if ProjectPath == "":
			print "Error: Invalid Project: %s" % PROJECT
			sys.exit()
		COMPANY = ProjectPath.split('/')[10]
#		Step 2: get info from ProjectConfig.mk
		ARCH = "arm64" if PROJECT.find("64") != -1 else "arm"
		ProjectConfigFile = ANDROID_BUILD_TOP + '/device/' + COMPANY + '/' + PROJECT + '/ProjectConfig.mk'
		with open(ProjectConfigFile, 'r') as project_cfg_file:
			for line in project_cfg_file:
				line = line.strip()
				if line.startswith('LINUX_KERNEL_VERSION'):
					KERNEL=line[line.index('=')+1:].strip()
				elif line.startswith('MTK_K64_SUPPORT'):
					MTK_K64_SUPPORT=line[line.index('=')+1:].strip()
					ARCH = "arm64" if MTK_K64_SUPPORT == "yes" else "arm"
				elif line.startswith('MTK_PLATFORM') and not line.startswith('MTK_PLATFORM_'):
					PLATFORM=line[line.index('=')+1:].strip().lower()
				elif line.startswith('MTK_LK_VERSION'):
					LK=line[line.index('=')+1:].strip()
				elif line.startswith('MTK_TFA_VERSION'):
					TFA=line[line.index('=')+1:].strip()
		if KERNEL.startswith('kernel-5.'):
			VndProjectFile = ANDROID_BUILD_TOP + '/device/' + COMPANY + '/' + PROJECT + '/vnd_' + PROJECT + '.mk'
			with open(VndProjectFile, 'r') as vnd_cfg_file:
				for line in vnd_cfg_file:
					line = line.strip()
					if line.startswith('HAL_TARGET_PROJECT') and not line.startswith('HAL_TARGET_PROJECT_'):
						VENDOR_PROJECT=line[line.index('=')+1:].strip()
					elif line.startswith('KRN_TARGET_PROJECT') and not line.startswith('KRN_TARGET_PROJECT_'):
						KERNEL_PROJECT=line[line.index('=')+1:].strip().replace("entry_level_", "")
		print "PROJECT: %s" % PROJECT
		print "FEATURE_OPTIONS_JSON: %s" % FEATURE_OPTIONS_JSON
		print "COMPANY: %s" % COMPANY
		print "PLATFORM: %s" % PLATFORM
		print "ARCH: %s" % ARCH
		print "KERNEL: %s" % KERNEL
		print "LK: %s" % LK
		if KERNEL.startswith('kernel-5.'):
			print "TFA: %s" % TFA
			print "VENDOR_PROJECT: %s" % VENDOR_PROJECT
			print "KERNEL_PROJECT: %s" % KERNEL_PROJECT
		main()
	else:
		print "PROJECT or feature_options_json is empty."
		print "Example: %s --project=k6853v1_64 [--dump] foc_trustonic_enable.json" % sys.argv[0]
