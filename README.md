# MTA NandoCrypt

## Setup

1. Create empty file named `nando_decrypter`
2. Use `start nandoCrypt` to initiate the resource
3. Use `/nandoCrypt` to open the panel

## Use

1. Generate or pick a **secret key** using the panel.
This string of characters will be used to encrypt and decrypt your files.

2. Encrypt a file stored in the server using the panel.
A new file will be created using the prefix defined.

3. Test decryption of that file using the panel.
Enter the file name without the custom extension and it will try to decrypt it using the decrypter file generated (*which can be used both clientside and serverside*).

4. Copy the decrypter file generated to your own unique resource and use it to handle encrypted files in your own way.
Check `nandoCrypt-example` to understand how this can be achieved.
