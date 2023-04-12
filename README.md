<h3 align="center">
  <img alt="pebbleOS" src="logo.svg" height="500">
</h3>

<h4 align="center">
  🪨 Rock solid stability, 🪶 lightweight, 🪟 Windows
</h4>

# ℹ️ About

<img src="icon.svg" height="14" alt="pebbleOS icon"> **pebbleOS** is a [Ameliorated Playbook](https://ameliorated.io/) that modifies your Windows installation to remove _bloatware_, improve your _privacy_, and increase _security_. This is acheived through _component removal_, _group policy_ settings, and _registry_ settings.

pebbleOS is based off of (mostly copied from 😅) the following excellent projects:

- [Atlas](https://github.com/Atlas-OS/Atlas/releases/latest)
- [Revision](https://github.com/meetrevision/playbook/releases/latest)
- [Ameliorated AME11](https://ameliorated.io/#:~:text=AME%2011)

The changes are a combination of the tweaks used in their respective Playbooks, as well as a few personal tweaks. In comparison to Atlas or Revision, pebbleOS doesn't have any system component removal. This will allow you to still use Windows Update without any problems, and will minimize any system breakage you'll come across.

Please check out their projects! They may suit your needs better. You can also visit each project's codebase by visting the [`sources`](./sources/) folder in this repo.

# 🛠️ Installation

Installation is unlike previous methods which often involved creating a bootable USB with an ISO file. Instead, we run Ameliorated's tool on an active Windows installation.

1️. _Recommended_ Clean install the latest Windows 10/11. Using the tool on existing installations may lead to some weirdness.

- _Optionally_ update the installation ISO with [NTLite](https://www.ntlite.com/) or update using Windows Update once installed.

2️. Install your computer's drivers.

3️. Download the required files:

- [AME Wizard from Amerliorated's website](https://ameliorated.io/)

- [The current pebbleOS release](https://github.com/pebble-os/pebble-os/releases/latest)

4️. Import the pebbleOS Playbook in the AME Wizard and run it.
