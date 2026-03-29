<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a id="readme-top"></a>
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->



<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![CC BY-NC-SA 4.0][license-shield]][license-url]



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/pinweichen/mira_the_assistant">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">Mira Assistant Setup</h3>

  <p align="center">
    One-command installer that sets up a Claude Code Executive Assistant with voice, Discord, and Google Calendar integration.
    <br />
    <a href="https://github.com/pinweichen/mira_the_assistant"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/pinweichen/mira_the_assistant/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    &middot;
    <a href="https://github.com/pinweichen/mira_the_assistant/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

Mira Assistant Setup is a one-command installer that configures a personalized AI executive assistant running as a Claude Code session. Run `./setup.sh`, answer a few prompts, and you have a fully operational AI assistant tailored to your name, role, timezone, and preferences.

Features include:

* **Voice transcription** — speech-to-text via whisper-cpp (speak to your assistant instead of typing)
* **Voice replies** — text-to-speech via macOS `say` (zero install) or VibeVoice neural TTS (optional premium, 2.5GB model)
* **Discord messaging integration** — send and receive messages through your assistant via Discord
* **Google Calendar and email access** — via gws plugin for scheduling, event creation, and email
* **Task management and project tracking** — structured workspace with tasks and tracker files
* **macOS launcher app** — double-click a generated `.app` in `~/Applications` to start your session
* **Fully customizable personality and permissions** — edit `CLAUDE.md` to change how your assistant behaves

The installer runs through 9 phases (preflight, system dependencies, Claude plugins, gstack skills, whisper/STT, voice setup, project scaffolding, Discord setup, and launcher creation), checking before acting so it is safe to run multiple times.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With

* Bash
* [Claude Code][claudecode-url]
* [whisper-cpp][whispercpp-url]
* Homebrew
* Node.js
* Bun

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

* macOS (Apple Silicon or Intel)
* [Claude Code CLI](https://claude.ai/code) installed and authenticated
* ~500MB free disk space

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/pinweichen/mira_the_assistant.git
   cd mira_the_assistant
   ```
2. Run the installer
   ```sh
   ./setup.sh
   ```
3. Follow the prompts — the installer will ask for your name, role, timezone, preferred voice, and optional Discord bot token. It handles all dependency installation automatically via Homebrew.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

After installation, start your assistant in one of two ways:

* **Double-click** the generated `.app` bundle in `~/Applications`
* **Run from the terminal:**
  ```sh
  ./start.sh
  ```

Your assistant reads `CLAUDE.md` in the workspace directory for its personality, permissions, and tool access. Edit that file at any time to customize behavior — change the tone, add new capabilities, restrict what it can do, or update your preferences.

To uninstall, run `./uninstall.sh`. The uninstaller prompts before each removal step and never touches system-level packages.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap

- [x] macOS installer (setup.sh)
- [x] Voice setup (macOS say + VibeVoice)
- [x] Discord integration
- [x] Google Calendar/email via gws
- [x] macOS .app launcher
- [x] Conservative uninstaller
- [ ] Windows support (setup.ps1)
- [ ] Linux support
- [ ] Web-based configuration UI

See the [open issues](https://github.com/pinweichen/mira_the_assistant/issues) for a full list of proposed features and known issues.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Top contributors:

<a href="https://github.com/pinweichen/mira_the_assistant/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=pinweichen/mira_the_assistant" alt="contrib.rocks image" />
</a>

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the CC BY-NC-SA 4.0 License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Pin-Wei Chen

Project Link: [https://github.com/pinweichen/mira_the_assistant](https://github.com/pinweichen/mira_the_assistant)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [Claude Code][claudecode-url] — The AI assistant platform
* [whisper-cpp][whispercpp-url] — Speech-to-text engine
* [Best-README-Template](https://github.com/othneildrew/Best-README-Template) — README template

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/pinweichen/mira_the_assistant.svg?style=for-the-badge
[contributors-url]: https://github.com/pinweichen/mira_the_assistant/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/pinweichen/mira_the_assistant.svg?style=for-the-badge
[forks-url]: https://github.com/pinweichen/mira_the_assistant/network/members
[stars-shield]: https://img.shields.io/github/stars/pinweichen/mira_the_assistant.svg?style=for-the-badge
[stars-url]: https://github.com/pinweichen/mira_the_assistant/stargazers
[issues-shield]: https://img.shields.io/github/issues/pinweichen/mira_the_assistant.svg?style=for-the-badge
[issues-url]: https://github.com/pinweichen/mira_the_assistant/issues
[license-shield]: https://img.shields.io/github/license/pinweichen/mira_the_assistant.svg?style=for-the-badge
[license-url]: https://github.com/pinweichen/mira_the_assistant/blob/master/LICENSE.txt
[product-screenshot]: images/screenshot.png
[claudecode-url]: https://claude.ai/code
[whispercpp-url]: https://github.com/ggerganov/whisper.cpp
