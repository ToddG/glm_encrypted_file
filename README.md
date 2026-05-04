# glm_encrypted_file

`glm_encrypted_file` is a simple wrapper around openssl for reading and writing encrypted files.
This library exists to provide low throughput access to encrypted files. The use case is as a replacement
for `ansible vault` for CI/CD type automation.


[![Package Version](https://img.shields.io/hexpm/v/glm_encrypted_file)](https://hex.pm/packages/glm_encrypted_file)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glm_encrypted_file/)

## Dependencies
* [gleam](https://gleam.run/)
* [openssl](https://docs.openssl.org/master/)

## Details

### Caveats

1. The author is not a an expert in security, gleam, erlang, or openssl
2. The author cannot guarantee that 'glm_encrypted_file' is appropriate for you and your use case
3. The author has not tested or otherwise characterized this library. The authort has unknown performance characteristics.


### OpenSSL

Using `glm_encrypted_file` is equivalent to running the following openssl commands in a terminal:

Encrypt a string shell command:

    openssl enc -base64 -aes-256-cbc -md sha512 -pbkdf2 -iter 1000000 -e salt -out [ENCRYPTED FILE PATH] -pass file:[PASSWORD FILE PATH]

Decrypt a file shell command:

    openssl enc -base64 -aes-256-cbc -md sha512 -pbkdf2 -iter 1000000 -d -in [ENCRYPTED FILE PATH] -pass file:[PASSWORD FILE PATH]

### Security

1. The passwords stored in the password file ([PASSWORD FILE PATH]) should be secured. This means that the password file should be readable only by the specific user / groups that need to read it. You must set the access permissions on the password file appropriately. For example, this command grants the password file owner read only access:

    chmod 0400 [PASSWORD FILE PATH]

2. You may also want to secure the directory that the password file is stored in:

   chmod 0500 [PASSWORD FILE DIRECTORY PATH]

3. You may also want to secure the encrypted file and the directory it is stored in, as well.

4. When decrypting an encrypted file, the decrypted contents will be passed to stdout. The contents will be passed to the client process (the process invoking this library) via the shellout library. The client process will hold the entire contents of the password file in memory.

5. For convenience, you _may_ want to use one encrypted file with many secrets. Or you may want to use multiple encrypted files, each with a single secret. Provided you use different passwords for each encrypted file, this could provide increased security. You make the call based on your needs and risk profile.

## Example

```sh
gleam add glm_encrypted_file@1
```
```gleam
import logging
import gleeunit
import glm_encrypted_file/encfile
import simplifile

pub fn main() -> Nil {
   // ----------------------------------------------------------------------------------
   // ensure this directory exists
   // ----------------------------------------------------------------------------------
   let assert Ok(_) = simplifile.create_directory_all("./test_data")
   // ensure that only this user can access this directory
   
   // ----------------------------------------------------------------------------------
   // create some file resources
   // ----------------------------------------------------------------------------------
   // plaintext to encrypt
   let plaintext_file = "./test_data/plaintext.txt"
   let assert Ok(_) = simplifile.write(plaintext_file, "sample plaintext")

   // a password to encrypt with
   let password_file = "./test_data/password.txt"
   let assert Ok(_) = simplifile.write(password_file, "password")

   // an encrypted output file
   let encrypted_file = "./test_data/encrypted.enc"

   // ----------------------------------------------------------------------------------
   // encrypt the plaintext
   // ----------------------------------------------------------------------------------
   let assert Ok(_) =
   encfile.encrypt(plaintext_file, encrypted_file, password_file)
   
   // TODO: 1. Copy the encrypted file to it's final storage location.
   
   // TODO: 2. Delete the plaintext file!

   // TODO: 3. Secure (or delete) the password file!

   // ----------------------------------------------------------------------------------
   // decrypt the encrypted file
   // ----------------------------------------------------------------------------------
   let assert Ok(_secret) = encfile.decrypt(encrypted_file, password_file)
}
```

Further documentation can be found at <https://hexdocs.pm/glm_encrypted_file>.

## Development

```sh
gleam test  # Run the tests
```
