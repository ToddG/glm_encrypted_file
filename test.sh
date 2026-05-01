#!/bin/sh

rm -rf ./test_data
mkdir -p ./test_data
echo "i am a secret" >> ./test_data/plaintext
echo "password" >> ./test_data/password

gleam run -m glm_encrypted_file -- encrypt --plaintext ./test_data/plaintext --encrypted ./test_data/encrypted --password ./test_data/password --log_level debug

gleam run -m glm_encrypted_file -- decrypt --decrypted ./test_data/decrypted --encrypted ./test_data/encrypted --password ./test_data/password --log_level debug

echo "input plaintext"
cat ./test_data/plaintext

echo "encrypted file"
cat ./test_data/encrypted

echo "decrypted file"
cat ./test_data/decrypted