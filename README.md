# Scandalous: scan server

[![Ruby](https://img.shields.io/badge/Ruby-3.1-red.svg)](https://www.ruby-lang.org/)
[![CI](https://github.com/woodie/scandalous/actions/workflows/ci.yml/badge.svg)](https://github.com/woodie/scandalous/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/woodie/scandalous.svg)](https://github.com/woodie/scandalous/releases/latest)
[![License](https://img.shields.io/github/license/woodie/scandalous.svg)](LICENSE)

Have an old Scanner/Printer that requires an open relay to e-mail out scans?
Now you can serve up scanned documents on your home network.

<img width="193" height="226" alt="printer" src="https://github.com/user-attachments/assets/a1d7f795-6e4b-43ca-91a9-1d915b28fedc" />
<img width="161" height="117" alt="piv1" src="https://github.com/user-attachments/assets/d4d1104a-7512-4310-a699-df8a36704b9b" /> &nbsp;
<img width="292" height="181" alt="listing" src="https://github.com/user-attachments/assets/5c7a480d-249d-4637-ae91-e07db638f35b" />
<br>
<br>
We run a very simple SMTP MTA on that same Pi that writes email attachments and serves them up.
Everything will be on my home network so there is no concern about having others access the scans.

Transactions work like this:
1. Scanner sends email with attached PDF file to the Pi.
2. SMTP MTA removes attachment, saves it with a timestamp filename.
3. Website serves a listing of the recent files with file size and date.
4. Older files are deleted when new files are received.

The V1 Pi with around 80MB free should be fine.
I'll use `sinatra` and `midi-smtp-server` to keep it simple.

If you want to use Samba to serve the files see the [lambada project](https://github.com/woodie/lambada).

<img width="368" height="168" alt="more" src="https://github.com/user-attachments/assets/f38661d8-886e-43de-8e18-8e9ee2032afe" />
