# Scandalous: scan server

I have an old HP Color Scanner/Printer from 2010 that requires an open relay to e-mail out scans,
and no ISP (that I'm aware of) will provide an open relay these days. For a while, 
I had Postfix (on a 512MB V1 Raspberry Pi) relaying to a Google account using an application specific password, 
which was unreliable and is now shut down by Google. The OS running on the Pi was too old to do OAuth,
and upgrading everything broke interoperability with the scanner.

<img width="193" height="226" alt="printer" src="https://github.com/user-attachments/assets/a1d7f795-6e4b-43ca-91a9-1d915b28fedc" />
<img width="364" height="200" alt="Raspberry-Pi-1-Model-B" src="https://github.com/user-attachments/assets/b12c3dd3-4ad0-49c8-9008-a1daa97bb59c" />

Now I'd like to run a very simple SMTP MTA on that same Pi that writes email attachments and serves them up.
Everything will be on my home network so there is no concern about having others access the scans.

Transactions should work something like this:
1. Scanner sends email with attached PDF file to the Pi.
2. SMTP MTA removes attachment, saves to a `recipient-email` folder with a timestamp filename.
3. Website main page shows a list of recipients (with a gravatar icon).
4. Website serves a listing of the recent files with thumbnail, file size and date.
5. Older files are deleted when new files are received.

I have newer models I could use, but the V1 Pi should be fine.
I'll probably give it more storage, currently has only 80MB free.
I assume I'll use `sinatra` to keep the website component minimal. 
The `pdftoimage` gem (which uses `mini_magick`) should work for thumbnails.
The `mail` gem (which uses `mini_mime`) should do what I need for the MTA,
It can handle incoming emails and save attachments.

```
/                              /john.doe@gmail.com/
•-----------------------•     •--------------------------------•
| 👩 jane.doe@gmail.com |     | 🖼 1.2MB  Today at 11:43AM      |
| 👩 jill.doe@gmail.com |     | 🖼 300kB  May 3, 2026 at 2:13PM |
| 👨 john.doe@gmail.com |  -> | 🖼 2.0MB  May 1, 2026 at 3:55P  |
•-----------------------•     •--------------------------------•
```


