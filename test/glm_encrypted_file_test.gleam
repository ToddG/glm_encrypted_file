import gleam/result
import gleam/string
import gleeunit
import glm_encrypted_file/openssl
import simplifile
import temporary

pub fn main() -> Nil {
  gleeunit.main()
}

pub const sample_plaintext = "THIS IS SOME SAMPLE PLAINTEXT THAT WILL BE ENCRYPTED 111111112222222223333333344444444"

pub const sample_password = "SAMPLE_PASSWORD"

pub fn encrypt_test() {
  // 1. create file resources
  //
  use plaintext_file <- temporary.create(temporary.file())
  use _ <- result.try(simplifile.write(plaintext_file, sample_plaintext))

  use password_file <- temporary.create(temporary.file())
  use _ <- result.try(simplifile.write(password_file, sample_password))

  use encrypted_file <- temporary.create(temporary.file())

  // 2. encrypt the plaintext file
  let assert Ok(value) =
    openssl.encrypt(plaintext_file, encrypted_file, password_file)
  let _ = value

  // 3. verify the encrypted file is not equal to the plaintext file
  let assert Ok(value) = simplifile.read(plaintext_file)
  let read_plaintext = value
  let assert Ok(value) = simplifile.read(encrypted_file)
  let read_encrypted = value
  let _ = {
    assert read_plaintext == sample_plaintext
  }
  let _ = {
    assert read_encrypted != read_plaintext
  }

  // 4. decrypt the encrypted file and verify decrypted plaintext equals original plaintext
  let assert Ok(value) = openssl.decrypt(encrypted_file, password_file)
  assert value == sample_plaintext
}

pub fn encrypt_missing_plaintext_file_test() {
  use password_file <- temporary.create(temporary.file())
  use _ <- result.try(simplifile.write(password_file, sample_password))

  use encrypted_file <- temporary.create(temporary.file())

  // ----------------------------------------------------------------------------------------------------
  // ERROR
  // ----------------------------------------------------------------------------------------------------
  //  value: Error(OpenSslError(1, "Can't open \"/this/plaintext/file/does/not/exist\" for reading, No such file or directory\n8020F56BC77D0000:error:80000002:system library:BIO_new_file:No such file or directory:crypto/bio/bss_file.c:67:calling fopen(/this/plaintext/file/does/not/exist, rb)\n8020F56BC77D0000:error:10000080:BIO routines:BIO_new_file:no such file:crypto/bio/bss_file.c:75:\n"))

  let assert Error(openssl.OpenSslError(1, b)) =
    openssl.encrypt(
      "/this/plaintext/file/does/not/exist",
      encrypted_file,
      password_file,
    )
  let assert True = string.contains(b, "No such file or directory")
}

pub fn encrypt_missing_password_file_test() {
  use plaintext_file <- temporary.create(temporary.file())
  use _ <- result.try(simplifile.write(plaintext_file, sample_plaintext))

  use encrypted_file <- temporary.create(temporary.file())

  // ERROR
  // value: Error(OpenSslError(1, "Can't open file /this/password/file/does/not/exist\nError getting password\n8050FE80E27C0000:error:80000002:system library:BIO_new_file:No such file or directory:crypto/bio/bss_file.c:67:calling fopen(/this/password/file/does/not/exist, r)\n8050FE80E27C0000:error:10000080:BIO routines:BIO_new_file:no such file:crypto/bio/bss_file.c:75:\n"))
  // info: Pattern match failed, no pattern matched the value.

  let assert Error(openssl.OpenSslError(1, b)) =
    openssl.encrypt(
      plaintext_file,
      encrypted_file,
      "/this/password/file/does/not/exist",
    )
  let assert True = string.contains(b, "No such file or directory")
}

pub fn encrypt_empty_password_file_test() {
  use plaintext_file <- temporary.create(temporary.file())
  use _ <- result.try(simplifile.write(plaintext_file, sample_plaintext))

  use password_file <- temporary.create(temporary.file())
  use _ <- result.try(simplifile.write(password_file, ""))

  use encrypted_file <- temporary.create(temporary.file())

  // ERROR
  //  code: let assert Ok(value) =
  //  openssl.encrypt(plaintext_file, encrypted_file, password_file)
  //  value: Error(OpenSslError(1, "Error reading password from BIO\nError getting password\n"))
  //  info: Pattern match failed, no pattern matched the value.

  let assert Error(openssl.OpenSslError(1, b)) =
    openssl.encrypt(plaintext_file, encrypted_file, password_file)
  let assert True =
    string.contains(
      b,
      "Error reading password from BIO\nError getting password\n",
    )
}

pub fn decrypt_missing_encrypted_file_test() {
  use plaintext_file <- temporary.create(temporary.file())
  use _ <- result.try(simplifile.write(plaintext_file, sample_plaintext))

  use password_file <- temporary.create(temporary.file())
  use _ <- result.try(simplifile.write(password_file, sample_password))

  use encrypted_file <- temporary.create(temporary.file())

  let assert Ok(value) =
    openssl.encrypt(plaintext_file, encrypted_file, password_file)
  let _ = value

  let assert Ok(value) = simplifile.read(plaintext_file)
  let read_plaintext = value
  let assert Ok(value) = simplifile.read(encrypted_file)
  let read_encrypted = value
  let _ = {
    assert read_plaintext == sample_plaintext
  }
  let _ = {
    assert read_encrypted != read_plaintext
  }

  // ERROR
  //  test: glm_encrypted_file_test.decrypt_missing_encrypted_file_test
  //  code: let assert Ok(value) = openssl.decrypt(encrypted_file, "/missing/password/file")
  //  value: Error(OpenSslError(1, "Can't open file /missing/password/file\nError getting password\n80C0DAB0277A0000:error:80000002:system library:BIO_new_file:No such file or directory:crypto/bio/bss_file.c:67:calling fopen(/missing/password/file, r)\n80C0DAB0277A0000:error:10000080:BIO routines:BIO_new_file:no such file:crypto/bio/bss_file.c:75:\n"))
  //  info: Pattern match failed, no pattern matched the value.
  let assert Error(openssl.OpenSslError(1, b)) =
    openssl.decrypt(encrypted_file, "/missing/password/file")
  let assert True = string.contains(b, "Can't open file /missing/password/file")
}

