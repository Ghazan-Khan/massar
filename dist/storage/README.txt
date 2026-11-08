Massar Services - private storage
=================================

Contents
--------
schema.sql      Table definitions for the contact-message database.
massar.sqlite   Created on the server by setup-db.php or the first contact
                message. Never commit this file: it contains personal data.
secret.key      Random per-installation key used to hash IP addresses.
                Created automatically. Never commit or share it.

Access
------
Apache is denied access to this directory by .htaccess. On other servers add
an equivalent rule, and keep the directory outside the web root when the host
allows it.

Backups
-------
Back up massar.sqlite and secret.key together. Without secret.key the stored
IP hashes cannot be reproduced; the messages themselves remain readable.

Retention
---------
Messages older than the configured retention period (365 days by default) are
deleted automatically when the contact form or the admin page runs.
