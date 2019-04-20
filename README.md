# Ada Keystore

[![Build Status](https://img.shields.io/jenkins/s/http/jenkins.vacs.fr/Ada-Keystore.svg)](http://jenkins.vacs.fr/job/Ada-Keystore/)
[![License](http://img.shields.io/badge/license-APACHE2-blue.svg)](LICENSE)
![Commits](https://img.shields.io/github/commits-since/stcarrez/ada-keystore/1.0.0.svg)

Ada Keystore is a library and tool to store information in secure wallets
and protect the stored information by encrypting the content.
It is necessary to know one of the wallet password to access its content.
Ada Keystore can be used to safely store passwords, credentials,
bank accounts and even documents.

Wallets are protected by a master key using AES-256 and the wallet
master key is protected by a user password.
The wallet defines up to 8 slots that identify
a password key that is able to unlock the master key.  To open a wallet,
it is necessary to unlock one of these 8 slots by providing the correct
password.  Wallet key slots are protected by the user's password
and the PBKDF2-HMAC-256 algorithm, a random salt, a random counter
and they are encrypted using AES-256.

Values stored in the wallet are protected by their own encryption keys
using AES-256.  A wallet can contain another wallet which is then
protected by its own encryption keys and passwords (with 8 independent slots).
Because the child wallet has its own master key, it is necessary to known
the primary password and the child password to unlock the parent wallet
first and then the child wallet.

The data is organized in blocks of 4K whose primary content is encrypted
either by the wallet master key or by the entry keys.  The data block is
signed by using HMAC-256.  A data block can contain several values but
each of them is protected by its own encryption key.  Each value is also
signed using HMAC-256.

# Building Ada Keystore

To configure Ada Keystore, use the following command:
```
   ./configure
```

The GTK application is not compiled by default unless to configure with
the `--enable-gtk` option.

```
   ./configure  --enable-gtk
```

Then, build the application:
```
   make
```

And install it:
```
   make install
```
