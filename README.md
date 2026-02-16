<div align="center">
  <img src="./kraftklammer/Resources/logo.png" width="400">
</div>

<br>

![CI](https://github.com/Clipy/Clipy/workflows/CI/badge.svg)
[![Release version](https://img.shields.io/github/release/Clipy/Clipy.svg)](https://github.com/Clipy/Clipy/releases/latest)
[![OpenCollective](https://opencollective.com/clipy/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/clipy/sponsors/badge.svg)](#sponsors)

The clipboard mananger ``kraftklammer`` (German for "power paper clip") is based on a fork of [clipboard-manager](https://github.com/nardellil/clipboard-managery) originally created by [Luca Nardelli](https://github.com/nardellil) and released under a [MIT license](https://github.com/nardellil/clipboard-manager/blob/main/LICENSE). To acknowledge his work, ``kraftklammer``uses the [MIT license](./LICENSE) as well.

## tl;dr

Forward to the year 2026: as the author of these lines always used the straight-forward approach and simple clipboard manager [Clipy](https://github.com/Clipy/Clipy) that has been abandoned somewhen in the years 2020/21. As all software will break over time because OS interfaces or requirements change, the author always expected the original Clipy to stop working as it has some dependencies that rely on functions that have been declared deprecated by Apple. Furthermore, Clipy is not available as a native Apple Silicon app. 

Clipy's build process relies on the programming language Ruby and a lot of libraries. Although the author could build the original software by patching some files and adjusting the Ruby-based configuration (see below).

After examining Clipy's source code it became obvious that it was not worth the effort to port the original software to a more modern macOS environment.

Hence, after some research a viable alternative for building a clipboard manager that fits the author's requirements was discovered: [clipboard-manager](https://github.com/nardellil/clipboard-managery). This project relies on Swift alone and is therefore a much better option for building some knowledge about Swift without getting distracted by a lot of libraries as it would have been the case with Clipy. 

As a result, ``kraftklammer`` was born.

The main development goal of the project is to provide a maintained simple clipboard manager that will be extended with some features that will become handy for power users in particular (see below).
 

### Building ``kraftklammer``

__TODO__

## Requirements 

* __TODO__

### Prerequisites

__TODO__

### Project Building

__TODO__

## Vision for ``kraftklammer``

* support for dark mode ✔︎
* native build for Apple Silicon ✔︎
* support Wake-on-LAN calls
* support for direct calls of user-specific shell scripts, e.g. for shutting down remote servers

## License
``kraftklammer`` is available under the MIT license. See the [LICENSE](./LICENSE) file for more information.
