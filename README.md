# Scandalous: scan server

I have an old HP Color Scanner/Printer from 2010 that requires an open relay to e-mail out scans. For a while, 
I had Postfix (on a 512MB Raspberry Pi V1) relaying to a Google account using an application specific password, 
which was unreliable and is now shut down by Google. The OS running on the Pi was too old to do OAuth,
and upgrading everything broke interoperability from the scanner.

<img width="193" height="226" alt="printer" src="https://github.com/user-attachments/assets/a1d7f795-6e4b-43ca-91a9-1d915b28fedc" />
<img width="364" height="200" alt="Raspberry-Pi-1-Model-B" src="https://github.com/user-attachments/assets/b12c3dd3-4ad0-49c8-9008-a1daa97bb59c" />

I'd like to run a very simply SMTP MTA on that same Pi that simply saves email attachments to a folder for each recipient 
and then have a web site that serves up the scans, letting older scan be automatically deleted.
Everything will be on my home network so there is no concern about having people access the scans.

- Scanner sends email with attached PDF file.
- SMTP MTA removes attachment, saves to recipient folder with a timestamp filename
- Website serves a listing of the recent files with thumbnail, file size and date
- Old files are deleting when new files are received
