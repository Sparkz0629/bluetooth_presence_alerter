#!/bin/bash

#	This is used so that the device list and token file dont get overwritten when doing a git pull

git stash
git pull
git stash pop
