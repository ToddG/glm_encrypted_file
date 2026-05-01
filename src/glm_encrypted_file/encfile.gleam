import gleam/list
import gleam/result
import gleam/string
import logging
import shellout

/// encrypted file library that is a wrapper around shell commands to openssl
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

const openssl_decrypt_command_arguments = ["-d"]

const openssl_encrypt_command_arguments = ["-e", "-salt"]

const openssl_command = "openssl"

/// A file containing plaintext
pub type PlaintextFile {
  PlaintextFile(path: String)
}

/// A file containing a password
pub type PasswordFile {
  PasswordFile(path: String)
}

/// A file containing encrpted content
pub type EncryptedFile {
  EncryptedFile(path: String)
}

/// Construct a plaintext file
pub fn new_plaintext_file(f: String) -> PlaintextFile {
  PlaintextFile(f)
}

/// Construct an encrypted file
pub fn new_encrypted_file(f: String) -> EncryptedFile {
  EncryptedFile(f)
}

/// Construct a password file
pub fn new_password_file(f: String) -> PasswordFile {
  PasswordFile(f)
}

/// Error types for this library
pub type EncFileError {
  DecryptEncryptedFileError(List(String), #(Int, String))
  EncryptEncryptedFileError(List(String), #(Int, String))
}

/// Decrypt an encrypted file
pub fn decrypt(
  encrypted_file: EncryptedFile,
  password_file: PasswordFile,
) -> Result(String, EncFileError) {
  let command_arguments =
    [
      openssl_base_command_arguments,
      openssl_decrypt_command_arguments,
      ["-in", encrypted_file.path, "-pass", "file:" <> password_file.path],
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
        <> string.inspect(command_arguments),
    )
    // pass output back, unchanged
    output
  })
  |> result.map_error(DecryptEncryptedFileError(command_arguments, _))
}

/// Encrypt a plaintext file
pub fn encrypt(
  plaintext_file: PlaintextFile,
  encrypted_file: EncryptedFile,
  password_file: PasswordFile,
) -> Result(Nil, EncFileError) {
  let command_arguments =
    [
      openssl_base_command_arguments,
      openssl_encrypt_command_arguments,
      [
        "-in",
        plaintext_file.path,
        "-out",
        encrypted_file.path,
        "-pass",
        "file:" <> password_file.path,
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
        <> string.inspect(command_arguments),
    )
    Nil
  })
  |> result.map_error(EncryptEncryptedFileError(command_arguments, _))
}
