# Scandalous: scan server

I have an old HP Color Scanner/Printer from 2010 that requires an open relay to e-mail out scans,
and no ISP (that I'm aware of) will provide an open relay these days. For a while, 
I had Postfix (on a 512MB V1 Raspberry Pi) relaying to a Google account using an application specific password, 
which was unreliable and is now shut down by Google. The OS running on the Pi was too old to do OAuth,
and upgrading everything broke interoperability with the scanner.

<img width="193" height="226" alt="printer" src="https://github.com/user-attachments/assets/a1d7f795-6e4b-43ca-91a9-1d915b28fedc" />
<img width="161" height="117" alt="piv1" src="https://github.com/user-attachments/assets/d4d1104a-7512-4310-a699-df8a36704b9b" />    
<img width="292" height="181" alt="piv1" src="https://github.com/user-attachments/assets/caf2f50b-95a9-4488-900c-2023d0665a8b" />
<br>
<br>
Now I'd like to run a very simple SMTP MTA on that same Pi that writes email attachments and serves them up.
Everything will be on my home network so there is no concern about having others access the scans.

Transactions should work something like this:
1. Scanner sends email with attached PDF file to the Pi.
2. SMTP MTA removes attachment, saves it with a timestamp filename.
3. Website serves a listing of the recent files with (thumbnail,) file size and date.
4. Older files are deleted when new files are received.

I have newer models I could use, but the V1 Pi should be fine.
I'll probably give it more storage, currently has only 80MB free.
I assume I'll use `sinatra` to keep the website component minimal. 
The `pdftoimage` gem (which uses `mini_magick`) should work for thumbnails.
The `mail` gem (which uses `mini_mime`) should do what I need for the MTA,
It can handle incoming emails and save attachments.
