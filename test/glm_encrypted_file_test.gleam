import gleam/result
import gleeunit
import gleeunit/should
import glm_encrypted_file/openssl as encfile
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
  let _ =
    should.be_ok(encfile.encrypt(plaintext_file, encrypted_file, password_file))

  // 3. verify the encrypted file is not equal to the plaintext file
  let read_plaintext = should.be_ok(simplifile.read(plaintext_file))
  let read_encrypted = should.be_ok(simplifile.read(encrypted_file))
  let _ = should.equal(read_plaintext, sample_plaintext)
  let _ = should.not_equal(read_encrypted, read_plaintext)

  // 4. decrypt the encrypted file and verify decrypted plaintext equals original plaintext
  should.equal(
    should.be_ok(encfile.decrypt(encrypted_file, password_file)),
    sample_plaintext,
  )
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
    encfile.encrypt(plaintext_file, encrypted_file, password_file)

  // TODO: 1. Copy the encrypted file to it's final storage location.

  // TODO: 2. Delete the plaintext file!

  // TODO: 3. Secure (or delete) the password file!

  // ----------------------------------------------------------------------------------
  // decrypt the encrypted file
  // ----------------------------------------------------------------------------------
  let assert Ok(_secret) = encfile.decrypt(encrypted_file, password_file)
}
