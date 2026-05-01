import argv
import clip.{type Command}
import clip/flag.{type Flag}
import clip/help
import clip/opt.{type Opt}
import gleam/io
import gleam/list
import gleam/string
import glm_encrypted_file/encfile
import logging
import pprint
import simplifile

type Args {
  EncryptArgs(
    plaintext_input_file_path: String,
    encrypted_output_file_path: String,
    password_file_path: String,
    log_level: String,
    dry_run: Bool,
  )
  DecryptArgs(
    encrypted_input_file_path: String,
    decrypted_output_file_path: String,
    password_file_path: String,
    log_level: String,
    dry_run: Bool,
  )
}

fn plaintext_file_path_opt() -> Opt(String) {
  opt.new("plaintext")
  |> opt.help("path to the plaintext input file")
}

fn decrypted_file_path_opt() -> Opt(String) {
  opt.new("decrypted")
  |> opt.help("path to the decrypted file")
}

fn encrypted_file_path_opt() -> Opt(String) {
  opt.new("encrypted")
  |> opt.help("path to the encrypted file")
}

fn password_file_path_opt() -> Opt(String) {
  opt.new("password")
  |> opt.help("path to the password file")
}

fn dry_run_opt() -> Flag {
  flag.new("dryrun")
  |> flag.help("dry run, don't actually do anything")
}

fn log_level_opt() -> Opt(String) {
  opt.new("log_level")
  |> opt.default("info")
  |> opt.help("log output verbosity, debug|info|warn|error")
}

fn encrypt_command() -> Command(Args) {
  clip.command({
    use plaintext_input_file_path <- clip.parameter
    use encrypted_output_file_path <- clip.parameter
    use password_file_path <- clip.parameter
    use log_level <- clip.parameter
    use dry_run <- clip.parameter

    EncryptArgs(
      plaintext_input_file_path:,
      encrypted_output_file_path:,
      password_file_path:,
      log_level:,
      dry_run:,
    )
  })
  |> clip.opt(plaintext_file_path_opt())
  |> clip.opt(encrypted_file_path_opt())
  |> clip.opt(password_file_path_opt())
  |> clip.opt(log_level_opt())
  |> clip.flag(dry_run_opt())
  |> clip.help(help.simple("subcommand generate", "generate all the files"))
}

fn decrypt_command() -> Command(Args) {
  clip.command({
    use encrypted_input_file_path <- clip.parameter
    use decrypted_output_file_path <- clip.parameter
    use password_file_path <- clip.parameter
    use log_level <- clip.parameter
    use dry_run <- clip.parameter

    DecryptArgs(
      encrypted_input_file_path:,
      decrypted_output_file_path:,
      password_file_path:,
      log_level:,
      dry_run:,
    )
  })
  |> clip.opt(encrypted_file_path_opt())
  |> clip.opt(decrypted_file_path_opt())
  |> clip.opt(password_file_path_opt())
  |> clip.opt(log_level_opt())
  |> clip.flag(dry_run_opt())
  |> clip.help(help.simple(
    "subcommand runscript",
    "runscript with the artifact directory on target server",
  ))
}

fn command() -> Command(Args) {
  clip.subcommands([
    #("encrypt", encrypt_command()),
    #("decrypt", decrypt_command()),
  ])
  |> clip.help(help.simple(
    "glm_encrypted_file",
    "encrypt and decrypt files, using shell and openssl.",
  ))
}

fn configure_logging(level: String) -> Nil {
  let _ = logging.configure()
  let level = level |> string.lowercase
  let logging_level = case level {
    "debug" -> logging.Debug
    "info" -> logging.Info
    "warn" -> logging.Warning
    "error" -> logging.Error
    _ -> logging.Debug
  }
  let _ = logging.set_level(logging_level)
}

pub fn main() -> Nil {
  case
    command()
    |> clip.help(help.simple("subcommands", "encrypt, decrypt"))
    |> clip.run(argv.load().arguments)
  {
    Error(e) -> {
      e |> string.inspect |> string.split("\\n") |> list.map(io.println_error)
      Nil
    }
    Ok(EncryptArgs(
      plaintext_file_path,
      encrypted_file_path,
      password_file_path,
      log_level,
      dry_run,
    )) -> {
      configure_logging(log_level)
      let plaintext_file = encfile.new_plaintext_file(plaintext_file_path)
      let encrypted_file = encfile.new_encrypted_file(encrypted_file_path)
      let password_file = encfile.new_password_file(password_file_path)

      logging.log(
        logging.Debug,
        "cli encrypt, plaintext_file_path:"
          <> plaintext_file_path
          <> ", encrypted_file_path: "
          <> encrypted_file_path
          <> ", password_file_path: "
          <> password_file_path,
      )
      case dry_run {
        True -> panic
        False -> {
          case encfile.encrypt(plaintext_file, encrypted_file, password_file) {
            Error(e) -> {
              pprint.debug(
                "failed to encrypt file, plaintext file: "
                <> plaintext_file_path
                <> ", encrypted file: "
                <> encrypted_file_path
                <> ", password file: "
                <> password_file_path,
              )
              pprint.debug(e)
              panic
            }
            Ok(_) -> {
              io.println(
                "successfully wrote encrypted file: " <> encrypted_file_path,
              )
              Nil
            }
          }
        }
      }
    }
    Ok(DecryptArgs(
      encrypted_input_file_path,
      decrypted_output_file_path,
      password_file_path,
      log_level,
      dry_run,
    )) -> {
      configure_logging(log_level)
      let encrypted_file = encfile.new_encrypted_file(encrypted_input_file_path)
      let password_file = encfile.new_password_file(password_file_path)

      logging.log(
        logging.Debug,
        "cli decrypt, encrypted_input_file_path: "
          <> encrypted_input_file_path
          <> ", password_file_path: "
          <> password_file_path
          <> ", decrypted_output_file_path: "
          <> decrypted_output_file_path,
      )
      case dry_run {
        True -> panic
        False -> {
          case encfile.decrypt(encrypted_file, password_file) {
            Error(e) -> {
              pprint.debug(
                "failed to decrypt, encrypted file: "
                <> encrypted_input_file_path
                <> ", password file: "
                <> password_file_path,
              )
              pprint.debug(e)
              panic
            }
            Ok(data) -> {
              case simplifile.write(decrypted_output_file_path, data) {
                Error(e) -> {
                  pprint.debug(
                    "failed to write decrypted file to: "
                    <> decrypted_output_file_path,
                  )
                  pprint.debug(e)
                  panic
                }
                Ok(_) -> {
                  io.println(
                    "successfully wrote decrypted file to: "
                    <> decrypted_output_file_path,
                  )
                  Nil
                }
              }
            }
          }
        }
      }
    }
  }
}
