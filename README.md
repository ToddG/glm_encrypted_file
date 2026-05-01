# glm_encrypted_file

This is a simple wrapper around openssl for reading and writing encrypted files.

[![Package Version](https://img.shields.io/hexpm/v/glm_encrypted_file)](https://hex.pm/packages/glm_encrypted_file)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glm_encrypted_file/)

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

  // ----------------------------------------------------------------------------------
  // create some file resources
  // ----------------------------------------------------------------------------------
  // note that the file resources are typed as one of [encrypted, plaintext, password]

  // plaintext to encrypt
  let plaintext_file = encfile.new_plaintext_file("./test_data/plaintext.txt")
  let assert Ok(_) = simplifile.write(plaintext_file.path, "sample plaintext")

  // a password to encrypt with
  let password_file = encfile.new_password_file("./test_data/password.txt")
  let assert Ok(_) = simplifile.write(password_file.path, "password")

  // an encrypted output file
  let encrypted_file = encfile.new_encrypted_file("./test_data/encrypted.enc")

  // ----------------------------------------------------------------------------------
  // encrypt the plaintext
  // ----------------------------------------------------------------------------------
  let assert Ok(_) = encfile.encrypt(plaintext_file, encrypted_file, password_file)

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
./test.sh   # Run the CLI tests
```

## Dependencies

* [gleam](https://gleam.run/)
* [openssl](https://docs.openssl.org/master/)