pub fn decrypt_missing_password_file_test() {
  use plaintext_file <- temporary.create(temporary.file())
  use _ <- result.try(simplifile.write(plaintext_file, sample_plaintext))

  use password_file <- temporary.create(temporary.file())
  use _ <- result.try(simplifile.write(password_file, sample_password))

  use encrypted_file <- temporary.create(temporary.file())

  let assert Ok(_) =
    openssl.encrypt(plaintext_file, encrypted_file, password_file)

  let assert Ok(value) = simplifile.read(plaintext_file)
  let read_plaintext = value
  let assert Ok(value) = simplifile.read(encrypted_file)
  let read_encrypted = value
  let _ = {
    assert read_plaintext == sample_plaintext
  }
  let _ = {
    assert read_encrypted != read_plaintext
  }

  // delete the password file
  use _ <- result.try(
    simplifile.delete_file(password_file)
    |> result.map_error(fn(_) { openssl.OpenSslError(-1, "TESTING") }),
  )

  // ERROR
  //  test: glm_encrypted_file_test.decrypt_missing_password_file_test
  //  code: let assert Ok(value) = openssl.decrypt(encrypted_file, password_file)
  //  value: Error(OpenSslError(1, "Can't open file /tmp/EDCD891DBAECE4B4AF46CB499325B05A\nError getting password\n8020624CAE7B0000:error:80000002:system library:BIO_new_file:No such file or directory:crypto/bio/bss_file.c:67:calling fopen(/tmp/EDCD891DBAECE4B4AF46CB499325B05A, r)\n8020624CAE7B0000:error:10000080:BIO routines:BIO_new_file:no such file:crypto/bio/bss_file.c:75:\n"))
  //  info: Pattern match failed, no pattern matched the value.

  let assert Error(openssl.OpenSslError(1, b)) =
    openssl.decrypt(encrypted_file, password_file)
  let assert True = string.contains(b, "Can't open file")
  Ok(Nil)
}

pub fn decrypt_incorrect_password_test() {
  use plaintext_file <- temporary.create(temporary.file())
  use _ <- result.try(simplifile.write(plaintext_file, sample_plaintext))

  use password_file <- temporary.create(temporary.file())
  use _ <- result.try(simplifile.write(password_file, sample_password))

  use encrypted_file <- temporary.create(temporary.file())

  let assert Ok(value) =
    openssl.encrypt(plaintext_file, encrypted_file, password_file)
  let _ = value

  let assert Ok(value) = simplifile.read(plaintext_file)
  let read_plaintext = value
  let assert Ok(value) = simplifile.read(encrypted_file)
  let read_encrypted = value
  let _ = {
    assert read_plaintext == sample_plaintext
  }
  let _ = {
    assert read_encrypted != read_plaintext
  }

  let assert Ok(value) = openssl.decrypt(encrypted_file, password_file)
  assert value == sample_plaintext

  use _ <- result.try(
    simplifile.write(password_file, "i am not the password you are looking for")
    |> result.map_error(fn(_) { openssl.OpenSslError(-1, "TESTING") }),
  )

  // ERROR
  //  test: glm_encrypted_file_test.decrypt_incorrect_password_test
  //  code: let assert Ok(_) =
  //    openssl.decrypt(encrypted_file, password_file)
  //  value: Error(OpenSslError(1, <<98, 97, 100, 32, 100, 101, 99, 114, 121, 112, 116, 10, 56, 48, 69, 48, 65, 50, 50, 50, 54
  //  ...
  //  226, 72, 62, 139, 88, 147, 128, 207, 141, 146, 98, 100, 30, 187, 61, 123, 129, 9, 100, 119, 242, 45, 165, 95, 25, 3>>))
  //  info: Pattern match failed, no pattern matched the value.

  // Attempt to decrypt file with an incorrect password
  let assert Error(openssl.OpenSslError(1, _b)) =
    openssl.decrypt(encrypted_file, password_file)
  // TODO: figure out why `b` is not displaying as a string, but instead as a bit string
  Ok(Nil)
}

/// example code for the README
pub fn example_for_readme() {
  // ----------------------------------------------------------------------------------
  // ensure this directory exists
  // ----------------------------------------------------------------------------------
  let assert Ok(_) = simplifile.create_directory_all("./test_data")

  // ----------------------------------------------------------------------------------
  // create some file resources
  // ----------------------------------------------------------------------------------
  // note that the file resources are typed as one of [encrypted, plaintext, password]

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
    openssl.encrypt(plaintext_file, encrypted_file, password_file)

  // TODO: 1. Copy the encrypted file to it's final storage location.

  // TODO: 2. Delete the plaintext file!

  // TODO: 3. Secure (or delete) the password file!

  // ----------------------------------------------------------------------------------
  // decrypt the encrypted file
  // ----------------------------------------------------------------------------------
  let assert Ok(_secret) = openssl.decrypt(encrypted_file, password_file)
}
