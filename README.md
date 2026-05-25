# Scandalous: scan server

I have an old HP Color Scanner/Printer from 2010 that requires an open relay to e-mail out scans,
and no ISP (that I'm aware of) will provide an open relay these days. For a while, 
I had Postfix (on a 512MB V1 Raspberry Pi) relaying to a Google account using an application specific password, 
which was unreliable and is now shut down by Google. The OS running on the Pi was too old to do OAuth,
and upgrading everything broke interoperability with the scanner.

<img width="193" height="226" alt="printer" src="https://github.com/user-attachments/assets/a1d7f795-6e4b-43ca-91a9-1d915b28fedc" />
<img width="161" height="117" alt="piv1" src="https://github.com/user-attachments/assets/d4d1104a-7512-4310-a699-df8a36704b9b" /> &nbsp;
<img width="292" height="181" alt="listing" src="https://github.com/user-attachments/assets/5c7a480d-249d-4637-ae91-e07db638f35b" />
<br>
<br>
We run a very simple SMTP MTA on that same Pi that writes email attachments and serves them up.
Everything will be on my home network so there is no concern about having others access the scans.

Transactions should work something like this:
1. Scanner sends email with attached PDF file to the Pi.
2. SMTP MTA removes attachment, saves it with a timestamp filename.
3. Website serves a listing of the recent files with file size and date.
4. Older files are deleted when new files are received.

The V1 Pi with around 80MB free should be fine.
I'll use `sinatra` and `midi-smtp-server` to keep it simple.

## Local file server 

I set up Samba because setting up certs for HTTPS on an internal hosts is a pain. 

<img width="349" height="171" alt="share" src="https://github.com/user-attachments/assets/32a7f3ae-4a4e-4347-9dab-bd7237620e07" />
