#!/usr/bin/env python3
from __future__ import annotations
import os, sys, subprocess, getpass, json, multiprocessing, shutil, platform
from distutils.spawn import find_executable

pre_requisites = [
	'git',
	'pip3'
]
verbose = 0

if verbose:
	stdout = sys.stdout
else:
	log_path = '/tmp/frappe-setup/logs/bench.log'
	stdout = open(log_path, 'w')
	print("Logs saved at {}".format(log_path))

def install_prerequisites():
	"""Installs packages in pre_requisites if not installed"""
	for pkg in pre_requisites:
		pkg_path = find_executable(pkg)
		if not pkg_path:
			install_pkg(pkg)

def install_pkg(pkg: str) -> bool:
	pass

def run_os_command(command_map: dict) -> bool:
	"""
	command_map => {'executable': command}
	For ex. {'apt-get': 'sudo apt-get install -y python2.7'}
	"""
	success_code = 1
	for pkg, commands in command_map.items():
		print("Installing", pkg)

		for command in commands:
			returncode = subprocess.run(command, stdout=stdout)
			success_code = success_code and ( returncode == 0 )

	return success_code

def setup():
	print("Setting Up bench")

