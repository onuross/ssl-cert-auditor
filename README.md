# 🛡️ SSL Certificate Expiry Auditor

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-lightgrey?style=flat-square)

A robust, defensively-programmed Bash utility designed to audit SSL/TLS certificate expiration dates for hostnames, IPv4 addresses, and batch files. 

> 🎓 *This project was originally developed as part of the Operating Systems (Betriebssysteme) course at HTW Dresden and has been refactored to comply with modern shell scripting standards (e.g., ShellCheck compliance, defensive Bash execution, and strict error handling).*

## ✨ Features

* **Multi-Input Support:** Accepts single hostnames, exact IPv4 addresses, or batch processing via text files.
* **Defensive Programming:** Implements `set -euo pipefail` to prevent silent failures and unbound variables.
* **OS-Agnostic File Parsing:** Handles Windows CRLF (`\r`) line endings automatically when reading batch files.
* **Target Date Comparison:** Calculates remaining validity relative to the current time or a user-defined future date (`DD-MM-YYYY`).
* **Time-Bound Execution:** Ensures network operations timeout gracefully (under 10s per host) to prevent infinite hanging.

## ⚙️ Prerequisites

* Any UNIX-like environment (Linux, macOS, WSL)
* `bash` (v4.0 or newer recommended)
* `openssl`
* Standard coreutils (`grep`, `cut`, `tr`, `head`, `date`)

## 🚀 Usage Examples

Make the script executable before running:
```bash
chmod +x ssl-cert-auditor.sh

```

**1. Single Hostname**

```bash
./ssl-cert-auditor.sh www.htw-dresden.de

```

**2. Exact IPv4 Address**

```bash
./ssl-cert-auditor.sh 8.8.8.8

```

**3. With a Custom Target Date (DD-MM-YYYY)**
Check if the certificate will still be valid on a specific future date:

```bash
./ssl-cert-auditor.sh example.com 31-12-2025

```

**4. Batch Processing from a File**
Run the script against a provided list of hosts (see `example_hosts.txt` for reference):

```bash
./ssl-cert-auditor.sh example_hosts.txt

```

## 🚦 Exit Codes

| Code | Description |
| --- | --- |
| `0` | **Success** / Execution completed normally. |
| `1` | **Error**: Invalid number of parameters provided. |
| `2` | **Error**: Target date format is incorrect (Must be `DD-MM-YYYY`). |
| `3` | **Error**: Invalid target date provided (e.g., 30-02-2025). |
| `4` | **Error**: Connection failed, no certificate found, or invalid input type. |

## 📝 License

This project is licensed under the MIT License - see the [LICENSE] file for details.
