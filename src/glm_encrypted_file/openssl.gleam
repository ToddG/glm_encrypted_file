/// This library is a shell command wrapper around openssl.
import gleam/list
import gleam/result
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

/// Error types for this library
pub type OpenSslError {
  /// OpenSslError is the shellout error passed through. From the shellout docs:
  ///
  ///   '''An Error result wraps a tuple in which the first element is an
  ///   OS error status code and the second is a message about what went wrong
  ///   (or an empty string).'''
  ///
  /// * Int: is the os error status code
  /// * String: message about what went wrong
  OpenSslError(Int, String)
}

/// Decrypt an encrypted file to a plaintext string
pub fn decrypt(
  encrypted_file: String,
  password_file: String,
) -> Result(String, OpenSslError) {
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
  |> result.map_error(fn(e) {
    let #(os_error_int, os_error_string) = e
    OpenSslError(os_error_int, os_error_string)
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
  plaintext_file: String,
  encrypted_file: String,
  password_file: String,
) -> Result(Nil, OpenSslError) {
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
    // Replace output with Nil as the output is not used by the client.
    Nil
  })
  |> result.map_error(fn(e) {
    let #(os_error_int, os_error_string) = e
    OpenSslError(os_error_int, os_error_string)
  })
}
