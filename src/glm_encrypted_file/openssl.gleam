/// This library is a shell command wrapper around openssl.
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import logging
import shellout

/// openssl shell command args
const openssl_base_command_arguments = [
  "enc",
  "-base64",
  "-aes-256-cbc",
  "-md",
  "sha512",
  "-pbkdf2",
  "-iter",
  "1000000",
]

/// openssl flag to decrypt an encrypted file
const openssl_decrypt_command_arguments = ["-d"]

/// openssl flag to encrypt plaintext
const openssl_encrypt_command_arguments = ["-e", "-salt"]

/// openssl command
const openssl_command = "openssl"

/// openssl password file path
pub type PasswordFilePath =
  String

/// openssl encrypted file path (input or output)
pub type EncryptedFilePath =
  String

/// openssl plaintext file path (input only)
pub type PlaintextFilePath =
  String

/// Error types for this library
pub type EncFileError {
  DecryptEncryptedFileError(List(String))
  EncryptEncryptedFileError(List(String))
}

/// Decrypt an encrypted file to a plaintext string
pub fn decrypt(
  encrypted_file: EncryptedFilePath,
  password_file: PasswordFilePath,
) -> Result(String, EncFileError) {
  let command_arguments =
    [
      openssl_base_command_arguments,
      openssl_decrypt_command_arguments,
      ["-in", encrypted_file, "-pass", "file:" <> password_file],
    ]
    |> list.flatten

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
        <> string.join(command_arguments, " "),
    )
    // pass output back, unchanged
    output
  })
  |> result.map_error(fn(e) {
    let #(a, b) = e
    logging.log(
      logging.Error,
      "openssl decryption failed, shell command arguments: "
        <> openssl_command
        <> " "
        <> string.join(command_arguments, " ")
        <> ", shell command error: "
        <> a |> int.to_string
        <> ", "
        <> b,
    )
    DecryptEncryptedFileError(command_arguments)
  })
}

/// Encrypt a plaintext string to an encrypted file
///
/// See README for details, but in short: you must ensure that both the
/// plaintext file and the password file are secure. Delete the plaintext file
/// once the encrypted file has been created from it.
///
/// TODO: investigate sending plaintext over stdin to openssl shellout process
/// TODO: see https://github.com/tynanbe/shellout/issues/4
pub fn encrypt(
  plaintext_file: PlaintextFilePath,
  encrypted_file: EncryptedFilePath,
  password_file: PasswordFilePath,
) -> Result(Nil, EncFileError) {
  let command_arguments =
    [
      openssl_base_command_arguments,
      openssl_encrypt_command_arguments,
      [
        "-in",
        plaintext_file,
        "-out",
        encrypted_file,
        "-pass",
        "file:" <> password_file,
      ],
    ]
    |> list.flatten

  shellout.command(
    run: openssl_command,
    with: command_arguments,
    in: ".",
    opt: [],
  )
  |> result.map(with: fn(_output) {
    logging.log(
      logging.Debug,
      "shell command succeeded: "
        <> openssl_command
        <> " "
        <> string.join(command_arguments, " "),
    )
    Nil
  })
  |> result.map_error(fn(e) {
    let #(a, b) = e
    logging.log(
      logging.Error,
      "openssl encryption failed, shell command arguments: "
        <> openssl_command
        <> " "
        <> string.join(command_arguments, " ")
        <> ", shell command error: "
        <> a |> int.to_string
        <> ", "
        <> b,
    )
    EncryptEncryptedFileError(command_arguments)
  })
}
