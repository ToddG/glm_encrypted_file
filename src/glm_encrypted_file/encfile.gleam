import gleam/result
import gleam/string
import logging
import shellout

/// encrypted file library that is a wrapper around shell commands to openssl
const openssl_decrypt_command_arguments = "enc -base64 -aes-256-cbc -md sha512 -pbkdf2 -iter 1000000 -d "

const openssl_encrypt_command_arguments = "enc -base64 -aes-256-cbc -md sha512 -pbkdf2 -iter 1000000 -e -salt "

const openssl_command = "openssl"

pub type Directory{
  Directory(path: String)
}

pub type PlaintextFile{
  PlaintextFile(path: String)
}

pub type PasswordFile{
  PasswordFile(path: String)
}

pub type EncryptedFile{
  EncryptedFile(path: String)
}

pub fn new_directory(d: String) -> Directory {
  Directory(d)
}

pub fn new_plaintext_file(f: String) -> PlaintextFile {
  PlaintextFile(f)
}

pub fn new_encrypted_file(f: String) -> EncryptedFile {
  EncryptedFile(f)
}

pub fn new_password_file(f: String) -> PasswordFile {
  PasswordFile(f)
}

pub type EncFileError {
  EncFileError
  DecryptEncryptedFileError(List(String), #(Int, String))
}

pub fn decrypt(
  encrypted_file: EncryptedFile,
  password_file: PasswordFile,
) -> Result(String, EncFileError) {
  let command_arguments =
    {
      openssl_decrypt_command_arguments
      <> " -in "
      <> encrypted_file.path
      <> " -pass file:"
      <> password_file.path
    }
    |> string.split(" ")

  shellout.command(
    run: openssl_command,
    with: command_arguments,
    in: ".",
    opt: [],
  )
  |> result.map(with: fn(output) {
    logging.log(
      logging.Debug,
      "shell command succeeded: "
        <> openssl_command
        <> " "
        <> string.inspect(command_arguments),
    )
    // pass output back, unchanged
    output
  })
  |> result.map_error(DecryptEncryptedFileError(command_arguments, _))
}

pub fn encrypt(
  plaintext_file: PlaintextFile,
  encrypted_file: EncryptedFile,
  password_file: PasswordFile,
) -> Result(Nil, EncFileError) {
  let command_arguments =
    {
      openssl_encrypt_command_arguments
      <> " -in "
      <> plaintext_file.path
      <> " -out "
      <> encrypted_file.path
      <> " -pass file:"
      <> password_file.path
    }
    |> string.split(" ")

  shellout.command(
    run: openssl_command,
    with: command_arguments,
    in: ".",
    opt: [],
  )
  |> result.map(with: fn(output) {
    logging.log(
      logging.Debug,
      "shell command succeeded: "
        <> openssl_command
        <> " "
        <> string.inspect(command_arguments)
        <> "; output="
        <> output
    )
    Nil
  })
  |> result.map_error(DecryptEncryptedFileError(command_arguments, _))
}
