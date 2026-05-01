import gleam/result
import gleeunit
import gleeunit/should
import glm_encrypted_file/encfile
import logging
import simplifile
import temporary

pub fn main() -> Nil {
  gleeunit.main()
  let _ = logging.configure()
  let _ = logging.set_level(logging.Debug)
  logging.log(logging.Info, "tests starting...")
}

pub const sample_plaintext = "THIS IS SOME SAMPLE PLAINTEXT THAT WILL BE ENCRYPTED 111111112222222223333333344444444"

pub const sample_password = "SAMPLE_PASSWORD"

pub fn encrypt_test() {
  // 1. create file resources
  //
  use plaintext <- temporary.create(temporary.file())
  let plaintext_file = encfile.new_plaintext_file(plaintext)
  use _ <- result.try(simplifile.write(plaintext_file.path, sample_plaintext))

  use password <- temporary.create(temporary.file())
  let password_file = encfile.new_password_file(password)
  use _ <- result.try(simplifile.write(password_file.path, sample_password))

  use encrypted <- temporary.create(temporary.file())
  let encrypted_file = encfile.new_encrypted_file(encrypted)

  // 2. encrypt the plaintext file
  let _ =
    should.be_ok(encfile.encrypt(plaintext_file, encrypted_file, password_file))

  // 3. verify the encrypted file is not equal to the plaintext file
  let read_plaintext = should.be_ok(simplifile.read(plaintext_file.path))
  let read_encrypted = should.be_ok(simplifile.read(encrypted_file.path))
  let _ = should.equal(read_plaintext, sample_plaintext)
  let _ = should.not_equal(read_encrypted, read_plaintext)
}

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
  let assert Ok(_) =
    encfile.encrypt(plaintext_file, encrypted_file, password_file)

  // ----------------------------------------------------------------------------------
  // decrypt the encrypted file
  // ----------------------------------------------------------------------------------
  let assert Ok(_secret) = encfile.decrypt(encrypted_file, password_file)
}
