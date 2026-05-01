import gleam/result
import gleeunit
import gleeunit/should
import glm_encrypted_file/encfile
import simplifile
import temporary

pub fn main() -> Nil {
  gleeunit.main()
}

pub const sample_text = "SAMPLETEXT111111112222222223333333344444444"

pub const sample_password = "SAMPLEPASSWORDabc"

pub fn roundtrip_test() {
  // create test resources
  use plaintext <- temporary.create(temporary.file())
  let plaintext_file = encfile.new_plaintext_file(plaintext)
  use _ <- result.try(simplifile.write(plaintext_file.path, sample_text))

  use password <- temporary.create(temporary.file())
  let password_file = encfile.new_password_file(password)
  use _ <- result.try(simplifile.write(password_file.path, sample_password))

  use encrypted <- temporary.create(temporary.file())
  let encrypted_file = encfile.new_encrypted_file(encrypted)

  // encrypt the plaintext file
  let _ =
    should.be_ok(encfile.encrypt(plaintext_file, encrypted_file, password_file))
  // verify the encrypted file is not equal to the plaintext file
  let plaintext2 = should.be_ok(simplifile.read(plaintext_file.path))
  let encrypted2 = should.be_ok(simplifile.read(encrypted_file.path))
  let _ = should.equal(plaintext, plaintext2)
  let _ = should.not_equal(plaintext2, encrypted2)

  // verify that the decrypted encrypted file equals the plaintext file
  should.equal(
    should.be_ok(encfile.decrypt(encrypted_file, password_file)),
    plaintext,
  )
  Ok(Nil)
}
