# BobHub Release Helper

## Objective

This document explains how to use the BobHub release helper.

The release helper is responsible for creating GitHub releases in a controlled and consistent way.

It validates the repository state before publishing a release, helping avoid releases with pending or uncommitted changes.

---

## Script Location

```text
scripts/git/create-release.sh